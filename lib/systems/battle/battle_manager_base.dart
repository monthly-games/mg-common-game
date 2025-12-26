import 'package:flutter/foundation.dart';
import 'battle_types.dart';
import 'battle_entity.dart';

/// Base class for turn-based battle managers
/// Extend this class and implement game-specific logic
abstract class BattleManagerBase extends ChangeNotifier {
  TurnPhase _phase = TurnPhase.playerStart;
  int _turnCount = 0;

  // VFX Callbacks (set by game)
  OnDamageVfx? onDamageVfx;
  OnHealVfx? onHealVfx;
  OnBlockVfx? onBlockVfx;
  OnEffectAppliedVfx? onEffectAppliedVfx;
  OnVictoryVfx? onVictoryVfx;
  OnDefeatVfx? onDefeatVfx;

  /// Current turn phase
  TurnPhase get phase => _phase;

  /// Current turn number (1-indexed)
  int get turnCount => _turnCount;

  /// Check if battle is over
  bool get isBattleOver =>
      _phase == TurnPhase.victory || _phase == TurnPhase.defeat;

  /// Check if it's player's turn
  bool get isPlayerTurn =>
      _phase == TurnPhase.playerStart || _phase == TurnPhase.playerAction;

  /// Get all player entities (implement in subclass)
  List<BattleEntity> get playerEntities;

  /// Get all enemy entities (implement in subclass)
  List<BattleEntity> get enemyEntities;

  /// Check victory condition (default: all enemies dead)
  bool get isVictory => enemyEntities.every((e) => !e.isAlive);

  /// Check defeat condition (default: all players dead)
  bool get isDefeat => playerEntities.every((e) => !e.isAlive);

  /// Initialize battle
  @mustCallSuper
  void startBattle() {
    _phase = TurnPhase.playerStart;
    _turnCount = 1;
    onBattleStart();
    notifyListeners();
  }

  /// Called when battle starts (override for custom logic)
  void onBattleStart() {}

  /// Start player turn
  @mustCallSuper
  void startPlayerTurn() {
    _phase = TurnPhase.playerAction;

    // Process start-of-turn for player entities
    for (final entity in playerEntities) {
      entity.onTurnStart();
    }

    onPlayerTurnStart();
    notifyListeners();
  }

  /// Called when player turn starts (override for custom logic)
  void onPlayerTurnStart() {}

  /// End player turn and start enemy turn
  @mustCallSuper
  Future<void> endPlayerTurn() async {
    // Process end-of-turn for player entities
    for (final entity in playerEntities) {
      entity.onTurnEnd();
    }

    _phase = TurnPhase.enemyAction;
    onPlayerTurnEnd();
    notifyListeners();

    // Execute enemy turn
    await executeEnemyTurn();
  }

  /// Called when player turn ends (override for custom logic)
  void onPlayerTurnEnd() {}

  /// Execute enemy turn (implement in subclass)
  Future<void> executeEnemyTurn();

  /// End enemy turn and check for victory/defeat
  @mustCallSuper
  void endEnemyTurn() {
    // Process end-of-turn for enemy entities
    for (final entity in enemyEntities) {
      entity.onTurnEnd();
    }

    // Check victory/defeat
    if (isVictory) {
      _phase = TurnPhase.victory;
      onVictory();
      onVictoryVfx?.call();
    } else if (isDefeat) {
      _phase = TurnPhase.defeat;
      onDefeat();
      onDefeatVfx?.call();
    } else {
      // Start next turn
      _turnCount++;
      _phase = TurnPhase.playerStart;
      startPlayerTurn();
    }

    notifyListeners();
  }

  /// Called on victory (override for custom logic)
  void onVictory() {}

  /// Called on defeat (override for custom logic)
  void onDefeat() {}

  /// Execute attack from source to target
  AttackResult executeAttack({
    required BattleEntity source,
    required BattleEntity target,
    int? baseDamage,
    double multiplier = 1.0,
    bool canCrit = true,
  }) {
    final damage = baseDamage ?? source.baseAttack;
    final calculatedDamage = source.calculateOutgoingDamage(damage);
    final finalDamage = (calculatedDamage * multiplier).toInt();

    // Check critical (simple implementation - override for custom)
    final isCritical = canCrit && _rollCritical();
    final critDamage = isCritical ? (finalDamage * 1.5).toInt() : finalDamage;

    // Apply vulnerability on target
    int actualDamage = critDamage;
    if (target.hasEffect(EffectType.vulnerable)) {
      actualDamage = (actualDamage * 1.5).toInt();
    }

    // Track block before damage
    final blockedAmount = target.block.clamp(0, actualDamage);
    final isBlocked = blockedAmount > 0;

    // Apply damage
    target.takeDamage(actualDamage);

    // VFX callback
    final isPlayer = playerEntities.contains(target);
    onDamageVfx?.call(
      actualDamage - blockedAmount,
      isCritical: isCritical,
      isPlayer: isPlayer,
    );

    return AttackResult(
      damage: actualDamage,
      isCritical: isCritical,
      isBlocked: isBlocked,
      blockedAmount: blockedAmount,
    );
  }

  /// Execute heal on target
  HealResult executeHeal({
    required BattleEntity target,
    required int amount,
  }) {
    final oldHp = target.currentHp;
    final actualHeal = target.heal(amount);
    final overheal = amount - actualHeal;

    // VFX callback
    final isPlayer = playerEntities.contains(target);
    onHealVfx?.call(actualHeal, isPlayer: isPlayer);

    return HealResult(
      amount: actualHeal,
      overheal: overheal,
    );
  }

  /// Apply effect to target
  void applyEffect({
    required BattleEntity target,
    required EffectType type,
    int duration = 2,
    int value = 0,
  }) {
    target.applyEffect(BattleEffect(
      type: type,
      duration: duration,
      value: value,
    ));

    // VFX callback
    final isPlayer = playerEntities.contains(target);
    onEffectAppliedVfx?.call(type, isPlayer: isPlayer);
  }

  /// Add block to target
  void addBlock({
    required BattleEntity target,
    required int amount,
  }) {
    target.addBlock(amount);
    onBlockVfx?.call(amount);
  }

  /// Simple critical roll (20% chance)
  bool _rollCritical() {
    return (DateTime.now().millisecondsSinceEpoch % 100) < 20;
  }

  /// Reset battle state
  @mustCallSuper
  void reset() {
    _phase = TurnPhase.playerStart;
    _turnCount = 0;

    for (final entity in playerEntities) {
      entity.reset();
    }
    for (final entity in enemyEntities) {
      entity.reset();
    }

    notifyListeners();
  }
}

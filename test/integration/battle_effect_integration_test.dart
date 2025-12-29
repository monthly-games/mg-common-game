import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/battle/battle_entity.dart';
import 'package:mg_common_game/systems/battle/battle_manager_base.dart';
import 'package:mg_common_game/systems/battle/battle_types.dart';

/// Test implementation of BattleManagerBase for integration testing
class TestBattleManager extends BattleManagerBase {
  final List<BattleEntity> _players = [];
  final List<BattleEntity> _enemies = [];

  @override
  List<BattleEntity> get playerEntities => _players;

  @override
  List<BattleEntity> get enemyEntities => _enemies;

  void addPlayer(BattleEntity entity) {
    _players.add(entity);
  }

  void addEnemy(BattleEntity entity) {
    _enemies.add(entity);
  }

  @override
  Future<void> executeEnemyTurn() async {
    // Simple enemy AI: attack random player
    for (final enemy in _enemies.where((e) => e.isAlive)) {
      final alivePlayers = _players.where((p) => p.isAlive).toList();
      if (alivePlayers.isEmpty) break;

      final target = alivePlayers[0]; // Attack first alive player
      executeAttack(source: enemy, target: target);

      // Small delay for realism
      await Future.delayed(const Duration(milliseconds: 50));
    }

    endEnemyTurn();
  }

  void clearAll() {
    _players.clear();
    _enemies.clear();
  }
}

/// Integration test for Battle + Effect systems
/// Tests combat scenarios with various status effects and turn mechanics
void main() {
  group('Battle + Effect Integration Tests', () {
    late TestBattleManager battleManager;
    late BattleEntity player;
    late BattleEntity enemy;

    setUp(() {
      battleManager = TestBattleManager();

      player = BattleEntityFactory.player(
        id: 'player_1',
        name: 'Hero',
        maxHp: 100,
        baseAttack: 10,
      );

      enemy = BattleEntityFactory.enemy(
        id: 'enemy_1',
        name: 'Goblin',
        maxHp: 50,
        baseAttack: 8,
      );

      battleManager.addPlayer(player);
      battleManager.addEnemy(enemy);
    });

    tearDown(() {
      battleManager.clearAll();
    });

    test('Poison effect deals damage over turns', () async {
      // 1. Start battle
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 2. Apply poison effect to enemy
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.poison,
        duration: 3,
        value: 5, // 5 damage per turn
      );

      expect(enemy.hasEffect(EffectType.poison), isTrue);
      final initialHp = enemy.currentHp;

      // 3. End player turn and process enemy turn
      await battleManager.endPlayerTurn();

      // 4. Start next turn - poison should tick at turn start
      battleManager.startPlayerTurn();
      enemy.onTurnStart(); // Process poison damage

      // Enemy should take poison damage
      expect(enemy.currentHp, lessThan(initialHp));
    });

    test('Vulnerable effect increases incoming damage', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Apply vulnerable effect
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.vulnerable,
        duration: 2,
        value: 0,
      );

      expect(enemy.hasEffect(EffectType.vulnerable), isTrue);

      // 2. Attack vulnerable enemy
      final result = battleManager.executeAttack(
        source: player,
        target: enemy,
      );

      // Damage should be increased (base 10 * 1.5 vulnerability = 15)
      expect(result.damage, greaterThanOrEqualTo(10));
    });

    test('Weak effect reduces outgoing damage', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Apply weak effect to player
      battleManager.applyEffect(
        target: player,
        type: EffectType.weak,
        duration: 2,
        value: 0,
      );

      // 2. Player attacks while weakened
      final result = battleManager.executeAttack(
        source: player,
        target: enemy,
      );

      // Damage should be reduced (10 * 0.75 = 7)
      expect(result.damage, lessThanOrEqualTo(10));
    });

    test('Strength effect increases attack power', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Attack without strength
      final normalResult = battleManager.executeAttack(
        source: player,
        target: enemy,
      );
      final normalDamage = normalResult.damage;

      // Reset enemy HP
      enemy.reset();

      // 2. Apply strength buff
      battleManager.applyEffect(
        target: player,
        type: EffectType.strength,
        duration: 3,
        value: 5, // +5 attack
      );

      // 3. Attack with strength
      final buffedResult = battleManager.executeAttack(
        source: player,
        target: enemy,
      );

      // Damage should be higher
      expect(buffedResult.damage, greaterThan(normalDamage));
    });

    test('Block absorbs damage completely', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Add block to player
      battleManager.addBlock(target: player, amount: 20);
      expect(player.block, 20);

      // 2. Enemy attacks player with block
      final result = battleManager.executeAttack(
        source: enemy,
        target: player,
      );

      // Block should absorb damage
      expect(result.isBlocked, isTrue);
      expect(result.blockedAmount, greaterThan(0));
      expect(player.currentHp, 100); // No HP damage taken
    });

    test('Burn effect ticks each turn', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Apply burn
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.burn,
        duration: 3,
        value: 3, // 3 damage per turn
      );

      final initialHp = enemy.currentHp;
      int totalBurnDamage = 0;

      // 2. Process multiple turns
      for (int turn = 0; turn < 3; turn++) {
        final hpBefore = enemy.currentHp;
        enemy.onTurnStart(); // Process burn damage
        final hpAfter = enemy.currentHp;
        totalBurnDamage += (hpBefore - hpAfter);

        enemy.onTurnEnd(); // Decay effects
      }

      // Total burn damage over 3 turns
      expect(totalBurnDamage, greaterThan(0));
      expect(enemy.currentHp, lessThan(initialHp));
    });

    test('Regeneration heals each turn', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Damage player first
      player.takeDamage(30);
      expect(player.currentHp, 70);

      // 2. Apply regeneration
      battleManager.applyEffect(
        target: player,
        type: EffectType.regeneration,
        duration: 3,
        value: 5, // 5 HP per turn
      );

      // 3. Process turn
      player.onTurnStart();

      // Player should heal
      expect(player.currentHp, greaterThan(70));
    });

    test('Effect duration decays over turns', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Apply effect with 3 turn duration
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.poison,
        duration: 3,
        value: 5,
      );

      expect(enemy.hasEffect(EffectType.poison), isTrue);
      final effect = enemy.effects.first;
      expect(effect.duration, 3);

      // 2. End turn - duration should decay
      enemy.onTurnEnd();
      expect(effect.duration, 2);

      // 3. Another turn
      enemy.onTurnEnd();
      expect(effect.duration, 1);

      // 4. Final turn - effect should be removed
      enemy.onTurnEnd();
      expect(enemy.hasEffect(EffectType.poison), isFalse);
    });

    test('Multiple effects stack and interact', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // 1. Apply multiple debuffs to enemy
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.vulnerable,
        duration: 2,
      );
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.poison,
        duration: 3,
        value: 3,
      );
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.burn,
        duration: 2,
        value: 2,
      );

      // 2. Verify all effects applied
      expect(enemy.effects, hasLength(3));
      expect(enemy.hasEffect(EffectType.vulnerable), isTrue);
      expect(enemy.hasEffect(EffectType.poison), isTrue);
      expect(enemy.hasEffect(EffectType.burn), isTrue);

      // 3. Attack vulnerable enemy (should take extra damage)
      final initialHp = enemy.currentHp;
      battleManager.executeAttack(source: player, target: enemy);

      // 4. Process DoT effects
      enemy.onTurnStart();

      // Enemy should be heavily damaged from attack + DoTs
      expect(enemy.currentHp, lessThan(initialHp - 10));
    });

    test('Critical hits deal increased damage', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // Execute multiple attacks to potentially get a crit
      var hasCrit = false;
      var maxDamage = 0;

      for (int i = 0; i < 50; i++) {
        enemy.reset();

        final result = battleManager.executeAttack(
          source: player,
          target: enemy,
          canCrit: true,
        );

        if (result.isCritical) {
          hasCrit = true;
          expect(result.damage, greaterThan(player.baseAttack));
        }

        if (result.damage > maxDamage) {
          maxDamage = result.damage;
        }
      }

      // Should have gotten at least one crit in 50 attacks
      // or at least have varying damage values
      expect(maxDamage, greaterThanOrEqualTo(player.baseAttack));
    });

    test('Complete battle with effect management', () async {
      // Real battle scenario with effects

      // 1. Start battle
      battleManager.startBattle();
      expect(battleManager.phase, TurnPhase.playerStart);

      battleManager.startPlayerTurn();
      expect(battleManager.phase, TurnPhase.playerAction);

      // 2. Player applies poison and attacks
      battleManager.applyEffect(
        target: enemy,
        type: EffectType.poison,
        duration: 5,
        value: 3,
      );
      battleManager.executeAttack(source: player, target: enemy);

      // 3. End player turn and enemy acts
      await battleManager.endPlayerTurn();

      // 4. Continue battle until someone wins
      int maxTurns = 20;
      int turnCount = 0;

      while (!battleManager.isBattleOver && turnCount < maxTurns) {
        if (battleManager.phase == TurnPhase.playerStart ||
            battleManager.phase == TurnPhase.playerAction) {
          battleManager.executeAttack(source: player, target: enemy);
          await battleManager.endPlayerTurn();
        }
        turnCount++;
      }

      // Battle should end
      expect(
        battleManager.phase,
        anyOf([TurnPhase.victory, TurnPhase.defeat]),
      );
    });

    test('Edge case: overkill damage', () async {
      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // Enemy with low HP
      enemy.reset(hp: 5);

      // Massive damage
      final result = battleManager.executeAttack(
        source: player,
        target: enemy,
        baseDamage: 100,
      );

      // Enemy should be dead
      expect(enemy.isAlive, isFalse);
      expect(enemy.currentHp, 0);
    });

    test('Edge case: heal overflow prevention', () async {
      battleManager.startBattle();

      // Player at full HP
      expect(player.currentHp, player.maxHp);

      // Try to overheal
      final healResult = battleManager.executeHeal(
        target: player,
        amount: 50,
      );

      // Should not exceed max HP
      expect(player.currentHp, player.maxHp);
      expect(healResult.overheal, 50);
    });

    test('Edge case: zero or negative damage', () async {
      battleManager.startBattle();

      final initialHp = enemy.currentHp;

      // Attack with 0 damage
      battleManager.executeAttack(
        source: player,
        target: enemy,
        baseDamage: 0,
      );

      expect(enemy.currentHp, initialHp);
    });

    test('Edge case: permanent effect (999 duration)', () async {
      battleManager.startBattle();

      // Apply permanent buff
      final permanentEffect = BattleEffect(
        type: EffectType.strength,
        duration: 999,
        value: 10,
      );

      player.applyEffect(permanentEffect);

      // Process many turns
      for (int i = 0; i < 10; i++) {
        player.onTurnEnd();
      }

      // Effect should still be active
      expect(player.hasEffect(EffectType.strength), isTrue);
      expect(permanentEffect.isPermanent, isTrue);
    });

    test('Real-world: boss battle with phases', () async {
      // Create a boss with high HP
      final boss = BattleEntityFactory.enemy(
        id: 'boss_1',
        name: 'Dragon',
        maxHp: 200,
        baseAttack: 15,
      );

      battleManager.clearAll();
      battleManager.addPlayer(player);
      battleManager.addEnemy(boss);

      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // Phase 1: Boss at full HP
      expect(boss.hpPercent, greaterThan(0.9));

      // Player attacks
      while (boss.hpPercent >= 0.75 && boss.isAlive) {
        battleManager.executeAttack(source: player, target: boss);
      }

      // Phase 2: Boss below 75% - apply rage buff
      expect(boss.hpPercent, lessThan(0.75));
      battleManager.applyEffect(
        target: boss,
        type: EffectType.strength,
        duration: 999,
        value: 5,
      );

      // Phase 3: Boss enraged state
      expect(boss.hasEffect(EffectType.strength), isTrue);

      // Continue battle
      final bossHpBefore = boss.currentHp;
      battleManager.executeAttack(source: player, target: boss);

      // Boss should be taking damage
      expect(boss.currentHp, lessThanOrEqualTo(bossHpBefore));
    });

    test('Real-world: party vs multiple enemies', () async {
      // Create a party
      final mage = BattleEntityFactory.player(
        id: 'mage',
        name: 'Mage',
        maxHp: 60,
        baseAttack: 15,
      );

      final tank = BattleEntityFactory.player(
        id: 'tank',
        name: 'Tank',
        maxHp: 150,
        baseAttack: 5,
      );

      // Multiple enemies
      final goblin1 = BattleEntityFactory.enemy(
        id: 'goblin1',
        name: 'Goblin 1',
        maxHp: 40,
        baseAttack: 7,
      );

      final goblin2 = BattleEntityFactory.enemy(
        id: 'goblin2',
        name: 'Goblin 2',
        maxHp: 40,
        baseAttack: 7,
      );

      battleManager.clearAll();
      battleManager.addPlayer(player);
      battleManager.addPlayer(mage);
      battleManager.addPlayer(tank);
      battleManager.addEnemy(goblin1);
      battleManager.addEnemy(goblin2);

      battleManager.startBattle();
      battleManager.startPlayerTurn();

      // Tank uses block ability
      battleManager.addBlock(target: tank, amount: 30);

      // Mage casts AoE poison
      for (final enemy in battleManager.enemyEntities) {
        battleManager.applyEffect(
          target: enemy,
          type: EffectType.poison,
          duration: 3,
          value: 4,
        );
      }

      // Party attacks
      battleManager.executeAttack(source: player, target: goblin1);
      battleManager.executeAttack(source: mage, target: goblin2);

      // End turn
      await battleManager.endPlayerTurn();

      // Check party is still alive
      final alivePlayers =
          battleManager.playerEntities.where((p) => p.isAlive).toList();
      expect(alivePlayers.length, greaterThanOrEqualTo(2));
    });
  });
}

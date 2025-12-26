/// Common battle system types and interfaces
library battle_types;

/// Turn phase enumeration for turn-based battle systems
enum TurnPhase {
  /// Player's turn starts (before actions)
  playerStart,
  /// Player is taking actions
  playerAction,
  /// Enemy's turn
  enemyAction,
  /// Battle won
  victory,
  /// Battle lost
  defeat,
}

/// Battle state for card-based or action-based systems
enum BattleState {
  /// Player can take actions
  playerTurn,
  /// Enemy is taking actions
  enemyTurn,
  /// Player won the battle
  win,
  /// Player lost the battle
  loss,
}

/// Common effect types used in battles
enum EffectType {
  /// Reduces outgoing damage
  weak,
  /// Increases incoming damage
  vulnerable,
  /// Increases attack power
  strength,
  /// Adds damage reduction
  defense,
  /// Poisons target (damage over time)
  poison,
  /// Burns target (damage over time)
  burn,
  /// Stuns target (skip turn)
  stun,
  /// Regenerates HP over time
  regeneration,
  /// Increases speed
  haste,
  /// Decreases speed
  slow,
}

/// A battle effect with duration and value
class BattleEffect {
  final EffectType type;
  int duration;
  int value;

  BattleEffect({
    required this.type,
    required this.duration,
    this.value = 0,
  });

  /// Whether this effect is permanent (very long duration)
  bool get isPermanent => duration >= 999;

  /// Create a copy with modified fields
  BattleEffect copyWith({
    EffectType? type,
    int? duration,
    int? value,
  }) {
    return BattleEffect(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      value: value ?? this.value,
    );
  }

  @override
  String toString() => 'BattleEffect($type, dur: $duration, val: $value)';
}

/// Result of an attack action
class AttackResult {
  final int damage;
  final bool isCritical;
  final bool isBlocked;
  final int blockedAmount;
  final List<EffectType> appliedEffects;

  const AttackResult({
    required this.damage,
    this.isCritical = false,
    this.isBlocked = false,
    this.blockedAmount = 0,
    this.appliedEffects = const [],
  });

  /// Actual damage dealt after block
  int get actualDamage => isBlocked ? (damage - blockedAmount).clamp(0, damage) : damage;
}

/// Result of a heal action
class HealResult {
  final int amount;
  final int overheal;

  const HealResult({
    required this.amount,
    this.overheal = 0,
  });
}

/// Interface for anything that can take damage
abstract class Damageable {
  int get currentHp;
  int get maxHp;
  bool get isAlive => currentHp > 0;

  /// Take damage and return remaining HP
  int takeDamage(int amount);

  /// Heal and return actual amount healed
  int heal(int amount);
}

/// Interface for anything that can attack
abstract class Attacker {
  int get baseAttack;

  /// Calculate damage with modifiers
  int calculateDamage({
    int? baseDamage,
    double multiplier = 1.0,
  });
}

/// Interface for entities with battle effects
abstract class Effectable {
  List<BattleEffect> get effects;

  /// Check if entity has a specific effect
  bool hasEffect(EffectType type);

  /// Get effect value (0 if not present)
  int getEffectValue(EffectType type);

  /// Apply an effect
  void applyEffect(BattleEffect effect);

  /// Remove effects of a type
  void removeEffect(EffectType type);

  /// Decay all effects (reduce duration by 1, remove expired)
  void decayEffects();
}

/// VFX callback signatures for battle visualization
typedef OnDamageVfx = void Function(int damage, {bool isCritical, bool isPlayer});
typedef OnHealVfx = void Function(int amount, {bool isPlayer});
typedef OnBlockVfx = void Function(int amount);
typedef OnEffectAppliedVfx = void Function(EffectType type, {bool isPlayer});
typedef OnVictoryVfx = void Function();
typedef OnDefeatVfx = void Function();

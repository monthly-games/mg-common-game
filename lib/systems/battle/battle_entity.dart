import 'package:flutter/foundation.dart';
import 'battle_types.dart';

/// Base class for battle participants (player, enemy, summon, etc.)
class BattleEntity with ChangeNotifier implements Damageable, Effectable {
  final String id;
  final String name;

  int _currentHp;
  final int _maxHp;
  int _baseAttack;
  int _baseDefense;
  int _block;

  final List<BattleEffect> _effects = [];

  BattleEntity({
    required this.id,
    required this.name,
    required int maxHp,
    int? currentHp,
    int baseAttack = 10,
    int baseDefense = 0,
  })  : _maxHp = maxHp,
        _currentHp = currentHp ?? maxHp,
        _baseAttack = baseAttack,
        _baseDefense = baseDefense,
        _block = 0;

  // Damageable interface
  @override
  int get currentHp => _currentHp;

  @override
  int get maxHp => _maxHp;

  @override
  bool get isAlive => _currentHp > 0;

  /// Current block amount
  int get block => _block;

  /// Base attack value
  int get baseAttack => _baseAttack;

  /// Base defense value
  int get baseDefense => _baseDefense;

  /// HP percentage (0.0 to 1.0)
  double get hpPercent => _maxHp > 0 ? (_currentHp / _maxHp).clamp(0.0, 1.0) : 0.0;

  @override
  int takeDamage(int amount) {
    if (amount <= 0) return _currentHp;

    // Apply vulnerability
    int actualDamage = amount;
    if (hasEffect(EffectType.vulnerable)) {
      actualDamage = (actualDamage * 1.5).toInt();
    }

    // Apply defense
    actualDamage = (actualDamage - _baseDefense).clamp(0, actualDamage);

    // Apply block
    if (_block > 0) {
      if (_block >= actualDamage) {
        _block -= actualDamage;
        actualDamage = 0;
      } else {
        actualDamage -= _block;
        _block = 0;
      }
    }

    _currentHp = (_currentHp - actualDamage).clamp(0, _maxHp);
    notifyListeners();
    return _currentHp;
  }

  @override
  int heal(int amount) {
    if (amount <= 0) return 0;

    final oldHp = _currentHp;
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
    final actualHeal = _currentHp - oldHp;

    if (actualHeal > 0) {
      notifyListeners();
    }

    return actualHeal;
  }

  /// Add block for this turn
  void addBlock(int amount) {
    if (amount > 0) {
      _block += amount;
      notifyListeners();
    }
  }

  /// Reset block (typically at start of turn)
  void resetBlock() {
    if (_block > 0) {
      _block = 0;
      notifyListeners();
    }
  }

  /// Modify base attack
  void modifyAttack(int delta) {
    _baseAttack = (_baseAttack + delta).clamp(0, 9999);
    notifyListeners();
  }

  /// Modify base defense
  void modifyDefense(int delta) {
    _baseDefense = (_baseDefense + delta).clamp(0, 9999);
    notifyListeners();
  }

  // Effectable interface
  @override
  List<BattleEffect> get effects => List.unmodifiable(_effects);

  @override
  bool hasEffect(EffectType type) {
    return _effects.any((e) => e.type == type);
  }

  @override
  int getEffectValue(EffectType type) {
    for (final effect in _effects) {
      if (effect.type == type) return effect.value;
    }
    return 0;
  }

  @override
  void applyEffect(BattleEffect effect) {
    // Check for existing effect of same type
    for (var existing in _effects) {
      if (existing.type == effect.type) {
        // Stack duration and value
        existing.duration += effect.duration;
        existing.value += effect.value;
        notifyListeners();
        return;
      }
    }

    // Add new effect
    _effects.add(effect);
    notifyListeners();
  }

  @override
  void removeEffect(EffectType type) {
    _effects.removeWhere((e) => e.type == type);
    notifyListeners();
  }

  @override
  void decayEffects() {
    for (final effect in _effects) {
      if (!effect.isPermanent) {
        effect.duration--;
      }
    }
    _effects.removeWhere((e) => e.duration <= 0);
    notifyListeners();
  }

  /// Start of turn processing
  void onTurnStart() {
    resetBlock();
    _processDotEffects();
  }

  /// End of turn processing
  void onTurnEnd() {
    decayEffects();
  }

  void _processDotEffects() {
    // Process damage over time effects
    for (final effect in _effects) {
      if (effect.type == EffectType.poison) {
        takeDamage(effect.value);
      } else if (effect.type == EffectType.burn) {
        takeDamage(effect.value);
      } else if (effect.type == EffectType.regeneration) {
        heal(effect.value);
      }
    }
  }

  /// Calculate outgoing damage with effects
  int calculateOutgoingDamage(int baseDamage) {
    double damage = baseDamage.toDouble();

    // Apply strength bonus
    damage += getEffectValue(EffectType.strength);

    // Apply weakness penalty
    if (hasEffect(EffectType.weak)) {
      damage *= 0.75;
    }

    return damage.toInt().clamp(0, 99999);
  }

  /// Reset to initial state
  void reset({int? hp}) {
    _currentHp = hp ?? _maxHp;
    _block = 0;
    _effects.clear();
    notifyListeners();
  }

  @override
  String toString() => 'BattleEntity($name, HP: $_currentHp/$_maxHp)';
}

/// Extension for creating common entity types
extension BattleEntityFactory on BattleEntity {
  /// Create a basic player entity
  static BattleEntity player({
    String id = 'player',
    String name = 'Player',
    int maxHp = 100,
    int baseAttack = 10,
  }) {
    return BattleEntity(
      id: id,
      name: name,
      maxHp: maxHp,
      baseAttack: baseAttack,
    );
  }

  /// Create a basic enemy entity
  static BattleEntity enemy({
    required String id,
    required String name,
    required int maxHp,
    int baseAttack = 8,
  }) {
    return BattleEntity(
      id: id,
      name: name,
      maxHp: maxHp,
      baseAttack: baseAttack,
    );
  }
}

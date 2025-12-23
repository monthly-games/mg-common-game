import 'package:mg_common_game/core/systems/rpg/stat_system/stat_modifier.dart';

class BaseStat {
  double _baseValue;
  final List<StatModifier> _modifiers = [];
  bool _isDirty = true;
  double _cachedValue = 0;

  BaseStat(this._baseValue);

  set baseValue(double value) {
    _baseValue = value;
    _isDirty = true;
  }

  double get baseValue => _baseValue;

  double get value {
    if (_isDirty) {
      _cachedValue = _calculateFinalValue();
      _isDirty = false;
    }
    return _cachedValue;
  }

  void addModifier(StatModifier modifier) {
    _modifiers.add(modifier);
    _isDirty = true;
  }

  bool removeModifier(StatModifier modifier) {
    if (_modifiers.remove(modifier)) {
      _isDirty = true;
      return true;
    }
    return false;
  }

  bool removeAllModifiersFromSource(Object source) {
    bool removed = false;
    _modifiers.removeWhere((mod) {
      if (mod.source == source) {
        removed = true;
        return true;
      }
      return false;
    });
    if (removed) _isDirty = true;
    return removed;
  }

  double _calculateFinalValue() {
    double finalValue = _baseValue;
    double sumPercentAdd = 0;

    // 1. Add Flat Modifiers
    for (final mod in _modifiers) {
      if (mod.type == StatModType.flat) {
        finalValue += mod.value;
      }
    }

    // 2. Sum PercentAdd
    for (final mod in _modifiers) {
      if (mod.type == StatModType.percentAdd) {
        sumPercentAdd += mod.value;
      }
    }

    // Apply Percent Add (Base + Flat) * (1 + Sum%)
    finalValue *= (1 + sumPercentAdd);

    // 3. Apply PercentMult
    for (final mod in _modifiers) {
      if (mod.type == StatModType.percentMult) {
        finalValue *= mod.value;
      }
    }

    // Optional: Rounding policy? For now, we keep distinct double logic.
    // If needed we can round here.
    return finalValue;
  }
}

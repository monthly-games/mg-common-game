import 'dart:math';
import 'package:mg_common_game/core/systems/rpg/stat_system/base_stat.dart';
import 'package:mg_common_game/features/battle/logic/buffs/buff.dart';

class BattleUnit {
  final String id;
  final String name;

  // Stats
  late final BaseStat hp;
  late final BaseStat atk;
  late final BaseStat def;

  // State
  double _currentHp;
  final List<Buff> _buffs = [];

  BattleUnit({
    required this.id,
    required this.name,
    double baseHp = 100,
    double baseAtk = 10,
    double baseDef = 0,
  }) : _currentHp = baseHp {
    hp = BaseStat(baseHp);
    atk = BaseStat(baseAtk);
    def = BaseStat(baseDef);
  }

  double get currentHp => _currentHp;
  bool get isDead => _currentHp <= 0;

  void takeDamage(double amount) {
    if (isDead) return;
    final finalDamage = max(0, amount - def.value); // Simple defense logic
    _currentHp = max(0, _currentHp - finalDamage);
  }

  void heal(double amount) {
    if (isDead) return;
    _currentHp = min(hp.value, _currentHp + amount);
  }

  void addBuff(Buff buff) {
    _buffs.add(buff);
    // Apply modifiers immediately
    buff.modifiers.forEach((statKey, mod) {
      _getStatByKey(statKey)?.addModifier(mod);
    });
  }

  void removeBuff(Buff buff) {
    if (_buffs.remove(buff)) {
      buff.modifiers.forEach((statKey, mod) {
        _getStatByKey(statKey)?.removeModifier(mod);
      });
    }
  }

  void onTurnEnd() {
    // Process buffs backwards to allow removal during iteration
    for (int i = _buffs.length - 1; i >= 0; i--) {
      final buff = _buffs[i];
      if (buff.tick()) {
        removeBuff(buff);
      }
    }
  }

  BaseStat? _getStatByKey(String key) {
    switch (key) {
      case 'hp':
        return hp;
      case 'atk':
        return atk;
      case 'def':
        return def;
      default:
        return null;
    }
  }
}

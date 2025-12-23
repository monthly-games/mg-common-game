import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/systems/rpg/stat_system/stat_modifier.dart';
import 'package:mg_common_game/features/battle/logic/battle_unit.dart';
import 'package:mg_common_game/features/battle/logic/buffs/buff.dart';

void main() {
  group('BattleUnit & Buffs', () {
    test('Initialization sets correct stats', () {
      final unit = BattleUnit(
        id: 'hero_1',
        name: 'Hero',
        baseHp: 100,
        baseAtk: 10,
        baseDef: 5,
      );

      expect(unit.hp.value, 100);
      expect(unit.atk.value, 10);
      expect(unit.def.value, 5);
      expect(unit.currentHp, 100);
    });

    test('Buff modifies stats', () {
      final unit =
          BattleUnit(id: 'hero', name: 'Hero', baseHp: 100, baseAtk: 10);

      // +100% ATK Buff
      final buff = Buff(
        id: 'rage',
        duration: 2,
        modifiers: {
          'atk': StatModifier(1.0, StatModType.percentAdd),
        },
      );

      unit.addBuff(buff);

      // Base 10 + 100% = 20
      expect(unit.atk.value, 20);
    });

    test('Buff expiration removes modifiers', () {
      final unit =
          BattleUnit(id: 'hero', name: 'Hero', baseHp: 100, baseAtk: 10);
      final buff = Buff(
        id: 'rage',
        duration: 2,
        modifiers: {
          'atk': StatModifier(10, StatModType.flat), // +10 Flat
        },
      );

      unit.addBuff(buff);
      expect(unit.atk.value, 20);

      // Turn 1 passing
      unit.onTurnEnd();
      expect(unit.atk.value, 20); // Duration 2 -> 1, still active

      // Turn 2 passing
      unit.onTurnEnd(); // Duration 1 -> 0, expires
      expect(unit.atk.value, 10); // Back to base
    });

    test('Damage calculation logic', () {
      // Very basic sanity check for takeDamage
      final unit = BattleUnit(id: 'dummy', name: 'Dummy', baseHp: 100);

      unit.takeDamage(10);
      expect(unit.currentHp, 90);

      unit.takeDamage(999);
      expect(unit.currentHp, 0);
      expect(unit.isDead, true);
    });
  });
}

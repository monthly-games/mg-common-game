import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/systems/rpg/stat_system/base_stat.dart';
import 'package:mg_common_game/core/systems/rpg/stat_system/stat_modifier.dart';

void main() {
  group('StatSystem', () {
    test('Calculate basic value without modifiers', () {
      final stat = BaseStat(10);
      expect(stat.value, 10);
    });

    test('Add flat modifier', () {
      final stat = BaseStat(10);
      stat.addModifier(StatModifier(10, StatModType.flat));
      expect(stat.value, 20); // 10 + 10
    });

    test('Add percent additive modifier', () {
      final stat = BaseStat(10);
      // +50% of base+flat
      stat.addModifier(StatModifier(0.5, StatModType.percentAdd));
      expect(stat.value, 15); // 10 * 1.5
    });

    test('Add percent multiplicative modifier', () {
      final stat = BaseStat(10);
      // x2
      stat.addModifier(StatModifier(2.0, StatModType.percentMult));
      expect(stat.value, 20); // 10 * 2
    });

    test('Verify calculation order: (Base + Flat) * (1 + Sum%Add) * Prod%Mult',
        () {
      final stat = BaseStat(10);

      stat.addModifier(
          StatModifier(10, StatModType.flat)); // Base(10) + 10 = 20
      stat.addModifier(StatModifier(0.5, StatModType.percentAdd)); // +50%
      stat.addModifier(StatModifier(
          1.0, StatModType.percentAdd)); // +100% -> Total +150% (x2.5)
      stat.addModifier(StatModifier(2.0, StatModType.percentMult)); // x2

      // Expected: (10 + 10) * (1 + 0.5 + 1.0) * 2.0
      // 20 * 2.5 * 2.0 = 100
      expect(stat.value, 100);
    });

    test('Remove modifier updates value', () {
      final stat = BaseStat(10);
      final mod = StatModifier(10, StatModType.flat);
      stat.addModifier(mod);
      expect(stat.value, 20);

      stat.removeModifier(mod);
      expect(stat.value, 10);
    });

    test('Changing base value updates final value', () {
      final stat = BaseStat(10);
      stat.addModifier(StatModifier(10, StatModType.flat)); // 20

      stat.baseValue = 20;
      expect(stat.value, 30); // 20 + 10
    });
  });
}

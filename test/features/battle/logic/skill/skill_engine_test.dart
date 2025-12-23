import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/features/battle/logic/battle_unit.dart';
import 'package:mg_common_game/features/battle/logic/skill/skill.dart';
import 'package:mg_common_game/features/battle/logic/skill/skill_effect.dart';

void main() {
  group('SkillEngine', () {
    late BattleUnit caster;
    late BattleUnit target;

    setUp(() {
      caster = BattleUnit(id: 'caster', name: 'Caster', baseAtk: 10);
      target = BattleUnit(id: 'target', name: 'Target', baseHp: 100);
    });

    test('Skill damage effect works', () {
      final damageSkill = Skill(
        id: 'fireball',
        name: 'Fireball',
        cooldown: 3,
        effects: [DamageEffect(multiplier: 2.0)], // 10 Atk * 2.0 = 20 Dmg
      );

      damageSkill.execute(caster, target);
      expect(target.currentHp, 80);
    });

    test('Skill heal effect works', () {
      // Damage self first
      caster.takeDamage(50);
      expect(caster.currentHp, 50);

      final healSkill = Skill(
        id: 'heal',
        name: 'Heal',
        cooldown: 2,
        effects: [HealEffect(amount: 20)],
      );

      healSkill.execute(caster, caster);
      expect(caster.currentHp, 70);
    });

    test('Skill cooldown management', () {
      final skill = Skill(id: 'slash', name: 'Slash', cooldown: 2, effects: []);

      expect(skill.isReady, true);

      skill.execute(caster, target);
      expect(skill.isReady, false);
      expect(skill.currentCooldown, 2);

      skill.tick(); // Turn 1 pass
      expect(skill.isReady, false);
      expect(skill.currentCooldown, 1);

      skill.tick(); // Turn 2 pass
      expect(skill.isReady, true);
      expect(skill.currentCooldown, 0);
    });
  });
}

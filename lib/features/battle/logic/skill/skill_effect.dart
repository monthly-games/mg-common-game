import 'package:mg_common_game/features/battle/logic/battle_unit.dart';

abstract class SkillEffect {
  void apply(BattleUnit caster, BattleUnit target);
}

class DamageEffect extends SkillEffect {
  final double multiplier;

  DamageEffect({required this.multiplier});

  @override
  void apply(BattleUnit caster, BattleUnit target) {
    // Basic Dmg = Caster.ATK * Multiplier
    final damage = caster.atk.value * multiplier;
    target.takeDamage(damage);
  }
}

class HealEffect extends SkillEffect {
  final double amount;

  HealEffect({required this.amount});

  @override
  void apply(BattleUnit caster, BattleUnit target) {
    target.heal(amount);
  }
}
// BuffEffect can be added later as needed

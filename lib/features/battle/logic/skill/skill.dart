import 'package:mg_common_game/features/battle/logic/battle_unit.dart';
import 'package:mg_common_game/features/battle/logic/skill/skill_effect.dart';

class Skill {
  final String id;
  final String name;
  final int cooldown;
  final List<SkillEffect> effects;

  int _currentCooldown = 0;

  Skill({
    required this.id,
    required this.name,
    required this.cooldown,
    required this.effects,
  });

  bool get isReady => _currentCooldown <= 0;
  int get currentCooldown => _currentCooldown;

  void execute(BattleUnit caster, BattleUnit target) {
    if (!isReady) return;

    for (final effect in effects) {
      effect.apply(caster, target);
    }

    _currentCooldown = cooldown;
  }

  void tick() {
    if (_currentCooldown > 0) {
      _currentCooldown--;
    }
  }
}

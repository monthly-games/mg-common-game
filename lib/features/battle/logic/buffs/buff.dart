import 'package:mg_common_game/core/systems/rpg/stat_system/stat_modifier.dart';

class Buff {
  final String id;
  int duration; // Turns or Seconds
  final Map<String, StatModifier> modifiers;
  final bool isDebuff;

  Buff({
    required this.id,
    required this.duration,
    required this.modifiers,
    this.isDebuff = false,
  });

  /// Returns true if duration ended
  bool tick() {
    if (duration > 0) {
      duration--;
    }
    return duration <= 0;
  }
}

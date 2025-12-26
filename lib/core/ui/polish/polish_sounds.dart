/// Polish Sound Effects
/// 폴리시 시스템 전용 사운드 상수 및 유틸리티

/// 폴리시용 사운드 이펙트 경로
class PolishSounds {
  PolishSounds._();

  // 터치/UI
  static const String tap = 'sfx/ui_tap.mp3';
  static const String tapHeavy = 'sfx/ui_tap_heavy.mp3';
  static const String swipe = 'sfx/ui_swipe.mp3';
  static const String toggle = 'sfx/ui_toggle.mp3';
  static const String error = 'sfx/ui_error.mp3';
  static const String success = 'sfx/ui_success.mp3';

  // 보상/획득
  static const String coinDrop = 'sfx/coin_drop.mp3';
  static const String coinStack = 'sfx/coin_stack.mp3';
  static const String itemGet = 'sfx/item_get.mp3';
  static const String chestOpen = 'sfx/chest_open.mp3';
  static const String legendary = 'sfx/legendary_drop.mp3';
  static const String levelUp = 'sfx/level_up.mp3';

  // 전투
  static const String hit = 'sfx/hit.mp3';
  static const String hitCritical = 'sfx/hit_critical.mp3';
  static const String hitWeak = 'sfx/hit_weak.mp3';
  static const String miss = 'sfx/miss.mp3';
  static const String block = 'sfx/block.mp3';
  static const String heal = 'sfx/heal.mp3';
  static const String buff = 'sfx/buff.mp3';
  static const String debuff = 'sfx/debuff.mp3';
  static const String death = 'sfx/death.mp3';

  // 콤보
  static const String combo1 = 'sfx/combo_1.mp3';
  static const String combo2 = 'sfx/combo_2.mp3';
  static const String combo3 = 'sfx/combo_3.mp3';
  static const String comboBreak = 'sfx/combo_break.mp3';
  static const String comboMax = 'sfx/combo_max.mp3';

  // 특수 연출
  static const String explosion = 'sfx/explosion.mp3';
  static const String magic = 'sfx/magic.mp3';
  static const String ultimate = 'sfx/ultimate.mp3';
  static const String victory = 'sfx/victory.mp3';
  static const String defeat = 'sfx/defeat.mp3';

  /// 콤보 카운트에 따른 사운드 반환
  static String comboSound(int count) {
    if (count >= 20) return comboMax;
    if (count >= 10) return combo3;
    if (count >= 5) return combo2;
    return combo1;
  }

  /// 콤보 카운트에 따른 피치 반환 (높을수록 높은 피치)
  static double comboPitch(int count) {
    if (count >= 20) return 1.3;
    if (count >= 10) return 1.2;
    if (count >= 5) return 1.1;
    return 1.0;
  }
}

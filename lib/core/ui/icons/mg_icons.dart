import 'package:flutter/material.dart';

/// MG-Games 아이콘 시스템
/// UI_UX_MASTER_GUIDE.md 기반
class MGIcons {
  MGIcons._();

  // ============================================================
  // 아이콘 크기 상수
  // ============================================================

  /// Navigation 아이콘 (24dp, 터치 영역 48dp)
  static const double navigationSize = 24;
  static const double navigationTouchTarget = 48;

  /// Action Bar 아이콘 (28dp, 터치 영역 44dp)
  static const double actionBarSize = 28;
  static const double actionBarTouchTarget = 44;

  /// Toolbar 아이콘 (24dp, 터치 영역 40dp)
  static const double toolbarSize = 24;
  static const double toolbarTouchTarget = 40;

  /// List Item 아이콘 (20dp)
  static const double listItemSize = 20;

  /// Badge 아이콘 (16dp)
  static const double badgeSize = 16;

  // ============================================================
  // 터치 영역 상수 (최소 44dp)
  // ============================================================
  static const double minTouchTarget = 44;
  static const double largeTouchTarget = 56;
  static const double extraLargeTouchTarget = 72;

  // ============================================================
  // Core Icons (필수)
  // ============================================================

  /// 내비게이션 아이콘
  static const IconData navHome = Icons.home_rounded;
  static const IconData navShop = Icons.store_rounded;
  static const IconData navInventory = Icons.inventory_2_rounded;
  static const IconData navQuest = Icons.assignment_rounded;
  static const IconData navSocial = Icons.people_rounded;

  /// 시스템 아이콘
  static const IconData settings = Icons.settings_rounded;
  static const IconData notification = Icons.notifications_rounded;
  static const IconData mail = Icons.mail_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData help = Icons.help_rounded;

  // ============================================================
  // Resource Icons (자원)
  // ============================================================
  static const IconData gold = Icons.monetization_on_rounded;
  static const IconData gem = Icons.diamond_rounded;
  static const IconData energy = Icons.bolt_rounded;
  static const IconData key = Icons.vpn_key_rounded;
  static const IconData ticket = Icons.confirmation_number_rounded;

  // ============================================================
  // Game Icons (게임 공통)
  // ============================================================
  static const IconData attack = Icons.sports_martial_arts_rounded;
  static const IconData defend = Icons.shield_rounded;
  static const IconData skill = Icons.auto_fix_high_rounded;
  static const IconData item = Icons.inventory_rounded;
  static const IconData special = Icons.star_rounded;

  // ============================================================
  // Control Icons (컨트롤)
  // ============================================================
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData fastForward = Icons.fast_forward_rounded;
  static const IconData speed1x = Icons.looks_one_rounded;
  static const IconData speed2x = Icons.looks_two_rounded;
  static const IconData speed3x = Icons.looks_3_rounded;

  // ============================================================
  // Tower Defense 전용 (MG-0001)
  // ============================================================
  static const IconData tower = Icons.cell_tower_rounded;
  static const IconData wave = Icons.waves_rounded;
  static const IconData hp = Icons.favorite_rounded;
  static const IconData upgrade = Icons.upgrade_rounded;
  static const IconData sell = Icons.sell_rounded;

  // ============================================================
  // 헬퍼 메서드
  // ============================================================

  /// 터치 영역이 적용된 아이콘 버튼 위젯
  static Widget iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = navigationSize,
    double touchTarget = minTouchTarget,
    Color? color,
    String? tooltip,
  }) {
    return SizedBox(
      width: touchTarget,
      height: touchTarget,
      child: IconButton(
        icon: Icon(icon, size: size, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: touchTarget,
          minHeight: touchTarget,
        ),
      ),
    );
  }

  /// 아이콘 + 라벨 조합 위젯
  static Widget iconWithLabel({
    required IconData icon,
    required String label,
    double iconSize = listItemSize,
    TextStyle? textStyle,
    Color? color,
    double spacing = 4,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: spacing),
        Text(label, style: textStyle?.copyWith(color: color)),
      ],
    );
  }
}

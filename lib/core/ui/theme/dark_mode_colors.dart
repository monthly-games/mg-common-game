import 'package:flutter/material.dart';

/// 라이트/다크 모드 컬러 시스템
/// UI_UX_MASTER_GUIDE.md 기반
class DarkModeColors {
  DarkModeColors._();

  // ============================================================
  // 라이트 모드 (Light Mode)
  // ============================================================
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ============================================================
  // 다크 모드 (Dark Mode)
  // ============================================================
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkDivider = Color(0xFF424242);

  // ============================================================
  // 다크 모드 원칙
  // ============================================================
  // ✓ 순수 검정(#000000) 피하기 → 사용: #121212
  // ✓ 밝기 대비 4.5:1 이상 유지
  // ✓ 포화도 낮은 컬러 사용
  // ✓ 그림자 대신 elevation 표현
  // ✓ 시스템 설정 자동 감지

  /// 밝기에 따른 배경색 가져오기
  static Color getBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : lightBackground;
  }

  /// 밝기에 따른 표면색 가져오기
  static Color getSurface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  /// 밝기에 따른 카드색 가져오기
  static Color getCard(Brightness brightness) {
    return brightness == Brightness.dark ? darkCard : lightCard;
  }

  /// 밝기에 따른 텍스트색 가져오기
  static Color getText(Brightness brightness) {
    return brightness == Brightness.dark ? darkText : lightText;
  }

  /// 밝기에 따른 보조 텍스트색 가져오기
  static Color getTextSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  }

  /// 밝기에 따른 구분선색 가져오기
  static Color getDivider(Brightness brightness) {
    return brightness == Brightness.dark ? darkDivider : lightDivider;
  }

  /// 다크 모드용 elevation 색상 (그림자 대신 사용)
  static Color getElevationOverlay(int elevation) {
    // Material 3 elevation overlay
    final overlayAlpha = switch (elevation) {
      0 => 0,
      1 => 5,
      2 => 7,
      3 => 8,
      4 => 9,
      6 => 11,
      8 => 12,
      12 => 14,
      16 => 15,
      24 => 16,
      _ => 16,
    };
    return Color.fromARGB(overlayAlpha, 255, 255, 255);
  }

  /// 다크 모드 ColorScheme 생성
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF2196F3),
        surface: darkSurface,
        error: Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkText,
        onError: Colors.black,
      );

  /// 라이트 모드 ColorScheme 생성
  static ColorScheme get lightColorScheme => const ColorScheme.light(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF2196F3),
        surface: lightSurface,
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
        onError: Colors.white,
      );
}

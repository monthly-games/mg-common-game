import 'package:flutter/material.dart';
import '../accessibility/accessibility_settings.dart' show TextScaleOption;

/// MG-Games 타이포그래피 시스템
/// UI_UX_MASTER_GUIDE.md 기반
class MGTextStyles {
  MGTextStyles._();

  // ============================================================
  // 폰트 패밀리
  // ============================================================
  static const String fontFamily = 'Pretendard';
  static const String fontFamilyFallback = 'Roboto';

  // Level A JRPG 보조 폰트
  static const String jrpgDisplayFont = 'Black Han Sans';

  // 지역별 폰트
  static const Map<String, String> regionalFonts = {
    'ko': 'Pretendard',
    'ja': 'Noto Sans JP',
    'zh': 'Noto Sans SC',
    'hi': 'Noto Sans Devanagari',
    'th': 'Noto Sans Thai',
    'ar': 'Noto Sans Arabic',
  };

  // ============================================================
  // 텍스트 스케일 옵션
  // ============================================================
  static const double scaleSmall = 0.85;
  static const double scaleNormal = 1.0;
  static const double scaleLarge = 1.15;
  static const double scaleExtraLarge = 1.3;
  static const double scaleHuge = 1.5;

  /// 스케일 옵션 enum
  static double getScale(TextScaleOption option) {
    return switch (option) {
      TextScaleOption.small => scaleSmall,
      TextScaleOption.medium => scaleNormal,
      TextScaleOption.large => scaleLarge,
      TextScaleOption.extraLarge => scaleExtraLarge,
      TextScaleOption.huge => scaleHuge,
    };
  }

  // ============================================================
  // Display (32-48sp)
  // ============================================================
  static const TextStyle display = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    height: 1.2,
  );

  // ============================================================
  // Headlines (H1: 24-28sp, H2: 20-22sp, H3: 18sp)
  // ============================================================
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    height: 1.4,
  );

  // ============================================================
  // Body (14-16sp)
  // ============================================================
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    height: 1.5,
  );

  // ============================================================
  // Caption (12sp)
  // ============================================================
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    height: 1.4,
  );

  // ============================================================
  // Button (14-16sp)
  // ============================================================
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    height: 1.0,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    height: 1.0,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    height: 1.0,
  );

  // ============================================================
  // HUD (게임 내 표시용)
  // ============================================================
  static const TextStyle hudLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    height: 1.0,
  );

  static const TextStyle hud = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    height: 1.0,
  );

  static const TextStyle hudSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    height: 1.0,
  );

  // ============================================================
  // 최소 텍스트 크기 (접근성)
  // ============================================================
  static const double minBodySize = 12;
  static const double minButtonSize = 12;
  static const double minCaptionSize = 10;
  static const double minHudSize = 11;

  // ============================================================
  // 헬퍼 메서드
  // ============================================================

  /// 스케일이 적용된 텍스트 스타일 가져오기
  static TextStyle getScaled(TextStyle style, double scale) {
    final scaledSize = (style.fontSize ?? 14) * scale;
    return style.copyWith(fontSize: scaledSize);
  }

  /// 색상이 적용된 텍스트 스타일 가져오기
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 지역별 폰트가 적용된 텍스트 스타일 가져오기
  static TextStyle forLocale(TextStyle style, String locale) {
    final font = regionalFonts[locale] ?? fontFamily;
    return style.copyWith(fontFamily: font);
  }

  /// 스케일된 폰트 크기 가져오기 (Context 기반)
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(baseSize);
    return textScaleFactor;
  }
}

// TextScaleOption은 accessibility_settings.dart에서 정의됨

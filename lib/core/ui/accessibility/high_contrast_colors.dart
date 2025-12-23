import 'package:flutter/material.dart';

/// 고대비 모드 컬러 시스템
/// ACCESSIBILITY_GUIDE.md 기반
class HighContrastColors {
  HighContrastColors._();

  // ============================================================
  // 배경 (Background)
  // ============================================================
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A1A);

  // ============================================================
  // 텍스트 (Text)
  // ============================================================
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFFFFF00); // 노랑
  static const Color textDisabled = Color(0xFF888888);

  // ============================================================
  // UI 요소 (UI Elements)
  // ============================================================
  static const Color buttonPrimary = Color(0xFFFFFFFF);
  static const Color buttonSecondary = Color(0xFF00FFFF); // 시안
  static const Color border = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFF444444);

  // ============================================================
  // 상태 (Status)
  // ============================================================
  static const Color success = Color(0xFF00FF00);
  static const Color error = Color(0xFFFF0000);
  static const Color warning = Color(0xFFFFFF00);
  static const Color info = Color(0xFF00FFFF);

  // ============================================================
  // 포커스 (Focus)
  // ============================================================
  static const Color focusRing = Color(0xFFFFFF00);
  static const Color selection = Color(0xFF0066FF);

  // ============================================================
  // 대비 비율 헬퍼
  // ============================================================

  /// WCAG 2.1 최소 대비 비율 (4.5:1 for normal text)
  static const double minContrastRatioNormal = 4.5;

  /// WCAG 2.1 최소 대비 비율 (3:1 for large text 18sp+)
  static const double minContrastRatioLarge = 3.0;

  /// 두 색상 간의 대비 비율 계산
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getRelativeLuminance(foreground);
    final l2 = _getRelativeLuminance(background);

    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 상대 휘도 계산 (WCAG 2.1)
  static double _getRelativeLuminance(Color color) {
    double r = color.red / 255;
    double g = color.green / 255;
    double b = color.blue / 255;

    r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055).clamp(0, 1);
    g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055).clamp(0, 1);
    b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055).clamp(0, 1);

    r = r <= 0.03928 ? r : (r * r * r);
    g = g <= 0.03928 ? g : (g * g * g);
    b = b <= 0.03928 ? b : (b * b * b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// 대비가 충분한지 확인
  static bool meetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = getContrastRatio(foreground, background);
    final minRatio = isLargeText ? minContrastRatioLarge : minContrastRatioNormal;
    return ratio >= minRatio;
  }

  /// 고대비 모드 테마 데이터
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        cardColor: card,
        dividerColor: divider,
        colorScheme: const ColorScheme.dark(
          primary: buttonPrimary,
          secondary: buttonSecondary,
          surface: surface,
          error: error,
          onPrimary: background,
          onSecondary: background,
          onSurface: textPrimary,
          onError: background,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
          bodySmall: TextStyle(color: textSecondary),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonPrimary,
            foregroundColor: background,
            side: const BorderSide(color: border, width: 2),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonSecondary,
            side: const BorderSide(color: buttonSecondary, width: 2),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: border, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: focusRing, width: 3),
          ),
          labelStyle: TextStyle(color: textSecondary),
        ),
        focusColor: focusRing,
        hoverColor: focusRing.withOpacity(0.3),
      );
}

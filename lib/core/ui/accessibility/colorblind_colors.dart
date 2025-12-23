import 'package:flutter/material.dart';

/// 색맹 유형
enum ColorBlindType {
  /// 적록 색맹 (Deuteranopia) - 6% 남성
  deuteranopia,

  /// 적색맹 (Protanopia) - 1%
  protanopia,

  /// 청황 색맹 (Tritanopia) - 0.01%
  tritanopia;

  /// 표시 이름
  String get displayName {
    return switch (this) {
      ColorBlindType.deuteranopia => '적록 색맹',
      ColorBlindType.protanopia => '적색맹',
      ColorBlindType.tritanopia => '청황 색맹',
    };
  }
}

/// 색맹 대응 컬러 시스템
/// ACCESSIBILITY_GUIDE.md 기반
class ColorBlindColors {
  ColorBlindColors._();

  // ============================================================
  // 일반 컬러 → 색맹 대응 컬러 매핑
  // ============================================================

  /// 성공 컬러 (녹색 → 청록)
  static const Color successNormal = Color(0xFF4CAF50);
  static const Color successColorblind = Color(0xFF00ACC1);

  /// 오류 컬러 (빨강 → 주황)
  static const Color errorNormal = Color(0xFFF44336);
  static const Color errorColorblind = Color(0xFFFF6D00);

  /// 경고 컬러 (노랑 - 유지)
  static const Color warningNormal = Color(0xFFFF9800);
  static const Color warningColorblind = Color(0xFFFF9800);

  /// 정보 컬러 (파랑 - 유지)
  static const Color infoNormal = Color(0xFF2196F3);
  static const Color infoColorblind = Color(0xFF2196F3);

  // ============================================================
  // 레어리티 색맹 대응 (색상 + 아이콘/패턴)
  // ============================================================

  static const Map<String, RarityStyleColorblind> rarityStyles = {
    'common': RarityStyleColorblind(
      color: Color(0xFF9E9E9E),
      icon: '○',
      pattern: RarityPattern.none,
    ),
    'uncommon': RarityStyleColorblind(
      color: Color(0xFF00BCD4), // 청록으로 변경
      icon: '◇',
      pattern: RarityPattern.dots,
    ),
    'rare': RarityStyleColorblind(
      color: Color(0xFF2196F3),
      icon: '☆',
      pattern: RarityPattern.stripes,
    ),
    'epic': RarityStyleColorblind(
      color: Color(0xFF9C27B0),
      icon: '◆',
      pattern: RarityPattern.gradient,
    ),
    'legendary': RarityStyleColorblind(
      color: Color(0xFFFF9800),
      icon: '★',
      pattern: RarityPattern.glow,
    ),
    'mythic': RarityStyleColorblind(
      color: Color(0xFFFF6D00), // 빨강 대신 주황
      icon: '✦',
      pattern: RarityPattern.shimmer,
    ),
  };

  // ============================================================
  // 유형별 색맹 팔레트
  // ============================================================

  /// 적록 색맹 (Deuteranopia) 팔레트
  static const deuteranopiaColors = ColorBlindPalette(
    primary: Color(0xFF2196F3), // 파랑
    secondary: Color(0xFFFF9800), // 주황
    success: Color(0xFF00ACC1), // 청록
    error: Color(0xFFFF6D00), // 주황
    warning: Color(0xFFFFEB3B), // 노랑
  );

  /// 적색맹 (Protanopia) 팔레트
  static const protanopiaColors = ColorBlindPalette(
    primary: Color(0xFF2196F3), // 파랑
    secondary: Color(0xFFFFEB3B), // 노랑
    success: Color(0xFF00BCD4), // 시안
    error: Color(0xFFFF9800), // 주황
    warning: Color(0xFFFFEB3B), // 노랑
  );

  /// 청황 색맹 (Tritanopia) 팔레트
  static const tritanopiaColors = ColorBlindPalette(
    primary: Color(0xFFE91E63), // 핑크
    secondary: Color(0xFF4CAF50), // 녹색
    success: Color(0xFF4CAF50), // 녹색
    error: Color(0xFFE91E63), // 핑크
    warning: Color(0xFFFF5722), // 딥오렌지
  );

  /// 색맹 유형에 따른 팔레트 가져오기
  static ColorBlindPalette getPalette(ColorBlindType type) {
    return switch (type) {
      ColorBlindType.deuteranopia => deuteranopiaColors,
      ColorBlindType.protanopia => protanopiaColors,
      ColorBlindType.tritanopia => tritanopiaColors,
    };
  }

  /// 일반 컬러를 색맹 대응 컬러로 변환
  static Color getAccessibleColor(
    Color normalColor, {
    required bool colorBlindMode,
    ColorBlindType type = ColorBlindType.deuteranopia,
  }) {
    if (!colorBlindMode) return normalColor;

    // 성공 (녹색)
    if (normalColor.value == successNormal.value) {
      return successColorblind;
    }

    // 오류 (빨강)
    if (normalColor.value == errorNormal.value) {
      return errorColorblind;
    }

    return normalColor;
  }
}

/// 색맹 대응 팔레트
class ColorBlindPalette {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color error;
  final Color warning;

  const ColorBlindPalette({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.error,
    required this.warning,
  });
}

/// 레어리티 패턴 (색상 외 보조 표시)
enum RarityPattern {
  none,
  dots,
  stripes,
  gradient,
  glow,
  shimmer,
}

/// 레어리티 스타일 (색맹 대응)
class RarityStyleColorblind {
  final Color color;
  final String icon;
  final RarityPattern pattern;

  const RarityStyleColorblind({
    required this.color,
    required this.icon,
    required this.pattern,
  });
}

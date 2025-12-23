import 'package:flutter/material.dart';

/// MG-Games 공통 컬러 시스템
/// UI_UX_MASTER_GUIDE.md 기반
class MGColors {
  MGColors._();

  // ============================================================
  // Primary Actions (주요 액션)
  // ============================================================
  static const Color primaryAction = Color(0xFF4CAF50);
  static const Color secondaryAction = Color(0xFF2196F3);

  // ============================================================
  // Status Colors (상태 컬러)
  // ============================================================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ============================================================
  // Resource Colors (자원 컬러)
  // ============================================================
  static const Color gold = Color(0xFFFFD700);
  static const Color gem = Color(0xFF9C27B0);
  static const Color energy = Color(0xFF00BCD4);
  static const Color exp = Color(0xFF8BC34A);

  // ============================================================
  // Rarity Colors (레어리티 컬러)
  // ============================================================
  static const Color common = Color(0xFF9E9E9E);
  static const Color uncommon = Color(0xFF4CAF50);
  static const Color rare = Color(0xFF2196F3);
  static const Color epic = Color(0xFF9C27B0);
  static const Color legendary = Color(0xFFFF9800);
  static const Color mythic = Color(0xFFF44336);

  // ============================================================
  // Category Theme Colors (카테고리별 테마)
  // ============================================================

  // Year 1 Core (MG-0001 ~ MG-0012)
  static const Color year1Primary = Color(0xFF4CAF50);
  static const Color year1Secondary = Color(0xFF81C784);
  static const Color year1Accent = Color(0xFFFFD700);

  // Year 2 Core (MG-0013 ~ MG-0024)
  static const Color year2Primary = Color(0xFF2196F3);
  static const Color year2Secondary = Color(0xFF64B5F6);
  static const Color year2Accent = Color(0xFFFF9800);

  // Level A JRPG (MG-0025 ~ MG-0036)
  static const Color levelAPrimary = Color(0xFF9C27B0);
  static const Color levelASecondary = Color(0xFFBA68C8);
  static const Color levelAAccent = Color(0xFFE91E63);

  // Emerging - India (MG-0037 ~ MG-0040)
  static const Color indiaPrimary = Color(0xFFFF5722);
  static const Color indiaSecondary = Color(0xFFFF8A65);
  static const Color indiaAccent = Color(0xFFFFEB3B);

  // Emerging - LATAM (MG-0041 ~ MG-0044)
  static const Color latamPrimary = Color(0xFFE91E63);
  static const Color latamSecondary = Color(0xFFF48FB1);
  static const Color latamAccent = Color(0xFF4CAF50);

  // Emerging - SEA (MG-0045 ~ MG-0048)
  static const Color seaPrimary = Color(0xFF00BCD4);
  static const Color seaSecondary = Color(0xFF4DD0E1);
  static const Color seaAccent = Color(0xFFFF9800);

  // Emerging - Africa (MG-0049 ~ MG-0052)
  static const Color africaPrimary = Color(0xFFFFC107);
  static const Color africaSecondary = Color(0xFFFFD54F);
  static const Color africaAccent = Color(0xFF4CAF50);

  // ============================================================
  // Text Colors (텍스트 컬러)
  // ============================================================
  static const Color textHighEmphasis = Color(0xFFFFFFFF);
  static const Color textMediumEmphasis = Color(0xB3FFFFFF); // 70%
  static const Color textDisabled = Color(0x61FFFFFF); // 38%

  // ============================================================
  // Background Colors (배경 컬러)
  // ============================================================
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  // HUD용 배경/테두리 색상
  static const Color surface = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF424242);

  // ============================================================
  // Game-specific Colors (게임별 특수 컬러)
  // ============================================================

  // Tower Defense (MG-0001)
  static const Color towerDefenseMap = Color(0xFF2E7D32);
  static const Color towerDefensePath = Color(0xFF8D6E63);
  static const Color towerDefenseBase = Color(0xFF1565C0);

  /// 게임 ID로 카테고리 테마 컬러 가져오기
  static CategoryColors getThemeByGameId(String gameId) {
    final id = int.tryParse(gameId) ?? 0;

    if (id >= 1 && id <= 12) {
      return CategoryColors(
        primary: year1Primary,
        secondary: year1Secondary,
        accent: year1Accent,
      );
    } else if (id >= 13 && id <= 24) {
      return CategoryColors(
        primary: year2Primary,
        secondary: year2Secondary,
        accent: year2Accent,
      );
    } else if (id >= 25 && id <= 36) {
      return CategoryColors(
        primary: levelAPrimary,
        secondary: levelASecondary,
        accent: levelAAccent,
      );
    } else if (id >= 37 && id <= 40) {
      return CategoryColors(
        primary: indiaPrimary,
        secondary: indiaSecondary,
        accent: indiaAccent,
      );
    } else if (id >= 41 && id <= 44) {
      return CategoryColors(
        primary: latamPrimary,
        secondary: latamSecondary,
        accent: latamAccent,
      );
    } else if (id >= 45 && id <= 48) {
      return CategoryColors(
        primary: seaPrimary,
        secondary: seaSecondary,
        accent: seaAccent,
      );
    } else if (id >= 49 && id <= 52) {
      return CategoryColors(
        primary: africaPrimary,
        secondary: africaSecondary,
        accent: africaAccent,
      );
    }

    // 기본값: Year 1
    return CategoryColors(
      primary: year1Primary,
      secondary: year1Secondary,
      accent: year1Accent,
    );
  }

  /// 레어리티 컬러 가져오기
  static Color getRarityColor(RarityLevel rarity) {
    return switch (rarity) {
      RarityLevel.common => common,
      RarityLevel.uncommon => uncommon,
      RarityLevel.rare => rare,
      RarityLevel.epic => epic,
      RarityLevel.legendary => legendary,
      RarityLevel.mythic => mythic,
    };
  }
}

/// 카테고리별 컬러 세트
class CategoryColors {
  final Color primary;
  final Color secondary;
  final Color accent;

  const CategoryColors({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

/// 레어리티 레벨
enum RarityLevel {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

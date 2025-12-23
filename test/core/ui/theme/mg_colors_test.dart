import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';

void main() {
  group('MGColors', () {
    group('semantic colors', () {
      test('success color is defined', () {
        expect(MGColors.success, isA<Color>());
      });

      test('warning color is defined', () {
        expect(MGColors.warning, isA<Color>());
      });

      test('error color is defined', () {
        expect(MGColors.error, isA<Color>());
      });

      test('info color is defined', () {
        expect(MGColors.info, isA<Color>());
      });
    });

    group('resource colors', () {
      test('gold color is defined', () {
        expect(MGColors.gold, isA<Color>());
      });

      test('gem color is defined', () {
        expect(MGColors.gem, isA<Color>());
      });

      test('energy color is defined', () {
        expect(MGColors.energy, isA<Color>());
      });

      test('exp color is defined', () {
        expect(MGColors.exp, isA<Color>());
      });
    });

    group('rarity colors', () {
      test('all rarity colors are defined', () {
        expect(MGColors.common, isA<Color>());
        expect(MGColors.uncommon, isA<Color>());
        expect(MGColors.rare, isA<Color>());
        expect(MGColors.epic, isA<Color>());
        expect(MGColors.legendary, isA<Color>());
        expect(MGColors.mythic, isA<Color>());
      });

      test('getRarityColor returns correct colors', () {
        expect(MGColors.getRarityColor(RarityLevel.common), equals(MGColors.common));
        expect(MGColors.getRarityColor(RarityLevel.legendary), equals(MGColors.legendary));
      });
    });

    group('getThemeByGameId', () {
      test('returns Year1 theme for games 1-12', () {
        final theme = MGColors.getThemeByGameId('1');
        expect(theme, isA<CategoryColors>());
        expect(theme.primary, equals(MGColors.year1Primary));
      });

      test('returns Year2 theme for games 13-24', () {
        final theme = MGColors.getThemeByGameId('15');
        expect(theme, isA<CategoryColors>());
        expect(theme.primary, equals(MGColors.year2Primary));
      });

      test('returns LevelA theme for games 25-36', () {
        final theme = MGColors.getThemeByGameId('30');
        expect(theme, isA<CategoryColors>());
        expect(theme.primary, equals(MGColors.levelAPrimary));
      });

      test('returns Emerging theme for games 37-52', () {
        final theme = MGColors.getThemeByGameId('45');
        expect(theme, isA<CategoryColors>());
        // SEA region (45-48)
        expect(theme.primary, equals(MGColors.seaPrimary));
      });

      test('returns Year1 theme for unknown game IDs', () {
        final theme = MGColors.getThemeByGameId('9999');
        expect(theme, isA<CategoryColors>());
        expect(theme.primary, equals(MGColors.year1Primary));
      });
    });
  });

  group('CategoryColors', () {
    test('has primary color', () {
      const theme = CategoryColors(
        primary: Colors.blue,
        secondary: Colors.lightBlue,
        accent: Colors.cyan,
      );

      expect(theme.primary, equals(Colors.blue));
    });

    test('has secondary color', () {
      const theme = CategoryColors(
        primary: Colors.blue,
        secondary: Colors.lightBlue,
        accent: Colors.cyan,
      );

      expect(theme.secondary, equals(Colors.lightBlue));
    });

    test('has accent color', () {
      const theme = CategoryColors(
        primary: Colors.blue,
        secondary: Colors.lightBlue,
        accent: Colors.cyan,
      );

      expect(theme.accent, equals(Colors.cyan));
    });
  });

  group('RarityLevel', () {
    test('all rarity values exist', () {
      expect(RarityLevel.values.length, equals(6));
      expect(RarityLevel.values, contains(RarityLevel.common));
      expect(RarityLevel.values, contains(RarityLevel.uncommon));
      expect(RarityLevel.values, contains(RarityLevel.rare));
      expect(RarityLevel.values, contains(RarityLevel.epic));
      expect(RarityLevel.values, contains(RarityLevel.legendary));
      expect(RarityLevel.values, contains(RarityLevel.mythic));
    });
  });
}

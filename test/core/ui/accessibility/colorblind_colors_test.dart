import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/accessibility/colorblind_colors.dart';

void main() {
  group('ColorBlindType', () {
    test('모든 타입 정의', () {
      expect(ColorBlindType.values.length, 3);
      expect(ColorBlindType.deuteranopia, isNotNull);
      expect(ColorBlindType.protanopia, isNotNull);
      expect(ColorBlindType.tritanopia, isNotNull);
    });

    test('displayName 반환', () {
      expect(ColorBlindType.deuteranopia.displayName, '적록 색맹');
      expect(ColorBlindType.protanopia.displayName, '적색맹');
      expect(ColorBlindType.tritanopia.displayName, '청황 색맹');
    });
  });

  group('RarityPattern', () {
    test('모든 패턴 정의', () {
      expect(RarityPattern.values.length, 6);
      expect(RarityPattern.none, isNotNull);
      expect(RarityPattern.dots, isNotNull);
      expect(RarityPattern.stripes, isNotNull);
      expect(RarityPattern.gradient, isNotNull);
      expect(RarityPattern.glow, isNotNull);
      expect(RarityPattern.shimmer, isNotNull);
    });
  });

  group('RarityStyleColorblind', () {
    test('기본 생성', () {
      const style = RarityStyleColorblind(
        color: Colors.blue,
        icon: '★',
        pattern: RarityPattern.glow,
      );

      expect(style.color, Colors.blue);
      expect(style.icon, '★');
      expect(style.pattern, RarityPattern.glow);
    });
  });

  group('ColorBlindPalette', () {
    test('기본 생성', () {
      const palette = ColorBlindPalette(
        primary: Colors.blue,
        secondary: Colors.orange,
        success: Colors.cyan,
        error: Colors.deepOrange,
        warning: Colors.yellow,
      );

      expect(palette.primary, Colors.blue);
      expect(palette.secondary, Colors.orange);
      expect(palette.success, Colors.cyan);
      expect(palette.error, Colors.deepOrange);
      expect(palette.warning, Colors.yellow);
    });
  });

  group('ColorBlindColors', () {
    group('static colors', () {
      test('success 컬러 정의', () {
        expect(ColorBlindColors.successNormal, const Color(0xFF4CAF50));
        expect(ColorBlindColors.successColorblind, const Color(0xFF00ACC1));
      });

      test('error 컬러 정의', () {
        expect(ColorBlindColors.errorNormal, const Color(0xFFF44336));
        expect(ColorBlindColors.errorColorblind, const Color(0xFFFF6D00));
      });

      test('warning 컬러 정의', () {
        expect(ColorBlindColors.warningNormal, const Color(0xFFFF9800));
        expect(ColorBlindColors.warningColorblind, const Color(0xFFFF9800));
      });

      test('info 컬러 정의', () {
        expect(ColorBlindColors.infoNormal, const Color(0xFF2196F3));
        expect(ColorBlindColors.infoColorblind, const Color(0xFF2196F3));
      });
    });

    group('rarityStyles', () {
      test('모든 레어리티 스타일 정의', () {
        expect(ColorBlindColors.rarityStyles.length, 6);
        expect(ColorBlindColors.rarityStyles['common'], isNotNull);
        expect(ColorBlindColors.rarityStyles['uncommon'], isNotNull);
        expect(ColorBlindColors.rarityStyles['rare'], isNotNull);
        expect(ColorBlindColors.rarityStyles['epic'], isNotNull);
        expect(ColorBlindColors.rarityStyles['legendary'], isNotNull);
        expect(ColorBlindColors.rarityStyles['mythic'], isNotNull);
      });

      test('common 스타일', () {
        final style = ColorBlindColors.rarityStyles['common']!;
        expect(style.color, const Color(0xFF9E9E9E));
        expect(style.icon, '○');
        expect(style.pattern, RarityPattern.none);
      });

      test('uncommon 스타일', () {
        final style = ColorBlindColors.rarityStyles['uncommon']!;
        expect(style.color, const Color(0xFF00BCD4));
        expect(style.icon, '◇');
        expect(style.pattern, RarityPattern.dots);
      });

      test('rare 스타일', () {
        final style = ColorBlindColors.rarityStyles['rare']!;
        expect(style.color, const Color(0xFF2196F3));
        expect(style.icon, '☆');
        expect(style.pattern, RarityPattern.stripes);
      });

      test('epic 스타일', () {
        final style = ColorBlindColors.rarityStyles['epic']!;
        expect(style.color, const Color(0xFF9C27B0));
        expect(style.icon, '◆');
        expect(style.pattern, RarityPattern.gradient);
      });

      test('legendary 스타일', () {
        final style = ColorBlindColors.rarityStyles['legendary']!;
        expect(style.color, const Color(0xFFFF9800));
        expect(style.icon, '★');
        expect(style.pattern, RarityPattern.glow);
      });

      test('mythic 스타일', () {
        final style = ColorBlindColors.rarityStyles['mythic']!;
        expect(style.color, const Color(0xFFFF6D00));
        expect(style.icon, '✦');
        expect(style.pattern, RarityPattern.shimmer);
      });
    });

    group('palettes', () {
      test('deuteranopia 팔레트', () {
        final palette = ColorBlindColors.deuteranopiaColors;
        expect(palette.primary, const Color(0xFF2196F3));
        expect(palette.secondary, const Color(0xFFFF9800));
        expect(palette.success, const Color(0xFF00ACC1));
        expect(palette.error, const Color(0xFFFF6D00));
        expect(palette.warning, const Color(0xFFFFEB3B));
      });

      test('protanopia 팔레트', () {
        final palette = ColorBlindColors.protanopiaColors;
        expect(palette.primary, const Color(0xFF2196F3));
        expect(palette.secondary, const Color(0xFFFFEB3B));
        expect(palette.success, const Color(0xFF00BCD4));
        expect(palette.error, const Color(0xFFFF9800));
        expect(palette.warning, const Color(0xFFFFEB3B));
      });

      test('tritanopia 팔레트', () {
        final palette = ColorBlindColors.tritanopiaColors;
        expect(palette.primary, const Color(0xFFE91E63));
        expect(palette.secondary, const Color(0xFF4CAF50));
        expect(palette.success, const Color(0xFF4CAF50));
        expect(palette.error, const Color(0xFFE91E63));
        expect(palette.warning, const Color(0xFFFF5722));
      });
    });

    group('getPalette', () {
      test('deuteranopia 타입으로 팔레트 가져오기', () {
        final palette = ColorBlindColors.getPalette(ColorBlindType.deuteranopia);
        expect(palette.primary, ColorBlindColors.deuteranopiaColors.primary);
      });

      test('protanopia 타입으로 팔레트 가져오기', () {
        final palette = ColorBlindColors.getPalette(ColorBlindType.protanopia);
        expect(palette.primary, ColorBlindColors.protanopiaColors.primary);
      });

      test('tritanopia 타입으로 팔레트 가져오기', () {
        final palette = ColorBlindColors.getPalette(ColorBlindType.tritanopia);
        expect(palette.primary, ColorBlindColors.tritanopiaColors.primary);
      });
    });

    group('getAccessibleColor', () {
      test('colorBlindMode가 false면 원본 컬러 반환', () {
        final result = ColorBlindColors.getAccessibleColor(
          ColorBlindColors.successNormal,
          colorBlindMode: false,
        );
        expect(result, ColorBlindColors.successNormal);
      });

      test('colorBlindMode가 true이고 success 컬러면 색맹 대응 컬러 반환', () {
        final result = ColorBlindColors.getAccessibleColor(
          ColorBlindColors.successNormal,
          colorBlindMode: true,
        );
        expect(result, ColorBlindColors.successColorblind);
      });

      test('colorBlindMode가 true이고 error 컬러면 색맹 대응 컬러 반환', () {
        final result = ColorBlindColors.getAccessibleColor(
          ColorBlindColors.errorNormal,
          colorBlindMode: true,
        );
        expect(result, ColorBlindColors.errorColorblind);
      });

      test('colorBlindMode가 true지만 매핑되지 않은 컬러면 원본 반환', () {
        const customColor = Color(0xFF123456);
        final result = ColorBlindColors.getAccessibleColor(
          customColor,
          colorBlindMode: true,
        );
        expect(result, customColor);
      });

      test('warning 컬러는 색맹 모드에서도 동일', () {
        final result = ColorBlindColors.getAccessibleColor(
          ColorBlindColors.warningNormal,
          colorBlindMode: true,
        );
        // warning은 매핑되지 않으므로 원본 반환
        expect(result, ColorBlindColors.warningNormal);
      });

      test('info 컬러는 색맹 모드에서도 동일', () {
        final result = ColorBlindColors.getAccessibleColor(
          ColorBlindColors.infoNormal,
          colorBlindMode: true,
        );
        // info는 매핑되지 않으므로 원본 반환
        expect(result, ColorBlindColors.infoNormal);
      });
    });
  });
}

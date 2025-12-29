import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/layout/mg_spacing.dart';

void main() {
  group('MGSpacing Constants', () {
    group('간격 상수', () {
      test('xxs = 4', () {
        expect(MGSpacing.xxs, 4);
      });

      test('xs = 8', () {
        expect(MGSpacing.xs, 8);
      });

      test('sm = 12', () {
        expect(MGSpacing.sm, 12);
      });

      test('md = 16', () {
        expect(MGSpacing.md, 16);
      });

      test('lg = 24', () {
        expect(MGSpacing.lg, 24);
      });

      test('xl = 32', () {
        expect(MGSpacing.xl, 32);
      });

      test('xxl = 48', () {
        expect(MGSpacing.xxl, 48);
      });
    });

    group('마진 상수', () {
      test('screenMarginPortrait = 16', () {
        expect(MGSpacing.screenMarginPortrait, 16);
      });

      test('screenMarginLandscape = 24', () {
        expect(MGSpacing.screenMarginLandscape, 24);
      });

      test('cardPadding = 16', () {
        expect(MGSpacing.cardPadding, 16);
      });

      test('buttonPaddingH = 16', () {
        expect(MGSpacing.buttonPaddingH, 16);
      });

      test('buttonPaddingV = 12', () {
        expect(MGSpacing.buttonPaddingV, 12);
      });
    });

    group('그리드 상수', () {
      test('columnsPortrait = 4', () {
        expect(MGSpacing.columnsPortrait, 4);
      });

      test('columnsLandscape = 6', () {
        expect(MGSpacing.columnsLandscape, 6);
      });

      test('columnGapPortrait = 8', () {
        expect(MGSpacing.columnGapPortrait, 8);
      });

      test('columnGapLandscape = 12', () {
        expect(MGSpacing.columnGapLandscape, 12);
      });
    });

    group('Safe Area 상수', () {
      test('hudMargin = 8', () {
        expect(MGSpacing.hudMargin, 8);
      });

      test('buttonMargin = 16', () {
        expect(MGSpacing.buttonMargin, 16);
      });

      test('textMargin = 16', () {
        expect(MGSpacing.textMargin, 16);
      });

      test('modalMargin = 24', () {
        expect(MGSpacing.modalMargin, 24);
      });
    });
  });

  group('MGSpacing EdgeInsets Helpers', () {
    test('all() 모든 방향 패딩', () {
      final padding = MGSpacing.all(10);
      expect(padding, const EdgeInsets.all(10));
    });

    test('horizontal() 수평 패딩', () {
      final padding = MGSpacing.horizontal(20);
      expect(padding, const EdgeInsets.symmetric(horizontal: 20));
    });

    test('vertical() 수직 패딩', () {
      final padding = MGSpacing.vertical(15);
      expect(padding, const EdgeInsets.symmetric(vertical: 15));
    });

    test('symmetric() 수평/수직 패딩', () {
      final padding = MGSpacing.symmetric(horizontal: 10, vertical: 20);
      expect(padding, const EdgeInsets.symmetric(horizontal: 10, vertical: 20));
    });

    test('symmetric() 기본값', () {
      final padding = MGSpacing.symmetric();
      expect(padding, EdgeInsets.zero);
    });

    test('screenPaddingPortrait', () {
      final padding = MGSpacing.screenPaddingPortrait;
      expect(padding, const EdgeInsets.symmetric(horizontal: 16));
    });

    test('screenPaddingLandscape', () {
      final padding = MGSpacing.screenPaddingLandscape;
      expect(padding, const EdgeInsets.symmetric(horizontal: 24));
    });

    test('cardEdgePadding', () {
      final padding = MGSpacing.cardEdgePadding;
      expect(padding, const EdgeInsets.all(16));
    });

    test('buttonEdgePadding', () {
      final padding = MGSpacing.buttonEdgePadding;
      expect(padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 12));
    });
  });

  group('MGSpacing SizedBox Helpers', () {
    test('horizontalSpace() 수평 간격', () {
      final box = MGSpacing.horizontalSpace(25);
      expect(box.width, 25);
      expect(box.height, null);
    });

    test('verticalSpace() 수직 간격', () {
      final box = MGSpacing.verticalSpace(30);
      expect(box.width, null);
      expect(box.height, 30);
    });

    group('수평 간격 getters', () {
      test('hXxs', () {
        final box = MGSpacing.hXxs;
        expect(box.width, 4);
      });

      test('hXs', () {
        final box = MGSpacing.hXs;
        expect(box.width, 8);
      });

      test('hSm', () {
        final box = MGSpacing.hSm;
        expect(box.width, 12);
      });

      test('hMd', () {
        final box = MGSpacing.hMd;
        expect(box.width, 16);
      });

      test('hLg', () {
        final box = MGSpacing.hLg;
        expect(box.width, 24);
      });
    });

    group('수직 간격 getters', () {
      test('vXxs', () {
        final box = MGSpacing.vXxs;
        expect(box.height, 4);
      });

      test('vXs', () {
        final box = MGSpacing.vXs;
        expect(box.height, 8);
      });

      test('vSm', () {
        final box = MGSpacing.vSm;
        expect(box.height, 12);
      });

      test('vMd', () {
        final box = MGSpacing.vMd;
        expect(box.height, 16);
      });

      test('vLg', () {
        final box = MGSpacing.vLg;
        expect(box.height, 24);
      });

      test('vXl', () {
        final box = MGSpacing.vXl;
        expect(box.height, 32);
      });

      test('vXxl', () {
        final box = MGSpacing.vXxl;
        expect(box.height, 48);
      });
    });
  });
}

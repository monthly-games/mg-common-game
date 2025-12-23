import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';
import 'package:mg_common_game/core/ui/accessibility/colorblind_colors.dart';

void main() {
  group('MGAccessibilitySettings', () {
    test('default settings have correct values', () {
      const settings = MGAccessibilitySettings();

      expect(settings.colorBlindModeEnabled, isFalse);
      expect(settings.highContrastEnabled, isFalse);
      expect(settings.textScaleOption, equals(TextScaleOption.medium));
      expect(settings.reduceMotion, isFalse);
      expect(settings.subtitlesEnabled, isFalse);
      expect(settings.touchAreaSize, equals(TouchAreaSize.medium));
      expect(settings.oneHandedMode, isFalse);
      expect(settings.hapticFeedbackEnabled, isTrue);
    });

    test('copyWith creates new instance with modified values', () {
      const original = MGAccessibilitySettings();
      final modified = original.copyWith(
        colorBlindModeEnabled: true,
        textScaleOption: TextScaleOption.large,
      );

      expect(modified.colorBlindModeEnabled, isTrue);
      expect(modified.textScaleOption, equals(TextScaleOption.large));
      // Original should be unchanged
      expect(original.colorBlindModeEnabled, isFalse);
      expect(original.textScaleOption, equals(TextScaleOption.medium));
    });

    test('toJson returns correct map', () {
      const settings = MGAccessibilitySettings(
        colorBlindModeEnabled: true,
        colorBlindType: ColorBlindType.protanopia,
        textScaleOption: TextScaleOption.large,
      );

      final json = settings.toJson();

      expect(json['colorBlindModeEnabled'], isTrue);
      expect(json['colorBlindType'], equals(ColorBlindType.protanopia.index));
      expect(json['textScaleOption'], equals(TextScaleOption.large.index));
    });

    test('fromJson creates correct instance', () {
      final json = {
        'colorBlindModeEnabled': true,
        'colorBlindType': ColorBlindType.tritanopia.index,
        'highContrastEnabled': true,
        'textScaleOption': TextScaleOption.extraLarge.index,
        'hapticFeedbackEnabled': false,
      };

      final settings = MGAccessibilitySettings.fromJson(json);

      expect(settings.colorBlindModeEnabled, isTrue);
      expect(settings.colorBlindType, equals(ColorBlindType.tritanopia));
      expect(settings.highContrastEnabled, isTrue);
      expect(settings.textScaleOption, equals(TextScaleOption.extraLarge));
      expect(settings.hapticFeedbackEnabled, isFalse);
    });

    test('fromJson handles missing values with defaults', () {
      final json = <String, dynamic>{};

      final settings = MGAccessibilitySettings.fromJson(json);

      expect(settings.colorBlindModeEnabled, isFalse);
      expect(settings.textScaleOption, equals(TextScaleOption.medium));
      expect(settings.hapticFeedbackEnabled, isTrue);
    });

    group('presets', () {
      test('lowVision preset has correct settings', () {
        const settings = MGAccessibilitySettings.lowVision;

        expect(settings.highContrastEnabled, isTrue);
        expect(settings.textScaleOption, equals(TextScaleOption.large));
        expect(settings.reduceMotion, isTrue);
        expect(settings.touchAreaSize, equals(TouchAreaSize.large));
      });

      test('deaf preset has correct settings', () {
        const settings = MGAccessibilitySettings.deaf;

        expect(settings.subtitlesEnabled, isTrue);
        expect(settings.subtitleSize, equals(SubtitleSize.large));
        expect(settings.subtitleBackgroundEnabled, isTrue);
        expect(settings.speakerIndicatorEnabled, isTrue);
        expect(settings.visualSoundEffects, isTrue);
        expect(settings.hapticFeedbackEnabled, isTrue);
      });

      test('motorImpaired preset has correct settings', () {
        const settings = MGAccessibilitySettings.motorImpaired;

        expect(settings.touchAreaSize, equals(TouchAreaSize.extraLarge));
        expect(settings.oneHandedMode, isTrue);
        expect(settings.replaceLongPress, isTrue);
        expect(settings.replaceDrag, isTrue);
        expect(settings.qteTimingMultiplier, equals(2.0));
      });

      test('cognitiveImpaired preset has correct settings', () {
        const settings = MGAccessibilitySettings.cognitiveImpaired;

        expect(settings.reduceMotion, isTrue);
        expect(settings.reduceFlashing, isTrue);
        expect(settings.autoPauseEnabled, isTrue);
        expect(settings.simplifiedUIEnabled, isTrue);
        expect(settings.detailedTutorials, isTrue);
      });

      test('colorBlind factory creates correct settings', () {
        final settings = MGAccessibilitySettings.colorBlind(ColorBlindType.deuteranopia);

        expect(settings.colorBlindModeEnabled, isTrue);
        expect(settings.colorBlindType, equals(ColorBlindType.deuteranopia));
      });
    });
  });

  group('TextScaleOption', () {
    test('scale values are correct', () {
      expect(TextScaleOption.small.scale, equals(0.85));
      expect(TextScaleOption.medium.scale, equals(1.0));
      expect(TextScaleOption.large.scale, equals(1.15));
      expect(TextScaleOption.extraLarge.scale, equals(1.3));
      expect(TextScaleOption.huge.scale, equals(1.5));
    });

    test('displayName values are correct', () {
      expect(TextScaleOption.small.displayName, equals('작게'));
      expect(TextScaleOption.medium.displayName, equals('보통'));
      expect(TextScaleOption.large.displayName, equals('크게'));
    });
  });

  group('SubtitleSize', () {
    test('fontSize values are correct', () {
      expect(SubtitleSize.small.fontSize, equals(14));
      expect(SubtitleSize.medium.fontSize, equals(18));
      expect(SubtitleSize.large.fontSize, equals(22));
      expect(SubtitleSize.extraLarge.fontSize, equals(28));
    });
  });

  group('TouchAreaSize', () {
    test('minSize values are correct', () {
      expect(TouchAreaSize.small.minSize, equals(36));
      expect(TouchAreaSize.medium.minSize, equals(44));
      expect(TouchAreaSize.large.minSize, equals(56));
      expect(TouchAreaSize.extraLarge.minSize, equals(72));
    });
  });
}

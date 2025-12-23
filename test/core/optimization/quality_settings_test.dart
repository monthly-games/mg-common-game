import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/optimization/quality_settings.dart';
import 'package:mg_common_game/core/optimization/device_capability.dart';

void main() {
  group('MGQualitySettings', () {
    test('default settings have correct values', () {
      const settings = MGQualitySettings();

      expect(settings.particleQuality, equals(1.0));
      expect(settings.maxParticles, equals(500));
      expect(settings.textureQuality, equals(TextureQuality.high));
      expect(settings.shadowsEnabled, isTrue);
      expect(settings.targetFps, equals(60));
    });

    group('presets', () {
      test('low preset has reduced settings', () {
        const settings = MGQualitySettings.low;

        expect(settings.particleQuality, equals(0.3));
        expect(settings.maxParticles, equals(100));
        expect(settings.textureQuality, equals(TextureQuality.low));
        expect(settings.shadowsEnabled, isFalse);
        expect(settings.postProcessingEnabled, isFalse);
        expect(settings.targetFps, equals(30));
        expect(settings.imageCacheSizeMB, equals(30));
      });

      test('medium preset has balanced settings', () {
        const settings = MGQualitySettings.medium;

        expect(settings.particleQuality, equals(0.6));
        expect(settings.maxParticles, equals(300));
        expect(settings.textureQuality, equals(TextureQuality.medium));
        expect(settings.shadowsEnabled, isTrue);
        expect(settings.shadowQuality, equals(0.5));
        expect(settings.targetFps, equals(45));
      });

      test('high preset has maximum settings', () {
        const settings = MGQualitySettings.high;

        expect(settings.particleQuality, equals(1.0));
        expect(settings.maxParticles, equals(500));
        expect(settings.textureQuality, equals(TextureQuality.high));
        expect(settings.shadowsEnabled, isTrue);
        expect(settings.shadowQuality, equals(1.0));
        expect(settings.postProcessingEnabled, isTrue);
        expect(settings.targetFps, equals(60));
      });

      test('batterySaver preset optimizes for power', () {
        const settings = MGQualitySettings.batterySaver;

        expect(settings.particleQuality, equals(0.2));
        expect(settings.maxParticles, equals(50));
        expect(settings.shadowsEnabled, isFalse);
        expect(settings.postProcessingEnabled, isFalse);
        expect(settings.targetFps, equals(30));
        expect(settings.backgroundUpdateInterval, equals(100));
      });
    });

    test('forTier returns correct preset', () {
      expect(MGQualitySettings.forTier(DeviceTier.low), equals(MGQualitySettings.low));
      expect(MGQualitySettings.forTier(DeviceTier.mid), equals(MGQualitySettings.medium));
      expect(MGQualitySettings.forTier(DeviceTier.high), equals(MGQualitySettings.high));
    });

    test('copyWith creates new instance with modified values', () {
      const original = MGQualitySettings.medium;
      final modified = original.copyWith(
        targetFps: 60,
        shadowsEnabled: false,
      );

      expect(modified.targetFps, equals(60));
      expect(modified.shadowsEnabled, isFalse);
      // Other values should remain
      expect(modified.particleQuality, equals(0.6));
      expect(modified.maxParticles, equals(300));
    });

    test('toJson returns correct map', () {
      const settings = MGQualitySettings(
        particleQuality: 0.8,
        maxParticles: 400,
        targetFps: 45,
      );

      final json = settings.toJson();

      expect(json['particleQuality'], equals(0.8));
      expect(json['maxParticles'], equals(400));
      expect(json['targetFps'], equals(45));
    });

    test('fromJson creates correct instance', () {
      final json = {
        'particleQuality': 0.7,
        'maxParticles': 350,
        'textureQuality': TextureQuality.medium.index,
        'targetFps': 50,
        'shadowsEnabled': false,
      };

      final settings = MGQualitySettings.fromJson(json);

      expect(settings.particleQuality, equals(0.7));
      expect(settings.maxParticles, equals(350));
      expect(settings.textureQuality, equals(TextureQuality.medium));
      expect(settings.targetFps, equals(50));
      expect(settings.shadowsEnabled, isFalse);
    });

    test('fromJson handles missing values with defaults', () {
      final json = <String, dynamic>{};

      final settings = MGQualitySettings.fromJson(json);

      expect(settings.particleQuality, equals(1.0));
      expect(settings.targetFps, equals(60));
      expect(settings.shadowsEnabled, isTrue);
    });
  });

  group('QualityLevel', () {
    test('displayName returns correct values', () {
      expect(QualityLevel.low.displayName, equals('낮음'));
      expect(QualityLevel.medium.displayName, equals('중간'));
      expect(QualityLevel.high.displayName, equals('높음'));
      expect(QualityLevel.ultra.displayName, equals('최고'));
    });

    test('settings returns correct presets', () {
      expect(QualityLevel.low.settings, equals(MGQualitySettings.low));
      expect(QualityLevel.medium.settings, equals(MGQualitySettings.medium));
      expect(QualityLevel.high.settings, equals(MGQualitySettings.high));
    });

    test('ultra settings has enhanced values', () {
      final ultraSettings = QualityLevel.ultra.settings;

      expect(ultraSettings.maxParticles, equals(1000));
      expect(ultraSettings.targetFps, equals(120));
    });
  });
}

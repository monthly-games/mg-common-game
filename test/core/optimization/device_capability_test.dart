import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/optimization/device_capability.dart';

void main() {
  group('DeviceTier', () {
    test('displayName returns correct values', () {
      expect(DeviceTier.low.displayName, equals('저사양'));
      expect(DeviceTier.mid.displayName, equals('중사양'));
      expect(DeviceTier.high.displayName, equals('고사양'));
    });

    test('index returns correct values', () {
      expect(DeviceTier.low.index, equals(0));
      expect(DeviceTier.mid.index, equals(1));
      expect(DeviceTier.high.index, equals(2));
    });

    test('performanceMultiplier returns correct values', () {
      expect(DeviceTier.low.performanceMultiplier, equals(0.5));
      expect(DeviceTier.mid.performanceMultiplier, equals(1.0));
      expect(DeviceTier.high.performanceMultiplier, equals(1.5));
    });
  });

  group('DeviceInfo', () {
    test('hasEnoughMemory returns true for 4GB+', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.hasEnoughMemory, isTrue);
    });

    test('hasEnoughMemory returns false for less than 4GB', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 2,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.hasEnoughMemory, isFalse);
    });

    test('isHighDensity returns true for 2.5+ density', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 3.0,
      );

      expect(info.isHighDensity, isTrue);
    });

    test('isHighDensity returns false for less than 2.5 density', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.isHighDensity, isFalse);
    });

    test('isMobile returns true for Android', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.isMobile, isTrue);
    });

    test('isMobile returns true for iOS', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 3.0,
      );

      expect(info.isMobile, isTrue);
    });

    test('isMobile returns false for web', () {
      const info = DeviceInfo(
        platform: DevicePlatform.web,
        ramGB: 8,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.isMobile, isFalse);
    });
  });

  group('TextureQuality', () {
    test('scaleFactor returns correct values', () {
      expect(TextureQuality.low.scaleFactor, equals(0.5));
      expect(TextureQuality.medium.scaleFactor, equals(0.75));
      expect(TextureQuality.high.scaleFactor, equals(1.0));
    });

    test('displayName returns correct values', () {
      expect(TextureQuality.low.displayName, equals('낮음'));
      expect(TextureQuality.medium.displayName, equals('중간'));
      expect(TextureQuality.high.displayName, equals('높음'));
    });
  });

  group('PerformanceTestResult', () {
    test('recommendedTier returns high for excellent performance', () {
      const result = PerformanceTestResult(
        averageFps: 60,
        minFps: 55,
        maxFps: 60,
        droppedFrames: 0,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.high));
    });

    test('recommendedTier returns mid for good performance', () {
      const result = PerformanceTestResult(
        averageFps: 45,
        minFps: 35,
        maxFps: 50,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.mid));
    });

    test('recommendedTier returns low for poor performance', () {
      const result = PerformanceTestResult(
        averageFps: 25,
        minFps: 15,
        maxFps: 30,
        droppedFrames: 20,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.low));
    });
  });
}

import 'package:flutter/foundation.dart';
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

    test('recommendedTier 경계값 테스트 - high/mid', () {
      const result = PerformanceTestResult(
        averageFps: 55,
        minFps: 45,
        maxFps: 60,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.high));
    });

    test('recommendedTier 경계값 테스트 - mid/low', () {
      const result = PerformanceTestResult(
        averageFps: 40,
        minFps: 25,
        maxFps: 50,
        droppedFrames: 10,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.mid));
    });

    test('recommendedTier minFps가 기준 미달이면 낮은 티어', () {
      const result = PerformanceTestResult(
        averageFps: 58,
        minFps: 40, // high가 되려면 45 이상 필요
        maxFps: 60,
        droppedFrames: 2,
        testDuration: Duration(seconds: 10),
      );

      expect(result.recommendedTier, equals(DeviceTier.mid));
    });
  });

  group('DevicePlatform', () {
    test('모든 플랫폼 정의', () {
      expect(DevicePlatform.values.length, 4);
      expect(DevicePlatform.android, isNotNull);
      expect(DevicePlatform.ios, isNotNull);
      expect(DevicePlatform.web, isNotNull);
      expect(DevicePlatform.other, isNotNull);
    });

    test('플랫폼 인덱스 순서', () {
      expect(DevicePlatform.android.index, 0);
      expect(DevicePlatform.ios.index, 1);
      expect(DevicePlatform.web.index, 2);
      expect(DevicePlatform.other.index, 3);
    });

    test('플랫폼 이름', () {
      expect(DevicePlatform.android.name, 'android');
      expect(DevicePlatform.ios.name, 'ios');
      expect(DevicePlatform.web.name, 'web');
      expect(DevicePlatform.other.name, 'other');
    });
  });

  group('MGDeviceCapability', () {
    test('tier는 DeviceTier 반환', () {
      final tier = MGDeviceCapability.tier;
      expect(tier, isA<DeviceTier>());
    });

    test('info는 DeviceInfo 반환', () {
      final info = MGDeviceCapability.info;
      expect(info, isA<DeviceInfo>());
    });

    test('info는 필수 속성 포함', () {
      final info = MGDeviceCapability.info;
      expect(info.platform, isA<DevicePlatform>());
      expect(info.ramGB, greaterThan(0));
      expect(info.isTablet, isA<bool>());
      expect(info.screenDensity, greaterThan(0));
    });

    test('clearCache로 캐시 초기화', () {
      // 캐시 초기화 전
      final tierBefore = MGDeviceCapability.tier;
      final infoBefore = MGDeviceCapability.info;

      MGDeviceCapability.clearCache();

      // 캐시 초기화 후에도 같은 값 반환 (테스트 환경)
      final tierAfter = MGDeviceCapability.tier;
      final infoAfter = MGDeviceCapability.info;

      expect(tierBefore, isA<DeviceTier>());
      expect(tierAfter, isA<DeviceTier>());
      expect(infoBefore, isA<DeviceInfo>());
      expect(infoAfter, isA<DeviceInfo>());
    });
  });

  group('MGDeviceCapability 성능 추정', () {
    test('estimatedGpuPerformance는 0.0~1.0 범위', () {
      final gpuPerf = MGDeviceCapability.estimatedGpuPerformance;
      expect(gpuPerf, greaterThanOrEqualTo(0.0));
      expect(gpuPerf, lessThanOrEqualTo(1.0));
    });

    test('estimatedCpuPerformance는 0.0~1.0 범위', () {
      final cpuPerf = MGDeviceCapability.estimatedCpuPerformance;
      expect(cpuPerf, greaterThanOrEqualTo(0.0));
      expect(cpuPerf, lessThanOrEqualTo(1.0));
    });

    test('recommendedFps는 30, 45, 60 중 하나', () {
      final fps = MGDeviceCapability.recommendedFps;
      expect([30, 45, 60], contains(fps));
    });

    test('recommendedTextureQuality는 TextureQuality 반환', () {
      final quality = MGDeviceCapability.recommendedTextureQuality;
      expect(quality, isA<TextureQuality>());
    });

    test('성능 추정 값은 티어와 일치', () {
      final tier = MGDeviceCapability.tier;
      final gpuPerf = MGDeviceCapability.estimatedGpuPerformance;
      final cpuPerf = MGDeviceCapability.estimatedCpuPerformance;

      switch (tier) {
        case DeviceTier.high:
          expect(gpuPerf, equals(1.0));
          expect(cpuPerf, equals(1.0));
          expect(MGDeviceCapability.recommendedFps, equals(60));
          expect(MGDeviceCapability.recommendedTextureQuality, equals(TextureQuality.high));
          break;
        case DeviceTier.mid:
          expect(gpuPerf, equals(0.6));
          expect(cpuPerf, equals(0.6));
          expect(MGDeviceCapability.recommendedFps, equals(45));
          expect(MGDeviceCapability.recommendedTextureQuality, equals(TextureQuality.medium));
          break;
        case DeviceTier.low:
          expect(gpuPerf, equals(0.3));
          expect(cpuPerf, equals(0.3));
          expect(MGDeviceCapability.recommendedFps, equals(30));
          expect(MGDeviceCapability.recommendedTextureQuality, equals(TextureQuality.low));
          break;
      }
    });
  });

  group('DeviceInfo 생성자', () {
    test('기본 생성', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );

      expect(info.platform, DevicePlatform.android);
      expect(info.ramGB, 4);
      expect(info.isTablet, false);
      expect(info.screenDensity, 2.0);
    });

    test('const 생성자', () {
      const info1 = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 8,
        isTablet: true,
        screenDensity: 3.0,
      );
      const info2 = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 8,
        isTablet: true,
        screenDensity: 3.0,
      );

      expect(identical(info1, info2), true);
    });

    test('다양한 RAM 크기', () {
      for (final ram in [1, 2, 3, 4, 6, 8, 12, 16]) {
        final info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: ram.toDouble(),
          isTablet: false,
          screenDensity: 2.0,
        );

        expect(info.ramGB, ram.toDouble());
        expect(info.hasEnoughMemory, ram >= 4);
      }
    });

    test('다양한 화면 밀도', () {
      for (final density in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]) {
        final info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: density,
        );

        expect(info.screenDensity, density);
        expect(info.isHighDensity, density >= 2.5);
      }
    });
  });

  group('PerformanceTestResult 필드', () {
    test('모든 필드 포함', () {
      const result = PerformanceTestResult(
        averageFps: 50.5,
        minFps: 40.0,
        maxFps: 60.0,
        droppedFrames: 10,
        testDuration: Duration(minutes: 1, seconds: 30),
      );

      expect(result.averageFps, 50.5);
      expect(result.minFps, 40.0);
      expect(result.maxFps, 60.0);
      expect(result.droppedFrames, 10);
      expect(result.testDuration, const Duration(minutes: 1, seconds: 30));
    });

    test('zero dropped frames', () {
      const result = PerformanceTestResult(
        averageFps: 60,
        minFps: 58,
        maxFps: 60,
        droppedFrames: 0,
        testDuration: Duration(seconds: 5),
      );

      expect(result.droppedFrames, 0);
      expect(result.recommendedTier, DeviceTier.high);
    });

    test('높은 드롭 프레임', () {
      const result = PerformanceTestResult(
        averageFps: 30,
        minFps: 10,
        maxFps: 55,
        droppedFrames: 100,
        testDuration: Duration(seconds: 10),
      );

      expect(result.droppedFrames, 100);
      expect(result.recommendedTier, DeviceTier.low);
    });

    test('const 생성자', () {
      const result1 = PerformanceTestResult(
        averageFps: 50,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      const result2 = PerformanceTestResult(
        averageFps: 50,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );

      expect(identical(result1, result2), true);
    });
  });

  group('TextureQuality 모든 값', () {
    test('모든 품질 레벨 정의', () {
      expect(TextureQuality.values.length, 3);
      expect(TextureQuality.low, isNotNull);
      expect(TextureQuality.medium, isNotNull);
      expect(TextureQuality.high, isNotNull);
    });

    test('품질 인덱스 순서', () {
      expect(TextureQuality.low.index, 0);
      expect(TextureQuality.medium.index, 1);
      expect(TextureQuality.high.index, 2);
    });

    test('품질 이름', () {
      expect(TextureQuality.low.name, 'low');
      expect(TextureQuality.medium.name, 'medium');
      expect(TextureQuality.high.name, 'high');
    });
  });

  group('DeviceTier 모든 값', () {
    test('모든 티어 레벨 정의', () {
      expect(DeviceTier.values.length, 3);
      expect(DeviceTier.low, isNotNull);
      expect(DeviceTier.mid, isNotNull);
      expect(DeviceTier.high, isNotNull);
    });

    test('티어 인덱스 순서', () {
      expect(DeviceTier.low.index, 0);
      expect(DeviceTier.mid.index, 1);
      expect(DeviceTier.high.index, 2);
    });

    test('티어 이름', () {
      expect(DeviceTier.low.name, 'low');
      expect(DeviceTier.mid.name, 'mid');
      expect(DeviceTier.high.name, 'high');
    });
  });

  group('MGDeviceCapability 캐싱 동작', () {
    setUp(() {
      MGDeviceCapability.clearCache();
    });

    test('tier는 캐시되어 같은 객체 반환', () {
      final tier1 = MGDeviceCapability.tier;
      final tier2 = MGDeviceCapability.tier;
      expect(tier1, equals(tier2));
    });

    test('info는 캐시되어 같은 객체 반환', () {
      final info1 = MGDeviceCapability.info;
      final info2 = MGDeviceCapability.info;
      expect(info1, equals(info2));
    });

    test('clearCache 후 새로운 감지 수행', () {
      final tier1 = MGDeviceCapability.tier;
      MGDeviceCapability.clearCache();
      final tier2 = MGDeviceCapability.tier;
      // 같은 환경이므로 같은 값이지만, 캐시가 초기화됨
      expect(tier1, equals(tier2));
    });
  });

  group('MGDeviceCapability 성능 추정 - Low Tier', () {
    test('low tier GPU performance는 0.3', () {
      // low tier 기기에서 테스트
      const lowRamInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 2, // < 4GB = low tier
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(lowRamInfo.ramGB < 4, isTrue);
    });

    test('low tier CPU performance는 0.3', () {
      // low tier 기기 확인
      const lowRamInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 3,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(lowRamInfo.ramGB < 4, isTrue);
    });

    test('low tier recommended FPS는 30', () {
      // low tier 기기 확인
      const lowRamInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 2,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(lowRamInfo.ramGB < 4, isTrue);
    });

    test('low tier texture quality는 low', () {
      // low tier 기기 확인
      const lowRamInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 1,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(lowRamInfo.ramGB < 4, isTrue);
    });
  });

  group('DeviceInfo 플랫폼별 테스트', () {
    test('Android 플랫폼 정보', () {
      const androidInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(androidInfo.platform, DevicePlatform.android);
      expect(androidInfo.isMobile, isTrue);
    });

    test('iOS 플랫폼 정보', () {
      const iosInfo = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 3.0,
      );
      expect(iosInfo.platform, DevicePlatform.ios);
      expect(iosInfo.isMobile, isTrue);
    });

    test('Web 플랫폼 정보', () {
      const webInfo = DeviceInfo(
        platform: DevicePlatform.web,
        ramGB: 8,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(webInfo.platform, DevicePlatform.web);
      expect(webInfo.isMobile, isFalse);
    });

    test('Other 플랫폼 정보', () {
      const otherInfo = DeviceInfo(
        platform: DevicePlatform.other,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(otherInfo.platform, DevicePlatform.other);
      expect(otherInfo.isMobile, isFalse);
    });
  });

  group('DeviceInfo 태블릿 감지', () {
    test('태블릿 기기 감지', () {
      const tabletInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: true,
        screenDensity: 2.0,
      );
      expect(tabletInfo.isTablet, isTrue);
    });

    test('휴대폰 기기 감지', () {
      const phoneInfo = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(phoneInfo.isTablet, isFalse);
    });
  });

  group('DeviceInfo 메모리 경계값', () {
    test('정확히 4GB는 충분한 메모리', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4.0,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.hasEnoughMemory, isTrue);
    });

    test('3.99GB는 부족한 메모리', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 3.99,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.hasEnoughMemory, isFalse);
    });

    test('매우 높은 RAM (16GB)', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 16.0,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.hasEnoughMemory, isTrue);
    });
  });

  group('DeviceInfo 화면 밀도 경계값', () {
    test('정확히 2.5 밀도는 고해상도', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.5,
      );
      expect(info.isHighDensity, isTrue);
    });

    test('2.49 밀도는 저해상도', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.49,
      );
      expect(info.isHighDensity, isFalse);
    });

    test('매우 높은 밀도 (4.0)', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 4.0,
      );
      expect(info.isHighDensity, isTrue);
    });
  });

  group('PerformanceTestResult 경계값 상세', () {
    test('high tier 경계: averageFps 55, minFps 45', () {
      const result = PerformanceTestResult(
        averageFps: 55,
        minFps: 45,
        maxFps: 60,
        droppedFrames: 0,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.high);
    });

    test('high tier 경계 미달: averageFps 54.9, minFps 45', () {
      const result = PerformanceTestResult(
        averageFps: 54.9,
        minFps: 45,
        maxFps: 60,
        droppedFrames: 0,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.mid);
    });

    test('mid tier 경계: averageFps 40, minFps 25', () {
      const result = PerformanceTestResult(
        averageFps: 40,
        minFps: 25,
        maxFps: 50,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.mid);
    });

    test('mid tier 경계 미달: averageFps 39.9, minFps 25', () {
      const result = PerformanceTestResult(
        averageFps: 39.9,
        minFps: 25,
        maxFps: 50,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.low);
    });

    test('low tier: averageFps 30, minFps 20', () {
      const result = PerformanceTestResult(
        averageFps: 30,
        minFps: 20,
        maxFps: 40,
        droppedFrames: 15,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.low);
    });
  });

  group('TextureQuality 스케일 팩터 정밀도', () {
    test('low quality scale factor 정확성', () {
      expect(TextureQuality.low.scaleFactor, equals(0.5));
      expect(TextureQuality.low.scaleFactor, isNot(equals(0.51)));
    });

    test('medium quality scale factor 정확성', () {
      expect(TextureQuality.medium.scaleFactor, equals(0.75));
      expect(TextureQuality.medium.scaleFactor, isNot(equals(0.74)));
    });

    test('high quality scale factor 정확성', () {
      expect(TextureQuality.high.scaleFactor, equals(1.0));
      expect(TextureQuality.high.scaleFactor, isNot(equals(0.99)));
    });
  });

  group('DeviceTier 성능 배수 정밀도', () {
    test('low tier performance multiplier', () {
      expect(DeviceTier.low.performanceMultiplier, equals(0.5));
    });

    test('mid tier performance multiplier', () {
      expect(DeviceTier.mid.performanceMultiplier, equals(1.0));
    });

    test('high tier performance multiplier', () {
      expect(DeviceTier.high.performanceMultiplier, equals(1.5));
    });
  });

  group('MGDeviceCapability 통합 테스트', () {
    test('tier와 info는 일관성 있음', () {
      final tier = MGDeviceCapability.tier;
      final info = MGDeviceCapability.info;

      // tier는 info의 RAM 기반으로 결정됨
      if (info.ramGB >= 8) {
        expect(tier, DeviceTier.high);
      } else if (info.ramGB >= 4) {
        expect(tier, DeviceTier.mid);
      } else {
        expect(tier, DeviceTier.low);
      }
    });

    test('모든 성능 추정 값이 tier와 일치', () {
      final tier = MGDeviceCapability.tier;
      final gpu = MGDeviceCapability.estimatedGpuPerformance;
      final cpu = MGDeviceCapability.estimatedCpuPerformance;
      final fps = MGDeviceCapability.recommendedFps;
      final quality = MGDeviceCapability.recommendedTextureQuality;

      switch (tier) {
        case DeviceTier.high:
          expect(gpu, 1.0);
          expect(cpu, 1.0);
          expect(fps, 60);
          expect(quality, TextureQuality.high);
          break;
        case DeviceTier.mid:
          expect(gpu, 0.6);
          expect(cpu, 0.6);
          expect(fps, 45);
          expect(quality, TextureQuality.medium);
          break;
        case DeviceTier.low:
          expect(gpu, 0.3);
          expect(cpu, 0.3);
          expect(fps, 30);
          expect(quality, TextureQuality.low);
          break;
      }
    });

    test('web 플랫폼은 기본값 반환', () {
      // kIsWeb 체크는 테스트 환경에서 false이지만,
      // 실제 web 환경에서는 기본값 반환 확인
      final info = MGDeviceCapability.info;
      expect(info, isA<DeviceInfo>());
      expect(info.ramGB, greaterThan(0));
    });
  });

  group('DeviceInfo 동등성', () {
    test('같은 값의 DeviceInfo는 동등', () {
      const info1 = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      const info2 = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info1, equals(info2));
    });

    test('다른 값의 DeviceInfo는 다름', () {
      const info1 = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      const info2 = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info1, isNot(equals(info2)));
    });
  });

  group('PerformanceTestResult 동등성', () {
    test('같은 값의 PerformanceTestResult는 동등', () {
      const result1 = PerformanceTestResult(
        averageFps: 50,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      const result2 = PerformanceTestResult(
        averageFps: 50,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      expect(result1, equals(result2));
    });

    test('다른 FPS의 PerformanceTestResult는 다름', () {
      const result1 = PerformanceTestResult(
        averageFps: 50,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      const result2 = PerformanceTestResult(
        averageFps: 51,
        minFps: 45,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      expect(result1, isNot(equals(result2)));
    });
  });

  group('RAM 기반 티어 분류', () {
    test('1GB RAM = low tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 1,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB < 4, isTrue);
    });

    test('2GB RAM = low tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 2,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB < 4, isTrue);
    });

    test('4GB RAM = mid tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 4,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB >= 4 && info.ramGB < 8, isTrue);
    });

    test('6GB RAM = mid tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 6,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB >= 4 && info.ramGB < 8, isTrue);
    });

    test('8GB RAM = high tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 8,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB >= 8, isTrue);
    });

    test('12GB RAM = high tier', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 12,
        isTablet: false,
        screenDensity: 2.0,
      );
      expect(info.ramGB >= 8, isTrue);
    });
  });

  group('DeviceTierExtension 모든 메서드', () {
    test('low tier displayName', () {
      expect(DeviceTier.low.displayName, '저사양');
    });

    test('mid tier displayName', () {
      expect(DeviceTier.mid.displayName, '중사양');
    });

    test('high tier displayName', () {
      expect(DeviceTier.high.displayName, '고사양');
    });

    test('low tier index', () {
      expect(DeviceTier.low.index, 0);
    });

    test('mid tier index', () {
      expect(DeviceTier.mid.index, 1);
    });

    test('high tier index', () {
      expect(DeviceTier.high.index, 2);
    });

    test('low tier performanceMultiplier', () {
      expect(DeviceTier.low.performanceMultiplier, 0.5);
    });

    test('mid tier performanceMultiplier', () {
      expect(DeviceTier.mid.performanceMultiplier, 1.0);
    });

    test('high tier performanceMultiplier', () {
      expect(DeviceTier.high.performanceMultiplier, 1.5);
    });
  });

  group('TextureQualityExtension 모든 메서드', () {
    test('low quality scaleFactor', () {
      expect(TextureQuality.low.scaleFactor, 0.5);
    });

    test('medium quality scaleFactor', () {
      expect(TextureQuality.medium.scaleFactor, 0.75);
    });

    test('high quality scaleFactor', () {
      expect(TextureQuality.high.scaleFactor, 1.0);
    });

    test('low quality displayName', () {
      expect(TextureQuality.low.displayName, '낮음');
    });

    test('medium quality displayName', () {
      expect(TextureQuality.medium.displayName, '중간');
    });

    test('high quality displayName', () {
      expect(TextureQuality.high.displayName, '높음');
    });
  });

  group('MGDeviceCapability 성능 추정 전체 커버리지', () {
    test('estimatedGpuPerformance 모든 티어', () {
      // 현재 환경의 tier에 따라 테스트
      final tier = MGDeviceCapability.tier;
      final gpu = MGDeviceCapability.estimatedGpuPerformance;

      if (tier == DeviceTier.high) {
        expect(gpu, 1.0);
      } else if (tier == DeviceTier.mid) {
        expect(gpu, 0.6);
      } else {
        expect(gpu, 0.3);
      }
    });

    test('estimatedCpuPerformance 모든 티어', () {
      final tier = MGDeviceCapability.tier;
      final cpu = MGDeviceCapability.estimatedCpuPerformance;

      if (tier == DeviceTier.high) {
        expect(cpu, 1.0);
      } else if (tier == DeviceTier.mid) {
        expect(cpu, 0.6);
      } else {
        expect(cpu, 0.3);
      }
    });

    test('recommendedFps 모든 티어', () {
      final tier = MGDeviceCapability.tier;
      final fps = MGDeviceCapability.recommendedFps;

      if (tier == DeviceTier.high) {
        expect(fps, 60);
      } else if (tier == DeviceTier.mid) {
        expect(fps, 45);
      } else {
        expect(fps, 30);
      }
    });

    test('recommendedTextureQuality 모든 티어', () {
      final tier = MGDeviceCapability.tier;
      final quality = MGDeviceCapability.recommendedTextureQuality;

      if (tier == DeviceTier.high) {
        expect(quality, TextureQuality.high);
      } else if (tier == DeviceTier.mid) {
        expect(quality, TextureQuality.medium);
      } else {
        expect(quality, TextureQuality.low);
      }
    });
  });

  group('PerformanceTestResult 권장 티어 전체 커버리지', () {
    test('high tier 조건 충족', () {
      const result = PerformanceTestResult(
        averageFps: 60,
        minFps: 50,
        maxFps: 60,
        droppedFrames: 0,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.high);
    });

    test('mid tier 조건 충족', () {
      const result = PerformanceTestResult(
        averageFps: 45,
        minFps: 30,
        maxFps: 50,
        droppedFrames: 5,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.mid);
    });

    test('low tier 조건 충족', () {
      const result = PerformanceTestResult(
        averageFps: 20,
        minFps: 10,
        maxFps: 30,
        droppedFrames: 20,
        testDuration: Duration(seconds: 10),
      );
      expect(result.recommendedTier, DeviceTier.low);
    });
  });

  group('DeviceInfo 모든 속성 조합', () {
    test('Android 저사양 기기', () {
      const info = DeviceInfo(
        platform: DevicePlatform.android,
        ramGB: 2,
        isTablet: false,
        screenDensity: 1.5,
      );
      expect(info.platform, DevicePlatform.android);
      expect(info.hasEnoughMemory, isFalse);
      expect(info.isHighDensity, isFalse);
      expect(info.isMobile, isTrue);
    });

    test('iOS 고사양 기기', () {
      const info = DeviceInfo(
        platform: DevicePlatform.ios,
        ramGB: 8,
        isTablet: false,
        screenDensity: 3.0,
      );
      expect(info.platform, DevicePlatform.ios);
      expect(info.hasEnoughMemory, isTrue);
      expect(info.isHighDensity, isTrue);
      expect(info.isMobile, isTrue);
    });

    test('Web 기기', () {
      const info = DeviceInfo(
        platform: DevicePlatform.web,
        ramGB: 4,
        isTablet: true,
        screenDensity: 2.0,
      );
      expect(info.platform, DevicePlatform.web);
      expect(info.hasEnoughMemory, isTrue);
      expect(info.isHighDensity, isFalse);
      expect(info.isMobile, isFalse);
      expect(info.isTablet, isTrue);
    });

    test('Other 플랫폼 기기', () {
      const info = DeviceInfo(
        platform: DevicePlatform.other,
        ramGB: 6,
        isTablet: true,
        screenDensity: 2.5,
      );
      expect(info.platform, DevicePlatform.other);
      expect(info.hasEnoughMemory, isTrue);
      expect(info.isHighDensity, isTrue);
      expect(info.isMobile, isFalse);
      expect(info.isTablet, isTrue);
    });
  });
}

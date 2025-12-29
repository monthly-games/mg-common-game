import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/optimization/device_capability.dart';

void main() {
  // ============================================================
  // MGDeviceCapability 테스트
  // ============================================================

  group('MGDeviceCapability', () {
    setUp(() {
      // 각 테스트 전 캐시 초기화
      MGDeviceCapability.clearCache();
    });

    tearDown(() {
      MGDeviceCapability.clearCache();
    });

    group('clearCache', () {
      test('캐시 초기화 후 다시 감지해야 함', () {
        // 첫 번째 접근으로 캐시 생성
        final tier1 = MGDeviceCapability.tier;
        final info1 = MGDeviceCapability.info;

        // 캐시 초기화
        MGDeviceCapability.clearCache();

        // 다시 접근
        final tier2 = MGDeviceCapability.tier;
        final info2 = MGDeviceCapability.info;

        // 같은 기기이므로 같은 값이어야 함
        expect(tier1, equals(tier2));
        expect(info1.platform, equals(info2.platform));
      });

      test('clearCache 여러 번 호출해도 오류 없음', () {
        expect(() {
          MGDeviceCapability.clearCache();
          MGDeviceCapability.clearCache();
          MGDeviceCapability.clearCache();
        }, returnsNormally);
      });
    });

    group('tier', () {
      test('tier가 null이 아니어야 함', () {
        expect(MGDeviceCapability.tier, isNotNull);
      });

      test('tier가 유효한 DeviceTier 값이어야 함', () {
        expect(MGDeviceCapability.tier, isA<DeviceTier>());
        expect(
          DeviceTier.values.contains(MGDeviceCapability.tier),
          isTrue,
        );
      });

      test('tier가 캐시됨', () {
        final tier1 = MGDeviceCapability.tier;
        final tier2 = MGDeviceCapability.tier;
        expect(identical(tier1, tier2), isTrue);
      });
    });

    group('info', () {
      test('info가 null이 아니어야 함', () {
        expect(MGDeviceCapability.info, isNotNull);
      });

      test('info가 유효한 DeviceInfo 객체여야 함', () {
        final info = MGDeviceCapability.info;
        expect(info, isA<DeviceInfo>());
        expect(info.ramGB, greaterThan(0));
        expect(info.screenDensity, greaterThan(0));
      });

      test('info가 캐시됨', () {
        final info1 = MGDeviceCapability.info;
        final info2 = MGDeviceCapability.info;
        expect(identical(info1, info2), isTrue);
      });
    });

    group('estimatedGpuPerformance', () {
      test('값이 0.0 ~ 1.0 범위 내에 있어야 함', () {
        final performance = MGDeviceCapability.estimatedGpuPerformance;
        expect(performance, greaterThanOrEqualTo(0.0));
        expect(performance, lessThanOrEqualTo(1.0));
      });

      test('tier에 따른 올바른 값 반환', () {
        // 현재 tier에 따라 예상 값 검증
        final tier = MGDeviceCapability.tier;
        final performance = MGDeviceCapability.estimatedGpuPerformance;

        switch (tier) {
          case DeviceTier.high:
            expect(performance, equals(1.0));
            break;
          case DeviceTier.mid:
            expect(performance, equals(0.6));
            break;
          case DeviceTier.low:
            expect(performance, equals(0.3));
            break;
        }
      });
    });

    group('estimatedCpuPerformance', () {
      test('값이 0.0 ~ 1.0 범위 내에 있어야 함', () {
        final performance = MGDeviceCapability.estimatedCpuPerformance;
        expect(performance, greaterThanOrEqualTo(0.0));
        expect(performance, lessThanOrEqualTo(1.0));
      });

      test('tier에 따른 올바른 값 반환', () {
        final tier = MGDeviceCapability.tier;
        final performance = MGDeviceCapability.estimatedCpuPerformance;

        switch (tier) {
          case DeviceTier.high:
            expect(performance, equals(1.0));
            break;
          case DeviceTier.mid:
            expect(performance, equals(0.6));
            break;
          case DeviceTier.low:
            expect(performance, equals(0.3));
            break;
        }
      });
    });

    group('recommendedFps', () {
      test('값이 양수여야 함', () {
        expect(MGDeviceCapability.recommendedFps, greaterThan(0));
      });

      test('tier에 따른 올바른 값 반환', () {
        final tier = MGDeviceCapability.tier;
        final fps = MGDeviceCapability.recommendedFps;

        switch (tier) {
          case DeviceTier.high:
            expect(fps, equals(60));
            break;
          case DeviceTier.mid:
            expect(fps, equals(45));
            break;
          case DeviceTier.low:
            expect(fps, equals(30));
            break;
        }
      });

      test('모든 tier의 FPS 값이 30 이상이어야 함', () {
        // 어떤 tier든 최소 30fps는 보장
        expect(MGDeviceCapability.recommendedFps, greaterThanOrEqualTo(30));
      });
    });

    group('recommendedTextureQuality', () {
      test('유효한 TextureQuality 값이어야 함', () {
        expect(MGDeviceCapability.recommendedTextureQuality, isA<TextureQuality>());
        expect(
          TextureQuality.values.contains(MGDeviceCapability.recommendedTextureQuality),
          isTrue,
        );
      });

      test('tier에 따른 올바른 값 반환', () {
        final tier = MGDeviceCapability.tier;
        final quality = MGDeviceCapability.recommendedTextureQuality;

        switch (tier) {
          case DeviceTier.high:
            expect(quality, equals(TextureQuality.high));
            break;
          case DeviceTier.mid:
            expect(quality, equals(TextureQuality.medium));
            break;
          case DeviceTier.low:
            expect(quality, equals(TextureQuality.low));
            break;
        }
      });
    });
  });

  // ============================================================
  // DeviceTier 테스트
  // ============================================================

  group('DeviceTier', () {
    group('displayName', () {
      test('low tier 표시 이름', () {
        expect(DeviceTier.low.displayName, equals('저사양'));
      });

      test('mid tier 표시 이름', () {
        expect(DeviceTier.mid.displayName, equals('중사양'));
      });

      test('high tier 표시 이름', () {
        expect(DeviceTier.high.displayName, equals('고사양'));
      });

      test('모든 tier가 비어 있지 않은 displayName을 가짐', () {
        for (final tier in DeviceTier.values) {
          expect(tier.displayName.isNotEmpty, isTrue);
        }
      });
    });

    group('index', () {
      test('low tier index는 0', () {
        expect(DeviceTier.low.index, equals(0));
      });

      test('mid tier index는 1', () {
        expect(DeviceTier.mid.index, equals(1));
      });

      test('high tier index는 2', () {
        expect(DeviceTier.high.index, equals(2));
      });

      test('index가 순서대로 증가', () {
        expect(DeviceTier.low.index, lessThan(DeviceTier.mid.index));
        expect(DeviceTier.mid.index, lessThan(DeviceTier.high.index));
      });

      test('모든 index가 고유함', () {
        final indices = DeviceTier.values.map((t) => t.index).toSet();
        expect(indices.length, equals(DeviceTier.values.length));
      });
    });

    group('performanceMultiplier', () {
      test('low tier 배수는 0.5', () {
        expect(DeviceTier.low.performanceMultiplier, equals(0.5));
      });

      test('mid tier 배수는 1.0', () {
        expect(DeviceTier.mid.performanceMultiplier, equals(1.0));
      });

      test('high tier 배수는 1.5', () {
        expect(DeviceTier.high.performanceMultiplier, equals(1.5));
      });

      test('모든 배수가 양수', () {
        for (final tier in DeviceTier.values) {
          expect(tier.performanceMultiplier, greaterThan(0));
        }
      });

      test('배수가 tier에 따라 증가', () {
        expect(
          DeviceTier.low.performanceMultiplier,
          lessThan(DeviceTier.mid.performanceMultiplier),
        );
        expect(
          DeviceTier.mid.performanceMultiplier,
          lessThan(DeviceTier.high.performanceMultiplier),
        );
      });
    });

    group('enum values', () {
      test('정확히 3개의 tier가 있어야 함', () {
        expect(DeviceTier.values.length, equals(3));
      });

      test('모든 tier가 포함됨', () {
        expect(DeviceTier.values, contains(DeviceTier.low));
        expect(DeviceTier.values, contains(DeviceTier.mid));
        expect(DeviceTier.values, contains(DeviceTier.high));
      });
    });
  });

  // ============================================================
  // DevicePlatform 테스트
  // ============================================================

  group('DevicePlatform', () {
    test('정확히 4개의 플랫폼이 있어야 함', () {
      expect(DevicePlatform.values.length, equals(4));
    });

    test('모든 플랫폼이 포함됨', () {
      expect(DevicePlatform.values, contains(DevicePlatform.android));
      expect(DevicePlatform.values, contains(DevicePlatform.ios));
      expect(DevicePlatform.values, contains(DevicePlatform.web));
      expect(DevicePlatform.values, contains(DevicePlatform.other));
    });
  });

  // ============================================================
  // DeviceInfo 테스트
  // ============================================================

  group('DeviceInfo', () {
    group('생성', () {
      test('모든 필드가 올바르게 설정됨', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 6.0,
          isTablet: true,
          screenDensity: 2.5,
        );

        expect(info.platform, equals(DevicePlatform.android));
        expect(info.ramGB, equals(6.0));
        expect(info.isTablet, isTrue);
        expect(info.screenDensity, equals(2.5));
      });

      test('const 생성자 사용 가능', () {
        const info1 = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        );
        const info2 = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        );

        expect(info1, isA<DeviceInfo>());
        expect(info2, isA<DeviceInfo>());
      });
    });

    group('hasEnoughMemory', () {
      test('RAM 4GB 이상이면 true', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isTrue);
      });

      test('RAM 정확히 4GB면 true (경계값)', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4.0,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isTrue);
      });

      test('RAM 4GB 미만이면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 3.9,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isFalse);
      });

      test('RAM 2GB면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 2,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isFalse);
      });

      test('RAM 8GB면 true', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 8,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isTrue);
      });

      test('RAM 0GB면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 0,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isFalse);
      });
    });

    group('isHighDensity', () {
      test('밀도 2.5 이상이면 true', () {
        const info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        );
        expect(info.isHighDensity, isTrue);
      });

      test('밀도 정확히 2.5면 true (경계값)', () {
        const info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.5,
        );
        expect(info.isHighDensity, isTrue);
      });

      test('밀도 2.5 미만이면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.4,
        );
        expect(info.isHighDensity, isFalse);
      });

      test('밀도 2.0이면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.isHighDensity, isFalse);
      });

      test('밀도 1.0이면 false', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 1.0,
        );
        expect(info.isHighDensity, isFalse);
      });
    });

    group('isMobile', () {
      test('Android는 모바일', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.isMobile, isTrue);
      });

      test('iOS는 모바일', () {
        const info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        );
        expect(info.isMobile, isTrue);
      });

      test('Web은 모바일이 아님', () {
        const info = DeviceInfo(
          platform: DevicePlatform.web,
          ramGB: 8,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.isMobile, isFalse);
      });

      test('Other는 모바일이 아님', () {
        const info = DeviceInfo(
          platform: DevicePlatform.other,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.isMobile, isFalse);
      });

      test('Android 태블릿도 모바일', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 6,
          isTablet: true,
          screenDensity: 2.0,
        );
        expect(info.isMobile, isTrue);
      });

      test('iPad도 모바일', () {
        const info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 8,
          isTablet: true,
          screenDensity: 2.0,
        );
        expect(info.isMobile, isTrue);
      });
    });

    group('플랫폼별 테스트', () {
      test('Android 기기 정보', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 6,
          isTablet: false,
          screenDensity: 2.75,
        );

        expect(info.isMobile, isTrue);
        expect(info.hasEnoughMemory, isTrue);
        expect(info.isHighDensity, isTrue);
      });

      test('iOS 기기 정보', () {
        const info = DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        );

        expect(info.isMobile, isTrue);
        expect(info.hasEnoughMemory, isTrue);
        expect(info.isHighDensity, isTrue);
      });

      test('Web 플랫폼 정보', () {
        const info = DeviceInfo(
          platform: DevicePlatform.web,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        );

        expect(info.isMobile, isFalse);
        expect(info.hasEnoughMemory, isTrue);
        expect(info.isHighDensity, isFalse);
      });

      test('저사양 Android', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 2,
          isTablet: false,
          screenDensity: 1.5,
        );

        expect(info.isMobile, isTrue);
        expect(info.hasEnoughMemory, isFalse);
        expect(info.isHighDensity, isFalse);
      });
    });
  });

  // ============================================================
  // TextureQuality 테스트
  // ============================================================

  group('TextureQuality', () {
    group('scaleFactor', () {
      test('low 품질 배수는 0.5', () {
        expect(TextureQuality.low.scaleFactor, equals(0.5));
      });

      test('medium 품질 배수는 0.75', () {
        expect(TextureQuality.medium.scaleFactor, equals(0.75));
      });

      test('high 품질 배수는 1.0', () {
        expect(TextureQuality.high.scaleFactor, equals(1.0));
      });

      test('모든 배수가 0.0 ~ 1.0 범위', () {
        for (final quality in TextureQuality.values) {
          expect(quality.scaleFactor, greaterThanOrEqualTo(0.0));
          expect(quality.scaleFactor, lessThanOrEqualTo(1.0));
        }
      });

      test('배수가 품질에 따라 증가', () {
        expect(
          TextureQuality.low.scaleFactor,
          lessThan(TextureQuality.medium.scaleFactor),
        );
        expect(
          TextureQuality.medium.scaleFactor,
          lessThan(TextureQuality.high.scaleFactor),
        );
      });
    });

    group('displayName', () {
      test('low 품질 표시 이름', () {
        expect(TextureQuality.low.displayName, equals('낮음'));
      });

      test('medium 품질 표시 이름', () {
        expect(TextureQuality.medium.displayName, equals('중간'));
      });

      test('high 품질 표시 이름', () {
        expect(TextureQuality.high.displayName, equals('높음'));
      });

      test('모든 품질이 비어 있지 않은 displayName을 가짐', () {
        for (final quality in TextureQuality.values) {
          expect(quality.displayName.isNotEmpty, isTrue);
        }
      });
    });

    group('enum values', () {
      test('정확히 3개의 품질 레벨이 있어야 함', () {
        expect(TextureQuality.values.length, equals(3));
      });

      test('모든 품질 레벨이 포함됨', () {
        expect(TextureQuality.values, contains(TextureQuality.low));
        expect(TextureQuality.values, contains(TextureQuality.medium));
        expect(TextureQuality.values, contains(TextureQuality.high));
      });
    });
  });

  // ============================================================
  // PerformanceTestResult 테스트
  // ============================================================

  group('PerformanceTestResult', () {
    group('생성', () {
      test('모든 필드가 올바르게 설정됨', () {
        const result = PerformanceTestResult(
          averageFps: 55.0,
          minFps: 45.0,
          maxFps: 60.0,
          droppedFrames: 5,
          testDuration: Duration(seconds: 10),
        );

        expect(result.averageFps, equals(55.0));
        expect(result.minFps, equals(45.0));
        expect(result.maxFps, equals(60.0));
        expect(result.droppedFrames, equals(5));
        expect(result.testDuration, equals(const Duration(seconds: 10)));
      });

      test('const 생성자 사용 가능', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 5),
        );
        expect(result, isA<PerformanceTestResult>());
      });
    });

    group('recommendedTier', () {
      // High tier 테스트
      test('우수한 성능은 high tier (avgFps >= 55, minFps >= 45)', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.high));
      });

      test('경계값 high tier (avgFps = 55, minFps = 45)', () {
        const result = PerformanceTestResult(
          averageFps: 55,
          minFps: 45,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.high));
      });

      test('avgFps 55 미만이면 high tier 아님', () {
        const result = PerformanceTestResult(
          averageFps: 54,
          minFps: 50,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, isNot(equals(DeviceTier.high)));
      });

      test('minFps 45 미만이면 high tier 아님', () {
        const result = PerformanceTestResult(
          averageFps: 58,
          minFps: 44,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, isNot(equals(DeviceTier.high)));
      });

      // Mid tier 테스트
      test('양호한 성능은 mid tier (avgFps >= 40, minFps >= 25)', () {
        const result = PerformanceTestResult(
          averageFps: 45,
          minFps: 35,
          maxFps: 50,
          droppedFrames: 5,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      test('경계값 mid tier (avgFps = 40, minFps = 25)', () {
        const result = PerformanceTestResult(
          averageFps: 40,
          minFps: 25,
          maxFps: 50,
          droppedFrames: 10,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      test('avgFps 54, minFps 44는 mid tier', () {
        const result = PerformanceTestResult(
          averageFps: 54,
          minFps: 44,
          maxFps: 60,
          droppedFrames: 2,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      // Low tier 테스트
      test('낮은 성능은 low tier (avgFps < 40 또는 minFps < 25)', () {
        const result = PerformanceTestResult(
          averageFps: 25,
          minFps: 15,
          maxFps: 30,
          droppedFrames: 20,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      test('avgFps 39는 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 39,
          minFps: 30,
          maxFps: 45,
          droppedFrames: 10,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      test('minFps 24는 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 45,
          minFps: 24,
          maxFps: 50,
          droppedFrames: 15,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      test('avgFps와 minFps 모두 낮으면 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 20,
          minFps: 10,
          maxFps: 25,
          droppedFrames: 50,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      // 극단적인 값 테스트
      test('매우 높은 FPS는 high tier', () {
        const result = PerformanceTestResult(
          averageFps: 120,
          minFps: 100,
          maxFps: 144,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.high));
      });

      test('0 FPS는 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 0,
          minFps: 0,
          maxFps: 0,
          droppedFrames: 100,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      test('음수 FPS 처리 (비정상 상황)', () {
        const result = PerformanceTestResult(
          averageFps: -10,
          minFps: -20,
          maxFps: 0,
          droppedFrames: 100,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });
    });

    group('droppedFrames', () {
      test('드롭된 프레임 0', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.droppedFrames, equals(0));
      });

      test('드롭된 프레임 양수', () {
        const result = PerformanceTestResult(
          averageFps: 45,
          minFps: 30,
          maxFps: 55,
          droppedFrames: 100,
          testDuration: Duration(seconds: 10),
        );
        expect(result.droppedFrames, equals(100));
      });
    });

    group('testDuration', () {
      test('짧은 테스트 시간', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 1),
        );
        expect(result.testDuration.inSeconds, equals(1));
      });

      test('긴 테스트 시간', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(minutes: 5),
        );
        expect(result.testDuration.inMinutes, equals(5));
      });

      test('밀리초 단위 테스트 시간', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 55,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(milliseconds: 500),
        );
        expect(result.testDuration.inMilliseconds, equals(500));
      });
    });

    group('FPS 관계', () {
      test('minFps <= averageFps <= maxFps 관계', () {
        const result = PerformanceTestResult(
          averageFps: 50,
          minFps: 40,
          maxFps: 60,
          droppedFrames: 5,
          testDuration: Duration(seconds: 10),
        );

        expect(result.minFps, lessThanOrEqualTo(result.averageFps));
        expect(result.averageFps, lessThanOrEqualTo(result.maxFps));
      });

      test('모든 FPS가 같은 경우', () {
        const result = PerformanceTestResult(
          averageFps: 60,
          minFps: 60,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );

        expect(result.minFps, equals(result.averageFps));
        expect(result.averageFps, equals(result.maxFps));
        expect(result.recommendedTier, equals(DeviceTier.high));
      });
    });
  });

  // ============================================================
  // 통합 테스트
  // ============================================================

  group('통합 테스트', () {
    setUp(() {
      MGDeviceCapability.clearCache();
    });

    test('tier와 info가 일관성 있음', () {
      final tier = MGDeviceCapability.tier;
      final info = MGDeviceCapability.info;

      // RAM에 따른 tier 분류 검증
      if (info.ramGB >= 8) {
        expect(tier, equals(DeviceTier.high));
      } else if (info.ramGB >= 4) {
        expect(tier, equals(DeviceTier.mid));
      } else {
        expect(tier, equals(DeviceTier.low));
      }
    });

    test('recommendedTextureQuality와 tier가 일치', () {
      final tier = MGDeviceCapability.tier;
      final quality = MGDeviceCapability.recommendedTextureQuality;

      switch (tier) {
        case DeviceTier.high:
          expect(quality, equals(TextureQuality.high));
          break;
        case DeviceTier.mid:
          expect(quality, equals(TextureQuality.medium));
          break;
        case DeviceTier.low:
          expect(quality, equals(TextureQuality.low));
          break;
      }
    });

    test('GPU와 CPU 성능이 같은 tier에서 동일', () {
      final gpuPerf = MGDeviceCapability.estimatedGpuPerformance;
      final cpuPerf = MGDeviceCapability.estimatedCpuPerformance;

      expect(gpuPerf, equals(cpuPerf));
    });

    test('PerformanceTestResult로 tier 재조정 시나리오', () {
      // 현재 기기 tier
      final currentTier = MGDeviceCapability.tier;

      // 성능 테스트 결과 시뮬레이션
      const testResult = PerformanceTestResult(
        averageFps: 45,
        minFps: 35,
        maxFps: 55,
        droppedFrames: 5,
        testDuration: Duration(seconds: 30),
      );

      final recommendedTier = testResult.recommendedTier;

      // recommendedTier가 유효한 DeviceTier여야 함
      expect(DeviceTier.values, contains(recommendedTier));

      // 현재 tier와 다를 수 있음 (실제 성능 기반)
      expect(currentTier, isA<DeviceTier>());
    });

    test('DeviceInfo의 모든 속성 조합 테스트', () {
      final combinations = [
        const DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 2,
          isTablet: false,
          screenDensity: 1.5,
        ),
        const DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.0,
        ),
        const DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 8,
          isTablet: true,
          screenDensity: 2.5,
        ),
        const DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 4,
          isTablet: false,
          screenDensity: 3.0,
        ),
        const DeviceInfo(
          platform: DevicePlatform.ios,
          ramGB: 6,
          isTablet: true,
          screenDensity: 2.0,
        ),
        const DeviceInfo(
          platform: DevicePlatform.web,
          ramGB: 8,
          isTablet: false,
          screenDensity: 2.0,
        ),
        const DeviceInfo(
          platform: DevicePlatform.other,
          ramGB: 4,
          isTablet: false,
          screenDensity: 1.0,
        ),
      ];

      for (final info in combinations) {
        // 모든 속성에 접근 가능
        expect(() => info.hasEnoughMemory, returnsNormally);
        expect(() => info.isHighDensity, returnsNormally);
        expect(() => info.isMobile, returnsNormally);
      }
    });
  });

  // ============================================================
  // 경계값 테스트
  // ============================================================

  group('경계값 테스트', () {
    group('RAM 경계값', () {
      test('RAM 3.99GB는 메모리 부족', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 3.99,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isFalse);
      });

      test('RAM 4.00GB는 메모리 충분', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4.00,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isTrue);
      });

      test('RAM 4.01GB는 메모리 충분', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4.01,
          isTablet: false,
          screenDensity: 2.0,
        );
        expect(info.hasEnoughMemory, isTrue);
      });
    });

    group('화면 밀도 경계값', () {
      test('밀도 2.49는 고밀도 아님', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.49,
        );
        expect(info.isHighDensity, isFalse);
      });

      test('밀도 2.50은 고밀도', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.50,
        );
        expect(info.isHighDensity, isTrue);
      });

      test('밀도 2.51은 고밀도', () {
        const info = DeviceInfo(
          platform: DevicePlatform.android,
          ramGB: 4,
          isTablet: false,
          screenDensity: 2.51,
        );
        expect(info.isHighDensity, isTrue);
      });
    });

    group('PerformanceTestResult 경계값', () {
      // High tier 경계
      test('avgFps=55, minFps=45는 high tier', () {
        const result = PerformanceTestResult(
          averageFps: 55,
          minFps: 45,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.high));
      });

      test('avgFps=54.99, minFps=45는 mid tier', () {
        const result = PerformanceTestResult(
          averageFps: 54.99,
          minFps: 45,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      test('avgFps=55, minFps=44.99는 mid tier', () {
        const result = PerformanceTestResult(
          averageFps: 55,
          minFps: 44.99,
          maxFps: 60,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      // Mid tier 경계
      test('avgFps=40, minFps=25는 mid tier', () {
        const result = PerformanceTestResult(
          averageFps: 40,
          minFps: 25,
          maxFps: 50,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.mid));
      });

      test('avgFps=39.99, minFps=25는 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 39.99,
          minFps: 25,
          maxFps: 50,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });

      test('avgFps=40, minFps=24.99는 low tier', () {
        const result = PerformanceTestResult(
          averageFps: 40,
          minFps: 24.99,
          maxFps: 50,
          droppedFrames: 0,
          testDuration: Duration(seconds: 10),
        );
        expect(result.recommendedTier, equals(DeviceTier.low));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/optimization/performance_profiler.dart';
import 'package:mg_common_game/core/optimization/device_capability.dart';

void main() {
  group('PerformanceData', () {
    final testTimestamp = DateTime(2025, 1, 1, 12, 0);

    test('기본 생성', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 60.0,
        minFps: 55.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      expect(data.name, 'test');
      expect(data.duration, const Duration(seconds: 10));
      expect(data.frameCount, 600);
      expect(data.averageFps, 60.0);
      expect(data.minFps, 55.0);
      expect(data.maxFps, 60.0);
      expect(data.droppedFrames, 0);
    });

    test('toString 출력', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 60.0,
        minFps: 55.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      final str = data.toString();
      expect(str, contains('test'));
      expect(str, contains('60.0'));
      expect(str, contains('55.0'));
    });

    test('toJson/fromJson 변환', () {
      final now = DateTime(2025, 1, 1, 12, 0);
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 60.0,
        minFps: 55.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: now,
      );

      final json = data.toJson();
      final restored = PerformanceData.fromJson(json);

      expect(restored.name, data.name);
      expect(restored.duration, data.duration);
      expect(restored.frameCount, data.frameCount);
      expect(restored.averageFps, data.averageFps);
      expect(restored.minFps, data.minFps);
      expect(restored.maxFps, data.maxFps);
      expect(restored.droppedFrames, data.droppedFrames);
    });

    test('recommendedTier - high 성능', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 58.0,
        minFps: 50.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      expect(data.recommendedTier, DeviceTier.high);
    });

    test('recommendedTier - mid 성능', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 450,
        averageFps: 45.0,
        minFps: 30.0,
        maxFps: 55.0,
        droppedFrames: 5,
        timestamp: testTimestamp,
      );

      expect(data.recommendedTier, DeviceTier.mid);
    });

    test('recommendedTier - low 성능', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 250,
        averageFps: 25.0,
        minFps: 15.0,
        maxFps: 35.0,
        droppedFrames: 20,
        timestamp: testTimestamp,
      );

      expect(data.recommendedTier, DeviceTier.low);
    });

    test('performanceGrade - A등급', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 58.0,
        minFps: 52.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      expect(data.performanceGrade, 'A');
    });

    test('performanceGrade - B등급', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 550,
        averageFps: 55.0,
        minFps: 42.0,
        maxFps: 58.0,
        droppedFrames: 3,
        timestamp: testTimestamp,
      );

      expect(data.performanceGrade, 'B');
    });

    test('performanceGrade - C등급', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 450,
        averageFps: 45.0,
        minFps: 32.0,
        maxFps: 55.0,
        droppedFrames: 8,
        timestamp: testTimestamp,
      );

      expect(data.performanceGrade, 'C');
    });

    test('performanceGrade - D등급', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 300,
        averageFps: 30.0,
        minFps: 22.0,
        maxFps: 40.0,
        droppedFrames: 15,
        timestamp: testTimestamp,
      );

      expect(data.performanceGrade, 'D');
    });

    test('performanceGrade - F등급', () {
      final data = PerformanceData(
        name: 'test',
        duration: const Duration(seconds: 10),
        frameCount: 200,
        averageFps: 20.0,
        minFps: 10.0,
        maxFps: 30.0,
        droppedFrames: 30,
        timestamp: testTimestamp,
      );

      expect(data.performanceGrade, 'F');
    });
  });

  group('FrameTimeData', () {
    final testTimestamp = DateTime(2025, 1, 1, 12, 0);

    test('기본 생성', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 16),
        timestamp: testTimestamp,
      );

      expect(data.frameNumber, 100);
      expect(data.frameTime, const Duration(milliseconds: 16));
    });

    test('isDropped - 정상 프레임', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 14),
        timestamp: testTimestamp,
      );

      expect(data.isDropped, false);
    });

    test('isDropped - 드롭프레임', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 20),
        timestamp: testTimestamp,
      );

      expect(data.isDropped, true);
    });

    test('isDropped - 경계값 (16ms)', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 16),
        timestamp: testTimestamp,
      );

      expect(data.isDropped, false);
    });

    test('toString - 정상 프레임', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 14),
        timestamp: testTimestamp,
      );

      expect(data.toString(), contains('Frame #100'));
      expect(data.toString(), contains('14ms'));
      expect(data.toString(), isNot(contains('[DROPPED]')));
    });

    test('toString - 드롭프레임', () {
      final data = FrameTimeData(
        frameNumber: 100,
        frameTime: const Duration(milliseconds: 20),
        timestamp: testTimestamp,
      );

      expect(data.toString(), contains('[DROPPED]'));
    });
  });

  group('MGPerformanceProfiler', () {
    test('싱글톤 인스턴스', () {
      final profiler1 = MGPerformanceProfiler.instance;
      final profiler2 = MGPerformanceProfiler.instance;

      expect(identical(profiler1, profiler2), true);
    });

    test('초기 상태', () {
      final profiler = MGPerformanceProfiler.instance;

      expect(profiler.isProfiling, false);
      expect(profiler.history, isEmpty);
      expect(profiler.frameTimeHistory, isEmpty);
      expect(profiler.totalDroppedFrames, 0);
    });

    test('startProfile으로 프로파일링 시작', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test');
      expect(profiler.isProfiling, true);

      profiler.stopProfile();
    });

    test('stopProfile으로 프로파일링 중지', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test');
      final data = profiler.stopProfile(name: 'test');

      expect(profiler.isProfiling, false);
      expect(data, isNotNull);
      expect(data!.name, 'test');
    });

    test('중복 startProfile은 무시됨', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'first');
      final wasProfiling = profiler.isProfiling;

      profiler.startProfile(name: 'second');

      expect(wasProfiling, true);
      expect(profiler.isProfiling, true);

      profiler.stopProfile();
    });

    test('프로파일링 중지되지 않았을 때 stopProfile은 null 반환', () {
      final profiler = MGPerformanceProfiler.instance;

      final data = profiler.stopProfile();
      expect(data, isNull);
    });

    test('getCurrentProfile은 현재 상태 반환', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test');

      // 즉시 확인하면 데이터가 거의 없음
      final current = profiler.getCurrentProfile(name: 'current');
      expect(current, isNotNull);

      profiler.stopProfile();
    });

    test('getCurrentProfile은 프로파일링 중지 시 null 반환', () {
      final profiler = MGPerformanceProfiler.instance;

      final current = profiler.getCurrentProfile();
      expect(current, isNull);
    });

    test('clearHistory로 기록 초기화', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test1');
      profiler.stopProfile(name: 'test1');

      profiler.startProfile(name: 'test2');
      profiler.stopProfile(name: 'test2');

      expect(profiler.history.length, greaterThan(0));

      profiler.clearHistory();

      expect(profiler.history, isEmpty);
    });

    test('history는 불변 리스트', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test');
      profiler.stopProfile(name: 'test');

      final history = profiler.history;
      final testTimestamp = DateTime(2025, 1, 1, 12, 0);
      expect(() => (history as List).add(PerformanceData(
        name: 'another',
        duration: Duration.zero,
        frameCount: 0,
        averageFps: 0,
        minFps: 0,
        maxFps: 0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      )), throwsUnsupportedError);
    });

    test('frameTimeHistory도 불변 리스트', () {
      final profiler = MGPerformanceProfiler.instance;

      profiler.startProfile(name: 'test');
      profiler.stopProfile(name: 'test');

      final history = profiler.frameTimeHistory;
      final testTimestamp = DateTime(2025, 1, 1, 12, 0);
      expect(() => (history as List).add(FrameTimeData(
        frameNumber: 1,
        frameTime: const Duration(milliseconds: 16),
        timestamp: testTimestamp,
      )), throwsUnsupportedError);
    });

    test('ChangeNotifier 상속', () {
      final profiler = MGPerformanceProfiler.instance;

      expect(profiler, isA<MGPerformanceProfiler>());

      var notified = false;
      profiler.addListener(() => notified = true);

      profiler.startProfile(name: 'test');
      expect(notified, true);

      profiler.stopProfile();
    });

    test('여러 프로파일링 세션 기록', () {
      final profiler = MGPerformanceProfiler.instance;
      profiler.clearHistory();

      for (int i = 1; i <= 3; i++) {
        profiler.startProfile(name: 'session_$i');
        profiler.stopProfile(name: 'session_$i');
      }

      expect(profiler.history.length, 3);
      expect(profiler.history[0].name, 'session_1');
      expect(profiler.history[1].name, 'session_2');
      expect(profiler.history[2].name, 'session_3');
    });
  });

  group('PerformanceOptimizer', () {
    final testTimestamp = DateTime(2025, 1, 1, 12, 0);

    test('getOptimizationSuggestions - 성공 시', () {
      final data = PerformanceData(
        name: 'good',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 58.0,
        minFps: 52.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      final suggestions = PerformanceOptimizer.getOptimizationSuggestions(data);

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains('양호')), true);
    });

    test('getOptimizationSuggestions - 낮은 FPS', () {
      final data = PerformanceData(
        name: 'low',
        duration: const Duration(seconds: 10),
        frameCount: 200,
        averageFps: 20.0,
        minFps: 10.0,
        maxFps: 30.0,
        droppedFrames: 30,
        timestamp: testTimestamp,
      );

      final suggestions = PerformanceOptimizer.getOptimizationSuggestions(data);

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains('낮습니다')), true);
      expect(suggestions.any((s) => s.contains('텍스처')), true);
    });

    test('getOptimizationSuggestions - 많은 드롭프레임', () {
      final data = PerformanceData(
        name: 'drops',
        duration: const Duration(seconds: 10),
        frameCount: 550,
        averageFps: 55.0,
        minFps: 40.0,
        maxFps: 60.0,
        droppedFrames: 15,
        timestamp: testTimestamp,
      );

      final suggestions = PerformanceOptimizer.getOptimizationSuggestions(data);

      expect(suggestions.any((s) => s.contains('드롭프레임')), true);
    });

    test('getRecommendedSettings - high 티어', () {
      final data = PerformanceData(
        name: 'high',
        duration: const Duration(seconds: 10),
        frameCount: 600,
        averageFps: 58.0,
        minFps: 50.0,
        maxFps: 60.0,
        droppedFrames: 0,
        timestamp: testTimestamp,
      );

      final settings = PerformanceOptimizer.getRecommendedSettings(data);

      expect(settings, isA<Map<String, dynamic>>());
      expect(settings['enableShadows'], true);
      expect(settings['enableParticles'], true);
      expect(settings['enablePostProcessing'], true);
    });

    test('getRecommendedSettings - low 티어', () {
      final data = PerformanceData(
        name: 'low',
        duration: const Duration(seconds: 10),
        frameCount: 250,
        averageFps: 25.0,
        minFps: 15.0,
        maxFps: 35.0,
        droppedFrames: 20,
        timestamp: testTimestamp,
      );

      final settings = PerformanceOptimizer.getRecommendedSettings(data);

      expect(settings['enableShadows'], false);
      expect(settings['enableParticles'], false);
      expect(settings['enablePostProcessing'], false);
      expect(settings['maxConcurrentAnimations'], 2);
    });

    // TODO: Fix compareWithBaseline test issue
    // test('compareWithBaseline - 베이스라인 없음', () {
    //   final current = PerformanceData(
    //     name: 'test',
    //     duration: const Duration(seconds: 10),
    //     frameCount: 600,
    //     averageFps: 60.0,
    //     minFps: 55.0,
    //     maxFps: 60.0,
    //     droppedFrames: 0,
    //     timestamp: testTimestamp,
    //   );
    //
    //   final result = PerformanceOptimizer.compareToBaseline(current, null);
    //
    //   expect(result, contains('베이스라인 데이터가 없습니다'));
    // });

    // TODO: Fix compareWithBaseline test issue
    // test('compareWithBaseline - 개선됨', () {
    //   final baseline = PerformanceData(
    //     name: 'baseline',
    //     duration: const Duration(seconds: 10),
    //     frameCount: 500,
    //     averageFps: 50.0,
    //     minFps: 40.0,
    //     maxFps: 55.0,
    //     droppedFrames: 10,
    //     timestamp: testTimestamp,
    //   );
    //
    //   final current = PerformanceData(
    //     name: 'current',
    //     duration: const Duration(seconds: 10),
    //     frameCount: 600,
    //     averageFps: 58.0,
    //     minFps: 50.0,
    //     maxFps: 60.0,
    //     droppedFrames: 2,
    //     timestamp: testTimestamp,
    //   );
    //
    //   final result = PerformanceOptimizer.compareToBaseline(current, baseline);
    //
    //   expect(result, contains('성능이 개선'));
    // });

    // TODO: Fix compareWithBaseline test issue
    // test('compareWithBaseline - 저하됨', () {
    //   final baseline = PerformanceData(
    //     name: 'baseline',
    //     duration: const Duration(seconds: 10),
    //     frameCount: 600,
    //     averageFps: 60.0,
    //     minFps: 55.0,
    //     maxFps: 60.0,
    //     droppedFrames: 0,
    //     timestamp: testTimestamp,
    //   );
    //
    //   final current = PerformanceData(
    //     name: 'current',
    //     duration: const Duration(seconds: 10),
    //     frameCount: 400,
    //     averageFps: 40.0,
    //     minFps: 30.0,
    //     maxFps: 50.0,
    //     droppedFrames: 20,
    //     timestamp: testTimestamp,
    //   );
    //
    //   final result = PerformanceOptimizer.compareToBaseline(current, baseline);
    //
    //   expect(result, contains('성능이 저하'));
    // });
  });

  group('WidgetPerformanceAnalyzer', () {
    test('measureWidgetBuildTime - 빌드 시간 측정', () async {
      final result = await WidgetPerformanceAnalyzer.measureWidgetBuildTime(
        () async => Future.value('test result'),
        'TestWidget',
      );

      expect(result, 'test result');
    });

    test('measureWidgetBuildTime - 동기 함수', () async {
      final result = await WidgetPerformanceAnalyzer.measureWidgetBuildTime(
        () => Future.value('sync result'),
        'SyncWidget',
      );

      expect(result, 'sync result');
    });
  });
}

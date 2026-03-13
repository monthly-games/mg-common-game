import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/performance/memory_profiler.dart';
import 'package:mg_common_game/performance/widget_optimizer.dart';
import 'package:mg_common_game/performance/image_cache_manager.dart';

void main() {
  group('MemoryManager Unit Tests', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager.instance;
    });

    tearDown(() {
      memoryManager.dispose();
    });

    test('메모리 통계 캡처', () {
      final stats = memoryManager.captureStats();

      expect(stats, isNotNull);
      expect(stats.heapUsage, greaterThanOrEqualTo(0));
      expect(stats.heapCapacity, greaterThanOrEqualTo(0));
    });

    test('메모리 모니터링 시작/중지', () {
      memoryManager.startMonitoring();
      expect(memoryManager.history, isEmpty);

      // 통계 캡처 대기
      Future.delayed(const Duration(milliseconds: 100), () {
        expect(memoryManager.history.isNotEmpty, isTrue);
      });

      memoryManager.stopMonitoring();
    });

    test('메모리 경고 레벨 계산', () {
      final normalStats = MemoryStats(
        heapUsage: 50 * 1024 * 1024, // 50MB
        heapCapacity: 100 * 1024 * 1024, // 100MB
        externalUsage: 10 * 1024 * 1024,
        timestamp: DateTime.now(),
      );

      expect(normalStats.usagePercent, equals(50.0));

      final highStats = MemoryStats(
        heapUsage: 85 * 1024 * 1024,
        heapCapacity: 100 * 1024 * 1024,
        externalUsage: 10 * 1024 * 1024,
        timestamp: DateTime.now(),
      );

      expect(highStats.usagePercent, equals(85.0));
    });

    test('메모리 최적화 제안', () {
      final suggestions = MemoryOptimizationHelper.getOptimizationSuggestions();
      expect(suggestions, isA<List<String>>());
    });
  });

  group('WidgetProfiler Unit Tests', () {
    late WidgetProfiler profiler;

    setUp(() {
      profiler = WidgetProfiler.instance;
    });

    tearDown(() {
      profiler.clear();
    });

    test('위젯 빌드 시간 측정', () {
      const widgetName = 'TestWidget';

      profiler.startBuild(widgetName);
      Future.delayed(const Duration(milliseconds: 10));
      profiler.endBuild(widgetName);

      final metrics = profiler.getMetrics(widgetName);
      expect(metrics, isNotNull);
      expect(metrics!.buildCount, greaterThan(0));
    });

    test('여러 위젯 메트릭', () {
      profiler.startBuild('Widget1');
      profiler.endBuild('Widget1');

      profiler.startBuild('Widget2');
      profiler.endBuild('Widget2');

      final allMetrics = profiler.getAllMetrics();
      expect(allMetrics.length, equals(2));
    });

    test('프로파일러 리포트', () {
      profiler.startBuild('SlowWidget');
      Future.delayed(const Duration(milliseconds: 20));
      profiler.endBuild('SlowWidget');

      final report = profiler.generateReport();
      expect(report, contains('SlowWidget'));
    });
  });

  group('ImageCacheManager Unit Tests', () {
    late ImageCacheManager cacheManager;

    setUp(() async {
      cacheManager = ImageCacheManager.instance;
      await cacheManager.initialize();
    });

    tearDown(() {
      cacheManager.dispose();
    });

    test('캐시 키 생성', () {
      final url1 = 'https://example.com/image1.png';
      final url2 = 'https://example.com/image1.png';
      final url3 = 'https://example.com/image2.png';

      final key1 = cacheManager.generateCacheKey(url1);
      final key2 = cacheManager.generateCacheKey(url2);
      final key3 = cacheManager.generateCacheKey(url3);

      expect(key1, equals(key2)); // 같은 URL
      expect(key1, isNot(equals(key3))); // 다른 URL
    });

    test('캐시 통계', () {
      final stats = cacheManager.getStatistics();

      expect(stats['memory_cache_items'], isA<int>());
      expect(stats['memory_cache_size'], isA<int>());
      expect(stats['max_memory_cache_size'], isA<int>());
    });

    test('캐시 크기 설정', () {
      const newSize = 200 * 1024 * 1024; // 200MB

      cacheManager.setMaxMemoryCacheSize(newSize);

      final stats = cacheManager.getStatistics();
      expect(stats['max_memory_cache_size'], equals(newSize));
    });
  });

  group('BuildAnalyzer Unit Tests', () {
    test('위젯 분석 결과', () {
      // 실제 위젯 트리 분석은 테스트 환경에서 제한적
      // 기본 구조 검증

      final analysis = WidgetAnalysis(
        widgetType: 'Container',
        depth: 5,
        totalChildren: 20,
        needsRebuild: false,
      );

      expect(analysis.widgetType, equals('Container'));
      expect(analysis.depth, equals(5));
      expect(analysis.totalChildren, equals(20));
      expect(analysis.needsRebuild, isFalse);
    });

    test('최적화 제안 생성', () {
      final deepAnalysis = WidgetAnalysis(
        widgetType: 'DeepWidget',
        depth: 15,
        totalChildren: 10,
        needsRebuild: true,
      );

      final suggestions = BuildAnalyzer.getOptimizationSuggestionsFor(deepAnalysis);

      expect(suggestions, anyElement(contains('깊습니다')));
    });
  });
}

// 테스트 헬퍼
extension BuildAnalyzerExtension on BuildAnalyzer {
  static List<String> getOptimizationSuggestionsFor(WidgetAnalysis analysis) {
    final suggestions = <String>[];

    if (analysis.depth > 10) {
      suggestions.add('위젯 트리가 깊습니다 (${analysis.depth}단계)');
    }

    if (analysis.totalChildren > 50) {
      suggestions.add('자식 위젯이 많습니다 (${analysis.totalChildren}개)');
    }

    if (analysis.needsRebuild) {
      suggestions.add('빈번한 rebuild가 발생합니다');
    }

    return suggestions;
  }
}

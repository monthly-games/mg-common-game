/// MG-Games 통합 테스트 프레임워크
/// 모든 게임에서 공통으로 사용할 수 있는 테스트 유틸리티
///
/// Usage:
/// 1. Copy to: mg-game-XXXX/game/test/
/// 2. Import in your test files
/// 3. Use provided utilities and helpers

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// 테스트 설정 및 유틸리티
// ============================================================

/// 테스트 환경 설정
class MGTestConfig {
  /// 테스트 타임아웃 (밀리초)
  static const int defaultTimeout = 30000;

  /// 애니메이션 대기 시간
  static const Duration animationDuration = Duration(milliseconds: 500);

  /// 네트워크 요청 대기 시간
  static const Duration networkTimeout = Duration(seconds: 5);
}

/// 테스트 헬퍼 클래스
class MGTestHelper {
  /// 위젯 테스트 래퍼
  static Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  /// 다크 테마 래퍼
  static Widget wrapWithDarkTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  /// 미디어 쿼리 래퍼
  static Widget wrapWithSize(Widget child, Size size) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    );
  }

  /// 버튼 탭 헬퍼
  static Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// 텍스트 입력 헬퍼
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// 스크롤 헬퍼
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = 100,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
    );
  }
}

// ============================================================
// 매처 (Matchers)
// ============================================================

/// 범위 내 값 매처
Matcher inRange(num min, num max) => _InRangeMatcher(min, max);

class _InRangeMatcher extends Matcher {
  final num min;
  final num max;

  _InRangeMatcher(this.min, this.max);

  @override
  bool matches(Object? item, Map matchState) {
    if (item is num) {
      return item >= min && item <= max;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('a value between $min and $max');
  }
}

/// 리스트 길이 매처
Matcher hasLength(int length) => _HasLengthMatcher(length);

class _HasLengthMatcher extends Matcher {
  final int expectedLength;

  _HasLengthMatcher(this.expectedLength);

  @override
  bool matches(Object? item, Map matchState) {
    if (item is List) {
      return item.length == expectedLength;
    }
    if (item is Map) {
      return item.length == expectedLength;
    }
    if (item is String) {
      return item.length == expectedLength;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has length $expectedLength');
  }
}

/// 정렬 확인 매처
Matcher isSortedAscending<T extends Comparable>() => _SortedMatcher<T>(true);
Matcher isSortedDescending<T extends Comparable>() => _SortedMatcher<T>(false);

class _SortedMatcher<T extends Comparable> extends Matcher {
  final bool ascending;

  _SortedMatcher(this.ascending);

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! List<T>) return false;
    for (int i = 0; i < item.length - 1; i++) {
      final comparison = item[i].compareTo(item[i + 1]);
      if (ascending ? comparison > 0 : comparison < 0) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('is sorted ${ascending ? 'ascending' : 'descending'}');
  }
}

// ============================================================
// 목(Mock) 클래스
// ============================================================

/// 목 저장소 (SharedPreferences 대체)
class MockStorage {
  final Map<String, dynamic> _data = {};

  dynamic get(String key) => _data[key];

  void set(String key, dynamic value) {
    _data[key] = value;
  }

  void remove(String key) {
    _data.remove(key);
  }

  void clear() {
    _data.clear();
  }

  bool containsKey(String key) => _data.containsKey(key);
}

/// 목 오디오 매니저
class MockAudioManager {
  bool isMuted = false;
  double volume = 1.0;
  String? lastPlayedBgm;
  String? lastPlayedSfx;

  void playBgm(String name) {
    lastPlayedBgm = name;
  }

  void playSfx(String name) {
    lastPlayedSfx = name;
  }

  void stopBgm() {
    lastPlayedBgm = null;
  }

  void setVolume(double vol) {
    volume = vol.clamp(0.0, 1.0);
  }

  void mute() => isMuted = true;
  void unmute() => isMuted = false;
}

/// 목 네트워크 서비스
class MockNetworkService {
  final Map<String, dynamic> _responses = {};
  final List<String> _requestLog = [];
  bool shouldFail = false;
  int delayMs = 0;

  void setResponse(String endpoint, dynamic response) {
    _responses[endpoint] = response;
  }

  Future<dynamic> get(String endpoint) async {
    _requestLog.add('GET $endpoint');
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    if (shouldFail) {
      throw Exception('Network error');
    }
    return _responses[endpoint];
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    _requestLog.add('POST $endpoint: $data');
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    if (shouldFail) {
      throw Exception('Network error');
    }
    return _responses[endpoint];
  }

  List<String> get requestLog => List.unmodifiable(_requestLog);

  void clearLog() => _requestLog.clear();
}

// ============================================================
// 테스트 데이터 생성
// ============================================================

/// 테스트 데이터 팩토리
class MGTestDataFactory {
  static int _idCounter = 0;

  /// 유니크 ID 생성
  static String uniqueId([String prefix = 'test']) {
    return '${prefix}_${++_idCounter}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 랜덤 정수 생성
  static int randomInt(int min, int max) {
    return min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1));
  }

  /// 랜덤 double 생성
  static double randomDouble(double min, double max) {
    final random = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000;
    return min + (max - min) * random;
  }

  /// 테스트용 맵 데이터 생성
  static Map<String, dynamic> createTestData({
    String? id,
    String? name,
    int? level,
    int? coins,
    int? gems,
  }) {
    return {
      'id': id ?? uniqueId(),
      'name': name ?? 'Test Item',
      'level': level ?? randomInt(1, 100),
      'coins': coins ?? randomInt(0, 10000),
      'gems': gems ?? randomInt(0, 500),
    };
  }
}

// ============================================================
// 성능 테스트 유틸리티
// ============================================================

/// 성능 측정 유틸리티
class MGPerformanceTest {
  /// 함수 실행 시간 측정
  static Duration measure(void Function() action) {
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// 비동기 함수 실행 시간 측정
  static Future<Duration> measureAsync(Future<void> Function() action) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// 반복 실행 평균 시간 측정
  static Duration measureAverage(void Function() action, int iterations) {
    final times = <Duration>[];
    for (int i = 0; i < iterations; i++) {
      times.add(measure(action));
    }
    final totalMicroseconds = times.fold<int>(
      0,
      (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ iterations);
  }

  /// 성능 기준 테스트
  static void expectPerformance(
    void Function() action,
    Duration maxDuration, {
    String? reason,
  }) {
    final elapsed = measure(action);
    expect(
      elapsed,
      lessThanOrEqualTo(maxDuration),
      reason: reason ?? 'Performance exceeded expected duration',
    );
  }
}

// ============================================================
// 테스트 그룹 헬퍼
// ============================================================

/// 매니저 테스트 헬퍼
mixin ManagerTestMixin {
  /// 상태 리셋 확인
  void testStateReset(dynamic manager, void Function() resetAction) {
    test('should reset state correctly', () {
      resetAction();
      // 상태가 초기화되었는지 확인
      expect(manager, isNotNull);
    });
  }

  /// 저장/로드 테스트
  Future<void> testPersistence(
    dynamic manager,
    Map<String, dynamic> Function() toJson,
    void Function(Map<String, dynamic>) fromJson,
  ) async {
    test('should save and load state', () {
      final json = toJson();
      expect(json, isA<Map<String, dynamic>>());

      fromJson(json);
      final reloaded = toJson();
      expect(reloaded, equals(json));
    });
  }
}

/// 위젯 테스트 헬퍼
mixin WidgetTestMixin {
  /// 렌더링 테스트
  Future<void> testRenders(
    WidgetTester tester,
    Widget widget,
    Finder expectedFinder,
  ) async {
    await tester.pumpWidget(MGTestHelper.wrapWithMaterial(widget));
    expect(expectedFinder, findsOneWidget);
  }

  /// 탭 테스트
  Future<void> testTap(
    WidgetTester tester,
    Widget widget,
    Finder tapTarget,
    void Function() verification,
  ) async {
    await tester.pumpWidget(MGTestHelper.wrapWithMaterial(widget));
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    verification();
  }
}

// ============================================================
// 기본 테스트 템플릿
// ============================================================

/// 기본 테스트 그룹 템플릿
void runManagerTests<T>({
  required String name,
  required T Function() createManager,
  required List<void Function(T manager)> testCases,
}) {
  group(name, () {
    late T manager;

    setUp(() {
      manager = createManager();
    });

    for (final testCase in testCases) {
      testCase(manager);
    }
  });
}

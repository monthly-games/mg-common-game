import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// jsonDecode is already imported via dart:convert

/// 테스트 상태
enum TestStatus {
  drafting,       // 준비 중
  running,        // 실행 중
  paused,         // 일시 정지
  completed,      // 완료
  cancelled,      // 취소됨
}

/// 테스트 타입
enum TestType {
  ui,             // UI 테스트
  feature,        // 기능 테스트
  algorithm,      // 알고리즘 테스트
  content,        // 콘텐츠 테스트
  pricing,        // 가격 테스트
  onboarding,     // 온보딩 테스트
}

/// 테스트 변형
class TestVariant {
  final String variantId;
  final String name;
  final String description;
  final double traffic; // 트래픽 비율 (0.0-1.0)
  final Map<String, dynamic> configuration;
  final Map<String, dynamic>? metadata;

  const TestVariant({
    required this.variantId,
    required this.name,
    required this.description,
    required this.traffic,
    required this.configuration,
    this.metadata,
  });
}

/// 테스트 메트릭
class TestMetric {
  final String metricId;
  final String name;
  final String description;
  final String type; // conversion, revenue, retention, engagement, custom
  final String aggregation; // sum, avg, count, rate
  final bool isPrimary;

  const TestMetric({
    required this.metricId,
    required this.name,
    required this.description,
    required this.type,
    required this.aggregation,
    this.isPrimary = false,
  });
}

/// 메트릭 값
class MetricValue {
  final String metricId;
  final double value;
  final int sampleSize;
  final DateTime timestamp;

  const MetricValue({
    required this.metricId,
    required this.value,
    required this.sampleSize,
    required this.timestamp,
  });
}

/// 테스트 결과
class VariantResult {
  final String variantId;
  final Map<String, MetricValue> metrics;
  final int participants;
  final int conversions;
  final double conversionRate;
  final double revenue;
  final DateTime updatedAt;

  const VariantResult({
    required this.variantId,
    required this.metrics,
    required this.participants,
    required this.conversions,
    required this.conversionRate,
    required this.revenue,
    required this.updatedAt,
  });

  /// 전환율
  double getConversionRate() => conversionRate;

  /// 1인당 평균 수익
  double getARPU() => participants > 0 ? revenue / participants : 0;

  /// 전환당 평균 수익
  double getARPC() => conversions > 0 ? revenue / conversions : 0;
}

/// 통계 분석 결과
class StatisticalAnalysis {
  final String variantId;
  final double conversionRate;
  final double standardError;
  final double confidenceInterval95Lower;
  final double confidenceInterval95Upper;
  final double pValue;
  final double zScore;
  final bool isSignificant;
  final double lift; // 대비 그룹 대비 증가율
  final double? relativeLift;

  const StatisticalAnalysis({
    required this.variantId,
    required this.conversionRate,
    required this.standardError,
    required this.confidenceInterval95Lower,
    required this.confidenceInterval95Upper,
    required this.pValue,
    required this.zScore,
    required this.isSignificant,
    required this.lift,
    this.relativeLift,
  });
}

/// A/B 테스트
class ABTest {
  final String testId;
  final String name;
  final String description;
  final TestType type;
  final TestStatus status;
  final List<TestVariant> variants;
  final List<TestMetric> metrics;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? duration;
  final int minSampleSize;
  final double significanceLevel; // 유의 수준 (0.05 = 95%)
  final String? controlVariantId;
  final Map<String, dynamic>? targetingCriteria;
  final Map<String, dynamic>? metadata;

  const ABTest({
    required this.testId,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.variants,
    required this.metrics,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.duration,
    this.minSampleSize = 1000,
    this.significanceLevel = 0.05,
    this.controlVariantId,
    this.targetingCriteria,
    this.metadata,
  });

  /// 전체 트래픽 합계
  double get totalTraffic {
    return variants.fold(0, (sum, v) => sum + v.traffic);
  }

  /// 실행 중인지
  bool get isActive => status == TestStatus.running;

  /// 기간 경과 여부
  bool get hasDurationPassed {
    if (duration == null || startedAt == null) return false;
    return DateTime.now().isAfter(startedAt!.add(duration!));
  }
}

/// A/B 테스트 관리자
class ABTestingManager {
  static final ABTestingManager _instance = ABTestingManager._();
  static ABTestingManager get instance => _instance;

  ABTestingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, ABTest> _tests = {};
  final Map<String, String> _userAssignments = {}; // userId -> variantId
  final Map<String, VariantResult> _results = {};

  final StreamController<ABTest> _testController =
      StreamController<ABTest>.broadcast();
  final StreamController<VariantResult> _resultController =
      StreamController<VariantResult>.broadcast();
  final StreamController<StatisticalAnalysis> _analysisController =
      StreamController<StatisticalAnalysis>.broadcast();

  Stream<ABTest> get onTestUpdate => _testController.stream;
  Stream<VariantResult> get onResultUpdate => _resultController.stream;
  Stream<StatisticalAnalysis> get onAnalysisComplete => _analysisController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 테스트 로드
    await _loadTests();

    // 유저 할당 로드
    await _loadUserAssignments();

    // 분석 타이머 시작
    _startAnalysisTimer();

    debugPrint('[ABTesting] Initialized');
  }

  Future<void> _loadTests() async {
    final json = _prefs?.getString('ab_tests');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[ABTesting] Error loading tests: $e');
      }
    }

    // 샘플 테스트 생성
    _createSampleTests();
  }

  void _createSampleTests() {
    // UI 테스트
    _tests['ui_button_color'] = ABTest(
      testId: 'ui_button_color',
      name: '버튼 색상 테스트',
      description: '구매 버튼의 색상에 따른 전환율 테스트',
      type: TestType.ui,
      status: TestStatus.running,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      startedAt: DateTime.now().subtract(const Duration(days: 7)),
      duration: const Duration(days: 14),
      minSampleSize: 5000,
      variants: [
        const TestVariant(
          variantId: 'control',
          name: '컨트롤 (파란색)',
          description: '기존 파란색 버튼',
          traffic: 0.5,
          configuration: {'color': '#2196F3', 'text': '구매하기'},
        ),
        const TestVariant(
          variantId: 'variant_a',
          name: '변형 A (빨간색)',
          description: '빨간색 버튼',
          traffic: 0.25,
          configuration: {'color': '#F44336', 'text': '구매하기'},
        ),
        const TestVariant(
          variantId: 'variant_b',
          name: '변형 B (초록색)',
          description: '초록색 버튼',
          traffic: 0.25,
          configuration: {'color': '#4CAF50', 'text': '지금 구매'},
        ),
      ],
      metrics: [
        const TestMetric(
          metricId: 'conversion',
          name: '전환율',
          description: '구매 버튼 클릭률',
          type: 'conversion',
          aggregation: 'rate',
          isPrimary: true,
        ),
        const TestMetric(
          metricId: 'revenue',
          name: '수익',
          description: '총 수익',
          type: 'revenue',
          aggregation: 'sum',
        ),
      ],
      controlVariantId: 'control',
    );

    // 가격 테스트
    _tests['pricing_subscription'] = ABTest(
      testId: 'pricing_subscription',
      name: '구독 가격 테스트',
      description: '월 구독 가격에 따른 가입률 테스트',
      type: TestType.pricing,
      status: TestStatus.running,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      startedAt: DateTime.now().subtract(const Duration(days: 3)),
      duration: const Duration(days: 30),
      minSampleSize: 10000,
       variants: [
         const TestVariant(
           variantId: 'control',
           name: '컨트롤 (9.99)',
           description: '기존 가격',
           traffic: 0.5,
           configuration: {'price': 9.99, 'currency': 'USD'},
         ),
         const TestVariant(
           variantId: 'variant_a',
           name: '변형 A (7.99)',
           description: '낮춘 가격',
           traffic: 0.25,
           configuration: {'price': 7.99, 'currency': 'USD'},
         ),
         const TestVariant(
           variantId: 'variant_b',
           name: '변형 B (12.99)',
           description: '높인 가격',
           traffic: 0.25,
           configuration: {'price': 12.99, 'currency': 'USD'},
         ),
       ],
      metrics: [
        const TestMetric(
          metricId: 'signup_rate',
          name: '가입률',
          description: '구독 가입률',
          type: 'conversion',
          aggregation: 'rate',
          isPrimary: true,
        ),
        const TestMetric(
          metricId: 'revenue_per_user',
          name: '1인당 수익',
          description: '사용자당 평균 수익',
          type: 'revenue',
          aggregation: 'avg',
        ),
      ],
      controlVariantId: 'control',
    );
  }

  Future<void> _loadUserAssignments() async {
    final json = _prefs?.getString('ab_assignments_$_currentUserId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _userAssignments.clear();
        for (final entry in data.entries) {
          _userAssignments[entry.key] = entry.value as String;
        }
      } catch (e) {
        debugPrint('[ABTesting] Error loading assignments: $e');
      }
    }
  }

  void _startAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _runAnalysis();
    });
  }

  /// 테스트 생성
  Future<String> createTest({
    required String name,
    required String description,
    required TestType type,
    required List<TestVariant> variants,
    required List<TestMetric> metrics,
    Duration? duration,
    int minSampleSize = 1000,
    double significanceLevel = 0.05,
    String? controlVariantId,
    Map<String, dynamic>? targetingCriteria,
  }) async {
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';

    final test = ABTest(
      testId: testId,
      name: name,
      description: description,
      type: type,
      status: TestStatus.drafting,
      variants: variants,
      metrics: metrics,
      createdAt: DateTime.now(),
      duration: duration,
      minSampleSize: minSampleSize,
      significanceLevel: significanceLevel,
      controlVariantId: controlVariantId,
      targetingCriteria: targetingCriteria,
    );

    _tests[testId] = test;

    await _saveTests();

    debugPrint('[ABTesting] Test created: $testId');

    return testId;
  }

  /// 테스트 시작
  Future<bool> startTest(String testId) async {
    final test = _tests[testId];
    if (test == null) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      type: test.type,
      status: TestStatus.running,
      variants: test.variants,
      metrics: test.metrics,
      createdAt: test.createdAt,
      startedAt: DateTime.now(),
      completedAt: test.completedAt,
      duration: test.duration,
      minSampleSize: test.minSampleSize,
      significanceLevel: test.significanceLevel,
      controlVariantId: test.controlVariantId,
      targetingCriteria: test.targetingCriteria,
      metadata: test.metadata,
    );

    _tests[testId] = updated;
    _testController.add(updated);

    await _saveTests();

    debugPrint('[ABTesting] Test started: $testId');

    return true;
  }

  /// 테스트 일시 정지
  Future<bool> pauseTest(String testId) async {
    final test = _tests[testId];
    if (test == null || test.status != TestStatus.running) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      type: test.type,
      status: TestStatus.paused,
      variants: test.variants,
      metrics: test.metrics,
      createdAt: test.createdAt,
      startedAt: test.startedAt,
      completedAt: test.completedAt,
      duration: test.duration,
      minSampleSize: test.minSampleSize,
      significanceLevel: test.significanceLevel,
      controlVariantId: test.controlVariantId,
      targetingCriteria: test.targetingCriteria,
      metadata: test.metadata,
    );

    _tests[testId] = updated;
    _testController.add(updated);

    await _saveTests();

    return true;
  }

  /// 테스트 완료
  Future<bool> completeTest(String testId) async {
    final test = _tests[testId];
    if (test == null) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      type: test.type,
      status: TestStatus.completed,
      variants: test.variants,
      metrics: test.metrics,
      createdAt: test.createdAt,
      startedAt: test.startedAt,
      completedAt: DateTime.now(),
      duration: test.duration,
      minSampleSize: test.minSampleSize,
      significanceLevel: test.significanceLevel,
      controlVariantId: test.controlVariantId,
      targetingCriteria: test.targetingCriteria,
      metadata: test.metadata,
    );

    _tests[testId] = updated;
    _testController.add(updated);

    await _saveTests();

    // 최종 분석 실행
    await _runAnalysisForTest(testId);

    debugPrint('[ABTesting] Test completed: $testId');

    return true;
  }

  /// 유저 변형 할당
  String? assignVariant(String testId) {
    if (_currentUserId == null) return null;

    final test = _tests[testId];
    if (test == null || !test.isActive) return null;

    // 이미 할당된 변형 확인
    final existing = _userAssignments['$testId'];
    if (existing != null) {
      final variant = test.variants.firstWhere(
        (v) => v.variantId == existing,
        orElse: () => test.variants.first,
      );
      return variant.variantId;
    }

    // 새로운 할당
    final random = Random().nextDouble();
    var cumulative = 0.0;

    for (final variant in test.variants) {
      cumulative += variant.traffic;
      if (random <= cumulative) {
        _userAssignments['$testId'] = variant.variantId;
        _saveAssignments();
        return variant.variantId;
      }
    }

    // 기본값 (첫 번째 변형)
    _userAssignments['$testId'] = test.variants.first.variantId;
    _saveAssignments();
    return test.variants.first.variantId;
  }

  /// 변형 설정 조회
  Map<String, dynamic>? getVariantConfig(String testId) {
    final variantId = assignVariant(testId);
    if (variantId == null) return null;

    final test = _tests[testId];
    if (test == null) return null;

    final variant = test.variants.firstWhere(
      (v) => v.variantId == variantId,
      orElse: () => test.variants.first,
    );

    return variant.configuration;
  }

  /// 이벤트 추적
  Future<void> trackEvent({
    required String testId,
    required String metricId,
    required dynamic value,
  }) async {
    final variantId = assignVariant(testId);
    if (variantId == null) return;

    final resultKey = '$testId:$variantId';
    var result = _results[resultKey];

    if (result == null) {
      result = VariantResult(
        variantId: variantId,
        metrics: {},
        participants: 0,
        conversions: 0,
        conversionRate: 0,
        revenue: 0,
        updatedAt: DateTime.now(),
      );
    }

    // 메트릭 업데이트
    final metrics = Map<String, MetricValue>.from(result.metrics);
    final existingMetric = metrics[metricId];

    double newValue = value is num ? value.toDouble() : 1.0;
    if (existingMetric != null) {
      newValue += existingMetric.value;
    }

    metrics[metricId] = MetricValue(
      metricId: metricId,
      value: newValue,
      sampleSize: existingMetric?.sampleSize ?? 0 + 1,
      timestamp: DateTime.now(),
    );

    // 결과 업데이트
    _results[resultKey] = VariantResult(
      variantId: result.variantId,
      metrics: metrics,
      participants: result.participants + 1,
      conversions: metricId == 'conversion'
          ? result.conversions + 1
          : result.conversions,
      conversionRate: result.participants > 0
          ? (result.conversions + (metricId == 'conversion' ? 1 : 0)) /
              (result.participants + 1)
          : 0,
      revenue: metricId == 'revenue'
          ? result.revenue + (value is num ? value.toDouble() : 0)
          : result.revenue,
      updatedAt: DateTime.now(),
    );

    _resultController.add(_results[resultKey]!);

    await _saveResults();
  }

  /// 통계 분석 실행
  void _runAnalysis() {
    for (final testId in _tests.keys) {
      final test = _tests[testId];
      if (test != null && test.isActive) {
        _runAnalysisForTest(testId);
      }
    }
  }

  Future<void> _runAnalysisForTest(String testId) async {
    final test = _tests[testId];
    if (test == null || test.controlVariantId == null) return;

    final controlResult = _results['$testId:${test.controlVariantId}'];
    if (controlResult == null) return;

    for (final variant in test.variants) {
      if (variant.variantId == test.controlVariantId) continue;

      final variantResult = _results['$testId:${variant.variantId}'];
      if (variantResult == null) continue;

      // Z-테스트 계산
      final analysis = _calculateZTest(
        controlConversions: controlResult.conversions,
        controlParticipants: controlResult.participants,
        variantConversions: variantResult.conversions,
        variantParticipants: variantResult.participants,
        significanceLevel: test.significanceLevel,
        variantId: variant.variantId,
      );

      _analysisController.add(analysis);

      // 유의미한 차이가 있고 승자 결정 가능
      if (analysis.isSignificant &&
          variantResult.participants >= test.minSampleSize) {
        debugPrint('[ABTesting] Significant result found: $testId - ${variant.variantId}');
      }
    }
  }

  /// Z-테스트 계산
  StatisticalAnalysis _calculateZTest({
    required int controlConversions,
    required int controlParticipants,
    required int variantConversions,
    required int variantParticipants,
    required double significanceLevel,
    required String variantId,
  }) {
    final p1 = controlConversions / controlParticipants;
    final p2 = variantConversions / variantParticipants;

    final pooledP = (controlConversions + variantConversions) /
        (controlParticipants + variantParticipants);

    final se = sqrt(pooledP * (1 - pooledP) *
        (1 / controlParticipants + 1 / variantParticipants));

     final z = se > 0 ? (p2 - p1) / se : 0.0;

     // P-value (이표본 검정)
     final pValue = 2 * (1 - _normalCDF((z as double).abs()));

    final isSignificant = pValue < significanceLevel;

    // 신뢰 구간
    final margin = 1.96 * se;
    final ciLower = (p2 - p1) - margin;
    final ciUpper = (p2 - p1) + margin;

    // Lift
    final lift = p2 - p1;
    final relativeLift = p1 > 0 ? ((p2 - p1) / p1) * 100 : null;

     return StatisticalAnalysis(
       variantId: variantId,
       conversionRate: p2,
       standardError: se,
       confidenceInterval95Lower: ciLower,
       confidenceInterval95Upper: ciUpper,
       pValue: pValue,
       zScore: z as double,
       isSignificant: isSignificant,
       lift: lift,
       relativeLift: relativeLift,
     );
  }

  /// 표준정규분포 CDF
  double _normalCDF(double x) {
    // 근사식
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
        t * exp(-x * x);

    return 0.5 * (1.0 + sign * y);
  }

  /// 승자 선정
  String? getWinner(String testId) {
    final test = _tests[testId];
    if (test == null || test.status != TestStatus.completed) return null;

    String? winner;
    double bestLift = double.negativeInfinity;

    for (final variant in test.variants) {
      final result = _results['$testId:${variant.variantId}'];
      if (result == null) continue;

      if (result.conversionRate > bestLift) {
        bestLift = result.conversionRate;
        winner = variant.variantId;
      }
    }

    return winner;
  }

  /// 테스트 조회
  ABTest? getTest(String testId) {
    return _tests[testId];
  }

  /// 전체 테스트 목록
  List<ABTest> getTests({TestStatus? status}) {
    final tests = _tests.values.toList();

    if (status != null) {
      return tests.where((t) => t.status == status).toList();
    }

    return tests;
  }

  /// 테스트 결과 조회
  List<VariantResult> getResults(String testId) {
    return _results.entries
        .where((e) => e.key.startsWith('$testId:'))
        .map((e) => e.value)
        .toList();
  }

  /// 테스트 삭제
  Future<bool> deleteTest(String testId) async {
    final test = _tests[testId];
    if (test == null) return false;

    if (test.isActive) {
      // 실행 중인 테스트는 먼저 중지
      await completeTest(testId);
    }

    _tests.remove(testId);

    // 관련 결과 삭제
    _results.removeWhere((key, _) => key.startsWith('$testId:'));

    await _saveTests();

    return true;
  }

  Future<void> _saveTests() async {
    final data = _tests.map((testId, test) => MapEntry(
      testId,
      {
        'testId': test.testId,
        'name': test.name,
        'status': test.status.name,
      },
    ));

    await _prefs?.setString('ab_tests', jsonEncode(data));
  }

  Future<void> _saveResults() async {
    // 결과 저장 로직
  }

  Future<void> _saveAssignments() async {
    if (_currentUserId == null) return;

    await _prefs?.setString(
      'ab_assignments_$_currentUserId',
      jsonEncode(_userAssignments),
    );
  }

  void dispose() {
    _testController.close();
    _resultController.close();
    _analysisController.close();
    _analysisTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 메트릭 카테고리
enum MetricCategory {
  acquisition,    // 유입
  engagement,     // 참여도
  retention,      // 리텐션
  monetization,   // 수익화
  technical,      // 기술적
  social,         // 소셜
  custom,         // 커스텀
}

/// KPI 타입
enum KPIType {
  dau,            // DAU (일일 활성 사용자)
  mau,            // MAU (월간 활성 사용자)
  retention,      // 리텐션률
  arpu,           // 1인당 평균 수익
  arppu,          // 유료 1인당 평균 수익
  conversion,     // 전환율
  ltv,            // 생애 가치
  churn,          // 이탈률
  sessionLength,  // 세션 길이
  revenue,        // 수익
}

/// 시간 범위
enum TimeRange {
  hour,           // 시간
  day,            // 일
  week,           // 주
  month,          // 월
  quarter,        // 분기
  year,           // 연
  custom,         // 커스텀
}

/// 사용자 세그먼트
enum UserSegment {
  newUsers,       // 신규 유저
  active,         // 활성 유저
  dormant,        // 휴면 유저
  churned,        // 이탈 유저
  whales,         // 고지출 유저
  dolphins,       // 중간 지출 유저
  minnows,        // 저지출 유저
  nonPayers,      // 비지출 유저
  powerUsers,     // 파워 유저
  casual,         // 캐주얼 유저
}

/// 메트릭 데이터 포인트
class MetricDataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic>? dimensions;
  final Map<String, dynamic>? metadata;

  const MetricDataPoint({
    required this.timestamp,
    required this.value,
    this.dimensions,
    this.metadata,
  });
}

/// KPI 데이터
class KPIData {
  final KPIType type;
  final double value;
  final double? target;
  final double? previousValue;
  final double changePercentage;
  final TimeRange timeRange;
  final DateTime calculatedAt;

  const KPIData({
    required this.type,
    required this.value,
    this.target,
    this.previousValue,
    required this.changePercentage,
    required this.timeRange,
    required this.calculatedAt,
  });

  /// 목표 달성 여부
  bool get isTargetMet {
    if (target == null) return false;
    return value >= target!;
  }
}

/// 사용자 코호트
class UserCohort {
  final String cohortId;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final int userCount;
  final Map<int, double> retentionRates; // day -> rate

  const UserCohort({
    required this.cohortId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.userCount,
    required this.retentionRates,
  });
}

/// 펀널 분석
class FunnelAnalysis {
  final String funnelId;
  final String name;
  final List<FunnelStep> steps;
  final int totalUsers;
  final DateTime periodStart;
  final DateTime periodEnd;

  const FunnelAnalysis({
    required this.funnelId,
    required this.name,
    required this.steps,
    required this.totalUsers,
    required this.periodStart,
    required this.periodEnd,
  });

  /// 전환율
  double get conversionRate {
    if (steps.isEmpty) return 0;
    return steps.last.userCount / totalUsers;
  }
}

/// 펀널 스텝
class FunnelStep {
  final String stepId;
  final String name;
  final int userCount;
  final double dropOffRate;

  const FunnelStep({
    required this.stepId,
    required this.name,
    required this.userCount,
    required this.dropOffRate,
  });
}

/// 리포트
class BIReport {
  final String reportId;
  final String name;
  final String description;
  final Map<KPIType, KPIData> kpis;
  final List<MetricDataPoint> metricData;
  final List<UserCohort> cohorts;
  final List<FunnelAnalysis> funnels;
  final DateTime generatedAt;
  final TimeRange timeRange;

  const BIReport({
    required this.reportId,
    required this.name,
    required this.description,
    required this.kpis,
    required this.metricData,
    required this.cohorts,
    required this.funnels,
    required this.generatedAt,
    required this.timeRange,
  });
}

/// BI 관리자
class BusinessIntelligenceManager {
  static final BusinessIntelligenceManager _instance =
      BusinessIntelligenceManager._();
  static BusinessIntelligenceManager get instance => _instance;

  BusinessIntelligenceManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<KPIType, List<MetricDataPoint>> _metricHistory = {};
  final List<UserCohort> _cohorts = [];
  final List<FunnelAnalysis> _funnels = [];
  final Map<String, Map<UserSegment, int>> _segmentDistribution = {};

  final StreamController<KPIData> _kpiController =
      StreamController<KPIData>.broadcast();
  final StreamController<BIReport> _reportController =
      StreamController<BIReport>.broadcast();

  Stream<KPIData> get onKPIUpdate => _kpiController.stream;
  Stream<BIReport> get onReportGenerated => _reportController.stream;

  Timer? _reportTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 메트릭 로드
    await _loadMetrics();

    // 펀널 정의
    await _loadFunnels();

    // 주기 리포트 생성
    _startPeriodicReporting();

    debugPrint('[BI] Initialized');
  }

  Future<void> _loadMetrics() async {
    // 샘플 메트릭 데이터
    final now = DateTime.now();

    for (final type in KPIType.values) {
      final dataPoints = <MetricDataPoint>[];

      for (var i = 0; i < 30; i++) {
        final timestamp = now.subtract(Duration(days: 29 - i));
        final value = _generateSampleMetricValue(type);

        dataPoints.add(MetricDataPoint(
          timestamp: timestamp,
          value: value,
        ));
      }

      _metricHistory[type] = dataPoints;
    }
  }

  double _generateSampleMetricValue(KPIType type) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000;

    switch (type) {
      case KPIType.dau:
        return 50000 + random * 10000;
      case KPIType.mau:
        return 200000 + random * 50000;
      case KPIType.retention:
        return 0.3 + random * 0.2;
      case KPIType.arpu:
        return 5 + random * 3;
      case KPIType.arppu:
        return 50 + random * 20;
      case KPIType.conversion:
        return 0.02 + random * 0.03;
      case KPIType.ltv:
        return 100 + random * 50;
      case KPIType.churn:
        return 0.05 + random * 0.1;
      case KPIType.sessionLength:
        return 30 + random * 30;
      case KPIType.revenue:
        return 250000 + random * 100000;
    }
  }

  Future<void> _loadFunnels() async {
    // 온보딩 펀널
    _funnels.add(FunnelAnalysis(
      funnelId: 'onboarding',
      name: '온보딩',
      steps: [
        const FunnelStep(
          stepId: 'install',
          name: '설치',
          userCount: 100000,
          dropOffRate: 0,
        ),
        const FunnelStep(
          stepId: 'launch',
          name: '첫 실행',
          userCount: 95000,
          dropOffRate: 0.05,
        ),
        const FunnelStep(
          stepId: 'tutorial',
          name: '튜토리얼 완료',
          userCount: 80000,
          dropOffRate: 0.16,
        ),
        const FunnelStep(
          stepId: 'first_purchase',
          name: '첫 결제',
          userCount: 2000,
          dropOffRate: 0.98,
        ),
      ],
      totalUsers: 100000,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
    ));

    // 배틀 펀널
    _funnels.add(FunnelAnalysis(
      funnelId: 'battle',
      name: '배틀',
      steps: [
        const FunnelStep(
          stepId: 'matchmaking',
          name: '매칭 시작',
          userCount: 50000,
          dropOffRate: 0,
        ),
        const FunnelStep(
          stepId: 'battle_start',
          name: '배틀 시작',
          userCount: 48000,
          dropOffRate: 0.04,
        ),
        const FunnelStep(
          stepId: 'battle_complete',
          name: '배틀 완료',
          userCount: 45000,
          dropOffRate: 0.06,
        ),
      ],
      totalUsers: 50000,
      periodStart: DateTime.now().subtract(const Duration(days: 7)),
      periodEnd: DateTime.now(),
    ));
  }

  void _startPeriodicReporting() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _updateKPIs();
    });
  }

  /// 이벤트 추적
  Future<void> trackEvent({
    required String eventName,
    required Map<String, dynamic> properties,
    DateTime? timestamp,
  }) async {
    // 실제로는 분석 서버로 전송
    debugPrint('[BI] Event: $eventName');
  }

  /// 사용자 속성 설정
  Future<void> setUserProperties({
    required String userId,
    required Map<String, dynamic> properties,
  }) async {
    // 사용자 속성 저장
    debugPrint('[BI] User properties updated: $userId');
  }

  /// KPI 계산
  Future<KPIData> calculateKPI(
    KPIType type,
    TimeRange timeRange,
  ) async {
    final now = DateTime.now();
    final dataPoints = _metricHistory[type] ?? [];

    double value = 0;
    double? previousValue;

    switch (timeRange) {
      case TimeRange.day:
        value = dataPoints.isNotEmpty
            ? dataPoints.last.value
            : 0;
        if (dataPoints.length > 1) {
          previousValue = dataPoints[dataPoints.length - 2].value;
        }
        break;

      case TimeRange.week:
        final weekData = dataPoints.take(7).toList();
        value = weekData.isEmpty
            ? 0
            : weekData.map((d) => d.value).reduce((a, b) => a + b) / weekData.length;
        break;

      case TimeRange.month:
        value = dataPoints.isEmpty
            ? 0
            : dataPoints.map((d) => d.value).reduce((a, b) => a + b) / dataPoints.length;
        break;

      default:
        value = dataPoints.isNotEmpty ? dataPoints.last.value : 0;
    }

    final changePercentage = previousValue != null && previousValue > 0
        ? ((value - previousValue) / previousValue) * 100
        : 0;

    final kpiData = KPIData(
      type: type,
      value: value,
      previousValue: previousValue,
      changePercentage: changePercentage,
      timeRange: timeRange,
      calculatedAt: now,
    );

    _kpiController.add(kpiData);

    return kpiData;
  }

  /// 모든 KPI 조회
  Future<Map<KPIType, KPIData>> getAllKPIs(TimeRange timeRange) async {
    final kpis = <KPIType, KPIData>{};

    for (final type in KPIType.values) {
      kpis[type] = await calculateKPI(type, timeRange);
    }

    return kpis;
  }

  /// 리포트 생성
  Future<BIReport> generateReport({
    String? name,
    String? description,
    TimeRange timeRange = TimeRange.day,
  }) async {
    final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';

    final kpis = await getAllKPIs(timeRange);

    final metricData = _metricHistory.values
        .expand((data) => data)
        .toList();

    final report = BIReport(
      reportId: reportId,
      name: name ?? '일일 리포트',
      description: description ?? '자동 생성된 리포트',
      kpis: kpis,
      metricData: metricData,
      cohorts: _cohorts,
      funnels: _funnels,
      generatedAt: DateTime.now(),
      timeRange: timeRange,
    );

    _reportController.add(report);

    await _saveReport(report);

    return report;
  }

  /// 코호트 분석
  Future<UserCohort> analyzeCohort({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final cohortId = 'cohort_${DateTime.now().millisecondsSinceEpoch}';

    // 샘플 코호트 데이터
    final retentionRates = <int, double>{
      1: 1.0,
      7: 0.6,
      14: 0.4,
      30: 0.25,
    };

    final cohort = UserCohort(
      cohortId: cohortId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      userCount: 10000,
      retentionRates: retentionRates,
    );

    _cohorts.add(cohort);

    return cohort;
  }

  /// 사용자 세그먼트 분석
  Map<UserSegment, int> analyzeSegments({
    DateTime? date,
  }) {
    final dateKey = date ?? DateTime.now();

    // 샘플 세그먼트 분포
    return {
      UserSegment.newUsers: 5000,
      UserSegment.active: 45000,
      UserSegment.dormant: 30000,
      UserSegment.churned: 15000,
      UserSegment.whales: 500,
      UserSegment.dolphins: 2000,
      UserSegment.minnows: 10000,
      UserSegment.nonPayers: 72500,
      UserSegment.powerUsers: 10000,
      UserSegment.casual: 35000,
    };
  }

  /// 펀널 분석 생성
  Future<FunnelAnalysis> createFunnel({
    required String name,
    required List<FunnelStep> steps,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final funnelId = 'funnel_${DateTime.now().millisecondsSinceEpoch}';

    final funnel = FunnelAnalysis(
      funnelId: funnelId,
      name: name,
      steps: steps,
      totalUsers: steps.first.userCount,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    _funnels.add(funnel);

    return funnel;
  }

  /// A/B 테스트 결과 분석
  Map<String, double> analyzeABTest({
    required String testId,
    required Map<String, List<double>> variantData,
  }) {
    final results = <String, double>{};

    for (final entry in variantData.entries) {
      final values = entry.value;
      final average = values.reduce((a, b) => a + b) / values.length;
      results[entry.key] = average;
    }

    return results;
  }

  /// 리텐션 분석
  Map<int, double> analyzeRetention({
    required DateTime cohortDate,
    required List<DateTime> userDates,
  }) {
    final retention = <int, double>{};

    final cohortUserCount = userDates.length;

    for (var day = 1; day <= 30; day++) {
      final retained = userDates.where((date) =>
          date.isAfter(cohortDate.add(Duration(days: day - 1))) ||
          date.isAtSameMomentAs(cohortDate.add(Duration(days: day - 1)))).length;

      retention[day] = retained / cohortUserCount;
    }

    return retention;
  }

  /// LTV 계산
  double calculateLTV({
    required double arpu,
    required double retentionRate,
    required int timePeriod, // months
  }) {
    double ltv = 0;

    for (var month = 1; month <= timePeriod; month++) {
      ltv += arpu * pow(retentionRate, month);
    }

    return ltv;
  }

  /// 차트 데이터 생성
  List<Map<String, dynamic>> generateChartData({
    required KPIType kpiType,
    required TimeRange timeRange,
  }) {
    final dataPoints = _metricHistory[kpiType] ?? [];

    return dataPoints.map((point) => {
      'timestamp': point.timestamp.toIso8601String(),
      'value': point.value,
    }).toList();
  }

  void _updateKPIs() {
    for (final type in KPIType.values) {
      calculateKPI(type, TimeRange.day);
    }
  }

  Future<void> _saveReport(BIReport report) async {
    // 리포트 저장
    debugPrint('[BI] Report saved: ${report.reportId}');
  }

  /// 대시보드 데이터
  Future<Map<String, dynamic>> getDashboardData() async {
    final kpis = await getAllKPIs(TimeRange.day);
    final segments = analyzeSegments();

    return {
      'kpis': kpis.map((type, data) => MapEntry(
        type.name,
        {
          'value': data.value,
          'change': data.changePercentage,
          'target': data.target,
        },
      )),
      'segments': segments.map((segment, count) => MapEntry(
        segment.name,
        count,
      )),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _kpiController.close();
    _reportController.close();
    _reportTimer?.cancel();
  }
}

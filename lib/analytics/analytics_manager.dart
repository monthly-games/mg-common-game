import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 메트릭 타입
enum MetricType {
  counter,      // 카운터 (로그인 횟수 등)
  gauge,        // 게이지 (현재 접속자 등)
  histogram,    // 히스토그램 (로딩 시간 분포 등)
  summary,      // 요약 (배틀 시간 등)
}

/// 시간 범위
enum TimeRange {
  hour,         // 1시간
  day,          // 1일
  week,         // 1주
  month,        // 1달
  quarter,      // 1분기
  year,         // 1년
}

/// 이벤트 카테고리
enum EventCategory {
  acquisition,  // 획득 (가입, 설치)
  activation,   // 활성화 (첫 세션, 튜토리얼)
  retention,    // 리텐션 (재방문, 재구매)
  revenue,      // 매출 (결제, 아이템 구매)
  referral,     // 추천 (초대, 공유)
  engagement,   // 참여도 (플레이 시간, 세션)
}

/// 퍼널 단계
class FunnelStep {
  final String id;
  final String name;
  final int userCount;
  final double conversionRate;
  final double dropOffRate;
  final DateTime timestamp;

  const FunnelStep({
    required this.id,
    required this.name,
    required this.userCount,
    required this.conversionRate,
    required this.dropOffRate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'userCount': userCount,
        'conversionRate': conversionRate,
        'dropOffRate': dropOffRate,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 퍼널 데이터
class FunnelData {
  final String id;
  final String name;
  final List<FunnelStep> steps;
  final double overallConversion;
  final DateTime startDate;
  final DateTime endDate;

  const FunnelData({
    required this.id,
    required this.name,
    required this.steps,
    required this.overallConversion,
    required this.startDate,
    required this.endDate,
  });
}

/// 리텐션 데이터
class RetentionData {
  final DateTime cohortDate;
  final int cohortSize;
  final Map<int, double> retentionRates; // day 1, day 7, day 30 etc.
  final Map<int, int> retainedUsers;

  const RetentionData({
    required this.cohortDate,
    required this.cohortSize,
    required this.retentionRates,
    required this.retainedUsers,
  });

  double getRetentionRate(int day) {
    return retentionRates[day] ?? 0.0;
  }
}

/// 매출 데이터
class RevenueData {
  final DateTime date;
  final double totalRevenue;
  final int transactionCount;
  final double arpu; // Average Revenue Per User
  final double arppu; // Average Revenue Per Paying User
  final Map<String, double> revenueByProduct;

  const RevenueData({
    required this.date,
    required this.totalRevenue,
    required this.transactionCount,
    required this.arpu,
    required this.arppu,
    required this.revenueByProduct,
  });
}

/// 사용자 행동 이벤트
class UserEvent {
  final String id;
  final String name;
  final EventCategory category;
  final Map<String, dynamic> properties;
  final String? userId;
  final DateTime timestamp;
  final double? value;

  UserEvent({
    required this.name,
    required this.category,
    this.properties = const {},
    this.userId,
    DateTime? timestamp,
    this.value,
  })  : id = '${name}_${timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'properties': properties,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      };
}

/// 메트릭 데이터
class MetricData {
  final String name;
  final MetricType type;
  final double value;
  final Map<String, dynamic>? tags;
  final DateTime timestamp;

  const MetricData({
    required this.name,
    required this.type,
    required this.value,
    this.tags,
    required this.timestamp,
  });
}

/// 대시보드 위젯
class DashboardWidget {
  final String id;
  final String title;
  final String type; // chart, number, table, funnel
  final Map<String, dynamic> config;
  final int refreshInterval;

  const DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    this.config = const {},
    this.refreshInterval = 60,
  });
}

/// 분석 관리자
class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._();
  static AnalyticsManager get instance => _instance;

  AnalyticsManager._();

  SharedPreferences? _prefs;
  String? _userId;

  final List<UserEvent> _events = [];
  final List<MetricData> _metrics = [];
  final Map<String, FunnelData> _funnels = {};
  final Map<String, RetentionData> _retentionData = {};
  final List<RevenueData> _revenueHistory = [];

  final StreamController<UserEvent> _eventController =
      StreamController<UserEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _dashboardController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<UserEvent> get onEvent => _eventController.stream;
  Stream<Map<String, dynamic>> get onDashboardUpdate => _dashboardController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs?.getString('user_id');

    // 기본 퍼널 로드
    _loadDefaultFunnels();

    // 리텐션 데이터 로드
    _loadRetentionData();

    // 매출 데이터 로드
    _loadRevenueData();

    debugPrint('[Analytics] Initialized');
  }

  void _loadDefaultFunnels() {
    final now = DateTime.now();

    // 가입 퍼널
    _funnels['registration'] = FunnelData(
      id: 'registration',
      name: '회원가입 퍼널',
      steps: [
        FunnelStep(
          id: 'app_install',
          name: '앱 설치',
          userCount: 10000,
          conversionRate: 1.0,
          dropOffRate: 0.0,
          timestamp: now,
        ),
        FunnelStep(
          id: 'first_open',
          name: '첫 실행',
          userCount: 8000,
          conversionRate: 0.8,
          dropOffRate: 0.2,
          timestamp: now,
        ),
        FunnelStep(
          id: 'tutorial_start',
          name: '튜토리얼 시작',
          userCount: 6000,
          conversionRate: 0.6,
          dropOffRate: 0.25,
          timestamp: now,
        ),
        FunnelStep(
          id: 'tutorial_complete',
          name: '튜토리얼 완료',
          userCount: 4500,
          conversionRate: 0.45,
          dropOffRate: 0.25,
          timestamp: now,
        ),
        FunnelStep(
          id: 'sign_up',
          name: '회원가입',
          userCount: 3000,
          conversionRate: 0.3,
          dropOffRate: 0.33,
          timestamp: now,
        ),
      ],
      overallConversion: 0.3,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );

    // 결제 퍼널
    _funnels['purchase'] = FunnelData(
      id: 'purchase',
      name: '결제 퍼널',
      steps: [
        FunnelStep(
          id: 'store_visit',
          name: '상점 방문',
          userCount: 5000,
          conversionRate: 1.0,
          dropOffRate: 0.0,
          timestamp: now,
        ),
        FunnelStep(
          id: 'item_view',
          name: '아이템 조회',
          userCount: 3000,
          conversionRate: 0.6,
          dropOffRate: 0.4,
          timestamp: now,
        ),
        FunnelStep(
          id: 'add_to_cart',
          name: '장바구니 담기',
          userCount: 1500,
          conversionRate: 0.3,
          dropOffRate: 0.5,
          timestamp: now,
        ),
        FunnelStep(
          id: 'checkout',
          name: '결제',
          userCount: 800,
          conversionRate: 0.16,
          dropOffRate: 0.47,
          timestamp: now,
        ),
        FunnelStep(
          id: 'purchase_complete',
          name: '결제 완료',
          userCount: 700,
          conversionRate: 0.14,
          dropOffRate: 0.125,
          timestamp: now,
        ),
      ],
      overallConversion: 0.14,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }

  void _loadRetentionData() {
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final cohortDate = now.subtract(Duration(days: i));
      final cohortSize = 1000 - (i * 20);

      _retentionData[cohortDate.toIso8601String()] = RetentionData(
        cohortDate: cohortDate,
        cohortSize: cohortSize,
        retentionRates: {
          1: 0.7 - (i * 0.01),
          7: 0.4 - (i * 0.01),
          30: 0.2 - (i * 0.005),
        },
        retainedUsers: {
          1: ((0.7 - (i * 0.01)) * cohortSize).toInt(),
          7: ((0.4 - (i * 0.01)) * cohortSize).toInt(),
          30: ((0.2 - (i * 0.005)) * cohortSize).toInt(),
        },
      );
    }
  }

  void _loadRevenueData() {
    final now = DateTime.now();

    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final baseRevenue = 10000.0 + (i * 100.0);

      _revenueHistory.add(RevenueData(
        date: date,
        totalRevenue: baseRevenue,
        transactionCount: 500 + (i % 100),
        arpu: baseRevenue / 10000,
        arppu: baseRevenue / 500,
        revenueByProduct: {
          'gem_pack': baseRevenue * 0.6,
          'gold_pack': baseRevenue * 0.3,
          'subscription': baseRevenue * 0.1,
        },
      ));
    }
  }

  /// 이벤트 트래킹
  void trackEvent({
    required String name,
    required EventCategory category,
    Map<String, dynamic> properties = const {},
    double? value,
  }) {
    final event = UserEvent(
      name: name,
      category: category,
      properties: properties,
      userId: _userId,
      value: value,
    );

    _events.add(event);
    _eventController.add(event);

    debugPrint('[Analytics] Event: $name (${category.name})');
  }

  /// 메트릭 기록
  void recordMetric({
    required String name,
    required MetricType type,
    required double value,
    Map<String, dynamic>? tags,
  }) {
    final metric = MetricData(
      name: name,
      type: type,
      value: value,
      tags: tags,
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);

    debugPrint('[Analytics] Metric: $name = $value');
  }

  /// 퍼널 데이터 조회
  FunnelData? getFunnel(String funnelId) {
    return _funnels[funnelId];
  }

  /// 모든 퍼널 조회
  List<FunnelData> getFunnels() {
    return _funnels.values.toList();
  }

  /// 리텐션 데이터 조회
  RetentionData? getRetentionData(String cohortDate) {
    return _retentionData[cohortDate];
  }

  /// 리텐션 코호트 목록
  List<RetentionData> getRetentionCohorts({int days = 30}) {
    final cohorts = _retentionData.values.toList()
      ..sort((a, b) => b.cohortDate.compareTo(a.cohortDate));

    return cohorts.take(days).toList();
  }

  /// 매출 데이터 조회
  List<RevenueData> getRevenueData({TimeRange range = TimeRange.month}) {
    final now = DateTime.now();
    DateTime startDate;

    switch (range) {
      case TimeRange.day:
        startDate = now.subtract(const Duration(days: 1));
        break;
      case TimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.quarter:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case TimeRange.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    return _revenueHistory
        .where((data) => data.date.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// DAU/MAU 계산
  double getStickiness({int days = 30}) {
    // DAU / MAU 계산
    final now = DateTime.now();
    final mauEvents = _events.where((e) =>
        e.timestamp.isAfter(now.subtract(const Duration(days: 30)))).length;
    final dauEvents = _events.where((e) =>
        e.timestamp.isAfter(now.subtract(const Duration(days: 1)))).length;

    if (mauEvents == 0) return 0.0;
    return dauEvents / mauEvents;
  }

  /// 세션 시간 추적
  DateTime? _sessionStart;
  Duration get sessionDuration {
    if (_sessionStart == null) return Duration.zero;
    return DateTime.now().difference(_sessionStart!);
  }
  
  /// 세션 시작
  void startSession() {
    _sessionStart = DateTime.now();
  }

  /// 화면 뷰 트래킹
  void trackScreenView({
    required String screenName,
    Map<String, dynamic> properties = const {},
  }) {
    trackEvent(
      name: 'screen_view',
      category: EventCategory.engagement,
      properties: {
        'screen_name': screenName,
        ...properties,
      },
    );
  }

  /// 사용자 속성 설정
  void setUserProperties(Map<String, dynamic> properties) {
    debugPrint('[Analytics] User properties updated: $properties');
    // 실제 구현에서는 원격 서버로 전송
  }

  /// 대시보드 데이터 조회
  Future<Map<String, dynamic>> getDashboardData({
    TimeRange range = TimeRange.week,
  }) async {
    final revenueData = getRevenueData(range: range);
    final totalRevenue = revenueData.fold<double>(
        0.0, (sum, data) => sum + data.totalRevenue);

    final retentionCohorts = getRetentionCohorts();
    final avgDay1Retention = retentionCohorts.isEmpty
        ? 0.0
        : retentionCohorts
            .map((c) => c.getRetentionRate(1))
            .reduce((a, b) => a + b) / retentionCohorts.length;

    final avgDay7Retention = retentionCohorts.isEmpty
        ? 0.0
        : retentionCohorts
            .map((c) => c.getRetentionRate(7))
            .reduce((a, b) => a + b) / retentionCohorts.length;

    return {
      'revenue': {
        'total': totalRevenue,
        'average': revenueData.isEmpty ? 0.0 : totalRevenue / revenueData.length,
        'trend': _calculateTrend(revenueData.map((d) => d.totalRevenue).toList()),
      },
      'retention': {
        'day1': avgDay1Retention,
        'day7': avgDay7Retention,
        'day30': retentionCohorts.isEmpty
            ? 0.0
            : retentionCohorts
                .map((c) => c.getRetentionRate(30))
                .reduce((a, b) => a + b) / retentionCohorts.length,
      },
      'engagement': {
        'stickiness': getStickiness(),
        'avgSessionDuration': _calculateAverageSessionDuration(),
      },
      'funnels': _funnels.values.map((f) => {
        'id': f.id,
        'name': f.name,
        'conversion': f.overallConversion,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  List<double> _calculateTrend(List<double> values) {
    if (values.isEmpty) return [];

    // 간단한 이동 평균 계산
    final windowSize = 7;
    final trends = <double>[];

    for (int i = windowSize; i < values.length; i++) {
      final window = values.sublist(i - windowSize, i);
      final avg = window.reduce((a, b) => a + b) / windowSize;
      trends.add(avg);
    }

    return trends;
  }

  double _calculateAverageSessionDuration() {
    // 세션 지속 시간 계산 (시뮬레이션)
    return 300.0; // 5분
  }

  /// 사용자 ID 설정
  void setUserId(String userId) {
    _userId = userId;
    setUserProperties({'user_id': userId});
  }

  /// 이벤트 내보내기
  String exportEvents({int limit = 1000}) {
    final events = _events.take(limit).toList();
    final json = jsonEncode(events.map((e) => e.toJson()).toList());
    return json;
  }

  /// 매출 예측
  Future<Map<String, dynamic>> predictRevenue({int days = 30}) async {
    final revenueData = getRevenueData(range: TimeRange.month);

    if (revenueData.isEmpty) {
      return {
        'predicted': 0.0,
        'confidence': 0.0,
      };
    }

    // 간단한 선형 회귀 (시뮬레이션)
    final values = revenueData.map((d) => d.totalRevenue).toList();
    final avgRevenue = values.reduce((a, b) => a + b) / values.length;
    final trend = values.length > 1
        ? (values.last - values.first) / values.length
        : 0.0;

    final predicted = avgRevenue + (trend * days);
    final confidence = 0.7; // 70% 신뢰도

    return {
      'predicted': predicted,
      'confidence': confidence,
      'trend': trend > 0 ? 'up' : trend < 0 ? 'down' : 'stable',
    };
  }

  void dispose() {
    _eventController.close();
    _dashboardController.close();
  }
}

/// 차트 데이터 포맷터
class ChartDataFormatter {
  /// 시계열 데이터 포맷
  static List<Map<String, dynamic>> formatTimeSeries(
    List<RevenueData> data, {
    String valueKey = 'totalRevenue',
    String dateKey = 'date',
  }) {
    return data.map((d) => {
      dateKey: d.date.toIso8601String(),
      valueKey: d.totalRevenue,
    }).toList();
  }

  /// 퍼널 차트 데이터 포맷
  static List<Map<String, dynamic>> formatFunnel(FunnelData funnel) {
    return funnel.steps.map((step) => {
      'name': step.name,
      'value': step.userCount,
      'conversion': step.conversionRate,
    }).toList();
  }

  /// 코호트 히트맵 데이터
  static List<Map<String, dynamic>> formatCohortHeatmap(
    List<RetentionData> cohorts,
  ) {
    return cohorts.map((cohort) => {
      'cohort': cohort.cohortDate.toIso8601String(),
      'size': cohort.cohortSize,
      'retention': cohort.retentionRates,
    }).toList();
  }
}

/// AARRR 프레임워크 트래커
class AARRRTracker {
  final AnalyticsManager _analytics = AnalyticsManager.instance;

  /// Acquisition - 획득
  void trackAcquisition({required String source, String? campaign}) {
    _analytics.trackEvent(
      name: 'acquisition',
      category: EventCategory.acquisition,
      properties: {
        'source': source,
        'campaign': campaign,
      },
    );
  }

  /// Activation - 활성화
  void trackActivation({required String milestone}) {
    _analytics.trackEvent(
      name: 'activation',
      category: EventCategory.activation,
      properties: {
        'milestone': milestone,
      },
    );
  }

  /// Retention - 리텐션
  void trackRetention({required String action}) {
    _analytics.trackEvent(
      name: 'retention',
      category: EventCategory.retention,
      properties: {
        'action': action,
      },
    );
  }

  /// Revenue - 매출
  void trackRevenue({
    required String product,
    required double amount,
    String? currency,
  }) {
    _analytics.trackEvent(
      name: 'revenue',
      category: EventCategory.revenue,
      properties: {
        'product': product,
        'currency': currency ?? 'USD',
      },
      value: amount,
    );
  }

  /// Referral - 추천
  void trackReferral({required String method, String? referredUserId}) {
    _analytics.trackEvent(
      name: 'referral',
      category: EventCategory.referral,
      properties: {
        'method': method,
        'referred_user_id': referredUserId,
      },
    );
  }
}

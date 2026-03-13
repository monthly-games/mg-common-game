import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 대시보드 위젯 타입
enum WidgetType {
  metric,          // 메트릭 카드
  chart,           // 차트
  list,            // 리스트
  alert,           // 알림
  activity,        // 액티비티 피드
  serverStatus,    // 서버 상태
  userMap,         // 유저 지도
  leaderboard,     // 리더보드
}

/// 메트릭 타입
enum MetricType {
  count,           // 카운트
  percentage,      // 백분율
  currency,        // 통화
  duration,        // 시간
  rate,            // 비율
}

/// 알림 심각도
enum AlertSeverity {
  info,            // 정보
  warning,         // 경고
  error,           // 에러
  critical,        // 심각
}

/// 차트 타입
enum ChartType {
  line,            // 라인 차트
  bar,             // 바 차트
  pie,             // 파이 차트
  area,            // 영역 차트
  gauge,           // 게이지
}

/// 대시보드 메트릭
class DashboardMetric {
  final String id;
  final String title;
  final String? subtitle;
  final dynamic value;
  final String? unit;
  final MetricType type;
  final String? icon;
  final Color? color;
  final Trend? trend;
  final String? onClickAction;

  const DashboardMetric({
    required this.id,
    required this.title,
    this.subtitle,
    required this.value,
    this.unit,
    required this.type,
    this.icon,
    this.color,
    this.trend,
    this.onClickAction,
  });
}

/// 트렌드
class Trend {
  final double value; // +10%, -5%, etc.
  final TrendDirection direction;

  const Trend({
    required this.value,
    required this.direction,
  });
}

enum TrendDirection {
  up,
  down,
  neutral,
}

/// 차트 데이터
class ChartData {
  final String id;
  final String title;
  final ChartType type;
  final List<DataPoint> dataPoints;
  final Map<String, String>? labels;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final Color? color;

  const ChartData({
    required this.id,
    required this.title,
    required this.type,
    required this.dataPoints,
    this.labels,
    this.xAxisLabel,
    this.yAxisLabel,
    this.color,
  });
}

/// 데이터 포인트
class DataPoint {
  final String label;
  final double value;
  final String? group;
  final DateTime? timestamp;

  const DataPoint({
    required this.label,
    required this.value,
    this.group,
    this.timestamp,
  });
}

/// 알림
class Alert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? actionUrl;
  final bool isRead;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.expiresAt,
    this.actionUrl,
    required this.isRead,
  });
}

/// 액티비티
class Activity {
  final String id;
  final String title;
  final String description;
  final String? icon;
  final ActivityType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    this.icon,
    required this.type,
    required this.timestamp,
    this.metadata,
  });
}

enum ActivityType {
  user,
  system,
  security,
  performance,
  business,
}

/// 대시보드 위젯
class DashboardWidget {
  final String id;
  final String title;
  final WidgetType type;
  final int rowSpan;
  final int columnSpan;
  final int position; // 0-11 (12-grid)
  final Map<String, dynamic> config;

  const DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    this.rowSpan = 1,
    this.columnSpan = 3,
    required this.position,
    required this.config,
  });
}

/// 대시보드
class Dashboard {
  final String id;
  final String name;
  final String description;
  final List<DashboardWidget> widgets;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final String? ownerUserId;

  const Dashboard({
    required this.id,
    required this.name,
    required this.description,
    required this.widgets,
    required this.createdAt,
    this.updatedAt,
    required this.isPublic,
    this.ownerUserId,
  });
}

/// 대시보드 관리자
class DashboardManager {
  static final DashboardManager _instance = DashboardManager._();
  static DashboardManager get instance => _instance;

  DashboardManager._();

  SharedPreferences? _prefs;

  final Map<String, Dashboard> _dashboards = {};
  final Map<String, List<DashboardMetric>> _metrics = {};
  final Map<String, List<ChartData>> _charts = {};
  final Map<String, List<Alert>> _alerts = {};
  final Map<String, List<Activity>> _activities = {};

  final StreamController<DashboardMetric> _metricController =
      StreamController<DashboardMetric>.broadcast();
  final StreamController<Alert> _alertController =
      StreamController<Alert>.broadcast();
  final StreamController<Activity> _activityController =
      StreamController<Activity>.broadcast();

  Stream<DashboardMetric> get onMetricUpdate => _metricController.stream;
  Stream<Alert> get onAlert => _alertController.stream;
  Stream<Activity> get onActivity => _activityController.stream;

  Timer? _updateTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 대시보드 로드
    await _loadDefaultDashboards();

    // 데이터 업데이트 시작
    _startDataUpdates();

    debugPrint('[Dashboard] Initialized');
  }

  Future<void> _loadDefaultDashboards() async {
    // 메인 대시보드
    final mainDashboard = Dashboard(
      id: 'main',
      name: '메인 대시보드',
      description: '게임运营 대시보드',
      widgets: [
        const DashboardWidget(
          id: 'widget_users',
          title: '실시간 유저',
          type: WidgetType.metric,
          position: 0,
          config: {'metric_id': 'online_users'},
        ),
        const DashboardWidget(
          id: 'widget_revenue',
          title: '매출',
          type: WidgetType.metric,
          position: 3,
          config: {'metric_id': 'daily_revenue'},
        ),
        const DashboardWidget(
          id: 'widget_chart',
          title: '유저 추이',
          type: WidgetType.chart,
          columnSpan: 6,
          position: 6,
          config: {'chart_id': 'user_trend'},
        ),
        const DashboardWidget(
          id: 'widget_alerts',
          title: '알림',
          type: WidgetType.alert,
          position: 9,
          config: {'limit': 5},
        ),
      ],
      createdAt: DateTime.now(),
      isPublic: true,
    );

    _dashboards[mainDashboard.id] = mainDashboard;

    // 초기 메트릭
    _metrics['main'] = [
      DashboardMetric(
        id: 'online_users',
        title: '실시간 유저',
        value: 15234,
        unit: '명',
        type: MetricType.count,
        trend: const Trend(value: 5.2, direction: TrendDirection.up),
      ),
      DashboardMetric(
        id: 'daily_revenue',
        title: '일일 매출',
        value: 5420000,
        unit: '원',
        type: MetricType.currency,
        trend: const Trend(value: 12.5, direction: TrendDirection.up),
      ),
      DashboardMetric(
        id: 'avg_session',
        title: '평균 세션 시간',
        value: 42.5,
        unit: '분',
        type: MetricType.duration,
        trend: const Trend(value: 3.1, direction: TrendDirection.down),
      ),
    ];

    // 초기 차트
    _charts['main'] = [
      ChartData(
        id: 'user_trend',
        title: '유저 추이',
        type: ChartType.line,
        dataPoints: const [
          DataPoint(label: '00:00', value: 12000),
          DataPoint(label: '04:00', value: 8000),
          DataPoint(label: '08:00', value: 15000),
          DataPoint(label: '12:00', value: 18000),
          DataPoint(label: '16:00', value: 16000),
          DataPoint(label: '20:00', value: 22000),
        ],
        xAxisLabel: '시간',
        yAxisLabel: '유저 수',
      ),
    ];

    // 초기 알림
    _alerts['main'] = [
      Alert(
        id: 'alert_1',
        title: '서버 부하 높음',
        message: '서버 3의 CPU 사용량이 85%를 초과했습니다.',
        severity: AlertSeverity.warning,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      Alert(
        id: 'alert_2',
        title: '결제 오류',
        message: '결제 게이트웨이에서 오류가 발생했습니다.',
        severity: AlertSeverity.error,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        actionUrl: '/payments/errors',
      ),
    ];

    // 초기 액티비티
    _activities['main'] = [
      Activity(
        id: 'act_1',
        title: '유저 가입',
        description: '새로운 유저 100명이 가입했습니다.',
        type: ActivityType.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Activity(
        id: 'act_2',
        title: '시스템 업데이트',
        description: '서버 패치 v1.2.3이 적용되었습니다.',
        type: ActivityType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void _startDataUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMetrics();
    });
  }

  /// 메트릭 업데이트
  void _updateMetrics() {
    for (final dashboardId in _dashboards.keys) {
      final metrics = _metrics[dashboardId] ?? [];

      for (final metric in metrics) {
        // 값 업데이트 (시뮬레이션)
        dynamic newValue = metric.value;
        if (metric.value is int) {
          newValue = (metric.value as int) + Random().nextInt(100) - 50;
        } else if (metric.value is double) {
          newValue = (metric.value as double) + (Random().nextDouble() * 10 - 5);
        }

        final updated = DashboardMetric(
          id: metric.id,
          title: metric.title,
          subtitle: metric.subtitle,
          value: newValue,
          unit: metric.unit,
          type: metric.type,
          icon: metric.icon,
          color: metric.color,
          trend: metric.trend,
          onClickAction: metric.onClickAction,
        );

        _metricController.add(updated);
      }
    }
  }

  /// 대시보드 생성
  Future<Dashboard> createDashboard({
    required String name,
    required String description,
    required List<DashboardWidget> widgets,
    bool isPublic = false,
  }) async {
    final dashboardId = 'dashboard_${DateTime.now().millisecondsSinceEpoch}';
    final dashboard = Dashboard(
      id: dashboardId,
      name: name,
      description: description,
      widgets: widgets,
      createdAt: DateTime.now(),
      isPublic: isPublic,
    );

    _dashboards[dashboardId] = dashboard;

    // 초기 데이터 생성
    _metrics[dashboardId] = [];
    _charts[dashboardId] = [];
    _alerts[dashboardId] = [];
    _activities[dashboardId] = [];

    await _saveDashboard(dashboard);

    debugPrint('[Dashboard] Created: $name');

    return dashboard;
  }

  /// 위젯 추가
  Future<void> addWidget({
    required String dashboardId,
    required DashboardWidget widget,
  }) async {
    final dashboard = _dashboards[dashboardId];
    if (dashboard == null) return;

    final updated = Dashboard(
      id: dashboard.id,
      name: dashboard.name,
      description: dashboard.description,
      widgets: [...dashboard.widgets, widget],
      createdAt: dashboard.createdAt,
      updatedAt: DateTime.now(),
      isPublic: dashboard.isPublic,
      ownerUserId: dashboard.ownerUserId,
    );

    _dashboards[dashboardId] = updated;

    await _saveDashboard(updated);

    debugPrint('[Dashboard] Widget added: ${widget.id}');
  }

  /// 위젯 제거
  Future<void> removeWidget({
    required String dashboardId,
    required String widgetId,
  }) async {
    final dashboard = _dashboards[dashboardId];
    if (dashboard == null) return;

    final updatedWidgets = dashboard.widgets.where((w) => w.id != widgetId).toList();

    final updated = Dashboard(
      id: dashboard.id,
      name: dashboard.name,
      description: dashboard.description,
      widgets: updatedWidgets,
      createdAt: dashboard.createdAt,
      updatedAt: DateTime.now(),
      isPublic: dashboard.isPublic,
      ownerUserId: dashboard.ownerUserId,
    );

    _dashboards[dashboardId] = updated;

    await _saveDashboard(updated);

    debugPrint('[Dashboard] Widget removed: $widgetId');
  }

  /// 메트릭 추가
  Future<void> addMetric({
    required String dashboardId,
    required DashboardMetric metric,
  }) async {
    _metrics.putIfAbsent(dashboardId, () => []).add(metric);
    _metricController.add(metric);
  }

  /// 차트 추가
  Future<void> addChart({
    required String dashboardId,
    required ChartData chart,
  }) async {
    _metrics.putIfAbsent(dashboardId, () => []);
    _charts.putIfAbsent(dashboardId, () => []).add(chart);
  }

  /// 알림 생성
  Future<void> createAlert({
    required String dashboardId,
    required String title,
    required String message,
    required AlertSeverity severity,
    String? actionUrl,
  }) async {
    final alert = Alert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      severity: severity,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
      isRead: false,
    );

    _alerts.putIfAbsent(dashboardId, () => []).add(alert);
    _alertController.add(alert);

    // 알림 전송 (실제 환경에서는 푸시 등)
    debugPrint('[Dashboard] Alert created: $title');
  }

  /// 알림 읽음 처리
  Future<void> markAlertRead({
    required String dashboardId,
    required String alertId,
  }) async {
    final alerts = _alerts[dashboardId];
    if (alerts == null) return;

    final index = alerts.indexWhere((a) => a.id == alertId);
    if (index == -1) return;

    final updated = Alert(
      id: alerts[index].id,
      title: alerts[index].title,
      message: alerts[index].message,
      severity: alerts[index].severity,
      createdAt: alerts[index].createdAt,
      expiresAt: alerts[index].expiresAt,
      actionUrl: alerts[index].actionUrl,
      isRead: true,
    );

    final updatedAlerts = List<Alert>.from(alerts);
    updatedAlerts[index] = updated;
    _alerts[dashboardId] = updatedAlerts;
  }

  /// 액티비티 추가
  Future<void> addActivity({
    required String dashboardId,
    required String title,
    required String description,
    required ActivityType type,
    String? icon,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = Activity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      icon: icon,
      type: type,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _activities.putIfAbsent(dashboardId, () => []).add(activity);
    _activityController.add(activity);

    // 최대 100개만 유지
    final activities = _activities[dashboardId]!;
    if (activities.length > 100) {
      activities.removeRange(0, activities.length - 100);
    }
  }

  /// 대시보드 조회
  Dashboard? getDashboard(String dashboardId) {
    return _dashboards[dashboardId];
  }

  /// 모든 대시보드
  List<Dashboard> getDashboards() {
    return _dashboards.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 메트릭 조회
  List<DashboardMetric> getMetrics(String dashboardId) {
    return _metrics[dashboardId] ?? [];
  }

  /// 차트 조회
  List<ChartData> getCharts(String dashboardId) {
    return _charts[dashboardId] ?? [];
  }

  /// 알림 조회
  List<Alert> getAlerts(String dashboardId, {bool? isRead}) {
    var alerts = _alerts[dashboardId] ?? [];

    if (isRead != null) {
      alerts = alerts.where((a) => a.isRead == isRead).toList();
    }

    return alerts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 액티비티 조회
  List<Activity> getActivities(String dashboardId, {int limit = 20}) {
    final activities = _activities[dashboardId] ?? [];

    return activities.take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 요약 데이터
  Map<String, dynamic> getSummary(String dashboardId) {
    final metrics = _metrics[dashboardId] ?? [];
    final alerts = _alerts[dashboardId] ?? [];

    return {
      'totalMetrics': metrics.length,
      'unreadAlerts': alerts.where((a) => !a.isRead).length,
      'criticalAlerts': alerts.where((a) => a.severity == AlertSeverity.critical).length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// 대시보드 통계
  Map<String, dynamic> getDashboardStatistics() {
    return {
      'totalDashboards': _dashboards.length,
      'totalWidgets': _dashboards.values.fold<int>(
          0, (sum, d) => sum + d.widgets.length),
      'totalAlerts': _alerts.values.fold<int>(
          0, (sum, a) => sum + a.length),
      'unreadAlerts': _alerts.values.fold<int>(
          0, (sum, a) => sum + a.where((alert) => !alert.isRead).length),
    };
  }

  Future<void> _saveDashboard(Dashboard dashboard) async {
    await _prefs?.setString(
      'dashboard_${dashboard.id}',
      jsonEncode({
        'id': dashboard.id,
        'name': dashboard.name,
        'description': dashboard.description,
        'widgets': dashboard.widgets.length,
      }),
    );
  }

  void dispose() {
    _metricController.close();
    _alertController.close();
    _activityController.close();
    _updateTimer?.cancel();
  }
}

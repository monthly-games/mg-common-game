import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 에러 심각도
enum ErrorSeverity {
  debug,          // 디버그
  info,           // 정보
  warning,        // 경고
  error,          // 에러
  critical,       // 치명적
  fatal,          // 치명적 (앱 크래시)
}

/// 에러 타입
enum ErrorType {
  runtime,        // 런타임 에러
  network,        // 네트워크 에러
  ui,             // UI 에러
  logic,          // 로직 에러
  performance,    // 성능 에러
  security,       // 보안 에러
  crash,          // 크래시
  anr,            // ANR (Application Not Responding)
}

/// 에러 상태
enum ErrorStatus {
  open,           // 열림
  investigating,  // 조사 중
  resolved,       // 해결됨
  closed,         // 닫힘
}

/// 에러 이슈
class ErrorIssue {
  final String issueId;
  final String title;
  final String description;
  final ErrorType type;
  final ErrorSeverity severity;
  final ErrorStatus status;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int occurrenceCount;
  final int affectedUsers;
  final List<String> affectedUserIds;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;

  const ErrorIssue({
    required this.issueId,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    this.stackTrace,
    this.context,
    required this.firstSeen,
    required this.lastSeen,
    required this.occurrenceCount,
    required this.affectedUsers,
    required this.affectedUserIds,
    this.assignedTo,
    this.metadata,
  });

  /// 영향도 점수
  double get impactScore {
    final severityWeight = {
      ErrorSeverity.debug: 1,
      ErrorSeverity.info: 2,
      ErrorSeverity.warning: 5,
      ErrorSeverity.error: 10,
      ErrorSeverity.critical: 20,
      ErrorSeverity.fatal: 50,
    };

    final severityScore = severityWeight[severity] ?? 1;
    final frequencyScore = occurrenceCount.toDouble();
    final userScore = affectedUsers.toDouble();

    return severityScore * (frequencyScore * 0.3 + userScore * 0.7);
  }
}

/// 에러 이벤트
class ErrorEvent {
  final String eventId;
  final String issueId;
  final String? userId;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? breadcrumbs;
  final DeviceInfo? deviceInfo;
  final AppInfo? appInfo;
  final DateTime timestamp;
  final Map<String, dynamic>? customData;

  const ErrorEvent({
    required this.eventId,
    required this.issueId,
    this.userId,
    required this.type,
    required this.severity,
    this.errorMessage,
    this.stackTrace,
    this.context,
    this.breadcrumbs,
    this.deviceInfo,
    this.appInfo,
    required this.timestamp,
    this.customData,
  });
}

/// 기기 정보
class DeviceInfo {
  final String model;
  final String manufacturer;
  final String os;
  final String osVersion;
  final String? platform;
  final int? cpuCores;
  final int? ramMB;
  final double? screenDensity;
  final String? locale;
  final String? carrier;
  final String? networkType;

  const DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.os,
    required this.osVersion,
    this.platform,
    this.cpuCores,
    this.ramMB,
    this.screenDensity,
    this.locale,
    this.carrier,
    this.networkType,
  });
}

/// 앱 정보
class AppInfo {
  final String appName;
  final String appVersion;
  final String buildNumber;
  final String package;
  final DateTime? buildDate;
  final String? environment;
  final String? flavor;

  const AppInfo({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.package,
    this.buildDate,
    this.environment,
    this.flavor,
  });
}

/// 크래시 리포트
class CrashReport {
  final String reportId;
  final ErrorEvent errorEvent;
  final List<String>? attachments;
  final String? reproductionSteps;
  final String? workaround;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const CrashReport({
    required this.reportId,
    required this.errorEvent,
    this.attachments,
    this.reproductionSteps,
    this.workaround,
    this.resolvedAt,
    this.resolvedBy,
  });
}

/// 성능 메트릭
class PerformanceMetric {
  final String metricId;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  const PerformanceMetric({
    required this.metricId,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.context,
  });
}

/// 브레드크럼브 (사용자 경로)
class Breadcrumb {
  final String category;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final BreadcrumbLevel level;

  const Breadcrumb({
    required this.category,
    required this.message,
    required this.timestamp,
    this.data,
    required this.level,
  });
}

enum BreadcrumbLevel {
  debug,
  info,
  warning,
  error,
}

/// 에러 통계
class ErrorStatistics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalErrors;
  final int totalCrashes;
  final Map<ErrorType, int> errorsByType;
  final Map<ErrorSeverity, int> errorsBySeverity;
  final double errorRate;
  final double crashRate;
  final List<ErrorIssue> topIssues;
  final Map<String, int> affectedVersions;

  const ErrorStatistics({
    required this.periodStart,
    required this.periodEnd,
    required this.totalErrors,
    required this.totalCrashes,
    required this.errorsByType,
    required this.errorsBySeverity,
    required this.errorRate,
    required this.crashRate,
    required this.topIssues,
    required this.affectedVersions,
  });
}

/// 에러 리포팅 관리자
class ErrorReportingManager {
  static final ErrorReportingManager _instance =
      ErrorReportingManager._();
  static ErrorReportingManager get instance => _instance;

  ErrorReportingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, ErrorIssue> _issues = {};
  final List<ErrorEvent> _events = [];
  final List<Breadcrumb> _breadcrumbs = [];
  final List<CrashReport> _crashReports = [];
  final List<PerformanceMetric> _performanceMetrics = [];

  final StreamController<ErrorEvent> _errorController =
      StreamController<ErrorEvent>.broadcast();
  final StreamController<CrashReport> _crashController =
      StreamController<CrashReport>.broadcast();
  final StreamController<ErrorStatistics> _statsController =
      StreamController<ErrorStatistics>.broadcast();

  Stream<ErrorEvent> get onError => _errorController.stream;
  Stream<CrashReport> get onCrash => _crashController.stream;
  Stream<ErrorStatistics> get onStatsUpdate => _statsController.stream;

  Timer? _reportTimer;
  Timer? _cleanupTimer;
  DeviceInfo? _deviceInfo;
  AppInfo? _appInfo;

  static const int _maxBreadcrumbs = 100;
  static const int _maxEvents = 1000;
  static const int _eventReportingInterval = 300; // 5 minutes

  /// 초기화
  Future<void> initialize({
    DeviceInfo? deviceInfo,
    AppInfo? appInfo,
  }) async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    _deviceInfo = deviceInfo;
    _appInfo = appInfo;

    // 에러 로드
    await _loadErrors();

    // 크래시 리포트 로드
    await _loadCrashReports();

    // 글로벌 에러 핸들러 설정
    _setupErrorHandlers();

    // 주기 리포팅 시작
    _startPeriodicReporting();

    // 청소 타이머 시작
    _startCleanupTimer();

    debugPrint('[ErrorReporting] Initialized');
  }

  Future<void> _loadErrors() async {
    final json = _prefs?.getString('error_events');

    if (json != null) {
      try {
        final data = jsonDecode(json) as List;
        // 파싱
      } catch (e) {
        debugPrint('[ErrorReporting] Error loading: $e');
      }
    }
  }

  Future<void> _loadCrashReports() async {
    // 이전 크래시 리포트 확인
    final hadCrash = _prefs?.getBool('had_crash') ?? false;

    if (hadCrash) {
      final crashData = _prefs?.getString('last_crash');
      if (crashData != null) {
        // 크래시 리포트 생성
        await _createCrashReportFromData(crashData);
      }

      await _prefs?.setBool('had_crash', false);
    }
  }

  void _setupErrorHandlers() {
    // Flutter 에러 핸들러 설정
    FlutterError.onError = (details) {
      captureException(
        exception: details.exception,
        stackTrace: details.stack,
        context: {
          'fatal': true,
        },
      );
    };
  }

  void _startPeriodicReporting() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      const Duration(seconds: _eventReportingInterval),
      (_) => _sendPendingReports(),
    );
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldData();
    });
  }

  /// 예외 캡처
  Future<void> captureException({
    required dynamic exception,
    StackTrace? stackTrace,
    ErrorType type = ErrorType.runtime,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
    Map<String, dynamic>? customData,
  }) async {
    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
    final errorMessage = exception.toString();

    // 이슈 ID 생성 (에러 메시지 해싱)
    final issueId = _generateIssueId(errorMessage, type);

    // 기존 이슈 확인 및 업데이트
    var issue = _issues[issueId];
    if (issue != null) {
      issue = ErrorIssue(
        issueId: issue.issueId,
        title: issue.title,
        description: issue.description,
        type: issue.type,
        severity: issue.severity,
        status: issue.status,
        stackTrace: issue.stackTrace,
        context: issue.context,
        firstSeen: issue.firstSeen,
        lastSeen: DateTime.now(),
        occurrenceCount: issue.occurrenceCount + 1,
        affectedUsers: issue.affectedUsers +
            (_currentUserId != null && !issue.affectedUserIds.contains(_currentUserId!)
                ? 1
                : 0),
        affectedUserIds: _currentUserId != null && !issue.affectedUserIds.contains(_currentUserId!)
            ? [...issue.affectedUserIds, _currentUserId!]
            : issue.affectedUserIds,
        assignedTo: issue.assignedTo,
        metadata: issue.metadata,
      );
      _issues[issueId] = issue;
    } else {
      // 새 이슈 생성
      issue = ErrorIssue(
        issueId: issueId,
        title: _generateTitle(errorMessage),
        description: errorMessage,
        type: type,
        severity: severity,
        status: ErrorStatus.open,
        stackTrace: stackTrace?.toString(),
        context: context,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
        occurrenceCount: 1,
        affectedUsers: 1,
        affectedUserIds: _currentUserId != null ? [_currentUserId!] : [],
      );
      _issues[issueId] = issue;
    }

    // 이벤트 생성
    final event = ErrorEvent(
      eventId: eventId,
      issueId: issueId,
      userId: _currentUserId,
      type: type,
      severity: severity,
      errorMessage: errorMessage,
      stackTrace: stackTrace?.toString(),
      context: context,
      breadcrumbs: _getBreadcrumbsMap(),
      deviceInfo: _deviceInfo,
      appInfo: _appInfo,
      timestamp: DateTime.now(),
      customData: customData,
    );

    _events.add(event);

    // 메모리 관리
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }

    _errorController.add(event);

    // 치명적 에러인 경우 즉시 전송
    if (severity == ErrorSeverity.fatal ||
        severity == ErrorSeverity.critical) {
      await _sendErrorReport(event);
    }

    await _saveErrors();

    debugPrint('[ErrorReporting] Exception captured: $issueId');
  }

  /// 메시지 캡처
  Future<void> captureMessage({
    required String message,
    ErrorSeverity severity = ErrorSeverity.info,
    Map<String, dynamic>? context,
  }) async {
    addBreadcrumb(
      category: 'message',
      message: message,
      level: _mapSeverityToLevel(severity),
      data: context,
    );
  }

  /// 브레드크럼브 추가
  void addBreadcrumb({
    required String category,
    required String message,
    required BreadcrumbLevel level,
    Map<String, dynamic>? data,
  }) {
    final breadcrumb = Breadcrumb(
      category: category,
      message: message,
      timestamp: DateTime.now(),
      data: data,
      level: level,
    );

    _breadcrumbs.add(breadcrumb);

    // 최대 개수 유지
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// 크래시 리포트 생성
  Future<void> _createCrashReportFromData(String crashData) async {
    try {
      final data = jsonDecode(crashData) as Map<String, dynamic>;

      final event = ErrorEvent(
        eventId: 'crash_${DateTime.now().millisecondsSinceEpoch}',
        issueId: _generateIssueId(data['error'] ?? 'Unknown', ErrorType.crash),
        userId: _currentUserId,
        type: ErrorType.crash,
        severity: ErrorSeverity.fatal,
        errorMessage: data['error']?.toString(),
        stackTrace: data['stackTrace']?.toString(),
        timestamp: DateTime.now(),
      );

      final report = CrashReport(
        reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
        errorEvent: event,
      );

      _crashReports.add(report);
      _crashController.add(report);

      debugPrint('[ErrorReporting] Crash report created');
    } catch (e) {
      debugPrint('[ErrorReporting] Error creating crash report: $e');
    }
  }

  /// 성능 메트릭 기록
  void recordPerformanceMetric({
    required String name,
    required double value,
    required String unit,
    Map<String, dynamic>? context,
  }) {
    final metric = PerformanceMetric(
      metricId: 'metric_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      context: context,
    );

    _performanceMetrics.add(metric);

    // 성능 경고
    if (_isPoorPerformance(name, value)) {
      captureException(
        exception: 'Poor performance: $name = $value$unit',
        type: ErrorType.performance,
        severity: ErrorSeverity.warning,
        context: context,
      );
    }
  }

  bool _isPoorPerformance(String name, double value) {
    final thresholds = {
      'frame_time': 16.67, // 60fps
      'memory_usage': 500, // MB
      'cpu_usage': 80, // %
      'load_time': 3, // seconds
    };

    final threshold = thresholds[name];
    return threshold != null && value > threshold;
  }

  /// 이슈 ID 생성
  String _generateIssueId(String errorMessage, ErrorType type) {
    // 에러 메시지와 타입으로 해싱
    final hash = errorMessage.hashCode ^ type.hashCode;
    return 'issue_${hash.abs()}';
  }

  /// 제목 생성
  String _generateTitle(String errorMessage) {
    // 에러 메시지의 첫 줄 또는 짧은 요약
    final lines = errorMessage.split('\n');
    final title = lines.first.trim();
    return title.length > 100 ? '${title.substring(0, 100)}...' : title;
  }

  /// 브레드크럼브 맵 변환
  Map<String, dynamic>? _getBreadcrumbsMap() {
    if (_breadcrumbs.isEmpty) return null;

    return {
      'breadcrumbs': _breadcrumbs.map((b) => {
        'category': b.category,
        'message': b.message,
        'timestamp': b.timestamp.toIso8601String(),
        'level': b.level.name,
        'data': b.data,
      }).toList(),
    };
  }

  /// 심각도 레벨 매핑
  BreadcrumbLevel _mapSeverityToLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.debug:
        return BreadcrumbLevel.debug;
      case ErrorSeverity.info:
        return BreadcrumbLevel.info;
      case ErrorSeverity.warning:
        return BreadcrumbLevel.warning;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
      case ErrorSeverity.fatal:
        return BreadcrumbLevel.error;
    }
  }

  /// 에러 리포트 전송
  Future<void> _sendErrorReport(ErrorEvent event) async {
    // 실제로는 서버에 전송
    debugPrint('[ErrorReporting] Sending error report: ${event.eventId}');

    // 여기서 서버 API 호출
    // await http.post(...)
  }

  /// 대기 중인 리포트 전송
  Future<void> _sendPendingReports() async {
    if (_events.isEmpty) return;

    debugPrint('[ErrorReporting] Sending ${_events.length} pending reports');

    // 일괄 전송
    for (final event in _events) {
      await _sendErrorReport(event);
    }

    // 전송 후 클리어
    _events.clear();
  }

  /// 통계 생성
  ErrorStatistics generateStatistics({
    DateTime? start,
    DateTime? end,
  }) {
    final now = DateTime.now();
    final periodStart = start ?? now.subtract(const Duration(days: 7));
    final periodEnd = end ?? now;

    // 기간 내 이벤트 필터링
    final periodEvents = _events.where((e) =>
        e.timestamp.isAfter(periodStart) &&
        e.timestamp.isBefore(periodEnd)).toList();

    final crashes = periodEvents.where((e) => e.type == ErrorType.crash).toList();

    // 타입별 집계
    final errorsByType = <ErrorType, int>{};
    for (final type in ErrorType.values) {
      errorsByType[type] = periodEvents.where((e) => e.type == type).length;
    }

    // 심각도별 집계
    final errorsBySeverity = <ErrorSeverity, int>{};
    for (final severity in ErrorSeverity.values) {
      errorsBySeverity[severity] = periodEvents.where((e) => e.severity == severity).length;
    }

    // 상위 이슈
    final topIssues = _issues.values.toList()
      ..sort((a, b) => b.impactScore.compareTo(a.impactScore));

    // 영향받은 버전
    final affectedVersions = <String, int>{};
    for (final event in periodEvents) {
      final version = event.appInfo?.appVersion ?? 'unknown';
      affectedVersions[version] = (affectedVersions[version] ?? 0) + 1;
    }

    return ErrorStatistics(
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalErrors: periodEvents.length,
      totalCrashes: crashes.length,
      errorsByType: errorsByType,
      errorsBySeverity: errorsBySeverity,
      errorRate: periodEvents.length.toDouble(),
      crashRate: crashes.length.toDouble(),
      topIssues: topIssues.take(10).toList(),
      affectedVersions: affectedVersions,
    );
  }

  /// 이슈 해결
  Future<bool> resolveIssue({
    required String issueId,
    required String resolvedBy,
  }) async {
    final issue = _issues[issueId];
    if (issue == null) return false;

    _issues[issueId] = ErrorIssue(
      issueId: issue.issueId,
      title: issue.title,
      description: issue.description,
      type: issue.type,
      severity: issue.severity,
      status: ErrorStatus.resolved,
      stackTrace: issue.stackTrace,
      context: issue.context,
      firstSeen: issue.firstSeen,
      lastSeen: issue.lastSeen,
      occurrenceCount: issue.occurrenceCount,
      affectedUsers: issue.affectedUsers,
      affectedUserIds: issue.affectedUserIds,
      assignedTo: resolvedBy,
      metadata: issue.metadata,
    );

    await _saveErrors();

    return true;
  }

  /// 오래된 데이터 정리
  void _cleanupOldData() {
    final now = DateTime.now();
    const retentionPeriod = Duration(days: 30);

    // 이벤트 정리
    _events.removeWhere((e) =>
        now.difference(e.timestamp) > retentionPeriod);

    // 브레드크럼브 정리
    _breadcrumbs.removeWhere((b) =>
        now.difference(b.timestamp) > const Duration(hours: 24));

    debugPrint('[ErrorReporting] Cleanup completed');
  }

  /// 이슈 목록 조회
  List<ErrorIssue> getIssues({ErrorStatus? status}) {
    final issues = _issues.values.toList();

    if (status != null) {
      return issues.where((i) => i.status == status).toList();
    }

    return issues;
  }

  /// 최근 이벤트 조회
  List<ErrorEvent> getRecentEvents({int limit = 100}) {
    return _events.take(limit).toList();
  }

  Future<void> _saveErrors() async {
    final data = _events.map((e) => {
      'eventId': e.eventId,
      'issueId': e.issueId,
      'errorMessage': e.errorMessage,
      'timestamp': e.timestamp.toIso8601String(),
    }).toList();

    await _prefs?.setString('error_events', jsonEncode(data));
  }

  void dispose() {
    _errorController.close();
    _crashController.close();
    _statsController.close();
    _reportTimer?.cancel();
    _cleanupTimer?.cancel();
  }
}

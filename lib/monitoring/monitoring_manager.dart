import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그 레벨
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 로그 엔트리
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final String? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.context,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
        'stackTrace': stackTrace,
      };
}

/// 성능 메트릭
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final Map<String, dynamic>? tags;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    this.tags,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'unit': unit,
        'tags': tags,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 에러 리포트
class ErrorReport {
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  ErrorReport({
    required this.message,
    this.stackTrace,
    this.context,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'stackTrace': stackTrace,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'sessionId': sessionId,
      };
}

/// 사용자 이벤트
class UserEvent {
  final String name;
  final Map<String, dynamic>? properties;
  final DateTime timestamp;
  final String? userId;

  UserEvent({
    required this.name,
    this.properties,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
      };
}

/// 모니터링 매니저
class MonitoringManager {
  static final MonitoringManager _instance = MonitoringManager._();
  static MonitoringManager get instance => _instance;

  MonitoringManager._() {
    _initialize();
  }

  final List<LogEntry> _logs = [];
  final List<PerformanceMetric> _metrics = [];
  final List<ErrorReport> _errors = [];
  final List<UserEvent> _events = [];

  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<ErrorReport> _errorController =
      StreamController<ErrorReport>.broadcast();
  final StreamController<PerformanceMetric> _metricController =
      StreamController<PerformanceMetric>.broadcast();

  SharedPreferences? _prefs;
  String? _sessionId;
  String? _userId;

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<ErrorReport> get onError => _errorController.stream;
  Stream<PerformanceMetric> get onMetric => _metricController.stream;

  void _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionId = _generateSessionId();
    _userId = _prefs?.getString('user_id');
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 로그 기록
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Map<String, dynamic>? context,
  }) {
    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      context: context,
    );

    _logs.add(entry);
    _logController.add(entry);

    // 콘솔 출력
    _printLog(entry);

    // 로그 크기 제한
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }

  void _printLog(LogEntry entry) {
    final levelStr = '[${entry.level.name.toUpperCase()}]';
    final tagStr = entry.tag != null ? '[${entry.tag}]' : '';
    final timeStr = '${entry.timestamp.hour}:${entry.timestamp.minute}:${entry.timestamp.second}';

    debugPrint('$timeStr $levelStr$tagStr ${entry.message}');

    if (entry.stackTrace != null) {
      debugPrint(entry.stackTrace!);
    }
  }

  /// 각 레벨별 로그 메서드
  void verbose(String message, {String? tag, Map<String, dynamic>? context}) {
    log(message, level: LogLevel.verbose, tag: tag, context: context);
  }

  void debug(String message, {String? tag, Map<String, dynamic>? context}) {
    log(message, level: LogLevel.debug, tag: tag, context: context);
  }

  void info(String message, {String? tag, Map<String, dynamic>? context}) {
    log(message, level: LogLevel.info, tag: tag, context: context);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? context}) {
    log(message, level: LogLevel.warning, tag: tag, context: context);
  }

  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    String? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.error,
      tag: tag,
      context: context,
      stackTrace: stackTrace,
    );

    // 에러 리포트 생성
    reportError(
      message,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? context,
    String? stackTrace,
  }) {
    log(
      message,
      level: LogLevel.fatal,
      tag: tag,
      context: context,
      stackTrace: stackTrace,
    );

    reportError(
      message,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// 에러 리포트
  void reportError(
    String message, {
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final report = ErrorReport(
      message: message,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
      userId: _userId,
      sessionId: _sessionId,
    );

    _errors.add(report);
    _errorController.add(report);

    // Sentry 등 외부 서비스로 전송
    _sendErrorToSentry(report);
  }

  /// 성능 메트릭 기록
  void recordMetric(
    String name,
    double value, {
    String unit = 'ms',
    Map<String, dynamic>? tags,
  }) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      unit: unit,
      tags: tags,
      timestamp: DateTime.now(),
    );

    _metrics.add(metric);
    _metricController.add(metric);

    // 메트릭 크기 제한
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// 사용자 이벤트 추적
  void trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) {
    final event = UserEvent(
      name: name,
      properties: properties,
      timestamp: DateTime.now(),
      userId: _userId,
    );

    _events.add(event);

    // AnalyticsManager로 전송
    // AnalyticsManager.instance.logEvent(name, properties);
  }

  /// 성능 측정 (Stopwatch)
  Stopwatch? startMeasure(String name) {
    info('Measure started: $name', tag: 'performance');
    return Stopwatch()..start();
  }

  void stopMeasure(String name, Stopwatch? stopwatch, {Map<String, dynamic>? tags}) {
    if (stopwatch == null) return;

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds.toDouble();

    recordMetric(name, duration, unit: 'ms', tags: tags);
    info('Measure completed: $name (${duration}ms)', tag: 'performance');
  }

  /// 메서드 실행 시간 측정
  Future<T> measure<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, dynamic>? tags,
  }) async {
    final stopwatch = startMeasure(name);

    try {
      final result = await operation();
      stopMeasure(name, stopwatch, tags: tags);
      return result;
    } catch (e, stackTrace) {
      stopMeasure(name, stopwatch, tags: {...?tags, 'error': true});
      error('Error in $name: $e', stackTrace: stackTrace.toString());
      rethrow;
    }
  }

  /// 로그 조회
  List<LogEntry> getLogs({LogLevel? minLevel, DateTime? since}) {
    var logs = _logs.toList();

    if (minLevel != null) {
      logs = logs.where((l) => l.level.index >= minLevel.index).toList();
    }

    if (since != null) {
      logs = logs.where((l) => l.timestamp.isAfter(since)).toList();
    }

    return logs;
  }

  /// 메트릭 조회
  List<PerformanceMetric> getMetrics({String? name, DateTime? since}) {
    var metrics = _metrics.toList();

    if (name != null) {
      metrics = metrics.where((m) => m.name == name).toList();
    }

    if (since != null) {
      metrics = metrics.where((m) => m.timestamp.isAfter(since)).toList();
    }

    return metrics;
  }

  /// 에러 리포트 조회
  List<ErrorReport> getErrors({DateTime? since}) {
    var errors = _errors.toList();

    if (since != null) {
      errors = errors.where((e) => e.timestamp.isAfter(since)).toList();
    }

    return errors;
  }

  /// 세션 ID 설정
  void setSessionId(String sessionId) {
    _sessionId = sessionId;
    info('Session ID updated: $_sessionId');
  }

  /// 사용자 ID 설정
  void setUserId(String userId) {
    _userId = userId;
    _prefs?.setString('user_id', userId);
    info('User ID updated: $_userId');
  }

  /// 외부 서비스로 전송 (Sentry)
  void _sendErrorToSentry(ErrorReport report) {
    // 실제 구현에서는 Sentry SDK 사용
    // Sentry.captureException(
    //   exception: Exception(report.message),
    //   stackTrace: report.stackTrace,
    //   hint: report.context,
    // );
  }

  /// 로그 내보내기
  String exportLogs({LogLevel? minLevel}) {
    final logs = getLogs(minLevel: minLevel);
    return jsonEncode(logs.map((l) => l.toJson()).toList());
  }

  /// 메트릭 내보내기
  String exportMetrics({String? name}) {
    final metrics = getMetrics(name: name);
    return jsonEncode(metrics.map((m) => m.toJson()).toList());
  }

  /// 메모리 정리
  void clear() {
    _logs.clear();
    _metrics.clear();
    // 에러는 유지 (분석용)
    info('Monitoring data cleared');
  }

  void dispose() {
    _logController.close();
    _errorController.close();
    _metricController.close();
  }
}

/// API 호출 모니터링
class APIMonitor {
  final MonitoringManager _monitoring = MonitoringManager.instance;

  /// API 호출 추적
  Future<T> trackAPICall<T>(
    String endpoint,
    Future<T> Function() call, {
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? error;

    try {
      _monitoring.info('API Call: $endpoint', tag: 'api');

      final result = await call();

      stopwatch.stop();
      _monitoring.recordMetric(
        'api_call_duration',
        stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
        tags: {
          'endpoint': endpoint,
          'success': true,
          ...?metadata,
        },
      );

      _monitoring.trackEvent('api_call_success', properties: {
        'endpoint': endpoint,
        'duration': stopwatch.elapsedMilliseconds,
        ...?metadata,
      });

      return result;
    } catch (e) {
      stopwatch.stop();
      error = e.toString();

      _monitoring.error('API Error: $endpoint - $e', tag: 'api');

      _monitoring.recordMetric(
        'api_call_duration',
        stopwatch.elapsedMilliseconds.toDouble(),
        unit: 'ms',
        tags: {
          'endpoint': endpoint,
          'success': false,
          'error': error,
          ...?metadata,
        },
      );

      _monitoring.trackEvent('api_call_error', properties: {
        'endpoint': endpoint,
        'error': error,
        'duration': stopwatch.elapsedMilliseconds,
        ...?metadata,
      });

      rethrow;
    }
  }
}

/// 화면 렌더링 모니터맅
class RenderMonitor {
  final MonitoringManager _monitoring = MonitoringManager.instance;

  /// 위젯 렌더링 시간 측정
  void trackRenderPerformance(String screenName) {
    // 실제 구현에서는 Flutter DevTools 연동
    _monitoring.recordMetric(
      'screen_render',
      16.67, // 60 FPS = 16.67ms
      unit: 'ms',
      tags: {'screen': screenName},
    );
  }
}

/// 네트워크 상태 모니터맱
class NetworkMonitor {
  final MonitoringManager _monitoring = MonitoringManager.instance;

  void updateConnectionStatus(bool isConnected, String connectionType) {
    _monitoring.trackEvent('network_status_change', properties: {
      'isConnected': isConnected,
      'connectionType': connectionType,
    });

    if (!isConnected) {
      _monitoring.warning('Network disconnected', tag: 'network');
    } else {
      _monitoring.info('Network connected: $connectionType', tag: 'network');
    }
  }
}

/// 메모리 모니터링
class MemoryMonitor {
  final MonitoringManager _monitoring = MonitoringManager.instance;

  void checkMemoryUsage() {
    // 실제 구현에서는 dart:developer 사용
    final usage = 100 * 1024 * 1024; // 100MB 예시

    _monitoring.recordMetric(
      'memory_usage',
      usage.toDouble(),
      unit: 'bytes',
    );

    if (usage > 200 * 1024 * 1024) {
      _monitoring.warning('High memory usage: ${(usage / 1024 / 1024).toStringAsFixed(0)}MB');
    }
  }
}

/// 배터리 모니터맱 (플랫폼 채널 필요)
class BatteryMonitor {
  final MonitoringManager _monitoring = MonitoringManager.instance;

  void updateBatteryLevel(int level) {
    _monitoring.trackEvent('battery_level', properties: {
      'level': level,
    });

    if (level < 20) {
      _monitoring.warning('Low battery: $level%', tag: 'battery');
    }
  }
}

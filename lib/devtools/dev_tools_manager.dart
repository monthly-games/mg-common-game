import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그 레벨
enum LogLevel {
  verbose,        // 상세
  debug,          // 디버그
  info,           // 정보
  warning,        // 경고
  error,          // 에러
  fatal,          // 치명적
}

/// 로그 항목
class LogEntry {
  final String logId;
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final dynamic error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.logId,
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.context,
    this.error,
    this.stackTrace,
  });
}

/// 네트워크 요청
class NetworkRequest {
  final String requestId;
  final String method;
  final String url;
  final Map<String, String>? headers;
  final dynamic body;
  final DateTime timestamp;

  const NetworkRequest({
    required this.requestId,
    required this.method,
    required this.url,
    this.headers,
    this.body,
    required this.timestamp,
  });
}

/// 네트워크 응답
class NetworkResponse {
  final String requestId;
  final int statusCode;
  final Map<String, String>? headers;
  final dynamic body;
  final Duration duration;
  final DateTime timestamp;

  const NetworkResponse({
    required this.requestId,
    required this.statusCode,
    this.headers,
    this.body,
    required this.duration,
    required this.timestamp,
  });
}

/// 위젯 트리 정보
class WidgetTreeNode {
  final String nodeId;
  final String widgetType;
  final String? key;
  final Map<String, dynamic>? properties;
  final List<WidgetTreeNode> children;
  final Size? size;
  final Offset? position;

  const WidgetTreeNode({
    required this.nodeId,
    required this.widgetType,
    this.key,
    this.properties,
    required this.children,
    this.size,
    this.position,
  });
}

/// 성능 메트릭
class PerformanceMetric {
  final String metricId;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.metricId,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
}

/// 메모리 사용량
class MemoryUsage {
  final int heapUsed;
  final int heapCapacity;
  final int externalUsed;
  final DateTime timestamp;

  const MemoryUsage({
    required this.heapUsed,
    required this.heapCapacity,
    required this.externalUsed,
    required this.timestamp,
  });

  double get heapUsage => heapCapacity > 0 ? heapUsed / heapCapacity : 0;
}

/// 개발자 도구 관리자
class DevToolsManager {
  static final DevToolsManager _instance = DevToolsManager._();
  static DevToolsManager get instance => _instance;

  DevToolsManager._();

  SharedPreferences? _prefs;

  // 로깅
  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  // 네트워크
  final List<NetworkRequest> _requests = [];
  final List<NetworkResponse> _responses = [];
  final StreamController<NetworkRequest> _requestController =
      StreamController<NetworkRequest>.broadcast();
  final StreamController<NetworkResponse> _responseController =
      StreamController<NetworkResponse>.broadcast();

  // 위젯 트리
  WidgetTreeNode? _widgetTree;
  final StreamController<WidgetTreeNode> _widgetTreeController =
      StreamController<WidgetTreeNode>.broadcast();

  // 성능
  final List<PerformanceMetric> _metrics = [];
  final StreamController<PerformanceMetric> _metricController =
      StreamController<PerformanceMetric>.broadcast();

  // 메모리
  final List<MemoryUsage> _memorySnapshots = [];
  final StreamController<MemoryUsage> _memoryController =
      StreamController<MemoryUsage>.broadcast();

  Stream<LogEntry> get onLog => _logController.stream;
  Stream<NetworkRequest> get onRequest => _requestController.stream;
  Stream<NetworkResponse> get onResponse => _responseController.stream;
  Stream<WidgetTreeNode> get onWidgetTreeUpdate => _widgetTreeController.stream;
  Stream<PerformanceMetric> get onMetricUpdate => _metricController.stream;
  Stream<MemoryUsage> get onMemoryUpdate => _memoryController.stream;

  bool _isEnabled = false;
  Timer? _metricTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 설정 로드
    _isEnabled = _prefs.getBool('devtools_enabled') ?? false;

    if (_isEnabled) {
      _startMonitoring();
    }

    debugPrint('[DevTools] Initialized (enabled: $_isEnabled)');
  }

  /// 활성화/비활성화
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;

    await _prefs?.setBool('devtools_enabled', enabled);

    if (enabled) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }

    debugPrint('[DevTools] ${enabled ? "Enabled" : "Disabled"}');
  }

  /// 활성화 여부
  bool get isEnabled => _isEnabled;

  void _startMonitoring() {
    // 성능 모니터링 시작
    _metricTimer?.cancel();
    _metricTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _collectPerformanceMetrics();
    });
  }

  void _stopMonitoring() {
    _metricTimer?.cancel();
  }

  /// 로그 출력
  void log({
    required LogLevel level,
    required String message,
    String? tag,
    Map<String, dynamic>? context,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled && level != LogLevel.error && level != LogLevel.fatal) {
      return;
    }

    final entry = LogEntry(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    _logController.add(entry);

    // 콘솔 출력
    _printToConsole(entry);

    // Flutter DevTools 로그
    developer.log(
      message,
      time: entry.timestamp,
      level: _getLogLevelValue(level),
      name: tag ?? 'App',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _printToConsole(LogEntry entry) {
    final prefix = '[${entry.level.name.toUpperCase()}]${entry.tag != null ? ' [${entry.tag}]' : ''}';
    debugPrint('$prefix ${entry.message}');

    if (entry.error != null) {
      debugPrint('Error: ${entry.error}');
    }
    if (entry.stackTrace != null) {
      debugPrint('StackTrace: ${entry.stackTrace}');
    }
  }

  int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 500;
      case LogLevel.debug:
        return 800;
      case LogLevel.info:
        return 900;
      case LogLevel.warning:
        return 1000;
      case LogLevel.error:
        return 1200;
      case LogLevel.fatal:
        return 2000;
    }
  }

  /// 네트워크 요청 로깅
  void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_isEnabled) return;

    final request = NetworkRequest(
      requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
      method: method,
      url: url,
      headers: headers,
      body: body,
      timestamp: DateTime.now(),
    );

    _requests.add(request);
    _requestController.add(request);

    log(
      level: LogLevel.debug,
      message: '$method $url',
      tag: 'Network',
      context: {'headers': headers, 'body': body},
    );
  }

  /// 네트워크 응답 로깅
  void logResponse({
    required String requestId,
    required int statusCode,
    Map<String, String>? headers,
    dynamic body,
    required Duration duration,
  }) {
    if (!_isEnabled) return;

    final response = NetworkResponse(
      requestId: requestId,
      statusCode: statusCode,
      headers: headers,
      body: body,
      duration: duration,
      timestamp: DateTime.now(),
    );

    _responses.add(response);
    _responseController.add(response);

    final level = statusCode >= 400 ? LogLevel.error : LogLevel.debug;
    log(
      level: level,
      message: '$requestId - $statusCode (${duration.inMilliseconds}ms)',
      tag: 'Network',
    );
  }

  /// 위젯 트리 갱신
  void updateWidgetTree(BuildContext context) {
    if (!_isEnabled) return;

    final tree = _buildWidgetTree(context);
    _widgetTree = tree;
    _widgetTreeController.add(tree);
  }

  WidgetTreeNode _buildWidgetTree(BuildContext context) {
    return WidgetTreeNode(
      nodeId: 'root',
      widgetType: context.widget.runtimeType.toString(),
      key: context.widget.key?.toString(),
      properties: {
        'depth': context.depth,
      },
      children: [],
      size: context.size,
      position: (context.findRenderObject() as RenderBox?)
          ?.localToGlobal(Offset.zero),
    );
  }

  /// 성능 메트릭 수집
  void _collectPerformanceMetrics() {
    // 프레임 시간
    final frameMetrics = _collectFrameMetrics();

    // 메모리
    final memory = _collectMemory();

    // CPU 사용량 (플랫폼별)
    final cpuUsage = _collectCPUUsage();

    _metricController.add(frameMetrics);
    _metricController.add(cpuUsage);
    _memoryController.add(memory);
  }

  PerformanceMetric _collectFrameMetrics() {
    // 실제로는 SchedulerBinding에서 프레임 시간 가져옴
    return PerformanceMetric(
      metricId: 'frame_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Frame Time',
      value: 16.7, // 60fps
      unit: 'ms',
      timestamp: DateTime.now(),
    );
  }

  MemoryUsage _collectMemory() {
    // 실제로는 platform_info 또는 다른 방법으로 메모리 정보 가져옴
    final memory = MemoryUsage(
      heapUsed: 50 * 1024 * 1024, // 50MB
      heapCapacity: 100 * 1024 * 1024, // 100MB
      externalUsed: 10 * 1024 * 1024, // 10MB
      timestamp: DateTime.now(),
    );

    _memorySnapshots.add(memory);

    return memory;
  }

  PerformanceMetric _collectCPUUsage() {
    // 실제로는 플랫폼별 API 사용
    return PerformanceMetric(
      metricId: 'cpu_${DateTime.now().millisecondsSinceEpoch}',
      name: 'CPU Usage',
      value: 30.0,
      unit: '%',
      timestamp: DateTime.now(),
    );
  }

  /// 로그 조회
  List<LogEntry> getLogs({
    LogLevel? minLevel,
    String? tag,
    int limit = 1000,
  }) {
    var logs = _logs.toList();

    if (minLevel != null) {
      logs = logs.where((l) => l.level.index >= minLevel.index).toList();
    }

    if (tag != null) {
      logs = logs.where((l) => l.tag == tag).toList();
    }

    return logs.take(limit).toList();
  }

  /// 로그 검색
  List<LogEntry> searchLogs(String query) {
    return _logs.where((log) =>
        log.message.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// 로그 클리어
  void clearLogs() {
    _logs.clear();
  }

  /// 네트워크 기록 조회
  (List<NetworkRequest>, List<NetworkResponse>) getNetworkHistory() {
    return (_requests.toList(), _responses.toList());
  }

  /// 네트워크 기록 클리어
  void clearNetworkHistory() {
    _requests.clear();
    _responses.clear();
  }

  /// 성능 메트릭 조회
  List<PerformanceMetric> getMetrics({String? name}) {
    if (name != null) {
      return _metrics.where((m) => m.name == name).toList();
    }
    return _metrics.toList();
  }

  /// 메모리 스냅샷 조회
  List<MemoryUsage> getMemorySnapshots() {
    return _memorySnapshots.toList();
  }

  /// 위젯 트리 조회
  WidgetTreeNode? get widgetTree => _widgetTree;

  /// 간편 로그 메서드들
  void verbose(String message, {String? tag}) =>
      log(level: LogLevel.verbose, message: message, tag: tag);

  void debug(String message, {String? tag}) =>
      log(level: LogLevel.debug, message: message, tag: tag);

  void info(String message, {String? tag}) =>
      log(level: LogLevel.info, message: message, tag: tag);

  void warning(String message, {String? tag}) =>
      log(level: LogLevel.warning, message: message, tag: tag);

  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      log(
        level: LogLevel.error,
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  void fatal(String message, {String? tag, dynamic error, StackTrace? stackTrace}) =>
      log(
        level: LogLevel.fatal,
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  void dispose() {
    _logController.close();
    _requestController.close();
    _responseController.close();
    _widgetTreeController.close();
    _metricController.close();
    _memoryController.close();
    _metricTimer?.cancel();
  }
}

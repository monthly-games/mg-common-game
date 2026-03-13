import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 프로파일링 타입
enum ProfilingType {
  cpu,            // CPU 사용량
  memory,         // 메모리 사용량
  gpu,            // GPU 사용량
  network,        // 네트워크 사용량
  frameRate,      // 프레임 레이트
  battery,        // 배터리 사용량
  disk,           // 디스크 I/O
  custom,         // 사용자 정의
}

/// 성능 메트릭
class PerformanceMetric {
  final String id;
  final ProfilingType type;
  final String name;
  final double value; // 현재 값
  final double average; // 평균
  final double peak; // 최대값
  final double min; // 최소값
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.id,
    required this.type,
    required this.name,
    required this.value,
    required this.average,
    required this.peak,
    required this.min,
    required this.timestamp,
    required this.metadata,
  });

  /// 심각도
  Severity get severity {
    switch (type) {
      case ProfilingType.cpu:
        if (value > 90) return Severity.critical;
        if (value > 70) return Severity.warning;
        return Severity.normal;
      case ProfilingType.memory:
        if (value > 500) return Severity.critical; // MB
        if (value > 300) return Severity.warning;
        return Severity.normal;
      case ProfilingType.frameRate:
        if (value < 30) return Severity.critical; // FPS
        if (value < 50) return Severity.warning;
        return Severity.normal;
      default:
        return Severity.normal;
    }
  }
}

/// 심각도
enum Severity {
  normal,        // 정상
  warning,       // 경고
  critical,      // 심각
}

/// 프레임 메트릭
class FrameMetric {
  final int frameNumber;
  final Duration duration;
  final double fps;
  final DateTime timestamp;
  final bool isDropped;

  const FrameMetric({
    required this.frameNumber,
    required this.duration,
    required this.fps,
    required this.timestamp,
    required this.isDropped,
  });
}

/// 메모리 스냅샷
class MemorySnapshot {
  final DateTime timestamp;
  final int usedHeap; // bytes
  final int totalHeap; // bytes
  final int external; // bytes
  final List<MemoryAllocation> allocations;

  const MemorySnapshot({
    required this.timestamp,
    required this.usedHeap,
    required this.totalHeap,
    required this.external,
    required this.allocations,
  });

  /// 사용률
  double get usageRate => totalHeap > 0 ? usedHeap / totalHeap : 0.0;

  /// MB 단위
  double get usedHeapMB => usedHeap / (1024 * 1024);
  double get totalHeapMB => totalHeap / (1024 * 1024);
}

/// 메모리 할당
class MemoryAllocation {
  final String className;
  final int size; // bytes
  final int count;
  final String? library;

  const MemoryAllocation({
    required this.className,
    required this.size,
    required this.count,
    this.library,
  });
}

/// 네트워크 요청
class NetworkRequest {
  final String id;
  final String url;
  final String method;
  final int? statusCode;
  final Duration? duration;
  final int requestSize; // bytes
  final int responseSize; // bytes
  final DateTime timestamp;
  final bool isSuccess;

  const NetworkRequest({
    required this.id,
    required this.url,
    required this.method,
    this.statusCode,
    this.duration,
    required this.requestSize,
    required this.responseSize,
    required this.timestamp,
    required this.isSuccess,
  });
}

/// 배터리 메트릭
class BatteryMetric {
  final DateTime timestamp;
  final int level; // 0-100
  final bool isCharging;
  final double dischargeRate; // % per hour

  const BatteryMetric({
    required this.timestamp,
    required this.level,
    required this.isCharging,
    required this.dischargeRate,
  });
}

/// 성능 병목 현상
class PerformanceBottleneck {
  final String id;
  final String description;
  final ProfilingType type;
  final Severity severity;
  final String location; // 코드 위치
  final double impact; // 0.0 - 1.0
  final List<String> suggestions;
  final DateTime detectedAt;

  const PerformanceBottleneck({
    required this.id,
    required this.description,
    required this.type,
    required this.severity,
    required this.location,
    required this.impact,
    required this.suggestions,
    required this.detectedAt,
  });
}

/// 프로파일링 세션
class ProfilingSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ProfilingType> activeProfiles;
  final Map<String, List<PerformanceMetric>> metrics;
  final List<FrameMetric> frames;
  final List<NetworkRequest> networkRequests;
  final List<MemorySnapshot> memorySnapshots;
  final List<BatteryMetric> batteryMetrics;

  const ProfilingSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.activeProfiles,
    required this.metrics,
    required this.frames,
    required this.networkRequests,
    required this.memorySnapshots,
    required this.batteryMetrics,
  });

  /// 세션 지속 시간
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  /// 평균 FPS
  double get averageFPS {
    if (frames.isEmpty) return 0.0;
    final total = frames.fold<double>(0.0, (sum, f) => sum + f.fps);
    return total / frames.length;
  }

  /// 드롭된 프레임 비율
  double get droppedFrameRate {
    if (frames.isEmpty) return 0.0;
    final dropped = frames.where((f) => f.isDropped).length;
    return dropped / frames.length;
  }
}

/// 성능 프로파일러 관리자
class PerformanceProfilerManager {
  static final PerformanceProfilerManager _instance =
      PerformanceProfilerManager._();
  static PerformanceProfilerManager get instance => _instance;

  PerformanceProfilerManager._();

  SharedPreferences? _prefs;
  ProfilingSession? _currentSession;

  final List<ProfilingSession> _sessions = [];
  final Map<String, List<PerformanceMetric>> _metricsHistory = {};

  final StreamController<PerformanceMetric> _metricController =
      StreamController<PerformanceMetric>.broadcast();
  final StreamController<FrameMetric> _frameController =
      StreamController<FrameMetric>.broadcast();
  final StreamController<PerformanceBottleneck> _bottleneckController =
      StreamController<PerformanceBottleneck>.broadcast();

  Stream<PerformanceMetric> get onMetric => _metricController.stream;
  Stream<FrameMetric> get onFrame => _frameController.stream;
  Stream<PerformanceBottleneck> get onBottleneck =>
      _bottleneckController.stream;

  Timer? _profilingTimer;
  int _frameCount = 0;
  DateTime? _lastFrameTime;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 세션 로드
    await _loadSessions();

    debugPrint('[PerformanceProfiler] Initialized');
  }

  Future<void> _loadSessions() async {
    final sessionsJson = _prefs?.getString('profiling_sessions');
    if (sessionsJson != null) {
      // 실제로는 파싱
    }
  }

  /// 프로파일링 시작
  Future<ProfilingSession> startProfiling({
    List<ProfilingType>? profiles,
  }) async {
    if (_currentSession != null) {
      throw Exception('Profiling session already active');
    }

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final activeProfiles = profiles ?? ProfilingType.values;

    _currentSession = ProfilingSession(
      id: sessionId,
      startedAt: DateTime.now(),
      activeProfiles: activeProfiles,
      metrics: {},
      frames: [],
      networkRequests: [],
      memorySnapshots: [],
      batteryMetrics: [],
    );

    // 타이머 시작
    _startProfilingTimer(activeProfiles);

    // 프레임 모니터링 시작
    _startFrameMonitoring();

    debugPrint('[PerformanceProfiler] Profiling started: $sessionId');

    return _currentSession!;
  }

  /// 프로파일링 타이머 시작
  void _startProfilingTimer(List<ProfilingType> profiles) {
    _profilingTimer?.cancel();
    _profilingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _collectMetrics(profiles);
    });
  }

  /// 메트릭 수집
  Future<void> _collectMetrics(List<ProfilingType> profiles) async {
    for (final type in profiles) {
      final metric = await _collectMetric(type);
      if (metric != null) {
        _metricController.add(metric);

        // 병목 현상 탐지
        await _detectBottlenecks(metric);
      }
    }
  }

  /// 메트릭 수집
  Future<PerformanceMetric?> _collectMetric(ProfilingType type) async {
    final sessionId = _currentSession?.id ?? '';
    final timestamp = DateTime.now();

    switch (type) {
      case ProfilingType.cpu:
        return _collectCPUMetric(sessionId, timestamp);
      case ProfilingType.memory:
        return _collectMemoryMetric(sessionId, timestamp);
      case ProfilingType.gpu:
        return _collectGPUMetric(sessionId, timestamp);
      case ProfilingType.network:
        return _collectNetworkMetric(sessionId, timestamp);
      case ProfilingType.frameRate:
        return _collectFrameRateMetric(sessionId, timestamp);
      case ProfilingType.battery:
        return _collectBatteryMetric(sessionId, timestamp);
      case ProfilingType.disk:
        return _collectDiskMetric(sessionId, timestamp);
      default:
        return null;
    }
  }

  /// CPU 메트릭 수집
  PerformanceMetric _collectCPUMetric(String sessionId, DateTime timestamp) {
    // 실제 환경에서는 시스템 API 호출
    final value = 30.0 + (DateTime.now().millisecond % 40).toDouble();

    return PerformanceMetric(
      id: 'cpu_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.cpu,
      name: 'CPU Usage',
      value: value,
      average: 40.0,
      peak: 85.0,
      min: 10.0,
      timestamp: timestamp,
      metadata: {'cores': 8},
    );
  }

  /// 메모리 메트릭 수집
  PerformanceMetric _collectMemoryMetric(String sessionId, DateTime timestamp) {
    // 실제 환경에서는 dart:developer 사용
    final value = 150.0 + (DateTime.now().millisecond % 200).toDouble();

    return PerformanceMetric(
      id: 'memory_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.memory,
      name: 'Memory Usage',
      value: value,
      average: 200.0,
      peak: 450.0,
      min: 100.0,
      timestamp: timestamp,
      metadata: {'unit': 'MB'},
    );
  }

  /// GPU 메트릭 수집
  PerformanceMetric _collectGPUMetric(String sessionId, DateTime timestamp) {
    final value = 20.0 + (DateTime.now().millisecond % 60).toDouble();

    return PerformanceMetric(
      id: 'gpu_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.gpu,
      name: 'GPU Usage',
      value: value,
      average: 35.0,
      peak: 80.0,
      min: 5.0,
      timestamp: timestamp,
      metadata: {'renderer': 'OpenGL ES 3.0'},
    );
  }

  /// 네트워크 메트릭 수집
  PerformanceMetric _collectNetworkMetric(String sessionId, DateTime timestamp) {
    final value = 50.0 + (DateTime.now().millisecond % 100).toDouble(); // KB/s

    return PerformanceMetric(
      id: 'network_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.network,
      name: 'Network Usage',
      value: value,
      average: 75.0,
      peak: 500.0,
      min: 0.0,
      timestamp: timestamp,
      metadata: {'unit': 'KB/s'},
    );
  }

  /// 프레임 레이트 메트릭 수집
  PerformanceMetric _collectFrameRateMetric(
    String sessionId,
    DateTime timestamp,
  ) {
    final frames = _currentSession?.frames ?? [];
    final avgFPS = frames.isNotEmpty
        ? frames.map((f) => f.fps).reduce((a, b) => a + b) / frames.length
        : 60.0;

    return PerformanceMetric(
      id: 'fps_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.frameRate,
      name: 'Frame Rate',
      value: avgFPS,
      average: 58.0,
      peak: 60.0,
      min: 30.0,
      timestamp: timestamp,
      metadata: {'target_fps': 60},
    );
  }

  /// 배터리 메트릭 수집
  PerformanceMetric _collectBatteryMetric(String sessionId, DateTime timestamp) {
    final value = 2.0 + (DateTime.now().millisecond % 8).toDouble(); // % per hour

    return PerformanceMetric(
      id: 'battery_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.battery,
      name: 'Battery Drain',
      value: value,
      average: 5.0,
      peak: 15.0,
      min: 1.0,
      timestamp: timestamp,
      metadata: {'unit': '%/hour'},
    );
  }

  /// 디스크 메트릭 수집
  PerformanceMetric _collectDiskMetric(String sessionId, DateTime timestamp) {
    final value = 10.0 + (DateTime.now().millisecond % 50).toDouble(); // MB/s

    return PerformanceMetric(
      id: 'disk_${timestamp.millisecondsSinceEpoch}',
      type: ProfilingType.disk,
      name: 'Disk I/O',
      value: value,
      average: 20.0,
      peak: 100.0,
      min: 0.0,
      timestamp: timestamp,
      metadata: {'unit': 'MB/s'},
    );
  }

  /// 프레임 모니터링 시작
  void _startFrameMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      _onFrame();
    });
  }

  /// 프레임 콜백
  void _onFrame() {
    if (_currentSession == null) return;

    final now = DateTime.now();
    _frameCount++;

    if (_lastFrameTime != null) {
      final duration = now.difference(_lastFrameTime!);
      final fps = 1000.0 / duration.inMilliseconds.toDouble();
      final isDropped = fps < 55; // 55 FPS 이하면 드롭으로 간주

      final frame = FrameMetric(
        frameNumber: _frameCount,
        duration: duration,
        fps: fps,
        timestamp: now,
        isDropped: isDropped,
      );

      _currentSession!.frames.add(frame);
      _frameController.add(frame);

      // 10초마다 메모리 스냅샷
      if (_frameCount % 600 == 0) {
        _captureMemorySnapshot();
      }
    }

    _lastFrameTime = now;
  }

  /// 메모리 스냅샷 캡처
  Future<void> _captureMemorySnapshot() async {
    if (_currentSession == null) return;

    // 실제 환경에서는 dart:developer 사용
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      usedHeap: 150 * 1024 * 1024,
      totalHeap: 200 * 1024 * 1024,
      external: 50 * 1024 * 1024,
      allocations: const [
        MemoryAllocation(
          className: 'List',
          size: 10 * 1024 * 1024,
          count: 1000,
          library: 'dart:core',
        ),
        MemoryAllocation(
          className: 'Image',
          size: 50 * 1024 * 1024,
          count: 10,
          library: 'package:flutter/src/painting/image.dart',
        ),
      ],
    );

    _currentSession!.memorySnapshots.add(snapshot);

    debugPrint('[PerformanceProfiler] Memory snapshot captured');
  }

  /// 네트워크 요청 추적
  void trackNetworkRequest({
    required String url,
    required String method,
    int? statusCode,
    Duration? duration,
    int requestSize = 0,
    int responseSize = 0,
  }) {
    if (_currentSession == null) return;

    final request = NetworkRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      url: url,
      method: method,
      statusCode: statusCode,
      duration: duration,
      requestSize: requestSize,
      responseSize: responseSize,
      timestamp: DateTime.now(),
      isSuccess: (statusCode ?? 0) >= 200 && (statusCode ?? 0) < 300,
    );

    _currentSession!.networkRequests.add(request);

    debugPrint('[PerformanceProfiler] Network request tracked: ${request.id}');
  }

  /// 병목 현상 탐지
  Future<void> _detectBottlenecks(PerformanceMetric metric) async {
    if (metric.severity != Severity.critical) return;

    final bottleneck = PerformanceBottleneck(
      id: 'bottleneck_${DateTime.now().millisecondsSinceEpoch}',
      description: '${metric.name} is critically high',
      type: metric.type,
      severity: Severity.critical,
      location: 'Unknown',
      impact: 0.8,
      suggestions: _getSuggestions(metric.type),
      detectedAt: DateTime.now(),
    );

    _bottleneckController.add(bottleneck);

    debugPrint('[PerformanceProfiler] Bottleneck detected: ${metric.type}');
  }

  /// 개선 제안
  List<String> _getSuggestions(ProfilingType type) {
    switch (type) {
      case ProfilingType.cpu:
        return [
          '비동기 작업 사용 (Isolate)',
          '애니메이션 복잡도 줄이기',
          '불필요한 계산 최적화',
        ];
      case ProfilingType.memory:
        return [
          '메모리 누수 확인',
          '이미지 캐싱 최적화',
          '불필요한 객체 제거',
        ];
      case ProfilingType.frameRate:
        return [
          '위젯 리빌드 최적화',
          'const 생성자 사용',
          'RepaintBoundary 사용',
        ];
      default:
        return ['프로파일링 계속 진행'];
    }
  }

  /// 프로파일링 중지
  Future<ProfilingSession> stopProfiling() async {
    if (_currentSession == null) {
      throw Exception('No active profiling session');
    }

    _profilingTimer?.cancel();

    final session = ProfilingSession(
      id: _currentSession!.id,
      startedAt: _currentSession!.startedAt,
      endedAt: DateTime.now(),
      activeProfiles: _currentSession!.activeProfiles,
      metrics: _currentSession!.metrics,
      frames: List.from(_currentSession!.frames),
      networkRequests: List.from(_currentSession!.networkRequests),
      memorySnapshots: List.from(_currentSession!.memorySnapshots),
      batteryMetrics: List.from(_currentSession!.batteryMetrics),
    );

    _sessions.add(session);
    _currentSession = null;

    await _saveSession(session);

    debugPrint('[PerformanceProfiler] Profiling stopped: ${session.id}');

    return session;
  }

  /// 세션 저장
  Future<void> _saveSession(ProfilingSession session) async {
    await _prefs?.setString(
      'profiling_session_${session.id}',
      jsonEncode({
        'id': session.id,
        'startedAt': session.startedAt.toIso8601String(),
        'endedAt': session.endedAt?.toIso8601String(),
        'averageFPS': session.averageFPS,
        'droppedFrameRate': session.droppedFrameRate,
      }),
    );

    debugPrint('[PerformanceProfiler] Session saved: ${session.id}');
  }

  /// 세션 조회
  ProfilingSession? getSession(String sessionId) {
    return _sessions.firstWhere((s) => s.id == sessionId,
        orElse: () => _sessions.first);
  }

  /// 모든 세션 조회
  List<ProfilingSession> getSessions({int limit = 10}) {
    return _sessions.take(limit).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// 성능 리포트 생성
  Map<String, dynamic> generateReport(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) return {};

    return {
      'sessionId': session.id,
      'duration': session.duration?.inMinutes ?? 0,
      'averageFPS': session.averageFPS,
      'droppedFrameRate': session.droppedFrameRate,
      'totalFrames': session.frames.length,
      'networkRequests': session.networkRequests.length,
      'memorySnapshots': session.memorySnapshots.length,
      'summary': {
        'cpuUsage': _getMetricSummary(session, ProfilingType.cpu),
        'memoryUsage': _getMetricSummary(session, ProfilingType.memory),
        'frameRate': _getMetricSummary(session, ProfilingType.frameRate),
      },
      'recommendations': _generateRecommendations(session),
    };
  }

  /// 메트릭 요약
  Map<String, dynamic> _getMetricSummary(
    ProfilingSession session,
    ProfilingType type,
  ) {
    final metrics = session.metrics[type.name] ?? [];
    if (metrics.isEmpty) return {};

    return {
      'average': metrics.map((m) => m.value).reduce((a, b) => a + b) / metrics.length,
      'peak': metrics.map((m) => m.peak).reduce((a, b) => a > b ? a : b),
      'min': metrics.map((m) => m.min).reduce((a, b) => a < b ? a : b),
      'count': metrics.length,
    };
  }

  /// 추천사항 생성
  List<String> _generateRecommendations(ProfilingSession session) {
    final recommendations = <String>[];

    if (session.averageFPS < 50) {
      recommendations.add('프레임 레이트가 낮습니다. 위젯 최적화를 권장합니다.');
    }

    if (session.droppedFrameRate > 0.1) {
      recommendations.add('프레임 드롭이 많습니다. 애니메이션을 최적화하세요.');
    }

    if (session.networkRequests.length > 100) {
      recommendations.add('네트워크 요청이 많습니다. 요청을 병합하세요.');
    }

    if (session.memorySnapshots.isNotEmpty) {
      final avgMemory = session.memorySnapshots
          .map((s) => s.usedHeapMB)
          .reduce((a, b) => a + b) / session.memorySnapshots.length;

      if (avgMemory > 300) {
        recommendations.add('메모리 사용량이 높습니다. 메모리 누수를 확인하세요.');
      }
    }

    return recommendations;
  }

  /// 실시간 메트릭 스트림
  Stream<Map<ProfilingType, PerformanceMetric>> getRealtimeMetrics() async* {
    if (_currentSession == null) return;

    while (_currentSession != null) {
      await Future.delayed(const Duration(seconds: 1));

      final metrics = <ProfilingType, PerformanceMetric>{};

      for (final type in _currentSession!.activeProfiles) {
        final metric = await _collectMetric(type);
        if (metric != null) {
          metrics[type] = metric;
        }
      }

      if (metrics.isNotEmpty) {
        yield metrics;
      }
    }
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    return {
      'totalSessions': _sessions.length,
      'currentSession': _currentSession?.id,
      'totalFrames': _sessions.fold<int>(
          0, (sum, s) => sum + s.frames.length),
      'averageFPS': _sessions.isEmpty
          ? 0.0
          : _sessions
                  .map((s) => s.averageFPS)
                  .reduce((a, b) => a + b) /
              _sessions.length,
    };
  }

  void dispose() {
    _profilingTimer?.cancel();
    _metricController.close();
    _frameController.close();
    _bottleneckController.close();
  }
}

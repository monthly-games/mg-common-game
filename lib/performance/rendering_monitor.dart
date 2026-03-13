import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

/// 렌더링 성능 메트릭
class RenderingMetrics {
  final double fps;
  final Duration frameTime;
  final int frameCount;
  final int droppedFrames;
  final DateTime timestamp;

  const RenderingMetrics({
    required this.fps,
    required this.frameTime,
    required this.frameCount,
    required this.droppedFrames,
    required this.timestamp,
  });

  /// 60fps 기준 프레임 드롭 여부
  bool get hasDroppedFrames => droppedFrames > 0;

  /// 성능 등급
  PerformanceGrade get grade {
    if (fps >= 55) return PerformanceGrade.excellent;
    if (fps >= 45) return PerformanceGrade.good;
    if (fps >= 30) return PerformanceGrade.fair;
    return PerformanceGrade.poor;
  }

  Map<String, dynamic> toJson() => {
        'fps': fps,
        'frameTime': frameTime.inMicroseconds,
        'frameCount': frameCount,
        'droppedFrames': droppedFrames,
        'timestamp': timestamp.toIso8601String(),
        'grade': grade.name,
      };
}

/// 성능 등급
enum PerformanceGrade {
  excellent,
  good,
  fair,
  poor,
}

/// 렌더링 이벤트
class RenderingEvent {
  final RenderingEventType type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const RenderingEvent({
    required this.type,
    required this.message,
    this.data = const {},
    required this.timestamp,
  });
}

/// 렌더링 이벤트 타입
enum RenderingEventType {
  frameDropped,
  lowFps,
  highFps,
  stutter,
  recovery,
}

/// 렌더링 모니터
class RenderingMonitor {
  static final RenderingMonitor _instance = RenderingMonitor._();
  static RenderingMonitor get instance => _instance;

  RenderingMonitor._();

  final StreamController<RenderingMetrics> _metricsController =
      StreamController<RenderingMetrics>.broadcast();
  final StreamController<RenderingEvent> _eventController =
      StreamController<RenderingEvent>.broadcast();

  Ticker? _ticker;
  DateTime? _lastFrameTime;
  int _frameCount = 0;
  int _droppedFrames = 0;
  List<double> _fpsHistory = [];
  static const int _maxHistorySize = 60;

  // 임계값
  double _targetFps = 60.0;
  double _lowFpsThreshold = 45.0;
  Duration _frameTimeThreshold = const Duration(milliseconds: 20);

  // Getters
  Stream<RenderingMetrics> get onMetrics => _metricsController.stream;
  Stream<RenderingEvent> get onEvent => _eventController.stream;
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  double get averageFps {
    if (_fpsHistory.isEmpty) return 0.0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  // ============================================
  // 모니터링 시작/중지
  // ============================================

  void startMonitoring() {
    if (_ticker != null) return;

    _ticker = createTicker(_onTick);
    _ticker!.start();

    debugPrint('[RenderingMonitor] Monitoring started');
  }

  void stopMonitoring() {
    _ticker?.dispose();
    _ticker = null;

    debugPrint('[RenderingMonitor] Monitoring stopped');
  }

  /// 틱 핸들러
  void _onTick(Duration elapsed) {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);
      final fps = 1000000 / frameTime.inMicroseconds;

      _frameCount++;
      _fpsHistory.add(fps);
      if (_fpsHistory.length > _maxHistorySize) {
        _fpsHistory.removeAt(0);
      }

      // 프레임 드롭 체크
      if (frameTime > _frameTimeThreshold) {
        _droppedFrames++;
        _reportEvent(RenderingEventType.frameDropped, 'Frame dropped', {
          'frameTime': frameTime.inMicroseconds,
          'threshold': _frameTimeThreshold.inMicroseconds,
        });
      }

      // 낮은 FPS 체크
      if (fps < _lowFpsThreshold && _frameCount % 60 == 0) {
        _reportEvent(RenderingEventType.lowFps, 'Low FPS detected', {
          'fps': fps,
          'threshold': _lowFpsThreshold,
        });
      }

      // 메트릭 전송 (1초마다)
      if (_frameCount % 60 == 0) {
        final metrics = RenderingMetrics(
          fps: averageFps,
          frameTime: frameTime,
          frameCount: _frameCount,
          droppedFrames: _droppedFrames,
          timestamp: now,
        );
        _metricsController.add(metrics);
      }
    }

    _lastFrameTime = now;
  }

  /// 이벤트 보고
  void _reportEvent(
    RenderingEventType type,
    String message,
    Map<String, dynamic> data,
  ) {
    final event = RenderingEvent(
      type: type,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
    _eventController.add(event);

    if (kDebugMode) {
      debugPrint('[RenderingMonitor] Event: ${type.name} - $message');
    }
  }

  // ============================================
  // 설정
  // ============================================

  void setTargetFps(double fps) {
    _targetFps = fps.clamp(30.0, 120.0);
    _frameTimeThreshold = Duration(microseconds: (1000000 / _targetFps).round());
    debugPrint('[RenderingMonitor] Target FPS: $_targetFps');
  }

  void setLowFpsThreshold(double threshold) {
    _lowFpsThreshold = threshold.clamp(10.0, _targetFps);
    debugPrint('[RenderingMonitor] Low FPS threshold: $_lowFpsThreshold');
  }

  /// 성능 보고서 생성
  String generateReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== Rendering Performance Report ===');
    buffer.writeln();

    buffer.writeln('Overall Statistics:');
    buffer.writeln('  Average FPS: ${averageFps.toStringAsFixed(1)}');
    buffer.writeln('  Target FPS: $_targetFps');
    buffer.writeln('  Total Frames: $_frameCount');
    buffer.writeln('  Dropped Frames: $_droppedFrames');
    buffer.writeln();

    if (_fpsHistory.isNotEmpty) {
      final minFps = _fpsHistory.reduce((a, b) => a < b ? a : b);
      final maxFps = _fpsHistory.reduce((a, b) => a > b ? a : b);

      buffer.writeln('FPS Range:');
      buffer.writeln('  Min: ${minFps.toStringAsFixed(1)}');
      buffer.writeln('  Max: ${maxFps.toStringAsFixed(1)}');
      buffer.writeln();
    }

    final currentGrade = _getCurrentGrade();
    buffer.writeln('Performance Grade: ${currentGrade.name}');

    return buffer.toString();
  }

  PerformanceGrade _getCurrentGrade() {
    final avg = averageFps;
    if (avg >= 55) return PerformanceGrade.excellent;
    if (avg >= 45) return PerformanceGrade.good;
    if (avg >= 30) return PerformanceGrade.fair;
    return PerformanceGrade.poor;
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _metricsController.close();
    _eventController.close();
  }
}

/// 렌더링 성능 위젯
class RenderingPerformanceWidget extends StatefulWidget {
  final bool showDetails;

  const RenderingPerformanceWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  State<RenderingPerformanceWidget> createState() =>
      _RenderingPerformanceWidgetState();
}

class _RenderingPerformanceWidgetState
    extends State<RenderingPerformanceWidget> {
  RenderingMetrics? _currentMetrics;
  PerformanceGrade _currentGrade = PerformanceGrade.excellent;

  @override
  void initState() {
    super.initState();

    RenderingMonitor.instance.startMonitoring();

    RenderingMonitor.instance.onMetrics.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
          _currentGrade = metrics.grade;
        });
      }
    });
  }

  @override
  void dispose() {
    RenderingMonitor.instance.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradeColors(_currentGrade);

    return Card(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getGradeIcon(_currentGrade),
                  color: colors.icon,
                ),
                const SizedBox(width: 8),
                Text(
                  '렌더링 성능',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FPS 표시
            Row(
              children: [
                Text(
                  '${_currentMetrics?.fps.toStringAsFixed(1) ?? RenderingMonitor.instance.averageFps.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  'FPS',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 등급 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.icon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getGradeLabel(_currentGrade),
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (widget.showDetails && _currentMetrics != null) ...[
              const SizedBox(height: 12),
              Text(
                '프레임: ${_currentMetrics!.frameCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '드롭된 프레임: ${_currentMetrics!.droppedFrames}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '프레임 시간: ${_currentMetrics!.frameTime.inMicroseconds / 1000}ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _GradeColors _getGradeColors(PerformanceGrade grade) {
    switch (grade) {
      case PerformanceGrade.excellent:
        return _GradeColors(
          background: Colors.green.shade50,
          icon: Colors.green,
          text: Colors.green.shade900,
        );
      case PerformanceGrade.good:
        return _GradeColors(
          background: Colors.lightGreen.shade50,
          icon: Colors.lightGreen,
          text: Colors.lightGreen.shade900,
        );
      case PerformanceGrade.fair:
        return _GradeColors(
          background: Colors.orange.shade50,
          icon: Colors.orange,
          text: Colors.orange.shade900,
        );
      case PerformanceGrade.poor:
        return _GradeColors(
          background: Colors.red.shade50,
          icon: Colors.red,
          text: Colors.red.shade900,
        );
    }
  }

  IconData _getGradeIcon(PerformanceGrade grade) {
    switch (grade) {
      case PerformanceGrade.excellent:
        return Icons.speed;
      case PerformanceGrade.good:
        return Icons.check_circle;
      case PerformanceGrade.fair:
        return Icons.warning;
      case PerformanceGrade.poor:
        return Icons.error;
    }
  }

  String _getGradeLabel(PerformanceGrade grade) {
    switch (grade) {
      case PerformanceGrade.excellent:
        return '우수';
      case PerformanceGrade.good:
        return '양호';
      case PerformanceGrade.fair:
        return '보통';
      case PerformanceGrade.poor:
        return '낮음';
    }
  }
}

class _GradeColors {
  final Color background;
  final Color icon;
  final Color text;

  _GradeColors({
    required this.background,
    required this.icon,
    required this.text,
  });
}

/// 성능 프로파일러 오버레이
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showMetrics;
  final bool showMemory;
  final bool showRendering;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showMetrics = true,
    this.showMemory = true,
    this.showRendering = true,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // 토글 버튼
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              color: Colors.transparent,
              child: const Center(
                child: Icon(
                  Icons.bug_report,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ),

        // 오버레이
        if (_isVisible)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('성능 모니터'),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isVisible = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      if (widget.showRendering)
                        const RenderingPerformanceWidget(showDetails: true),
                      if (widget.showMemory) ...[
                        const SizedBox(height: 8),
                        // MemoryProfilerWidget(showDetails: true),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

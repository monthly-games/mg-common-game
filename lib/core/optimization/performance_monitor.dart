import 'dart:collection';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'device_capability.dart';
import 'quality_settings.dart';

/// MG-Games 성능 모니터
/// DEVICE_OPTIMIZATION_GUIDE.md 기반
class MGPerformanceMonitor {
  MGPerformanceMonitor._();

  static MGPerformanceMonitor? _instance;
  static MGPerformanceMonitor get instance {
    _instance ??= MGPerformanceMonitor._();
    return _instance!;
  }

  // ============================================================
  // 상태
  // ============================================================

  bool _isMonitoring = false;
  final List<FrameTiming> _frameTimings = [];
  final Queue<double> _recentFps = Queue();
  static const int _maxSamples = 60;

  int _droppedFrameCount = 0;
  int _totalFrameCount = 0;

  /// 모니터링 중인지
  bool get isMonitoring => _isMonitoring;

  /// 평균 FPS
  double get averageFps {
    if (_recentFps.isEmpty) return 0;
    return _recentFps.reduce((a, b) => a + b) / _recentFps.length;
  }

  /// 최소 FPS (최근 샘플 중)
  double get minFps {
    if (_recentFps.isEmpty) return 0;
    return _recentFps.reduce((a, b) => a < b ? a : b);
  }

  /// 최대 FPS (최근 샘플 중)
  double get maxFps {
    if (_recentFps.isEmpty) return 0;
    return _recentFps.reduce((a, b) => a > b ? a : b);
  }

  /// 드롭 프레임 수
  int get droppedFrameCount => _droppedFrameCount;

  /// 총 프레임 수
  int get totalFrameCount => _totalFrameCount;

  /// 드롭 프레임 비율
  double get dropRate {
    if (_totalFrameCount == 0) return 0;
    return _droppedFrameCount / _totalFrameCount;
  }

  // ============================================================
  // 모니터링 제어
  // ============================================================

  /// 모니터링 시작
  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _reset();

    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// 모니터링 중지
  void stop() {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  /// 리셋
  void _reset() {
    _frameTimings.clear();
    _recentFps.clear();
    _droppedFrameCount = 0;
    _totalFrameCount = 0;
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameTimings.add(timing);
      _totalFrameCount++;

      // FPS 계산
      final frameDuration = timing.totalSpan;
      final fps = 1000000 / frameDuration.inMicroseconds;

      _recentFps.addLast(fps);
      if (_recentFps.length > _maxSamples) {
        _recentFps.removeFirst();
      }

      // 드롭 프레임 감지 (16.67ms = 60fps 기준)
      if (frameDuration.inMilliseconds > 20) {
        _droppedFrameCount++;
      }
    }
  }

  // ============================================================
  // 분석
  // ============================================================

  /// 성능 상태 분석
  PerformanceState get performanceState {
    final fps = averageFps;
    final drops = dropRate;

    if (fps >= 55 && drops < 0.02) {
      return PerformanceState.excellent;
    } else if (fps >= 45 && drops < 0.05) {
      return PerformanceState.good;
    } else if (fps >= 30 && drops < 0.10) {
      return PerformanceState.acceptable;
    } else {
      return PerformanceState.poor;
    }
  }

  /// 권장 품질 설정
  MGQualitySettings get recommendedSettings {
    switch (performanceState) {
      case PerformanceState.excellent:
        return MGQualitySettings.high;
      case PerformanceState.good:
        return MGQualitySettings.medium;
      case PerformanceState.acceptable:
        return MGQualitySettings.medium.copyWith(
          particleQuality: 0.5,
          shadowsEnabled: false,
        );
      case PerformanceState.poor:
        return MGQualitySettings.low;
    }
  }

  /// 성능 보고서 생성
  PerformanceReport generateReport() {
    return PerformanceReport(
      averageFps: averageFps,
      minFps: minFps,
      maxFps: maxFps,
      droppedFrames: _droppedFrameCount,
      totalFrames: _totalFrameCount,
      dropRate: dropRate,
      state: performanceState,
      deviceTier: MGDeviceCapability.tier,
    );
  }
}

/// 성능 상태
enum PerformanceState {
  /// 우수 (55+ FPS, 드롭 < 2%)
  excellent,

  /// 양호 (45+ FPS, 드롭 < 5%)
  good,

  /// 적정 (30+ FPS, 드롭 < 10%)
  acceptable,

  /// 불량 (30 미만 FPS 또는 드롭 >= 10%)
  poor,
}

extension PerformanceStateExtension on PerformanceState {
  /// 표시 이름
  String get displayName {
    switch (this) {
      case PerformanceState.excellent:
        return '우수';
      case PerformanceState.good:
        return '양호';
      case PerformanceState.acceptable:
        return '적정';
      case PerformanceState.poor:
        return '불량';
    }
  }

  /// 색상
  Color get color {
    switch (this) {
      case PerformanceState.excellent:
        return Colors.green;
      case PerformanceState.good:
        return Colors.lightGreen;
      case PerformanceState.acceptable:
        return Colors.orange;
      case PerformanceState.poor:
        return Colors.red;
    }
  }

  /// 아이콘
  IconData get icon {
    switch (this) {
      case PerformanceState.excellent:
        return Icons.speed;
      case PerformanceState.good:
        return Icons.check_circle;
      case PerformanceState.acceptable:
        return Icons.warning;
      case PerformanceState.poor:
        return Icons.error;
    }
  }
}

/// 성능 보고서
class PerformanceReport {
  final double averageFps;
  final double minFps;
  final double maxFps;
  final int droppedFrames;
  final int totalFrames;
  final double dropRate;
  final PerformanceState state;
  final DeviceTier deviceTier;
  final DateTime timestamp;

  PerformanceReport({
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.dropRate,
    required this.state,
    required this.deviceTier,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'averageFps': averageFps,
      'minFps': minFps,
      'maxFps': maxFps,
      'droppedFrames': droppedFrames,
      'totalFrames': totalFrames,
      'dropRate': dropRate,
      'state': state.index,
      'deviceTier': deviceTier.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// FPS 표시 위젯
class MGFpsCounter extends StatefulWidget {
  final bool showDetails;
  final TextStyle? textStyle;

  const MGFpsCounter({
    super.key,
    this.showDetails = false,
    this.textStyle,
  });

  @override
  State<MGFpsCounter> createState() => _MGFpsCounterState();
}

class _MGFpsCounterState extends State<MGFpsCounter> {
  @override
  void initState() {
    super.initState();
    MGPerformanceMonitor.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = MGPerformanceMonitor.instance;
    final state = monitor.performanceState;

    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 500)),
      builder: (context, snapshot) {
        final fps = monitor.averageFps.toStringAsFixed(1);

        if (widget.showDetails) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$fps FPS',
                style: widget.textStyle?.copyWith(color: state.color) ??
                    TextStyle(
                      color: state.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
              Text(
                'Min: ${monitor.minFps.toStringAsFixed(0)} / Max: ${monitor.maxFps.toStringAsFixed(0)}',
                style: TextStyle(
                  color: state.color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              Text(
                'Drops: ${monitor.droppedFrameCount}',
                style: TextStyle(
                  color: state.color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }

        return Text(
          '$fps FPS',
          style: widget.textStyle?.copyWith(color: state.color) ??
              TextStyle(
                color: state.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
        );
      },
    );
  }
}

/// 성능 오버레이 위젯
class MGPerformanceOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Alignment position;

  const MGPerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.position = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: position == Alignment.topRight || position == Alignment.topLeft
              ? MediaQuery.of(context).padding.top + 8
              : null,
          bottom: position == Alignment.bottomRight ||
                  position == Alignment.bottomLeft
              ? MediaQuery.of(context).padding.bottom + 8
              : null,
          left: position == Alignment.topLeft ||
                  position == Alignment.bottomLeft
              ? 8
              : null,
          right: position == Alignment.topRight ||
                  position == Alignment.bottomRight
              ? 8
              : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const MGFpsCounter(showDetails: true),
          ),
        ),
      ],
    );
  }
}

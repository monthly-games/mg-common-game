import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'device_capability.dart';

/// 성능 프로파일링 데이터
class PerformanceData {
  final String name;
  final Duration duration;
  final int frameCount;
  final double averageFps;
  final double minFps;
  final double maxFps;
  final int droppedFrames;
  final DateTime timestamp;

  const PerformanceData({
    required this.name,
    required this.duration,
    required this.frameCount,
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceData{name: $name, avgFps: $averageFps.toStringAsFixed(1)}, '
        'minFps: $minFps.toStringAsFixed(1), maxFps: $maxFps.toStringAsFixed(1)}, '
        'droppedFrames: $droppedFrames}';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'durationMs': duration.inMilliseconds,
        'frameCount': frameCount,
        'averageFps': averageFps,
        'minFps': minFps,
        'maxFps': maxFps,
        'droppedFrames': droppedFrames,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      name: json['name'] as String,
      duration: Duration(milliseconds: json['durationMs'] as int),
      frameCount: json['frameCount'] as int,
      averageFps: (json['averageFps'] as num).toDouble(),
      minFps: (json['minFps'] as num).toDouble(),
      maxFps: (json['maxFps'] as num).toDouble(),
      droppedFrames: json['droppedFrames'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 권장 티어 계산
  DeviceTier get recommendedTier {
    if (averageFps >= 55 && minFps >= 45) {
      return DeviceTier.high;
    } else if (averageFps >= 40 && minFps >= 25) {
      return DeviceTier.mid;
    } else {
      return DeviceTier.low;
    }
  }

  /// 성능 등급 (A, B, C, D, F)
  String get performanceGrade {
    if (averageFps >= 55 && minFps >= 50 && droppedFrames == 0) {
      return 'A';
    } else if (averageFps >= 50 && minFps >= 40 && droppedFrames <= 5) {
      return 'B';
    } else if (averageFps >= 40 && minFps >= 30 && droppedFrames <= 10) {
      return 'C';
    } else if (averageFps >= 30 && minFps >= 20) {
      return 'D';
    } else {
      return 'F';
    }
  }
}

/// 프레임 시간 데이터
class FrameTimeData {
  final int frameNumber;
  final Duration frameTime;
  final DateTime timestamp;

  const FrameTimeData({
    required this.frameNumber,
    required this.frameTime,
    required this.timestamp,
  });

  bool get isDropped => frameTime.inMilliseconds > 16; // 60fps 기준

  @override
  String toString() {
    return 'Frame #$frameNumber: ${frameTime.inMilliseconds}ms${isDropped ? " [DROPPED]" : ""}';
  }
}

/// MG Games 성능 프로파일러
///
/// 실시간 성능 모니터링, 프레임 시간 추적, 메모리 사용량 분석 기능 제공
class MGPerformanceProfiler extends ChangeNotifier {
  static final MGPerformanceProfiler _instance = MGPerformanceProfiler._();
  static MGPerformanceProfiler get instance => _instance;

  MGPerformanceProfiler._();

  // ============================================
  // 상태
  // ============================================
  bool _isProfiling = false;
  Timer? _profileTimer;
  Timer? _frameTimer;
  final List<PerformanceData> _history = [];
  final List<FrameTimeData> _frameTimeHistory = [];

  int _currentFrameCount = 0;
  DateTime? _lastFrameTime;
  DateTime? _profileStartTime;

  final List<double> _fpsValues = [];
  final List<Duration> _frameTimes = [];

  int _totalDroppedFrames = 0;
  double _minFps = double.infinity;
  double _maxFps = 0.0;

  // ============================================
  // Getters
  // ============================================
  bool get isProfiling => _isProfiling;
  List<PerformanceData> get history => List.unmodifiable(_history);
  List<FrameTimeData> get frameTimeHistory => List.unmodifiable(_frameTimeHistory);
  int get totalDroppedFrames => _totalDroppedFrames;

  /// 현재 FPS (실시간 추정치)
  double get currentFps {
    if (_frameTimes.isEmpty) return 0.0;
    if (_frameTimes.length < 3) return 60.0;

    // 최근 3프레임의 평균
    final recentFrameTimes = _frameTimes.take(3).toList();
    final avgFrameTime = recentFrameTimes.reduce(
        (a, b) => Duration(
            microseconds:
                (a.inMicroseconds + b.inMicroseconds) ~/ 2,
        ),
    );

    if (avgFrameTime.inMicroseconds == 0) return 60.0;
    return 1000000 / avgFrameTime.inMicroseconds;
  }

  /// 평균 FPS (현재 프로파일링 세션)
  double get averageFps {
    if (_fpsValues.isEmpty) return 0.0;
    return _fpsValues.reduce((a, b) => a + b) / _fpsValues.length;
  }

  /// 최소 FPS
  double get minFps => _minFps == double.infinity ? 0.0 : _minFps;

  /// 최대 FPS
  double get maxFps => _maxFps;

  // ============================================
  // 프로파일링 제어
  // ============================================

  /// 프로파일링 시작
  void startProfile({String? name}) {
    if (_isProfiling) {
      debugPrint('Already profiling');
      return;
    }

    _isProfiling = true;
    _profileStartTime = DateTime.now();
    _currentFrameCount = 0;
    _totalDroppedFrames = 0;
    _minFps = double.infinity;
    _maxFps = 0.0;
    _fpsValues.clear();
    _frameTimes.clear();
    _frameTimeHistory.clear();

    debugPrint('Performance profiler started: ${name ?? "unnamed"}');
    notifyListeners();

    // 1초마다 FPS 계산
    _profileTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateFps();
    });

    // 매 프레임마다 프레임 시간 기록
    _startFrameTracking();
  }

  /// 프로파일링 중지 및 결과 반환
  PerformanceData? stopProfile({String? name}) {
    if (!_isProfiling) {
      debugPrint('Not profiling');
      return null;
    }

    _isProfiling = false;

    // 타이머 중지
    _profileTimer?.cancel();
    _frameTimer?.cancel();
    _profileTimer = null;
    _frameTimer = null;

    // 최종 FPS 계산
    _calculateFps();

    // 프로파일링 데이터 생성
    final duration = DateTime.now().difference(_profileStartTime!);
    final avgFps = averageFps;

    final data = PerformanceData(
      name: name ?? 'profile_${_history.length}',
      duration: duration,
      frameCount: _currentFrameCount,
      averageFps: avgFps,
      minFps: _minFps,
      maxFps: _maxFps,
      droppedFrames: _totalDroppedFrames,
      timestamp: DateTime.now(),
    );

    _history.add(data);

    debugPrint('Performance profiler stopped: $data');
    notifyListeners();

    return data;
  }

  /// 현재까지의 프로파일링 결과 반환 (중지 없음)
  PerformanceData? getCurrentProfile({String? name}) {
    if (!_isProfiling || _profileStartTime == null) {
      return null;
    }

    final duration = DateTime.now().difference(_profileStartTime!);
    final avgFps = averageFps;

    return PerformanceData(
      name: name ?? 'current',
      duration: duration,
      frameCount: _currentFrameCount,
      averageFps: avgFps,
      minFps: _minFps,
      maxFps: _maxFps,
      droppedFrames: _totalDroppedFrames,
      timestamp: DateTime.now(),
    );
  }

  /// 프로파일링 기록 초기화
  void clearHistory() {
    _history.clear();
    _frameTimeHistory.clear();
    _totalDroppedFrames = 0;
    notifyListeners();
  }

  // ============================================
  // 내부 메서드
  // ============================================

  void _calculateFps() {
    if (_lastFrameTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime!).inMicroseconds;
    _lastFrameTime = now;

    if (elapsed > 0) {
      final fps = 1000000 / elapsed;
      _fpsValues.add(fps);

      // 최소/최대 FPS 업데이트
      if (fps < _minFps) _minFps = fps;
      if (fps > _maxFps) _maxFps = fps;

      // 드롭프레임 확인
      if (fps < 55) { // 55fps 미만은 드롭으로 간주
        _totalDroppedFrames++;
      }
    }

    _currentFrameCount++;
  }

  void _startFrameTracking() {
    _lastFrameTime = DateTime.now();

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isProfiling) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final frameTime = now.difference(_lastFrameTime!);
      _lastFrameTime = now;

      _frameTimes.add(frameTime);

      final frameData = FrameTimeData(
        frameNumber: _currentFrameCount,
        frameTime: frameTime,
        timestamp: now,
      );

      _frameTimeHistory.add(frameData);

      if (frameData.isDropped) {
        _totalDroppedFrames++;
      }

      _currentFrameCount++;

      // 프레임 히스토리 크기 제한
      if (_frameTimeHistory.length > 1000) {
        _frameTimeHistory.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    stopProfile();
    super.dispose();
  }
}

/// 성능 최적화 제안
class PerformanceOptimizer {
  const PerformanceOptimizer._();

  /// 프레임 레이트 최적화 제안
  static List<String> getOptimizationSuggestions(PerformanceData data) {
    final suggestions = <String>[];

    // 낮은 FPS
    if (data.averageFps < 30) {
      suggestions.add('FPS가 매우 낮습니다. 다음을 고려해보세요:');
      suggestions.add('  - 텍스처 품질 낮추기 (low/medium)');
      suggestions.add('  - 파티클 이펙트 줄이기');
      suggestions.add('  - 그림자 품질 낮추기');
    } else if (data.averageFps < 45) {
      suggestions.add('FPS 개선이 필요합니다:');
      suggestions.add('  - 텍스처 압축 사용');
      suggestions.add('  - 불필요한 위젯 제거');
    }

    // 드롭프레임
    if (data.droppedFrames > 10) {
      suggestions.add('드롭프레임이 많습니다:');
      suggestions.add('  - 복잡한 애니메이션 최적화');
      suggestions.add('  - GC(Garbage Collection) 최적화');
      suggestions.add('  - 계산 비용이 높은 작업 분리');
    }

    // 최소 FPS
    if (data.minFps < 20) {
      suggestions.add('최소 FPS가 너무 낮습니다:');
      suggestions.add('  - 로딩 시간 최적화');
      suggestions.add('  - 자원 프리로딩 고려');
    }

    // 권장 티어 확인
    final tier = data.recommendedTier;
    final currentTier = MGDeviceCapability.tier;

    if (tier.index < currentTier.index) {
      suggestions.add('현재 기기보다 낮은 티어가 권장됩니다:');
      suggestions.add('  - 현재: ${currentTier.displayName}');
      suggestions.add('  - 권장: ${tier.displayName}');
      suggestions.add('  - 설정을 낮추면 성능이 개선될 수 있습니다.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('성능이 양호합니다! 현재 설정을 유지하세요.');
    }

    return suggestions;
  }

  /// 권장 설정 반환
  static Map<String, dynamic> getRecommendedSettings(PerformanceData data) {
    final tier = data.recommendedTier;

    return {
      'textureQuality': MGDeviceCapability.recommendedTextureQuality,
      'targetFps': MGDeviceCapability.recommendedFps,
      'enableShadows': tier != DeviceTier.low,
      'enableParticles': tier != DeviceTier.low,
      'enablePostProcessing': tier == DeviceTier.high,
      'maxConcurrentAnimations': tier == DeviceTier.high
          ? 10
          : tier == DeviceTier.mid
              ? 5
              : 2,
      'cacheSizeMB': tier == DeviceTier.high
          ? 100
          : tier == DeviceTier.mid
              ? 50
              : 25,
    };
  }

  /// 성능 비교
  static String compareWithBaseline(PerformanceData current, PerformanceData? baseline) {
    if (baseline == null) {
      return '베이스라인 데이터가 없습니다.';
    }

    final fpsDiff = current.averageFps - baseline.averageFps;
    final droppedDiff = current.droppedFrames - baseline.droppedFrames;

    final result = StringBuffer();
    result.writeln('베이스라인과 비교:');
    result.writeln('  평균 FPS: ${fpsDiff > 0 ? "+" : ""}${fpsDiff.toStringAsFixed(1)}');
    result.writeln('  드롭프레임: ${droppedDiff > 0 ? "+" : ""}$droppedDiff');

    if (fpsDiff >= 5) {
      result.writeln('  ⇒ 성능이 개선되었습니다! ✓');
    } else if (fpsDiff <= -5) {
      result.writeln('  ⇒ 성능이 저하되었습니다. ✗');
    } else {
      result.writeln('  ⇒ 성능 변화가 미미합니다.');
    }

    return result.toString();
  }
}

/// 위젯 트리 성능 분석기
class WidgetPerformanceAnalyzer {
  const WidgetPerformanceAnalyzer._();

  /// 위젯 빌드 시간 측정
  static Future<T> measureWidgetBuildTime<T>(
    Future<T> Function() builder,
    String widgetName,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await builder();
    stopwatch.stop();

    final buildTime = stopwatch.elapsedMilliseconds;
    debugPrint('[$widgetName] 빌드 시간: ${buildTime}ms');

    if (buildTime > 16) {
      debugPrint('  ⚠️  빌드 시간이 16ms를 초과합니다. 최적화가 필요할 수 있습니다.');
    }

    return result;
  }

  /// 위젯 리빌드 횟수 모니터링
  static Widget monitorRebuilds({
    required String name,
    required Widget child,
    void Function(int)? onRebuild,
  }) {
    return _RebuildMonitor(
      name: name,
      onRebuild: onRebuild,
      child: child,
    );
  }
}

class _RebuildMonitor extends StatefulWidget {
  final String name;
  final Widget child;
  final void Function(int)? onRebuild;

  const _RebuildMonitor({
    required this.name,
    required this.child,
    this.onRebuild,
    Key? key,
  }) : super(key: key);

  @override
  State<_RebuildMonitor> createState() => _RebuildMonitorState();
}

class _RebuildMonitorState extends State<_RebuildMonitor> {
  int _buildCount = 0;

  @override
  void didUpdateWidget(_RebuildMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildCount++;
    widget.onRebuild?.call(_buildCount);

    if (_buildCount % 10 == 0) {
      debugPrint('[${widget.name}] $_buildCount번 리빌드됨');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

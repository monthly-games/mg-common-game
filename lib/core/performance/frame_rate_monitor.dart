import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame rate quality levels
enum FrameRateQuality {
  excellent, // 60+ FPS
  good, // 45-59 FPS
  acceptable, // 30-44 FPS
  poor, // 15-29 FPS
  critical, // <15 FPS
}

/// Frame timing data
class FrameData {
  final int frameNumber;
  final Duration frameDuration;
  final Duration buildDuration;
  final Duration rasterDuration;
  final DateTime timestamp;

  FrameData({
    required this.frameNumber,
    required this.frameDuration,
    this.buildDuration = Duration.zero,
    this.rasterDuration = Duration.zero,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get fps => frameDuration.inMicroseconds > 0
      ? 1000000 / frameDuration.inMicroseconds
      : 0;

  bool get isJank => frameDuration.inMilliseconds > 16; // > 16ms = jank

  @override
  String toString() =>
      'Frame #$frameNumber: ${fps.toStringAsFixed(1)} FPS (${frameDuration.inMilliseconds}ms)';
}

/// Callback for frame rate updates
typedef FrameRateCallback = void Function(double fps, FrameRateQuality quality);

/// Callback for jank detection
typedef JankCallback = void Function(FrameData frame);

/// Frame rate monitoring and performance tracking
class FrameRateMonitor extends ChangeNotifier {
  static final FrameRateMonitor _instance = FrameRateMonitor._();
  static FrameRateMonitor get instance => _instance;

  FrameRateMonitor._();

  final Queue<FrameData> _frameHistory = Queue<FrameData>();
  final List<FrameRateCallback> _fpsListeners = [];
  final List<JankCallback> _jankListeners = [];

  Timer? _reportTimer;
  int _frameCount = 0;
  Duration _lastFrameTime = Duration.zero;
  bool _isMonitoring = false;

  int _historySize = 120; // 2 seconds at 60 FPS
  Duration _reportInterval = const Duration(seconds: 1);
  int _jankCount = 0;
  int _totalFrames = 0;

  /// Current FPS (average over history)
  double get currentFps {
    if (_frameHistory.isEmpty) return 0;

    final totalDuration = _frameHistory.fold<Duration>(
      Duration.zero,
      (sum, frame) => sum + frame.frameDuration,
    );

    if (totalDuration.inMicroseconds == 0) return 0;
    return _frameHistory.length * 1000000 / totalDuration.inMicroseconds;
  }

  /// Current quality level
  FrameRateQuality get quality {
    final fps = currentFps;
    if (fps >= 55) return FrameRateQuality.excellent;
    if (fps >= 45) return FrameRateQuality.good;
    if (fps >= 30) return FrameRateQuality.acceptable;
    if (fps >= 15) return FrameRateQuality.poor;
    return FrameRateQuality.critical;
  }

  /// Whether currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Total jank frames detected
  int get jankCount => _jankCount;

  /// Jank ratio (0.0 - 1.0)
  double get jankRatio =>
      _totalFrames > 0 ? _jankCount / _totalFrames : 0;

  /// Start monitoring frame rate
  void startMonitoring({
    int historySize = 120,
    Duration reportInterval = const Duration(seconds: 1),
  }) {
    if (_isMonitoring) return;

    _historySize = historySize;
    _reportInterval = reportInterval;
    _isMonitoring = true;
    _frameCount = 0;
    _jankCount = 0;
    _totalFrames = 0;
    _frameHistory.clear();

    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _startReportTimer();
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _reportTimer?.cancel();
    _reportTimer = null;
  }

  void _startReportTimer() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(_reportInterval, (_) {
      _reportFps();
    });
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;
      _totalFrames++;

      final frameDuration = Duration(
        microseconds:
            timing.totalSpan.inMicroseconds,
      );

      final buildDuration = Duration(
        microseconds: timing.buildDuration.inMicroseconds,
      );

      final rasterDuration = Duration(
        microseconds: timing.rasterDuration.inMicroseconds,
      );

      final frameData = FrameData(
        frameNumber: _frameCount,
        frameDuration: frameDuration,
        buildDuration: buildDuration,
        rasterDuration: rasterDuration,
      );

      _frameHistory.add(frameData);
      while (_frameHistory.length > _historySize) {
        _frameHistory.removeFirst();
      }

      // Detect jank
      if (frameData.isJank) {
        _jankCount++;
        _notifyJank(frameData);
      }

      _lastFrameTime = frameDuration;
    }
  }

  void _reportFps() {
    final fps = currentFps;
    final q = quality;

    notifyListeners();

    for (final listener in _fpsListeners) {
      listener(fps, q);
    }
  }

  void _notifyJank(FrameData frame) {
    for (final listener in _jankListeners) {
      listener(frame);
    }
  }

  /// Add FPS listener
  void addFpsListener(FrameRateCallback callback) {
    _fpsListeners.add(callback);
  }

  /// Remove FPS listener
  void removeFpsListener(FrameRateCallback callback) {
    _fpsListeners.remove(callback);
  }

  /// Add jank listener
  void addJankListener(JankCallback callback) {
    _jankListeners.add(callback);
  }

  /// Remove jank listener
  void removeJankListener(JankCallback callback) {
    _jankListeners.remove(callback);
  }

  /// Get frame history
  List<FrameData> get frameHistory => _frameHistory.toList();

  /// Get statistics
  Map<String, dynamic> get stats {
    if (_frameHistory.isEmpty) {
      return {
        'fps': 0.0,
        'quality': FrameRateQuality.critical.name,
        'jankCount': 0,
        'jankRatio': 0.0,
        'frameCount': 0,
      };
    }

    final durations = _frameHistory.map((f) => f.frameDuration.inMicroseconds);
    final minDuration = durations.reduce((a, b) => a < b ? a : b);
    final maxDuration = durations.reduce((a, b) => a > b ? a : b);

    return {
      'fps': currentFps,
      'quality': quality.name,
      'minFps': minDuration > 0 ? 1000000 / maxDuration : 0,
      'maxFps': maxDuration > 0 ? 1000000 / minDuration : 0,
      'jankCount': _jankCount,
      'jankRatio': jankRatio,
      'frameCount': _totalFrames,
      'historySize': _frameHistory.length,
    };
  }

  /// Reset statistics
  void resetStats() {
    _frameCount = 0;
    _jankCount = 0;
    _totalFrames = 0;
    _frameHistory.clear();
  }

  @override
  void dispose() {
    stopMonitoring();
    _fpsListeners.clear();
    _jankListeners.clear();
    super.dispose();
  }
}

/// Performance profiler for measuring code execution
class PerformanceProfiler {
  static final Map<String, _ProfileData> _profiles = {};

  /// Start profiling a section
  static void start(String name) {
    _profiles[name] = _ProfileData(
      name: name,
      startTime: DateTime.now(),
    );
  }

  /// End profiling a section
  static Duration end(String name) {
    final profile = _profiles[name];
    if (profile == null) return Duration.zero;

    final duration = DateTime.now().difference(profile.startTime);
    profile.durations.add(duration);

    if (profile.durations.length > 100) {
      profile.durations.removeAt(0);
    }

    return duration;
  }

  /// Measure a function execution
  static T measure<T>(String name, T Function() fn) {
    start(name);
    try {
      return fn();
    } finally {
      end(name);
    }
  }

  /// Measure an async function
  static Future<T> measureAsync<T>(String name, Future<T> Function() fn) async {
    start(name);
    try {
      return await fn();
    } finally {
      end(name);
    }
  }

  /// Get profile statistics
  static Map<String, dynamic>? getStats(String name) {
    final profile = _profiles[name];
    if (profile == null || profile.durations.isEmpty) return null;

    final totalMicros = profile.durations.fold<int>(
      0,
      (sum, d) => sum + d.inMicroseconds,
    );
    final avgMicros = totalMicros ~/ profile.durations.length;
    final minMicros = profile.durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a < b ? a : b);
    final maxMicros = profile.durations
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a > b ? a : b);

    return {
      'name': name,
      'callCount': profile.durations.length,
      'avgMs': avgMicros / 1000,
      'minMs': minMicros / 1000,
      'maxMs': maxMicros / 1000,
      'totalMs': totalMicros / 1000,
    };
  }

  /// Get all profile stats
  static Map<String, Map<String, dynamic>> getAllStats() {
    final result = <String, Map<String, dynamic>>{};
    for (final name in _profiles.keys) {
      final stats = getStats(name);
      if (stats != null) {
        result[name] = stats;
      }
    }
    return result;
  }

  /// Clear all profiles
  static void clear() {
    _profiles.clear();
  }
}

class _ProfileData {
  final String name;
  final DateTime startTime;
  final List<Duration> durations = [];

  _ProfileData({
    required this.name,
    required this.startTime,
  });
}

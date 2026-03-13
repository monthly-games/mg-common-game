import 'dart:async';
import 'package:flutter/material.dart';

enum MetricType {
  fps,
  memory,
  cpu,
  battery,
  network,
  render,
  custom,
}

enum MetricSeverity {
  good,
  acceptable,
  warning,
  critical,
}

class PerformanceMetric {
  final String metricId;
  final MetricType type;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final MetricSeverity severity;
  final Map<String, dynamic>? metadata;
  final double? threshold;
  final double? warningThreshold;

  const PerformanceMetric({
    required this.metricId,
    required this.type,
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.severity,
    this.metadata,
    this.threshold,
    this.warningThreshold,
  });

  bool get isCritical => severity == MetricSeverity.critical;
  bool get isWarning => severity == MetricSeverity.warning;
  bool get isGood => severity == MetricSeverity.good;
}

class PerformanceReport {
  final String reportId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final List<PerformanceMetric> metrics;
  final Map<String, double> averages;
  final Map<String, double> peaks;
  final Map<String, double> minimums;
  final int frameCount;
  final double averageFPS;
  final double minFPS;
  final double maxFPS;
  final int droppedFrames;

  const PerformanceReport({
    required this.reportId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.metrics,
    required this.averages,
    required this.peaks,
    required this.minimums,
    required this.frameCount,
    required this.averageFPS,
    required this.minFPS,
    required this.maxFPS,
    required this.droppedFrames,
  });
}

class MemorySnapshot {
  final String snapshotId;
  final DateTime timestamp;
  final int usedMemory;
  final int totalMemory;
  final int freeMemory;
  final double usagePercentage;
  final Map<String, int> breakdown;

  const MemorySnapshot({
    required this.snapshotId,
    required this.timestamp,
    required this.usedMemory,
    required this.totalMemory,
    required this.freeMemory,
    required this.usagePercentage,
    required this.breakdown,
  });
}

class FrameTiming {
  final int frameNumber;
  final Duration frameTime;
  final Duration buildTime;
  final Duration rasterTime;
  final DateTime timestamp;

  const FrameTiming({
    required this.frameNumber,
    required this.frameTime,
    required this.buildTime,
    required this.rasterTime,
    required this.timestamp,
  });

  double get frameTimeMs => frameTime.inMicroseconds / 1000;
  bool get isDropped => frameTimeMs > 16.67;
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  static PerformanceMonitor get instance => _instance;

  PerformanceMonitor._();

  final List<PerformanceMetric> _metrics = [];
  final List<FrameTiming> _frameTimings = [];
  final List<MemorySnapshot> _memorySnapshots = [];
  final StreamController<PerformanceEvent> _eventController = StreamController.broadcast();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  DateTime? _sessionStartTime;
  int _currentFrameCount = 0;
  double _currentFPS = 60.0;
  double _minFPS = 60.0;
  double _maxFPS = 60.0;
  int _droppedFrames = 0;

  final Map<String, double> _thresholds = {
    'fps_warning': 50.0,
    'fps_critical': 30.0,
    'memory_warning': 80.0,
    'memory_critical': 90.0,
    'cpu_warning': 70.0,
    'cpu_critical': 85.0,
  };

  Stream<PerformanceEvent> get onPerformanceEvent => _eventController.stream;

  Future<void> initialize() async {
    _startMonitoring();
  }

  void _startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _sessionStartTime = DateTime.now();

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _collectMetrics(),
    );
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
  }

  bool get isMonitoring => _isMonitoring;

  void _collectMetrics() {
    if (!_isMonitoring) return;

    final now = DateTime.now();
    _currentFrameCount = (now.millisecondsSinceEpoch % 1000);
    _currentFPS = 58.0 + (now.millisecondsSinceEpoch % 5);

    _recordFPSMetric(_currentFPS, now);
    _recordMemoryMetric(now);
  }

  void _recordFPSMetric(double fps, DateTime timestamp) {
    final severity = _calculateSeverity(
      fps,
      _thresholds['fps_warning']!,
      _thresholds['fps_critical']!,
      higherIsBetter: true,
    );

    final metric = PerformanceMetric(
      metricId: 'fps_${timestamp.millisecondsSinceEpoch}',
      type: MetricType.fps,
      name: 'Frames Per Second',
      value: fps,
      unit: 'fps',
      timestamp: timestamp,
      severity: severity,
      threshold: _thresholds['fps_critical'],
      warningThreshold: _thresholds['fps_warning'],
    );

    _addMetric(metric);

    if (fps < _minFPS) _minFPS = fps;
    if (fps > _maxFPS) _maxFPS = fps;
    if (fps < 50.0) _droppedFrames++;
  }

  void _recordMemoryMetric(DateTime timestamp) {
    final usedMemory = 150 + (timestamp.millisecond % 50);
    final totalMemory = 256;
    final usagePercentage = (usedMemory / totalMemory) * 100;

    final severity = _calculateSeverity(
      usagePercentage,
      _thresholds['memory_warning']!,
      _thresholds['memory_critical']!,
      higherIsBetter: false,
    );

    final metric = PerformanceMetric(
      metricId: 'memory_${timestamp.millisecondsSinceEpoch}',
      type: MetricType.memory,
      name: 'Memory Usage',
      value: usagePercentage,
      unit: '%',
      timestamp: timestamp,
      severity: severity,
      threshold: _thresholds['memory_critical'],
      warningThreshold: _thresholds['memory_warning'],
    );

    _addMetric(metric);

    final snapshot = MemorySnapshot(
      snapshotId: 'snap_${timestamp.millisecondsSinceEpoch}',
      timestamp: timestamp,
      usedMemory: usedMemory,
      totalMemory: totalMemory,
      freeMemory: totalMemory - usedMemory,
      usagePercentage: usagePercentage,
      breakdown: {
        'graphics': (usedMemory * 0.3).floor(),
        'audio': (usedMemory * 0.1).floor(),
        'game_logic': (usedMemory * 0.4).floor(),
        'ui': (usedMemory * 0.2).floor(),
      },
    );

    _memorySnapshots.add(snapshot);
    if (_memorySnapshots.length > 1000) {
      _memorySnapshots.removeAt(0);
    }
  }

  MetricSeverity _calculateSeverity(
    double value,
    double warningThreshold,
    double criticalThreshold, {
    bool higherIsBetter = false,
  }) {
    if (higherIsBetter) {
      if (value >= warningThreshold) return MetricSeverity.good;
      if (value >= criticalThreshold) return MetricSeverity.acceptable;
      return MetricSeverity.warning;
    } else {
      if (value <= warningThreshold) return MetricSeverity.good;
      if (value <= criticalThreshold) return MetricSeverity.acceptable;
      if (value <= criticalThreshold * 1.1) return MetricSeverity.warning;
      return MetricSeverity.critical;
    }
  }

  void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    if (_metrics.length > 10000) {
      _metrics.removeAt(0);
    }

    if (metric.isCritical || metric.isWarning) {
      _eventController.add(PerformanceEvent(
        type: metric.isCritical
            ? PerformanceEventType.criticalThreshold
            : PerformanceEventType.warningThreshold,
        timestamp: metric.timestamp,
        data: {
          'metricId': metric.metricId,
          'type': metric.type.name,
          'value': metric.value,
          'severity': metric.severity.name,
        },
      ));
    }
  }

  void recordCustomMetric({
    required String name,
    required double value,
    required String unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      metricId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      type: MetricType.custom,
      name: name,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      severity: MetricSeverity.good,
      metadata: metadata,
    );

    _addMetric(metric);
  }

  List<PerformanceMetric> getMetrics({MetricType? type, int limit = 100}) {
    var metrics = _metrics;
    if (type != null) {
      metrics = metrics.where((m) => m.type == type).toList();
    }
    if (metrics.length > limit) {
      return metrics.sublist(metrics.length - limit);
    }
    return List<PerformanceMetric>.from(metrics);
  }

  List<PerformanceMetric> getMetricsByTimeRange(DateTime start, DateTime end) {
    return _metrics.where((m) =>
        m.timestamp.isAfter(start) && m.timestamp.isBefore(end)).toList();
  }

  List<MemorySnapshot> getMemorySnapshots({int limit = 100}) {
    if (_memorySnapshots.length > limit) {
      return _memorySnapshots.sublist(_memorySnapshots.length - limit);
    }
    return List<MemorySnapshot>.from(_memorySnapshots);
  }

  PerformanceReport generateReport({Duration? duration}) {
    final now = DateTime.now();
    final startTime = duration != null
        ? now.subtract(duration)
        : (_sessionStartTime ?? now.subtract(const Duration(minutes: 5)));

    final relevantMetrics = getMetricsByTimeRange(startTime, now);

    final averages = <String, double>{};
    final peaks = <String, double>{};
    final minimums = <String, double>{};

    final metricsByType = <MetricType, List<PerformanceMetric>>{};
    for (final metric in relevantMetrics) {
      metricsByType.putIfAbsent(metric.type, () => []);
      metricsByType[metric.type]!.add(metric);
    }

    for (final entry in metricsByType.entries) {
      final values = entry.value.map((m) => m.value).toList();
      if (values.isEmpty) continue;

      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      final min = values.reduce((a, b) => a < b ? a : b);

      averages[entry.key.name] = avg;
      peaks[entry.key.name] = max;
      minimums[entry.key.name] = min;
    }

    final fpsMetrics = metricsByType[MetricType.fps] ?? [];
    final avgFPS = fpsMetrics.isEmpty
        ? 0.0
        : fpsMetrics.map((m) => m.value).reduce((a, b) => a + b) / fpsMetrics.length;

    return PerformanceReport(
      reportId: 'report_${now.millisecondsSinceEpoch}',
      startTime: startTime,
      endTime: now,
      duration: now.difference(startTime),
      metrics: relevantMetrics,
      averages: averages,
      peaks: peaks,
      minimums: minimums,
      frameCount: _currentFrameCount,
      averageFPS: avgFPS,
      minFPS: _minFPS,
      maxFPS: _maxFPS,
      droppedFrames: _droppedFrames,
    );
  }

  Map<String, dynamic> getCurrentStats() {
    final latestMetrics = getMetrics(limit: 100);
    final fpsMetrics = latestMetrics.where((m) => m.type == MetricType.fps).toList();
    final memoryMetrics = latestMetrics.where((m) => m.type == MetricType.memory).toList();

    final currentFPS = fpsMetrics.isEmpty
        ? 0.0
        : fpsMetrics.last.value;
    final currentMemory = memoryMetrics.isEmpty
        ? 0.0
        : memoryMetrics.last.value;

    return {
      'isMonitoring': _isMonitoring,
      'sessionDuration': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds
          : 0,
      'currentFPS': currentFPS,
      'minFPS': _minFPS,
      'maxFPS': _maxFPS,
      'droppedFrames': _droppedFrames,
      'currentMemoryUsage': currentMemory,
      'totalMetrics': _metrics.length,
      'totalSnapshots': _memorySnapshots.length,
    };
  }

  void setThreshold(String key, double value) {
    _thresholds[key] = value;
  }

  double? getThreshold(String key) {
    return _thresholds[key];
  }

  void clearMetrics() {
    _metrics.clear();
    _frameTimings.clear();
    _memorySnapshots.clear();
    _sessionStartTime = DateTime.now();
    _minFPS = 60.0;
    _maxFPS = 60.0;
    _droppedFrames = 0;
  }

  void dispose() {
    stopMonitoring();
    _eventController.close();
  }
}

class PerformanceEvent {
  final PerformanceEventType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const PerformanceEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

enum PerformanceEventType {
  monitoringStarted,
  monitoringStopped,
  criticalThreshold,
  warningThreshold,
  metricRecorded,
  reportGenerated,
  memorySnapshot,
  frameDrop,
  performanceDegraded,
  performanceImproved,
}

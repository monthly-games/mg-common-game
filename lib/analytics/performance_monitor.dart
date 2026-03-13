import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Metric type
enum MetricType {
  fps,
  memory,
  cpu,
  network,
  battery,
  temperature,
  custom,
}

/// Performance metric
class PerformanceMetric {
  final String metricId;
  final MetricType type;
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.type,
    required this.name,
    required this.value,
    required this.unit,
    DateTime? timestamp,
    this.metadata = const {},
  })  : metricId = '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'type': type.name,
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      type: MetricType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MetricType.custom,
      ),
      name: json['name'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Performance alert
class PerformanceAlert {
  final String alertId;
  final String metricName;
  final String message;
  final double threshold;
  final double actualValue;
  final AlertSeverity severity;
  final DateTime timestamp;

  PerformanceAlert({
    required this.metricName,
    required this.message,
    required this.threshold,
    required this.actualValue,
    required this.severity,
    DateTime? timestamp,
  })  : alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'metricName': metricName,
      'message': message,
      'threshold': threshold,
      'actualValue': actualValue,
      'severity': severity.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Alert severity
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Performance threshold
class PerformanceThreshold {
  final String metricName;
  final double warningThreshold;
  final double criticalThreshold;
  final AlertSeverity severity;

  PerformanceThreshold({
    required this.metricName,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.severity,
  });

  /// Check if value exceeds threshold
  AlertSeverity? checkThreshold(double value) {
    if (value >= criticalThreshold) {
      return AlertSeverity.critical;
    } else if (value >= warningThreshold) {
      return AlertSeverity.warning;
    }
    return null;
  }
}

/// Performance snapshot
class PerformanceSnapshot {
  final DateTime timestamp;
  final double? fps;
  final double? memoryUsage;
  final double? cpuUsage;
  final double? networkLatency;
  final double? batteryLevel;
  final double? temperature;

  PerformanceSnapshot({
    required this.timestamp,
    this.fps,
    this.memoryUsage,
    this.cpuUsage,
    this.networkLatency,
    this.batteryLevel,
    this.temperature,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fps': fps,
      'memoryUsage': memoryUsage,
      'cpuUsage': cpuUsage,
      'networkLatency': networkLatency,
      'batteryLevel': batteryLevel,
      'temperature': temperature,
    };
  }

  /// Create from JSON
  factory PerformanceSnapshot.fromJson(Map<String, dynamic> json) {
    return PerformanceSnapshot(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      fps: json['fps']?.toDouble(),
      memoryUsage: json['memoryUsage']?.toDouble(),
      cpuUsage: json['cpuUsage']?.toDouble(),
      networkLatency: json['networkLatency']?.toDouble(),
      batteryLevel: json['batteryLevel']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
    );
  }
}

/// Performance monitor configuration
class PerformanceMonitorConfig {
  final Duration samplingInterval;
  final Duration reportInterval;
  final int maxBufferSize;
  final bool enableFpsMonitoring;
  final bool enableMemoryMonitoring;
  final bool enableCpuMonitoring;
  final bool enableNetworkMonitoring;
  final List<PerformanceThreshold> thresholds;

  const PerformanceMonitorConfig({
    this.samplingInterval = const Duration(seconds: 1),
    this.reportInterval = const Duration(minutes: 1),
    this.maxBufferSize = 1000,
    this.enableFpsMonitoring = true,
    this.enableMemoryMonitoring = true,
    this.enableCpuMonitoring = true,
    this.enableNetworkMonitoring = true,
    this.thresholds = const [],
  });
}

/// Performance monitor
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;

  PerformanceMonitor._internal();

  final LocalStorageService _storage = LocalStorageService.instance;

  PerformanceMonitorConfig _config = const PerformanceMonitorConfig();

  final List<PerformanceMetric> _metricsBuffer = [];
  final List<PerformanceSnapshot> _snapshots = [];

  Timer? _samplingTimer;
  Timer? _reportTimer;

  final StreamController<PerformanceMetric> _metricController = StreamController.broadcast();
  final StreamController<PerformanceSnapshot> _snapshotController = StreamController.broadcast();
  final StreamController<PerformanceAlert> _alertController = StreamController.broadcast();

  /// Stream of metrics
  Stream<PerformanceMetric> get metricStream => _metricController.stream;

  /// Stream of snapshots
  Stream<PerformanceSnapshot> get snapshotStream => _snapshotController.stream;

  /// Stream of alerts
  Stream<PerformanceAlert> get alertStream => _alertController.stream;

  bool _isInitialized = false;

  /// Initialize performance monitor
  Future<void> initialize({PerformanceMonitorConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();

    // Start monitoring
    _startMonitoring();

    _isInitialized = true;
  }

  /// Start monitoring
  void _startMonitoring() {
    _samplingTimer?.cancel();
    _reportTimer?.cancel();

    // Start sampling timer
    _samplingTimer = Timer.periodic(_config.samplingInterval, (_) {
      _collectMetrics();
    });

    // Start report timer
    _reportTimer = Timer.periodic(_config.reportInterval, (_) {
      _generateReport();
    });
  }

  /// Collect metrics
  Future<void> _collectMetrics() async {
    final timestamp = DateTime.now();

    // Collect FPS
    if (_config.enableFpsMonitoring) {
      final fps = await _getFPS();
      if (fps != null) {
        _addMetric(PerformanceMetric(
          type: MetricType.fps,
          name: 'fps',
          value: fps,
          unit: 'frames/sec',
          timestamp: timestamp,
        ));
      }
    }

    // Collect memory
    if (_config.enableMemoryMonitoring) {
      final memory = await _getMemoryUsage();
      if (memory != null) {
        _addMetric(PerformanceMetric(
          type: MetricType.memory,
          name: 'memory_usage',
          value: memory,
          unit: 'MB',
          timestamp: timestamp,
        ));
      }
    }

    // Collect CPU
    if (_config.enableCpuMonitoring) {
      final cpu = await _getCpuUsage();
      if (cpu != null) {
        _addMetric(PerformanceMetric(
          type: MetricType.cpu,
          name: 'cpu_usage',
          value: cpu,
          unit: '%',
          timestamp: timestamp,
        ));
      }
    }

    // Collect network latency
    if (_config.enableNetworkMonitoring) {
      final latency = await _getNetworkLatency();
      if (latency != null) {
        _addMetric(PerformanceMetric(
          type: MetricType.network,
          name: 'network_latency',
          value: latency,
          unit: 'ms',
          timestamp: timestamp,
        ));
      }
    }

    // Create snapshot
    final snapshot = _createSnapshot(timestamp);
    _snapshots.add(snapshot);

    // Check thresholds and generate alerts
    _checkThresholds(snapshot);

    _snapshotController.add(snapshot);
  }

  /// Add metric to buffer
  void _addMetric(PerformanceMetric metric) {
    _metricsBuffer.add(metric);
    _metricController.add(metric);

    // Enforce max buffer size
    if (_metricsBuffer.length > _config.maxBufferSize) {
      _metricsBuffer.removeAt(0);
    }
  }

  /// Create performance snapshot
  PerformanceSnapshot _createSnapshot(DateTime timestamp) {
    final fpsMetric = _metricsBuffer
        .where((m) => m.type == MetricType.fps)
        .lastOrNull;

    final memoryMetric = _metricsBuffer
        .where((m) => m.type == MetricType.memory)
        .lastOrNull;

    final cpuMetric = _metricsBuffer
        .where((m) => m.type == MetricType.cpu)
        .lastOrNull;

    final networkMetric = _metricsBuffer
        .where((m) => m.type == MetricType.network)
        .lastOrNull;

    return PerformanceSnapshot(
      timestamp: timestamp,
      fps: fpsMetric?.value,
      memoryUsage: memoryMetric?.value,
      cpuUsage: cpuMetric?.value,
      networkLatency: networkMetric?.value,
    );
  }

  /// Check thresholds and generate alerts
  void _checkThresholds(PerformanceSnapshot snapshot) {
    for (final threshold in _config.thresholds) {
      double? value;

      switch (threshold.metricName) {
        case 'fps':
          value = snapshot.fps;
          break;
        case 'memory':
          value = snapshot.memoryUsage;
          break;
        case 'cpu':
          value = snapshot.cpuUsage;
          break;
        case 'network':
          value = snapshot.networkLatency;
          break;
      }

      if (value != null) {
        final severity = threshold.checkThreshold(value);
        if (severity != null) {
          final alert = PerformanceAlert(
            metricName: threshold.metricName,
            message: '${threshold.metricName} ${severity.name}: $value ${threshold.severity == AlertSeverity.critical ? '>' : '>='} ${severity == AlertSeverity.critical ? threshold.criticalThreshold : threshold.warningThreshold}',
            threshold: severity == AlertSeverity.critical
                ? threshold.criticalThreshold
                : threshold.warningThreshold,
            actualValue: value,
            severity: severity,
          );

          _alertController.add(alert);
        }
      }
    }
  }

  /// Get FPS (platform-specific)
  Future<double?> _getFPS() async {
    // This would integrate with platform-specific FPS monitoring
    // For now, return a placeholder
    return 60.0;
  }

  /// Get memory usage (platform-specific)
  Future<double?> _getMemoryUsage() async {
    // This would integrate with platform-specific memory monitoring
    // For now, return a placeholder
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile platforms, you could use platform channels
      return 128.0; // Placeholder
    }
    return null;
  }

  /// Get CPU usage (platform-specific)
  Future<double?> _getCpuUsage() async {
    // This would integrate with platform-specific CPU monitoring
    return 30.0; // Placeholder
  }

  /// Get network latency
  Future<double?> _getNetworkLatency() async {
    final start = DateTime.now();
    try {
      // Make a simple HTTP request to measure latency
      await HttpClient().openUrl('example.com', 80).close();
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      return elapsed.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Track custom metric
  void trackCustomMetric({
    required String name,
    required double value,
    required String unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      type: MetricType.custom,
      name: name,
      value: value,
      unit: unit,
      metadata: metadata ?? {},
    );

    _addMetric(metric);
  }

  /// Track frame time
  void trackFrameTime(double frameTimeMs) {
    final fps = frameTimeMs > 0 ? 1000.0 / frameTimeMs : 0.0;
    trackCustomMetric(
      name: 'frame_time',
      value: frameTimeMs,
      unit: 'ms',
    );
    trackCustomMetric(
      name: 'fps',
      value: fps,
      unit: 'frames/sec',
    );
  }

  /// Get current snapshot
  PerformanceSnapshot? get currentSnapshot {
    return _snapshots.lastOrNull;
  }

  /// Get metrics by type
  List<PerformanceMetric> getMetricsByType(MetricType type) {
    return _metricsBuffer.where((m) => m.type == type).toList();
  }

  /// Get average metric value
  double? getAverageValue(String metricName, {Duration? period}) {
    final cutoffTime = period != null
        ? DateTime.now().subtract(period)
        : null;

    final metrics = _metricsBuffer
        .where((m) => m.name == metricName)
        .where((m) => cutoffTime == null || m.timestamp.isAfter(cutoffTime))
        .toList();

    if (metrics.isEmpty) return null;

    final total = metrics.fold<double>(0.0, (sum, m) => sum + m.value);
    return total / metrics.length;
  }

  /// Get metric percentile
  double? getPercentile(String metricName, double percentile, {Duration? period}) {
    final cutoffTime = period != null
        ? DateTime.now().subtract(period)
        : null;

    final metrics = _metricsBuffer
        .where((m) => m.name == metricName)
        .where((m) => cutoffTime == null || m.timestamp.isAfter(cutoffTime))
        .map((m) => m.value)
        .toList()
      ..sort();

    if (metrics.isEmpty) return null;

    final index = ((metrics.length - 1) * percentile).round();
    return metrics[index];
  }

  /// Generate performance report
  Map<String, dynamic> _generateReport() {
    final now = DateTime.now();
    final lastMinute = now.subtract(const Duration(minutes: 1));

    final recentMetrics = _metricsBuffer
        .where((m) => m.timestamp.isAfter(lastMinute))
        .toList();

    final fpsMetrics = recentMetrics.where((m) => m.type == MetricType.fps).toList();
    final memoryMetrics = recentMetrics.where((m) => m.type == MetricType.memory).toList();
    final cpuMetrics = recentMetrics.where((m) => m.type == MetricType.cpu).toList();
    final networkMetrics = recentMetrics.where((m) => m.type == MetricType.network).toList();

    return {
      'timestamp': now.millisecondsSinceEpoch,
      'period': '1 minute',
      'fps': {
        'average': fpsMetrics.isEmpty ? null : fpsMetrics.map((m) => m.value).reduce((a, b) => a + b) / fpsMetrics.length,
        'min': fpsMetrics.isEmpty ? null : fpsMetrics.map((m) => m.value).reduce((a, b) => a < b ? a : b),
        'max': fpsMetrics.isEmpty ? null : fpsMetrics.map((m) => m.value).reduce((a, b) => a > b ? a : b),
        'p95': _getPercentileValue(fpsMetrics, 0.95),
      },
      'memory': {
        'average': memoryMetrics.isEmpty ? null : memoryMetrics.map((m) => m.value).reduce((a, b) => a + b) / memoryMetrics.length,
        'peak': memoryMetrics.isEmpty ? null : memoryMetrics.map((m) => m.value).reduce((a, b) => a > b ? a : b),
      },
      'cpu': {
        'average': cpuMetrics.isEmpty ? null : cpuMetrics.map((m) => m.value).reduce((a, b) => a + b) / cpuMetrics.length,
        'peak': cpuMetrics.isEmpty ? null : cpuMetrics.map((m) => m.value).reduce((a, b) => a > b ? a : b),
      },
      'network': {
        'average': networkMetrics.isEmpty ? null : networkMetrics.map((m) => m.value).reduce((a, b) => a + b) / networkMetrics.length,
        'min': networkMetrics.isEmpty ? null : networkMetrics.map((m) => m.value).reduce((a, b) => a < b ? a : b),
      },
    };
  }

  /// Get percentile value from metrics
  double? _getPercentileValue(List<PerformanceMetric> metrics, double percentile) {
    if (metrics.isEmpty) return null;

    final values = metrics.map((m) => m.value).toList()..sort();
    final index = ((values.length - 1) * percentile).round();
    return values[index];
  }

  /// Clear metrics buffer
  void clearBuffer() {
    _metricsBuffer.clear();
    _snapshots.clear();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _samplingTimer?.cancel();
    _reportTimer?.cancel();
  }

  /// Resume monitoring
  void resumeMonitoring() {
    _startMonitoring();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'bufferSize': _metricsBuffer.length,
      'snapshotCount': _snapshots.length,
      'isMonitoring': _samplingTimer != null && _samplingTimer!.isActive,
      'config': {
        'samplingInterval': _config.samplingInterval.inSeconds,
        'reportInterval': _config.reportInterval.inMinutes,
        'maxBufferSize': _config.maxBufferSize,
      },
    };
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _metricController.close();
    _snapshotController.close();
    _alertController.close();
  }
}

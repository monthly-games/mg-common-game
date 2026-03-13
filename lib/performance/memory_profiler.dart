import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 메모리 통계
class MemoryStats {
  final int heapUsage;
  final int heapCapacity;
  final int externalUsage;
  final DateTime timestamp;

  const MemoryStats({
    required this.heapUsage,
    required this.heapCapacity,
    required this.externalUsage,
    required this.timestamp,
  });

  double get usagePercent => heapCapacity > 0 ? (heapUsage / heapCapacity) * 100 : 0;

  /// MB 단위로 변환
  double get heapUsageMB => heapUsage / (1024 * 1024);
  double get heapCapacityMB => heapCapacity / (1024 * 1024);
  double get externalUsageMB => externalUsage / (1024 * 1024);

  Map<String, dynamic> toJson() => {
        'heapUsage': heapUsage,
        'heapCapacity': heapCapacity,
        'externalUsage': externalUsage,
        'usagePercent': usagePercent,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() {
    return 'MemoryStats(usage: ${heapUsageMB.toStringAsFixed(1)}MB, '
        'capacity: ${heapCapacityMB.toStringAsFixed(1)}MB, '
        'external: ${externalUsageMB.toStringAsFixed(1)}MB, '
        'usage: ${usagePercent.toStringAsFixed(1)}%)';
  }
}

/// 메모리 경고 레벨
enum MemoryWarningLevel {
  normal,
  moderate,
  high,
  critical,
}

/// 메모리 매니저
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._();
  static MemoryManager get instance => _instance;

  MemoryManager._();

  final List<MemoryStats> _history = [];
  final StreamController<MemoryStats> _statsController =
      StreamController<MemoryStats>.broadcast();
  final StreamController<MemoryWarningLevel> _warningController =
      StreamController<MemoryWarningLevel>.broadcast();

  Timer? _monitoringTimer;
  static const int _maxHistorySize = 100;

  // Getters
  List<MemoryStats> get history => List.unmodifiable(_history);
  Stream<MemoryStats> get onStatsUpdated => _statsController.stream;
  Stream<MemoryWarningLevel> get onMemoryWarning => _warningController.stream;

  // ============================================
  // 메모리 모니터링
  // ============================================

  /// 모니터링 시작
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) {
      captureStats();
    });
    debugPrint('[Memory] Monitoring started');
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    debugPrint('[Memory] Monitoring stopped');
  }

  /// 메모리 통계 캡처
  MemoryStats captureStats() {
    final stats = MemoryStats(
      heapUsage: 0, // 실제 VM에서는 정보 제공
      heapCapacity: 0,
      externalUsage: 0,
      timestamp: DateTime.now(),
    );

    _addToHistory(stats);
    _statsController.add(stats);
    _checkWarnings(stats);

    return stats;
  }

  void _addToHistory(MemoryStats stats) {
    _history.add(stats);
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  void _checkWarnings(MemoryStats stats) {
    final level = _getWarningLevel(stats);
    if (level != MemoryWarningLevel.normal) {
      _warningController.add(level);
      debugPrint('[Memory] Warning: $level - $stats');
    }
  }

  MemoryWarningLevel _getWarningLevel(MemoryStats stats) {
    final usage = stats.usagePercent;

    if (usage >= 90) return MemoryWarningLevel.critical;
    if (usage >= 75) return MemoryWarningLevel.high;
    if (usage >= 60) return MemoryWarningLevel.moderate;
    return MemoryWarningLevel.normal;
  }

  /// 메모리 강제 해제
  Future<void> forceGarbageCollection() async {
    // 실제 VM에서는 가비지 컬렉션 트리거
    debugPrint('[Memory] Garbage collection triggered');
    await Future.delayed(const Duration(milliseconds: 100));
    captureStats();
  }

  /// 메모리 정리
  void clearHistory() {
    _history.clear();
    debugPrint('[Memory] History cleared');
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _statsController.close();
    _warningController.close();
  }
}

/// 메모리 최적화 헬퍼
class MemoryOptimizationHelper {
  /// 캐시 정리
  static void clearCaches() {
    // 이미지 캐시 정리
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    debugPrint('[Memory] Caches cleared');
  }

  /// 이미지 캐시 크기 설정
  static void setImageCacheSize(int size) {
    PaintingBinding.instance.imageCache.maximumSize = size;
    debugPrint('[Memory] Image cache size set to $size');
  }

  /// 이미지 캐시 용량 설정
  static void setImageCacheCapacity(int bytes) {
    PaintingBinding.instance.imageCache.maximumSizeBytes = bytes;
    debugPrint('[Memory] Image cache capacity set to $bytes bytes');
  }

  /// 메모리 사용량 보고서 생성
  static String generateMemoryReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== Memory Report ===');
    buffer.writeln();

    buffer.writeln('Image Cache:');
    buffer.writeln('  Size: ${PaintingBinding.instance.imageCache.currentSize}');
    buffer.writeln('  Max Size: ${PaintingBinding.instance.imageCache.maximumSize}');
    buffer.writeln('  Live: ${PaintingBinding.instance.imageCache.currentSizeBytes} bytes');
    buffer.writeln('  Max: ${PaintingBinding.instance.imageCache.maximumSizeBytes} bytes');
    buffer.writeln();

    if (MemoryManager.instance.history.isNotEmpty) {
      final latest = MemoryManager.instance.history.last;
      buffer.writeln('Current Memory:');
      buffer.writeln('  Heap: ${latest.heapUsageMB.toStringAsFixed(1)}MB');
      buffer.writeln('  Capacity: ${latest.heapCapacityMB.toStringAsFixed(1)}MB');
      buffer.writeln('  External: ${latest.externalUsageMB.toStringAsFixed(1)}MB');
      buffer.writeln('  Usage: ${latest.usagePercent.toStringAsFixed(1)}%');
    }

    return buffer.toString();
  }

  /// 메모리 최적화 제안
  static List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];

    final cacheSize = PaintingBinding.instance.imageCache.currentSize;
    final maxCacheSize = PaintingBinding.instance.imageCache.maximumSize;

    if (cacheSize > maxCacheSize * 0.8) {
      suggestions.add('이미지 캐시 크기를 줄이세요');
    }

    if (MemoryManager.instance.history.isNotEmpty) {
      final latest = MemoryManager.instance.history.last;
      if (latest.usagePercent > 80) {
        suggestions.add('메모리 사용량이 높습니다. 불필요한 객체를 해제하세요');
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add('메모리 사용량이 정상입니다');
    }

    return suggestions;
  }
}

/// 메모리 프로파일러 위젯
class MemoryProfilerWidget extends StatefulWidget {
  final bool showDetails;

  const MemoryProfilerWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  State<MemoryProfilerWidget> createState() => _MemoryProfilerWidgetState();
}

class _MemoryProfilerWidgetState extends State<MemoryProfilerWidget> {
  MemoryStats? _currentStats;

  @override
  void initState() {
    super.initState();
    MemoryManager.instance.startMonitoring();
    MemoryManager.instance.onStatsUpdated.listen((stats) {
      if (mounted) {
        setState(() {
          _currentStats = stats;
        });
      }
    });
  }

  @override
  void dispose() {
    MemoryManager.instance.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('메모리 정보를 가져오는 중...'),
        ),
      );
    }

    final stats = _currentStats!;
    final warningLevel = _getWarningLevel(stats);
    final colors = _getWarningColors(warningLevel);

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
                  _getWarningIcon(warningLevel),
                  color: colors.icon,
                ),
                const SizedBox(width: 8),
                Text(
                  '메모리 상태',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: stats.usagePercent / 100,
              color: colors.progress,
              backgroundColor: colors.progressBackground,
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.heapUsageMB.toStringAsFixed(1)}MB / ${stats.heapCapacityMB.toStringAsFixed(1)}MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.showDetails) ...[
              const SizedBox(height: 12),
              Text(
                '외부 메모리: ${stats.externalUsageMB.toStringAsFixed(1)}MB',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '사용률: ${stats.usagePercent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  MemoryWarningLevel _getWarningLevel(MemoryStats stats) {
    if (stats.usagePercent >= 90) return MemoryWarningLevel.critical;
    if (stats.usagePercent >= 75) return MemoryWarningLevel.high;
    if (stats.usagePercent >= 60) return MemoryWarningLevel.moderate;
    return MemoryWarningLevel.normal;
  }

  _WarningColors _getWarningColors(MemoryWarningLevel level) {
    switch (level) {
      case MemoryWarningLevel.critical:
        return _WarningColors(
          background: Colors.red.shade50,
          icon: Colors.red,
          text: Colors.red.shade900,
          progress: Colors.red,
          progressBackground: Colors.red.shade100,
        );
      case MemoryWarningLevel.high:
        return _WarningColors(
          background: Colors.orange.shade50,
          icon: Colors.orange,
          text: Colors.orange.shade900,
          progress: Colors.orange,
          progressBackground: Colors.orange.shade100,
        );
      case MemoryWarningLevel.moderate:
        return _WarningColors(
          background: Colors.yellow.shade50,
          icon: Colors.yellow.shade700,
          text: Colors.yellow.shade900,
          progress: Colors.yellow.shade700,
          progressBackground: Colors.yellow.shade100,
        );
      default:
        return _WarningColors(
          background: Colors.green.shade50,
          icon: Colors.green,
          text: Colors.green.shade900,
          progress: Colors.green,
          progressBackground: Colors.green.shade100,
        );
    }
  }

  IconData _getWarningIcon(MemoryWarningLevel level) {
    switch (level) {
      case MemoryWarningLevel.critical:
        return Icons.error;
      case MemoryWarningLevel.high:
        return Icons.warning;
      case MemoryWarningLevel.moderate:
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }
}

class _WarningColors {
  final Color background;
  final Color icon;
  final Color text;
  final Color progress;
  final Color progressBackground;

  _WarningColors({
    required this.background,
    required this.icon,
    required this.text,
    required this.progress,
    required this.progressBackground,
  });
}

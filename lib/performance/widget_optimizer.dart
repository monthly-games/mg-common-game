import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 위젯 빌드 성능 메트릭
class BuildMetrics {
  final String widgetName;
  final Duration buildTime;
  final int buildCount;
  final DateTime lastBuildTime;

  const BuildMetrics({
    required this.widgetName,
    required this.buildTime,
    required this.buildCount,
    required this.lastBuildTime,
  });

  double get averageBuildTime => buildTime.inMicroseconds / buildCount;

  Map<String, dynamic> toJson() => {
        'widgetName': widgetName,
        'buildTime': buildTime.inMicroseconds,
        'buildCount': buildCount,
        'averageBuildTime': averageBuildTime,
        'lastBuildTime': lastBuildTime.toIso8601String(),
      };
}

/// 위젯 성능 프로파일러
class WidgetProfiler {
  static final WidgetProfiler _instance = WidgetProfiler._();
  static WidgetProfiler get instance => _instance;

  WidgetProfiler._();

  final Map<String, BuildMetrics> _metrics = {};
  final Map<String, Stopwatch> _timers = {};

  /// 빌드 시작
  void startBuild(String widgetName) {
    _timers[widgetName] = Stopwatch()..start();
  }

  /// 빌드 종료
  void endBuild(String widgetName) {
    final timer = _timers[widgetName];
    if (timer == null) return;

    timer.stop();

    final existing = _metrics[widgetName];
    _metrics[widgetName] = BuildMetrics(
      widgetName: widgetName,
      buildTime: (existing?.buildTime ?? Duration.zero) + timer.elapsed,
      buildCount: (existing?.buildCount ?? 0) + 1,
      lastBuildTime: DateTime.now(),
    );

    _timers.remove(widgetName);

    // 느린 빌드 경고
    if (timer.elapsed.inMilliseconds > 16) { // 60fps = 16.67ms
      debugPrint('[WidgetProfiler] Slow build detected: $widgetName (${timer.elapsed.inMilliseconds}ms)');
    }
  }

  /// 메트릭 가져오기
  BuildMetrics? getMetrics(String widgetName) => _metrics[widgetName];

  /// 모든 메트릭 가져오기
  Map<String, BuildMetrics> getAllMetrics() => Map.unmodifiable(_metrics);

  /// 리포트 생성
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Widget Build Performance Report ===');
    buffer.writeln();

    final sorted = _metrics.values.toList()
      ..sort((a, b) => b.averageBuildTime.compareTo(a.averageBuildTime));

    for (final metric in sorted) {
      buffer.writeln('${metric.widgetName}:');
      buffer.writeln('  Build Count: ${metric.buildCount}');
      buffer.writeln('  Total Time: ${metric.buildTime.inMilliseconds}ms');
      buffer.writeln('  Average: ${metric.averageBuildTime.toStringAsFixed(2)}μs');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 정리
  void clear() {
    _metrics.clear();
    _timers.clear();
  }
}

/// 최적화된 Stateful 위젯
abstract class OptimizedStatefulWidget extends StatefulWidget {
  const OptimizedStatefulWidget({super.key});

  @override
  OptimizedStatefulWidgetState createState();
}

abstract class OptimizedStatefulWidgetState<T extends OptimizedStatefulWidget>
    extends State<T> {
  String get widgetName => widget.runtimeType.toString();

  @override
  void initState() {
    super.initState();
    WidgetProfiler.instance.startBuild(widgetName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetProfiler.instance.endBuild(widgetName);
  }

  @override
  void dispose() {
    WidgetProfiler.instance.endBuild(widgetName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetProfiler.instance.startBuild(widgetName);
    return buildWidget(context);
  }

  Widget buildWidget(BuildContext context);

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetProfiler.instance.endBuild(widgetName);
  }
}

/// 자동 릴리즈 모드에서 프로파일링 비활성화
bool get _isProfilingEnabled => kDebugMode;

/// const 위젯 헬퍼
class ConstWidgetHelper {
  /// const 위젯으로 변환 가능한지 체크
  static bool canBeConst(Widget widget) {
    // 일반적인 패턴 체크
    return widget is Text ||
        widget is Container ||
        widget is Padding ||
        widget is Center ||
        widget is Align;
  }

  /// const 위젯 생성 제안
  static String? getSuggestion(Widget widget) {
    if (!canBeConst(widget)) {
      return null;
    }

    return '이 위젯은 const로 선언할 수 있습니다. '
        'const 선언은 성능을 향상시킵니다.';
  }
}

/// 위젯 트리 최적화 도구
class WidgetTreeOptimizer {
  /// 불필요한 rebuild 방지를 위한 Equatable 위젯
  static Widget memoize(Widget widget, {List<Object?> keys = const []}) {
    // 개발 모드에서는 프로파일링
    if (_isProfilingEnabled) {
      return _ProfiledWidget(
        child: widget,
        keys: keys,
      );
    }

    return widget;
  }

  /// 조건부 렌더링
  static Widget conditional(
    bool condition,
    Widget Function() builder, [
    Widget? fallback,
  ]) {
    return condition ? builder() : (fallback ?? const SizedBox.shrink());
  }

  /// lazy 빌딩
  static Widget lazy(Widget Function() builder) {
    return _LazyWidget(builder);
  }
}

/// 프로파일링된 위젯 래퍼
class _ProfiledWidget extends StatefulWidget {
  final Widget child;
  final List<Object?> keys;

  const _ProfiledWidget({
    required this.child,
    required this.keys,
  });

  @override
  State<_ProfiledWidget> createState() => _ProfiledWidgetState();
}

class _ProfiledWidgetState extends State<_ProfiledWidget> {
  @override
  Widget build(BuildContext context) {
    final name = widget.child.runtimeType.toString();
    WidgetProfiler.instance.startBuild(name);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      WidgetProfiler.instance.endBuild(name);
    });
    return widget.child;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ProfiledWidget &&
        listEquals(other.keys, widget.keys);
  }

  @override
  int get hashCode => Object.hashAll(widget.keys);
}

/// Lazy 위젯
class _LazyWidget extends StatefulWidget {
  final Widget Function() builder;

  const _LazyWidget({required this.builder});

  @override
  State<_LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<_LazyWidget> {
  Widget? _cachedWidget;

  @override
  void didUpdateWidget(_LazyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cachedWidget = null;
  }

  @override
  Widget build(BuildContext context) {
    return _cachedWidget ??= widget.builder();
  }
}

/// RepaintBoundary 헬퍼
class RepaintBoundaryHelper {
  /// 자동으로 RepaintBoundary 추가
  static Widget wrap({
    required Widget child,
    bool enabled = true,
  }) {
    if (!enabled) return child;
    return RepaintBoundary(child: child);
  }

  /// 특정 조건에서만 RepaintBoundary 추가
  static Widget conditionalWrap({
    required Widget child,
    required bool condition,
  }) {
    return condition ? RepaintBoundary(child: child) : child;
  }
}

/// 빌드 최적화 분석기
class BuildAnalyzer {
  /// 위젯 트리 분석
  static WidgetAnalysis analyze(BuildContext context) {
    final widget = context.widget;
    final element = context as Element;

    int depth = 0;
    int totalChildren = 0;

    void traverse(Element e, int currentDepth) {
      depth = depth > currentDepth ? depth : currentDepth;
      e.visitChildElements((child) {
        totalChildren++;
        traverse(child, currentDepth + 1);
      });
    }

    traverse(element, 0);

    return WidgetAnalysis(
      widgetType: widget.runtimeType.toString(),
      depth: depth,
      totalChildren: totalChildren,
      needsRebuild: element.dirty,
    );
  }

  /// 최적화 제안 생성
  static List<String> getOptimizationSuggestions(
    BuildContext context,
  ) {
    final analysis = analyze(context);
    final suggestions = <String>[];

    if (analysis.depth > 10) {
      suggestions.add('위젯 트리가 깊습니다 (${analysis.depth}단계). '
          '위젯을 분리하거나 Builder를 사용하세요.');
    }

    if (analysis.totalChildren > 50) {
      suggestions.add('자식 위젯이 많습니다 (${analysis.totalChildren}개). '
          'ListView/GridView를 사용하세요.');
    }

    if (analysis.needsRebuild) {
      suggestions.add('빈번한 rebuild가 발생합니다. '
          'const 생성자나 AutomaticAnimatedBuilder를 고려하세요.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('위젯 트리가 최적화되어 있습니다.');
    }

    return suggestions;
  }
}

/// 위젯 분석 결과
class WidgetAnalysis {
  final String widgetType;
  final int depth;
  final int totalChildren;
  final bool needsRebuild;

  const WidgetAnalysis({
    required this.widgetType,
    required this.depth,
    required this.totalChildren,
    required this.needsRebuild,
  });

  @override
  String toString() {
    return 'WidgetAnalysis(type: $widgetType, depth: $depth, '
        'children: $totalChildren, needsRebuild: $needsRebuild)';
  }
}

/// 성능 모니터링 위젯
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration? _lastFrameTime;
  double? _fps;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (_lastFrameTime != null) {
      final frameTime = elapsed - _lastFrameTime!;
      _fps = 1000000 / frameTime.inMicroseconds;
    }
    _lastFrameTime = elapsed;

    if (mounted && widget.showOverlay) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && _fps != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_fps!.toStringAsFixed(1)} FPS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

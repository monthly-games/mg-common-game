import 'package:flutter/material.dart';
import 'accessibility_settings.dart';

/// MG-Games 타이밍 설정
/// ACCESSIBILITY_GUIDE.md 기반
class MGTimingSettings {
  MGTimingSettings._();

  // ============================================================
  // 기본 타이밍 상수
  // ============================================================

  /// QTE 기본 윈도우 (ms)
  static const int defaultQteWindow = 1000;

  /// 타이밍 허용 오차 기본값 (ms)
  static const int defaultTimingTolerance = 100;

  /// 자동 일시정지 대기 시간 (초)
  static const int autoPauseDelay = 30;

  // ============================================================
  // 타이밍 조절 계산
  // ============================================================

  /// QTE 윈도우 계산
  static int calculateQteWindow(
    int baseWindow,
    double multiplier,
  ) {
    return (baseWindow * multiplier).round();
  }

  /// 타이밍 허용 오차 계산
  static int calculateTolerance(
    int baseTolerance,
    double multiplier,
  ) {
    return (baseTolerance * multiplier).round();
  }

  /// 설정에서 QTE 윈도우 가져오기
  static int getQteWindow(
    BuildContext context, {
    int baseWindow = defaultQteWindow,
  }) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    return calculateQteWindow(baseWindow, settings.qteTimingMultiplier);
  }

  /// 설정에서 타이밍 허용 오차 가져오기
  static int getTolerance(
    BuildContext context, {
    int baseTolerance = defaultTimingTolerance,
  }) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    return calculateTolerance(baseTolerance, settings.timingToleranceMultiplier);
  }
}

/// QTE 난이도 레벨
enum QTEDifficulty {
  /// 쉬움 (2.0x 시간)
  easy,

  /// 보통 (1.0x 시간)
  normal,

  /// 어려움 (0.7x 시간)
  hard,

  /// 매우 어려움 (0.5x 시간)
  extreme,
}

extension QTEDifficultyExtension on QTEDifficulty {
  /// 시간 배수
  double get timeMultiplier {
    switch (this) {
      case QTEDifficulty.easy:
        return 2.0;
      case QTEDifficulty.normal:
        return 1.0;
      case QTEDifficulty.hard:
        return 0.7;
      case QTEDifficulty.extreme:
        return 0.5;
    }
  }

  /// 표시 이름
  String get displayName {
    switch (this) {
      case QTEDifficulty.easy:
        return '쉬움';
      case QTEDifficulty.normal:
        return '보통';
      case QTEDifficulty.hard:
        return '어려움';
      case QTEDifficulty.extreme:
        return '매우 어려움';
    }
  }
}

/// QTE 타이머 위젯
/// 접근성 설정에 따라 시간 자동 조절
class MGQTETimer extends StatefulWidget {
  /// 기본 시간 (ms)
  final int baseDuration;

  /// 시간 완료 콜백
  final VoidCallback? onTimeUp;

  /// 시간 업데이트 콜백 (0.0 ~ 1.0)
  final ValueChanged<double>? onProgress;

  /// 타이머 표시 위젯 빌더
  final Widget Function(double progress, int remainingMs)? builder;

  /// 난이도 (null이면 접근성 설정 사용)
  final QTEDifficulty? difficulty;

  /// 자동 시작
  final bool autoStart;

  const MGQTETimer({
    super.key,
    required this.baseDuration,
    this.onTimeUp,
    this.onProgress,
    this.builder,
    this.difficulty,
    this.autoStart = true,
  });

  @override
  State<MGQTETimer> createState() => MGQTETimerState();
}

class MGQTETimerState extends State<MGQTETimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _adjustedDuration;

  @override
  void initState() {
    super.initState();
    _adjustedDuration = widget.baseDuration;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _adjustedDuration),
    );

    _controller.addListener(_onProgress);
    _controller.addStatusListener(_onStatusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDuration();

    if (widget.autoStart && !_controller.isAnimating) {
      start();
    }
  }

  void _updateDuration() {
    double multiplier;

    if (widget.difficulty != null) {
      multiplier = widget.difficulty!.timeMultiplier;
    } else {
      final settings = MGAccessibilityProvider.settingsOf(context);
      multiplier = settings.qteTimingMultiplier;
    }

    _adjustedDuration = (widget.baseDuration * multiplier).round();
    _controller.duration = Duration(milliseconds: _adjustedDuration);
  }

  void _onProgress() {
    widget.onProgress?.call(_controller.value);
  }

  void _onStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onTimeUp?.call();
    }
  }

  /// 타이머 시작
  void start() {
    _controller.forward(from: 0);
  }

  /// 타이머 일시정지
  void pause() {
    _controller.stop();
  }

  /// 타이머 재개
  void resume() {
    _controller.forward();
  }

  /// 타이머 리셋
  void reset() {
    _controller.reset();
  }

  /// 타이머 정지
  void stop() {
    _controller.stop();
    _controller.reset();
  }

  /// 남은 시간 (ms)
  int get remainingMs {
    return ((1 - _controller.value) * _adjustedDuration).round();
  }

  /// 진행률 (0.0 ~ 1.0)
  double get progress => _controller.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return widget.builder!(_controller.value, remainingMs);
      },
    );
  }
}

/// 자동 일시정지 위젯
/// 사용자 입력 없이 일정 시간 지나면 자동 일시정지
class MGAutoPause extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAutoPause;
  final Duration timeout;
  final bool enabled;

  const MGAutoPause({
    super.key,
    required this.child,
    this.onAutoPause,
    this.timeout = const Duration(seconds: 30),
    this.enabled = true,
  });

  @override
  State<MGAutoPause> createState() => _MGAutoPauseState();
}

class _MGAutoPauseState extends State<MGAutoPause> {
  DateTime _lastActivity = DateTime.now();

  void _onActivity() {
    _lastActivity = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final settings = MGAccessibilityProvider.settingsOf(context);
      if (!widget.enabled || !settings.autoPauseEnabled) {
        _startTimer();
        return;
      }

      final elapsed = DateTime.now().difference(_lastActivity);
      if (elapsed >= widget.timeout) {
        widget.onAutoPause?.call();
      }

      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onActivity,
      onPanDown: (_) => _onActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

/// 타이밍 판정 헬퍼
class MGTimingJudge {
  final int perfectWindow;
  final int greatWindow;
  final int goodWindow;
  final int tolerance;

  const MGTimingJudge({
    this.perfectWindow = 50,
    this.greatWindow = 100,
    this.goodWindow = 200,
    this.tolerance = 0,
  });

  /// 접근성 설정 적용된 인스턴스 생성
  factory MGTimingJudge.withSettings(
    BuildContext context, {
    int perfectWindow = 50,
    int greatWindow = 100,
    int goodWindow = 200,
  }) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final multiplier = settings.timingToleranceMultiplier;

    return MGTimingJudge(
      perfectWindow: (perfectWindow * multiplier).round(),
      greatWindow: (greatWindow * multiplier).round(),
      goodWindow: (goodWindow * multiplier).round(),
      tolerance: settings.timingToleranceMultiplier > 1.0 ? 50 : 0,
    );
  }

  /// 타이밍 판정
  TimingResult judge(int errorMs) {
    final absError = errorMs.abs();
    final adjustedError = (absError - tolerance).clamp(0, double.infinity);

    if (adjustedError <= perfectWindow) {
      return TimingResult.perfect;
    } else if (adjustedError <= greatWindow) {
      return TimingResult.great;
    } else if (adjustedError <= goodWindow) {
      return TimingResult.good;
    } else {
      return TimingResult.miss;
    }
  }
}

/// 타이밍 판정 결과
enum TimingResult {
  perfect,
  great,
  good,
  miss,
}

extension TimingResultExtension on TimingResult {
  /// 점수 배수
  double get scoreMultiplier {
    switch (this) {
      case TimingResult.perfect:
        return 1.0;
      case TimingResult.great:
        return 0.8;
      case TimingResult.good:
        return 0.5;
      case TimingResult.miss:
        return 0.0;
    }
  }

  /// 표시 텍스트
  String get displayText {
    switch (this) {
      case TimingResult.perfect:
        return 'PERFECT';
      case TimingResult.great:
        return 'GREAT';
      case TimingResult.good:
        return 'GOOD';
      case TimingResult.miss:
        return 'MISS';
    }
  }

  /// 색상
  Color get color {
    switch (this) {
      case TimingResult.perfect:
        return const Color(0xFFFFD700); // 금색
      case TimingResult.great:
        return const Color(0xFF00FF00); // 초록
      case TimingResult.good:
        return const Color(0xFF00BFFF); // 하늘색
      case TimingResult.miss:
        return const Color(0xFFFF4444); // 빨강
    }
  }
}

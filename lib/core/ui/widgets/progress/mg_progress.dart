import 'package:flutter/material.dart';

/// MG-Games 프로그레스 위젯
/// UI_UX_MASTER_GUIDE.md 기반

/// 선형 프로그레스 바
class MGLinearProgress extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final double borderRadius;
  final bool showLabel;
  final String? label;
  final bool animate;

  const MGLinearProgress({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 8,
    this.borderRadius = 4,
    this.showLabel = false,
    this.label,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveValueColor = valueColor ?? theme.colorScheme.primary;

    Widget progressBar = Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedFractionallySizedBox(
          duration:
              animate ? const Duration(milliseconds: 300) : Duration.zero,
          widthFactor: value.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveValueColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ),
    );

    if (!showLabel) return progressBar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Text(
                label!,
                style: theme.textTheme.bodySmall,
              ),
            Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        progressBar,
      ],
    );
  }
}

/// HP 바 (체력 표시)
class MGHpBar extends StatelessWidget {
  final double current;
  final double max;
  final Color? backgroundColor;
  final Color? hpColor;
  final Color? lowHpColor;
  final double lowHpThreshold;
  final double height;
  final bool showLabel;
  final bool showNumbers;

  const MGHpBar({
    super.key,
    required this.current,
    required this.max,
    this.backgroundColor,
    this.hpColor,
    this.lowHpColor,
    this.lowHpThreshold = 0.25,
    this.height = 12,
    this.showLabel = false,
    this.showNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final isLowHp = ratio <= lowHpThreshold;

    final effectiveHpColor = isLowHp
        ? (lowHpColor ?? Colors.red)
        : (hpColor ?? Colors.green);

    Widget hpBar = MGLinearProgress(
      value: ratio,
      backgroundColor: backgroundColor ?? Colors.grey[800],
      valueColor: effectiveHpColor,
      height: height,
      borderRadius: height / 2,
    );

    if (!showLabel && !showNumbers) return hpBar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showLabel)
              const Text(
                'HP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (showNumbers)
              Text(
                '${current.round()} / ${max.round()}',
                style: TextStyle(
                  color: effectiveHpColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        hpBar,
      ],
    );
  }
}

/// 경험치 바
class MGExpBar extends StatelessWidget {
  final double current;
  final double max;
  final int level;
  final Color? backgroundColor;
  final Color? expColor;
  final double height;
  final bool showLevel;

  const MGExpBar({
    super.key,
    required this.current,
    required this.max,
    required this.level,
    this.backgroundColor,
    this.expColor,
    this.height = 8,
    this.showLevel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        if (showLevel)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: expColor ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Lv.$level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        if (showLevel) const SizedBox(width: 8),
        Expanded(
          child: MGLinearProgress(
            value: ratio,
            backgroundColor: backgroundColor ?? Colors.grey[800],
            valueColor: expColor ?? theme.colorScheme.primary,
            height: height,
          ),
        ),
      ],
    );
  }
}

/// 타이머 프로그레스
class MGTimerProgress extends StatelessWidget {
  final double value; // 0.0 ~ 1.0 (0 = 시작, 1 = 끝)
  final Color? backgroundColor;
  final Color? valueColor;
  final Color? warningColor;
  final double warningThreshold;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool countdown;

  const MGTimerProgress({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.warningColor,
    this.warningThreshold = 0.25,
    this.size = 48,
    this.strokeWidth = 4,
    this.child,
    this.countdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = countdown ? 1 - value : value;
    final isWarning = countdown
        ? value >= (1 - warningThreshold)
        : value <= warningThreshold;

    final effectiveValueColor = isWarning
        ? (warningColor ?? Colors.red)
        : (valueColor ?? theme.colorScheme.primary);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: displayValue.clamp(0.0, 1.0),
            backgroundColor:
                backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(effectiveValueColor),
            strokeWidth: strokeWidth,
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// 원형 프로그레스
class MGCircularProgress extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final Color? backgroundColor;
  final Color? valueColor;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final bool showPercent;

  const MGCircularProgress({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.size = 64,
    this.strokeWidth = 6,
    this.center,
    this.showPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor:
                backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              valueColor ?? theme.colorScheme.primary,
            ),
            strokeWidth: strokeWidth,
          ),
          if (center != null)
            center!
          else if (showPercent)
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// 자원 바 (재화 표시)
class MGResourceBar extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const MGResourceBar({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 애니메이션 FractionallySizedBox
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double? widthFactor;
  final double? heightFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve = Curves.easeInOut,
    this.widthFactor,
    this.heightFactor,
    this.alignment = Alignment.center,
    this.child,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor ?? 1.0,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;

    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor ?? 1.0,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation),
      heightFactor: _heightFactor?.evaluate(animation),
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}

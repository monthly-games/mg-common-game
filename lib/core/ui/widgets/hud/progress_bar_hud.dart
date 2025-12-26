import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Common HUD progress bar for health, mana, stamina, exp, etc.
class ProgressBarHud extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color? fillColor;
  final Color? backgroundColor;
  final double height;
  final double width;
  final String? label;
  final bool showValue;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const ProgressBarHud({
    super.key,
    required this.value,
    required this.maxValue,
    this.fillColor,
    this.backgroundColor,
    this.height = 20,
    this.width = 200,
    this.label,
    this.showValue = true,
    this.borderRadius,
    this.gradient,
  });

  /// Factory for health bar (red)
  factory ProgressBarHud.health({
    required double value,
    required double maxValue,
    double height = 20,
    double width = 200,
    bool showValue = true,
  }) {
    return ProgressBarHud(
      value: value,
      maxValue: maxValue,
      fillColor: Colors.red,
      height: height,
      width: width,
      label: 'HP',
      showValue: showValue,
    );
  }

  /// Factory for mana bar (blue)
  factory ProgressBarHud.mana({
    required double value,
    required double maxValue,
    double height = 20,
    double width = 200,
    bool showValue = true,
  }) {
    return ProgressBarHud(
      value: value,
      maxValue: maxValue,
      fillColor: Colors.blue,
      height: height,
      width: width,
      label: 'MP',
      showValue: showValue,
    );
  }

  /// Factory for stamina bar (green)
  factory ProgressBarHud.stamina({
    required double value,
    required double maxValue,
    double height = 20,
    double width = 200,
    bool showValue = true,
  }) {
    return ProgressBarHud(
      value: value,
      maxValue: maxValue,
      fillColor: Colors.green,
      height: height,
      width: width,
      label: 'SP',
      showValue: showValue,
    );
  }

  /// Factory for experience bar (yellow/gold)
  factory ProgressBarHud.exp({
    required double value,
    required double maxValue,
    double height = 16,
    double width = 200,
    bool showValue = true,
  }) {
    return ProgressBarHud(
      value: value,
      maxValue: maxValue,
      gradient: const LinearGradient(
        colors: [Colors.orange, Colors.yellow],
      ),
      height: height,
      width: width,
      label: 'EXP',
      showValue: showValue,
    );
  }

  /// Factory for skill/cooldown bar (cyan)
  factory ProgressBarHud.cooldown({
    required double value,
    required double maxValue,
    double height = 8,
    double width = 100,
    bool showValue = false,
  }) {
    return ProgressBarHud(
      value: value,
      maxValue: maxValue,
      fillColor: Colors.cyan,
      height: height,
      width: width,
      showValue: showValue,
    );
  }

  double get _progress => maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.black.withValues(alpha: 0.6);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: TextStyle(
                color: AppColors.textMediumEmphasis,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Fill bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: width * _progress,
                height: height,
                decoration: BoxDecoration(
                  color: gradient == null ? fillColor : null,
                  gradient: gradient,
                  borderRadius: radius,
                ),
              ),
              // Value text
              if (showValue)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${value.toInt()} / ${maxValue.toInt()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: height * 0.6,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

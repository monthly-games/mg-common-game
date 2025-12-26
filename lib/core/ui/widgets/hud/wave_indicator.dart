import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Wave/Stage/Level indicator for battle and roguelike games
class WaveIndicator extends StatelessWidget {
  final int currentWave;
  final int? maxWave;
  final String label;
  final Color? accentColor;
  final bool showProgress;
  final TextStyle? textStyle;

  const WaveIndicator({
    super.key,
    required this.currentWave,
    this.maxWave,
    this.label = 'WAVE',
    this.accentColor,
    this.showProgress = true,
    this.textStyle,
  });

  /// Factory for stage indicator
  factory WaveIndicator.stage({
    required int current,
    int? max,
    Color? accentColor,
  }) {
    return WaveIndicator(
      currentWave: current,
      maxWave: max,
      label: 'STAGE',
      accentColor: accentColor ?? Colors.purple,
    );
  }

  /// Factory for floor indicator (dungeon)
  factory WaveIndicator.floor({
    required int current,
    int? max,
    Color? accentColor,
  }) {
    return WaveIndicator(
      currentWave: current,
      maxWave: max,
      label: 'FLOOR',
      accentColor: accentColor ?? Colors.teal,
    );
  }

  /// Factory for round indicator (battle)
  factory WaveIndicator.round({
    required int current,
    int? max,
    Color? accentColor,
  }) {
    return WaveIndicator(
      currentWave: current,
      maxWave: max,
      label: 'ROUND',
      accentColor: accentColor ?? Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final style = textStyle ?? AppTextStyles.headline3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentWave.toString(),
                style: style.copyWith(color: Colors.white),
              ),
              if (maxWave != null) ...[
                Text(
                  ' / $maxWave',
                  style: TextStyle(
                    color: AppColors.textMediumEmphasis,
                    fontSize: style.fontSize! * 0.6,
                  ),
                ),
              ],
            ],
          ),
          if (showProgress && maxWave != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              height: 4,
              child: LinearProgressIndicator(
                value: (currentWave / maxWave!).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

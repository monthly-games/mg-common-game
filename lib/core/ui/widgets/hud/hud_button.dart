import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Common HUD button for pause, settings, menu actions
class HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;
  final bool hasBorder;

  const HudButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.tooltip,
    this.hasBorder = true,
  });

  /// Factory for pause button
  factory HudButton.pause({VoidCallback? onPressed}) {
    return HudButton(
      icon: Icons.pause,
      onPressed: onPressed,
      tooltip: 'Pause',
    );
  }

  /// Factory for settings button
  factory HudButton.settings({VoidCallback? onPressed}) {
    return HudButton(
      icon: Icons.settings,
      onPressed: onPressed,
      tooltip: 'Settings',
    );
  }

  /// Factory for menu button
  factory HudButton.menu({VoidCallback? onPressed}) {
    return HudButton(
      icon: Icons.menu,
      onPressed: onPressed,
      tooltip: 'Menu',
    );
  }

  /// Factory for close/back button
  factory HudButton.close({VoidCallback? onPressed}) {
    return HudButton(
      icon: Icons.close,
      onPressed: onPressed,
      tooltip: 'Close',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.surface.withValues(alpha: 0.8);
    final fgColor = iconColor ?? AppColors.textHighEmphasis;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: hasBorder
                ? Border.all(color: AppColors.border, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: fgColor,
            size: size * 0.5,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

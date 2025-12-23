import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'package:mg_common_game/core/ui/theme/app_text_styles.dart';

enum GameButtonVariant { primary, secondary, destructive }

class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final double? width;

  const GameButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = GameButtonVariant.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: _getStyle(),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.button,
        ),
      ),
    );
  }

  ButtonStyle _getStyle() {
    Color bg;
    Color fg;

    switch (variant) {
      case GameButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.textHighEmphasis;
        break;
      case GameButtonVariant.secondary:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case GameButtonVariant.destructive:
        bg = AppColors.error;
        fg = Colors.white;
        break;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: AppColors.surfaceLight,
      disabledForegroundColor: AppColors.textDisabled,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: variant == GameButtonVariant.secondary
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }
}

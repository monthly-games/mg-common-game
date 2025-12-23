import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/game_button.dart';
import '../containers/game_panel.dart';

class GameDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onConfirm;
  final String confirmText;
  final VoidCallback? onCancel;
  final String? cancelText;

  const GameDialog({
    super.key,
    required this.title,
    required this.content,
    this.onConfirm,
    this.confirmText = 'OK',
    this.onCancel,
    this.cancelText,
  });

  /// Factory for a simple Alert dialog (single button)
  static Widget alert({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
  }) {
    return GameDialog(
      title: title,
      content: content,
      onConfirm: onConfirm,
      confirmText: confirmText,
    );
  }

  /// Factory for a Confirm dialog (two buttons)
  static Widget confirm({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = 'CONFIRM',
    VoidCallback? onCancel,
    String cancelText = 'CANCEL',
  }) {
    return GameDialog(
      title: title,
      content: content,
      onConfirm: onConfirm,
      confirmText: confirmText,
      onCancel: onCancel,
      cancelText: cancelText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GamePanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title.toUpperCase(),
              style: AppTextStyles.header2.copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              content,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onCancel != null || cancelText != null) ...[
                  Expanded(
                    child: GameButton(
                      text: cancelText ?? 'CANCEL',
                      onPressed: () {
                        onCancel?.call();
                        Navigator.of(context)
                            .pop(); // Close dialog on secondary action too
                      },
                      variant: GameButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: GameButton(
                    text: confirmText,
                    onPressed: () {
                      onConfirm?.call();
                      Navigator.of(context).pop();
                    },
                    variant: GameButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

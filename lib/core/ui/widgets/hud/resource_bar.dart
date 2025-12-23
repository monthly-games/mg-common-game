import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../containers/game_panel.dart';

class ResourceBar extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  const ResourceBar({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.color = AppColors.secondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GamePanel(
        isGlass: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),

            // Value
            Text(value, style: AppTextStyles.button),

            // Optional Label
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMediumEmphasis),
              ),
            ],

            // Plus Button hint (if tappable)
            if (onTap != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              )
            ]
          ],
        ),
      ),
    );
  }
}

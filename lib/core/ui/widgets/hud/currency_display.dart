import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Currency/Resource display widget for HUD
class CurrencyDisplay extends StatelessWidget {
  final int amount;
  final IconData icon;
  final Color? iconColor;
  final String? label;
  final bool compact;
  final VoidCallback? onTap;
  final bool animate;

  const CurrencyDisplay({
    super.key,
    required this.amount,
    required this.icon,
    this.iconColor,
    this.label,
    this.compact = false,
    this.onTap,
    this.animate = true,
  });

  /// Factory for gold display
  factory CurrencyDisplay.gold({
    required int amount,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return CurrencyDisplay(
      amount: amount,
      icon: Icons.monetization_on,
      iconColor: Colors.amber,
      label: 'Gold',
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for gems/diamonds display
  factory CurrencyDisplay.gems({
    required int amount,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return CurrencyDisplay(
      amount: amount,
      icon: Icons.diamond,
      iconColor: Colors.cyan,
      label: 'Gems',
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for energy display
  factory CurrencyDisplay.energy({
    required int amount,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return CurrencyDisplay(
      amount: amount,
      icon: Icons.bolt,
      iconColor: Colors.yellow,
      label: 'Energy',
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for crystals display
  factory CurrencyDisplay.crystals({
    required int amount,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return CurrencyDisplay(
      amount: amount,
      icon: Icons.hexagon,
      iconColor: Colors.purple,
      label: 'Crystals',
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for tokens display
  factory CurrencyDisplay.tokens({
    required int amount,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return CurrencyDisplay(
      amount: amount,
      icon: Icons.toll,
      iconColor: Colors.orange,
      label: 'Tokens',
      compact: compact,
      onTap: onTap,
    );
  }

  String get _formattedAmount {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.secondary;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: compact ? 16 : 20,
          ),
          SizedBox(width: compact ? 4 : 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: amount, end: amount),
            duration:
                animate ? const Duration(milliseconds: 300) : Duration.zero,
            builder: (context, value, child) {
              return Text(
                _formattedAmount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          if (onTap != null) ...[
            SizedBox(width: compact ? 4 : 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: compact ? 10 : 12,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

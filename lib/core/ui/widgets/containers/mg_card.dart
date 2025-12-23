import 'package:flutter/material.dart';
import '../../layout/mg_spacing.dart';

/// MG-Games 카드 위젯
/// UI_UX_MASTER_GUIDE.md 기반
class MGCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final String? semanticLabel;

  const MGCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 12,
    this.elevation = 2,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
  });

  /// 상호작용 카드
  const MGCard.interactive({
    super.key,
    required this.child,
    required VoidCallback this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 12,
    this.elevation = 2,
    this.enabled = true,
    this.semanticLabel,
  });

  /// 테두리 카드
  const MGCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    Color this.borderColor = const Color(0xFF444444),
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
  }) : elevation = 0;

  /// 투명 카드
  const MGCard.transparent({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 12,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
  })  : backgroundColor = Colors.transparent,
        elevation = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground = backgroundColor ?? theme.cardColor;
    final effectivePadding = padding ?? MGSpacing.cardEdgePadding;

    Widget cardContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null || borderWidth != null
            ? Border.all(
                color: borderColor ?? theme.dividerColor,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      cardContent = Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: cardContent,
      ),
    );
  }
}

/// 아이템 카드 (아이콘 + 제목 + 설명)
class MGItemCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool enabled;

  const MGItemCard({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MGCard(
      onTap: onTap,
      enabled: enabled,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: leading,
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 통계 카드 (숫자 강조)
class MGStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? change;
  final bool positive;
  final VoidCallback? onTap;

  const MGStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.change,
    this.positive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return MGCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: effectiveColor,
                ),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                change!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: positive ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 게임 카드 (썸네일 + 정보)
class MGGameCard extends StatelessWidget {
  final Widget thumbnail;
  final String title;
  final String? category;
  final double? rating;
  final VoidCallback? onTap;
  final double width;

  const MGGameCard({
    super.key,
    required this.thumbnail,
    required this.title,
    this.category,
    this.rating,
    this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: MGCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbnail,
              ),
            ),
            // 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null || rating != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (category != null)
                            Expanded(
                              child: Text(
                                category!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          if (rating != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating!.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

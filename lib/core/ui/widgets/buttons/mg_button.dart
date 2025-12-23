import 'package:flutter/material.dart';
import '../../layout/mg_spacing.dart';
import '../../accessibility/accessibility_settings.dart';
import '../../accessibility/haptic_feedback_manager.dart';

/// MG-Games 버튼 위젯
/// UI_UX_MASTER_GUIDE.md 기반
class MGButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MGButtonSize size;
  final MGButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final String? semanticLabel;

  const MGButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = MGButtonSize.medium,
    this.style = MGButtonStyle.filled,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.semanticLabel,
  });

  /// Primary 버튼 생성자
  const MGButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = MGButtonSize.medium,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.width,
    this.semanticLabel,
  })  : style = MGButtonStyle.filled,
        backgroundColor = null,
        foregroundColor = null;

  /// Secondary 버튼 생성자
  const MGButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = MGButtonSize.medium,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.width,
    this.semanticLabel,
  })  : style = MGButtonStyle.outlined,
        backgroundColor = null,
        foregroundColor = null;

  /// Text 버튼 생성자
  const MGButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = MGButtonSize.medium,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.width,
    this.semanticLabel,
  })  : style = MGButtonStyle.text,
        backgroundColor = null,
        foregroundColor = null;

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final minHeight = _getMinHeight(settings.touchAreaSize);
    final padding = _getPadding();

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: _getIconSize()),
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    final isDisabled = !enabled || loading;

    switch (style) {
      case MGButtonStyle.filled:
        return Semantics(
          button: true,
          enabled: !isDisabled,
          label: semanticLabel ?? label,
          child: SizedBox(
            width: width,
            height: minHeight,
            child: ElevatedButton(
              onPressed: isDisabled
                  ? null
                  : () {
                      MGHapticFeedback.lightTap(context);
                      onPressed?.call();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                padding: padding,
                minimumSize: Size(0, minHeight),
              ),
              child: child,
            ),
          ),
        );

      case MGButtonStyle.outlined:
        return Semantics(
          button: true,
          enabled: !isDisabled,
          label: semanticLabel ?? label,
          child: SizedBox(
            width: width,
            height: minHeight,
            child: OutlinedButton(
              onPressed: isDisabled
                  ? null
                  : () {
                      MGHapticFeedback.lightTap(context);
                      onPressed?.call();
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: foregroundColor ?? backgroundColor,
                padding: padding,
                minimumSize: Size(0, minHeight),
                side: backgroundColor != null
                    ? BorderSide(color: backgroundColor!)
                    : null,
              ),
              child: child,
            ),
          ),
        );

      case MGButtonStyle.text:
        return Semantics(
          button: true,
          enabled: !isDisabled,
          label: semanticLabel ?? label,
          child: SizedBox(
            width: width,
            height: minHeight,
            child: TextButton(
              onPressed: isDisabled
                  ? null
                  : () {
                      MGHapticFeedback.lightTap(context);
                      onPressed?.call();
                    },
              style: TextButton.styleFrom(
                foregroundColor: foregroundColor ?? backgroundColor,
                padding: padding,
                minimumSize: Size(0, minHeight),
              ),
              child: child,
            ),
          ),
        );
    }
  }

  double _getMinHeight(TouchAreaSize touchSize) {
    // 접근성 설정에 따른 최소 높이
    final accessibilityMin = touchSize.minSize;

    switch (size) {
      case MGButtonSize.small:
        return accessibilityMin.clamp(36, 44);
      case MGButtonSize.medium:
        return accessibilityMin.clamp(44, 56);
      case MGButtonSize.large:
        return accessibilityMin.clamp(52, 72);
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case MGButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case MGButtonSize.medium:
        return MGSpacing.buttonEdgePadding;
      case MGButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case MGButtonSize.small:
        return 14;
      case MGButtonSize.medium:
        return 16;
      case MGButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (size) {
      case MGButtonSize.small:
        return 16;
      case MGButtonSize.medium:
        return 20;
      case MGButtonSize.large:
        return 24;
    }
  }
}

/// 버튼 크기
enum MGButtonSize {
  small,
  medium,
  large,
}

/// 버튼 스타일
enum MGButtonStyle {
  filled,
  outlined,
  text,
}

/// 아이콘 버튼 크기
enum MGIconButtonSize {
  small,
  medium,
  large,
}

/// 아이콘 버튼
class MGIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final MGIconButtonSize buttonSize;
  final double? size; // deprecated: 하위 호환성을 위해 유지
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final String? semanticLabel;
  final bool enabled;

  const MGIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.buttonSize = MGIconButtonSize.medium,
    this.size,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final minSize = settings.touchAreaSize.minSize;

    // size 파라미터가 제공되면 사용, 아니면 buttonSize enum 사용
    final baseSize = size ?? _getSizeFromEnum(buttonSize);
    final effectiveSize = baseSize.clamp(minSize, double.infinity);

    Widget button = IconButton(
      icon: Icon(icon),
      iconSize: effectiveSize * 0.5,
      color: color,
      onPressed: enabled
          ? () {
              MGHapticFeedback.lightTap(context);
              onPressed?.call();
            }
          : null,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: Size(effectiveSize, effectiveSize),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? tooltip,
      child: button,
    );
  }

  double _getSizeFromEnum(MGIconButtonSize buttonSize) {
    switch (buttonSize) {
      case MGIconButtonSize.small:
        return 36;
      case MGIconButtonSize.medium:
        return 44;
      case MGIconButtonSize.large:
        return 56;
    }
  }
}

/// 플로팅 액션 버튼
class MGFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final String? semanticLabel;
  final bool mini;
  final bool extended;
  final String? label;

  const MGFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.semanticLabel,
    this.mini = false,
    this.extended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (extended && label != null) {
      button = FloatingActionButton.extended(
        onPressed: () {
          MGHapticFeedback.mediumTap(context);
          onPressed?.call();
        },
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        tooltip: tooltip,
      );
    } else {
      button = FloatingActionButton(
        onPressed: () {
          MGHapticFeedback.mediumTap(context);
          onPressed?.call();
        },
        mini: mini,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        tooltip: tooltip,
        child: Icon(icon),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? tooltip ?? label,
      child: button,
    );
  }
}

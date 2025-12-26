import 'package:flutter/material.dart';

/// A pressable button with scale and opacity animation feedback.
///
/// Provides tactile feedback by scaling down and reducing opacity when pressed.
class MGPressableButton extends StatefulWidget {
  /// The child widget (typically text or icon).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The scale factor when pressed (e.g., 0.95 for 5% reduction).
  final double pressedScale;

  /// The opacity when pressed (0.0 to 1.0).
  final double pressedOpacity;

  /// Duration of the press animation.
  final Duration duration;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Border radius of the button.
  final double borderRadius;

  /// Optional border for the button.
  final BorderSide? border;

  const MGPressableButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.95,
    this.pressedOpacity = 0.7,
    this.duration = const Duration(milliseconds: 100),
    this.padding,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.border,
  });

  @override
  State<MGPressableButton> createState() => _MGPressableButtonState();
}

class _MGPressableButtonState extends State<MGPressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final buttonContent = Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
      ),
      child: widget.child,
    );

    if (reduceMotion || widget.onPressed == null) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: buttonContent,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          );
        },
        child: buttonContent,
      ),
    );
  }
}

/// A button with a bounce effect when pressed.
///
/// Provides tactile feedback with a spring-like bounce animation.
class MGBounceButton extends StatefulWidget {
  /// The child widget (typically text or icon).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The scale factor at the peak of the bounce.
  final double bounceScale;

  /// Duration of the bounce animation.
  final Duration duration;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Border radius of the button.
  final double borderRadius;

  /// Optional border for the button.
  final BorderSide? border;

  const MGBounceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.bounceScale = 1.2,
    this.duration = const Duration(milliseconds: 400),
    this.padding,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.border,
  });

  @override
  State<MGBounceButton> createState() => _MGBounceButtonState();
}

class _MGBounceButtonState extends State<MGBounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: widget.bounceScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.bounceScale, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      _controller.forward(from: 0.0);
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final buttonContent = Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
      ),
      child: widget.child,
    );

    if (reduceMotion || widget.onPressed == null) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: buttonContent,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: buttonContent,
      ),
    );
  }
}

/// A button with an animated shimmer highlight effect.
///
/// Displays a moving shimmer/shine effect across the button surface.
class MGShimmerButton extends StatefulWidget {
  /// The child widget (typically text or icon).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Duration of the shimmer animation cycle.
  final Duration duration;

  /// The color of the shimmer highlight.
  final Color? shimmerColor;

  /// Whether to animate the shimmer continuously.
  final bool continuous;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Border radius of the button.
  final double borderRadius;

  /// Optional border for the button.
  final BorderSide? border;

  const MGShimmerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 2000),
    this.shimmerColor,
    this.continuous = true,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.border,
  });

  @override
  State<MGShimmerButton> createState() => _MGShimmerButtonState();
}

class _MGShimmerButtonState extends State<MGShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.continuous) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      if (!widget.continuous) {
        _controller.forward(from: 0.0);
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final baseColor = widget.backgroundColor ?? Theme.of(context).primaryColor;
    final shimmer = widget.shimmerColor ?? Colors.white.withOpacity(0.3);

    final buttonContent = Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
      ),
      child: widget.child,
    );

    if (reduceMotion || widget.onPressed == null) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: buttonContent,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              buttonContent,
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Transform.translate(
                    offset: Offset(200 * _shimmerAnimation.value, 0),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            shimmer,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A button with a glow effect on hover or press.
///
/// Displays an animated glow around the button when interacted with.
class MGGlowButton extends StatefulWidget {
  /// The child widget (typically text or icon).
  final Widget child;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Duration of the glow animation.
  final Duration duration;

  /// The color of the glow effect.
  final Color? glowColor;

  /// The maximum blur radius of the glow.
  final double glowRadius;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Border radius of the button.
  final double borderRadius;

  /// Optional border for the button.
  final BorderSide? border;

  const MGGlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 200),
    this.glowColor,
    this.glowRadius = 20.0,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.border,
  });

  @override
  State<MGGlowButton> createState() => _MGGlowButtonState();
}

class _MGGlowButtonState extends State<MGGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverEnter(PointerEvent event) {
    setState(() => _isHovering = true);
    _controller.forward();
  }

  void _handleHoverExit(PointerEvent event) {
    setState(() => _isHovering = false);
    _controller.reverse();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isHovering) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!_isHovering) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final baseColor = widget.backgroundColor ?? Theme.of(context).primaryColor;
    final glow = widget.glowColor ?? baseColor;

    final buttonContent = Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
      ),
      child: widget.child,
    );

    if (reduceMotion || widget.onPressed == null) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: buttonContent,
        ),
      );
    }

    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: glow.withOpacity(0.6 * _glowAnimation.value),
                    blurRadius: widget.glowRadius * _glowAnimation.value,
                    spreadRadius: 2.0 * _glowAnimation.value,
                  ),
                ],
              ),
              child: buttonContent,
            );
          },
        ),
      ),
    );
  }
}

/// An icon button with ripple effect.
///
/// Displays an icon with a circular ripple animation on press.
class MGIconButton extends StatefulWidget {
  /// The icon to display.
  final IconData icon;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Size of the icon.
  final double iconSize;

  /// Color of the icon.
  final Color? iconColor;

  /// Background color of the button.
  final Color? backgroundColor;

  /// The size of the button (width and height).
  final double size;

  /// Duration of the ripple animation.
  final Duration duration;

  /// Color of the ripple effect.
  final Color? rippleColor;

  const MGIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24.0,
    this.iconColor,
    this.backgroundColor,
    this.size = 48.0,
    this.duration = const Duration(milliseconds: 300),
    this.rippleColor,
  });

  @override
  State<MGIconButton> createState() => _MGIconButtonState();
}

class _MGIconButtonState extends State<MGIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      _controller.forward(from: 0.0);
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ripple = widget.rippleColor ?? Theme.of(context).primaryColor.withOpacity(0.3);

    if (reduceMotion || widget.onPressed == null) {
      return GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.onPressed == null
                  ? (widget.iconColor ?? Colors.grey)
                  : widget.iconColor,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: ripple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Button background
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

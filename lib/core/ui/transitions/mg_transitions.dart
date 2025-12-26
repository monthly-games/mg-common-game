import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Fade transition widget that animates opacity.
///
/// Fades a child widget in or out over a specified duration.
class MGFadeTransition extends StatefulWidget {
  /// The child widget to animate.
  final Widget child;

  /// Duration of the fade animation.
  final Duration duration;

  /// The curve to use for the animation.
  final Curve curve;

  /// The initial opacity (0.0 to 1.0).
  final double initialOpacity;

  /// The final opacity (0.0 to 1.0).
  final double finalOpacity;

  /// Whether to start the animation automatically.
  final bool autoStart;

  const MGFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.initialOpacity = 0.0,
    this.finalOpacity = 1.0,
    this.autoStart = true,
  });

  @override
  State<MGFadeTransition> createState() => _MGFadeTransitionState();
}

class _MGFadeTransitionState extends State<MGFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.initialOpacity,
      end: widget.finalOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return Opacity(
        opacity: widget.finalOpacity,
        child: widget.child,
      );
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: widget.child,
    );
  }
}

/// Slide transition that animates from a direction.
///
/// Slides a child widget in from a specified direction.
class MGSlideTransition extends StatefulWidget {
  /// The child widget to animate.
  final Widget child;

  /// Duration of the slide animation.
  final Duration duration;

  /// The curve to use for the animation.
  final Curve curve;

  /// The direction to slide from.
  final AxisDirection direction;

  /// The distance to slide as a fraction of the widget size.
  final double distance;

  /// Whether to start the animation automatically.
  final bool autoStart;

  const MGSlideTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.direction = AxisDirection.left,
    this.distance = 1.0,
    this.autoStart = true,
  });

  @override
  State<MGSlideTransition> createState() => _MGSlideTransitionState();
}

class _MGSlideTransitionState extends State<MGSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final Offset begin = _getBeginOffset();
    _offsetAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case AxisDirection.up:
        return Offset(0, widget.distance);
      case AxisDirection.down:
        return Offset(0, -widget.distance);
      case AxisDirection.left:
        return Offset(widget.distance, 0);
      case AxisDirection.right:
        return Offset(-widget.distance, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return widget.child;
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

/// Scale transition that animates size.
///
/// Scales a child widget up or down from a specified scale.
class MGScaleTransition extends StatefulWidget {
  /// The child widget to animate.
  final Widget child;

  /// Duration of the scale animation.
  final Duration duration;

  /// The curve to use for the animation.
  final Curve curve;

  /// The initial scale factor.
  final double initialScale;

  /// The final scale factor.
  final double finalScale;

  /// The alignment point for scaling.
  final Alignment alignment;

  /// Whether to start the animation automatically.
  final bool autoStart;

  const MGScaleTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.initialScale = 0.0,
    this.finalScale = 1.0,
    this.alignment = Alignment.center,
    this.autoStart = true,
  });

  @override
  State<MGScaleTransition> createState() => _MGScaleTransitionState();
}

class _MGScaleTransitionState extends State<MGScaleTransition>
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

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: widget.finalScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}

/// 3D flip transition effect.
///
/// Flips a child widget around the Y-axis (horizontal flip) or X-axis (vertical flip).
class MGFlipTransition extends StatefulWidget {
  /// The child widget to animate.
  final Widget child;

  /// Duration of the flip animation.
  final Duration duration;

  /// The curve to use for the animation.
  final Curve curve;

  /// Whether to flip horizontally (around Y-axis) or vertically (around X-axis).
  final Axis flipAxis;

  /// Whether to start the animation automatically.
  final bool autoStart;

  const MGFlipTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.flipAxis = Axis.horizontal,
    this.autoStart = true,
  });

  @override
  State<MGFlipTransition> createState() => _MGFlipTransitionState();
}

class _MGFlipTransitionState extends State<MGFlipTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final transform = Matrix4.identity()..setEntry(3, 2, 0.001);

        if (widget.flipAxis == Axis.horizontal) {
          transform.rotateY(angle);
        } else {
          transform.rotateX(angle);
        }

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Builder for creating custom page route transitions.
///
/// Provides easy-to-use page transitions for navigation.
class MGPageTransitionBuilder {
  /// Creates a page route with a fade transition.
  static PageRouteBuilder<T> fade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  /// Creates a page route with a slide transition.
  static PageRouteBuilder<T> slide<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    AxisDirection direction = AxisDirection.left,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        final Offset begin;
        switch (direction) {
          case AxisDirection.up:
            begin = const Offset(0, 1);
            break;
          case AxisDirection.down:
            begin = const Offset(0, -1);
            break;
          case AxisDirection.left:
            begin = const Offset(1, 0);
            break;
          case AxisDirection.right:
            begin = const Offset(-1, 0);
            break;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  /// Creates a page route with a scale transition.
  static PageRouteBuilder<T> scale<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Alignment alignment = Alignment.center,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          alignment: alignment,
          child: child,
        );
      },
    );
  }

  /// Creates a page route with a combined fade and scale transition.
  static PageRouteBuilder<T> fadeScale<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Alignment alignment = Alignment.center,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(curvedAnimation),
            alignment: alignment,
            child: child,
          ),
        );
      },
    );
  }

  /// Creates a page route with a 3D flip transition.
  static PageRouteBuilder<T> flip<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    Axis flipAxis = Axis.horizontal,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final angle = animation.value * math.pi;
            final transform = Matrix4.identity()..setEntry(3, 2, 0.001);

            if (flipAxis == Axis.horizontal) {
              transform.rotateY(angle);
            } else {
              transform.rotateX(angle);
            }

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// Creates a page route with a slide and fade combined transition.
  static PageRouteBuilder<T> slideFade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    AxisDirection direction = AxisDirection.left,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

        if (reduceMotion) {
          return child;
        }

        final Offset begin;
        switch (direction) {
          case AxisDirection.up:
            begin = const Offset(0, 0.3);
            break;
          case AxisDirection.down:
            begin = const Offset(0, -0.3);
            break;
          case AxisDirection.left:
            begin = const Offset(0.3, 0);
            break;
          case AxisDirection.right:
            begin = const Offset(-0.3, 0);
            break;
        }

        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

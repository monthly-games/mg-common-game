import 'package:flutter/material.dart';

/// Visual feedback utilities
class VisualFeedbackManager {
  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  /// Create a scale animation on tap
  static Widget scaleOnTap({
    required Widget child,
    VoidCallback? onTap,
    double pressedScale = 0.95,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _ScaleOnTapWidget(
      onTap: onTap,
      pressedScale: pressedScale,
      duration: duration,
      child: child,
    );
  }

  /// Create a bounce animation
  static Widget bounce({
    required Widget child,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    double bounceHeight = 10,
  }) {
    if (!animate) return child;
    return _BounceWidget(
      duration: duration,
      bounceHeight: bounceHeight,
      child: child,
    );
  }

  /// Create a shake animation
  static Widget shake({
    required Widget child,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 500),
    double intensity = 10,
  }) {
    if (!animate) return child;
    return _ShakeWidget(
      duration: duration,
      intensity: intensity,
      child: child,
    );
  }

  /// Create a pulse animation
  static Widget pulse({
    required Widget child,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    if (!animate) return child;
    return _PulseWidget(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      child: child,
    );
  }

  /// Create a glow effect
  static Widget glow({
    required Widget child,
    Color glowColor = Colors.yellow,
    double blurRadius = 20,
    bool animate = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(animate ? 0.6 : 0.3),
            blurRadius: blurRadius,
            spreadRadius: animate ? 5 : 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Scale on tap widget
class _ScaleOnTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  const _ScaleOnTapWidget({
    required this.child,
    this.onTap,
    required this.pressedScale,
    required this.duration,
  });

  @override
  State<_ScaleOnTapWidget> createState() => _ScaleOnTapWidgetState();
}

class _ScaleOnTapWidgetState extends State<_ScaleOnTapWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}

/// Bounce animation widget
class _BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;

  const _BounceWidget({
    required this.child,
    required this.duration,
    required this.bounceHeight,
  });

  @override
  State<_BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<_BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.bounceHeight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shake animation widget
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;

  const _ShakeWidget({
    required this.child,
    required this.duration,
    required this.intensity,
  });

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shake = (1 - _controller.value) *
            widget.intensity *
            ((_controller.value * 10).floor() % 2 == 0 ? 1 : -1);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pulse animation widget
class _PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const _PulseWidget({
    required this.child,
    required this.duration,
    required this.minScale,
    required this.maxScale,
  });

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

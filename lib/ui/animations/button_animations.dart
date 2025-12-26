import 'package:flutter/material.dart';

/// Animated button with scale and bounce effects
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double pressedScale;
  final Curve curve;
  final bool enabled;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.pressedScale = 0.95,
    this.curve = Curves.easeInOut,
    this.enabled = true,
    this.splashColor,
    this.borderRadius,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Bounce button with spring animation
class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double bounceScale;
  final bool enabled;

  const BounceButton({
    super.key,
    required this.child,
    this.onPressed,
    this.bounceScale = 0.9,
    this.enabled = true,
  });

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.bounceScale),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.bounceScale, end: 1.05),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.enabled) return;
    _controller.forward(from: 0);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Pulse button with continuous animation
class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool enabled;
  final bool autoPulse;

  const PulseButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.enabled = true,
    this.autoPulse = true,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
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
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.autoPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer effect button
class ShimmerButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color shimmerColor;
  final Duration duration;
  final bool enabled;

  const ShimmerButton({
    super.key,
    required this.child,
    this.onPressed,
    this.shimmerColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  widget.shimmerColor.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: [
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                ].map((e) => e.clamp(0.0, 1.0)).toList(),
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Glow button with animated glow effect
class GlowButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;
  final bool enabled;

  const GlowButton({
    super.key,
    required this.child,
    this.onPressed,
    this.glowColor = Colors.blue,
    this.glowRadius = 20.0,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
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
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(_animation.value * 0.5),
                  blurRadius: widget.glowRadius * _animation.value,
                  spreadRadius: widget.glowRadius * 0.3 * _animation.value,
                ),
              ],
            ),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

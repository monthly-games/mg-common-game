import 'package:flutter/material.dart';

/// A customizable animated loading spinner widget.
///
/// Displays a circular spinning animation with customizable colors and size.
/// Automatically respects platform accessibility settings for reduced motion.
class MGLoadingSpinner extends StatefulWidget {
  /// The size of the spinner (width and height).
  final double size;

  /// The color of the spinner.
  final Color color;

  /// The width of the spinner stroke.
  final double strokeWidth;

  /// Duration of one complete rotation.
  final Duration duration;

  const MGLoadingSpinner({
    super.key,
    this.size = 40.0,
    this.color = Colors.blue,
    this.strokeWidth = 4.0,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<MGLoadingSpinner> createState() => _MGLoadingSpinnerState();
}

class _MGLoadingSpinnerState extends State<MGLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      );
    }

    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: widget.strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }
}

/// A progress bar with shimmer effect.
///
/// Displays a linear progress bar with an animated shimmer overlay
/// that moves across the bar to indicate activity.
class MGLoadingBar extends StatefulWidget {
  /// The width of the loading bar.
  final double? width;

  /// The height of the loading bar.
  final double height;

  /// The background color of the bar.
  final Color backgroundColor;

  /// The color of the progress fill.
  final Color progressColor;

  /// The color of the shimmer effect.
  final Color? shimmerColor;

  /// Optional progress value (0.0 to 1.0). If null, shows indeterminate progress.
  final double? value;

  /// Border radius of the bar.
  final double borderRadius;

  /// Duration of the shimmer animation.
  final Duration duration;

  const MGLoadingBar({
    super.key,
    this.width,
    this.height = 8.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.progressColor = Colors.blue,
    this.shimmerColor,
    this.value,
    this.borderRadius = 4.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<MGLoadingBar> createState() => _MGLoadingBarState();
}

class _MGLoadingBarState extends State<MGLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // Progress bar
            if (widget.value != null)
              FractionallySizedBox(
                widthFactor: widget.value!.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  color: widget.progressColor,
                ),
              )
            else
              Container(
                color: widget.progressColor,
              ),
            // Shimmer effect
            if (!reduceMotion)
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(
                        (widget.width ?? MediaQuery.of(context).size.width) *
                            _shimmerAnimation.value,
                        0,
                      ),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              widget.shimmerColor ??
                                  widget.progressColor.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Bouncing dots loading animation.
///
/// Displays three dots that bounce up and down in sequence.
class MGLoadingDots extends StatefulWidget {
  /// The size of each dot.
  final double dotSize;

  /// The color of the dots.
  final Color color;

  /// The spacing between dots.
  final double spacing;

  /// Duration of one complete bounce cycle.
  final Duration duration;

  /// The height of the bounce animation.
  final double bounceHeight;

  const MGLoadingDots({
    super.key,
    this.dotSize = 12.0,
    this.color = Colors.blue,
    this.spacing = 8.0,
    this.duration = const Duration(milliseconds: 1200),
    this.bounceHeight = 20.0,
  });

  @override
  State<MGLoadingDots> createState() => _MGLoadingDotsState();
}

class _MGLoadingDotsState extends State<MGLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    // Create staggered animations for each dot
    _animations = List.generate(3, (index) {
      final begin = index * 0.2;
      final end = begin + 0.4;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: -widget.bounceHeight)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: -widget.bounceHeight, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end.clamp(0.0, 1.0), curve: Curves.linear),
        ),
      );
    });
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Pulsing circle loading animation.
///
/// Displays a circle that pulses (scales and fades) continuously.
class MGLoadingPulse extends StatefulWidget {
  /// The size of the pulsing circle.
  final double size;

  /// The color of the circle.
  final Color color;

  /// Duration of one pulse cycle.
  final Duration duration;

  /// The minimum scale factor (0.0 to 1.0).
  final double minScale;

  /// The maximum scale factor (> 1.0).
  final double maxScale;

  const MGLoadingPulse({
    super.key,
    this.size = 50.0,
    this.color = Colors.blue,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.8,
    this.maxScale = 1.2,
  });

  @override
  State<MGLoadingPulse> createState() => _MGLoadingPulseState();
}

class _MGLoadingPulseState extends State<MGLoadingPulse>
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
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
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
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader placeholder for content loading.
///
/// Displays an animated shimmer effect over a placeholder shape
/// to indicate content is loading.
class MGSkeletonLoader extends StatefulWidget {
  /// The width of the skeleton placeholder.
  final double? width;

  /// The height of the skeleton placeholder.
  final double height;

  /// The base color of the skeleton.
  final Color baseColor;

  /// The highlight color for the shimmer effect.
  final Color highlightColor;

  /// Border radius of the skeleton.
  final double borderRadius;

  /// Duration of the shimmer animation.
  final Duration duration;

  const MGSkeletonLoader({
    super.key,
    this.width,
    this.height = 20.0,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.borderRadius = 4.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<MGSkeletonLoader> createState() => _MGSkeletonLoaderState();
}

class _MGSkeletonLoaderState extends State<MGSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

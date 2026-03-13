import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';

/// 애니메이션 타입
enum AnimationType {
  fadeIn,
  slideIn,
  scaleIn,
  rotation,
  bounce,
  shimmer,
}

/// 애니메이션 방향
enum AnimationDirection {
  top,
  bottom,
  left,
  right,
  center,
}

/// 애니메이션 옵션
class AnimationOptions {
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool autoStart;

  const AnimationOptions({
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.autoStart = true,
  });
}

/// 애니메이션된 위젯 래퍼
class AnimatedWidgetWrapper extends StatefulWidget {
  final Widget child;
  final AnimationType type;
  final AnimationDirection direction;
  final AnimationOptions options;
  final VoidCallback? onAnimationComplete;

  const AnimatedWidgetWrapper({
    super.key,
    required this.child,
    this.type = AnimationType.fadeIn,
    this.direction = AnimationDirection.bottom,
    this.options = const AnimationOptions(),
    this.onAnimationComplete,
  });

  @override
  State<AnimatedWidgetWrapper> createState() => _AnimatedWidgetWrapperState();
}

class _AnimatedWidgetWrapperState extends State<AnimatedWidgetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.options.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.options.curve,
    );

    if (widget.options.autoStart) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    Future.delayed(widget.options.delay, () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onAnimationComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case AnimationType.fadeIn:
        return _buildFadeIn();
      case AnimationType.slideIn:
        return _buildSlideIn();
      case AnimationType.scaleIn:
        return _buildScaleIn();
      case AnimationType.rotation:
        return _buildRotation();
      case AnimationType.bounce:
        return _buildBounce();
      case AnimationType.shimmer:
        return _buildShimmer();
    }
  }

  Widget _buildFadeIn() {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }

  Widget _buildSlideIn() {
    Tween<Offset> slideTween;

    switch (widget.direction) {
      case AnimationDirection.top:
        slideTween = Tween(begin: const Offset(0, -1), end: Offset.zero);
        break;
      case AnimationDirection.bottom:
        slideTween = Tween(begin: const Offset(0, 1), end: Offset.zero);
        break;
      case AnimationDirection.left:
        slideTween = Tween(begin: const Offset(-1, 0), end: Offset.zero);
        break;
      case AnimationDirection.right:
        slideTween = Tween(begin: const Offset(1, 0), end: Offset.zero);
        break;
      case AnimationDirection.center:
        slideTween = Tween(begin: Offset.zero, end: Offset.zero);
        break;
    }

    return SlideTransition(
      position: slideTween.animate(_animation),
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }

  Widget _buildScaleIn() {
    return ScaleTransition(
      scale: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }

  Widget _buildRotation() {
    return RotationTransition(
      turns: _animation,
      child: widget.child,
    );
  }

  Widget _buildBounce() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: widget.options.duration,
      curve: Curves.bounceOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: widget.child,
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ],
          ).createShader(bounds),
          child: widget.child,
        );
      },
    );
  }
}

/// 스태거드 애니메이션 (리스트 항목 순차적 등장)
class StaggeredAnimationListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final AnimationType animationType;
  final AnimationDirection direction;
  final Duration duration;
  final Duration staggerDelay;

  const StaggeredAnimationListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.animationType = AnimationType.slideIn,
    this.direction = AnimationDirection.bottom,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedWidgetWrapper(
          type: animationType,
          direction: direction,
          options: AnimationOptions(
            duration: duration,
            delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          ),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// 페이드 인아웃 컨테이너
class FadeInOutContainer extends StatefulWidget {
  final Widget child;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Duration displayDuration;
  final bool autoPlay;

  const FadeInOutContainer({
    super.key,
    required this.child,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeOutDuration = const Duration(milliseconds: 500),
    this.displayDuration = const Duration(seconds: 3),
    this.autoPlay = true,
  });

  @override
  State<FadeInOutContainer> createState() => _FadeInOutContainerState();
}

class _FadeInOutContainerState extends State<FadeInOutContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.fadeInDuration + widget.displayDuration + widget.fadeOutDuration,
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0, widget.fadeInDuration.inMilliseconds / _controller.duration.inMilliseconds),
      ),
    );

    _fadeOutAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (widget.fadeInDuration + widget.displayDuration).inMilliseconds / _controller.duration.inMilliseconds,
          1.0,
        ),
      ),
    );

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: widget.child,
    );
  }
}

/// 풀스크린 페이지 트랜지션
class PageTransitionBuilder {
  /// 페이드 트랜지션
  static PageRouteBuilder<T> fadeRoute<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// 슬라이드 트랜지션
  static PageRouteBuilder<T> slideRoute<T>({
    required Widget child,
    SlideDirection direction = SlideDirection.right,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    Offset begin;

    switch (direction) {
      case SlideDirection.up:
        begin = const Offset(0, 1);
        break;
      case SlideDirection.down:
        begin = const Offset(0, -1);
        break;
      case SlideDirection.left:
        begin = const Offset(1, 0);
        break;
      case SlideDirection.right:
        begin = const Offset(-1, 0);
        break;
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }

  /// 스케일 트랜지션
  static PageRouteBuilder<T> scaleRoute<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }
}

/// 슬라이드 방향
enum SlideDirection {
  up,
  down,
  left,
  right,
}

/// 페이드 인아웃 위젯
class FadeInOut extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool visible;
  final bool maintainState;

  const FadeInOut({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.visible = true,
    this.maintainState = false,
  });

  @override
  State<FadeInOut> createState() => _FadeInOutState();
}

class _FadeInOutState extends State<FadeInOut>
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

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FadeInOut oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.maintainState || widget.visible
          ? widget.child
          : const SizedBox.shrink(),
    );
  }
}

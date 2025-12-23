import 'dart:math';
import 'package:flutter/material.dart';
import 'animation_durations.dart';
import '../accessibility/accessibility_settings.dart';

/// MG-Games 애니메이션 위젯
/// UI_UX_MASTER_GUIDE.md 기반

/// 페이드 인 애니메이션
class MGFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final bool animate;

  const MGFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
    this.delay = Duration.zero,
    this.animate = true,
  });

  @override
  State<MGFadeIn> createState() => _MGFadeInState();
}

class _MGFadeInState extends State<MGFadeIn>
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
      curve: widget.curve,
    );

    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// 슬라이드 인 애니메이션
class MGSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final Offset beginOffset;
  final bool animate;

  const MGSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.2),
    this.animate = true,
  });

  /// 아래에서 위로
  const MGSlideIn.up({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0, 0.2);

  /// 위에서 아래로
  const MGSlideIn.down({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0, -0.2);

  /// 왼쪽에서
  const MGSlideIn.left({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(-0.2, 0);

  /// 오른쪽에서
  const MGSlideIn.right({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginOffset = const Offset(0.2, 0);

  @override
  State<MGSlideIn> createState() => _MGSlideInState();
}

class _MGSlideInState extends State<MGSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 스케일 인 애니메이션
class MGScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double beginScale;
  final bool animate;

  const MGScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutBack,
    this.delay = Duration.zero,
    this.beginScale = 0.8,
    this.animate = true,
  });

  /// 팝업 효과
  const MGScaleIn.pop({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutBack,
    this.delay = Duration.zero,
    this.animate = true,
  }) : beginScale = 0.5;

  @override
  State<MGScaleIn> createState() => _MGScaleInState();
}

class _MGScaleInState extends State<MGScaleIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.animate) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 흔들기 애니메이션
class MGShake extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;
  final int shakes;
  final bool trigger;

  const MGShake({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.intensity = 8.0,
    this.shakes = 4,
    this.trigger = false,
  });

  @override
  State<MGShake> createState() => MGShakeState();
}

class MGShakeState extends State<MGShake> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    if (widget.trigger) {
      shake();
    }
  }

  @override
  void didUpdateWidget(MGShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      shake();
    }
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue =
            sin(_animation.value * widget.shakes * 2 * 3.14159);
        return Transform.translate(
          offset: Offset(sineValue * widget.intensity, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 펄스 애니메이션 (반복)
class MGPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool animate;

  const MGPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.animate = true,
  });

  @override
  State<MGPulse> createState() => _MGPulseState();
}

class _MGPulseState extends State<MGPulse> with SingleTickerProviderStateMixin {
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

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MGPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion || !widget.animate) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// 스태거 애니메이션 (리스트 아이템)
class MGStaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Curve curve;
  final Offset slideOffset;

  const MGStaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 0.1),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (index) {
        return MGSlideIn(
          duration: itemDuration,
          curve: curve,
          delay: itemDelay * index,
          beginOffset: slideOffset,
          child: children[index],
        );
      }),
    );
  }
}

/// 타이핑 애니메이션 (텍스트)
class MGTypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const MGTypingText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 50),
    this.onComplete,
  });

  @override
  State<MGTypingText> createState() => _MGTypingTextState();
}

class _MGTypingTextState extends State<MGTypingText> {
  String _displayText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(widget.charDuration, () {
        if (mounted) {
          setState(() {
            _displayText = widget.text.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
          _startTyping();
        }
      });
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    if (settings.reduceMotion) {
      return Text(widget.text, style: widget.style);
    }

    return Text(_displayText, style: widget.style);
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../accessibility/accessibility_settings.dart';
import 'polish_sounds.dart';

/// 콤보 카운터 위젯
///
/// 콤보 수에 따라 색상/크기가 변하며 펄스 효과를 줍니다.
///
/// ```dart
/// MGComboCounter(
///   count: combo,
///   thresholds: [5, 10, 20],
///   onMilestone: (count) => playSound(),
/// )
/// ```
class MGComboCounter extends StatefulWidget {
  final int count;
  final List<int> thresholds;
  final List<Color> colors;
  final TextStyle? baseStyle;
  final bool showPulse;
  final bool showGlow;
  final void Function(int milestone)? onMilestone;
  final String prefix;

  const MGComboCounter({
    super.key,
    required this.count,
    this.thresholds = const [5, 10, 20],
    this.colors = const [
      Colors.white,   // 기본
      Colors.yellow,  // 5+
      Colors.orange,  // 10+
      Colors.purple,  // 20+
    ],
    this.baseStyle,
    this.showPulse = true,
    this.showGlow = true,
    this.onMilestone,
    this.prefix = 'COMBO',
  });

  @override
  State<MGComboCounter> createState() => _MGComboCounterState();
}

class _MGComboCounterState extends State<MGComboCounter>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bumpController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bumpAnimation;
  int _lastMilestone = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bumpController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _bumpController,
      curve: Curves.easeOutBack,
    ));

    if (widget.showPulse && widget.count > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MGComboCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 콤보 증가 시 bump 애니메이션
    if (widget.count > oldWidget.count) {
      _bumpController.forward(from: 0);

      // 마일스톤 체크
      for (int i = widget.thresholds.length - 1; i >= 0; i--) {
        if (widget.count >= widget.thresholds[i] &&
            oldWidget.count < widget.thresholds[i]) {
          widget.onMilestone?.call(widget.thresholds[i]);
          break;
        }
      }
    }

    // 콤보 리셋 시 펄스 중지
    if (widget.count == 0 && oldWidget.count > 0) {
      _pulseController.stop();
    } else if (widget.count > 0 && oldWidget.count == 0 && widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bumpController.dispose();
    super.dispose();
  }

  int get _colorIndex {
    for (int i = widget.thresholds.length - 1; i >= 0; i--) {
      if (widget.count >= widget.thresholds[i]) {
        return i + 1;
      }
    }
    return 0;
  }

  Color get _currentColor {
    final index = _colorIndex.clamp(0, widget.colors.length - 1);
    return widget.colors[index];
  }

  double get _fontSize {
    final base = widget.baseStyle?.fontSize ?? 24.0;
    // 콤보가 높을수록 약간 커짐
    return base + (_colorIndex * 4);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) {
      return const SizedBox.shrink();
    }

    final settings = MGAccessibilityProvider.settingsOf(context);

    Widget text = _buildComboText();

    // 글로우 효과
    if (widget.showGlow && _colorIndex > 0 && !settings.reduceMotion) {
      text = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _currentColor.withOpacity(0.5),
              blurRadius: 15 + (_colorIndex * 5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: text,
      );
    }

    if (settings.reduceMotion) {
      return text;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _bumpAnimation]),
      builder: (context, child) {
        final scale = _pulseAnimation.value * _bumpAnimation.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: text,
    );
  }

  Widget _buildComboText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 콤보 숫자
        Stack(
          children: [
            // 외곽선
            Text(
              '${widget.count}',
              style: TextStyle(
                fontSize: _fontSize + 8,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..color = Colors.black,
              ),
            ),
            // 본문
            Text(
              '${widget.count}',
              style: TextStyle(
                fontSize: _fontSize + 8,
                fontWeight: FontWeight.bold,
                color: _currentColor,
                shadows: [
                  Shadow(
                    color: _currentColor.withOpacity(0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        // COMBO 텍스트
        Text(
          widget.prefix,
          style: TextStyle(
            fontSize: _fontSize * 0.5,
            fontWeight: FontWeight.bold,
            color: _currentColor,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

/// 콤보 브레이크 표시
class MGComboBreak extends StatefulWidget {
  final int lostCombo;
  final VoidCallback? onComplete;

  const MGComboBreak({
    super.key,
    required this.lostCombo,
    this.onComplete,
  });

  @override
  State<MGComboBreak> createState() => _MGComboBreakState();
}

class _MGComboBreakState extends State<MGComboBreak>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8),
        weight: 50,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BREAK',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
              letterSpacing: 4,
            ),
          ),
          Text(
            '-${widget.lostCombo}',
            style: TextStyle(
              fontSize: 20,
              color: Colors.red.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

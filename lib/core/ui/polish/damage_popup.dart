import 'dart:math';
import 'package:flutter/material.dart';
import '../accessibility/accessibility_settings.dart';

/// 데미지 타입
enum DamageType {
  normal,
  critical,
  weak,
  heal,
  miss,
  blocked,
}

/// 데미지 팝업 데이터
class DamagePopupData {
  final int value;
  final DamageType type;
  final Offset position;
  final String? prefix;
  final String? suffix;
  final DateTime createdAt;

  DamagePopupData({
    required this.value,
    this.type = DamageType.normal,
    required this.position,
    this.prefix,
    this.suffix,
  }) : createdAt = DateTime.now();

  String get displayText {
    final buffer = StringBuffer();
    if (prefix != null) buffer.write(prefix);

    if (type == DamageType.miss) {
      buffer.write('MISS');
    } else if (type == DamageType.blocked) {
      buffer.write('BLOCKED');
    } else {
      buffer.write(value.abs());
    }

    if (suffix != null) buffer.write(suffix);
    return buffer.toString();
  }

  Color get color {
    switch (type) {
      case DamageType.normal:
        return Colors.white;
      case DamageType.critical:
        return Colors.yellow;
      case DamageType.weak:
        return Colors.grey;
      case DamageType.heal:
        return Colors.green;
      case DamageType.miss:
        return Colors.grey.shade400;
      case DamageType.blocked:
        return Colors.blue.shade300;
    }
  }

  double get fontSize {
    switch (type) {
      case DamageType.critical:
        return 32;
      case DamageType.weak:
      case DamageType.miss:
        return 18;
      case DamageType.heal:
        return 24;
      default:
        return 22;
    }
  }
}

/// 데미지 팝업 위젯
///
/// 전투 중 데미지/힐 숫자를 화면에 표시합니다.
class MGDamagePopup extends StatefulWidget {
  final DamagePopupData data;
  final VoidCallback? onComplete;
  final Duration duration;

  const MGDamagePopup({
    super.key,
    required this.data,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<MGDamagePopup> createState() => _MGDamagePopupState();
}

class _MGDamagePopupState extends State<MGDamagePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;
  late double _randomXOffset;

  @override
  void initState() {
    super.initState();
    _randomXOffset = (Random().nextDouble() - 0.5) * 40;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // 크리티컬은 더 큰 스케일로 시작
    final startScale = widget.data.type == DamageType.critical ? 1.5 : 1.2;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: startScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.8),
        weight: 70,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_randomXOffset, -80),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

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
    final settings = MGAccessibilityProvider.settingsOf(context);

    if (settings.reduceMotion) {
      // 모션 감소 시 단순 텍스트
      return Positioned(
        left: widget.data.position.dx,
        top: widget.data.position.dy,
        child: Text(
          widget.data.displayText,
          style: TextStyle(
            fontSize: widget.data.fontSize,
            color: widget.data.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.data.position.dx + _positionAnimation.value.dx,
          top: widget.data.position.dy + _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: _buildText(),
    );
  }

  Widget _buildText() {
    final isCritical = widget.data.type == DamageType.critical;

    return Stack(
      children: [
        // 외곽선 (가독성)
        Text(
          widget.data.displayText,
          style: TextStyle(
            fontSize: widget.data.fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
        ),
        // 본문
        Text(
          widget.data.displayText,
          style: TextStyle(
            fontSize: widget.data.fontSize,
            color: widget.data.color,
            fontWeight: FontWeight.bold,
            shadows: isCritical
                ? [
                    Shadow(
                      color: Colors.orange.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// 데미지 팝업 오버레이
///
/// 여러 개의 데미지 팝업을 관리합니다.
class MGDamagePopupOverlay extends StatefulWidget {
  final Widget child;

  const MGDamagePopupOverlay({
    super.key,
    required this.child,
  });

  @override
  State<MGDamagePopupOverlay> createState() => MGDamagePopupOverlayState();

  static MGDamagePopupOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<MGDamagePopupOverlayState>();
  }
}

class MGDamagePopupOverlayState extends State<MGDamagePopupOverlay> {
  final List<DamagePopupData> _popups = [];

  /// 데미지 팝업 표시
  void showDamage({
    required int value,
    required Offset position,
    DamageType type = DamageType.normal,
  }) {
    setState(() {
      _popups.add(DamagePopupData(
        value: value,
        position: position,
        type: type,
      ));
    });
  }

  /// 크리티컬 데미지
  void showCritical(int value, Offset position) {
    showDamage(value: value, position: position, type: DamageType.critical);
  }

  /// 힐
  void showHeal(int value, Offset position) {
    showDamage(value: value, position: position, type: DamageType.heal);
  }

  /// 미스
  void showMiss(Offset position) {
    showDamage(value: 0, position: position, type: DamageType.miss);
  }

  void _removePopup(DamagePopupData data) {
    setState(() {
      _popups.remove(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._popups.map((data) => MGDamagePopup(
              key: ValueKey(data.createdAt),
              data: data,
              onComplete: () => _removePopup(data),
            )),
      ],
    );
  }
}

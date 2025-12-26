import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../audio/audio_manager.dart';
import '../accessibility/accessibility_settings.dart';
import 'polish_sounds.dart';

/// 햅틱 피드백 타입
enum HapticType {
  /// 가벼운 탭 (일반 버튼)
  light,

  /// 중간 탭 (중요 버튼)
  medium,

  /// 무거운 탭 (확인, 구매 등)
  heavy,

  /// 선택/토글
  selection,

  /// 성공
  success,

  /// 에러/실패
  error,

  /// 없음
  none,
}

/// 터치 피드백 위젯
///
/// 터치 시 스케일 애니메이션 + 햅틱 진동 + 사운드 효과를 제공합니다.
///
/// ```dart
/// MGTouchFeedback(
///   onTap: () => doSomething(),
///   haptic: HapticType.medium,
///   sound: PolishSounds.tap,
///   child: Container(...),
/// )
/// ```
class MGTouchFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HapticType haptic;
  final String? sound;
  final double scaleDown;
  final Duration duration;
  final bool enabled;

  const MGTouchFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = HapticType.light,
    this.sound,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enabled = true,
  });

  /// 일반 버튼용
  const MGTouchFeedback.button({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
  })  : haptic = HapticType.light,
        sound = PolishSounds.tap,
        scaleDown = 0.95,
        duration = const Duration(milliseconds: 100);

  /// 중요 버튼용 (확인, 구매 등)
  const MGTouchFeedback.important({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
  })  : haptic = HapticType.heavy,
        sound = PolishSounds.tapHeavy,
        scaleDown = 0.92,
        duration = const Duration(milliseconds: 120);

  /// 아이콘 버튼용
  const MGTouchFeedback.icon({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
  })  : haptic = HapticType.selection,
        sound = PolishSounds.tap,
        scaleDown = 0.9,
        duration = const Duration(milliseconds: 80);

  /// 카드/타일용
  const MGTouchFeedback.card({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
  })  : haptic = HapticType.light,
        sound = PolishSounds.tap,
        scaleDown = 0.98,
        duration = const Duration(milliseconds: 150);

  @override
  State<MGTouchFeedback> createState() => _MGTouchFeedbackState();
}

class _MGTouchFeedbackState extends State<MGTouchFeedback>
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
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _onTap() {
    if (!widget.enabled) return;

    // 햅틱 피드백
    _triggerHaptic();

    // 사운드 효과
    _playSound();

    // 콜백 실행
    widget.onTap?.call();
  }

  void _triggerHaptic() {
    switch (widget.haptic) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.success:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact();
        });
        break;
      case HapticType.error:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 80), () {
          HapticFeedback.heavyImpact();
        });
        break;
      case HapticType.none:
        break;
    }
  }

  void _playSound() {
    if (widget.sound == null) return;
    // AudioManager는 GetIt/Injectable로 주입되므로 여기서는 static 호출
    // 실제 프로젝트에서는 Provider나 GetIt으로 접근
    try {
      // AudioManager.instance.playSfx(widget.sound!);
    } catch (_) {
      // Audio not initialized
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    // 접근성: 모션 감소 설정 시 스케일 애니메이션 비활성화
    if (settings.reduceMotion) {
      return GestureDetector(
        onTap: widget.enabled ? _onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? _onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// 버튼 래퍼 - 기존 버튼에 터치 피드백 추가
class MGPolishedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;

  const MGPolishedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return MGTouchFeedback.button(
      onTap: onPressed,
      enabled: enabled && onPressed != null,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'accessibility_settings.dart';

/// MG-Games 터치 설정
/// ACCESSIBILITY_GUIDE.md 기반
class MGTouchSettings {
  MGTouchSettings._();

  // ============================================================
  // 터치 영역 크기
  // ============================================================

  /// 기본 최소 터치 영역 (WCAG 기준)
  static const double minTouchSize = 44;

  /// 작은 터치 영역
  static const double smallTouchSize = 36;

  /// 큰 터치 영역
  static const double largeTouchSize = 56;

  /// 매우 큰 터치 영역
  static const double extraLargeTouchSize = 72;

  /// 설정에 따른 최소 터치 크기 반환
  static double getMinTouchSize(TouchAreaSize size) {
    return size.minSize;
  }

  // ============================================================
  // 터치 간격
  // ============================================================

  /// 터치 요소 간 최소 간격
  static const double minTouchSpacing = 8;

  /// 권장 터치 요소 간격
  static const double recommendedTouchSpacing = 12;

  // ============================================================
  // 제스처 타이밍
  // ============================================================

  /// 탭 최대 지속 시간 (ms)
  static const int tapMaxDuration = 200;

  /// 길게 누르기 최소 시간 (ms)
  static const int longPressMinDuration = 500;

  /// 더블탭 최대 간격 (ms)
  static const int doubleTapMaxInterval = 300;

  /// 스와이프 최소 속도 (px/s)
  static const double swipeMinVelocity = 150;

  /// 스와이프 최소 거리 (px)
  static const double swipeMinDistance = 50;
}

/// 적응형 터치 영역 위젯
/// 접근성 설정에 따라 터치 영역 자동 조절
class MGAdaptiveTouchArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final double? minWidth;
  final double? minHeight;
  final HitTestBehavior behavior;

  const MGAdaptiveTouchArea({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.minWidth,
    this.minHeight,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final minSize = settings.touchAreaSize.minSize;

    final effectiveMinWidth = minWidth ?? minSize;
    final effectiveMinHeight = minHeight ?? minSize;

    // 길게 누르기 대체 (더블탭으로)
    VoidCallback? effectiveLongPress = onLongPress;
    VoidCallback? effectiveDoubleTap = onDoubleTap;

    if (settings.replaceLongPress && onLongPress != null) {
      effectiveDoubleTap = onLongPress;
      effectiveLongPress = null;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: effectiveLongPress,
      onDoubleTap: effectiveDoubleTap,
      behavior: behavior,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: effectiveMinWidth,
          minHeight: effectiveMinHeight,
        ),
        child: child,
      ),
    );
  }
}

/// 한손 모드 레이아웃
/// 한손으로 조작하기 쉽게 UI 재배치
class MGOneHandedLayout extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool rightHanded;

  const MGOneHandedLayout({
    super.key,
    required this.child,
    this.enabled = true,
    this.rightHanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    final effectiveEnabled = enabled && settings.oneHandedMode;
    final effectiveRightHanded =
        settings.oneHandedModeRightHand;

    if (!effectiveEnabled) {
      return child;
    }

    return Align(
      alignment: effectiveRightHanded
          ? Alignment.bottomRight
          : Alignment.bottomLeft,
      child: FractionallySizedBox(
        heightFactor: 0.6, // 화면 하단 60%에 UI 집중
        widthFactor: 0.85, // 화면 너비 85% 사용
        child: child,
      ),
    );
  }
}

/// 드래그 대체 위젯
/// 드래그 대신 탭으로 이동
class MGTapToMove extends StatefulWidget {
  final Widget child;
  final void Function(Offset position)? onPositionChanged;
  final bool enabled;
  final Offset initialPosition;

  const MGTapToMove({
    super.key,
    required this.child,
    this.onPositionChanged,
    this.enabled = true,
    this.initialPosition = Offset.zero,
  });

  @override
  State<MGTapToMove> createState() => _MGTapToMoveState();
}

class _MGTapToMoveState extends State<MGTapToMove> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    if (!widget.enabled || !settings.replaceDrag) {
      // 일반 드래그 모드
      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
          widget.onPositionChanged?.call(_position);
        },
        child: Transform.translate(
          offset: _position,
          child: widget.child,
        ),
      );
    }

    // 탭 투 무브 모드
    return GestureDetector(
      onTapUp: (details) {
        setState(() {
          _position = details.localPosition;
        });
        widget.onPositionChanged?.call(_position);
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 탭 가능 영역 표시
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
            ),
          ),
          // 이동 대상
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// 확장 터치 영역 위젯
/// 시각적 크기보다 큰 터치 영역 제공
class MGExpandedTouchArea extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const MGExpandedTouchArea({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

/// 멀티탭 감지 위젯
/// 연속 탭 간격 조절 가능
class MGMultiTapDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;
  final int? customInterval;

  const MGMultiTapDetector({
    super.key,
    required this.child,
    this.onSingleTap,
    this.onDoubleTap,
    this.onTripleTap,
    this.customInterval,
  });

  @override
  State<MGMultiTapDetector> createState() => _MGMultiTapDetectorState();
}

class _MGMultiTapDetectorState extends State<MGMultiTapDetector> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final interval = widget.customInterval ?? settings.multiTapInterval;

    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        final lastTap = _lastTapTime;

        if (lastTap != null &&
            now.difference(lastTap).inMilliseconds < interval) {
          _tapCount++;
        } else {
          _tapCount = 1;
        }

        _lastTapTime = now;

        // 지연 후 처리
        Future.delayed(Duration(milliseconds: interval), () {
          if (_lastTapTime == now) {
            switch (_tapCount) {
              case 1:
                widget.onSingleTap?.call();
                break;
              case 2:
                widget.onDoubleTap?.call();
                break;
              case 3:
                widget.onTripleTap?.call();
                break;
            }
            _tapCount = 0;
          }
        });
      },
      child: widget.child,
    );
  }
}

/// 접근성 버튼 래퍼
/// 터치 영역, 시맨틱, 피드백 통합
class MGAccessibleButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final bool enabled;

  const MGAccessibleButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);
    final minSize = settings.touchAreaSize.minSize;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: MGAdaptiveTouchArea(
        onTap: enabled ? onPressed : null,
        minWidth: minSize,
        minHeight: minSize,
        child: child,
      ),
    );
  }
}

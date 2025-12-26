import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../accessibility/accessibility_settings.dart';

/// 화면 효과 컨트롤러
///
/// 쉐이크, 플래시, 슬로우모션 등 화면 전체 효과를 관리합니다.
///
/// ```dart
/// // BuildContext에서 사용
/// MGScreenEffects.of(context).shake();
/// MGScreenEffects.of(context).flash(Colors.red);
/// ```
class MGScreenEffectsController extends ChangeNotifier {
  // 쉐이크 상태
  double _shakeIntensity = 0;
  double _shakeOffsetX = 0;
  double _shakeOffsetY = 0;
  Timer? _shakeTimer;

  // 플래시 상태
  Color? _flashColor;
  double _flashOpacity = 0;
  Timer? _flashTimer;

  // 슬로우모션 상태
  double _timeScale = 1.0;
  Timer? _slowMoTimer;

  // 줌 상태
  double _zoomScale = 1.0;
  Offset _zoomCenter = Offset.zero;

  // Getters
  double get shakeOffsetX => _shakeOffsetX;
  double get shakeOffsetY => _shakeOffsetY;
  Color? get flashColor => _flashColor;
  double get flashOpacity => _flashOpacity;
  double get timeScale => _timeScale;
  double get zoomScale => _zoomScale;
  Offset get zoomCenter => _zoomCenter;

  final Random _random = Random();

  /// 화면 쉐이크
  ///
  /// [intensity] 0.0 ~ 1.0 (1.0 = 최대 20픽셀)
  /// [duration] 쉐이크 지속 시간
  void shake({
    double intensity = 0.5,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _shakeIntensity = intensity.clamp(0.0, 1.0);
    _shakeTimer?.cancel();

    final startTime = DateTime.now();
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed >= duration) {
        _shakeOffsetX = 0;
        _shakeOffsetY = 0;
        _shakeIntensity = 0;
        timer.cancel();
        notifyListeners();
        return;
      }

      // 감쇠 효과
      final progress = elapsed.inMilliseconds / duration.inMilliseconds;
      final decay = 1.0 - progress;
      final maxOffset = 20.0 * _shakeIntensity * decay;

      _shakeOffsetX = (_random.nextDouble() * 2 - 1) * maxOffset;
      _shakeOffsetY = (_random.nextDouble() * 2 - 1) * maxOffset;
      notifyListeners();
    });
  }

  /// 강한 쉐이크 (큰 타격, 폭발 등)
  void shakeHeavy() {
    shake(intensity: 1.0, duration: const Duration(milliseconds: 400));
  }

  /// 약한 쉐이크 (일반 타격)
  void shakeLight() {
    shake(intensity: 0.3, duration: const Duration(milliseconds: 200));
  }

  /// 화면 플래시
  ///
  /// [color] 플래시 색상 (기본: 흰색)
  /// [duration] 플래시 지속 시간
  /// [maxOpacity] 최대 불투명도
  void flash({
    Color color = Colors.white,
    Duration duration = const Duration(milliseconds: 150),
    double maxOpacity = 0.5,
  }) {
    _flashColor = color;
    _flashOpacity = maxOpacity;
    _flashTimer?.cancel();
    notifyListeners();

    _flashTimer = Timer(duration, () {
      _flashOpacity = 0;
      notifyListeners();
    });
  }

  /// 데미지 플래시 (빨간색)
  void flashDamage() {
    flash(color: Colors.red, maxOpacity: 0.3);
  }

  /// 힐 플래시 (녹색)
  void flashHeal() {
    flash(color: Colors.green, maxOpacity: 0.2);
  }

  /// 크리티컬 플래시 (노란색 + 쉐이크)
  void flashCritical() {
    flash(color: Colors.yellow, maxOpacity: 0.4);
    shake(intensity: 0.6, duration: const Duration(milliseconds: 250));
  }

  /// 슬로우모션
  ///
  /// [scale] 시간 배율 (0.5 = 절반 속도)
  /// [duration] 슬로우모션 지속 시간
  void slowMotion({
    double scale = 0.3,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _timeScale = scale.clamp(0.1, 1.0);
    _slowMoTimer?.cancel();
    notifyListeners();

    _slowMoTimer = Timer(duration, () {
      _timeScale = 1.0;
      notifyListeners();
    });
  }

  /// 줌 인/아웃
  void zoom({
    double scale = 1.2,
    Offset center = Offset.zero,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _zoomScale = scale;
    _zoomCenter = center;
    notifyListeners();

    Future.delayed(duration, () {
      _zoomScale = 1.0;
      notifyListeners();
    });
  }

  /// 히트스탑 (잠깐 멈춤)
  ///
  /// 큰 타격 시 게임이 순간적으로 멈추는 효과
  Future<void> hitStop({Duration duration = const Duration(milliseconds: 50)}) async {
    _timeScale = 0;
    notifyListeners();
    await Future.delayed(duration);
    _timeScale = 1.0;
    notifyListeners();
  }

  /// 콤보 연출 (쉐이크 + 플래시 + 줌)
  void comboEffect(int comboCount) {
    final intensity = (comboCount / 20).clamp(0.2, 1.0);
    shake(intensity: intensity * 0.5, duration: const Duration(milliseconds: 150));

    if (comboCount >= 10) {
      flash(
        color: _getComboColor(comboCount),
        maxOpacity: 0.2,
        duration: const Duration(milliseconds: 100),
      );
    }

    if (comboCount >= 20) {
      zoom(scale: 1.05, duration: const Duration(milliseconds: 200));
    }
  }

  Color _getComboColor(int count) {
    if (count >= 20) return Colors.purple;
    if (count >= 10) return Colors.orange;
    return Colors.yellow;
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _flashTimer?.cancel();
    _slowMoTimer?.cancel();
    super.dispose();
  }
}

/// 화면 효과 Provider
class MGScreenEffects extends InheritedNotifier<MGScreenEffectsController> {
  const MGScreenEffects({
    super.key,
    required MGScreenEffectsController controller,
    required super.child,
  }) : super(notifier: controller);

  static MGScreenEffectsController of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<MGScreenEffects>();
    return widget?.notifier ?? MGScreenEffectsController();
  }

  static MGScreenEffectsController? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<MGScreenEffects>();
    return widget?.notifier;
  }
}

/// 화면 효과 래퍼 위젯
///
/// 게임 화면을 이 위젯으로 감싸면 화면 효과가 적용됩니다.
///
/// ```dart
/// MGScreenEffectsWrapper(
///   child: GameScreen(),
/// )
/// ```
class MGScreenEffectsWrapper extends StatefulWidget {
  final Widget child;

  const MGScreenEffectsWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MGScreenEffectsWrapper> createState() => _MGScreenEffectsWrapperState();
}

class _MGScreenEffectsWrapperState extends State<MGScreenEffectsWrapper> {
  late final MGScreenEffectsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MGScreenEffectsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    return MGScreenEffects(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          Widget result = child!;

          // 줌 효과
          if (_controller.zoomScale != 1.0 && !settings.reduceMotion) {
            result = Transform.scale(
              scale: _controller.zoomScale,
              child: result,
            );
          }

          // 쉐이크 효과
          if ((_controller.shakeOffsetX != 0 || _controller.shakeOffsetY != 0) &&
              !settings.reduceMotion) {
            result = Transform.translate(
              offset: Offset(_controller.shakeOffsetX, _controller.shakeOffsetY),
              child: result,
            );
          }

          // 플래시 효과
          if (_controller.flashOpacity > 0 && !settings.reduceMotion) {
            result = Stack(
              children: [
                result,
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _controller.flashOpacity,
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        color: _controller.flashColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return result;
        },
        child: widget.child,
      ),
    );
  }
}

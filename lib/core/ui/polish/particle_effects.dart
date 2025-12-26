import 'dart:math';
import 'package:flutter/material.dart';
import '../accessibility/accessibility_settings.dart';

/// 파티클 설정
class ParticleConfig {
  final Color color;
  final double size;
  final double speed;
  final double gravity;
  final double drag;
  final double lifespan;
  final bool fadeOut;
  final bool scaleDown;
  final bool rotate;

  const ParticleConfig({
    this.color = Colors.white,
    this.size = 8.0,
    this.speed = 200.0,
    this.gravity = 300.0,
    this.drag = 0.98,
    this.lifespan = 1.0,
    this.fadeOut = true,
    this.scaleDown = true,
    this.rotate = false,
  });

  ParticleConfig copyWith({
    Color? color,
    double? size,
    double? speed,
    double? gravity,
    double? drag,
    double? lifespan,
    bool? fadeOut,
    bool? scaleDown,
    bool? rotate,
  }) {
    return ParticleConfig(
      color: color ?? this.color,
      size: size ?? this.size,
      speed: speed ?? this.speed,
      gravity: gravity ?? this.gravity,
      drag: drag ?? this.drag,
      lifespan: lifespan ?? this.lifespan,
      fadeOut: fadeOut ?? this.fadeOut,
      scaleDown: scaleDown ?? this.scaleDown,
      rotate: rotate ?? this.rotate,
    );
  }
}

/// 개별 파티클
class Particle {
  Offset position;
  Offset velocity;
  double rotation;
  double rotationSpeed;
  double age;
  final double lifespan;
  final Color color;
  final double size;
  final double gravity;
  final double drag;
  final bool fadeOut;
  final bool scaleDown;
  final bool rotate;

  Particle({
    required this.position,
    required this.velocity,
    required this.lifespan,
    required this.color,
    required this.size,
    this.gravity = 300.0,
    this.drag = 0.98,
    this.fadeOut = true,
    this.scaleDown = true,
    this.rotate = false,
    this.rotation = 0,
    this.rotationSpeed = 0,
    this.age = 0,
  });

  bool get isDead => age >= lifespan;
  double get progress => (age / lifespan).clamp(0.0, 1.0);
  double get opacity => fadeOut ? (1.0 - progress) : 1.0;
  double get scale => scaleDown ? (1.0 - progress * 0.5) : 1.0;

  void update(double dt) {
    age += dt;
    velocity = Offset(velocity.dx * drag, velocity.dy * drag + gravity * dt);
    position += velocity * dt;
    if (rotate) {
      rotation += rotationSpeed * dt;
    }
  }
}

/// 파티클 시스템 컨트롤러
class MGParticleController extends ChangeNotifier {
  final List<Particle> _particles = [];
  bool _isRunning = false;

  List<Particle> get particles => List.unmodifiable(_particles);
  bool get isRunning => _isRunning;
  bool get hasParticles => _particles.isNotEmpty;

  /// 버스트 이미터 (한번에 많은 파티클)
  void burst({
    required Offset position,
    int count = 20,
    ParticleConfig config = const ParticleConfig(),
    double spreadAngle = 2 * pi,
    double startAngle = 0,
  }) {
    final random = Random();

    for (int i = 0; i < count; i++) {
      final angle = startAngle + (spreadAngle * i / count) - spreadAngle / 2;
      final speed = config.speed * (0.5 + random.nextDouble() * 0.5);
      final velocity = Offset(
        cos(angle) * speed,
        sin(angle) * speed,
      );

      _particles.add(Particle(
        position: position,
        velocity: velocity,
        lifespan: config.lifespan * (0.8 + random.nextDouble() * 0.4),
        color: config.color,
        size: config.size * (0.5 + random.nextDouble() * 0.5),
        gravity: config.gravity,
        drag: config.drag,
        fadeOut: config.fadeOut,
        scaleDown: config.scaleDown,
        rotate: config.rotate,
        rotationSpeed: config.rotate ? (random.nextDouble() - 0.5) * 10 : 0,
      ));
    }

    _isRunning = true;
    notifyListeners();
  }

  /// 분수형 이미터 (위로 솟구침)
  void fountain({
    required Offset position,
    int count = 30,
    ParticleConfig config = const ParticleConfig(),
    double spreadAngle = pi / 4,
  }) {
    burst(
      position: position,
      count: count,
      config: config.copyWith(gravity: config.gravity * 1.5),
      spreadAngle: spreadAngle,
      startAngle: -pi / 2, // 위쪽
    );
  }

  /// 폭발형 이미터 (사방으로)
  void explode({
    required Offset position,
    int count = 40,
    ParticleConfig config = const ParticleConfig(),
  }) {
    burst(
      position: position,
      count: count,
      config: config.copyWith(gravity: 0, drag: 0.95),
      spreadAngle: 2 * pi,
    );
  }

  /// 스파클 이미터 (반짝임)
  void sparkle({
    required Offset position,
    int count = 15,
    Color color = Colors.yellow,
  }) {
    burst(
      position: position,
      count: count,
      config: ParticleConfig(
        color: color,
        size: 4,
        speed: 100,
        gravity: 50,
        lifespan: 0.6,
        scaleDown: false,
      ),
      spreadAngle: 2 * pi,
    );
  }

  /// 히트 이펙트
  void hitEffect({
    required Offset position,
    Color color = Colors.white,
    bool isCritical = false,
  }) {
    final count = isCritical ? 30 : 15;
    final speed = isCritical ? 300.0 : 200.0;

    burst(
      position: position,
      count: count,
      config: ParticleConfig(
        color: color,
        size: isCritical ? 6 : 4,
        speed: speed,
        gravity: 200,
        lifespan: 0.4,
      ),
      spreadAngle: pi,
      startAngle: -pi / 2,
    );
  }

  /// 코인 이펙트
  void coinEffect({
    required Offset position,
    int count = 10,
  }) {
    fountain(
      position: position,
      count: count,
      config: const ParticleConfig(
        color: Colors.amber,
        size: 8,
        speed: 250,
        gravity: 400,
        lifespan: 0.8,
        rotate: true,
      ),
    );
  }

  /// 힐 이펙트 (위로 올라감)
  void healEffect({
    required Offset position,
    Color color = Colors.green,
  }) {
    burst(
      position: position,
      count: 20,
      config: ParticleConfig(
        color: color,
        size: 6,
        speed: 100,
        gravity: -150, // 위로
        lifespan: 1.0,
        scaleDown: false,
      ),
      spreadAngle: pi / 2,
      startAngle: -pi / 2,
    );
  }

  /// 업데이트 (매 프레임)
  void update(double dt) {
    for (final particle in _particles) {
      particle.update(dt);
    }

    _particles.removeWhere((p) => p.isDead);

    if (_particles.isEmpty) {
      _isRunning = false;
    }

    notifyListeners();
  }

  /// 모두 제거
  void clear() {
    _particles.clear();
    _isRunning = false;
    notifyListeners();
  }
}

/// 파티클 렌더러 위젯
class MGParticleRenderer extends StatefulWidget {
  final MGParticleController controller;
  final Widget child;

  const MGParticleRenderer({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<MGParticleRenderer> createState() => _MGParticleRendererState();
}

class _MGParticleRendererState extends State<MGParticleRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    );

    _ticker.addListener(_onTick);
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (widget.controller.isRunning && !_ticker.isAnimating) {
      _lastTime = 0;
      _ticker.forward(from: 0);
    } else if (!widget.controller.hasParticles && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  void _onTick() {
    final currentTime = _ticker.value * 365 * 24 * 60 * 60; // days to seconds
    final dt = _lastTime > 0 ? (currentTime - _lastTime).clamp(0.0, 0.1) : 0.016;
    _lastTime = currentTime;

    widget.controller.update(dt);
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    widget.controller.removeListener(_onControllerUpdate);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = MGAccessibilityProvider.settingsOf(context);

    if (settings.reduceMotion) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(widget.controller.particles),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 파티클 페인터
class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final scaledSize = particle.size * particle.scale;

      if (particle.rotate) {
        canvas.save();
        canvas.translate(particle.position.dx, particle.position.dy);
        canvas.rotate(particle.rotation);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: scaledSize, height: scaledSize),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(particle.position, scaledSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// 간편 파티클 오버레이 (MGScreenEffectsWrapper와 함께 사용)
class MGParticleOverlay extends StatefulWidget {
  final Widget child;

  const MGParticleOverlay({
    super.key,
    required this.child,
  });

  /// 가장 가까운 MGParticleOverlay의 컨트롤러 접근
  static MGParticleController? of(BuildContext context) {
    return context.findAncestorStateOfType<_MGParticleOverlayState>()?.controller;
  }

  @override
  State<MGParticleOverlay> createState() => _MGParticleOverlayState();
}

class _MGParticleOverlayState extends State<MGParticleOverlay> {
  final MGParticleController controller = MGParticleController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MGParticleRenderer(
      controller: controller,
      child: widget.child,
    );
  }
}

/// 프리셋 파티클 패턴
class ParticlePresets {
  ParticlePresets._();

  /// 화염 파티클
  static ParticleConfig fire = const ParticleConfig(
    color: Colors.orange,
    size: 10,
    speed: 150,
    gravity: -100, // 위로
    lifespan: 0.8,
    fadeOut: true,
  );

  /// 얼음 파티클
  static ParticleConfig ice = const ParticleConfig(
    color: Colors.lightBlueAccent,
    size: 6,
    speed: 100,
    gravity: 50,
    lifespan: 1.0,
    scaleDown: false,
  );

  /// 독 파티클
  static ParticleConfig poison = const ParticleConfig(
    color: Colors.green,
    size: 8,
    speed: 80,
    gravity: -50,
    lifespan: 1.2,
  );

  /// 번개 파티클
  static ParticleConfig lightning = const ParticleConfig(
    color: Colors.yellow,
    size: 4,
    speed: 400,
    gravity: 0,
    drag: 0.9,
    lifespan: 0.3,
    scaleDown: false,
  );

  /// 어둠 파티클
  static ParticleConfig dark = const ParticleConfig(
    color: Colors.purple,
    size: 8,
    speed: 60,
    gravity: -30,
    lifespan: 1.5,
  );

  /// 빛 파티클
  static ParticleConfig light = const ParticleConfig(
    color: Colors.white,
    size: 5,
    speed: 120,
    gravity: -80,
    lifespan: 0.6,
    scaleDown: false,
  );

  /// 피 파티클 (데미지)
  static ParticleConfig blood = const ParticleConfig(
    color: Colors.red,
    size: 6,
    speed: 200,
    gravity: 400,
    lifespan: 0.5,
  );

  /// 별 파티클 (보상)
  static ParticleConfig star = const ParticleConfig(
    color: Colors.amber,
    size: 8,
    speed: 180,
    gravity: 200,
    lifespan: 0.8,
    rotate: true,
  );
}

/// 연속 파티클 이미터 (불, 연기 등)
class MGContinuousEmitter extends StatefulWidget {
  final Offset position;
  final ParticleConfig config;
  final int particlesPerSecond;
  final bool enabled;
  final Widget child;

  const MGContinuousEmitter({
    super.key,
    required this.position,
    required this.config,
    this.particlesPerSecond = 10,
    this.enabled = true,
    required this.child,
  });

  @override
  State<MGContinuousEmitter> createState() => _MGContinuousEmitterState();
}

class _MGContinuousEmitterState extends State<MGContinuousEmitter>
    with SingleTickerProviderStateMixin {
  final MGParticleController _controller = MGParticleController();
  late AnimationController _ticker;
  double _accumulator = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_emit);

    if (widget.enabled) {
      _ticker.repeat();
    }
  }

  void _emit() {
    if (!widget.enabled) return;

    final dt = 1 / 60; // Assume 60fps
    _accumulator += dt * widget.particlesPerSecond;

    while (_accumulator >= 1) {
      _accumulator -= 1;
      _controller.burst(
        position: widget.position,
        count: 1,
        config: widget.config,
        spreadAngle: pi / 6,
        startAngle: -pi / 2,
      );
    }

    _controller.update(dt);
  }

  @override
  void didUpdateWidget(MGContinuousEmitter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isAnimating) {
      _ticker.repeat();
    } else if (!widget.enabled && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MGParticleRenderer(
      controller: _controller,
      child: widget.child,
    );
  }
}

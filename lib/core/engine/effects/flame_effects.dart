/// Flame Engine Effects Integration
/// Flame 엔진의 Effect/Particle 시스템을 활용한 게임 이펙트

import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;

/// ============================================================
/// Damage Number Component (Flame 기반)
/// ============================================================
class FlameDamageNumber extends TextComponent with HasGameRef {
  final int amount;
  final DamageNumberType type;
  final Color color;

  FlameDamageNumber({
    required this.amount,
    required Vector2 position,
    this.type = DamageNumberType.normal,
    Color? color,
  })  : color = color ?? _getDefaultColor(type),
        super(
          text: _formatAmount(amount, type),
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: _getFontSize(type),
              fontWeight: FontWeight.bold,
              color: color ?? _getDefaultColor(type),
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
              ],
            ),
          ),
        );

  static String _formatAmount(int amount, DamageNumberType type) {
    switch (type) {
      case DamageNumberType.heal:
        return '+$amount';
      case DamageNumberType.miss:
        return 'MISS';
      case DamageNumberType.blocked:
        return 'BLOCKED';
      default:
        return amount.toString();
    }
  }

  static double _getFontSize(DamageNumberType type) {
    switch (type) {
      case DamageNumberType.critical:
        return 32;
      case DamageNumberType.heal:
        return 24;
      case DamageNumberType.miss:
      case DamageNumberType.blocked:
        return 18;
      default:
        return 22;
    }
  }

  static Color _getDefaultColor(DamageNumberType type) {
    switch (type) {
      case DamageNumberType.critical:
        return Colors.yellow;
      case DamageNumberType.heal:
        return Colors.green;
      case DamageNumberType.weak:
        return Colors.grey;
      case DamageNumberType.miss:
        return Colors.white70;
      case DamageNumberType.blocked:
        return Colors.blueGrey;
      default:
        return Colors.white;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 위로 떠오르면서 페이드아웃
    final moveOffset = type == DamageNumberType.critical
        ? Vector2(0, -80)
        : Vector2(0, -50);

    add(MoveByEffect(
      moveOffset,
      EffectController(duration: 0.8, curve: Curves.easeOut),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 0.8, startDelay: 0.3),
    ));

    // 크리티컬은 스케일 효과 추가
    if (type == DamageNumberType.critical) {
      add(ScaleEffect.by(
        Vector2.all(1.3),
        EffectController(
          duration: 0.15,
          curve: Curves.easeOut,
          reverseDuration: 0.15,
          reverseDelay: 0,
        ),
      ));
    }

    // 자동 제거
    add(RemoveEffect(delay: 1.0));
  }
}

enum DamageNumberType { normal, critical, weak, heal, miss, blocked }

/// ============================================================
/// Particle Effect Component (Flame ParticleComponent 활용)
/// ============================================================
class FlameParticleEffect extends ParticleSystemComponent {
  FlameParticleEffect._({required super.particle});

  /// 히트 이펙트
  static FlameParticleEffect hit({
    required Vector2 position,
    Color color = Colors.white,
    bool isCritical = false,
  }) {
    final count = isCritical ? 30 : 15;
    final speed = isCritical ? 150.0 : 100.0;
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: count,
        lifespan: 0.5,
        generator: (i) {
          final angle = (i / count) * 2 * pi;
          final velocity = Vector2(cos(angle), sin(angle)) *
              (speed * (0.5 + random.nextDouble() * 0.5));

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 200), // 중력
            child: CircleParticle(
              radius: isCritical ? 4 : 3,
              paint: Paint()..color = color.withOpacity(0.8),
            ),
          );
        },
      ),
    );
  }

  /// 힐 이펙트 (위로 올라감)
  static FlameParticleEffect heal({
    required Vector2 position,
    Color color = Colors.green,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: 20,
        lifespan: 1.0,
        generator: (i) {
          final spreadX = (random.nextDouble() - 0.5) * 40;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(0, -80),
            acceleration: Vector2(0, -50), // 위로
            child: CircleParticle(
              radius: 3,
              paint: Paint()..color = color.withOpacity(0.7),
            ),
          );
        },
      ),
    );
  }

  /// 폭발 이펙트
  static FlameParticleEffect explosion({
    required Vector2 position,
    Color color = Colors.orange,
    double radius = 100,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: 50,
        lifespan: 0.8,
        generator: (i) {
          final angle = random.nextDouble() * 2 * pi;
          final speed = radius * (0.3 + random.nextDouble() * 0.7);
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 100),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = (1.0 - progress * 0.5) * 5;

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()
                    ..color = Color.lerp(color, Colors.red, progress)!
                        .withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 스파클 이펙트
  static FlameParticleEffect sparkle({
    required Vector2 position,
    Color color = Colors.yellow,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: 15,
        lifespan: 0.6,
        generator: (i) {
          final angle = random.nextDouble() * 2 * pi;
          final speed = 60 + random.nextDouble() * 40;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 50),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                final size = 3 * (1.0 - particle.progress * 0.5);

                // 별 모양
                final path = Path();
                for (int j = 0; j < 5; j++) {
                  final a = (j * 4 * pi / 5) - pi / 2;
                  final x = cos(a) * size;
                  final y = sin(a) * size;
                  if (j == 0) {
                    path.moveTo(x, y);
                  } else {
                    path.lineTo(x, y);
                  }
                }
                path.close();

                canvas.drawPath(
                  path,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 버프 적용 이펙트
  static FlameParticleEffect buff({
    required Vector2 position,
    Color color = Colors.blue,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: 12,
        lifespan: 0.8,
        generator: (i) {
          final startAngle = (i / 12) * 2 * pi;
          final startPos = Vector2(cos(startAngle), sin(startAngle)) * 30;

          return MovingParticle(
            from: position + startPos,
            to: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.5).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  4,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 디버프 적용 이펙트
  static FlameParticleEffect debuff({
    required Vector2 position,
    Color color = Colors.purple,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: 15,
        lifespan: 1.0,
        generator: (i) {
          final spreadX = (random.nextDouble() - 0.5) * 50;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, -30),
            speed: Vector2(0, 30),
            acceleration: Vector2(0, 20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  3,
                  Paint()..color = color.withOpacity(opacity * 0.7),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 코인 획득 이펙트
  static FlameParticleEffect coins({
    required Vector2 position,
    int count = 10,
  }) {
    final random = Random();

    return FlameParticleEffect._(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final angle = -pi / 2 + (random.nextDouble() - 0.5) * pi / 3;
          final speed = 150 + random.nextDouble() * 100;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 400), // 강한 중력
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.3).clamp(0.0, 1.0);
                final rotation = particle.progress * 4 * pi;

                canvas.save();
                canvas.rotate(rotation);

                // 코인 모양 (타원)
                canvas.drawOval(
                  const Rect.fromLTWH(-4, -3, 8, 6),
                  Paint()..color = Colors.amber.withOpacity(opacity),
                );
                canvas.drawOval(
                  const Rect.fromLTWH(-4, -3, 8, 6),
                  Paint()
                    ..color = Colors.orange.withOpacity(opacity)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1,
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// Timer Component (수동 타이머 대체)
/// ============================================================
class FlameTimer extends TimerComponent with HasGameRef {
  final void Function()? onTick;
  final void Function()? onComplete;
  final bool autoRemove;

  FlameTimer({
    required double period,
    this.onTick,
    this.onComplete,
    bool repeat = false,
    bool autoStart = true,
    this.autoRemove = true,
  }) : super(
          period: period,
          repeat: repeat,
          autoStart: autoStart,
          removeOnFinish: autoRemove,
        );

  @override
  void onTick() {
    super.onTick();
    onTick?.call();
  }

  @override
  void onRemove() {
    onComplete?.call();
    super.onRemove();
  }
}

/// ============================================================
/// Screen Shake Effect (카메라 기반)
/// ============================================================
class FlameScreenShake extends Effect with HasGameRef {
  final double intensity;
  final int shakeCount;
  Vector2 _originalPosition = Vector2.zero();

  FlameScreenShake({
    required double duration,
    this.intensity = 10.0,
    this.shakeCount = 10,
  }) : super(EffectController(duration: duration));

  @override
  void onStart() {
    super.onStart();
    if (gameRef.camera.viewfinder.children.isNotEmpty) {
      _originalPosition = gameRef.camera.viewfinder.position.clone();
    }
  }

  @override
  void apply(double progress) {
    if (!isMounted) return;

    final random = Random();
    final shake = (1.0 - progress) * intensity;
    final offsetX = (random.nextDouble() - 0.5) * 2 * shake;
    final offsetY = (random.nextDouble() - 0.5) * 2 * shake;

    gameRef.camera.viewfinder.position =
        _originalPosition + Vector2(offsetX, offsetY);
  }

  @override
  void onFinish() {
    super.onFinish();
    gameRef.camera.viewfinder.position = _originalPosition;
  }
}

/// ============================================================
/// Combo Text Component
/// ============================================================
class FlameComboText extends TextComponent {
  int _combo = 0;

  FlameComboText({
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

  void updateCombo(int combo) {
    _combo = combo;
    text = combo > 0 ? '$combo COMBO!' : '';

    // 색상 변경
    final color = combo >= 10
        ? Colors.red
        : combo >= 5
            ? Colors.orange
            : combo >= 3
                ? Colors.yellow
                : Colors.white;

    textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 24 + (combo * 0.5).clamp(0, 12),
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.5), blurRadius: 10),
        ],
      ),
    );

    // 펀치 효과
    if (combo > 0) {
      add(ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ));
    }
  }
}

/// ============================================================
/// Chain Trigger Effect Component
/// ============================================================
class FlameChainTrigger extends PositionComponent with HasGameRef {
  final String chainName;
  final Color chainColor;

  FlameChainTrigger({
    required this.chainName,
    required this.chainColor,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 텍스트 추가
    final triggerText = TextComponent(
      text: 'CHAIN TRIGGER!',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
          shadows: [Shadow(color: chainColor, blurRadius: 10)],
        ),
      ),
      position: Vector2(0, -20),
      anchor: Anchor.center,
    );

    final nameText = TextComponent(
      text: chainName,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: chainColor,
          letterSpacing: 2,
          shadows: [Shadow(color: chainColor, blurRadius: 15)],
        ),
      ),
      position: Vector2(0, 15),
      anchor: Anchor.center,
    );

    add(triggerText);
    add(nameText);

    // 스케일 인
    scale = Vector2.all(0.5);
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3, curve: Curves.elasticOut),
    ));

    // 페이드 아웃 후 제거
    add(SequenceEffect([
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 1.0),
      ),
      OpacityEffect.fadeOut(
        EffectController(duration: 0.3),
      ),
      RemoveEffect(),
    ]));
  }
}

/// ============================================================
/// Elemental Skill Effects (속성별 스킬 이펙트)
/// ============================================================

/// 속성 타입 정의
enum ElementType {
  fire,       // 화염
  ice,        // 얼음
  lightning,  // 번개
  earth,      // 대지
  wind,       // 바람
  water,      // 물
  light,      // 빛
  dark,       // 어둠
  poison,     // 독
  holy,       // 신성
}

/// 속성별 색상 팔레트
class ElementColors {
  static const Map<ElementType, List<Color>> palette = {
    ElementType.fire: [Colors.orange, Colors.red, Colors.yellow],
    ElementType.ice: [Colors.lightBlue, Colors.cyan, Colors.white],
    ElementType.lightning: [Colors.yellow, Colors.amber, Colors.white],
    ElementType.earth: [Colors.brown, Colors.orange, Colors.grey],
    ElementType.wind: [Colors.teal, Colors.cyan, Colors.white],
    ElementType.water: [Colors.blue, Colors.lightBlue, Colors.white],
    ElementType.light: [Colors.white, Colors.yellow, Colors.amber],
    ElementType.dark: [Colors.purple, Colors.deepPurple, Colors.black],
    ElementType.poison: [Colors.green, Colors.lime, Colors.purple],
    ElementType.holy: [Colors.amber, Colors.white, Colors.yellow],
  };

  static Color primary(ElementType type) => palette[type]![0];
  static Color secondary(ElementType type) => palette[type]![1];
  static Color accent(ElementType type) => palette[type]![2];
}

/// 속성별 스킬 이펙트 팩토리
class FlameElementalEffect {
  static final Random _random = Random();

  /// 화염 속성 - 불꽃이 위로 솟구침
  static ParticleSystemComponent fire({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (30 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 40 * intensity;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 30,
              -80 - _random.nextDouble() * 60,
            ),
            acceleration: Vector2(0, -50),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = (6 - progress * 4) * intensity;

                final color = Color.lerp(
                  Colors.orange,
                  Colors.red,
                  progress,
                )!;

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 얼음 속성 - 결정이 퍼지며 깨짐
  static ParticleSystemComponent ice({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (25 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.0,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 60 + _random.nextDouble() * 40;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed * intensity,
            acceleration: Vector2(0, 30),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 4 * intensity;

                // 다이아몬드/결정 모양
                final path = Path();
                path.moveTo(0, -size);
                path.lineTo(size * 0.6, 0);
                path.lineTo(0, size);
                path.lineTo(-size * 0.6, 0);
                path.close();

                canvas.drawPath(
                  path,
                  Paint()..color = Colors.lightBlue.withOpacity(opacity),
                );
                canvas.drawPath(
                  path,
                  Paint()
                    ..color = Colors.white.withOpacity(opacity * 0.5)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 번개 속성 - 빠르게 퍼지는 스파크
  static ParticleSystemComponent lightning({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (35 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.3,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 200 + _random.nextDouble() * 150;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed * intensity,
            acceleration: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);
                final size = 3 * intensity;

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = Colors.yellow.withOpacity(opacity),
                );

                // 글로우 효과
                canvas.drawCircle(
                  Offset.zero,
                  size * 2,
                  Paint()..color = Colors.white.withOpacity(opacity * 0.3),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 대지 속성 - 바위/먼지가 솟구침
  static ParticleSystemComponent earth({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (20 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.2,
        generator: (i) {
          final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 2;
          final speed = 80 + _random.nextDouble() * 60;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed * intensity,
            acceleration: Vector2(0, 300),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);
                final size = (5 + _random.nextDouble() * 4) * intensity;
                final rotation = particle.progress * 2 * pi;

                canvas.save();
                canvas.rotate(rotation);

                // 불규칙한 바위 모양
                final rect = Rect.fromCenter(
                  center: Offset.zero,
                  width: size,
                  height: size * 0.8,
                );

                canvas.drawRect(
                  rect,
                  Paint()..color = Colors.brown.withOpacity(opacity),
                );

                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }

  /// 바람 속성 - 소용돌이 효과
  static ParticleSystemComponent wind({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (40 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.0,
        generator: (i) {
          final startAngle = (i / count) * 2 * pi;

          return ComputedParticle(
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final angle = startAngle + progress * 4 * pi;
              final radius = (30 + progress * 50) * intensity;
              final x = cos(angle) * radius;
              final y = sin(angle) * radius * 0.5; // 타원형

              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final size = 3 * (1.0 - progress * 0.5);

              canvas.drawCircle(
                Offset(position.x + x, position.y + y),
                size,
                Paint()..color = Colors.teal.withOpacity(opacity * 0.7),
              );
            },
          );
        },
      ),
    );
  }

  /// 물 속성 - 물방울이 튀어오름
  static ParticleSystemComponent water({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (25 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.0,
        generator: (i) {
          final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 2;
          final speed = 100 + _random.nextDouble() * 80;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed * intensity,
            acceleration: Vector2(0, 250),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress * 0.7).clamp(0.0, 1.0);
                final size = 4 * intensity * (1.0 - progress * 0.3);

                // 물방울 모양 (원 + 꼬리)
                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = Colors.blue.withOpacity(opacity),
                );
                canvas.drawCircle(
                  Offset.zero,
                  size * 0.5,
                  Paint()..color = Colors.white.withOpacity(opacity * 0.5),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 빛 속성 - 방사형 광선
  static ParticleSystemComponent light({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (20 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / count) * 2 * pi;

          return ComputedParticle(
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final length = (50 + progress * 30) * intensity;

              final startX = cos(angle) * 10;
              final startY = sin(angle) * 10;
              final endX = cos(angle) * length;
              final endY = sin(angle) * length;

              canvas.drawLine(
                Offset(position.x + startX, position.y + startY),
                Offset(position.x + endX, position.y + endY),
                Paint()
                  ..color = Colors.amber.withOpacity(opacity)
                  ..strokeWidth = 3 * (1.0 - progress * 0.5),
              );
            },
          );
        },
      ),
    );
  }

  /// 어둠 속성 - 안으로 모이는 어둠
  static ParticleSystemComponent dark({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (30 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final startAngle = (i / count) * 2 * pi;
          final startRadius = 80 * intensity;
          final startPos = Vector2(cos(startAngle), sin(startAngle)) * startRadius;

          return MovingParticle(
            from: position + startPos,
            to: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = progress.clamp(0.0, 1.0);
                final size = 5 * intensity * (0.5 + progress * 0.5);

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = Colors.purple.withOpacity(opacity * 0.8),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 독 속성 - 기포처럼 올라오는 독
  static ParticleSystemComponent poison({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (20 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.2,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 50 * intensity;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(
              (_random.nextDouble() - 0.5) * 20,
              -40 - _random.nextDouble() * 30,
            ),
            acceleration: Vector2(0, -20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = (4 + progress * 3) * intensity;

                // 독 기포
                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = Colors.green.withOpacity(opacity * 0.7),
                );
                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()
                    ..color = Colors.lime.withOpacity(opacity * 0.5)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 신성 속성 - 빛나는 십자가/별
  static ParticleSystemComponent holy({
    required Vector2 position,
    double intensity = 1.0,
  }) {
    final count = (15 * intensity).toInt();

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.0,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 50 + _random.nextDouble() * 40;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed * intensity,
            acceleration: Vector2(0, -30),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 5 * intensity;

                // 십자 모양
                canvas.drawRect(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: size * 0.4,
                    height: size * 1.5,
                  ),
                  Paint()..color = Colors.amber.withOpacity(opacity),
                );
                canvas.drawRect(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: size * 1.5,
                    height: size * 0.4,
                  ),
                  Paint()..color = Colors.amber.withOpacity(opacity),
                );

                // 글로우
                canvas.drawCircle(
                  Offset.zero,
                  size * 1.5,
                  Paint()..color = Colors.white.withOpacity(opacity * 0.3),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 속성에 따른 이펙트 생성 헬퍼
  static ParticleSystemComponent byElement({
    required ElementType element,
    required Vector2 position,
    double intensity = 1.0,
  }) {
    switch (element) {
      case ElementType.fire:
        return fire(position: position, intensity: intensity);
      case ElementType.ice:
        return ice(position: position, intensity: intensity);
      case ElementType.lightning:
        return lightning(position: position, intensity: intensity);
      case ElementType.earth:
        return earth(position: position, intensity: intensity);
      case ElementType.wind:
        return wind(position: position, intensity: intensity);
      case ElementType.water:
        return water(position: position, intensity: intensity);
      case ElementType.light:
        return light(position: position, intensity: intensity);
      case ElementType.dark:
        return dark(position: position, intensity: intensity);
      case ElementType.poison:
        return poison(position: position, intensity: intensity);
      case ElementType.holy:
        return holy(position: position, intensity: intensity);
    }
  }
}

/// 공용 파티클 이펙트 프리셋
class FlameParticlePresets {
  static final Random _random = Random();

  /// 일반 버스트
  static ParticleSystemComponent burst({
    required Vector2 position,
    required Color color,
    int count = 20,
    double speed = 100,
    double lifespan = 0.6,
    double gravity = 150,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: lifespan,
        generator: (i) {
          final angle = (i / count) * 2 * pi;
          final velocity = Vector2(cos(angle), sin(angle)) *
              (speed * (0.5 + _random.nextDouble() * 0.5));

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, gravity),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 4 * (1.0 - progress * 0.5);

                canvas.drawCircle(
                  Offset.zero,
                  size,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 분수형 (위로 솟구침)
  static ParticleSystemComponent fountain({
    required Vector2 position,
    required Color color,
    int count = 25,
    double speed = 120,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 1.0,
        generator: (i) {
          final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 3;
          final vel = speed * (0.7 + _random.nextDouble() * 0.3);

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * vel,
            acceleration: Vector2(0, 300),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  4,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 반짝임 (별 모양)
  static ParticleSystemComponent sparkle({
    required Vector2 position,
    Color color = Colors.yellow,
    int count = 15,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.5,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 50 + _random.nextDouble() * 40;

          return AcceleratedParticle(
            position: position.clone(),
            speed: Vector2(cos(angle), sin(angle)) * speed,
            acceleration: Vector2(0, 40),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                final size = 3 * (1.0 - particle.progress * 0.5);

                // 4포인트 별
                final path = Path();
                for (int j = 0; j < 4; j++) {
                  final a = (j * pi / 2);
                  if (j == 0) {
                    path.moveTo(cos(a) * size, sin(a) * size);
                  } else {
                    path.lineTo(cos(a) * size, sin(a) * size);
                  }
                }
                path.close();

                canvas.drawPath(
                  path,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 모이는 효과
  static ParticleSystemComponent converge({
    required Vector2 position,
    required Color color,
    int count = 12,
    double radius = 50,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.5,
        generator: (i) {
          final startAngle = (i / count) * 2 * pi;
          final startPos = Vector2(cos(startAngle), sin(startAngle)) * radius;

          return MovingParticle(
            from: position + startPos,
            to: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.5).clamp(0.0, 1.0);

                canvas.drawCircle(
                  Offset.zero,
                  4,
                  Paint()..color = color.withOpacity(opacity),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// 바닥 원형 이펙트
  static ParticleSystemComponent groundCircle({
    required Vector2 position,
    required Color color,
    double maxRadius = 50,
  }) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 0.6,
        generator: (i) {
          return ComputedParticle(
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final radius = 15 + progress * maxRadius;

              canvas.drawCircle(
                Offset(position.x, position.y),
                radius,
                Paint()
                  ..color = color.withOpacity(opacity * 0.4)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3,
              );
            },
          );
        },
      ),
    );
  }
}

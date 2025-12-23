import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FloatingTextComponent extends TextComponent {
  final double lifeTime;
  double _timer = 0;

  FloatingTextComponent({
    required String text,
    required Vector2 position,
    this.lifeTime = 0.8,
    Color color = Colors.white,
    double fontSize = 24,
  }) : super(
          text: text,
          position: position,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  blurRadius: 2,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    if (isRemoved) return;
    super.update(dt);
    _timer += dt;

    // Move up
    position.y -= 100 * dt;

    if (_timer >= lifeTime) {
      removeFromParent();
    }
  }
}

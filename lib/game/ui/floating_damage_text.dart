import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

class FloatingDamageText extends GameComponent {
  final String text;
  final Color color;
  final bool isCritical;

  double _duration = 0.85;
  double _elapsed = 0.0;
  final Vector2 _velocity;

  FloatingDamageText({
    required Vector2 position,
    required this.text,
    required this.color,
    this.isCritical = false,
  }) : _velocity = Vector2(0, -38.0) {
    this.position = position.clone();
    size = Vector2(60, 24);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position += _velocity * dt;

    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final scale = isCritical ? (1.3 - 0.2 * progress) : 1.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale, scale);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: isCritical ? 14 : 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha * 0.8),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    canvas.restore();
  }
}

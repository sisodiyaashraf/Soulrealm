import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

/// Pyre component that the player needs to light in levels.
class PyreComponent extends GameComponent with Attackable {
  final int id;
  final VoidCallback onLit;
  bool isLit = false;
  final Sprite unlitSprite;
  double _time = 0.0;

  PyreComponent({
    required this.id,
    required Vector2 position,
    required this.onLit,
    required this.unlitSprite,
  }) {
    this.position = position;
    this.size = Vector2(64, 64);
    
    // Set up collision for the base of the pyre
    add(
      RectangleHitbox(
        size: Vector2(24, 16),
        position: Vector2(20, 36),
      ),
    );
  }

  void lightUp() {
    if (isLit) return;
    isLit = true;
    onLit();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    // Draw the static bowl/pedestal underneath
    unlitSprite.render(
      canvas,
      position: Vector2(0, 0),
      size: size,
    );

    if (isLit) {
      // Draw procedural animated flame on top of the bowl
      canvas.save();
      
      // Center of the bowl is roughly at x: 32, y: 26
      final cx = 32.0;
      final cy = 26.0;

      // Flame flicker calculation
      final pulse = math.sin(_time * 12.0) * 0.1 + 0.9;
      final wave = math.cos(_time * 8.0) * 2.0;

      // Draw flame glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.8),
            const Color(0xFFFF3D00).withOpacity(0.3),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 18 * pulse));
      canvas.drawCircle(Offset(cx, cy - 4), 18 * pulse, glowPaint);

      // Draw inner flame core
      final corePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFEA00),
            const Color(0xFFFF5722).withOpacity(0.1),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 8 * pulse));
      
      final flamePath = Path()
        ..moveTo(cx - 6 * pulse, cy)
        ..quadraticBezierTo(cx - 8 * pulse, cy - 14 * pulse, cx + wave, cy - 22 * pulse)
        ..quadraticBezierTo(cx + 8 * pulse, cy - 14 * pulse, cx + 6 * pulse, cy)
        ..close();
      canvas.drawPath(flamePath, corePaint);

      canvas.restore();
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (!isLit) {
      lightUp();
    }
  }
}

/// Portal component that triggers level completion or transitions.
class PortalComponent extends GameComponent with Sensor {
  final VoidCallback onTrigger;
  bool _triggered = false;
  bool isActive = false;
  double _time = 0.0;

  PortalComponent({
    required Vector2 position,
    required this.onTrigger,
    this.isActive = true,
  }) {
    this.position = position;
    this.size = Vector2(64, 64);
    
    // Setup overlapping area (sensor)
    add(
      RectangleHitbox(
        size: Vector2(32, 16),
        position: Vector2(16, 24),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isActive) {
      _time += dt;
    }
  }

  @override
  void onContact(GameComponent component) {
    if (!isActive || _triggered) return;
    if (component is Player) {
      _triggered = true;
      onTrigger();
    }
  }

  @override
  void render(Canvas canvas) {
    if (isActive) {
      canvas.save();
      final cx = size.x / 2;
      final cy = size.y / 2;

      // Draw background portal glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00E5FF).withOpacity(0.7),
            const Color(0xFF005B9F).withOpacity(0.3),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 24));
      canvas.drawOval(Rect.fromLTRB(cx - 24, cy - 12, cx + 24, cy + 12), glowPaint);

      // Draw swirling portal rings
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw rotating/swirling segments
      for (int i = 0; i < 3; i++) {
        final angleOffset = _time * 2.5 + (i * math.pi / 1.5);
        final radiusOffset = 4.0 * math.sin(_time * 4.0 + i);
        canvas.drawArc(
          Rect.fromLTRB(cx - 18 - radiusOffset, cy - 9 - radiusOffset / 2, cx + 18 + radiusOffset, cy + 9 + radiusOffset / 2),
          angleOffset,
          1.5,
          false,
          ringPaint,
        );
      }

      canvas.restore();
    }
  }
}

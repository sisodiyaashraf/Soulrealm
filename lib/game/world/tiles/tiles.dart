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
    required Vector2 initialPosition,
    required this.onLit,
    required this.unlitSprite,
  }) {
    position = initialPosition;
    size = Vector2(64, 64);
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(64, 64);
    add(
      RectangleHitbox(
        size: Vector2(24, 16),
        position: Vector2(20, 36),
      ),
    );
    await super.onLoad();
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
      position: Vector2.zero(),
      size: Vector2(64, 64),
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
            const Color(0xFFFFA726).withValues(alpha: 0.8),
            const Color(0xFFFF3D00).withValues(alpha: 0.3),
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
            const Color(0xFFFF5722).withValues(alpha: 0.1),
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
    required Vector2 initialPosition,
    required this.onTrigger,
    this.isActive = true,
  }) {
    position = initialPosition;
    size = Vector2(64, 64);
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(64, 64);
    add(
      RectangleHitbox(
        size: Vector2(32, 16),
        position: Vector2(16, 24),
      ),
    );
    await super.onLoad();
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
    final cx = size.x / 2;
    final cy = size.y / 2;
    if (isActive) {
      canvas.save();

      // Draw background portal glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.7),
            const Color(0xFF005B9F).withValues(alpha: 0.3),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 24));
      canvas.drawOval(Rect.fromLTRB(cx - 24, cy - 12, cx + 24, cy + 12), glowPaint);

      // Draw swirling portal rings
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
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
    } else {
      // Draw dimmed, locked visual state (faint grey oval with center lock icon dot)
      final lockPaint = Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(Rect.fromLTRB(cx - 16, cy - 8, cx + 16, cy + 8), lockPaint);

      final dotPaint = Paint()..color = Colors.white12;
      canvas.drawCircle(Offset(cx, cy), 2, dotPaint);
    }
  }
}

/// A glowing restorative fountain in the overworld that replenishes player health.
class SanctuaryFountain extends GameComponent with Sensor {
  final VoidCallback onHeal;
  double _healCooldown = 0.0;
  double _time = 0.0;

  SanctuaryFountain({
    required Vector2 initialPosition,
    required this.onHeal,
  }) {
    position = initialPosition;
    size = Vector2(64, 64);
  }

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(32, 24),
        position: Vector2(16, 20),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_healCooldown > 0) {
      _healCooldown -= dt;
    }
  }

  @override
  void onContact(GameComponent component) {
    if (component is Player && _healCooldown <= 0) {
      _healCooldown = 3.0;
      onHeal();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Glowing holy/arcane spring pool
    final poolPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.8),
          const Color(0xFF00796B).withValues(alpha: 0.4),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 20));
    canvas.drawOval(Rect.fromLTRB(cx - 20, cy - 10, cx + 20, cy + 10), poolPaint);

    // Floating water ripple
    final ripple = (math.sin(_time * 4.0) + 1.0) * 0.5;
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * (1.0 - ripple))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(Rect.fromLTRB(cx - 16 * ripple, cy - 8 * ripple, cx + 16 * ripple, cy + 8 * ripple), ripplePaint);
  }
}

/// An ancient monolith with arcane engravings that reveals dark fantasy lore.
class LoreObelisk extends GameComponent with Sensor {
  final VoidCallback onRead;
  double _triggerCooldown = 0.0;
  double _time = 0.0;

  LoreObelisk({
    required Vector2 initialPosition,
    required this.onRead,
  }) {
    position = initialPosition;
    size = Vector2(64, 64);
  }

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(28, 20),
        position: Vector2(18, 24),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_triggerCooldown > 0) {
      _triggerCooldown -= dt;
    }
  }

  @override
  void onContact(GameComponent component) {
    if (component is Player && _triggerCooldown <= 0) {
      _triggerCooldown = 5.0;
      onRead();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Obelisk stone pillar
    final stonePath = Path()
      ..moveTo(cx, cy - 20)
      ..lineTo(cx + 8, cy - 14)
      ..lineTo(cx + 6, cy + 16)
      ..lineTo(cx - 6, cy + 16)
      ..lineTo(cx - 8, cy - 14)
      ..close();

    final stonePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF37474F), const Color(0xFF102027)],
      ).createShader(Rect.fromLTWH(cx - 8, cy - 20, 16, 36));
    canvas.drawPath(stonePath, stonePaint);

    // Glowing ancient rune
    final pulse = (math.sin(_time * 3.0) + 1.0) * 0.5;
    final runePaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.4 + 0.5 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 8), runePaint);
    canvas.drawCircle(Offset(cx, cy - 4), 3, runePaint);
  }
}


import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TilesetGenerator {
  /// Generates a 128x128 tileset image in memory containing 4 tiles (64x64 each).
  /// Row 0: Floor (0, 0), Wall (64, 0)
  /// Row 1: Pyre/Torch (0, 64), Portal (64, 64)
  static Future<ui.Image> generate() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 128));

    // Clear background
    final bgPaint = Paint()..color = const Color(0x00000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 128), bgPaint);

    // ==========================================
    // Tile 1: Floor (x: 0-64, y: 0-64)
    // ==========================================
    _drawFloorTile(canvas, 0, 0);

    // ==========================================
    // Tile 2: Wall / Pillar (x: 64-128, y: 0-64)
    // ==========================================
    _drawWallTile(canvas, 64, 0);

    // ==========================================
    // Tile 3: Pyre / Pillar (x: 0-64, y: 64-128)
    // ==========================================
    _drawPyreTile(canvas, 0, 64);

    // ==========================================
    // Tile 4: Portal (x: 64-128, y: 64-128)
    // ==========================================
    _drawPortalTile(canvas, 64, 64);

    final picture = recorder.endRecording();
    return await picture.toImage(128, 128);
  }

  static void _drawFloorTile(Canvas canvas, double ox, double oy) {
    final path = Path()
      ..moveTo(ox + 32, oy + 16) // Top
      ..lineTo(ox + 64, oy + 32) // Right
      ..lineTo(ox + 32, oy + 48) // Bottom
      ..lineTo(ox, oy + 32) // Left
      ..close();

    // Fill with gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(Offset(ox + 32, oy + 32), 24, [
        const Color(0xFF1B1E36),
        const Color(0xFF0C0E1A),
      ]);
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF3B487A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // Subtle runic groove
    final groovePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final groovePath = Path()
      ..moveTo(ox + 32, oy + 24)
      ..lineTo(ox + 48, oy + 32)
      ..lineTo(ox + 32, oy + 40)
      ..lineTo(ox + 16, oy + 32)
      ..close();
    canvas.drawPath(groovePath, groovePaint);
  }

  static void _drawWallTile(Canvas canvas, double ox, double oy) {
    // A vertical pillar with isometric top and faces

    // Top cap (top diamond, shifted up)
    final topPath = Path()
      ..moveTo(ox + 32, oy + 8)
      ..lineTo(ox + 64, oy + 20)
      ..lineTo(ox + 32, oy + 32)
      ..lineTo(ox, oy + 20)
      ..close();

    // Draw left face
    final leftFace = Path()
      ..moveTo(ox, oy + 20)
      ..lineTo(ox + 32, oy + 32)
      ..lineTo(ox + 32, oy + 64)
      ..lineTo(ox, oy + 56)
      ..close();

    // Draw right face
    final rightFace = Path()
      ..moveTo(ox + 32, oy + 32)
      ..lineTo(ox + 64, oy + 20)
      ..lineTo(ox + 64, oy + 56)
      ..lineTo(ox + 32, oy + 64)
      ..close();

    // Paint left face
    final leftPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(ox, oy + 20),
        Offset(ox + 32, oy + 64),
        [const Color(0xFF1D2030), const Color(0xFF0F101A)],
      );
    canvas.drawPath(leftFace, leftPaint);

    // Paint right face (slightly lighter for lighting)
    final rightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(ox + 32, oy + 32),
        Offset(ox + 64, oy + 64),
        [const Color(0xFF2C324D), const Color(0xFF181C2E)],
      );
    canvas.drawPath(rightFace, rightPaint);

    // Paint top cap
    final topPaint = Paint()
      ..shader = ui.Gradient.radial(Offset(ox + 32, oy + 20), 20, [
        const Color(0xFF3D4770),
        const Color(0xFF222740),
      ]);
    canvas.drawPath(topPath, topPaint);

    // Glowing glyph in the center of faces
    final glyphPaint = Paint()
      ..color = const Color(0xFFFF2A85).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(ox + 16, oy + 36),
      Offset(ox + 16, oy + 48),
      glyphPaint,
    );
    canvas.drawLine(
      Offset(ox + 48, oy + 36),
      Offset(ox + 48, oy + 48),
      glyphPaint,
    );

    // Outer outlines
    final outlinePaint = Paint()
      ..color = const Color(0xFF4C5894)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topPath, outlinePaint);
    canvas.drawPath(leftFace, outlinePaint);
    canvas.drawPath(rightFace, outlinePaint);
  }

  static void _drawPyreTile(Canvas canvas, double ox, double oy) {
    // Draws a low pedestal floor tile (for Pyre)
    _drawFloorTile(canvas, ox, oy);

    // Draw a small central bowl/pedestal on top of it
    final pedestalBase = Path()
      ..moveTo(ox + 32, oy + 36)
      ..lineTo(ox + 44, oy + 42)
      ..lineTo(ox + 32, oy + 48)
      ..lineTo(ox + 20, oy + 42)
      ..close();

    final pedestalTop = Path()
      ..moveTo(ox + 32, oy + 24)
      ..lineTo(ox + 42, oy + 29)
      ..lineTo(ox + 32, oy + 34)
      ..lineTo(ox + 22, oy + 29)
      ..close();

    final pedPaint = Paint()..color = const Color(0xFF1E223D);
    canvas.drawPath(pedestalBase, pedPaint);

    final pedTopPaint = Paint()..color = const Color(0xFF343B66);
    canvas.drawPath(pedestalTop, pedTopPaint);

    // Draw iron legs linking base and top
    final ironPaint = Paint()
      ..color = const Color(0xFF0F1122)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(ox + 20, oy + 42),
      Offset(ox + 22, oy + 29),
      ironPaint,
    );
    canvas.drawLine(
      Offset(ox + 44, oy + 42),
      Offset(ox + 42, oy + 29),
      ironPaint,
    );
  }

  static void _drawPortalTile(Canvas canvas, double ox, double oy) {
    // Dynamic circular glowing portal
    _drawFloorTile(canvas, ox, oy);

    // swirly portal circles
    final portalPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(ox + 32, oy + 32),
        16,
        [
          const Color(0xFF00E5FF),
          const Color(0xFF005B9F).withValues(alpha: 0.5),
          const Color(0x00000000),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawOval(
      Rect.fromLTRB(ox + 16, oy + 24, ox + 48, oy + 40),
      portalPaint,
    );

    final swirlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromLTRB(ox + 20, oy + 26, ox + 44, oy + 38),
      0,
      1.5,
      false,
      swirlPaint,
    );
    canvas.drawArc(
      Rect.fromLTRB(ox + 20, oy + 26, ox + 44, oy + 38),
      3.14,
      1.5,
      false,
      swirlPaint,
    );
  }

  /// Generates a player sprite sheet (128x64 px).
  /// Row 0: Idle (4 frames, 32x32 each)
  /// Row 1: Walk (4 frames, 32x32 each)
  static Future<ui.Image> generatePlayer() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 64));

    // Clear bg
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 128, 64),
      Paint()..color = const Color(0x00000000),
    );

    // Draw 4 frames of idle (Row 0, y=0)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 0.0;
      // Floating offset
      double floatY = (i == 0 || i == 2) ? 0.0 : (i == 1 ? -2.0 : 2.0);
      _drawSpirit(
        canvas,
        ox + 16,
        oy + 16 + floatY,
        const Color(0xFF00E5FF),
        const Color(0xFF005B9F),
      );
    }

    // Draw 4 frames of walk (Row 1, y=32)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 32.0;
      double floatY = (i % 2 == 0) ? -1.0 : 1.0;
      // Walk has a trailing spirit tail
      _drawSpirit(
        canvas,
        ox + 16,
        oy + 16 + floatY,
        const Color(0xFF00E5FF),
        const Color(0xFF005B9F),
        walkFrame: i,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 64);
  }

  /// Generates a shadow enemy sprite sheet (128x64 px).
  /// Row 0: Idle (4 frames, 32x32 each)
  /// Row 1: Walk (4 frames, 32x32 each)
  static Future<ui.Image> generateEnemy() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 64));

    // Clear bg
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 128, 64),
      Paint()..color = const Color(0x00000000),
    );

    // Draw 4 frames of idle (Row 0, y=0)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 0.0;
      double floatY = (i == 0 || i == 2) ? 0.0 : (i == 1 ? -1.5 : 1.5);
      _drawSpirit(
        canvas,
        ox + 16,
        oy + 16 + floatY,
        const Color(0xFFFF2A85),
        const Color(0xFF5F0033),
      );
    }

    // Draw 4 frames of walk (Row 1, y=32)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 32.0;
      double floatY = (i % 2 == 0) ? -1.0 : 1.0;
      _drawSpirit(
        canvas,
        ox + 16,
        oy + 16 + floatY,
        const Color(0xFFFF2A85),
        const Color(0xFF5F0033),
        walkFrame: i,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 64);
  }

  static void _drawSpirit(
    Canvas canvas,
    double cx,
    double cy,
    Color primary,
    Color secondary, {
    int? walkFrame,
  }) {
    // Body (glowing droplet shape)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        12,
        [primary, secondary.withValues(alpha: 0.3), const Color(0x00000000)],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), 12, glowPaint);

    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, cy - 8), Offset(cx, cy + 8), [
        Colors.white,
        primary,
      ]);

    // Main circular head/hood
    canvas.drawCircle(Offset(cx, cy - 2), 6, bodyPaint);

    // Glowing eyes (two tiny dots)
    final eyePaint = Paint()..color = Colors.white;
    if (walkFrame != null && walkFrame % 2 == 0) {
      canvas.drawCircle(Offset(cx - 2, cy - 3), 1, eyePaint);
      canvas.drawCircle(Offset(cx + 2, cy - 3), 1, eyePaint);
    } else {
      canvas.drawCircle(Offset(cx - 2, cy - 2), 1, eyePaint);
      canvas.drawCircle(Offset(cx + 2, cy - 2), 1, eyePaint);
    }

    // Drawing tail
    final tailPath = Path();
    tailPath.moveTo(cx - 4, cy + 2);
    tailPath.quadraticBezierTo(
      cx + (walkFrame != null ? (walkFrame % 2 == 0 ? 6 : -6) : 0),
      cy + 12,
      cx,
      cy + 14,
    );
    tailPath.quadraticBezierTo(
      cx - (walkFrame != null ? (walkFrame % 2 == 0 ? 2 : -2) : 0),
      cy + 10,
      cx + 4,
      cy + 2,
    );
    tailPath.close();

    final tailPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, cy), Offset(cx, cy + 12), [
        primary,
        secondary.withValues(alpha: 0.1),
      ]);
    canvas.drawPath(tailPath, tailPaint);
  }

  /// Generates a Void Caster (ranged sorcerer) sprite sheet (128x64 px).
  /// Row 0: Idle (4 frames, 32x32)
  /// Row 1: Walk (4 frames, 32x32)
  static Future<ui.Image> generateVoidCaster() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 64));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 64), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 0.0;
      double floatY = (i % 2 == 0) ? 0.0 : -2.0;
      _drawCaster(canvas, ox + 16, oy + 16 + floatY, frame: i);
    }
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 32.0;
      double floatY = (i % 2 == 0) ? -1.0 : 1.5;
      _drawCaster(canvas, ox + 16, oy + 16 + floatY, frame: i, isWalk: true);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 64);
  }

  static void _drawCaster(Canvas canvas, double cx, double cy, {int frame = 0, bool isWalk = false}) {
    // Aura
    final aura = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        14,
        [const Color(0xFFBA68C8), const Color(0xFF4A148C).withValues(alpha: 0.2), const Color(0x00000000)],
      );
    canvas.drawCircle(Offset(cx, cy), 14, aura);

    // Occult robe/body
    final robePath = Path()
      ..moveTo(cx, cy - 8)
      ..lineTo(cx + 7, cy + 10)
      ..lineTo(cx - 7, cy + 10)
      ..close();
    final robePaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, cy - 8), Offset(cx, cy + 10), [
        const Color(0xFF311B92),
        const Color(0xFF1A0A3A),
      ]);
    canvas.drawPath(robePath, robePaint);

    // Glowing one-eyed occult mask
    final eyePaint = Paint()..color = const Color(0xFFFF4081);
    canvas.drawCircle(Offset(cx, cy - 2), 2.5, eyePaint);
    canvas.drawCircle(Offset(cx, cy - 2), 1.0, Paint()..color = Colors.white);

    // Floating dark crystal above head
    final crystalY = cy - 12 + (frame % 2 == 0 ? 0.0 : -1.5);
    final crystalPath = Path()
      ..moveTo(cx, crystalY - 3)
      ..lineTo(cx + 2.5, crystalY)
      ..lineTo(cx, crystalY + 3)
      ..lineTo(cx - 2.5, crystalY)
      ..close();
    canvas.drawPath(crystalPath, Paint()..color = const Color(0xFFE040FB));
  }

  /// Generates the Stage 5 Void Warden Boss sprite sheet (192x96 px).
  /// Row 0: Idle (4 frames, 48x48)
  /// Row 1: Attack / Channel (4 frames, 48x48)
  static Future<ui.Image> generateVoidWarden() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 192, 96));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 192, 96), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double ox = i * 48.0;
      double oy = 0.0;
      double floatY = (i % 2 == 0) ? 0.0 : -3.0;
      _drawBoss(canvas, ox + 24, oy + 24 + floatY, frame: i, isAttacking: false);
    }
    for (int i = 0; i < 4; i++) {
      double ox = i * 48.0;
      double oy = 48.0;
      _drawBoss(canvas, ox + 24, oy + 24, frame: i, isAttacking: true);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(192, 96);
  }

  static void _drawBoss(Canvas canvas, double cx, double cy, {int frame = 0, bool isAttacking = false}) {
    // Massive Dark Pulsing Aura
    final auraRadius = isAttacking ? 22.0 : 18.0;
    final aura = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        auraRadius,
        [
          const Color(0xFFFF1744).withValues(alpha: 0.8),
          const Color(0xFF651FFF).withValues(alpha: 0.4),
          const Color(0x00000000),
        ],
      );
    canvas.drawCircle(Offset(cx, cy), auraRadius, aura);

    // Armored Archon Body
    final bodyPath = Path()
      ..moveTo(cx, cy - 14)
      ..lineTo(cx + 12, cy - 4)
      ..lineTo(cx + 10, cy + 14)
      ..lineTo(cx, cy + 18)
      ..lineTo(cx - 10, cy + 14)
      ..lineTo(cx - 12, cy - 4)
      ..close();
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, cy - 14), Offset(cx, cy + 18), [
        const Color(0xFF212121),
        const Color(0xFF0D0814),
      ]);
    canvas.drawPath(bodyPath, bodyPaint);

    // Large Demonic Horns
    final hornPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(cx - 6, cy - 12), Offset(cx - 16, cy - 20), hornPaint);
    canvas.drawLine(Offset(cx + 6, cy - 12), Offset(cx + 16, cy - 20), hornPaint);

    // Core Heart Eye / Void Rift
    final coreGlow = Paint()
      ..shader = ui.Gradient.radial(Offset(cx, cy), 6, [
        Colors.white,
        isAttacking ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
        const Color(0x00000000),
      ]);
    canvas.drawCircle(Offset(cx, cy), 6, coreGlow);

    // Claw Wings
    final wingPaint = Paint()
      ..color = const Color(0xFF4A148C).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx - 20, cy + (frame % 2 == 0 ? -4 : 4)), wingPaint);
    canvas.drawLine(Offset(cx + 12, cy), Offset(cx + 20, cy + (frame % 2 == 0 ? -4 : 4)), wingPaint);
  }

  /// Generates the Soul Bolt projectile sprite sheet (128x32 px, 4 frames of 32x32).
  static Future<ui.Image> generateSoulBolt() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 32));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 32), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double cx = i * 32.0 + 16.0;
      double cy = 16.0;

      // Outer glow
      final glow = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), 12, [
          const Color(0xFF00E5FF),
          const Color(0xFF005B9F).withValues(alpha: 0.3),
          const Color(0x00000000),
        ]);
      canvas.drawCircle(Offset(cx, cy), 12, glow);

      // Trailing tail
      final tail = Path()
        ..moveTo(cx - 10, cy)
        ..lineTo(cx, cy - 4)
        ..lineTo(cx + 6, cy)
        ..lineTo(cx, cy + 4)
        ..close();
      canvas.drawPath(tail, Paint()..color = const Color(0xFF00E5FF));

      // Core
      canvas.drawCircle(Offset(cx + 2, cy), 4, Paint()..color = Colors.white);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 32);
  }

  /// Generates the Void Orb projectile sprite sheet (128x32 px, 4 frames of 32x32).
  static Future<ui.Image> generateVoidOrb() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 32));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 32), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double cx = i * 32.0 + 16.0;
      double cy = 16.0;

      final aura = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), 12, [
          const Color(0xFFFF1744),
          const Color(0xFF4A148C).withValues(alpha: 0.4),
          const Color(0x00000000),
        ]);
      canvas.drawCircle(Offset(cx, cy), 12, aura);

      // Dark core
      canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFF260633));
      canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = const Color(0xFFFF4081));
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 32);
  }

  /// Generates the Soul Shard collectible sprite sheet (128x32 px, 4 frames of 32x32).
  static Future<ui.Image> generateSoulShard() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 32));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 32), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double cx = i * 32.0 + 16.0;
      double cy = 16.0;

      // Glow halo
      final glow = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), 10, [
          const Color(0xFF00E5FF).withValues(alpha: 0.7),
          const Color(0x00000000),
        ]);
      canvas.drawCircle(Offset(cx, cy), 10, glow);

      // Diamond crystal width oscillates for 3D rotation effect
      double w = [6.0, 3.5, 6.0, 3.5][i];
      final diamond = Path()
        ..moveTo(cx, cy - 8)
        ..lineTo(cx + w, cy)
        ..lineTo(cx, cy + 8)
        ..lineTo(cx - w, cy)
        ..close();

      final gemPaint = Paint()
        ..shader = ui.Gradient.linear(Offset(cx, cy - 8), Offset(cx, cy + 8), [
          Colors.white,
          const Color(0xFF00E5FF),
          const Color(0xFF0072BB),
        ]);
      canvas.drawPath(diamond, gemPaint);

      // Specular highlight glint
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(cx - 1, cy - 3), 1.2, Paint()..color = Colors.white);
      }
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 32);
  }

  /// Generates the Melee Slash arc animation sprite sheet (128x32 px, 4 frames of 32x32).
  static Future<ui.Image> generateSlashEffect() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 32));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 32), Paint()..color = const Color(0x00000000));

    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double cx = ox + 16.0;
      double cy = 16.0;
      double radius = 10.0 + i * 2.0;

      final slashPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 1.0 - (i * 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 - (i * 0.5)
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -0.8 + i * 0.2,
        1.6,
        false,
        slashPaint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 32);
  }
}

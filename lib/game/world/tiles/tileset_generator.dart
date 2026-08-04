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
      ..moveTo(ox + 32, oy + 16)  // Top
      ..lineTo(ox + 64, oy + 32)  // Right
      ..lineTo(ox + 32, oy + 48)  // Bottom
      ..lineTo(ox, oy + 32)       // Left
      ..close();

    // Fill with gradient
    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(ox + 32, oy + 32),
        24,
        [
          const Color(0xFF1B1E36),
          const Color(0xFF0C0E1A),
        ],
      );
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF3B487A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // Subtle runic groove
    final groovePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.3)
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
    // Floor footprint (bottom diamond)
    final bottomPath = Path()
      ..moveTo(ox + 32, oy + 48)
      ..lineTo(ox + 64, oy + 56)
      ..lineTo(ox + 32, oy + 64)
      ..lineTo(ox, oy + 56)
      ..close();

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
        [
          const Color(0xFF1D2030),
          const Color(0xFF0F101A),
        ],
      );
    canvas.drawPath(leftFace, leftPaint);

    // Paint right face (slightly lighter for lighting)
    final rightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(ox + 32, oy + 32),
        Offset(ox + 64, oy + 64),
        [
          const Color(0xFF2C324D),
          const Color(0xFF181C2E),
        ],
      );
    canvas.drawPath(rightFace, rightPaint);

    // Paint top cap
    final topPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(ox + 32, oy + 20),
        20,
        [
          const Color(0xFF3D4770),
          const Color(0xFF222740),
        ],
      );
    canvas.drawPath(topPath, topPaint);

    // Glowing glyph in the center of faces
    final glyphPaint = Paint()
      ..color = const Color(0xFFFF2A85).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(ox + 16, oy + 36), Offset(ox + 16, oy + 48), glyphPaint);
    canvas.drawLine(Offset(ox + 48, oy + 36), Offset(ox + 48, oy + 48), glyphPaint);

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
    canvas.drawLine(Offset(ox + 20, oy + 42), Offset(ox + 22, oy + 29), ironPaint);
    canvas.drawLine(Offset(ox + 44, oy + 42), Offset(ox + 42, oy + 29), ironPaint);
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
          const Color(0xFF005B9F).withOpacity(0.5),
          const Color(0x00000000),
        ],
      );
    canvas.drawOval(Rect.fromLTRB(ox + 16, oy + 24, ox + 48, oy + 40), portalPaint);

    final swirlPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
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
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 64), Paint()..color = const Color(0x00000000));

    // Draw 4 frames of idle (Row 0, y=0)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 0.0;
      // Floating offset
      double floatY = (i == 0 || i == 2) ? 0.0 : (i == 1 ? -2.0 : 2.0);
      _drawSpirit(canvas, ox + 16, oy + 16 + floatY, const Color(0xFF00E5FF), const Color(0xFF005B9F));
    }

    // Draw 4 frames of walk (Row 1, y=32)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 32.0;
      double floatY = (i % 2 == 0) ? -1.0 : 1.0;
      // Walk has a trailing spirit tail
      _drawSpirit(canvas, ox + 16, oy + 16 + floatY, const Color(0xFF00E5FF), const Color(0xFF005B9F), walkFrame: i);
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
    canvas.drawRect(const Rect.fromLTWH(0, 0, 128, 64), Paint()..color = const Color(0x00000000));

    // Draw 4 frames of idle (Row 0, y=0)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 0.0;
      double floatY = (i == 0 || i == 2) ? 0.0 : (i == 1 ? -1.5 : 1.5);
      _drawSpirit(canvas, ox + 16, oy + 16 + floatY, const Color(0xFFFF2A85), const Color(0xFF5F0033));
    }

    // Draw 4 frames of walk (Row 1, y=32)
    for (int i = 0; i < 4; i++) {
      double ox = i * 32.0;
      double oy = 32.0;
      double floatY = (i % 2 == 0) ? -1.0 : 1.0;
      _drawSpirit(canvas, ox + 16, oy + 16 + floatY, const Color(0xFFFF2A85), const Color(0xFF5F0033), walkFrame: i);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(128, 64);
  }

  static void _drawSpirit(Canvas canvas, double cx, double cy, Color primary, Color secondary, {int? walkFrame}) {
    // Body (glowing droplet shape)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        12,
        [
          primary,
          secondary.withOpacity(0.3),
          const Color(0x00000000),
        ],
      );
    canvas.drawCircle(Offset(cx, cy), 12, glowPaint);

    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, cy - 8),
        Offset(cx, cy + 8),
        [
          Colors.white,
          primary,
        ],
      );
    
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
      ..shader = ui.Gradient.linear(
        Offset(cx, cy),
        Offset(cx, cy + 12),
        [
          primary,
          secondary.withOpacity(0.1),
        ],
      );
    canvas.drawPath(tailPath, tailPaint);
  }
}

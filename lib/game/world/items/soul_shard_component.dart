import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/services.dart';

class SoulShardComponent extends GameComponent {
  final VoidCallback onCollected;
  final SpriteAnimation animation;
  final int value;
  
  double _time = 0.0;
  bool _collected = false;
  double _currentSpeed = 60.0;

  SoulShardComponent({
    required Vector2 position,
    required this.animation,
    required this.onCollected,
    this.value = 1,
  }) {
    this.position = position;
    size = Vector2(24, 24);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    _time += dt;

    // Check proximity to player
    final player = gameRef.player;
    if (player != null) {
      final playerCenter = player.position + (player.size / 2);
      final shardCenter = position + (size / 2);
      final dist = shardCenter.distanceTo(playerCenter);

      // Collect when touched
      if (dist < 18.0) {
        _collected = true;
        HapticFeedback.lightImpact();
        onCollected();
        removeFromParent();
        return;
      }

      // Magnet attraction towards player when within 70 pixels
      if (dist < 70.0) {
        _currentSpeed = math.min(_currentSpeed + 200.0 * dt, 240.0);
        final dir = (playerCenter - shardCenter).normalized();
        position += dir * (_currentSpeed * dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Floating sine wave offset
    final bob = math.sin(_time * 4.0) * 2.0;
    
    canvas.save();
    canvas.translate(0, bob);
    animation.getSprite().render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
    canvas.restore();
  }
}

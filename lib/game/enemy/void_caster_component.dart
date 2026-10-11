import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../world/items/soul_shard_component.dart';

class VoidCasterComponent extends SimpleEnemy with BlockMovementCollision {
  final SpriteAnimation voidOrbAnimation;
  final SpriteAnimation shardAnimation;
  final VoidCallback onShardCollected;

  double _castTimer = 1.5;
  final math.Random _random = math.Random();
  double _patrolTime = 0.0;
  int _patrolDirectionIndex = 0;

  VoidCasterComponent({
    required super.position,
    required SpriteAnimation idleRightAnimation,
    required SpriteAnimation runRightAnimation,
    required this.voidOrbAnimation,
    required this.shardAnimation,
    required this.onShardCollected,
  }) : super(
          size: Vector2(32, 32),
          life: 2.0,
          speed: 70.0,
          animation: SimpleDirectionAnimation(
            idleRight: idleRightAnimation,
            runRight: runRightAnimation,
          ),
        );

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(20, 16),
        position: Vector2(6, 12),
      ),
    );
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _castTimer -= dt;

    final player = gameRef.player;
    if (player != null && !player.isDead) {
      final dist = (player.position - position).length;

      if (dist < 220.0) {
        // If too close, retreat
        if (dist < 75.0) {
          final diff = position - player.position;
          final angle = math.atan2(diff.y, diff.x);
          moveFromAngle(angle);
        } else {
          // In sweet spot range: stop and face player
          idle();
          if (player.position.x < position.x) {
            lastDirection = Direction.left;
          } else {
            lastDirection = Direction.right;
          }
        }

        // Cast void projectile when cooldown is ready
        if (_castTimer <= 0.0) {
          _castTimer = 2.6 + _random.nextDouble() * 0.8;
          _castVoidOrb(player);
        }
        return;
      }
    }

    // Default patrol when player is far away
    _patrolTime -= dt;
    if (_patrolTime <= 0) {
      _patrolTime = 1.5 + _random.nextDouble() * 1.5;
      _patrolDirectionIndex = _random.nextInt(5);
    }
    switch (_patrolDirectionIndex) {
      case 1:
        moveLeft();
        break;
      case 2:
        moveRight();
      case 3:
        moveUp();
      case 4:
        moveDown();
      default:
        idle();
    }
  }

  void _castVoidOrb(Player player) {
    final diff = player.position - position;
    final angle = math.atan2(diff.y, diff.x);

    simpleAttackRangeByAngle(
      animation: Future.value(voidOrbAnimation),
      size: Vector2(20, 20),
      angle: angle,
      damage: 1.0,
      attackFrom: AttackOriginEnum.ENEMY,
      speed: 150.0,
      marginFromOrigin: 8.0,
    );
  }

  @override
  void onDie() {
    super.onDie();
    // Drop 2 Soul Shards
    gameRef.add(
      SoulShardComponent(
        position: position.clone(),
        animation: shardAnimation,
        onCollected: onShardCollected,
      ),
    );
    gameRef.add(
      SoulShardComponent(
        position: position.clone()..add(Vector2(12, 6)),
        animation: shardAnimation,
        onCollected: onShardCollected,
      ),
    );
  }
}

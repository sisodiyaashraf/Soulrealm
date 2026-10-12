import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import '../world/items/soul_shard_component.dart';
import '../player/player_component.dart';
import '../../services/save_service.dart';

class VoidWardenBoss extends SimpleEnemy with BlockMovementCollision {
  final double maxBossLife;
  final void Function(double currentHp, double maxHp) onBossHealthChanged;
  final VoidCallback onBossDefeated;
  final SpriteAnimation voidOrbAnimation;
  final SpriteAnimation shardAnimation;
  final VoidCallback onShardCollected;

  double _attackTimer = 2.0;
  int _attackCycle = 0;
  bool _isRushing = false;
  double _rushDuration = 0.0;
  Vector2 _rushDir = Vector2.zero();

  VoidWardenBoss({
    required super.position,
    required SpriteAnimation idleRightAnimation,
    required SpriteAnimation runRightAnimation,
    required this.voidOrbAnimation,
    required this.shardAnimation,
    required this.onShardCollected,
    required this.onBossHealthChanged,
    required this.onBossDefeated,
    this.maxBossLife = 15.0,
  }) : super(
          size: Vector2(48, 48),
          life: maxBossLife,
          speed: 85.0,
          animation: SimpleDirectionAnimation(
            idleRight: idleRightAnimation,
            runRight: runRightAnimation,
          ),
        );

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(32, 28),
        position: Vector2(8, 14),
      ),
    );
    await super.onLoad();
    onBossHealthChanged(life, maxBossLife);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final player = gameRef.player;
    if (player == null || player.isDead) return;

    final isEnraged = life <= (maxBossLife * 0.4);

    // Handle Rush attack motion
    if (_isRushing) {
      position += _rushDir * (speed * 1.8 * dt);
      _rushDuration -= dt;

      // Check contact damage while rushing
      if ((player.position - position).length < 32.0) {
        simpleAttackMelee(
          damage: 1.5,
          size: Vector2(36, 36),
          withPush: true,
        );
        _isRushing = false;
      }

      if (_rushDuration <= 0) {
        _isRushing = false;
      }
      return;
    }

    // Normal AI positioning
    final dist = (player.position - position).length;
    if (dist > 140.0) {
      final diff = player.position - position;
      final angle = math.atan2(diff.y, diff.x);
      moveFromAngle(angle);
    } else {
      idle();
      if (player.position.x < position.x) {
        lastDirection = Direction.left;
      } else {
        lastDirection = Direction.right;
      }
    }

    // Attack cooldown
    _attackTimer -= dt;
    final cooldown = isEnraged ? 1.4 : 2.2;
    if (_attackTimer <= 0) {
      _attackTimer = cooldown;
      _executeBossAttack(player, isEnraged);
    }
  }

  void _executeBossAttack(Player player, bool isEnraged) {
    _attackCycle = (_attackCycle + 1) % 2;

    if (_attackCycle == 0) {
      // Fan Barrage: 3 Void Orbs
      final diff = player.position - position;
      final baseAngle = math.atan2(diff.y, diff.x);

      final angles = [baseAngle - 0.32, baseAngle, baseAngle + 0.32];
      for (final a in angles) {
        simpleAttackRangeByAngle(
          animation: Future.value(voidOrbAnimation),
          size: Vector2(24, 24),
          angle: a,
          damage: 1.0,
          attackFrom: AttackOriginEnum.ENEMY,
          speed: isEnraged ? 200.0 : 160.0,
          marginFromOrigin: 16.0,
        );
      }
    } else {
      // Abyssal Rush: Charge towards player
      final diff = player.position - position;
      _rushDir = diff.normalized();
      _isRushing = true;
      _rushDuration = 1.0;
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    super.onReceiveDamage(attacker, damage, identify);
    onBossHealthChanged(life, maxBossLife);
    if (attacker == AttackOriginEnum.PLAYER_OR_ALLY) {
      final player = gameRef.player;
      if (player is PlayerComponent) {
        player.registerHit(damage, position);
      }
    }
  }

  @override
  void onDie() {
    super.onDie();
    SaveService().incrementEnemiesSlain(1);
    if (SaveService().getScreenShake()) {
      gameRef.camera.shake(intensity: 8, duration: const Duration(milliseconds: 600));
    }
    onBossHealthChanged(0.0, maxBossLife);
    onBossDefeated();

    // Spawn burst fountain of 8 Soul Shards around the boss
    final math.Random rnd = math.Random();
    for (int i = 0; i < 8; i++) {
      final angle = (i * (2 * math.pi / 8)) + (rnd.nextDouble() * 0.2);
      final offset = Vector2(math.cos(angle), math.sin(angle)) * (20.0 + rnd.nextDouble() * 25.0);
      gameRef.add(
        SoulShardComponent(
          position: position.clone()..add(offset),
          animation: shardAnimation,
          onCollected: onShardCollected,
          value: 2,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final isEnraged = life <= (maxBossLife * 0.4);
    if (isEnraged) {
      // Fiery crimson aura when enraged
      final glowPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 28, glowPaint);
    }

    super.render(canvas);
  }
}

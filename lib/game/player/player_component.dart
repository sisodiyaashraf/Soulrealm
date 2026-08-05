import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends SimplePlayer with BlockMovementCollision {
  static const double maxHealth = 3.0;
  
  // Callback when player health changes
  final Function(double) onHealthChanged;
  // Callback when player dies
  final VoidCallback onDeath;

  PlayerComponent({
    required super.position,
    required SpriteAnimation idleRightAnimation,
    required SpriteAnimation runRightAnimation,
    required this.onHealthChanged,
    required this.onDeath,
  }) : super(
          size: Vector2(32, 32),
          life: maxHealth,
          speed: 120.0,
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

  // Receive damage
  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life);
  }

  @override
  void onDie() {
    super.onDie();
    onDeath();
  }

  // Perform a melee attack
  void executeAttack() {
    simpleAttackMelee(
      damage: 1.0,
      size: Vector2(24, 24),
      withPush: true,
      direction: lastDirection,
    );
  }
}

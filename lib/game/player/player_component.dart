import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../world/tiles/tiles.dart';

class PlayerComponent extends SimplePlayer with BlockMovementCollision {
  static const double baseMaxHealth = 3.0;

  final Function(double) onHealthChanged;
  final VoidCallback onDeath;
  final Function(double currentMana, double maxMana) onManaChanged;
  final Function(double cooldownFraction) onDashCooldown;
  final SpriteAnimation slashAnimation;
  final SpriteAnimation soulBoltAnimation;

  final double attackDamage;
  final double dashCooldown;
  final double maxMana = 100.0;

  double _mana = 100.0;
  double _dashTimer = 0.0;
  bool _isDashing = false;
  double _dashDuration = 0.0;
  Vector2 _dashVelocity = Vector2.zero();
  double _invulnTimer = 0.0;

  PlayerComponent({
    required super.position,
    required SpriteAnimation idleRightAnimation,
    required SpriteAnimation runRightAnimation,
    required this.slashAnimation,
    required this.soulBoltAnimation,
    required this.onHealthChanged,
    required this.onDeath,
    required this.onManaChanged,
    required this.onDashCooldown,
    double maxHealth = baseMaxHealth,
    double moveSpeed = 120.0,
    this.attackDamage = 1.0,
    this.dashCooldown = 1.4,
  }) : super(
          size: Vector2(32, 32),
          life: maxHealth,
          speed: moveSpeed,
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
    onHealthChanged(life);
    onManaChanged(_mana, maxMana);
    onDashCooldown(0.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Invulnerability timer
    if (_invulnTimer > 0) {
      _invulnTimer -= dt;
    }

    // Dash update
    if (_isDashing) {
      position += _dashVelocity * dt;
      _dashDuration -= dt;
      if (_dashDuration <= 0) {
        _isDashing = false;
      }
    }

    // Dash cooldown
    if (_dashTimer > 0) {
      _dashTimer -= dt;
      onDashCooldown(math.max(0.0, _dashTimer / dashCooldown));
    }

    // Mana regeneration (+12 per sec)
    if (_mana < maxMana) {
      _mana = math.min(maxMana, _mana + (12.0 * dt));
      onManaChanged(_mana, maxMana);
    }

    // Proximity check for Pyres: automatically rekindle if standing right next to unlit pyre
    for (final comp in gameRef.query<PyreComponent>()) {
      if (!comp.isLit && (comp.position - position).length < 32.0) {
        comp.lightUp();
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void onJoystickAction(JoystickActionEvent event) {
    if (event.event == ActionEvent.DOWN) {
      if (event.id == 1 ||
          event.id == LogicalKeyboardKey.space ||
          event.id == LogicalKeyboardKey.keyJ) {
        executeMeleeAttack();
      } else if (event.id == 2 ||
          event.id == LogicalKeyboardKey.shiftLeft ||
          event.id == LogicalKeyboardKey.shiftRight ||
          event.id == LogicalKeyboardKey.keyK) {
        executeSoulDash();
      } else if (event.id == 3 ||
          event.id == LogicalKeyboardKey.keyX ||
          event.id == LogicalKeyboardKey.keyL) {
        executeSoulBolt();
      }
    }
  }

  // Perform melee attack
  void executeMeleeAttack() {
    HapticFeedback.lightImpact();
    simpleAttackMelee(
      damage: attackDamage,
      size: Vector2(28, 28),
      withPush: true,
      animationRight: Future.value(slashAnimation),
      direction: lastDirection,
    );

    // Also rekindle any pyre in melee range
    for (final comp in gameRef.query<PyreComponent>()) {
      if (!comp.isLit && (comp.position - position).length < 48.0) {
        comp.lightUp();
      }
    }
  }

  // Perform Soul Dash (burst speed with invulnerability)
  void executeSoulDash() {
    if (_dashTimer > 0) return;
    _dashTimer = dashCooldown;
    _isDashing = true;
    _dashDuration = 0.22;
    HapticFeedback.mediumImpact();

    final angle = _directionToAngle(lastDirection);
    _dashVelocity = Vector2(math.cos(angle), math.sin(angle)) * (speed * 2.6);
  }

  // Perform Soul Bolt (ranged homing/directional spell)
  void executeSoulBolt() {
    if (_mana < 25.0) {
      HapticFeedback.selectionClick();
      return;
    }
    _mana -= 25.0;
    onManaChanged(_mana, maxMana);
    HapticFeedback.lightImpact();

    // Auto-aim towards nearest active enemy within 200px if present
    double targetAngle = _directionToAngle(lastDirection);
    double minDistance = 200.0;

    for (final enemy in gameRef.enemies()) {
      if (!enemy.isDead) {
        final d = (enemy.position - position).length;
        if (d < minDistance) {
          minDistance = d;
          final diff = enemy.position - position;
          targetAngle = math.atan2(diff.y, diff.x);
        }
      }
    }

    simpleAttackRangeByAngle(
      animation: Future.value(soulBoltAnimation),
      size: Vector2(24, 24),
      angle: targetAngle,
      damage: attackDamage * 1.5,
      attackFrom: AttackOriginEnum.PLAYER_OR_ALLY,
      speed: 240.0,
      marginFromOrigin: 8.0,
    );
  }

  double _directionToAngle(Direction dir) {
    switch (dir) {
      case Direction.right:
        return 0.0;
      case Direction.downRight:
        return math.pi / 4;
      case Direction.down:
        return math.pi / 2;
      case Direction.downLeft:
        return 3 * math.pi / 4;
      case Direction.left:
        return math.pi;
      case Direction.upLeft:
        return -3 * math.pi / 4;
      case Direction.up:
        return -math.pi / 2;
      case Direction.upRight:
        return -math.pi / 4;
    }
  }

  @override
  void onReceiveDamage(AttackOriginEnum attacker, double damage, dynamic identify) {
    if (_isDashing || _invulnTimer > 0) return;
    _invulnTimer = 0.8;
    gameRef.camera.shake(intensity: 4, duration: const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();
    super.onReceiveDamage(attacker, damage, identify);
    onHealthChanged(life);
  }

  @override
  void onDie() {
    super.onDie();
    onDeath();
  }

  @override
  void render(Canvas canvas) {
    // Blinking effect during invulnerability
    if (_invulnTimer > 0 && (_invulnTimer * 12).toInt() % 2 == 0) {
      return;
    }

    // Ghost trail during dash
    if (_isDashing) {
      final trailPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 16, trailPaint);
    }

    super.render(canvas);
  }
}


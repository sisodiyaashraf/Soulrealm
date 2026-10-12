import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/save_service.dart';
import '../ui/floating_damage_text.dart';
import '../world/tiles/tiles.dart';

class PlayerComponent extends SimplePlayer with BlockMovementCollision {
  static const double baseMaxHealth = 3.0;

  final Function(double) onHealthChanged;
  final VoidCallback onDeath;
  final Function(double currentMana, double maxMana) onManaChanged;
  final Function(double cooldownFraction) onDashCooldown;
  final void Function(int combo, bool isSurge)? onComboChanged;
  final SpriteAnimation slashAnimation;
  final SpriteAnimation soulBoltAnimation;

  final double attackDamage;
  final double dashCooldown;
  final double maxMana;
  final double manaRegenRate;

  double _mana = 100.0;
  double _dashTimer = 0.0;
  bool _isDashing = false;
  double _dashDuration = 0.0;
  Vector2 _dashVelocity = Vector2.zero();
  double _invulnTimer = 0.0;

  // Combo system
  int _comboCount = 0;
  double _comboTimer = 0.0;
  bool _isSurge = false;

  final SaveService _saveService = SaveService();

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
    this.onComboChanged,
    double maxHealth = baseMaxHealth,
    double moveSpeed = 120.0,
    this.attackDamage = 1.0,
    this.dashCooldown = 1.4,
    this.maxMana = 100.0,
    this.manaRegenRate = 12.0,
  }) : super(
          size: Vector2(32, 32),
          life: maxHealth,
          speed: moveSpeed,
          animation: SimpleDirectionAnimation(
            idleRight: idleRightAnimation,
            runRight: runRightAnimation,
          ),
        ) {
    _mana = maxMana;
  }

  int get comboCount => _comboCount;
  bool get isSurge => _isSurge;

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
    onComboChanged?.call(0, false);
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

    // Mana regeneration
    if (_mana < maxMana) {
      _mana = math.min(maxMana, _mana + (manaRegenRate * dt));
      onManaChanged(_mana, maxMana);
    }

    // Combo timer decay
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboCount = 0;
        _isSurge = false;
        onComboChanged?.call(0, false);
      }
    }

    // Proximity check for Pyres: automatically rekindle if standing right next to unlit pyre
    for (final comp in gameRef.query<PyreComponent>()) {
      if (!comp.isLit && (comp.position - position).length < 32.0) {
        comp.lightUp();
        if (_saveService.getHaptics()) {
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  /// Register an enemy hit to build combo and activate Soul Surge
  void registerHit(double damageDealt, Vector2 hitPosition) {
    _comboCount++;
    _comboTimer = 3.2; // 3.2 seconds window to chain combos
    _isSurge = _comboCount >= 5;

    _saveService.recordCombo(_comboCount);
    onComboChanged?.call(_comboCount, _isSurge);

    if (_saveService.getFloatingDamage()) {
      final isCrit = _isSurge || damageDealt >= 2.0;
      final text = isCrit ? 'CRIT -${damageDealt.toStringAsFixed(1)}' : '-${damageDealt.toStringAsFixed(1)}';
      final color = isCrit ? const Color(0xFFFFD700) : const Color(0xFF00E5FF);

      gameRef.add(
        FloatingDamageText(
          position: hitPosition - Vector2(10, 16),
          text: text,
          color: color,
          isCritical: isCrit,
        ),
      );
    }
  }

  /// Use an Aether Flask to restore 1 Life Heart and 50 Soul Mana
  bool useFlask() {
    if (life >= maxLife && _mana >= maxMana) return false;

    addLife(1.0);
    _mana = math.min(maxMana, _mana + 50.0);
    onHealthChanged(life);
    onManaChanged(_mana, maxMana);

    if (_saveService.getHaptics()) {
      HapticFeedback.mediumImpact();
    }

    if (_saveService.getFloatingDamage()) {
      gameRef.add(
        FloatingDamageText(
          position: position - Vector2(10, 20),
          text: '+1 LIFE',
          color: const Color(0xFF00E676),
          isCritical: true,
        ),
      );
    }
    return true;
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
    if (_saveService.getHaptics()) {
      HapticFeedback.lightImpact();
    }

    final effectiveDamage = _isSurge ? attackDamage * 1.35 : attackDamage;

    simpleAttackMelee(
      damage: effectiveDamage,
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
    if (_saveService.getHaptics()) {
      HapticFeedback.mediumImpact();
    }

    final angle = _directionToAngle(lastDirection);
    final boost = _isSurge ? 3.0 : 2.6;
    _dashVelocity = Vector2(math.cos(angle), math.sin(angle)) * (speed * boost);
  }

  // Perform Soul Bolt (ranged homing/directional spell)
  void executeSoulBolt() {
    if (_mana < 25.0) {
      if (_saveService.getHaptics()) {
        HapticFeedback.selectionClick();
      }
      return;
    }
    _mana -= 25.0;
    onManaChanged(_mana, maxMana);
    if (_saveService.getHaptics()) {
      HapticFeedback.lightImpact();
    }

    // Auto-aim towards nearest active enemy within 220px if present
    double targetAngle = _directionToAngle(lastDirection);
    double minDistance = 220.0;

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

    final effectiveDamage = _isSurge ? (attackDamage * 1.5 * 1.35) : (attackDamage * 1.5);

    simpleAttackRangeByAngle(
      animation: Future.value(soulBoltAnimation),
      size: Vector2(24, 24),
      angle: targetAngle,
      damage: effectiveDamage,
      attackFrom: AttackOriginEnum.PLAYER_OR_ALLY,
      speed: 250.0,
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

    // Reset combo on hit
    _comboCount = 0;
    _isSurge = false;
    onComboChanged?.call(0, false);

    if (_saveService.getScreenShake()) {
      gameRef.camera.shake(intensity: 4, duration: const Duration(milliseconds: 200));
    }
    if (_saveService.getHaptics()) {
      HapticFeedback.mediumImpact();
    }

    if (_saveService.getFloatingDamage()) {
      gameRef.add(
        FloatingDamageText(
          position: position - Vector2(10, 20),
          text: '-${damage.toStringAsFixed(1)}',
          color: const Color(0xFFFF5252),
          isCritical: true,
        ),
      );
    }

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

    // Soul Surge radiant glowing aura
    if (_isSurge) {
      final surgePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 20, surgePaint);
    }

    super.render(canvas);
  }
}

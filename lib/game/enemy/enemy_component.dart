import '../world/items/soul_shard_component.dart';

class EnemyComponent extends SimpleEnemy with BlockMovementCollision {
  final double attackDamage = 1.0;
  final SpriteAnimation? shardAnimation;
  final VoidCallback? onShardCollected;
  bool _isAttacking = false;

  final math.Random _random = math.Random();
  double _patrolTime = 0.0;
  int _patrolDirectionIndex = 0;

  EnemyComponent({
    required super.position,
    required SpriteAnimation idleRightAnimation,
    required SpriteAnimation runRightAnimation,
    this.shardAnimation,
    this.onShardCollected,
  }) : super(
          size: Vector2(32, 32),
          life: 2.0,
          speed: 80.0,
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
    
    // AI behavior: see player, chase, and attack if close. Otherwise run randomly.
    seeAndMoveToPlayer(
      closePlayer: (player) {
        _executeAttack();
      },
      radiusVision: 128,
      observed: () {
        // Player seen, chasing
      },
      notObserved: () {
        // Player not in vision range, patrol randomly
        _patrolTime -= dt;
        if (_patrolTime <= 0) {
          _patrolTime = 1.0 + _random.nextDouble() * 1.5;
          _patrolDirectionIndex = _random.nextInt(5); // 0: idle, 1: left, 2: right, 3: up, 4: down
        }
        
        switch (_patrolDirectionIndex) {
          case 1:
            moveLeft();
            break;
          case 2:
            moveRight();
            break;
          case 3:
            moveUp();
            break;
          case 4:
            moveDown();
            break;
          default:
            idle();
            break;
        }
        return false;
      },
    );
  }

  void _executeAttack() {
    if (_isAttacking) return;
    _isAttacking = true;
    
    simpleAttackMelee(
      damage: attackDamage,
      size: Vector2(24, 24),
      withPush: true,
      execute: () {
        // Reset attack flag after strike interval
        Future.delayed(const Duration(milliseconds: 1000), () {
          _isAttacking = false;
        });
      },
    );
  }
}

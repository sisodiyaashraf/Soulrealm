import 'dart:async' as async;
import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import '../services/save_service.dart';
import '../services/games_services_wrapper.dart';
import '../ui/hud/hud_overlay.dart';
import 'enemy/enemy_component.dart';
import 'enemy/void_caster_component.dart';
import 'enemy/void_warden_boss.dart';
import 'player/player_component.dart';
import 'world/items/soul_shard_component.dart';
import 'world/tiles/tileset_generator.dart';
import 'world/overworld_map.dart';
import 'world/tiles/tiles.dart';

class SoulrealmGameWidget extends StatefulWidget {
  final int levelId;
  final bool isOverworld;

  const SoulrealmGameWidget({
    super.key,
    required this.levelId,
    required this.isOverworld,
  });

  @override
  State<SoulrealmGameWidget> createState() => _SoulrealmGameWidgetState();
}

class _SoulrealmGameWidgetState extends State<SoulrealmGameWidget> {
  final SaveService _saveService = SaveService();
  final GamesServicesWrapper _gamesServices = GamesServicesWrapper();

  bool _loading = true;
  double _playerHp = 3.0;
  double _maxHp = 3.0;
  double _playerMana = 100.0;
  double _maxMana = 100.0;
  double _dashCooldownFraction = 0.0;
  int _shardsCollectedThisRun = 0;
  int _totalPyres = 0;
  int _litPyres = 0;
  bool _levelWon = false;
  bool _gameOver = false;
  int _starsEarned = 1;

  double? _bossHp;
  double? _bossMaxHp;
  double? _compassAngle;
  String? _compassTargetName;

  final _fireworksController = FireworksController(
    colors: [
      const Color(0xFF00E5FF),
      const Color(0xFFFF2A85),
      const Color(0xFFFFEA00),
      const Color(0xFFFF5722),
    ],
    minExplosionDuration: 1.0,
    maxExplosionDuration: 3.0,
    minParticleCount: 100,
    maxParticleCount: 200,
  );

  late Sprite _unlitPyreSprite;
  late SpriteAnimation _playerIdle;
  late SpriteAnimation _playerWalk;
  late SpriteAnimation _enemyIdle;
  late SpriteAnimation _enemyWalk;
  late SpriteAnimation _casterIdle;
  late SpriteAnimation _casterWalk;
  late SpriteAnimation _bossIdle;
  late SpriteAnimation _bossAttack;
  late SpriteAnimation _soulBoltAnimation;
  late SpriteAnimation _voidOrbAnimation;
  late SpriteAnimation _shardAnimation;
  late SpriteAnimation _slashAnimation;

  late MapLoadResult _mapData;
  BonfireGameInterface? _bonfireGame;
  async.Timer? _compassTimer;

  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initGameData();
  }

  @override
  void dispose() {
    _compassTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _initGameData() async {
    await _saveService.init();
    await _gamesServices.initialize();

    _maxHp = _saveService.getMaxHealth();
    _playerHp = _maxHp;

    // Generate procedural assets
    final tilesetImg = await TilesetGenerator.generate();
    final playerImg = await TilesetGenerator.generatePlayer();
    final enemyImg = await TilesetGenerator.generateEnemy();
    final casterImg = await TilesetGenerator.generateVoidCaster();
    final bossImg = await TilesetGenerator.generateVoidWarden();
    final soulBoltImg = await TilesetGenerator.generateSoulBolt();
    final voidOrbImg = await TilesetGenerator.generateVoidOrb();
    final shardImg = await TilesetGenerator.generateSoulShard();
    final slashImg = await TilesetGenerator.generateSlashEffect();

    // Cache in Flame
    Flame.images.add('tileset.png', tilesetImg);
    Flame.images.add('player.png', playerImg);
    Flame.images.add('enemy.png', enemyImg);

    // Prepare Sprites / Animations
    _unlitPyreSprite = Sprite(tilesetImg, srcPosition: Vector2(0, 64), srcSize: Vector2(64, 64));

    _playerIdle = SpriteAnimation.fromFrameData(
      playerImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _playerWalk = SpriteAnimation.fromFrameData(
      playerImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 32)),
    );

    _enemyIdle = SpriteAnimation.fromFrameData(
      enemyImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _enemyWalk = SpriteAnimation.fromFrameData(
      enemyImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 32)),
    );

    _casterIdle = SpriteAnimation.fromFrameData(
      casterImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _casterWalk = SpriteAnimation.fromFrameData(
      casterImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 32)),
    );

    _bossIdle = SpriteAnimation.fromFrameData(
      bossImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2(48, 48), texturePosition: Vector2(0, 0)),
    );
    _bossAttack = SpriteAnimation.fromFrameData(
      bossImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(48, 48), texturePosition: Vector2(0, 48)),
    );

    _soulBoltAnimation = SpriteAnimation.fromFrameData(
      soulBoltImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _voidOrbAnimation = SpriteAnimation.fromFrameData(
      voidOrbImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.1, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _shardAnimation = SpriteAnimation.fromFrameData(
      shardImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0)),
    );
    _slashAnimation = SpriteAnimation.fromFrameData(
      slashImg,
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.06, textureSize: Vector2(32, 32), texturePosition: Vector2(0, 0), loop: false),
    );

    // Map parsing
    final mapPath = widget.isOverworld ? 'assets/tiles/overworld.tmx' : 'assets/tiles/level_${widget.levelId}.tmx';
    final unlockedLevels = _saveService.getUnlockedLevels();
    _mapData = await MapLoader.load(
      mapPath,
      pyreUnlitSprite: _unlitPyreSprite,
      onPyreLit: _onPyreLit,
      onPortalTrigger: _onPortalTrigger,
      isPortalActive: !widget.isOverworld,
      unlockedLevels: unlockedLevels,
      onHealFountain: _onHealFountain,
      onReadLore: _showLoreDialog,
    );

    if (widget.isOverworld) {
      final savedPos = _saveService.getOverworldPosition();
      if (savedPos != null) {
        _mapData.playerSpawn.x = savedPos['x']!;
        _mapData.playerSpawn.y = savedPos['y']!;
      }
    }

    _totalPyres = _mapData.components.whereType<PyreComponent>().length;
    _stopwatch.start();

    // Compass radar timer
    if (!widget.isOverworld) {
      _compassTimer = async.Timer.periodic(const Duration(milliseconds: 250), (_) {
        _updateCompass();
      });
    }

    setState(() {
      _loading = false;
    });
  }

  void _onHealFountain() {
    setState(() {
      _playerHp = _maxHp;
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aether Spring has fully restored your soul vessel!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF00E5FF),
      ),
    );
  }

  void _showLoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C0E1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Color(0xFF00E5FF)),
            SizedBox(width: 10),
            Text('CHRONICLES OF PURGATORY', style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5)),
          ],
        ),
        content: const Text(
          'Before the Void Eclipse, eternal flames kept the Soulrealm alive. '
          'Now, abyssal shades roam the shattered pathways.\n\n'
          'Rekindle each sacred Pyre to unveil the dimensional rifts, and vanquish '
          'the Void Warden lurking in the Silent Citadel to restore the Embers of Light!',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('UNDERSTOOD', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onShardCollected() {
    setState(() {
      _shardsCollectedThisRun++;
    });
  }

  void _onPyreLit(int id) {
    setState(() {
      _litPyres++;
      if (_litPyres >= _totalPyres) {
        for (var comp in _mapData.components.whereType<PortalComponent>()) {
          comp.isActive = true;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onPortalTrigger(int targetLevelId) {
    if (widget.isOverworld) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SoulrealmGameWidget(
            levelId: targetLevelId,
            isOverworld: false,
          ),
        ),
      ).then((_) {
        _initGameData();
      });
    } else {
      _winLevel();
    }
  }

  void _onBossDefeated() {
    _winLevel();
  }

  void _updateCompass() {
    final game = _bonfireGame;
    if (game == null || game.player == null) return;

    final playerPos = game.player!.position;

    if (_litPyres < _totalPyres) {
      // Find closest unlit Pyre
      PyreComponent? closest;
      double minDist = double.infinity;

      for (final comp in _mapData.components.whereType<PyreComponent>()) {
        if (!comp.isLit) {
          final d = (comp.position - playerPos).length;
          if (d < minDist) {
            minDist = d;
            closest = comp;
          }
        }
      }

      if (closest != null) {
        final diff = closest.position - playerPos;
        final angle = math.atan2(diff.y, diff.x);
        if (mounted) {
          setState(() {
            _compassAngle = angle;
            _compassTargetName = 'PYRE';
          });
        }
      }
    } else {
      // All pyres lit: point to exit Portal
      final portal = _mapData.components.whereType<PortalComponent>().firstOrNull;
      if (portal != null) {
        final diff = portal.position - playerPos;
        final angle = math.atan2(diff.y, diff.x);
        if (mounted) {
          setState(() {
            _compassAngle = angle;
            _compassTargetName = 'PORTAL';
          });
        }
      }
    }
  }

  void _winLevel() {
    if (_levelWon) return;
    _stopwatch.stop();
    _levelWon = true;

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;

    // Target times per level for 2-star rating
    final targetTimes = {1: 45, 2: 55, 3: 70, 4: 85, 5: 110};
    final target = targetTimes[widget.levelId] ?? 60;

    int stars = 1;
    if (elapsedSeconds <= target) stars++;
    if (_shardsCollectedThisRun >= 4 || _playerHp >= (_maxHp - 0.5)) stars++;
    _starsEarned = stars;

    // Save progress locally
    _saveService.completeLevel(widget.levelId);
    _saveService.saveScore(widget.levelId, elapsedSeconds);
    _saveService.saveLevelStars(widget.levelId, stars);
    _saveService.addSoulShards(_shardsCollectedThisRun);

    // Games services
    _gamesServices.submitScore(
      androidLeaderboardId: 'leaderboard_stage_${widget.levelId}',
      iosLeaderboardId: 'leaderboard_stage_${widget.levelId}',
      scoreValue: elapsedSeconds,
    );
    if (widget.levelId == 1) {
      _gamesServices.unlockAchievement(
        androidAchievementId: 'achievement_first_level',
        iosAchievementId: 'achievement_first_level',
      );
    }
    if (stars == 3) {
      _gamesServices.unlockAchievement(
        androidAchievementId: 'achievement_perfect_stage',
        iosAchievementId: 'achievement_perfect_stage',
      );
    }

    setState(() {});

    _fireworksController.fireMultipleRockets(
      minRockets: 8,
      maxRockets: 18,
      launchWindow: const Duration(milliseconds: 500),
    );
  }

  void _onPlayerHealthChanged(double hp) {
    setState(() {
      _playerHp = hp;
    });
  }

  void _onPlayerDeath() {
    _stopwatch.stop();
    setState(() {
      _gameOver = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07090F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    // Build enemy and collectible components
    final List<GameComponent> gameplayComponents = [];

    if (!widget.isOverworld) {
      // Spawn collectibles
      for (var pos in _mapData.shardSpawns) {
        gameplayComponents.add(
          SoulShardComponent(
            position: pos,
            animation: _shardAnimation,
            onCollected: _onShardCollected,
          ),
        );
      }

      // Spawn enemy varieties
      int enemyIndex = 0;
      for (var pos in _mapData.enemySpawns) {
        enemyIndex++;
        if (widget.levelId >= 3 && enemyIndex % 3 == 0) {
          // Void Caster sorcerer
          gameplayComponents.add(
            VoidCasterComponent(
              position: pos,
              idleRightAnimation: _casterIdle,
              runRightAnimation: _casterWalk,
              voidOrbAnimation: _voidOrbAnimation,
              shardAnimation: _shardAnimation,
              onShardCollected: _onShardCollected,
            ),
          );
        } else {
          // Standard shadow lurker
          gameplayComponents.add(
            EnemyComponent(
              position: pos,
              idleRightAnimation: _enemyIdle,
              runRightAnimation: _enemyWalk,
              shardAnimation: _shardAnimation,
              onShardCollected: _onShardCollected,
            ),
          );
        }
      }

      // Stage 5 Boss Encounter
      if (widget.levelId == 5) {
        final bossSpawn = _mapData.playerSpawn + Vector2(100, 40);
        gameplayComponents.add(
          VoidWardenBoss(
            position: bossSpawn,
            idleRightAnimation: _bossIdle,
            runRightAnimation: _bossAttack,
            voidOrbAnimation: _voidOrbAnimation,
            shardAnimation: _shardAnimation,
            onShardCollected: _onShardCollected,
            onBossHealthChanged: (hp, maxHp) {
              setState(() {
                _bossHp = hp;
                _bossMaxHp = maxHp;
              });
            },
            onBossDefeated: _onBossDefeated,
          ),
        );
      }
    }

    // Player upgraded stats
    final playerSpeed = _saveService.getPlayerSpeed();
    final playerDamage = _saveService.getPlayerDamage();
    final dashCooldown = _saveService.getDashCooldownSeconds();

    // Joystick with 3 action buttons
    final joystick = Joystick(
      directional: JoystickDirectional(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
        size: 80,
      ),
      actions: [
        // Action 1: Melee Attack (Space / J)
        JoystickAction(
          actionId: 1,
          margin: const EdgeInsets.only(right: 30, bottom: 40),
          color: const Color(0xFFFF2A85).withValues(alpha: 0.85),
          size: 52,
        ),
        // Action 2: Soul Dash (Shift / K)
        JoystickAction(
          actionId: 2,
          margin: const EdgeInsets.only(right: 95, bottom: 30),
          color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
          size: 46,
        ),
        // Action 3: Soul Bolt Ranged Spell (X / L)
        JoystickAction(
          actionId: 3,
          margin: const EdgeInsets.only(right: 35, bottom: 105),
          color: const Color(0xFFFFEA00).withValues(alpha: 0.85),
          size: 46,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        children: [
          BonfireWidget(
            map: _mapData.map,
            player: PlayerComponent(
              position: _mapData.playerSpawn,
              idleRightAnimation: _playerIdle,
              runRightAnimation: _playerWalk,
              slashAnimation: _slashAnimation,
              soulBoltAnimation: _soulBoltAnimation,
              maxHealth: _maxHp,
              moveSpeed: playerSpeed,
              attackDamage: playerDamage,
              dashCooldown: dashCooldown,
              onHealthChanged: _onPlayerHealthChanged,
              onDeath: _onPlayerDeath,
              onManaChanged: (mana, maxMana) {
                setState(() {
                  _playerMana = mana;
                  _maxMana = maxMana;
                });
              },
              onDashCooldown: (fraction) {
                setState(() {
                  _dashCooldownFraction = fraction;
                });
              },
            ),
            playerControllers: [
              joystick,
              Keyboard(
                config: KeyboardConfig(
                  directionalKeys: [
                    KeyboardDirectionalKeys.arrows(),
                    KeyboardDirectionalKeys.wasd(),
                  ],
                ),
              ),
            ],
            components: [
              ...gameplayComponents,
              ..._mapData.components,
            ],
            cameraConfig: CameraConfig(
              moveOnlyMapArea: true,
              zoom: 1.5,
            ),
            colorFilter: widget.isOverworld
                ? GameColorFilter(
                    color: const Color(0xFF4C5C8C).withValues(alpha: 0.25),
                    blendMode: BlendMode.colorBurn,
                  )
                : null,
            onReady: (game) {
              _bonfireGame = game;
            },
            overlayBuilderMap: {
              'hud': (context, game) {
                _bonfireGame ??= game;
                return HudOverlay(
                  levelName: widget.isOverworld ? 'OVERWORLD' : 'STAGE ${widget.levelId}',
                  hp: _playerHp,
                  maxHp: _maxHp,
                  mana: _playerMana,
                  maxMana: _maxMana,
                  dashCooldownFraction: _dashCooldownFraction,
                  litPyres: _litPyres,
                  totalPyres: _totalPyres,
                  shardsCollected: _shardsCollectedThisRun,
                  bossHp: _bossHp,
                  bossMaxHp: _bossMaxHp,
                  compassAngle: _compassAngle,
                  compassTargetName: _compassTargetName,
                  onPause: () {
                    game.pauseEngine();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => _buildPauseDialog(game),
                    );
                  },
                );
              },
            },
            initialActiveOverlays: const ['hud'],
          ),

          // Fireworks layer for Level Won celebration
          if (_levelWon) ...[
            IgnorePointer(
              child: FireworksDisplay(
                controller: _fireworksController,
              ),
            ),
            _buildLevelCompleteOverlay(),
          ],

          // Game Over overlay
          if (_gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildPauseDialog(BonfireGameInterface game) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F121F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('PAUSED', style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
      content: const Text('Do you wish to resume or return to progression map?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () {
            game.resumeEngine();
            Navigator.pop(context);
          },
          child: const Text('RESUME', style: TextStyle(color: Color(0xFF00E5FF))),
        ),
        TextButton(
          onPressed: () {
            if (widget.isOverworld) {
              final player = game.player;
              if (player != null) {
                _saveService.saveOverworldPosition(player.position.x, player.position.y);
              }
            }
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('QUIT', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                blurRadius: 25,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'STAGE CLEARED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 14),

              // Star Rating Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = index < _starsEarned;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      active ? Icons.star : Icons.star_border,
                      color: active ? const Color(0xFFFFD700) : Colors.white24,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              Text(
                'Time Taken: ${_stopwatch.elapsed.inSeconds} seconds',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Shards Gathered: +$_shardsCollectedThisRun',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (widget.levelId < 5) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SoulrealmGameWidget(
                          levelId: widget.levelId + 1,
                          isOverworld: false,
                        ),
                      ),
                    );
                  },
                  child: const Text('NEXT STAGE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
              ],

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('RETURN TO MAP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SOUL EXTINGUISHED',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SoulrealmGameWidget(
                        levelId: widget.levelId,
                        isOverworld: widget.isOverworld,
                      ),
                    ),
                  );
                },
                child: const Text('RETRY STAGE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('QUIT TO MAP', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

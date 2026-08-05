import 'dart:async';
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fireworks/flutter_fireworks.dart';
import '../services/save_service.dart';
import '../services/games_services_wrapper.dart';
import '../ui/hud/hud_overlay.dart';
import 'enemy/enemy_component.dart';
import 'player/player_component.dart';
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
  double _playerHp = PlayerComponent.maxHealth;
  int _totalPyres = 0;
  int _litPyres = 0;
  bool _levelWon = false;
  bool _gameOver = false;
  
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
  late MapLoadResult _mapData;
  
  final _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initGameData();
  }

  Future<void> _initGameData() async {
    await _saveService.init();
    await _gamesServices.initialize();
    
    // Generate procedural assets
    final tilesetImg = await TilesetGenerator.generate();
    final playerImg = await TilesetGenerator.generatePlayer();
    final enemyImg = await TilesetGenerator.generateEnemy();

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

    // Map parsing
    final mapPath = widget.isOverworld ? 'assets/tiles/overworld.tmx' : 'assets/tiles/level_${widget.levelId}.tmx';
    final unlockedLevels = _saveService.getUnlockedLevels();
    _mapData = await MapLoader.load(
      mapPath,
      pyreUnlitSprite: _unlitPyreSprite,
      onPyreLit: _onPyreLit,
      onPortalTrigger: _onPortalTrigger,
      isPortalActive: !widget.isOverworld, // Level portal starts inactive (until pyres are lit)
      unlockedLevels: unlockedLevels,
    );

    if (widget.isOverworld) {
      // Restore overworld player position if available
      final savedPos = _saveService.getOverworldPosition();
      if (savedPos != null) {
        _mapData.playerSpawn.x = savedPos['x']!;
        _mapData.playerSpawn.y = savedPos['y']!;
      }
    }

    _totalPyres = _mapData.components.whereType<PyreComponent>().length;
    _stopwatch.start();

    setState(() {
      _loading = false;
    });
  }

  void _onPyreLit(int id) {
    setState(() {
      _litPyres++;
      if (_litPyres >= _totalPyres) {
        // Activate portal once all pyres are lit
        for (var comp in _mapData.components.whereType<PortalComponent>()) {
          comp.isActive = true;
        }
      }
    });
  }

  void _onPortalTrigger(int targetLevelId) {
    if (widget.isOverworld) {
      // Launch target level
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SoulrealmGameWidget(
            levelId: targetLevelId,
            isOverworld: false,
          ),
        ),
      ).then((_) {
        // Refresh unlocked portals when returning
        _initGameData();
      });
    } else {
      // Completing a level
      _winLevel();
    }
  }

  void _winLevel() {
    if (_levelWon) return;
    _stopwatch.stop();
    _levelWon = true;

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;

    // Save progress locally
    _saveService.completeLevel(widget.levelId);
    _saveService.saveScore(widget.levelId, elapsedSeconds);

    // Games services submit score and unlock achievements
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

    setState(() {});

    // Blast fireworks!
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

    // Spawn list of bonfire enemies
    final List<Enemy> enemies = [];
    if (!widget.isOverworld) {
      for (var pos in _mapData.enemySpawns) {
        enemies.add(
          EnemyComponent(
            position: pos,
            idleRightAnimation: _enemyIdle,
            runRightAnimation: _enemyWalk,
          ),
        );
      }
    }

    // Set up joystick
    final joystick = Joystick(
      directional: JoystickDirectional(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
        size: 80,
      ),
      actions: [
        JoystickAction(
          actionId: 1,
          margin: const EdgeInsets.all(40),
          color: const Color(0xFFFF2A85).withValues(alpha: 0.8),
          size: 50,
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
              onHealthChanged: _onPlayerHealthChanged,
              onDeath: _onPlayerDeath,
            ),
            playerControllers: [
              joystick,
              Keyboard(),
            ],
            components: [
              ...enemies,
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
            overlayBuilderMap: {
              'hud': (context, game) => HudOverlay(
                levelName: widget.isOverworld ? 'OVERWORLD' : 'STAGE ${widget.levelId}',
                hp: _playerHp,
                litPyres: _litPyres,
                totalPyres: _totalPyres,
                onPause: () {
                  game.pause();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => _buildPauseDialog(game),
                  );
                },
              ),
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

  Widget _buildPauseDialog(BonfireGame game) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F121F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('PAUSED', style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
      content: const Text('Do you wish to resume or return to progression map?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () {
            game.resume();
            Navigator.pop(context);
          },
          child: const Text('RESUME', style: TextStyle(color: Color(0xFF00E5FF))),
        ),
        TextButton(
          onPressed: () {
            if (widget.isOverworld) {
              // Save player coordinates before exiting overworld
              final player = game.player;
              if (player != null) {
                _saveService.saveOverworldPosition(player.position.x, player.position.y);
              }
            }
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // exit game
          },
          child: const Text('QUIT', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                blurRadius: 20,
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time Taken: ${_stopwatch.elapsed.inSeconds} seconds',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('RETURN TO MAP', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // Reload game widget
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
                child: const Text('RETRY'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('QUIT', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

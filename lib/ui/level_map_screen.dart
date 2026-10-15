import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/games_services_wrapper.dart';
import '../game/soulrealm_game.dart';
import 'shrine/shrine_dialog.dart';
import 'codex/bestiary_dialog.dart';
import 'settings/settings_dialog.dart';
import 'stats/records_dialog.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with SingleTickerProviderStateMixin {
  final SaveService _saveService = SaveService();
  final GamesServicesWrapper _gamesServices = GamesServicesWrapper();

  List<int> _unlockedLevels = [1];
  List<int> _completedLevels = [];
  Map<String, int> _scores = {};
  Map<String, int> _stars = {};
  int _shards = 0;
  int _totalStars = 0;
  bool _loading = true;
  int _selectedStageIndex = 0;

  late final PageController _pageController;

  final List<Map<String, dynamic>> _levelConfig = [
    {
      'id': 1,
      'name': 'Gates of Purgatory',
      'subtitle': 'The Crumbling Threshold of the Abyss',
      'difficulty': 'NORMAL',
      'diffColor': Color(0xFF00E5FF),
      'targetSeconds': 45,
      'threats': ['Shadow Lurker'],
      'pyres': 3,
      'lore': 'The entrance to the lost realm. Kindle the sacred pyres to destabilize void shadows and breach the first dimensional seal.',
      'gradient': [Color(0xFF0F1E3D), Color(0xFF090D1C)],
    },
    {
      'id': 2,
      'name': 'Whispering Woods',
      'subtitle': 'Haunted Arbor of Forgotten Spirits',
      'difficulty': 'NORMAL',
      'diffColor': Color(0xFF00E5FF),
      'targetSeconds': 55,
      'threats': ['Shadow Lurkers', 'Void Spores'],
      'pyres': 3,
      'lore': 'Winds howling through petrified branches carry void echoes. Stay swift and strike down wandering shades before they encircle your vessel.',
      'gradient': [Color(0xFF132B2B), Color(0xFF081414)],
    },
    {
      'id': 3,
      'name': 'Shadow Crypt',
      'subtitle': 'Sepulcher of the Lost Sorcerers',
      'difficulty': 'HARD',
      'diffColor': Color(0xFF7C4DFF),
      'targetSeconds': 70,
      'threats': ['Void Caster', 'Shadow Lurkers'],
      'pyres': 4,
      'lore': 'Ancient sorcerers now linger as Void Casters, casting homing abyssal orbs. Use Soul Dash invulnerability to evade projectile barrages.',
      'gradient': [Color(0xFF26123D), Color(0xFF10071C)],
    },
    {
      'id': 4,
      'name': 'Void Breach',
      'subtitle': 'Dimensional Rift on the Verge of Collapse',
      'difficulty': 'HARD',
      'diffColor': Color(0xFF7C4DFF),
      'targetSeconds': 85,
      'threats': ['Multiple Void Casters', 'Lurker Swarms'],
      'pyres': 4,
      'lore': 'The barrier between dimensions fractures. Navigate twisting pathways under continuous sorcerer fire to locate all eternal embers.',
      'gradient': [Color(0xFF381028), Color(0xFF170610)],
    },
    {
      'id': 5,
      'name': 'Silent Citadel',
      'subtitle': 'Throne of the Void Warden',
      'difficulty': 'NIGHTMARE',
      'diffColor': Color(0xFFFF1744),
      'targetSeconds': 110,
      'threats': ['VOID WARDEN (BOSS)', 'Void Casters', 'Lurkers'],
      'pyres': 4,
      'lore': 'The supreme fortress of the abyssal archon. Vanquish the Void Warden in mortal combat to cleanse Soulrealm and restore the eternal sun.',
      'gradient': [Color(0xFF380C14), Color(0xFF140407)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    await _saveService.init();
    await _gamesServices.initialize();

    setState(() {
      _unlockedLevels = _saveService.getUnlockedLevels();
      _completedLevels = _saveService.getCompletedLevels();
      _scores = _saveService.getScores();
      _stars = _saveService.getAllStars();
      _shards = _saveService.getSoulShards();
      _totalStars = _saveService.getTotalStars();
      _loading = false;
    });
  }

  void _openShrine() {
    showDialog(
      context: context,
      builder: (context) => ShrineDialog(onUpdated: _loadProgress),
    );
  }

  void _openCodex() {
    showDialog(
      context: context,
      builder: (context) => const BestiaryDialog(),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(onDataChanged: _loadProgress),
    );
  }

  void _openRecords() {
    showDialog(
      context: context,
      builder: (context) => const RecordsDialog(),
    );
  }

  void _launchGame(int levelId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SoulrealmGameWidget(
          levelId: levelId,
          isOverworld: false,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  void _launchOverworld() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SoulrealmGameWidget(
          levelId: 0,
          isOverworld: true,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07090F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
      );
    }

    final playerTitle = _saveService.getPlayerTitle();

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: Stack(
        children: [
          // Background Atmospheric Nebula
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.4,
                  colors: [
                    Color(0xFF141936),
                    Color(0xFF0C0E1E),
                    Color(0xFF05070E),
                  ],
                ),
              ),
            ),
          ),

          // Particle Embers Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _EmbersBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Modern Glass Header Bar
                _buildHeaderBar(playerTitle),

                const SizedBox(height: 10),

                // Stage Selector Navigation Pills
                _buildStageSelectorTabs(),

                const SizedBox(height: 12),

                // Main Stage Cards Carousel View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _levelConfig.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _selectedStageIndex = idx;
                      });
                    },
                    itemBuilder: (context, index) {
                      final config = _levelConfig[index];
                      final id = config['id'] as int;
                      final isUnlocked = _unlockedLevels.contains(id);
                      final isCompleted = _completedLevels.contains(id);
                      final bestTime = _scores[id.toString()];
                      final stars = _stars[id.toString()] ?? 0;

                      return _buildStageCard(config, isUnlocked, isCompleted, bestTime, stars);
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Bottom Action Bar
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(String playerTitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1224).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Player Title Badge
          GestureDetector(
            onTap: _openRecords,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF), size: 16),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'VESSEL OF THE SOULREALM',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 8.5,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center: Stars & Shards Counters
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stars badge
              GestureDetector(
                onTap: _openRecords,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E223D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalStars / 15',
                        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Soul Shards Badge
              GestureDetector(
                onTap: _openShrine,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13172E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_shards',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Right: Action Icons (Codex, Leaderboard, Achievements, Settings)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_book, color: Color(0xFF00E5FF), size: 20),
                tooltip: 'Shadow Codex',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: _openCodex,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 20),
                tooltip: 'Career Chronicles',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: _openRecords,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.leaderboard, color: Colors.white70, size: 20),
                tooltip: 'Leaderboards',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  _gamesServices.showLeaderboard(
                    androidId: 'leaderboard_stage_1',
                    iosId: 'leaderboard_stage_1',
                  );
                },
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white70, size: 20),
                tooltip: 'Preferences',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: _openSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageSelectorTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_levelConfig.length, (index) {
          final id = index + 1;
          final isSelected = index == _selectedStageIndex;
          final isUnlocked = _unlockedLevels.contains(id);
          final isCompleted = _completedLevels.contains(id);

          Color tabColor = Colors.white24;
          if (isCompleted) {
            tabColor = const Color(0xFF00E5FF);
          } else if (isUnlocked) {
            tabColor = const Color(0xFFFF2A85);
          }

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? tabColor.withValues(alpha: 0.2)
                    : const Color(0xFF0F1224).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? tabColor : Colors.white12,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : (isUnlocked ? Icons.play_arrow : Icons.lock),
                    size: 13,
                    color: tabColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STAGE $id',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStageCard(
    Map<String, dynamic> config,
    bool isUnlocked,
    bool isCompleted,
    int? bestTime,
    int stars,
  ) {
    final id = config['id'] as int;
    final name = config['name'] as String;
    final subtitle = config['subtitle'] as String;
    final diff = config['difficulty'] as String;
    final diffColor = config['diffColor'] as Color;
    final targetSeconds = config['targetSeconds'] as int;
    final threats = config['threats'] as List<String>;
    final lore = config['lore'] as String;
    final gradient = config['gradient'] as List<Color>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked ? diffColor.withValues(alpha: 0.5) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: diffColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Stage Identifier, Difficulty Chip, Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: diffColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'STAGE $id',
                          style: TextStyle(
                            color: diffColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          diff,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Stars Display
                  Row(
                    children: List.generate(3, (starIdx) {
                      final hasStar = starIdx < stars;
                      return Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(
                          hasStar ? Icons.star : Icons.star_border,
                          size: 20,
                          color: hasStar ? const Color(0xFFFFD700) : Colors.white24,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),

              // Lore snippet
              Text(
                lore,
                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Threat Intel & Objectives Chips Row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...threats.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.dangerous, color: Colors.redAccent, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              t,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF00E5FF), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Target: <${targetSeconds}s',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom card action row: Best Time + Embark Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Best time or completion chip
                  if (bestTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1224),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFD700), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'BEST: ${bestTime}s',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Action Button
                  if (isUnlocked)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? const Color(0xFF00E5FF) : const Color(0xFFFF2A85),
                        foregroundColor: isCompleted ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                      ),
                      icon: Icon(isCompleted ? Icons.replay : Icons.play_arrow, size: 18),
                      label: Text(
                        isCompleted ? 'REPLAY EXPEDITION' : 'COMMENCE EXPEDITION',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11),
                      ),
                      onPressed: () => _launchGame(id),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.white38, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'LOCKED (CLEAR STAGE ${id - 1})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1224).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Void Forge quick button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(
                'VOID FORGE',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 11),
              ),
              onPressed: _openShrine,
            ),
          ),
          const SizedBox(width: 10),

          // Shadow Codex Quick Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _openCodex,
            child: const Icon(Icons.menu_book, size: 18),
          ),
          const SizedBox(width: 10),

          // Overworld Exploration Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.explore, size: 18),
              label: const Text(
                'EXPLORE OVERWORLD',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11),
              ),
              onPressed: _launchOverworld,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbersBackgroundPainter extends CustomPainter {
  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final emberPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = 1.0 + _random.nextDouble() * 2.2;
      final alpha = 0.15 + _random.nextDouble() * 0.45;
      final isCyan = i % 2 == 0;

      emberPaint.color = (isCyan ? const Color(0xFF00E5FF) : const Color(0xFFFF2A85)).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, emberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

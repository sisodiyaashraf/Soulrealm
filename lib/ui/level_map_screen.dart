import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../game/soulrealm_game.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final SaveService _saveService = SaveService();
  List<int> _unlockedLevels = [1];
  List<int> _completedLevels = [];
  Map<String, int> _scores = {};
  bool _loading = true;

  final List<Map<String, dynamic>> _levelConfig = [
    {'id': 1, 'name': 'Gates of Purgatory', 'align': Alignment.centerLeft},
    {'id': 2, 'name': 'Whispering Woods', 'align': Alignment.centerRight},
    {'id': 3, 'name': 'Shadow Crypt', 'align': Alignment.center},
    {'id': 4, 'name': 'Void Breach', 'align': Alignment.centerLeft},
    {'id': 5, 'name': 'Silent Citadel', 'align': Alignment.centerRight},
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await _saveService.init();
    setState(() {
      _unlockedLevels = _saveService.getUnlockedLevels();
      _completedLevels = _saveService.getCompletedLevels();
      _scores = _saveService.getScores();
      _loading = false;
    });
  }

  Future<void> _resetProgress() async {
    await _saveService.resetProgress();
    _loadProgress();
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      appBar: AppBar(
        title: const Text('SOUL PROGRESSION', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F121F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            tooltip: 'Reset Progress',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E223D),
                  title: const Text('Reset Progress?', style: TextStyle(color: Colors.white)),
                  content: const Text('This will delete all completed stages and high scores.', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetProgress();
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background atmospheric grid/glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF12162B), Color(0xFF07090F)],
                ),
              ),
            ),
          ),
          // Custom path painting
          Positioned.fill(
            child: CustomPaint(
              painter: PathPainter(levelCount: _levelConfig.length),
            ),
          ),
          // Level Nodes List
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    itemCount: _levelConfig.length,
                    itemBuilder: (context, index) {
                      final lvl = _levelConfig[index];
                      final id = lvl['id'] as int;
                      final name = lvl['name'] as String;
                      final align = lvl['align'] as Alignment;
                      
                      final isUnlocked = _unlockedLevels.contains(id);
                      final isCompleted = _completedLevels.contains(id);
                      final bestTime = _scores[id.toString()];

                      return Align(
                        alignment: align,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: _buildLevelNode(id, name, isUnlocked, isCompleted, bestTime),
                        ),
                      );
                    },
                  ),
                ),
                // Overworld Entry Seam
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF0F121F),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.explore),
                          label: const Text('ENTER ISOMETRIC OVERWORLD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          onPressed: _launchOverworld,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode(int id, String name, bool isUnlocked, bool isCompleted, int? bestTime) {
    Color nodeColor = Colors.grey.shade800;
    IconData icon = Icons.lock_outline;
    List<BoxShadow> shadows = [];

    if (isCompleted) {
      nodeColor = const Color(0xFF00E5FF);
      icon = Icons.done_all;
      shadows = [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)];
    } else if (isUnlocked) {
      nodeColor = const Color(0xFFFF2A85);
      icon = Icons.play_arrow;
      shadows = [BoxShadow(color: const Color(0xFFFF2A85).withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)];
    }

    return GestureDetector(
      onTap: isUnlocked ? () => _launchGame(id) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF0F121F),
              shape: BoxShape.circle,
              border: Border.all(color: nodeColor, width: 3),
              boxShadow: shadows,
            ),
            child: Icon(icon, color: nodeColor, size: 32),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F121F).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Text(
                  'STAGE $id: $name',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (bestTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'BEST TIME: ${bestTime}s',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final int levelCount;
  PathPainter({required this.levelCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333D6B).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Approximate paths from left-right zig-zag
    double startX = size.width * 0.15;
    double stepY = (size.height - 120) / (levelCount - 1);
    
    path.moveTo(startX, 60);

    for (int i = 1; i < levelCount; i++) {
      double targetX = (i % 2 == 1) ? size.width * 0.85 : size.width * 0.15;
      if (i == 2) targetX = size.width * 0.5; // shadow crypt centered
      
      final currentY = 60 + (i - 1) * stepY;
      final nextY = 60 + i * stepY;

      path.cubicTo(
        (i % 2 == 1) ? size.width * 0.9 : size.width * 0.1, currentY + stepY / 3,
        (i % 2 == 1) ? size.width * 0.1 : size.width * 0.9, currentY + 2 * stepY / 3,
        targetX, nextY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final String levelName;
  final double hp;
  final int litPyres;
  final int totalPyres;
  final VoidCallback onPause;

  const HudOverlay({
    super.key,
    required this.levelName,
    required this.hp,
    required this.litPyres,
    required this.totalPyres,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top HUD Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Health Hearts Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: List.generate(3, (index) {
                      final heartVal = index + 1;
                      final isFull = hp >= heartVal;
                      return Icon(
                        Icons.favorite,
                        color: isFull ? const Color(0xFF00E5FF) : Colors.white10,
                        size: 24,
                      );
                    }),
                  ),
                ),
                // Level Name / Progress Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    levelName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Pause Button
                IconButton(
                  icon: const Icon(
                    Icons.pause_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: onPause,
                ),
              ],
            ),
            const Spacer(),
            // Bottom Pyres Tracker (only in level modes where totalPyres > 0)
            if (totalPyres > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: litPyres >= totalPyres
                          ? const Color(0xFF00E5FF)
                          : Colors.white10,
                      width: 1.5,
                    ),
                    boxShadow: litPyres >= totalPyres
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: litPyres >= totalPyres
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFFFF5722),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PYRES REKINDLED: $litPyres / $totalPyres',
                        style: TextStyle(
                          color: litPyres >= totalPyres
                              ? const Color(0xFF00E5FF)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

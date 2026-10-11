import 'dart:math' as math;
import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final String levelName;
  final double hp;
  final double maxHp;
  final double mana;
  final double maxMana;
  final double dashCooldownFraction;
  final int litPyres;
  final int totalPyres;
  final int shardsCollected;
  final VoidCallback onPause;

  final double? bossHp;
  final double? bossMaxHp;
  final double? compassAngle;
  final String? compassTargetName;

  const HudOverlay({
    super.key,
    required this.levelName,
    required this.hp,
    this.maxHp = 3.0,
    this.mana = 100.0,
    this.maxMana = 100.0,
    this.dashCooldownFraction = 0.0,
    required this.litPyres,
    required this.totalPyres,
    this.shardsCollected = 0,
    required this.onPause,
    this.bossHp,
    this.bossMaxHp,
    this.compassAngle,
    this.compassTargetName,
  });

  @override
  Widget build(BuildContext context) {
    final heartCount = maxHp.ceil();
    final isDashReady = dashCooldownFraction <= 0.01;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Top HUD Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column: Health, Mana & Dash Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health Hearts Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(heartCount, (index) {
                          final heartVal = index + 1;
                          final isFull = hp >= heartVal;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Icon(
                              Icons.favorite,
                              color: isFull ? const Color(0xFF00E5FF) : Colors.white12,
                              size: 22,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Mana / Soul Energy Bar
                    Container(
                      width: 130,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (mana / maxMana).clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00B0FF), Color(0xFF00E5FF)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Dash Cooldown Status Pip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDashReady ? const Color(0xFF00E5FF) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 14,
                            color: isDashReady ? const Color(0xFF00E5FF) : Colors.white24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDashReady ? 'DASH READY' : 'RECHARGING',
                            style: TextStyle(
                              color: isDashReady ? const Color(0xFF00E5FF) : Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center Column: Boss Bar (if active) OR Compass Radar
                if (bossHp != null && bossHp! > 0 && bossMaxHp != null && bossMaxHp! > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'VOID WARDEN - ABYSSAL ARCHON',
                            style: TextStyle(
                              color: Color(0xFFFF1744),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F121F),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFF1744), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (bossHp! / bossMaxHp!).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF1744), Color(0xFFD500F9)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (compassAngle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: compassAngle! - (math.pi / 2),
                          child: const Icon(
                            Icons.navigation,
                            color: Color(0xFF00E5FF),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          compassTargetName ?? 'TARGET',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Right Column: Level Name, Shards Counter & Pause Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Soul Shards Count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$shardsCollected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Level Name Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        levelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Pause Button
                    IconButton(
                      icon: const Icon(
                        Icons.pause_circle_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: onPause,
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Bottom Pyres Tracker (only in level modes where totalPyres > 0)
            if (totalPyres > 0)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F121F).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: litPyres >= totalPyres ? const Color(0xFF00E5FF) : Colors.white12,
                      width: 1.5,
                    ),
                    boxShadow: litPyres >= totalPyres
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
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
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        litPyres >= totalPyres
                            ? 'PORTAL ACTIVATED! FIND THE RIFT'
                            : 'PYRES REKINDLED: $litPyres / $totalPyres',
                        style: TextStyle(
                          color: litPyres >= totalPyres ? const Color(0xFF00E5FF) : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12,
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

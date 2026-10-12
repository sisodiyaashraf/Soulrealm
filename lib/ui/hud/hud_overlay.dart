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

  final int comboCount;
  final bool isSoulSurge;
  final int flaskCharges;
  final VoidCallback? onUseFlask;

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
    this.comboCount = 0,
    this.isSoulSurge = false,
    this.flaskCharges = 2,
    this.onUseFlask,
  });

  @override
  Widget build(BuildContext context) {
    final heartCount = maxHp.ceil();
    final isDashReady = dashCooldownFraction <= 0.01;
    final isLowHp = hp <= 1.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                    // Health Hearts Vessel Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLowHp ? const Color(0xFFFF1744) : Colors.white12,
                          width: isLowHp ? 1.8 : 1.0,
                        ),
                        boxShadow: isLowHp
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF1744).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
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
                              color: isFull
                                  ? (isLowHp ? const Color(0xFFFF1744) : const Color(0xFF00E5FF))
                                  : Colors.white12,
                              size: 20,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Mana / Soul Energy Bar with Text readout
                    Container(
                      width: 136,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
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
                          Center(
                            child: Text(
                              '${mana.toInt()} / ${maxMana.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Row: Dash Cooldown Status + Aether Flask Potion
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dash Pip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
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
                                size: 13,
                                color: isDashReady ? const Color(0xFF00E5FF) : Colors.white24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDashReady ? 'DASH READY' : 'RECHARGING',
                                style: TextStyle(
                                  color: isDashReady ? const Color(0xFF00E5FF) : Colors.white54,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Aether Flask Quick Heal Potion
                        if (onUseFlask != null)
                          GestureDetector(
                            onTap: flaskCharges > 0 ? onUseFlask : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: flaskCharges > 0
                                    ? const Color(0xFF00E676).withValues(alpha: 0.2)
                                    : const Color(0xFF0C0E1A).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: flaskCharges > 0 ? const Color(0xFF00E676) : Colors.white12,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_drink,
                                    size: 13,
                                    color: flaskCharges > 0 ? const Color(0xFF00E676) : Colors.white24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'FLASK x$flaskCharges',
                                    style: TextStyle(
                                      color: flaskCharges > 0 ? const Color(0xFF00E676) : Colors.white38,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Center Column: Boss Bar (if active) OR Compass Radar OR Combo Streak
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (bossHp != null && bossHp! > 0 && bossMaxHp != null && bossMaxHp! > 0) ...[
                          const Text(
                            'VOID WARDEN - ABYSSAL ARCHON',
                            style: TextStyle(
                              color: Color(0xFFFF1744),
                              fontSize: 10,
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
                        ] else if (compassAngle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
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
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  compassTargetName ?? 'TARGET',
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Combo Streak & Soul Surge Badge
                        if (comboCount >= 2) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSoulSurge
                                  ? const Color(0xFFFFEA00).withValues(alpha: 0.2)
                                  : const Color(0xFFFF2A85).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSoulSurge ? const Color(0xFFFFEA00) : const Color(0xFFFF2A85),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSoulSurge ? const Color(0xFFFFEA00) : const Color(0xFFFF2A85))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSoulSurge ? Icons.bolt : Icons.local_fire_department,
                                  size: 13,
                                  color: isSoulSurge ? const Color(0xFFFFEA00) : const Color(0xFFFF2A85),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSoulSurge ? 'SOUL SURGE ACTIVE! (x$comboCount)' : 'x$comboCount STREAK',
                                  style: TextStyle(
                                    color: isSoulSurge ? const Color(0xFFFFEA00) : Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Right Column: Level Name, Shards Counter & Pause Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Soul Shards Count Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '+$shardsCollected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Level Name Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        levelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    // Pause Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: onPause,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0E1A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: litPyres >= totalPyres ? const Color(0xFF00E5FF) : Colors.white12,
                      width: 1.5,
                    ),
                    boxShadow: litPyres >= totalPyres
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 12,
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        litPyres >= totalPyres
                            ? 'PORTAL ACTIVATED! FIND THE RIFT'
                            : 'PYRES REKINDLED: $litPyres / $totalPyres',
                        style: TextStyle(
                          color: litPyres >= totalPyres ? const Color(0xFF00E5FF) : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          fontSize: 11,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/save_service.dart';

class ShrineDialog extends StatefulWidget {
  final VoidCallback onUpdated;

  const ShrineDialog({super.key, required this.onUpdated});

  @override
  State<ShrineDialog> createState() => _ShrineDialogState();
}

class _ShrineDialogState extends State<ShrineDialog> {
  final SaveService _saveService = SaveService();

  late int _shards;
  late int _healthLevel;
  late int _speedLevel;
  late int _damageLevel;
  late int _dashLevel;
  late int _manaLevel;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _shards = _saveService.getSoulShards();
      _healthLevel = _saveService.getUpgradeLevel('health');
      _speedLevel = _saveService.getUpgradeLevel('speed');
      _damageLevel = _saveService.getUpgradeLevel('damage');
      _dashLevel = _saveService.getUpgradeLevel('dash');
      _manaLevel = _saveService.getUpgradeLevel('mana');
    });
  }

  Future<void> _buy(String statKey) async {
    final success = await _saveService.purchaseUpgrade(statKey);
    if (success) {
      if (_saveService.getHaptics()) {
        HapticFeedback.mediumImpact();
      }
      _refreshStats();
      widget.onUpdated();
    } else {
      if (_saveService.getHaptics()) {
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 600),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0E1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VOID FORGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'SANCTUARY OF ASCENSION • TRANSCEND YOUR SOUL',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Shards badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13172E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_shards',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),

            // Scrollable Upgrade Cards
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildUpgradeTile(
                      title: 'VESSEL FORTITUDE',
                      subtitle: 'Expands maximum Life Hearts (+1 Heart per tier)',
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFFF2A85),
                      currentLevel: _healthLevel,
                      currentStatDesc: '${(3 + _healthLevel)} Hearts Max',
                      cost: _saveService.getNextUpgradeCost('health'),
                      onBuy: () => _buy('health'),
                    ),
                    _buildUpgradeTile(
                      title: 'VOID SWIFTNESS',
                      subtitle: 'Accelerates movement stride velocity (+15%)',
                      icon: Icons.directions_run,
                      iconColor: const Color(0xFF00E5FF),
                      currentLevel: _speedLevel,
                      currentStatDesc: '${(120 + _speedLevel * 15).toInt()} Move Spd',
                      cost: _saveService.getNextUpgradeCost('speed'),
                      onBuy: () => _buy('speed'),
                    ),
                    _buildUpgradeTile(
                      title: 'SOUL EDGE',
                      subtitle: 'Empowers Melee Slashes and Soul Bolts (+50% DMG)',
                      icon: Icons.flash_on,
                      iconColor: const Color(0xFFFFEA00),
                      currentLevel: _damageLevel,
                      currentStatDesc: '${(1.0 + _damageLevel * 0.5).toStringAsFixed(1)} Base Dmg',
                      cost: _saveService.getNextUpgradeCost('damage'),
                      onBuy: () => _buy('damage'),
                    ),
                    _buildUpgradeTile(
                      title: 'AETHER PHASE',
                      subtitle: 'Reduces Soul Dash recovery cooldown (-25%)',
                      icon: Icons.hourglass_empty,
                      iconColor: const Color(0xFF7C4DFF),
                      currentLevel: _dashLevel,
                      currentStatDesc: '${(1.4 - _dashLevel * 0.25).toStringAsFixed(2)}s Cooldown',
                      cost: _saveService.getNextUpgradeCost('dash'),
                      onBuy: () => _buy('dash'),
                    ),
                    _buildUpgradeTile(
                      title: 'AETHER RESERVOIR',
                      subtitle: 'Expands Soul Mana cap (+25) and quickens regen (+25%)',
                      icon: Icons.waves,
                      iconColor: const Color(0xFF00E676),
                      currentLevel: _manaLevel,
                      currentStatDesc: '${(100 + _manaLevel * 25).toInt()} Max Mana',
                      cost: _saveService.getNextUpgradeCost('mana'),
                      onBuy: () => _buy('mana'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E223D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CLOSE FORGE',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int currentLevel,
    required String currentStatDesc,
    required int cost,
    required VoidCallback onBuy,
  }) {
    final isMax = cost < 0;
    final canAfford = !isMax && _shards >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      currentStatDesc,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 6),
                // Level Pips (3 pips)
                Row(
                  children: List.generate(3, (index) {
                    final active = index < currentLevel;
                    return Container(
                      width: 24,
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: active ? iconColor : Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Buy Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMax
                  ? Colors.white12
                  : (canAfford ? const Color(0xFF00E5FF) : Colors.white12),
              foregroundColor: canAfford ? Colors.black : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: canAfford ? 4 : 0,
            ),
            onPressed: canAfford ? onBuy : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMax) ...[
                  const Icon(Icons.diamond_outlined, size: 13),
                  const SizedBox(width: 4),
                  Text('$cost', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ] else ...[
                  const Text('MAX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

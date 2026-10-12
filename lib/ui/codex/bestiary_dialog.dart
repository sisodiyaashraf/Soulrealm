import 'package:flutter/material.dart';
import '../../services/save_service.dart';

class BestiaryDialog extends StatefulWidget {
  const BestiaryDialog({super.key});

  @override
  State<BestiaryDialog> createState() => _BestiaryDialogState();
}

class _BestiaryDialogState extends State<BestiaryDialog> {
  final SaveService _saveService = SaveService();
  int _selectedCategoryIndex = 0; // 0: Foes, 1: Relics
  int _selectedEntryIndex = 0;

  final List<Map<String, dynamic>> _foes = [
    {
      'name': 'VOID LURKER',
      'title': 'Shadow Hound of the Abyss',
      'tier': 'MINION',
      'color': Color(0xFFFF2A85),
      'icon': Icons.pest_control,
      'hp': '2.0 HP',
      'damage': '1.0 DMG',
      'behavior': 'Patrols shattered paths and charges fiercely upon sensing mortal soul light.',
      'weakness': 'Vulnerable to Soul Dash dodge-counters and quick melee strikes.',
      'drops': '1 Soul Shard on demise.',
    },
    {
      'name': 'VOID CASTER',
      'title': 'Abyssal Sorcerer',
      'tier': 'ELITE',
      'color': Color(0xFF7C4DFF),
      'icon': Icons.science_outlined,
      'hp': '2.0 HP',
      'damage': '1.0 Ranged Orb',
      'behavior': 'Maintains tactical standoff distance and casts guided void orbs from afar.',
      'weakness': 'Retreats when rushed; strike during its orb charging windup or counter with Soul Bolt.',
      'drops': '2 Soul Shards upon dissipation.',
    },
    {
      'name': 'VOID WARDEN',
      'title': 'Archon of the Silent Citadel',
      'tier': 'BOSS ARCHON',
      'color': Color(0xFFFF1744),
      'icon': Icons.dangerous_outlined,
      'hp': '15.0 HP',
      'damage': '1.5 - 2.0 Heavy Strike',
      'behavior': 'Unleashes 3-way void projectile spreads and enters blazing enrage at 40% HP with ruthless rush attacks.',
      'weakness': 'Dodge through the charge using Soul Dash invulnerability and unleash Soul Bolts while it recovers.',
      'drops': '8 Soul Shards fountain burst and Citadel victory.',
    },
  ];

  final List<Map<String, dynamic>> _relics = [
    {
      'name': 'SACRED PYRE',
      'title': 'Embers of the Ancients',
      'tier': 'SANCTUARY RELIC',
      'color': Color(0xFFFF9100),
      'icon': Icons.local_fire_department,
      'hp': 'Indestructible',
      'damage': 'Purifying Aura',
      'behavior': 'Ancient fire urns placed by elder spirits. Rekindling all Pyres destabilizes the Void and opens the stage exit portal.',
      'weakness': 'Rekindle by standing near or striking with sword slashes.',
      'drops': 'Rift portal activation.',
    },
    {
      'name': 'AETHER SPRING',
      'title': 'Fountain of Rejuvenation',
      'tier': 'SANCTUM WELL',
      'color': Color(0xFF00E5FF),
      'icon': Icons.water_drop,
      'hp': 'Infinite',
      'damage': 'Restorative',
      'behavior': 'Pure crystalline energy rising from the overworld depth. Step into its pool to completely mend your mortal vessel.',
      'weakness': 'Refreshes every 3 seconds while standing in proximity.',
      'drops': 'Full Life Vessel replenishment.',
    },
    {
      'name': 'LORE OBELISK',
      'title': 'Chronicles of Purgatory',
      'tier': 'HISTORICAL ARTIFACT',
      'color': Color(0xFFFF4081),
      'icon': Icons.auto_stories,
      'hp': 'Ancient Stone',
      'damage': 'Enlightenment',
      'behavior': 'Carved monolith etched with celestial runes explaining the fall of Soulrealm and the Void Eclipse.',
      'weakness': 'Walk adjacent to decrypt ancient scriptures.',
      'drops': 'Forbidden knowledge.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedCategoryIndex == 0 ? _foes : _relics;
    final entry = activeList[_selectedEntryIndex.clamp(0, activeList.length - 1)];
    final kills = _saveService.getTotalEnemiesSlain();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0E1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              blurRadius: 30,
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
                      child: const Icon(Icons.menu_book, color: Color(0xFF00E5FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SHADOW CODEX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        Text(
                          'ENTITIES & RELICS OF THE VOID • $kills FOES SLAIN',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Selector Tabs
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = 0;
                        _selectedEntryIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 0
                            ? const Color(0xFF1E2442)
                            : const Color(0xFF101322),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedCategoryIndex == 0
                              ? const Color(0xFFFF2A85)
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'ABYSSAL FOES (${_foes.length})',
                          style: TextStyle(
                            color: _selectedCategoryIndex == 0
                                ? const Color(0xFFFF2A85)
                                : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = 1;
                        _selectedEntryIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 1
                            ? const Color(0xFF1E2442)
                            : const Color(0xFF101322),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedCategoryIndex == 1
                              ? const Color(0xFF00E5FF)
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'SACRED RELICS (${_relics.length})',
                          style: TextStyle(
                            color: _selectedCategoryIndex == 1
                                ? const Color(0xFF00E5FF)
                                : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Area: Left side list, Right side detail
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side list
                  SizedBox(
                    width: 170,
                    child: ListView.separated(
                      itemCount: activeList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final item = activeList[idx];
                        final isSelected = idx == _selectedEntryIndex;
                        final color = item['color'] as Color;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEntryIndex = idx;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : const Color(0xFF13172E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : Colors.white10,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, color: color, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['name'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right side detail view
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13172E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (entry['color'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tier & Name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (entry['color'] as Color).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry['tier'] as String,
                                    style: TextStyle(
                                      color: entry['color'] as Color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      entry['hp'] as String,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry['damage'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFFFF5252),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              entry['title'] as String,
                              style: TextStyle(
                                color: (entry['color'] as Color).withValues(alpha: 0.8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),

                            // Lore / Behavior
                            const Text(
                              'BEHAVIOR & NATURE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry['behavior'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                            ),
                            const SizedBox(height: 10),

                            // Tactical / Weakness
                            const Text(
                              'COMBAT TACTIC & VULNERABILITY',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry['weakness'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                            ),
                            const SizedBox(height: 10),

                            // Drops
                            const Text(
                              'REWARDS & DROPS',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry['drops'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

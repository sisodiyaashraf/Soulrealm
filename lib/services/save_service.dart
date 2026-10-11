import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const String _keyCompleted = 'soulrealm_completed_levels';
  static const String _keyUnlocked = 'soulrealm_unlocked_levels';
  static const String _keyScores = 'soulrealm_scores';
  static const String _keyOverworldX = 'soulrealm_overworld_x';
  static const String _keyOverworldY = 'soulrealm_overworld_y';
  static const String _keyShards = 'soulrealm_soul_shards';
  static const String _keyStars = 'soulrealm_level_stars';
  static const String _keyUpgradeHealth = 'soulrealm_upgrade_health';
  static const String _keyUpgradeSpeed = 'soulrealm_upgrade_speed';
  static const String _keyUpgradeDamage = 'soulrealm_upgrade_damage';
  static const String _keyUpgradeDash = 'soulrealm_upgrade_dash';

  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;
  SaveService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Get completed levels
  List<int> getCompletedLevels() {
    final list = _prefs.getStringList(_keyCompleted);
    if (list == null) return [];
    return list.map((e) => int.parse(e)).toList();
  }

  // Complete a level and unlock the next one
  Future<void> completeLevel(int levelId) async {
    final completed = getCompletedLevels();
    if (!completed.contains(levelId)) {
      completed.add(levelId);
      await _prefs.setStringList(_keyCompleted, completed.map((e) => e.toString()).toList());
    }

    // Unlock next level (e.g., if we complete level 1, level 2 is unlocked)
    final nextLevel = levelId + 1;
    await unlockLevel(nextLevel);
  }

  // Get unlocked levels (level 1 is unlocked by default)
  List<int> getUnlockedLevels() {
    final list = _prefs.getStringList(_keyUnlocked);
    if (list == null) return [1]; // Level 1 is always unlocked
    final unlocked = list.map((e) => int.parse(e)).toList();
    if (!unlocked.contains(1)) unlocked.add(1);
    return unlocked;
  }

  // Unlock a level
  Future<void> unlockLevel(int levelId) async {
    final unlocked = getUnlockedLevels();
    if (!unlocked.contains(levelId)) {
      unlocked.add(levelId);
      await _prefs.setStringList(_keyUnlocked, unlocked.map((e) => e.toString()).toList());
    }
  }

  // Save level high score (fastest time in seconds)
  Future<void> saveScore(int levelId, int seconds) async {
    final scoresMap = getScores();
    final currentBest = scoresMap[levelId.toString()];
    if (currentBest == null || seconds < currentBest) {
      scoresMap[levelId.toString()] = seconds;
      await _prefs.setString(_keyScores, jsonEncode(scoresMap));
    }
  }

  // Get all scores
  Map<String, int> getScores() {
    final jsonStr = _prefs.getString(_keyScores);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  // --- SOUL SHARDS CURRENCY ---
  int getSoulShards() {
    return _prefs.getInt(_keyShards) ?? 0;
  }

  Future<void> addSoulShards(int count) async {
    final current = getSoulShards();
    await _prefs.setInt(_keyShards, current + count);
  }

  Future<bool> spendSoulShards(int count) async {
    final current = getSoulShards();
    if (current >= count) {
      await _prefs.setInt(_keyShards, current - count);
      return true;
    }
    return false;
  }

  // --- UPGRADES ---
  // Upgrade keys: 'health', 'speed', 'damage', 'dash' (each max level 3)
  int getUpgradeLevel(String statKey) {
    switch (statKey) {
      case 'health':
        return _prefs.getInt(_keyUpgradeHealth) ?? 0;
      case 'speed':
        return _prefs.getInt(_keyUpgradeSpeed) ?? 0;
      case 'damage':
        return _prefs.getInt(_keyUpgradeDamage) ?? 0;
      case 'dash':
        return _prefs.getInt(_keyUpgradeDash) ?? 0;
      default:
        return 0;
    }
  }

  // Costs for upgrade levels 1, 2, 3
  static const Map<String, List<int>> upgradeCosts = {
    'health': [15, 30, 50],
    'speed': [12, 25, 45],
    'damage': [20, 40, 65],
    'dash': [15, 30, 50],
  };

  int getNextUpgradeCost(String statKey) {
    final currentLevel = getUpgradeLevel(statKey);
    final costs = upgradeCosts[statKey];
    if (costs != null && currentLevel < costs.length) {
      return costs[currentLevel];
    }
    return -1; // Maxed out
  }

  Future<bool> purchaseUpgrade(String statKey) async {
    final cost = getNextUpgradeCost(statKey);
    if (cost < 0) return false;
    final currentShards = getSoulShards();
    if (currentShards < cost) return false;

    final success = await spendSoulShards(cost);
    if (success) {
      final currentLevel = getUpgradeLevel(statKey);
      final newLevel = currentLevel + 1;
      switch (statKey) {
        case 'health':
          await _prefs.setInt(_keyUpgradeHealth, newLevel);
          break;
        case 'speed':
          await _prefs.setInt(_keyUpgradeSpeed, newLevel);
          break;
        case 'damage':
          await _prefs.setInt(_keyUpgradeDamage, newLevel);
          break;
        case 'dash':
          await _prefs.setInt(_keyUpgradeDash, newLevel);
          break;
      }
      return true;
    }
    return false;
  }

  // Derived gameplay stats based on upgrades
  double getMaxHealth() {
    final level = getUpgradeLevel('health');
    return 3.0 + level; // 3.0, 4.0, 5.0, 6.0
  }

  double getPlayerSpeed() {
    final level = getUpgradeLevel('speed');
    return 120.0 + (level * 15.0); // 120, 135, 150, 165
  }

  double getPlayerDamage() {
    final level = getUpgradeLevel('damage');
    return 1.0 + (level * 0.5); // 1.0, 1.5, 2.0, 2.5
  }

  double getDashCooldownSeconds() {
    final level = getUpgradeLevel('dash');
    return 1.4 - (level * 0.25); // 1.4s, 1.15s, 0.9s, 0.65s
  }

  // --- STAR RATINGS (1 - 3 stars per stage) ---
  int getLevelStars(int levelId) {
    final starsMap = getAllStars();
    return starsMap[levelId.toString()] ?? 0;
  }

  Map<String, int> getAllStars() {
    final jsonStr = _prefs.getString(_keyStars);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLevelStars(int levelId, int stars) async {
    final starsMap = getAllStars();
    final currentStars = starsMap[levelId.toString()] ?? 0;
    if (stars > currentStars) {
      starsMap[levelId.toString()] = stars;
      await _prefs.setString(_keyStars, jsonEncode(starsMap));
    }
  }

  int getTotalStars() {
    final starsMap = getAllStars();
    return starsMap.values.fold(0, (sum, val) => sum + val);
  }

  // Save last player position in overworld
  Future<void> saveOverworldPosition(double x, double y) async {
    await _prefs.setDouble(_keyOverworldX, x);
    await _prefs.setDouble(_keyOverworldY, y);
  }

  // Get last player position in overworld (returns null if not saved)
  Map<String, double>? getOverworldPosition() {
    final x = _prefs.getDouble(_keyOverworldX);
    final y = _prefs.getDouble(_keyOverworldY);
    if (x == null || y == null) return null;
    return {'x': x, 'y': y};
  }

  // Reset progress
  Future<void> resetProgress() async {
    await _prefs.remove(_keyCompleted);
    await _prefs.remove(_keyUnlocked);
    await _prefs.remove(_keyScores);
    await _prefs.remove(_keyOverworldX);
    await _prefs.remove(_keyOverworldY);
    await _prefs.remove(_keyShards);
    await _prefs.remove(_keyStars);
    await _prefs.remove(_keyUpgradeHealth);
    await _prefs.remove(_keyUpgradeSpeed);
    await _prefs.remove(_keyUpgradeDamage);
    await _prefs.remove(_keyUpgradeDash);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const String _keyCompleted = 'soulrealm_completed_levels';
  static const String _keyUnlocked = 'soulrealm_unlocked_levels';
  static const String _keyScores = 'soulrealm_scores';
  static const String _keyOverworldX = 'soulrealm_overworld_x';
  static const String _keyOverworldY = 'soulrealm_overworld_y';

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
  }
}

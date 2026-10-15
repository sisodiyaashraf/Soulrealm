import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class GamesServicesWrapper {
  static final GamesServicesWrapper _instance = GamesServicesWrapper._internal();
  factory GamesServicesWrapper() => _instance;
  GamesServicesWrapper._internal();

  bool _isConnected = false;

  // Platform check
  bool get isSupportedPlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  // Initialize and sign in
  Future<void> initialize() async {
    if (!isSupportedPlatform) {
      developer.log("GamesServices: Not supported on this platform.");
      return;
    }

    try {
      await GamesServices.signIn().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          developer.log("GamesServices: Sign-in timed out.");
          return;
        },
      );
      _isConnected = true;
      developer.log("GamesServices: Successfully signed in.");
    } catch (e) {
      _isConnected = false;
      developer.log("GamesServices Error signing in: $e");
    }
  }

  // Show Achievements UI
  Future<void> showAchievements() async {
    if (!isSupportedPlatform || !_isConnected) return;
    try {
      await GamesServices.showAchievements();
    } catch (e) {
      developer.log("GamesServices Error showing achievements: $e");
    }
  }

  // Show Leaderboard UI
  Future<void> showLeaderboard({required String androidId, required String iosId}) async {
    if (!isSupportedPlatform || !_isConnected) return;
    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: androidId,
        iOSLeaderboardID: iosId,
      );
    } catch (e) {
      developer.log("GamesServices Error showing leaderboard: $e");
    }
  }

  // Submit high score
  Future<void> submitScore({
    required String androidLeaderboardId,
    required String iosLeaderboardId,
    required int scoreValue,
  }) async {
    if (!isSupportedPlatform || !_isConnected) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: androidLeaderboardId,
          iOSLeaderboardID: iosLeaderboardId,
          value: scoreValue,
        ),
      );
      developer.log("GamesServices: Submitted score $scoreValue.");
    } catch (e) {
      developer.log("GamesServices Error submitting score: $e");
    }
  }

  // Unlock an achievement
  Future<void> unlockAchievement({
    required String androidAchievementId,
    required String iosAchievementId,
  }) async {
    if (!isSupportedPlatform || !_isConnected) return;
    try {
      await GamesServices.unlock(
        achievement: Achievement(
          androidID: androidAchievementId,
          iOSID: iosAchievementId,
        ),
      );
      developer.log("GamesServices: Unlocked achievement.");
    } catch (e) {
      developer.log("GamesServices Error unlocking achievement: $e");
    }
  }
}

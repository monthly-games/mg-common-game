import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks various game statistics
class StatisticsManager extends ChangeNotifier {
  // Lifetime stats
  int _totalGamesPlayed = 0;
  int _totalPlayTimeSeconds = 0;
  int _totalGoldEarned = 0;
  int _totalXpEarned = 0;
  int _totalDailyQuestsCompleted = 0;
  int _totalAchievementsUnlocked = 0;
  int _totalPrestigesPerformed = 0;

  // Current session stats
  DateTime? _sessionStartTime;
  int _sessionGamesPlayed = 0;
  int _sessionGoldEarned = 0;
  int _sessionXpEarned = 0;

  // High scores / records
  int _highestLevel = 1;
  int _mostGoldInSingleGame = 0;
  int _longestSessionSeconds = 0;

  // Getters - Lifetime stats
  int get totalGamesPlayed => _totalGamesPlayed;
  int get totalPlayTimeSeconds => _totalPlayTimeSeconds;
  int get totalGoldEarned => _totalGoldEarned;
  int get totalXpEarned => _totalXpEarned;
  int get totalDailyQuestsCompleted => _totalDailyQuestsCompleted;
  int get totalAchievementsUnlocked => _totalAchievementsUnlocked;
  int get totalPrestigesPerformed => _totalPrestigesPerformed;

  // Getters - Session stats
  int get sessionGamesPlayed => _sessionGamesPlayed;
  int get sessionGoldEarned => _sessionGoldEarned;
  int get sessionXpEarned => _sessionXpEarned;
  int get currentSessionTimeSeconds {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  // Getters - Records
  int get highestLevel => _highestLevel;
  int get mostGoldInSingleGame => _mostGoldInSingleGame;
  int get longestSessionSeconds => _longestSessionSeconds;

  // Calculated stats
  String get totalPlayTimeFormatted => _formatDuration(_totalPlayTimeSeconds);
  String get currentSessionTimeFormatted => _formatDuration(currentSessionTimeSeconds);
  double get averageGoldPerGame =>
      _totalGamesPlayed > 0 ? _totalGoldEarned / _totalGamesPlayed : 0;
  double get averageXpPerGame =>
      _totalGamesPlayed > 0 ? _totalXpEarned / _totalGamesPlayed : 0;

  /// Start a new session
  void startSession() {
    _sessionStartTime = DateTime.now();
    _sessionGamesPlayed = 0;
    _sessionGoldEarned = 0;
    _sessionXpEarned = 0;
  }

  /// End current session and save stats
  Future<void> endSession() async {
    if (_sessionStartTime != null) {
      final sessionTime = currentSessionTimeSeconds;
      _totalPlayTimeSeconds += sessionTime;

      if (sessionTime > _longestSessionSeconds) {
        _longestSessionSeconds = sessionTime;
      }
    }

    _sessionStartTime = null;
    await saveStats();
  }

  /// Record a game played
  void recordGamePlayed({int goldEarned = 0, int xpEarned = 0}) {
    _totalGamesPlayed++;
    _sessionGamesPlayed++;

    _totalGoldEarned += goldEarned;
    _sessionGoldEarned += goldEarned;

    _totalXpEarned += xpEarned;
    _sessionXpEarned += xpEarned;

    if (goldEarned > _mostGoldInSingleGame) {
      _mostGoldInSingleGame = goldEarned;
    }

    notifyListeners();
    saveStats();
  }

  /// Record gold earned (for incremental tracking)
  void recordGoldEarned(int amount) {
    if (amount <= 0) return;
    _totalGoldEarned += amount;
    _sessionGoldEarned += amount;
    notifyListeners();
  }

  /// Record XP earned (for incremental tracking)
  void recordXpEarned(int amount) {
    if (amount <= 0) return;
    _totalXpEarned += amount;
    _sessionXpEarned += amount;
    notifyListeners();
  }

  /// Record level reached
  void recordLevelReached(int level) {
    if (level > _highestLevel) {
      _highestLevel = level;
      notifyListeners();
      saveStats();
    }
  }

  /// Record daily quest completed
  void recordDailyQuestCompleted() {
    _totalDailyQuestsCompleted++;
    notifyListeners();
    saveStats();
  }

  /// Record achievement unlocked
  void recordAchievementUnlocked() {
    _totalAchievementsUnlocked++;
    notifyListeners();
    saveStats();
  }

  /// Record prestige performed
  void recordPrestigePerformed() {
    _totalPrestigesPerformed++;
    notifyListeners();
    saveStats();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  // ========== SAVE/LOAD SYSTEM ==========

  /// Save statistics to SharedPreferences
  Future<void> saveStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Lifetime stats
    await prefs.setInt('stats_total_games_played', _totalGamesPlayed);
    await prefs.setInt('stats_total_play_time', _totalPlayTimeSeconds);
    await prefs.setInt('stats_total_gold_earned', _totalGoldEarned);
    await prefs.setInt('stats_total_xp_earned', _totalXpEarned);
    await prefs.setInt('stats_total_quests_completed', _totalDailyQuestsCompleted);
    await prefs.setInt('stats_total_achievements', _totalAchievementsUnlocked);
    await prefs.setInt('stats_total_prestiges', _totalPrestigesPerformed);

    // Records
    await prefs.setInt('stats_highest_level', _highestLevel);
    await prefs.setInt('stats_most_gold_single_game', _mostGoldInSingleGame);
    await prefs.setInt('stats_longest_session', _longestSessionSeconds);
  }

  /// Load statistics from SharedPreferences
  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Lifetime stats
    _totalGamesPlayed = prefs.getInt('stats_total_games_played') ?? 0;
    _totalPlayTimeSeconds = prefs.getInt('stats_total_play_time') ?? 0;
    _totalGoldEarned = prefs.getInt('stats_total_gold_earned') ?? 0;
    _totalXpEarned = prefs.getInt('stats_total_xp_earned') ?? 0;
    _totalDailyQuestsCompleted = prefs.getInt('stats_total_quests_completed') ?? 0;
    _totalAchievementsUnlocked = prefs.getInt('stats_total_achievements') ?? 0;
    _totalPrestigesPerformed = prefs.getInt('stats_total_prestiges') ?? 0;

    // Records
    _highestLevel = prefs.getInt('stats_highest_level') ?? 1;
    _mostGoldInSingleGame = prefs.getInt('stats_most_gold_single_game') ?? 0;
    _longestSessionSeconds = prefs.getInt('stats_longest_session') ?? 0;

    notifyListeners();
  }

  /// Clear all statistics
  Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('stats_total_games_played');
    await prefs.remove('stats_total_play_time');
    await prefs.remove('stats_total_gold_earned');
    await prefs.remove('stats_total_xp_earned');
    await prefs.remove('stats_total_quests_completed');
    await prefs.remove('stats_total_achievements');
    await prefs.remove('stats_total_prestiges');
    await prefs.remove('stats_highest_level');
    await prefs.remove('stats_most_gold_single_game');
    await prefs.remove('stats_longest_session');

    // Reset all values
    _totalGamesPlayed = 0;
    _totalPlayTimeSeconds = 0;
    _totalGoldEarned = 0;
    _totalXpEarned = 0;
    _totalDailyQuestsCompleted = 0;
    _totalAchievementsUnlocked = 0;
    _totalPrestigesPerformed = 0;
    _highestLevel = 1;
    _mostGoldInSingleGame = 0;
    _longestSessionSeconds = 0;

    notifyListeners();
  }

  /// Reset session stats only
  void resetSessionStats() {
    _sessionGamesPlayed = 0;
    _sessionGoldEarned = 0;
    _sessionXpEarned = 0;
    notifyListeners();
  }
}

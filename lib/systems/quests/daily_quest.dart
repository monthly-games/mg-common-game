import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single daily quest
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int goldReward;
  final int xpReward;

  int _currentProgress = 0;
  bool _isCompleted = false;
  bool _isClaimedReward = false;

  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.goldReward,
    required this.xpReward,
  });

  int get currentProgress => _currentProgress;
  bool get isCompleted => _isCompleted;
  bool get isClaimedReward => _isClaimedReward;

  double get progressPercentage => (_currentProgress / targetValue).clamp(0.0, 1.0);

  /// Add progress to the quest
  void addProgress(int amount) {
    if (_isCompleted) return;

    _currentProgress += amount;
    if (_currentProgress >= targetValue) {
      _currentProgress = targetValue;
      _isCompleted = true;
    }
  }

  /// Set progress directly
  void setProgress(int progress) {
    _currentProgress = progress.clamp(0, targetValue);
    _isCompleted = _currentProgress >= targetValue;
  }

  /// Claim the quest reward
  bool claimReward() {
    if (!_isCompleted || _isClaimedReward) return false;
    _isClaimedReward = true;
    return true;
  }

  /// Reset quest to initial state
  void reset() {
    _currentProgress = 0;
    _isCompleted = false;
    _isClaimedReward = false;
  }
}

/// Manages daily quests
class DailyQuestManager extends ChangeNotifier {
  final Map<String, DailyQuest> _quests = {};
  DateTime? _lastResetDate;

  List<DailyQuest> get allQuests => _quests.values.toList();
  List<DailyQuest> get activeQuests =>
      _quests.values.where((q) => !q.isClaimedReward).toList();
  List<DailyQuest> get completedQuests =>
      _quests.values.where((q) => q.isCompleted && !q.isClaimedReward).toList();

  int get completedQuestCount =>
      _quests.values.where((q) => q.isCompleted).length;
  int get totalQuestCount => _quests.length;

  /// Register a daily quest
  void registerQuest(DailyQuest quest) {
    _quests[quest.id] = quest;
    notifyListeners();
  }

  /// Get a specific quest
  DailyQuest? getQuest(String id) => _quests[id];

  /// Add progress to a specific quest
  void addProgress(String questId, int amount) {
    final quest = _quests[questId];
    if (quest == null) return;

    quest.addProgress(amount);
    notifyListeners();

    // Auto-save progress
    saveQuestData();
  }

  /// Claim reward for a quest
  /// Returns true if reward was claimed successfully
  bool claimQuestReward(String questId) {
    final quest = _quests[questId];
    if (quest == null) return false;

    final claimed = quest.claimReward();
    if (claimed) {
      notifyListeners();
      saveQuestData();
    }
    return claimed;
  }

  /// Check if quests need to be reset (daily)
  Future<void> checkAndResetIfNeeded() async {
    final now = DateTime.now();

    // Load last reset date if not loaded
    if (_lastResetDate == null) {
      await _loadLastResetDate();
    }

    // Check if we need to reset (new day)
    if (_lastResetDate == null || !_isSameDay(_lastResetDate!, now)) {
      await resetDailyQuests();
      _lastResetDate = now;
      await _saveLastResetDate();
    }
  }

  /// Reset all quests (called at midnight)
  Future<void> resetDailyQuests() async {
    for (final quest in _quests.values) {
      quest.reset();
    }
    notifyListeners();
    await saveQuestData();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // ========== SAVE/LOAD SYSTEM ==========

  /// Save quest progress to SharedPreferences
  Future<void> saveQuestData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final quest in _quests.values) {
      await prefs.setInt('quest_progress_${quest.id}', quest.currentProgress);
      await prefs.setBool('quest_completed_${quest.id}', quest.isCompleted);
      await prefs.setBool('quest_claimed_${quest.id}', quest.isClaimedReward);
    }
  }

  /// Load quest progress from SharedPreferences
  Future<void> loadQuestData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final quest in _quests.values) {
      final progress = prefs.getInt('quest_progress_${quest.id}') ?? 0;
      quest.setProgress(progress);

      // Note: completed and claimed status will be derived from progress
      // or we can explicitly save/load them if needed
    }

    notifyListeners();
  }

  Future<void> _saveLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastResetDate != null) {
      await prefs.setString('daily_quest_last_reset', _lastResetDate!.toIso8601String());
    }
  }

  Future<void> _loadLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('daily_quest_last_reset');
    if (dateStr != null) {
      _lastResetDate = DateTime.parse(dateStr);
    }
  }

  /// Clear all quest data
  Future<void> clearQuestData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final quest in _quests.values) {
      await prefs.remove('quest_progress_${quest.id}');
      await prefs.remove('quest_completed_${quest.id}');
      await prefs.remove('quest_claimed_${quest.id}');
    }

    await prefs.remove('daily_quest_last_reset');
  }
}

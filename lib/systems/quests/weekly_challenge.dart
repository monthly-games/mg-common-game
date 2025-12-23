import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Difficulty tier for weekly challenges
enum ChallengeTier {
  bronze,   // Easy - smaller targets, basic rewards
  silver,   // Medium - moderate targets, better rewards
  gold,     // Hard - high targets, great rewards
  platinum, // Expert - very high targets, premium rewards
}

extension ChallengeTierExtension on ChallengeTier {
  String get displayName {
    switch (this) {
      case ChallengeTier.bronze:
        return 'Bronze';
      case ChallengeTier.silver:
        return 'Silver';
      case ChallengeTier.gold:
        return 'Gold';
      case ChallengeTier.platinum:
        return 'Platinum';
    }
  }

  double get rewardMultiplier {
    switch (this) {
      case ChallengeTier.bronze:
        return 1.0;
      case ChallengeTier.silver:
        return 1.5;
      case ChallengeTier.gold:
        return 2.0;
      case ChallengeTier.platinum:
        return 3.0;
    }
  }
}

/// Represents a single weekly challenge
class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int goldReward;
  final int xpReward;
  final int prestigePointReward; // Bonus prestige points
  final ChallengeTier tier;

  int _currentProgress = 0;
  bool _isCompleted = false;
  bool _isClaimedReward = false;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.goldReward,
    required this.xpReward,
    this.prestigePointReward = 0,
    this.tier = ChallengeTier.bronze,
  });

  int get currentProgress => _currentProgress;
  bool get isCompleted => _isCompleted;
  bool get isClaimedReward => _isClaimedReward;

  double get progressPercentage => (_currentProgress / targetValue).clamp(0.0, 1.0);

  /// Effective rewards with tier multiplier
  int get effectiveGoldReward => (goldReward * tier.rewardMultiplier).round();
  int get effectiveXpReward => (xpReward * tier.rewardMultiplier).round();

  /// Add progress to the challenge
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

  /// Claim the challenge reward
  bool claimReward() {
    if (!_isCompleted || _isClaimedReward) return false;
    _isClaimedReward = true;
    return true;
  }

  /// Reset challenge to initial state
  void reset() {
    _currentProgress = 0;
    _isCompleted = false;
    _isClaimedReward = false;
  }
}

/// Manages weekly challenges
class WeeklyChallengeManager extends ChangeNotifier {
  final Map<String, WeeklyChallenge> _challenges = {};
  DateTime? _lastResetDate;
  DateTime? _weekEndDate;

  // Callback for challenge completion (for haptic feedback, etc.)
  void Function(WeeklyChallenge challenge)? onChallengeCompleted;

  List<WeeklyChallenge> get allChallenges => _challenges.values.toList();
  List<WeeklyChallenge> get activeChallenges =>
      _challenges.values.where((c) => !c.isClaimedReward).toList();
  List<WeeklyChallenge> get completedChallenges =>
      _challenges.values.where((c) => c.isCompleted && !c.isClaimedReward).toList();

  int get completedChallengeCount =>
      _challenges.values.where((c) => c.isCompleted).length;
  int get totalChallengeCount => _challenges.length;

  /// Get challenges by tier
  List<WeeklyChallenge> getChallengesByTier(ChallengeTier tier) =>
      _challenges.values.where((c) => c.tier == tier).toList();

  /// Calculate remaining time until reset
  Duration get timeUntilReset {
    if (_weekEndDate == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(_weekEndDate!)) return Duration.zero;
    return _weekEndDate!.difference(now);
  }

  String get timeUntilResetFormatted {
    final remaining = timeUntilReset;
    if (remaining == Duration.zero) return 'Resetting soon...';

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h remaining';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  /// Register a weekly challenge
  void registerChallenge(WeeklyChallenge challenge) {
    _challenges[challenge.id] = challenge;
    notifyListeners();
  }

  /// Get a specific challenge
  WeeklyChallenge? getChallenge(String id) => _challenges[id];

  /// Add progress to a specific challenge
  void addProgress(String challengeId, int amount) {
    final challenge = _challenges[challengeId];
    if (challenge == null) return;

    final wasCompleted = challenge.isCompleted;
    challenge.addProgress(amount);

    // Trigger callback if just completed
    if (!wasCompleted && challenge.isCompleted) {
      onChallengeCompleted?.call(challenge);
    }

    notifyListeners();
    saveChallengeData();
  }

  /// Add progress to all challenges matching a category pattern
  void addProgressToMatching(String pattern, int amount) {
    for (final challenge in _challenges.values) {
      if (challenge.id.contains(pattern)) {
        addProgress(challenge.id, amount);
      }
    }
  }

  /// Claim reward for a challenge
  /// Returns true if reward was claimed successfully
  bool claimChallengeReward(String challengeId) {
    final challenge = _challenges[challengeId];
    if (challenge == null) return false;

    final claimed = challenge.claimReward();
    if (claimed) {
      notifyListeners();
      saveChallengeData();
    }
    return claimed;
  }

  /// Check if challenges need to be reset (weekly - every Monday)
  Future<void> checkAndResetIfNeeded() async {
    final now = DateTime.now();

    // Load last reset date if not loaded
    if (_lastResetDate == null) {
      await _loadLastResetDate();
    }

    // Calculate the start of current week (Monday 00:00)
    final currentWeekStart = _getWeekStart(now);

    // Check if we need to reset (new week)
    if (_lastResetDate == null || _getWeekStart(_lastResetDate!).isBefore(currentWeekStart)) {
      await resetWeeklyChallenges();
      _lastResetDate = now;
      _weekEndDate = currentWeekStart.add(const Duration(days: 7));
      await _saveLastResetDate();
    } else {
      // Calculate week end if not set
      _weekEndDate ??= _getWeekStart(_lastResetDate!).add(const Duration(days: 7));
    }
  }

  /// Get Monday 00:00 of the week containing the given date
  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1; // Monday = 1
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Reset all challenges (called at start of new week)
  Future<void> resetWeeklyChallenges() async {
    for (final challenge in _challenges.values) {
      challenge.reset();
    }
    notifyListeners();
    await saveChallengeData();
  }

  // ========== SAVE/LOAD SYSTEM ==========

  /// Save challenge progress to SharedPreferences
  Future<void> saveChallengeData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final challenge in _challenges.values) {
      await prefs.setInt('weekly_progress_${challenge.id}', challenge.currentProgress);
      await prefs.setBool('weekly_completed_${challenge.id}', challenge.isCompleted);
      await prefs.setBool('weekly_claimed_${challenge.id}', challenge.isClaimedReward);
    }
  }

  /// Load challenge progress from SharedPreferences
  Future<void> loadChallengeData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final challenge in _challenges.values) {
      final progress = prefs.getInt('weekly_progress_${challenge.id}') ?? 0;
      final claimed = prefs.getBool('weekly_claimed_${challenge.id}') ?? false;

      challenge.setProgress(progress);
      if (claimed && challenge.isCompleted) {
        challenge.claimReward();
      }
    }

    notifyListeners();
  }

  Future<void> _saveLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastResetDate != null) {
      await prefs.setString('weekly_challenge_last_reset', _lastResetDate!.toIso8601String());
    }
    if (_weekEndDate != null) {
      await prefs.setString('weekly_challenge_end_date', _weekEndDate!.toIso8601String());
    }
  }

  Future<void> _loadLastResetDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('weekly_challenge_last_reset');
    if (dateStr != null) {
      _lastResetDate = DateTime.parse(dateStr);
    }
    final endStr = prefs.getString('weekly_challenge_end_date');
    if (endStr != null) {
      _weekEndDate = DateTime.parse(endStr);
    }
  }

  /// Clear all challenge data
  Future<void> clearChallengeData() async {
    final prefs = await SharedPreferences.getInstance();

    for (final challenge in _challenges.values) {
      await prefs.remove('weekly_progress_${challenge.id}');
      await prefs.remove('weekly_completed_${challenge.id}');
      await prefs.remove('weekly_claimed_${challenge.id}');
    }

    await prefs.remove('weekly_challenge_last_reset');
    await prefs.remove('weekly_challenge_end_date');
  }

  /// Get total rewards summary
  Map<String, int> getTotalRewardsSummary() {
    int totalGold = 0;
    int totalXp = 0;
    int totalPrestige = 0;

    for (final challenge in _challenges.values) {
      totalGold += challenge.effectiveGoldReward;
      totalXp += challenge.effectiveXpReward;
      totalPrestige += challenge.prestigePointReward;
    }

    return {
      'gold': totalGold,
      'xp': totalXp,
      'prestige': totalPrestige,
    };
  }
}

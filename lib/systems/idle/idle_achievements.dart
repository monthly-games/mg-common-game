import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Achievement category for idle games
enum IdleAchievementCategory {
  /// Resource collection achievements
  collection,

  /// Time played achievements
  playtime,

  /// Prestige/rebirth achievements
  prestige,

  /// Clicking/tapping achievements
  clicking,

  /// Upgrade achievements
  upgrades,

  /// Milestone achievements
  milestone,

  /// Secret/hidden achievements
  secret,
}

/// Tier of achievement (affects rewards)
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Configuration for an idle achievement
class IdleAchievementConfig {
  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// Description of how to unlock
  final String description;

  /// Category
  final IdleAchievementCategory category;

  /// Achievement tier
  final AchievementTier tier;

  /// Icon for display
  final IconData icon;

  /// Target value to unlock (e.g., collect 1000000 gold)
  final int targetValue;

  /// Whether this is a hidden achievement
  final bool isHidden;

  /// Reward type and amount
  final AchievementReward? reward;

  /// Prestige points bonus when earned
  final int prestigeBonus;

  /// Prerequisites (other achievement IDs)
  final List<String> prerequisites;

  const IdleAchievementConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.tier = AchievementTier.bronze,
    this.icon = Icons.emoji_events,
    this.targetValue = 1,
    this.isHidden = false,
    this.reward,
    this.prestigeBonus = 0,
    this.prerequisites = const [],
  });

  /// Get tier color
  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }
}

/// Reward for completing an achievement
class AchievementReward {
  final String type;
  final int amount;
  final String? resourceId;

  const AchievementReward({
    required this.type,
    required this.amount,
    this.resourceId,
  });

  /// Predefined reward types
  static const AchievementReward gems10 = AchievementReward(type: 'gems', amount: 10);
  static const AchievementReward gems25 = AchievementReward(type: 'gems', amount: 25);
  static const AchievementReward gems50 = AchievementReward(type: 'gems', amount: 50);
  static const AchievementReward gems100 = AchievementReward(type: 'gems', amount: 100);

  static AchievementReward gold(int amount) =>
      AchievementReward(type: 'gold', amount: amount);

  static AchievementReward multiplier(double value) =>
      AchievementReward(type: 'multiplier', amount: (value * 100).toInt());
}

/// State of an achievement
class IdleAchievementState {
  final String id;
  int currentProgress;
  bool isUnlocked;
  DateTime? unlockedAt;
  bool rewardClaimed;

  IdleAchievementState({
    required this.id,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.rewardClaimed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory IdleAchievementState.fromJson(Map<String, dynamic> json) {
    return IdleAchievementState(
      id: json['id'] as String,
      currentProgress: json['currentProgress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'] as int)
          : null,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }
}

/// Callback for achievement events
typedef AchievementUnlockedCallback = void Function(
  IdleAchievementConfig achievement,
  IdleAchievementState state,
);

/// Manages idle game achievements
class IdleAchievementManager extends ChangeNotifier {
  static const String _stateKey = 'idle_achievements_state';

  SharedPreferences? _prefs;

  final Map<String, IdleAchievementConfig> _configs = {};
  final Map<String, IdleAchievementState> _states = {};

  /// Callback when achievement is unlocked
  AchievementUnlockedCallback? onAchievementUnlocked;

  /// Callback when achievement reward is claimed
  void Function(IdleAchievementConfig achievement, AchievementReward reward)? onRewardClaimed;

  /// Initialize the manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadState();
  }

  Future<void> _loadState() async {
    final stateJson = _prefs?.getString(_stateKey);
    if (stateJson != null) {
      try {
        // Parse state JSON and load into _states
        // Simplified for this implementation
      } catch (e) {
        // Ignore parse errors
      }
    }
  }

  Future<void> _saveState() async {
    final states = _states.values.map((s) => s.toJson()).toList();
    await _prefs?.setString(_stateKey, states.toString());
  }

  // ============================================================
  // Registration
  // ============================================================

  /// Register an achievement
  void registerAchievement(IdleAchievementConfig config) {
    _configs[config.id] = config;
    if (!_states.containsKey(config.id)) {
      _states[config.id] = IdleAchievementState(id: config.id);
    }
  }

  /// Register multiple achievements
  void registerAchievements(List<IdleAchievementConfig> configs) {
    for (final config in configs) {
      registerAchievement(config);
    }
  }

  /// Register common idle achievements
  void registerCommonAchievements() {
    final achievements = [
      // Collection achievements
      const IdleAchievementConfig(
        id: 'collect_1k',
        name: 'First Thousand',
        description: 'Collect 1,000 gold',
        category: IdleAchievementCategory.collection,
        tier: AchievementTier.bronze,
        targetValue: 1000,
        reward: AchievementReward.gems10,
      ),
      const IdleAchievementConfig(
        id: 'collect_100k',
        name: 'Getting Rich',
        description: 'Collect 100,000 gold',
        category: IdleAchievementCategory.collection,
        tier: AchievementTier.silver,
        targetValue: 100000,
        reward: AchievementReward.gems25,
      ),
      const IdleAchievementConfig(
        id: 'collect_1m',
        name: 'Millionaire',
        description: 'Collect 1,000,000 gold',
        category: IdleAchievementCategory.collection,
        tier: AchievementTier.gold,
        targetValue: 1000000,
        reward: AchievementReward.gems50,
        prestigeBonus: 1,
      ),
      const IdleAchievementConfig(
        id: 'collect_1b',
        name: 'Billionaire',
        description: 'Collect 1,000,000,000 gold',
        category: IdleAchievementCategory.collection,
        tier: AchievementTier.platinum,
        targetValue: 1000000000,
        reward: AchievementReward.gems100,
        prestigeBonus: 5,
      ),

      // Clicking achievements
      const IdleAchievementConfig(
        id: 'click_100',
        name: 'Tapper',
        description: 'Tap 100 times',
        category: IdleAchievementCategory.clicking,
        tier: AchievementTier.bronze,
        icon: Icons.touch_app,
        targetValue: 100,
      ),
      const IdleAchievementConfig(
        id: 'click_10k',
        name: 'Dedicated Tapper',
        description: 'Tap 10,000 times',
        category: IdleAchievementCategory.clicking,
        tier: AchievementTier.silver,
        icon: Icons.touch_app,
        targetValue: 10000,
        reward: AchievementReward.gems25,
      ),
      const IdleAchievementConfig(
        id: 'click_100k',
        name: 'Tap Master',
        description: 'Tap 100,000 times',
        category: IdleAchievementCategory.clicking,
        tier: AchievementTier.gold,
        icon: Icons.touch_app,
        targetValue: 100000,
        reward: AchievementReward.gems50,
      ),

      // Prestige achievements
      const IdleAchievementConfig(
        id: 'prestige_1',
        name: 'Born Again',
        description: 'Prestige for the first time',
        category: IdleAchievementCategory.prestige,
        tier: AchievementTier.silver,
        icon: Icons.autorenew,
        targetValue: 1,
        reward: AchievementReward.gems25,
      ),
      const IdleAchievementConfig(
        id: 'prestige_10',
        name: 'Seasoned Veteran',
        description: 'Prestige 10 times',
        category: IdleAchievementCategory.prestige,
        tier: AchievementTier.gold,
        icon: Icons.autorenew,
        targetValue: 10,
        reward: AchievementReward.gems50,
        prestigeBonus: 2,
      ),
      const IdleAchievementConfig(
        id: 'prestige_50',
        name: 'Eternal Champion',
        description: 'Prestige 50 times',
        category: IdleAchievementCategory.prestige,
        tier: AchievementTier.platinum,
        icon: Icons.autorenew,
        targetValue: 50,
        reward: AchievementReward.gems100,
        prestigeBonus: 5,
      ),

      // Playtime achievements
      const IdleAchievementConfig(
        id: 'play_1h',
        name: 'Getting Started',
        description: 'Play for 1 hour',
        category: IdleAchievementCategory.playtime,
        tier: AchievementTier.bronze,
        icon: Icons.timer,
        targetValue: 3600,
      ),
      const IdleAchievementConfig(
        id: 'play_10h',
        name: 'Dedicated Player',
        description: 'Play for 10 hours',
        category: IdleAchievementCategory.playtime,
        tier: AchievementTier.silver,
        icon: Icons.timer,
        targetValue: 36000,
        reward: AchievementReward.gems25,
      ),
      const IdleAchievementConfig(
        id: 'play_100h',
        name: 'True Fan',
        description: 'Play for 100 hours',
        category: IdleAchievementCategory.playtime,
        tier: AchievementTier.gold,
        icon: Icons.timer,
        targetValue: 360000,
        reward: AchievementReward.gems50,
      ),

      // Secret achievements
      const IdleAchievementConfig(
        id: 'secret_speed',
        name: '???',
        description: 'Tap 10 times in 1 second',
        category: IdleAchievementCategory.secret,
        tier: AchievementTier.gold,
        icon: Icons.bolt,
        targetValue: 10,
        isHidden: true,
        reward: AchievementReward.gems50,
      ),
    ];

    registerAchievements(achievements);
  }

  // ============================================================
  // Getters
  // ============================================================

  /// Get all achievements
  List<IdleAchievementConfig> get allAchievements => _configs.values.toList();

  /// Get achievements by category
  List<IdleAchievementConfig> getByCategory(IdleAchievementCategory category) {
    return _configs.values.where((c) => c.category == category).toList();
  }

  /// Get unlocked achievements
  List<IdleAchievementConfig> get unlockedAchievements {
    return _configs.values.where((c) => isUnlocked(c.id)).toList();
  }

  /// Get locked achievements (non-hidden)
  List<IdleAchievementConfig> get lockedAchievements {
    return _configs.values
        .where((c) => !isUnlocked(c.id) && !c.isHidden)
        .toList();
  }

  /// Get achievements with unclaimed rewards
  List<IdleAchievementConfig> get achievementsWithUnclaimedRewards {
    return _configs.values.where((c) {
      final state = _states[c.id];
      return state != null &&
          state.isUnlocked &&
          !state.rewardClaimed &&
          c.reward != null;
    }).toList();
  }

  /// Check if achievement is unlocked
  bool isUnlocked(String id) {
    return _states[id]?.isUnlocked ?? false;
  }

  /// Get progress for an achievement
  int getProgress(String id) {
    return _states[id]?.currentProgress ?? 0;
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgressPercentage(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null) return 0;
    if (state.isUnlocked) return 1.0;
    return state.currentProgress / config.targetValue;
  }

  /// Get total achievement points
  int get totalAchievementPoints {
    int total = 0;
    for (final config in unlockedAchievements) {
      total += _getTierPoints(config.tier);
    }
    return total;
  }

  int _getTierPoints(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 10;
      case AchievementTier.silver:
        return 25;
      case AchievementTier.gold:
        return 50;
      case AchievementTier.platinum:
        return 100;
      case AchievementTier.diamond:
        return 200;
    }
  }

  /// Get completion percentage
  double get completionPercentage {
    if (_configs.isEmpty) return 0;
    return unlockedAchievements.length / _configs.length;
  }

  // ============================================================
  // Progress Tracking
  // ============================================================

  /// Update progress for an achievement
  void updateProgress(String id, int progress) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null || state.isUnlocked) return;

    // Check prerequisites
    for (final prereqId in config.prerequisites) {
      if (!isUnlocked(prereqId)) return;
    }

    state.currentProgress = progress;

    if (progress >= config.targetValue) {
      _unlock(config, state);
    }

    notifyListeners();
  }

  /// Increment progress for an achievement
  void incrementProgress(String id, [int amount = 1]) {
    final state = _states[id];
    if (state == null) return;

    updateProgress(id, state.currentProgress + amount);
  }

  /// Set progress to max (force unlock)
  void forceUnlock(String id) {
    final config = _configs[id];
    if (config == null) return;

    updateProgress(id, config.targetValue);
  }

  void _unlock(IdleAchievementConfig config, IdleAchievementState state) {
    state.isUnlocked = true;
    state.unlockedAt = DateTime.now();
    _saveState();

    onAchievementUnlocked?.call(config, state);
  }

  // ============================================================
  // Rewards
  // ============================================================

  /// Claim reward for an achievement
  AchievementReward? claimReward(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null) return null;
    if (!state.isUnlocked || state.rewardClaimed) return null;
    if (config.reward == null) return null;

    state.rewardClaimed = true;
    _saveState();

    onRewardClaimed?.call(config, config.reward!);
    notifyListeners();

    return config.reward;
  }

  /// Claim all unclaimed rewards
  List<AchievementReward> claimAllRewards() {
    final rewards = <AchievementReward>[];

    for (final config in achievementsWithUnclaimedRewards) {
      final reward = claimReward(config.id);
      if (reward != null) {
        rewards.add(reward);
      }
    }

    return rewards;
  }

  // ============================================================
  // Persistence
  // ============================================================

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'states': _states.values.map((s) => s.toJson()).toList(),
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    if (json['states'] != null) {
      final statesList = json['states'] as List;
      for (final stateData in statesList) {
        final state = IdleAchievementState.fromJson(stateData as Map<String, dynamic>);
        _states[state.id] = state;
      }
    }
    notifyListeners();
  }

  /// Reset all achievements
  Future<void> reset() async {
    for (final state in _states.values) {
      state.currentProgress = 0;
      state.isUnlocked = false;
      state.unlockedAt = null;
      state.rewardClaimed = false;
    }

    await _prefs?.remove(_stateKey);
    notifyListeners();
  }

  @override
  String toString() {
    return 'IdleAchievementManager(total: ${_configs.length}, unlocked: ${unlockedAchievements.length})';
  }
}

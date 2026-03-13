import 'dart:async';
import 'package:flutter/material.dart';

enum XPSourceType {
  quest,
  achievement,
  battle,
  exploration,
  crafting,
  social,
  dailyBonus,
  event,
  tutorial,
  purchase,
}

enum StageType {
  normal,
  elite,
  boss,
  special,
  event,
  tutorial,
  pvp,
  guild,
}

enum StageStatus {
  locked,
  unlocked,
  inProgress,
  completed,
  failed,
}

enum Rank {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
  challenger,
}

class XPRequirement {
  final int level;
  final int requiredXP;
  final int rewardCount;

  const XPRequirement({
    required this.level,
    required this.requiredXP,
    required this.rewardCount,
  });
}

class LevelReward {
  final String rewardId;
  final int level;
  final String type;
  final int amount;
  final String itemId;
  final String itemName;
  final bool isClaimed;

  const LevelReward({
    required this.rewardId,
    required this.level,
    required this.type,
    required this.amount,
    required this.itemId,
    required this.itemName,
    required this.isClaimed,
  });
}

class StageProgress {
  final String stageId;
  final StageType type;
  final StageStatus status;
  final int stars;
  final int maxStars;
  final DateTime? firstCompletedAt;
  final DateTime? lastCompletedAt;
  final int completionCount;
  final int bestScore;
  final int fastestTime;
  final Map<String, dynamic> metadata;

  const StageProgress({
    required this.stageId,
    required this.type,
    required this.status,
    required this.stars,
    required this.maxStars,
    this.firstCompletedAt,
    this.lastCompletedAt,
    required this.completionCount,
    required this.bestScore,
    required this.fastestTime,
    required this.metadata,
  });

  double get starProgress => maxStars > 0 ? stars / maxStars : 0.0;
}

class PlayerProgress {
  final String userId;
  final int level;
  final int currentXP;
  final int totalXP;
  final Rank rank;
  final String stageId;
  final int stageIndex;
  final List<LevelReward> claimedRewards;
  final Map<String, StageProgress> stageProgress;
  final DateTime? lastLevelUpAt;
  final DateTime createdAt;

  const PlayerProgress({
    required this.userId,
    required this.level,
    required this.currentXP,
    required this.totalXP,
    required this.rank,
    required this.stageId,
    required this.stageIndex,
    required this.claimedRewards,
    required this.stageProgress,
    this.lastLevelUpAt,
    required this.createdAt,
  });

  int get xpToNextLevel => _getXPForLevel(level + 1) - currentXP;
  double get levelProgress {
    final currentLevelXP = _getXPForLevel(level);
    final nextLevelXP = _getXPForLevel(level + 1);
    return nextLevelXP > currentLevelXP
        ? (totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP)
        : 1.0;
  }

  int _getXPForLevel(int level) {
    return level * 100 + (level * level * 10);
  }
}

class DailyProgress {
  final String userId;
  final DateTime date;
  final int dailyXP;
  final int questsCompleted;
  final int battlesWon;
  final int achievementsUnlocked;
  final int loginStreak;
  final bool claimedDailyReward;

  const DailyProgress({
    required this.userId,
    required this.date,
    required this.dailyXP,
    required this.questsCompleted,
    required this.battlesWon,
    required this.achievementsUnlocked,
    required this.loginStreak,
    required this.claimedDailyReward,
  });
}

class ProgressionManager {
  static final ProgressionManager _instance = ProgressionManager._();
  static ProgressionManager get instance => _instance;

  ProgressionManager._();

  final Map<String, PlayerProgress> _playerProgress = {};
  final Map<String, DailyProgress> _dailyProgress = {};
  final Map<String, List<LevelReward>> _levelRewards = {};
  final StreamController<ProgressionEvent> _eventController = StreamController.broadcast();
  Timer? _dailyResetTimer;

  Stream<ProgressionEvent> get onProgressionEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultLevelRewards();
    await _loadDefaultStages();
    _startDailyResetTimer();
  }

  Future<void> _loadDefaultLevelRewards() async {
    final rewards = [
      LevelReward(
        rewardId: 'level_5',
        level: 5,
        type: 'currency',
        amount: 1000,
        itemId: 'gold',
        itemName: 'Gold',
        isClaimed: false,
      ),
      LevelReward(
        rewardId: 'level_10',
        level: 10,
        type: 'premium_currency',
        amount: 50,
        itemId: 'gems',
        itemName: 'Gems',
        isClaimed: false,
      ),
      LevelReward(
        rewardId: 'level_20',
        level: 20,
        type: 'bundle',
        amount: 1,
        itemId: 'equipment_bundle',
        itemName: 'Equipment Bundle',
        isClaimed: false,
      ),
    ];

    _levelRewards['default'] = rewards;
  }

  Future<void> _loadDefaultStages() async {
  }

  void _startDailyResetTimer() {
    _dailyResetTimer?.cancel();
    _dailyResetTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkDailyReset(),
    );
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final entry in _dailyProgress.entries) {
      if (entry.value.date.isBefore(today)) {
        _resetDailyProgress(entry.key);
      }
    }
  }

  void _resetDailyProgress(String userId) {
    final yesterday = _dailyProgress[userId];
    final streak = yesterday?.loginStreak ?? 0;

    _dailyProgress[userId] = DailyProgress(
      userId: userId,
      date: DateTime.now(),
      dailyXP: 0,
      questsCompleted: 0,
      battlesWon: 0,
      achievementsUnlocked: 0,
      loginStreak: streak + 1,
      claimedDailyReward: false,
    );

    _eventController.add(ProgressionEvent(
      type: ProgressionEventType.dailyReset,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  PlayerProgress? getPlayerProgress(String userId) {
    return _playerProgress[userId];
  }

  Future<void> createPlayerProgress(String userId) async {
    if (_playerProgress.containsKey(userId)) return;

    _playerProgress[userId] = PlayerProgress(
      userId: userId,
      level: 1,
      currentXP: 0,
      totalXP: 0,
      rank: Rank.bronze,
      stageId: 'stage_1_1',
      stageIndex: 0,
      claimedRewards: [],
      stageProgress: {},
      createdAt: DateTime.now(),
    );

    _dailyProgress[userId] = DailyProgress(
      userId: userId,
      date: DateTime.now(),
      dailyXP: 0,
      questsCompleted: 0,
      battlesWon: 0,
      achievementsUnlocked: 0,
      loginStreak: 1,
      claimedDailyReward: false,
    );
  }

  Future<bool> addXP({
    required String userId,
    required int amount,
    required XPSourceType source,
    String? sourceId,
  }) async {
    final progress = _playerProgress[userId];
    if (progress == null) return false;

    final newTotalXP = progress.totalXP + amount;
    int newLevel = progress.level;
    int newCurrentXP = progress.currentXP + amount;

    while (newCurrentXP >= _getXPForLevel(newLevel + 1)) {
      final requiredXP = _getXPForLevel(newLevel + 1);
      newCurrentXP -= requiredXP;
      newLevel++;
    }

    final updated = PlayerProgress(
      userId: progress.userId,
      level: newLevel,
      currentXP: newCurrentXP,
      totalXP: newTotalXP,
      rank: _calculateRank(newLevel),
      stageId: progress.stageId,
      stageIndex: progress.stageIndex,
      claimedRewards: progress.claimedRewards,
      stageProgress: progress.stageProgress,
      lastLevelUpAt: newLevel > progress.level ? DateTime.now() : progress.lastLevelUpAt,
      createdAt: progress.createdAt,
    );

    _playerProgress[userId] = updated;

    final daily = _dailyProgress[userId];
    if (daily != null) {
      _dailyProgress[userId] = DailyProgress(
        userId: daily.userId,
        date: daily.date,
        dailyXP: daily.dailyXP + amount,
        questsCompleted: daily.questsCompleted,
        battlesWon: daily.battlesWon,
        achievementsUnlocked: daily.achievementsUnlocked,
        loginStreak: daily.loginStreak,
        claimedDailyReward: daily.claimedDailyReward,
      );
    }

    _eventController.add(ProgressionEvent(
      type: ProgressionEventType.xpGained,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'amount': amount, 'source': source.name, 'sourceId': sourceId},
    ));

    if (newLevel > progress.level) {
      _eventController.add(ProgressionEvent(
        type: ProgressionEventType.levelUp,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'oldLevel': progress.level, 'newLevel': newLevel},
      ));
    }

    return true;
  }

  int _getXPForLevel(int level) {
    return level * 100 + (level * level * 10);
  }

  Rank _calculateRank(int level) {
    if (level >= 50) return Rank.challenger;
    if (level >= 40) return Rank.grandmaster;
    if (level >= 30) return Rank.master;
    if (level >= 25) return Rank.diamond;
    if (level >= 20) return Rank.platinum;
    if (level >= 15) return Rank.gold;
    if (level >= 10) return Rank.silver;
    return Rank.bronze;
  }

  Future<bool> completeStage({
    required String userId,
    required String stageId,
    required int stars,
    int? score,
    int? time,
  }) async {
    final progress = _playerProgress[userId];
    if (progress == null) return false;

    final existing = progress.stageProgress[stageId];
    final newStars = existing != null ? (existing.stars).clamp(0, stars) : stars;

    final stageProgress = StageProgress(
      stageId: stageId,
      type: StageType.normal,
      status: StageStatus.completed,
      stars: newStars,
      maxStars: 3,
      firstCompletedAt: existing?.firstCompletedAt ?? DateTime.now(),
      lastCompletedAt: DateTime.now(),
      completionCount: (existing?.completionCount ?? 0) + 1,
      bestScore: score != null ? (existing?.bestScore ?? 0).clamp(0, score) : (existing?.bestScore ?? 0),
      fastestTime: time != null ? (existing?.fastestTime ?? 999999).clamp(0, time) : (existing?.fastestTime ?? 999999),
      metadata: {},
    );

    final updatedStageProgress = Map<String, StageProgress>.from(progress.stageProgress);
    updatedStageProgress[stageId] = stageProgress;

    final updated = PlayerProgress(
      userId: progress.userId,
      level: progress.level,
      currentXP: progress.currentXP,
      totalXP: progress.totalXP,
      rank: progress.rank,
      stageId: progress.stageId,
      stageIndex: progress.stageIndex,
      claimedRewards: progress.claimedRewards,
      stageProgress: updatedStageProgress,
      lastLevelUpAt: progress.lastLevelUpAt,
      createdAt: progress.createdAt,
    );

    _playerProgress[userId] = updated;

    _eventController.add(ProgressionEvent(
      type: ProgressionEventType.stageCompleted,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'stageId': stageId, 'stars': stars},
    ));

    return true;
  }

  Future<bool> claimLevelReward({
    required String userId,
    required int level,
  }) async {
    final progress = _playerProgress[userId];
    if (progress == null) return false;
    if (progress.level < level) return false;

    final rewards = _levelRewards['default'];
    if (rewards == null) return false;

    final rewardIndex = rewards.indexWhere((r) => r.level == level && !r.isClaimed);
    if (rewardIndex < 0) return false;

    final reward = rewards[rewardIndex];
    final claimed = LevelReward(
      rewardId: reward.rewardId,
      level: reward.level,
      type: reward.type,
      amount: reward.amount,
      itemId: reward.itemId,
      itemName: reward.itemName,
      isClaimed: true,
    );

    final updatedRewards = List<LevelReward>.from(progress.claimedRewards);
    updatedRewards.add(claimed);

    final updated = PlayerProgress(
      userId: progress.userId,
      level: progress.level,
      currentXP: progress.currentXP,
      totalXP: progress.totalXP,
      rank: progress.rank,
      stageId: progress.stageId,
      stageIndex: progress.stageIndex,
      claimedRewards: updatedRewards,
      stageProgress: progress.stageProgress,
      lastLevelUpAt: progress.lastLevelUpAt,
      createdAt: progress.createdAt,
    );

    _playerProgress[userId] = updated;

    _eventController.add(ProgressionEvent(
      type: ProgressionEventType.rewardClaimed,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'level': level, 'reward': reward},
    ));

    return true;
  }

  List<LevelReward> getAvailableRewards(String userId) {
    final progress = _playerProgress[userId];
    if (progress == null) return [];

    final rewards = _levelRewards['default'] ?? [];
    return rewards.where((r) =>
        r.level <= progress.level &&
        !progress.claimedRewards.any((cr) => cr.rewardId == r.rewardId)
    ).toList();
  }

  DailyProgress? getDailyProgress(String userId) {
    return _dailyProgress[userId];
  }

  Map<String, dynamic> getProgressionStats(String userId) {
    final progress = _playerProgress[userId];
    final daily = _dailyProgress[userId];

    if (progress == null) return {};

    return {
      'level': progress.level,
      'currentXP': progress.currentXP,
      'totalXP': progress.totalXP,
      'rank': progress.rank.name,
      'stageId': progress.stageId,
      'stagesCompleted': progress.stageProgress.length,
      'dailyXP': daily?.dailyXP ?? 0,
      'loginStreak': daily?.loginStreak ?? 0,
    };
  }

  void dispose() {
    _dailyResetTimer?.cancel();
    _eventController.close();
  }
}

class ProgressionEvent {
  final ProgressionEventType type;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const ProgressionEvent({
    required this.type,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum ProgressionEventType {
  xpGained,
  levelUp,
  stageCompleted,
  stageUnlocked,
  rewardClaimed,
  rankChanged,
  dailyReset,
  dailyRewardClaimed,
  loginStreakUpdated,
}

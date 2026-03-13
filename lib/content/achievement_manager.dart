import 'dart:async';
import 'package:flutter/material.dart';

enum AchievementType {
  progression,
  collection,
  combat,
  social,
  exploration,
  crafting,
  trading,
  milestone,
}

enum AchievementStatus {
  hidden,
  revealed,
  inProgress,
  completed,
  claimed,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class AchievementObjective {
  final String objectiveId;
  final String description;
  final int targetValue;
  int currentValue;
  final String objectiveType;

  AchievementObjective({
    required this.objectiveId,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.objectiveType,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0.0;
  bool get isCompleted => currentValue >= targetValue;
}

class AchievementReward {
  final String rewardId;
  final String type;
  final int amount;
  final String itemId;

  const AchievementReward({
    required this.rewardId,
    required this.type,
    required this.amount,
    required this.itemId,
  });
}

class Achievement {
  final String achievementId;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementStatus status;
  final AchievementTier tier;
  final List<AchievementObjective> objectives;
  final List<AchievementReward> rewards;
  final int points;
  final bool isHidden;
  final List<String> prerequisiteIds;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;
  final int sortOrder;
  final String? category;
  final double globalCompletionRate;

  const Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.status,
    required this.tier,
    required this.objectives,
    required this.rewards,
    required this.points,
    required this.isHidden,
    required this.prerequisiteIds,
    this.unlockedAt,
    this.claimedAt,
    required this.sortOrder,
    this.category,
    required this.globalCompletionRate,
  });

  double get progress {
    if (objectives.isEmpty) return status == AchievementStatus.completed ? 1.0 : 0.0;
    final totalProgress = objectives.fold<double>(0, (sum, obj) => sum + obj.progress);
    return totalProgress / objectives.length;
  }

  bool get isCompleted => status == AchievementStatus.completed;
  bool get isClaimable => isCompleted && claimedAt == null;
  bool get canShow => !isHidden || status != AchievementStatus.hidden;
}

class AchievementCategory {
  final String categoryId;
  final String name;
  final String description;
  final String icon;
  final List<String> achievementIds;

  const AchievementCategory({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.achievementIds,
  });

  int get totalAchievements => achievementIds.length;
}

class AchievementManager {
  static final AchievementManager _instance = AchievementManager._();
  static AchievementManager get instance => _instance;

  AchievementManager._();

  final Map<String, Achievement> _achievements = {};
  final Map<String, AchievementCategory> _categories = {};
  final Map<String, List<String>> _userAchievements = {};
  final StreamController<AchievementEvent> _eventController = StreamController.broadcast();

  Stream<AchievementEvent> get onAchievementEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultAchievements();
    await _loadDefaultCategories();
  }

  Future<void> _loadDefaultAchievements() async {
    final achievements = [
      Achievement(
        achievementId: 'first_win',
        name: 'First Victory',
        description: 'Win your first battle',
        icon: 'first_win_icon',
        type: AchievementType.combat,
        status: AchievementStatus.hidden,
        tier: AchievementTier.bronze,
        objectives: [
          AchievementObjective(
            objectiveId: 'win_battle',
            description: 'Win a battle',
            targetValue: 1,
            currentValue: 0,
            objectiveType: 'win',
          ),
        ],
        rewards: const [
          AchievementReward(
            rewardId: 'coins',
            type: 'currency',
            amount: 100,
            itemId: 'coins',
          ),
        ],
        points: 10,
        isHidden: true,
        prerequisiteIds: [],
        sortOrder: 1,
        globalCompletionRate: 0.0,
      ),
      Achievement(
        achievementId: 'level_10',
        name: 'Rising Star',
        description: 'Reach level 10',
        icon: 'level_10_icon',
        type: AchievementType.progression,
        status: AchievementStatus.revealed,
        tier: AchievementTier.bronze,
        objectives: [
          AchievementObjective(
            objectiveId: 'reach_level',
            description: 'Reach level 10',
            targetValue: 10,
            currentValue: 0,
            objectiveType: 'level',
          ),
        ],
        rewards: const [
          AchievementReward(
            rewardId: 'exp',
            type: 'experience',
            amount: 500,
            itemId: 'exp',
          ),
        ],
        points: 25,
        isHidden: false,
        prerequisiteIds: [],
        sortOrder: 2,
        category: 'progression',
        globalCompletionRate: 0.15,
      ),
      Achievement(
        achievementId: 'collect_100',
        name: 'Collector',
        description: 'Collect 100 items',
        icon: 'collector_icon',
        type: AchievementType.collection,
        status: AchievementStatus.revealed,
        tier: AchievementTier.silver,
        objectives: [
          AchievementObjective(
            objectiveId: 'collect_items',
            description: 'Collect items',
            targetValue: 100,
            currentValue: 0,
            objectiveType: 'collect',
          ),
        ],
        rewards: const [
          AchievementReward(
            rewardId: 'storage',
            type: 'storage_space',
            amount: 10,
            itemId: 'storage',
          ),
        ],
        points: 50,
        isHidden: false,
        prerequisiteIds: [],
        sortOrder: 3,
        category: 'collection',
        globalCompletionRate: 0.08,
      ),
    ];

    for (final achievement in achievements) {
      _achievements[achievement.achievementId] = achievement;
    }
  }

  Future<void> _loadDefaultCategories() async {
    final categories = [
      AchievementCategory(
        categoryId: 'progression',
        name: 'Progression',
        description: 'Level and skill achievements',
        icon: 'progression_icon',
        achievementIds: ['level_10'],
      ),
      AchievementCategory(
        categoryId: 'combat',
        name: 'Combat',
        description: 'Battle-related achievements',
        icon: 'combat_icon',
        achievementIds: ['first_win'],
      ),
      AchievementCategory(
        categoryId: 'collection',
        name: 'Collection',
        description: 'Collection achievements',
        icon: 'collection_icon',
        achievementIds: ['collect_100'],
      ),
    ];

    for (final category in categories) {
      _categories[category.categoryId] = category;
    }
  }

  List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  List<Achievement> getVisibleAchievements() {
    return _achievements.values.where((a) => a.canShow).toList();
  }

  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.values
        .where((a) => a.type == type && a.canShow)
        .toList();
  }

  List<Achievement> getAchievementsByTier(AchievementTier tier) {
    return _achievements.values
        .where((a) => a.tier == tier && a.canShow)
        .toList();
  }

  Achievement? getAchievement(String achievementId) {
    return _achievements[achievementId];
  }

  List<Achievement> getCompletedAchievements(String userId) {
    final userAchievementIds = _userAchievements[userId] ?? [];
    return _achievements.values
        .where((a) => userAchievementIds.contains(a.achievementId))
        .toList();
  }

  List<Achievement> getInProgressAchievements(String userId) {
    final userAchievementIds = _userAchievements[userId] ?? [];
    return _achievements.values
        .where((a) =>
            userAchievementIds.contains(a.achievementId) &&
            a.status == AchievementStatus.inProgress)
        .toList();
  }

  List<AchievementCategory> getAllCategories() {
    return _categories.values.toList();
  }

  Future<bool> updateObjective({
    required String userId,
    required String achievementId,
    required String objectiveId,
    required int increment,
  }) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return false;

    final objIndex = achievement.objectives.indexWhere((obj) => obj.objectiveId == objectiveId);
    if (objIndex < 0) return false;

    final objective = achievement.objectives[objIndex];
    final updated = AchievementObjective(
      objectiveId: objective.objectiveId,
      description: objective.description,
      targetValue: objective.targetValue,
      currentValue: (objective.currentValue + increment).clamp(0, objective.targetValue),
      objectiveType: objective.objectiveType,
    );

    final updatedObjectives = [...achievement.objectives];
    updatedObjectives[objIndex] = updated;

    final updatedAchievement = Achievement(
      achievementId: achievement.achievementId,
      name: achievement.name,
      description: achievement.description,
      icon: achievement.icon,
      type: achievement.type,
      status: _isAllCompleted(updatedObjectives) ? AchievementStatus.completed : AchievementStatus.inProgress,
      tier: achievement.tier,
      objectives: updatedObjectives,
      rewards: achievement.rewards,
      points: achievement.points,
      isHidden: achievement.isHidden,
      prerequisiteIds: achievement.prerequisiteIds,
      unlockedAt: achievement.unlockedAt ?? DateTime.now(),
      claimedAt: achievement.claimedAt,
      sortOrder: achievement.sortOrder,
      category: achievement.category,
      globalCompletionRate: achievement.globalCompletionRate,
    );

    _achievements[achievementId] = updatedAchievement;

    _userAchievements.putIfAbsent(userId, () => []);
    if (!_userAchievements[userId]!.contains(achievementId)) {
      _userAchievements[userId]!.add(achievementId);
    }

    _eventController.add(AchievementEvent(
      type: AchievementEventType.objectiveUpdated,
      achievementId: achievementId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    if (updatedAchievement.isCompleted) {
      _eventController.add(AchievementEvent(
        type: AchievementEventType.achievementUnlocked,
        achievementId: achievementId,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'points': updatedAchievement.points},
      ));
    }

    return true;
  }

  bool _isAllCompleted(List<AchievementObjective> objectives) {
    return objectives.every((obj) => obj.isCompleted);
  }

  Future<bool> claimReward({
    required String userId,
    required String achievementId,
  }) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return false;
    if (!achievement.isCompleted) return false;
    if (achievement.claimedAt != null) return false;

    final updated = Achievement(
      achievementId: achievement.achievementId,
      name: achievement.name,
      description: achievement.description,
      icon: achievement.icon,
      type: achievement.type,
      status: AchievementStatus.claimed,
      tier: achievement.tier,
      objectives: achievement.objectives,
      rewards: achievement.rewards,
      points: achievement.points,
      isHidden: achievement.isHidden,
      prerequisiteIds: achievement.prerequisiteIds,
      unlockedAt: achievement.unlockedAt,
      claimedAt: DateTime.now(),
      sortOrder: achievement.sortOrder,
      category: achievement.category,
      globalCompletionRate: achievement.globalCompletionRate,
    );

    _achievements[achievementId] = updated;

    _eventController.add(AchievementEvent(
      type: AchievementEventType.rewardClaimed,
      achievementId: achievementId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'rewards': achievement.rewards},
    ));

    return true;
  }

  int getTotalPoints(String userId) {
    final completed = getCompletedAchievements(userId);
    return completed.fold<int>(0, (sum, a) => sum + a.points);
  }

  Map<AchievementTier, int> getAchievementsByTier(String userId) {
    final completed = getCompletedAchievements(userId);
    final result = <AchievementTier, int>{};

    for (final tier in AchievementTier.values) {
      result[tier] = completed.where((a) => a.tier == tier).length;
    }

    return result;
  }

  Map<String, dynamic> getAchievementStats(String userId) {
    final total = _achievements.length;
    final completed = getCompletedAchievements(userId).length;
    final inProgress = getInProgressAchievements(userId).length;
    final totalPoints = getTotalPoints(userId);

    return {
      'totalAchievements': total,
      'completedAchievements': completed,
      'inProgressAchievements': inProgress,
      'totalPoints': totalPoints,
      'completionRate': total > 0 ? completed / total : 0.0,
    };
  }

  void dispose() {
    _eventController.close();
  }
}

class AchievementEvent {
  final AchievementEventType type;
  final String? achievementId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const AchievementEvent({
    required this.type,
    this.achievementId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum AchievementEventType {
  achievementUnlocked,
  objectiveUpdated,
  rewardClaimed,
  tierReached,
  categoryCompleted,
}

import 'dart:async';
import 'package:flutter/material.dart';

enum QuestType {
  main,
  side,
  daily,
  weekly,
  monthly,
  event,
  tutorial,
  achievement,
}

enum QuestStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  abandoned,
  claimed,
}

enum QuestRepeatType {
  none,
  daily,
  weekly,
  monthly,
}

class QuestObjective {
  final String objectiveId;
  final String description;
  final int targetValue;
  int currentValue;
  final String objectiveType;
  final Map<String, dynamic> metadata;

  QuestObjective({
    required this.objectiveId,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.objectiveType,
    required this.metadata,
  });

  double get progress => targetValue > 0 ? currentValue / targetValue : 0.0;
  bool get isCompleted => currentValue >= targetValue;
}

class QuestReward {
  final String rewardId;
  final String type;
  final int amount;
  final String itemId;
  final String itemName;
  final Map<String, dynamic> metadata;

  const QuestReward({
    required this.rewardId,
    required this.type,
    required this.amount,
    required this.itemId,
    required this.itemName,
    required this.metadata,
  });
}

class Quest {
  final String questId;
  final String name;
  final String description;
  final QuestType type;
  final QuestStatus status;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
  final int levelRequirement;
  final List<String> prerequisiteQuestIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final int sortOrder;
  final bool isAutoStart;
  final QuestRepeatType repeatType;
  final DateTime? lastCompletedAt;
  final int completionCount;
  final String? category;
  final int estimatedDuration;
  final Map<String, dynamic> metadata;

  const Quest({
    required this.questId,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.objectives,
    required this.rewards,
    required this.levelRequirement,
    required this.prerequisiteQuestIds,
    this.startDate,
    this.endDate,
    required this.sortOrder,
    required this.isAutoStart,
    required this.repeatType,
    this.lastCompletedAt,
    required this.completionCount,
    this.category,
    required this.estimatedDuration,
    required this.metadata,
  });

  double get progress {
    if (objectives.isEmpty) return 0.0;
    final totalProgress = objectives.fold<double>(0, (sum, obj) => sum + obj.progress);
    return totalProgress / objectives.length;
  }

  bool get isCompletable => objectives.every((obj) => obj.isCompleted);
  bool get canStart => status == QuestStatus.notStarted;
  bool get isActive => status == QuestStatus.inProgress;
  bool get isCompleted => status == QuestStatus.completed;
  bool get isClaimable => status == QuestStatus.completed;
  bool get hasExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isRepeatable => repeatType != QuestRepeatType.none;
  bool get canClaim => isCompleted && !hasExpired;
}

class QuestProgress {
  final String questId;
  final String userId;
  final QuestStatus status;
  final List<QuestObjective> objectives;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;
  final int attempts;
  final Map<String, dynamic> userProgress;

  const QuestProgress({
    required this.questId,
    required this.userId,
    required this.status,
    required this.objectives,
    this.startedAt,
    this.completedAt,
    this.claimedAt,
    required this.attempts,
    required this.userProgress,
  });

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}

class QuestCategory {
  final String categoryId;
  final String name;
  final String description;
  final String icon;
  final int sortOrder;
  final List<String> questIds;

  const QuestCategory({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.sortOrder,
    required this.questIds,
  });
}

class QuestManager {
  static final QuestManager _instance = QuestManager._();
  static QuestManager get instance => _instance;

  QuestManager._();

  final Map<String, Quest> _quests = {};
  final Map<String, QuestProgress> _userProgress = {};
  final Map<String, QuestCategory> _categories = {};
  final StreamController<QuestEvent> _eventController = StreamController.broadcast();
  Timer? _dailyResetTimer;
  Timer? _weeklyResetTimer;
  DateTime? _lastDailyReset;
  DateTime? _lastWeeklyReset;

  Stream<QuestEvent> get onQuestEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultQuests();
    await _loadDefaultCategories();
    _startResetTimers();
  }

  Future<void> _loadDefaultQuests() async {
    final quests = [
      Quest(
        questId: 'tutorial_1',
        name: 'First Steps',
        description: 'Complete the tutorial',
        type: QuestType.tutorial,
        status: QuestStatus.notStarted,
        objectives: [
          QuestObjective(
            objectiveId: 'obj1',
            description: 'Complete tutorial stage 1',
            targetValue: 1,
            currentValue: 0,
            objectiveType: 'complete_stage',
            metadata: {'stageId': 'tutorial_1'},
          ),
        ],
        rewards: const [
          QuestReward(
            rewardId: 'rew1',
            type: 'experience',
            amount: 100,
            itemId: 'exp',
            itemName: 'Experience',
            metadata: {},
          ),
        ],
        levelRequirement: 1,
        prerequisiteQuestIds: [],
        sortOrder: 1,
        isAutoStart: true,
        repeatType: QuestRepeatType.none,
        completionCount: 0,
        estimatedDuration: 5,
        metadata: {},
      ),
      Quest(
        questId: 'daily_login',
        name: 'Daily Login',
        description: 'Log in once today',
        type: QuestType.daily,
        status: QuestStatus.notStarted,
        objectives: [
          QuestObjective(
            objectiveId: 'login',
            description: 'Log in',
            targetValue: 1,
            currentValue: 0,
            objectiveType: 'login',
            metadata: {},
          ),
        ],
        rewards: const [
          QuestReward(
            rewardId: 'coins',
            type: 'currency',
            amount: 50,
            itemId: 'coins',
            itemName: 'Coins',
            metadata: {},
          ),
        ],
        levelRequirement: 1,
        prerequisiteQuestIds: [],
        startDate: _getTodayStart(),
        endDate: _getTodayEnd(),
        sortOrder: 1,
        isAutoStart: false,
        repeatType: QuestRepeatType.daily,
        completionCount: 0,
        estimatedDuration: 1,
        metadata: {},
      ),
      Quest(
        questId: 'weekly_battles',
        name: 'Weekly Battles',
        description: 'Win 10 battles this week',
        type: QuestType.weekly,
        status: QuestStatus.notStarted,
        objectives: [
          QuestObjective(
            objectiveId: 'wins',
            description: 'Win battles',
            targetValue: 10,
            currentValue: 0,
            objectiveType: 'win_battle',
            metadata: {},
          ),
        ],
        rewards: const [
          QuestReward(
            rewardId: 'gems',
            type: 'premium_currency',
            amount: 50,
            itemId: 'gems',
            itemName: 'Gems',
            metadata: {},
          ),
        ],
        levelRequirement: 5,
        prerequisiteQuestIds: [],
        startDate: _getWeekStart(),
        endDate: _getWeekEnd(),
        sortOrder: 1,
        isAutoStart: false,
        repeatType: QuestRepeatType.weekly,
        completionCount: 0,
        estimatedDuration: 60,
        metadata: {},
      ),
    ];

    for (final quest in quests) {
      _quests[quest.questId] = quest;
    }
  }

  Future<void> _loadDefaultCategories() async {
    final categories = [
      QuestCategory(
        categoryId: 'main',
        name: 'Main Story',
        description: 'Main quest line',
        icon: 'main_quest_icon',
        sortOrder: 1,
        questIds: ['tutorial_1'],
      ),
      QuestCategory(
        categoryId: 'daily',
        name: 'Daily',
        description: 'Daily quests',
        icon: 'daily_quest_icon',
        sortOrder: 2,
        questIds: ['daily_login'],
      ),
      QuestCategory(
        categoryId: 'weekly',
        name: 'Weekly',
        description: 'Weekly challenges',
        icon: 'weekly_quest_icon',
        sortOrder: 3,
        questIds: ['weekly_battles'],
      ),
    ];

    for (final category in categories) {
      _categories[category.categoryId] = category;
    }
  }

  void _startResetTimers() {
    _dailyResetTimer?.cancel();
    _weeklyResetTimer?.cancel();

    _dailyResetTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkDailyReset(),
    );

    _weeklyResetTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkWeeklyReset(),
    );
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_lastDailyReset == null || _lastDailyReset!.isBefore(todayStart)) {
      _resetDailyQuests();
      _lastDailyReset = now;
    }
  }

  void _checkWeeklyReset() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);

    if (_lastWeeklyReset == null || _lastWeeklyReset!.isBefore(weekStartNormalized)) {
      _resetWeeklyQuests();
      _lastWeeklyReset = now;
    }
  }

  void _resetDailyQuests() {
    for (final quest in _quests.values) {
      if (quest.repeatType == QuestRepeatType.daily) {
        final reset = Quest(
          questId: quest.questId,
          name: quest.name,
          description: quest.description,
          type: quest.type,
          status: QuestStatus.notStarted,
          objectives: quest.objectives.map((obj) => QuestObjective(
            objectiveId: obj.objectiveId,
            description: obj.description,
            targetValue: obj.targetValue,
            currentValue: 0,
            objectiveType: obj.objectiveType,
            metadata: obj.metadata,
          )).toList(),
          rewards: quest.rewards,
          levelRequirement: quest.levelRequirement,
          prerequisiteQuestIds: quest.prerequisiteQuestIds,
          startDate: _getTodayStart(),
          endDate: _getTodayEnd(),
          sortOrder: quest.sortOrder,
          isAutoStart: quest.isAutoStart,
          repeatType: quest.repeatType,
          completionCount: 0,
          category: quest.category,
          estimatedDuration: quest.estimatedDuration,
          metadata: quest.metadata,
        );

        _quests[quest.questId] = reset;
      }
    }

    _eventController.add(QuestEvent(
      type: QuestEventType.dailyReset,
      timestamp: DateTime.now(),
    ));
  }

  void _resetWeeklyQuests() {
    for (final quest in _quests.values) {
      if (quest.repeatType == QuestRepeatType.weekly) {
        final reset = Quest(
          questId: quest.questId,
          name: quest.name,
          description: quest.description,
          type: quest.type,
          status: QuestStatus.notStarted,
          objectives: quest.objectives.map((obj) => QuestObjective(
            objectiveId: obj.objectiveId,
            description: obj.description,
            targetValue: obj.targetValue,
            currentValue: 0,
            objectiveType: obj.objectiveType,
            metadata: obj.metadata,
          )).toList(),
          rewards: quest.rewards,
          levelRequirement: quest.levelRequirement,
          prerequisiteQuestIds: quest.prerequisiteQuestIds,
          startDate: _getWeekStart(),
          endDate: _getWeekEnd(),
          sortOrder: quest.sortOrder,
          isAutoStart: quest.isAutoStart,
          repeatType: quest.repeatType,
          completionCount: 0,
          category: quest.category,
          estimatedDuration: quest.estimatedDuration,
          metadata: quest.metadata,
        );

        _quests[quest.questId] = reset;
      }
    }

    _eventController.add(QuestEvent(
      type: QuestEventType.weeklyReset,
      timestamp: DateTime.now(),
    ));
  }

  static DateTime _getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _getTodayEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  static DateTime _getWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static DateTime _getWeekEnd() {
    final now = DateTime.now();
    return now.add(Duration(days: 7 - now.weekday));
  }

  List<Quest> getAllQuests() {
    return _quests.values.toList();
  }

  List<Quest> getQuestsByType(QuestType type) {
    return _quests.values
        .where((quest) => quest.type == type)
        .toList();
  }

  List<Quest> getAvailableQuests(String userId, int userLevel) {
    return _quests.values
        .where((quest) =>
            quest.levelRequirement <= userLevel &&
            quest.canStart &&
            !quest.hasExpired &&
            _checkPrerequisites(userId, quest.questId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Quest> getActiveQuests(String userId) {
    return _quests.values
        .where((quest) => quest.isActive && !quest.hasExpired)
        .toList();
  }

  List<Quest> getCompletedQuests(String userId) {
    return _quests.values
        .where((quest) => quest.isCompleted && !quest.hasExpired)
        .toList();
  }

  Quest? getQuest(String questId) {
    return _quests[questId];
  }

  bool _checkPrerequisites(String userId, String questId) {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (quest.prerequisiteQuestIds.isEmpty) return true;

    for (final prereqId in quest.prerequisiteQuestIds) {
      final progress = _userProgress['$userId-$prereqId'];
      if (progress == null || !progress.isCompleted) {
        return false;
      }
    }

    return true;
  }

  Future<bool> startQuest({
    required String userId,
    required String questId,
  }) async {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (!quest.canStart) return false;

    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      type: quest.type,
      status: QuestStatus.inProgress,
      objectives: quest.objectives,
      rewards: quest.rewards,
      levelRequirement: quest.levelRequirement,
      prerequisiteQuestIds: quest.prerequisiteQuestIds,
      startDate: quest.startDate,
      endDate: quest.endDate,
      sortOrder: quest.sortOrder,
      isAutoStart: quest.isAutoStart,
      repeatType: quest.repeatType,
      lastCompletedAt: quest.lastCompletedAt,
      completionCount: quest.completionCount,
      category: quest.category,
      estimatedDuration: quest.estimatedDuration,
      metadata: quest.metadata,
    );

    _quests[questId] = updated;

    final progress = QuestProgress(
      questId: questId,
      userId: userId,
      status: QuestStatus.inProgress,
      objectives: quest.objectives,
      startedAt: DateTime.now(),
      attempts: 1,
      userProgress: {},
    );

    _userProgress['$userId-$questId'] = progress;

    _eventController.add(QuestEvent(
      type: QuestEventType.questStarted,
      questId: questId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> updateObjective({
    required String userId,
    required String questId,
    required String objectiveId,
    required int increment,
  }) async {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (!quest.isActive) return false;

    final progress = _userProgress['$userId-$questId'];
    if (progress == null) return false;

    final objIndex = progress.objectives.indexWhere((obj) => obj.objectiveId == objectiveId);
    if (objIndex < 0) return false;

    final objective = progress.objectives[objIndex];
    if (objective.isCompleted) return true;

    final updated = QuestObjective(
      objectiveId: objective.objectiveId,
      description: objective.description,
      targetValue: objective.targetValue,
      currentValue: (objective.currentValue + increment).clamp(0, objective.targetValue),
      objectiveType: objective.objectiveType,
      metadata: objective.metadata,
    );

    progress.objectives[objIndex] = updated;

    _eventController.add(QuestEvent(
      type: QuestEventType.objectiveUpdated,
      questId: questId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'objectiveId': objectiveId, 'newValue': updated.currentValue},
    ));

    if (_isQuestCompleted(questId, userId)) {
      await _completeQuest(userId, questId);
    }

    return true;
  }

  bool _isQuestCompleted(String questId, String userId) {
    final progress = _userProgress['$userId-$questId'];
    if (progress == null) return false;

    return progress.objectives.every((obj) => obj.isCompleted);
  }

  Future<void> _completeQuest(String userId, String questId) async {
    final quest = _quests[questId];
    if (quest == null) return;

    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      type: quest.type,
      status: QuestStatus.completed,
      objectives: quest.objectives,
      rewards: quest.rewards,
      levelRequirement: quest.levelRequirement,
      prerequisiteQuestIds: quest.prerequisiteQuestIds,
      startDate: quest.startDate,
      endDate: quest.endDate,
      sortOrder: quest.sortOrder,
      isAutoStart: quest.isAutoStart,
      repeatType: quest.repeatType,
      lastCompletedAt: DateTime.now(),
      completionCount: quest.completionCount + 1,
      category: quest.category,
      estimatedDuration: quest.estimatedDuration,
      metadata: quest.metadata,
    );

    _quests[questId] = updated;

    final progress = _userProgress['$userId-$questId'];
    if (progress != null) {
      final updatedProgress = QuestProgress(
        questId: questId,
        userId: userId,
        status: QuestStatus.completed,
        objectives: progress.objectives,
        startedAt: progress.startedAt,
        completedAt: DateTime.now(),
        attempts: progress.attempts,
        userProgress: progress.userProgress,
      );

      _userProgress['$userId-$questId'] = updatedProgress;
    }

    _eventController.add(QuestEvent(
      type: QuestEventType.questCompleted,
      questId: questId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'rewards': quest.rewards},
    ));
  }

  Future<bool> claimRewards({
    required String userId,
    required String questId,
  }) async {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (!quest.isCompleted) return false;
    if (quest.hasExpired) return false;

    final progress = _userProgress['$userId-$questId'];
    if (progress?.claimedAt != null) return false;

    if (progress != null) {
      final updated = QuestProgress(
        questId: questId,
        userId: userId,
        status: QuestStatus.claimed,
        objectives: progress.objectives,
        startedAt: progress.startedAt,
        completedAt: progress.completedAt,
        claimedAt: DateTime.now(),
        attempts: progress.attempts,
        userProgress: progress.userProgress,
      );

      _userProgress['$userId-$questId'] = updated;
    }

    _eventController.add(QuestEvent(
      type: QuestEventType.rewardsClaimed,
      questId: questId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'rewards': quest.rewards},
    ));

    return true;
  }

  Future<bool> abandonQuest({
    required String userId,
    required String questId,
  }) async {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (!quest.isActive) return false;

    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      type: quest.type,
      status: QuestStatus.abandoned,
      objectives: quest.objectives,
      rewards: quest.rewards,
      levelRequirement: quest.levelRequirement,
      prerequisiteQuestIds: quest.prerequisiteQuestIds,
      startDate: quest.startDate,
      endDate: quest.endDate,
      sortOrder: quest.sortOrder,
      isAutoStart: quest.isAutoStart,
      repeatType: quest.repeatType,
      lastCompletedAt: quest.lastCompletedAt,
      completionCount: quest.completionCount,
      category: quest.category,
      estimatedDuration: quest.estimatedDuration,
      metadata: quest.metadata,
    );

    _quests[questId] = updated;

    _eventController.add(QuestEvent(
      type: QuestEventType.questAbandoned,
      questId: questId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  List<QuestCategory> getAllCategories() {
    return _categories.values.toList();
  }

  QuestCategory? getCategory(String categoryId) {
    return _categories[categoryId];
  }

  QuestProgress? getQuestProgress(String userId, String questId) {
    return _userProgress['$userId-$questId'];
  }

  Map<String, dynamic> getQuestStats(String userId) {
    final available = getAvailableQuests(userId, 1).length;
    final active = getActiveQuests(userId).length;
    final completed = getCompletedQuests(userId).length;

    int totalCompleted = 0;
    for (final progress in _userProgress.values) {
      if (progress.userId == userId && progress.isCompleted) {
        totalCompleted++;
      }
    }

    return {
      'availableQuests': available,
      'activeQuests': active,
      'completedQuests': completed,
      'totalCompleted': totalCompleted,
    };
  }

  void dispose() {
    _dailyResetTimer?.cancel();
    _weeklyResetTimer?.cancel();
    _eventController.close();
  }
}

class QuestEvent {
  final QuestEventType type;
  final String? questId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const QuestEvent({
    required this.type,
    this.questId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum QuestEventType {
  questStarted,
  questCompleted,
  questAbandoned,
  objectiveUpdated,
  rewardsClaimed,
  dailyReset,
  weeklyReset,
  questExpired,
}

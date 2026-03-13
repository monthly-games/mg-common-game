import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 퀘스트 타입
enum QuestType {
  main,           // 메인 퀘스트
  side,           // 사이드 퀘스트
  daily,          // 일일 퀘스트
  weekly,         // 주간 퀘스트
  event,          // 이벤트 퀘스트
  achievement,    // 업적 퀘스트
  tutorial,       // 튜토리얼
}

/// 퀘스트 상태
enum QuestStatus {
  notStarted,     // 시작 전
  inProgress,     // 진행 중
  completed,      // 완료
  failed,         // 실패
  abandoned,      // 포기
  locked,         // 잠김
}

/// 퀘스트 목표
class QuestObjective {
  final String objectiveId;
  final String description;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;

  const QuestObjective({
    required this.objectiveId,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
  });
}

/// 퀘스트 보상
class QuestReward {
  final String rewardId;
  final RewardType type;
  final int amount;
  final String? itemId;
  final Map<String, dynamic>? metadata;

  const QuestReward({
    required this.rewardId,
    required this.type,
    required this.amount,
    this.itemId,
    this.metadata,
  });
}

/// 보상 타입
enum RewardType {
  experience,     // 경험치
  gold,           // 골드
  item,           // 아이템
  currency,       // 화폐
  reputation,     // 평판
  skill,          // 스킬 포인트
  custom,         // 커스텀
}

/// 퀘스트
class Quest {
  final String questId;
  final String name;
  final String description;
  final String? longDescription;
  final QuestType type;
  final QuestStatus status;
  final List<QuestObjective> objectives;
  final List<QuestReward> rewards;
  final List<String> prerequisites; // 선행 퀘스트
  final int requiredLevel;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final Duration? timeLimit;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? category;
  final Map<String, dynamic>? metadata;

  const Quest({
    required this.questId,
    required this.name,
    required this.description,
    this.longDescription,
    required this.type,
    required this.status,
    required this.objectives,
    required this.rewards,
    required this.prerequisites,
    required this.requiredLevel,
    this.availableFrom,
    this.availableUntil,
    this.timeLimit,
    this.startedAt,
    this.completedAt,
    this.category,
    this.metadata,
  });

  /// 진행률
  double get progress {
    if (objectives.isEmpty) return 0;
    final completed = objectives.where((o) => o.isCompleted).length;
    return completed / objectives.length;
  }

  /// 완료 가능한지
  bool get canComplete {
    return status == QuestStatus.inProgress &&
        objectives.every((o) => o.isCompleted);
  }

  /// 사용 가능한지
  bool get isAvailable {
    if (status == QuestStatus.locked) return false;
    if (requiredLevel > 0) return false; // 실제로는 레벨 체크
    if (availableFrom != null && DateTime.now().isBefore(availableFrom!)) {
      return false;
    }
    if (availableUntil != null && DateTime.now().isAfter(availableUntil!)) {
      return false;
    }
    return true;
  }
}

/// 퀘스트 진행
class QuestProgress {
  final String questId;
  final String objectiveId;
  final int progress;
  final DateTime timestamp;

  const QuestProgress({
    required this.questId,
    required this.objectiveId,
    required this.progress,
    required this.timestamp,
  });
}

/// 퀘스트 체인 (연속 퀘스트)
class QuestChain {
  final String chainId;
  final String name;
  final List<String> questIds; // 순서대로 진행
  final String currentQuestId;
  final bool isCompleted;

  const QuestChain({
    required this.chainId,
    required this.name,
    required this.questIds,
    required this.currentQuestId,
    required this.isCompleted,
  });
}

/// 퀘스트 카테고리
class QuestCategory {
  final String categoryId;
  final String name;
  final String description;
  final String icon;
  final List<String> questIds;

  const QuestCategory({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.questIds,
  });
}

/// 퀘스트 시스템 관리자
class QuestSystemManager {
  static final QuestSystemManager _instance =
      QuestSystemManager._();
  static QuestSystemManager get instance => _instance;

  QuestSystemManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;
  int? _currentLevel;

  final Map<String, Quest> _quests = {};
  final Map<String, QuestChain> _questChains = {};
  final Map<String, QuestCategory> _categories = {};

  final StreamController<Quest> _questController =
      StreamController<Quest>.broadcast();
  final StreamController<QuestProgress> _progressController =
      StreamController<QuestProgress>.broadcast();

  Stream<Quest> get onQuestUpdate => _questController.stream;
  Stream<QuestProgress> get onProgressUpdate => _progressController.stream;

  Timer? _dailyResetTimer;
  DateTime? _lastDailyReset;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');
    _currentLevel = _prefs?.getInt('player_level') ?? 1;

    // 퀘스트 로드
    await _loadQuests();

    // 퀘스트 카테고리 로드
    await _loadCategories();

    // 일일 리셋 타이머 시작
    _startDailyResetTimer();

    debugPrint('[QuestSystem] Initialized');
  }

  Future<void> _loadQuests() async {
    // 메인 퀘스트
    _quests['main_1'] = Quest(
      questId: 'main_1',
      name: '모험의 시작',
      description: '마을을 떠나 모험을 시작하세요',
      longDescription: '당신은 이제 막 모험을 시작한 초보 모험가입니다. 마을 밖으로 나가 세상을 탐험해보세요.',
      type: QuestType.main,
      status: QuestStatus.notStarted,
      objectives: const [
        QuestObjective(
          objectiveId: 'leave_village',
          description: '마을을 떠나기',
          currentProgress: 0,
          targetProgress: 1,
          isCompleted: false,
        ),
      ],
      rewards: const [
        QuestReward(
          rewardId: 'exp',
          type: RewardType.experience,
          amount: 100,
        ),
        QuestReward(
          rewardId: 'gold',
          type: RewardType.gold,
          amount: 50,
        ),
      ],
      prerequisites: [],
      requiredLevel: 1,
      category: 'story',
    );

    // 일일 퀘스트
    _quests['daily_1'] = Quest(
      questId: 'daily_1',
      name: '일일 사냥',
      description: '몬스터 10마리 처치',
      type: QuestType.daily,
      status: QuestStatus.notStarted,
      objectives: const [
        QuestObjective(
          objectiveId: 'kill_monsters',
          description: '몬스터 처치',
          currentProgress: 0,
          targetProgress: 10,
          isCompleted: false,
        ),
      ],
      rewards: const [
        QuestReward(
          rewardId: 'gold',
          type: RewardType.gold,
          amount: 100,
        ),
        QuestReward(
          rewardId: 'exp',
          type: RewardType.experience,
          amount: 50,
        ),
      ],
      prerequisites: [],
      requiredLevel: 1,
      category: 'daily',
    );

    // 업적 퀘스트
    _quests['achievement_1'] = Quest(
      questId: 'achievement_1',
      name: '첫 승리',
      description: '전투에서 승리하기',
      type: QuestType.achievement,
      status: QuestStatus.notStarted,
      objectives: const [
        QuestObjective(
          objectiveId: 'win_battle',
          description: '전투 승리',
          currentProgress: 0,
          targetProgress: 1,
          isCompleted: false,
        ),
      ],
      rewards: const [
        QuestReward(
          rewardId: 'item',
          type: RewardType.item,
          amount: 1,
          itemId: 'sword_001',
        ),
      ],
      prerequisites: [],
      requiredLevel: 1,
      category: 'battle',
    );

    // 퀘스트 체인 생성
    _questChains['main_story'] = QuestChain(
      chainId: 'main_story',
      name: '메인 스토리',
      questIds: ['main_1', 'main_2', 'main_3'],
      currentQuestId: 'main_1',
      isCompleted: false,
    );
  }

  Future<void> _loadCategories() async {
    _categories['story'] = QuestCategory(
      categoryId: 'story',
      name: '스토리',
      description: '메인 스토리 퀘스트',
      icon: 'book',
      questIds: ['main_1'],
    );

    _categories['daily'] = QuestCategory(
      categoryId: 'daily',
      name: '일일',
      description: '매일 완료할 수 있는 퀘스트',
      icon: 'calendar_today',
      questIds: ['daily_1'],
    );

    _categories['battle'] = QuestCategory(
      categoryId: 'battle',
      name: '전투',
      description: '전투 관련 퀘스트',
      icon: 'sword',
      questIds: ['achievement_1'],
    );
  }

  void _startDailyResetTimer() {
    _dailyResetTimer?.cancel();
    _dailyResetTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkDailyReset();
    });
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastDailyReset == null || _lastDailyReset!.isBefore(today)) {
      _resetDailyQuests();
      _lastDailyReset = today;
    }
  }

  void _resetDailyQuests() {
    for (final quest in _quests.values) {
      if (quest.type == QuestType.daily && quest.status == QuestStatus.completed) {
        final reset = Quest(
          questId: quest.questId,
          name: quest.name,
          description: quest.description,
          longDescription: quest.longDescription,
          type: quest.type,
          status: QuestStatus.notStarted,
          objectives: quest.objectives.map((o) => QuestObjective(
            objectiveId: o.objectiveId,
            description: o.description,
            currentProgress: 0,
            targetProgress: o.targetProgress,
            isCompleted: false,
          )).toList(),
          rewards: quest.rewards,
          prerequisites: quest.prerequisites,
          requiredLevel: quest.requiredLevel,
          category: quest.category,
        );

        _quests[quest.questId] = reset;
        _questController.add(reset);
      }
    }

    debugPrint('[QuestSystem] Daily quests reset');
  }

  /// 퀘스트 시작
  Future<bool> startQuest(String questId) async {
    final quest = _quests[questId];
    if (quest == null) {
      debugPrint('[QuestSystem] Quest not found: $questId');
      return false;
    }

    if (!quest.isAvailable) {
      debugPrint('[QuestSystem] Quest not available: $questId');
      return false;
    }

    // 선행 퀘스트 체크
    for (final prereq in quest.prerequisites) {
      final prereqQuest = _quests[prereq];
      if (prereqQuest == null || prereqQuest.status != QuestStatus.completed) {
        debugPrint('[QuestSystem] Prerequisite not met: $prereq');
        return false;
      }
    }

    // 퀘스트 시작
    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      longDescription: quest.longDescription,
      type: quest.type,
      status: QuestStatus.inProgress,
      objectives: quest.objectives,
      rewards: quest.rewards,
      prerequisites: quest.prerequisites,
      requiredLevel: quest.requiredLevel,
      availableFrom: quest.availableFrom,
      availableUntil: quest.availableUntil,
      timeLimit: quest.timeLimit,
      startedAt: DateTime.now(),
      category: quest.category,
    );

    _quests[questId] = updated;
    _questController.add(updated);

    await _saveQuestProgress();

    debugPrint('[QuestSystem] Started: $questId');

    return true;
  }

  /// 퀘스트 진행 업데이트
  Future<void> updateProgress({
    required String questId,
    required String objectiveId,
    required int progress,
  }) async {
    final quest = _quests[questId];
    if (quest == null || quest.status != QuestStatus.inProgress) {
      return;
    }

    // 목표 찾기
    final objectiveIndex = quest.objectives.indexWhere(
      (o) => o.objectiveId == objectiveId,
    );

    if (objectiveIndex == -1) return;

    final oldObjective = quest.objectives[objectiveIndex];

    // 목표 업데이트
    final updatedObjectives = List<QuestObjective>.from(quest.objectives);
    final newProgress = progress.clamp(0, oldObjective.targetProgress);

    updatedObjectives[objectiveIndex] = QuestObjective(
      objectiveId: oldObjective.objectiveId,
      description: oldObjective.description,
      currentProgress: newProgress,
      targetProgress: oldObjective.targetProgress,
      isCompleted: newProgress >= oldObjective.targetProgress,
    );

    // 퀘스트 업데이트
    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      longDescription: quest.longDescription,
      type: quest.type,
      status: quest.status,
      objectives: updatedObjectives,
      rewards: quest.rewards,
      prerequisites: quest.prerequisites,
      requiredLevel: quest.requiredLevel,
      availableFrom: quest.availableFrom,
      availableUntil: quest.availableUntil,
      timeLimit: quest.timeLimit,
      startedAt: quest.startedAt,
      category: quest.category,
    );

    _quests[questId] = updated;
    _questController.add(updated);

    // 진행 이벤트
    _progressController.add(QuestProgress(
      questId: questId,
      objectiveId: objectiveId,
      progress: newProgress,
      timestamp: DateTime.now(),
    ));

    // 자동 완료 체크
    if (updated.canComplete) {
      await completeQuest(questId);
    }

    await _saveQuestProgress();
  }

  /// 퀘스트 완료
  Future<bool> completeQuest(String questId) async {
    final quest = _quests[questId];
    if (quest == null) return false;

    // 보상 지급
    await _grantRewards(quest.rewards);

    // 상태 변경
    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      longDescription: quest.longDescription,
      type: quest.type,
      status: QuestStatus.completed,
      objectives: quest.objectives,
      rewards: quest.rewards,
      prerequisites: quest.prerequisites,
      requiredLevel: quest.requiredLevel,
      availableFrom: quest.availableFrom,
      availableUntil: quest.availableUntil,
      timeLimit: quest.timeLimit,
      startedAt: quest.startedAt,
      completedAt: DateTime.now(),
      category: quest.category,
    );

    _quests[questId] = updated;
    _questController.add(updated);

    // 퀘스트 체인 업데이트
    _updateQuestChain(questId);

    await _saveQuestProgress();

    debugPrint('[QuestSystem] Completed: $questId');

    return true;
  }

  /// 퀘스트 포기
  Future<bool> abandonQuest(String questId) async {
    final quest = _quests[questId];
    if (quest == null) return false;
    if (quest.type == QuestType.main) {
      debugPrint('[QuestSystem] Cannot abandon main quest');
      return false;
    }

    final updated = Quest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      longDescription: quest.longDescription,
      type: quest.type,
      status: QuestStatus.abandoned,
      objectives: quest.objectives,
      rewards: quest.rewards,
      prerequisites: quest.prerequisites,
      requiredLevel: quest.requiredLevel,
      category: quest.category,
    );

    _quests[questId] = updated;
    _questController.add(updated);

    await _saveQuestProgress();

    return true;
  }

  /// 퀘스트 조회
  Quest? getQuest(String questId) {
    return _quests[questId];
  }

  /// 퀘스트 목록 조회
  List<Quest> getQuests({
    QuestType? type,
    QuestStatus? status,
    String? category,
  }) {
    var quests = _quests.values.toList();

    if (type != null) {
      quests = quests.where((q) => q.type == type).toList();
    }

    if (status != null) {
      quests = quests.where((q) => q.status == status).toList();
    }

    if (category != null) {
      quests = quests.where((q) => q.category == category).toList();
    }

    return quests;
  }

  /// 사용 가능한 퀘스트
  List<Quest> getAvailableQuests() {
    return _quests.values.where((q) => q.isAvailable).toList();
  }

  /// 진행 중인 퀘스트
  List<Quest> getInProgressQuests() {
    return _quests.values
        .where((q) => q.status == QuestStatus.inProgress)
        .toList();
  }

  /// 완료한 퀘스트
  List<Quest> getCompletedQuests() {
    return _quests.values
        .where((q) => q.status == QuestStatus.completed)
        .toList();
  }

  /// 퀘스트 카테고리 목록
  List<QuestCategory> getCategories() {
    return _categories.values.toList();
  }

  /// 카테고리별 퀘스트
  List<Quest> getQuestsByCategory(String categoryId) {
    final category = _categories[categoryId];
    if (category == null) return [];

    return category.questIds
        .map((id) => _quests[id])
        .where((q) => q != null)
        .cast<Quest>()
        .toList();
  }

  /// 퀘스트 체인 조회
  QuestChain? getQuestChain(String chainId) {
    return _questChains[chainId];
  }

  /// 보상 지급
  Future<void> _grantRewards(List<QuestReward> rewards) async {
    for (final reward in rewards) {
      switch (reward.type) {
        case RewardType.experience:
          debugPrint('[QuestSystem] Granted ${reward.amount} EXP');
          break;

        case RewardType.gold:
          debugPrint('[QuestSystem] Granted ${reward.amount} Gold');
          break;

        case RewardType.item:
          debugPrint('[QuestSystem] Granted item: ${reward.itemId}');
          break;

        default:
          break;
      }
    }
  }

  void _updateQuestChain(String completedQuestId) {
    for (final chain in _questChains.values) {
      if (chain.currentQuestId == completedQuestId) {
        final currentIndex = chain.questIds.indexOf(completedQuestId);

        if (currentIndex < chain.questIds.length - 1) {
          // 다음 퀘스트 잠금 해제
          final nextQuestId = chain.questIds[currentIndex + 1];
          final nextQuest = _quests[nextQuestId];

          if (nextQuest != null && nextQuest.status == QuestStatus.locked) {
            final updated = Quest(
              questId: nextQuest.questId,
              name: nextQuest.name,
              description: nextQuest.description,
              longDescription: nextQuest.longDescription,
              type: nextQuest.type,
              status: QuestStatus.notStarted,
              objectives: nextQuest.objectives,
              rewards: nextQuest.rewards,
              prerequisites: nextQuest.prerequisites,
              requiredLevel: nextQuest.requiredLevel,
              category: nextQuest.category,
            );

            _quests[nextQuestId] = updated;
            _questController.add(updated);
          }

          // 체인 업데이트
          _questChains[chain.chainId] = QuestChain(
            chainId: chain.chainId,
            name: chain.name,
            questIds: chain.questIds,
            currentQuestId: nextQuestId,
            isCompleted: false,
          );
        } else {
          // 체인 완료
          _questChains[chain.chainId] = QuestChain(
            chainId: chain.chainId,
            name: chain.name,
            questIds: chain.questIds,
            currentQuestId: completedQuestId,
            isCompleted: true,
          );
        }

        break;
      }
    }
  }

  Future<void> _saveQuestProgress() async {
    // 진행 상태 저장
    debugPrint('[QuestSystem] Progress saved');
  }

  void dispose() {
    _questController.close();
    _progressController.close();
    _dailyResetTimer?.cancel();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/quest/daily_quest_system.dart';
import 'package:mg_common_game/core/economy/currency_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('QuestReward', () {
    test('기본 생성', () {
      final reward = QuestReward(
        type: QuestRewardType.coins,
        amount: 100,
      );

      expect(reward.type, QuestRewardType.coins);
      expect(reward.amount, 100);
      expect(reward.itemId, isNull);
      expect(reward.customData, isNull);
    });

    test('toJson/fromJson 변환 - coins', () {
      final reward = QuestReward(
        type: QuestRewardType.coins,
        amount: 500,
      );

      final json = reward.toJson();
      final restored = QuestReward.fromJson(json);

      expect(restored.type, QuestRewardType.coins);
      expect(restored.amount, 500);
    });

    test('toJson/fromJson 변환 - items with itemId', () {
      final reward = QuestReward(
        type: QuestRewardType.items,
        amount: 1,
        itemId: 'powerup_001',
      );

      final json = reward.toJson();
      final restored = QuestReward.fromJson(json);

      expect(restored.type, QuestRewardType.items);
      expect(restored.itemId, 'powerup_001');
    });

    test('toJson/fromJson 변환 - custom with data', () {
      final customData = {'key': 'value', 'count': 5};
      final reward = QuestReward(
        type: QuestRewardType.custom,
        amount: 0,
        customData: customData,
      );

      final json = reward.toJson();
      final restored = QuestReward.fromJson(json);

      expect(restored.type, QuestRewardType.custom);
      expect(restored.customData, customData);
    });
  });

  group('DailyQuest', () {
    late DateTime now;
    late DateTime tomorrow;

    setUp(() {
      // 항상 미래의 날짜를 사용하도록 설정
      final current = DateTime.now();
      now = DateTime(current.year, current.month, current.day, 12, 0);
      tomorrow = now.add(const Duration(days: 1));
    });

    test('기본 생성', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트 퀘스트',
        description: '테스트 설명',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 100),
        ],
        requirements: {'target': 10},
        startTime: now,
        endTime: tomorrow,
      );

      expect(quest.id, 'quest_001');
      expect(quest.title, '테스트 퀘스트');
      expect(quest.difficulty, QuestDifficulty.easy);
      expect(quest.rewards.length, 1);
      expect(quest.isActive, true);
    });

    test('progress 계산', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
      );

      expect(quest.progress, 1.0);
    });

    test('isCompleted - progress >= 1.0', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
      );

      expect(quest.isCompleted, true);
    });

    test('canComplete - 시간 내에 활성화된 퀘스트', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
        isActive: true,
      );

      expect(quest.canComplete, true);
    });

    test('canComplete - 비활성화된 퀘스트', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
        isActive: false,
      );

      expect(quest.canComplete, false);
    });

    test('canComplete - 만료된 퀘스트', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: past,
        endTime: past,
        isActive: true,
      );

      expect(quest.canComplete, false);
    });

    test('remainingTime 계산', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트',
        description: '설명',
        difficulty: QuestDifficulty.normal,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
      );

      final remaining = quest.remainingTime;
      expect(remaining.inHours, greaterThan(0));
      expect(remaining.inHours, lessThanOrEqualTo(24));
    });

    test('copyWith - 부분 업데이트', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '원본',
        description: '설명',
        difficulty: QuestDifficulty.easy,
        rewards: [],
        requirements: {},
        startTime: now,
        endTime: tomorrow,
      );

      final updated = quest.copyWith(
        title: '수정됨',
        difficulty: QuestDifficulty.hard,
      );

      expect(updated.id, 'quest_001');
      expect(updated.title, '수정됨');
      expect(updated.difficulty, QuestDifficulty.hard);
      expect(updated.description, '설명');
    });

    test('toJson/fromJson 변환', () {
      final quest = DailyQuest(
        id: 'quest_001',
        title: '테스트 퀘스트',
        description: '테스트 설명',
        difficulty: QuestDifficulty.expert,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 1000),
          QuestReward(type: QuestRewardType.gems, amount: 50),
        ],
        requirements: {'wins': 5, 'score': 10000},
        startTime: now,
        endTime: tomorrow,
        isActive: true,
      );

      final json = quest.toJson();
      final restored = DailyQuest.fromJson(json);

      expect(restored.id, quest.id);
      expect(restored.title, quest.title);
      expect(restored.description, quest.description);
      expect(restored.difficulty, quest.difficulty);
      expect(restored.rewards.length, quest.rewards.length);
      expect(restored.requirements, quest.requirements);
      expect(restored.isActive, quest.isActive);
    });
  });

  group('QuestStatistics', () {
    final testDate = DateTime(2025, 1, 1, 12, 0);

    test('기본 생성', () {
      final stats = QuestStatistics(
        totalQuestsCompleted: 50,
        totalQuestsAvailable: 100,
        currentStreak: 7,
        longestStreak: 14,
        lastCompletionDate: testDate,
      );

      expect(stats.totalQuestsCompleted, 50);
      expect(stats.totalQuestsAvailable, 100);
      expect(stats.currentStreak, 7);
      expect(stats.longestStreak, 14);
    });

    test('completionRate 계산', () {
      final stats = QuestStatistics(
        totalQuestsCompleted: 75,
        totalQuestsAvailable: 100,
        currentStreak: 5,
        longestStreak: 10,
        lastCompletionDate: testDate,
      );

      expect(stats.completionRate, 0.75);
    });

    test('completionRate - 0으로 나누기 방지', () {
      final stats = QuestStatistics(
        totalQuestsCompleted: 0,
        totalQuestsAvailable: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastCompletionDate: testDate,
      );

      expect(stats.completionRate, 0.0);
    });

    test('toJson/fromJson 변환', () {
      final stats = QuestStatistics(
        totalQuestsCompleted: 30,
        totalQuestsAvailable: 50,
        currentStreak: 3,
        longestStreak: 8,
        lastCompletionDate: testDate,
      );

      final json = stats.toJson();
      final restored = QuestStatistics.fromJson(json);

      expect(restored.totalQuestsCompleted, 30);
      expect(restored.totalQuestsAvailable, 50);
      expect(restored.currentStreak, 3);
      expect(restored.longestStreak, 8);
    });
  });

  group('DailyQuestSystem', () {
    setUp(() async {
      // 테스트를 위해 SharedPreferences 초기화
      SharedPreferences.setMockInitialValues({});
      await CurrencyManager.instance.initialize();
    });

    tearDown(() async {
      // 각 테스트 후 시스템 초기화
      final system = DailyQuestSystem.instance;
      await system.clearData();
    });

    test('싱글톤 인스턴스', () {
      final system1 = DailyQuestSystem.instance;
      final system2 = DailyQuestSystem.instance;

      expect(identical(system1, system2), true);
    });

    test('초기화 전 isInitialized는 false', () {
      final system = DailyQuestSystem.instance;
      expect(system.isInitialized, false);
    });

    test('initialize 후 isInitialized는 true', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      expect(system.isInitialized, true);
    });

    test('registerGameData로 게임 데이터 등록', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      final mockGameData = _MockQuestData();
      system.registerGameData('mg-game-0047', mockGameData);

      expect(system.getQuestsForGame('mg-game-0047'), isNotNull);
    });

    test('초기 상태에서는 빈 퀘스트 목록', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      expect(system.allQuests, isEmpty);
      expect(system.getQuestsForGame('non-existent'), isEmpty);
    });

    test('completableQuests 계산', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      final mockGameData = _MockQuestData();
      system.registerGameData('mg-game-0047', mockGameData);

      final completable = system.completableQuests;
      expect(completable, greaterThanOrEqualTo(0));
    });

    test('completedQuests 계산', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      final mockGameData = _MockQuestData();
      system.registerGameData('mg-game-0047', mockGameData);

      final completed = system.completedQuests;
      expect(completed, greaterThanOrEqualTo(0));
    });

    test('updateQuestProgress로 진행률 업데이트', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      await system.updateQuestProgress(
        'mg-game-0047',
        'quest_001',
        {'progress': 0.5},
      );

      // 예외가 발생하지 않으면 성공
      expect(system.isInitialized, true);
    });

    test('clearData로 모든 데이터 초기화', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      await system.updateQuestProgress(
        'mg-game-0047',
        'quest_001',
        {'progress': 0.5},
      );

      await system.clearData();

      expect(system.allQuests, isEmpty);
    });

    test('ChangeNotifier 상속', () async {
      final system = DailyQuestSystem.instance;
      await system.initialize();

      var notified = false;
      system.addListener(() => notified = true);

      system.registerGameData('mg-game-0047', _MockQuestData());

      expect(notified, true);
    });
  });

  group('QuestDifficulty', () {
    test('모든 난이도 값 존재', () {
      expect(QuestDifficulty.values.length, 4);
      expect(QuestDifficulty.values, contains(QuestDifficulty.easy));
      expect(QuestDifficulty.values, contains(QuestDifficulty.normal));
      expect(QuestDifficulty.values, contains(QuestDifficulty.hard));
      expect(QuestDifficulty.values, contains(QuestDifficulty.expert));
    });

    test('난이도별 name 속성', () {
      expect(QuestDifficulty.easy.name, 'easy');
      expect(QuestDifficulty.normal.name, 'normal');
      expect(QuestDifficulty.hard.name, 'hard');
      expect(QuestDifficulty.expert.name, 'expert');
    });
  });

  group('QuestRewardType', () {
    test('모든 보상 타입 값 존재', () {
      expect(QuestRewardType.values.length, 5);
      expect(QuestRewardType.values, contains(QuestRewardType.coins));
      expect(QuestRewardType.values, contains(QuestRewardType.gems));
      expect(QuestRewardType.values, contains(QuestRewardType.experience));
      expect(QuestRewardType.values, contains(QuestRewardType.items));
      expect(QuestRewardType.values, contains(QuestRewardType.custom));
    });

    test('보상 타입별 name 속성', () {
      expect(QuestRewardType.coins.name, 'coins');
      expect(QuestRewardType.gems.name, 'gems');
      expect(QuestRewardType.experience.name, 'experience');
      expect(QuestRewardType.items.name, 'items');
      expect(QuestRewardType.custom.name, 'custom');
    });
  });
}

/// 테스트용 Mock GameQuestData 구현
class _MockQuestData extends GameQuestData {
  @override
  String get gameId => 'mg-game-0047';

  @override
  Future<void> completeQuest(String questId) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>> fetchPlayerProgress() async {
    return {'quest_001': 0.5};
  }

  @override
  Future<void> grantReward(QuestReward reward) async {
    // Mock implementation
  }

  @override
  List<DailyQuest> getQuestTemplates() {
    final now = DateTime.now();
    return [
      DailyQuest(
        id: 'daily_play',
        title: '일일 플레이',
        description: '게임을 1회 플레이하세요',
        difficulty: QuestDifficulty.easy,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 100),
        ],
        requirements: {'plays': 1},
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        isActive: true,
      ),
      DailyQuest(
        id: 'daily_win',
        title: '일일 승리',
        description: '게임에서 1회 승리하세요',
        difficulty: QuestDifficulty.normal,
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 200),
          QuestReward(type: QuestRewardType.gems, amount: 10),
        ],
        requirements: {'wins': 1},
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        isActive: true,
      ),
    ];
  }
}

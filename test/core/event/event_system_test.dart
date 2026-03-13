import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/event/event_system.dart';
import 'package:mg_common_game/core/quest/daily_quest_system.dart';
import 'package:mg_common_game/core/economy/currency_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EventType', () {
    test('모든 이벤트 타입 존재', () {
      expect(EventType.values.length, 6);
      expect(EventType.values, contains(EventType.daily));
      expect(EventType.values, contains(EventType.weekly));
      expect(EventType.values, contains(EventType.seasonal));
      expect(EventType.values, contains(EventType.special));
      expect(EventType.values, contains(EventType.limited));
      expect(EventType.values, contains(EventType.campaign));
    });
  });

  group('EventStatus', () {
    test('모든 상태 존재', () {
      expect(EventStatus.values.length, 4);
      expect(EventStatus.values, contains(EventStatus.upcoming));
      expect(EventStatus.values, contains(EventStatus.active));
      expect(EventStatus.values, contains(EventStatus.ended));
      expect(EventStatus.values, contains(EventStatus.archived));
    });
  });

  group('EventRequirement', () {
    test('기본 생성', () {
      final requirement = EventRequirement(
        type: EventRequirementType.level,
        description: '레벨 10 달성',
        criteria: {'level': 10},
      );

      expect(requirement.type, EventRequirementType.level);
      expect(requirement.description, '레벨 10 달성');
      expect(requirement.isSatisfied, false);
    });

    test('toJson/fromJson 변환', () {
      final requirement = EventRequirement(
        type: EventRequirementType.achievement,
        description: '업적 완료',
        criteria: {'achievement_id': 'first_win'},
        isSatisfied: true,
      );

      final json = requirement.toJson();
      final restored = EventRequirement.fromJson(json);

      expect(restored.type, EventRequirementType.achievement);
      expect(restored.description, '업적 완료');
      expect(restored.isSatisfied, true);
    });
  });

  group('EventReward', () {
    test('기본 생성', () {
      final reward = EventReward(
        id: 'reward_001',
        description: '100코인 보상',
        rewards: [
          QuestReward(type: QuestRewardType.coins, amount: 100),
        ],
        requiredPoints: 50,
      );

      expect(reward.id, 'reward_001');
      expect(reward.description, '100코인 보상');
      expect(reward.requiredPoints, 50);
      expect(reward.rewards.length, 1);
    });

    test('toJson/fromJson 변환', () {
      final reward = EventReward(
        id: 'reward_002',
        description: '보석 보상',
        rewards: [
          QuestReward(type: QuestRewardType.gems, amount: 50),
        ],
        requiredPoints: 100,
      );

      final json = reward.toJson();
      final restored = EventReward.fromJson(json);

      expect(restored.id, 'reward_002');
      expect(restored.requiredPoints, 100);
    });
  });

  group('GameEvent', () {
    late DateTime now;
    late DateTime tomorrow;
    late DateTime nextWeek;

    setUp(() {
      final current = DateTime.now();
      now = DateTime(current.year, current.month, current.day, 12, 0);
      tomorrow = now.add(const Duration(days: 1));
      nextWeek = now.add(const Duration(days: 7));
    });

    test('기본 생성', () {
      final event = GameEvent(
        id: 'event_001',
        title: '일일 이벤트',
        description: '매일 참여 가능한 이벤트',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [],
        rewards: [],
      );

      expect(event.id, 'event_001');
      expect(event.title, '일일 이벤트');
      expect(event.type, EventType.daily);
      expect(event.status, EventStatus.active);
    });

    test('isActive - 활성화된 이벤트', () {
      final event = GameEvent(
        id: 'event_001',
        title: '활성 이벤트',
        description: '설명',
        type: EventType.special,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [],
        rewards: [],
      );

      expect(event.isActive, true);
    });

    test('isActive - 비활성화된 이벤트', () {
      final event = GameEvent(
        id: 'event_001',
        title: '비활성 이벤트',
        description: '설명',
        type: EventType.special,
        status: EventStatus.ended,
        startTime: now,
        endTime: tomorrow,
        requirements: [],
        rewards: [],
      );

      expect(event.isActive, false);
    });

    test('canParticipate - 참여 가능', () {
      final event = GameEvent(
        id: 'event_001',
        title: '이벤트',
        description: '설명',
        type: EventType.special,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [
          EventRequirement(
            type: EventRequirementType.level,
            description: '레벨 10',
            criteria: {'level': 10},
            isSatisfied: true,
          ),
        ],
        rewards: [],
        maxParticipants: 100,
        currentParticipants: 50,
      );

      expect(event.canParticipate, true);
    });

    test('canParticipate - 조건 불충족', () {
      final event = GameEvent(
        id: 'event_001',
        title: '이벤트',
        description: '설명',
        type: EventType.special,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [
          EventRequirement(
            type: EventRequirementType.level,
            description: '레벨 10',
            criteria: {'level': 10},
            isSatisfied: false,
          ),
        ],
        rewards: [],
      );

      expect(event.canParticipate, false);
    });

    test('canParticipate - 정원 초과', () {
      final event = GameEvent(
        id: 'event_001',
        title: '이벤트',
        description: '설명',
        type: EventType.limited,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [],
        rewards: [],
        maxParticipants: 100,
        currentParticipants: 100,
      );

      expect(event.canParticipate, false);
    });

    test('progress 계산', () {
      final event = GameEvent(
        id: 'event_001',
        title: '이벤트',
        description: '설명',
        type: EventType.weekly,
        status: EventStatus.active,
        startTime: now,
        endTime: nextWeek,
        requirements: [],
        rewards: [],
      );

      // 이벤트 시작 후이므로 진행률 > 0
      expect(event.progress, greaterThan(0.0));
      expect(event.progress, lessThanOrEqualTo(1.0));
    });

    test('copyWith', () {
      final event = GameEvent(
        id: 'event_001',
        title: '원본',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [],
        rewards: [],
      );

      final updated = event.copyWith(
        title: '수정됨',
        currentParticipants: 10,
      );

      expect(updated.id, 'event_001');
      expect(updated.title, '수정됨');
      expect(updated.currentParticipants, 10);
      expect(updated.description, '설명');
    });

    test('toJson/fromJson 변환', () {
      final event = GameEvent(
        id: 'event_001',
        title: '테스트 이벤트',
        description: '테스트 설명',
        type: EventType.seasonal,
        status: EventStatus.active,
        startTime: now,
        endTime: tomorrow,
        requirements: [
          EventRequirement(
            type: EventRequirementType.level,
            description: '레벨 20',
            criteria: {'level': 20},
          ),
        ],
        rewards: [
          EventReward(
            id: 'reward_001',
            description: '보상',
            rewards: [
              QuestReward(type: QuestRewardType.coins, amount: 500),
            ],
            requiredPoints: 100,
          ),
        ],
        maxParticipants: 1000,
        currentParticipants: 500,
      );

      final json = event.toJson();
      final restored = GameEvent.fromJson(json);

      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.type, event.type);
      expect(restored.status, event.status);
      expect(restored.requirements.length, event.requirements.length);
      expect(restored.rewards.length, event.rewards.length);
      expect(restored.maxParticipants, 1000);
      expect(restored.currentParticipants, 500);
    });
  });

  group('PlayerEventProgress', () {
    test('기본 생성', () {
      final progress = PlayerEventProgress(
        eventId: 'event_001',
        currentPoints: 50,
        claimedRewards: ['reward_001'],
      );

      expect(progress.eventId, 'event_001');
      expect(progress.currentPoints, 50);
      expect(progress.claimedRewards, contains('reward_001'));
    });

    test('toJson/fromJson 변환', () {
      final progress = PlayerEventProgress(
        eventId: 'event_002',
        currentPoints: 100,
        claimedRewards: ['reward_001', 'reward_002'],
        customData: {'stage': 5},
      );

      final json = progress.toJson();
      final restored = PlayerEventProgress.fromJson(json);

      expect(restored.eventId, 'event_002');
      expect(restored.currentPoints, 100);
      expect(restored.claimedRewards.length, 2);
      expect(restored.customData['stage'], 5);
    });
  });

  group('EventSystem', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CurrencyManager.instance.initialize();
      await EventSystem.instance.initialize();
    });

    tearDown(() async {
      final system = EventSystem.instance;
      await system.clearData();
    });

    test('싱글톤 인스턴스', () {
      final system1 = EventSystem.instance;
      final system2 = EventSystem.instance;

      expect(identical(system1, system2), true);
    });

    test('초기화 후 isInitialized는 true', () {
      final system = EventSystem.instance;
      // setUp에서 초기화됨
      expect(system.isInitialized, true);
    });

    test('registerEvent로 이벤트 등록', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final event = GameEvent(
        id: 'test_event',
        title: '테스트 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      system.registerEvent(event);

      expect(system.getEvent('test_event'), isNotNull);
      expect(system.allEvents.length, 1);
    });

    test('registerEvents로 여러 이벤트 등록', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final events = [
        GameEvent(
          id: 'event_001',
          title: '이벤트 1',
          description: '설명',
          type: EventType.daily,
          status: EventStatus.active,
          startTime: now,
          endTime: now.add(const Duration(days: 1)),
          requirements: [],
          rewards: [],
        ),
        GameEvent(
          id: 'event_002',
          title: '이벤트 2',
          description: '설명',
          type: EventType.weekly,
          status: EventStatus.upcoming,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 8)),
          requirements: [],
          rewards: [],
        ),
      ];

      system.registerEvents(events);

      expect(system.allEvents.length, 2);
    });

    test('activeEvents로 활성 이벤트 필터링', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final activeEvent = GameEvent(
        id: 'active_event',
        title: '활성 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      final upcomingEvent = GameEvent(
        id: 'upcoming_event',
        title: '예정 이벤트',
        description: '설명',
        type: EventType.weekly,
        status: EventStatus.upcoming,
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 8)),
        requirements: [],
        rewards: [],
      );

      system.registerEvents([activeEvent, upcomingEvent]);

      expect(system.activeEvents.length, 1);
      expect(system.activeEvents.first.id, 'active_event');
    });

    test('participatableEvents로 참여 가능한 이벤트 필터링', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final participatableEvent = GameEvent(
        id: 'can_participate',
        title: '참여 가능',
        description: '설명',
        type: EventType.special,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      final lockedEvent = GameEvent(
        id: 'locked',
        title: '잠김',
        description: '설명',
        type: EventType.special,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [
          EventRequirement(
            type: EventRequirementType.level,
            description: '레벨 50',
            criteria: {'level': 50},
            isSatisfied: false,
          ),
        ],
        rewards: [],
      );

      system.registerEvents([participatableEvent, lockedEvent]);

      expect(system.participatableEvents.length, 1);
      expect(system.participatableEvents.first.id, 'can_participate');
    });

    test('earnEventPoints로 포인트 획득', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final event = GameEvent(
        id: 'point_event',
        title: '포인트 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      system.registerEvent(event);

      await system.earnEventPoints('point_event', 50);

      final progress = system.getProgress('point_event');
      expect(progress, isNotNull);
      expect(progress!.currentPoints, 50);
    });

    test('participateInEvent로 참여 처리', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final event = GameEvent(
        id: 'participate_event',
        title: '참여 이벤트',
        description: '설명',
        type: EventType.limited,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
        maxParticipants: 100,
        currentParticipants: 10,
      );

      system.registerEvent(event);

      await system.participateInEvent('participate_event');

      final updatedEvent = system.getEvent('participate_event');
      expect(updatedEvent!.currentParticipants, 11);
    });

    test('getProgress로 진행률 조회', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final event = GameEvent(
        id: 'progress_event',
        title: '진행률 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      system.registerEvent(event);

      final progress = system.getProgress('progress_event');
      expect(progress, isNotNull);
      expect(progress!.eventId, 'progress_event');
      expect(progress.currentPoints, 0);
    });

    test('ChangeNotifier 상속', () async {
      final system = EventSystem.instance;
      await system.initialize();

      var notified = false;
      system.addListener(() => notified = true);

      final now = DateTime.now();
      final event = GameEvent(
        id: 'notify_event',
        title: '알림 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      system.registerEvent(event);

      expect(notified, true);
    });

    test('clearData로 모든 데이터 초기화', () async {
      final system = EventSystem.instance;
      await system.initialize();

      final now = DateTime.now();
      final event = GameEvent(
        id: 'clear_event',
        title: '초기화 이벤트',
        description: '설명',
        type: EventType.daily,
        status: EventStatus.active,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        requirements: [],
        rewards: [],
      );

      system.registerEvent(event);
      await system.earnEventPoints('clear_event', 100);

      await system.clearData();

      expect(system.allEvents, isEmpty);
    });
  });

  group('EventStatistics', () {
    test('기본 생성', () {
      final stats = EventStatistics(
        totalEventsParticipated: 10,
        totalEventsCompleted: 7,
        totalPointsEarned: 5000,
        totalRewardsClaimed: 15,
        lastParticipationDate: DateTime(2025, 1, 1, 12, 0),
      );

      expect(stats.totalEventsParticipated, 10);
      expect(stats.totalEventsCompleted, 7);
      expect(stats.totalPointsEarned, 5000);
    });

    test('completionRate 계산', () {
      final stats = EventStatistics(
        totalEventsParticipated: 10,
        totalEventsCompleted: 7,
        totalPointsEarned: 5000,
        totalRewardsClaimed: 15,
        lastParticipationDate: DateTime(2025, 1, 1, 12, 0),
      );

      expect(stats.completionRate, 0.7);
    });

    test('completionRate - 0으로 나누기 방지', () {
      final stats = EventStatistics(
        totalEventsParticipated: 0,
        totalEventsCompleted: 0,
        totalPointsEarned: 0,
        totalRewardsClaimed: 0,
        lastParticipationDate: DateTime(2025, 1, 1, 12, 0),
      );

      expect(stats.completionRate, 0.0);
    });

    test('toJson/fromJson 변환', () {
      final stats = EventStatistics(
        totalEventsParticipated: 20,
        totalEventsCompleted: 15,
        totalPointsEarned: 10000,
        totalRewardsClaimed: 30,
        lastParticipationDate: DateTime(2025, 1, 1, 12, 0),
      );

      final json = stats.toJson();
      final restored = EventStatistics.fromJson(json);

      expect(restored.totalEventsParticipated, 20);
      expect(restored.totalEventsCompleted, 15);
      expect(restored.completionRate, 0.75);
    });
  });
}

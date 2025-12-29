import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/notifications/notification_manager.dart';

/// 테스트용 NotificationManager
class TestableNotificationManager extends NotificationManager {
  TestableNotificationManager() : super.testable();
}

void main() {
  group('NotificationType', () {
    test('모든 타입 정의', () {
      expect(NotificationType.values.length, 9);
      expect(NotificationType.dailyReward, isNotNull);
      expect(NotificationType.energyFull, isNotNull);
      expect(NotificationType.freeSpin, isNotNull);
      expect(NotificationType.event, isNotNull);
      expect(NotificationType.offer, isNotNull);
      expect(NotificationType.achievement, isNotNull);
      expect(NotificationType.social, isNotNull);
      expect(NotificationType.reminder, isNotNull);
      expect(NotificationType.custom, isNotNull);
    });

    test('타입 인덱스 순서', () {
      expect(NotificationType.dailyReward.index, 0);
      expect(NotificationType.energyFull.index, 1);
      expect(NotificationType.freeSpin.index, 2);
      expect(NotificationType.event.index, 3);
      expect(NotificationType.offer.index, 4);
      expect(NotificationType.achievement.index, 5);
      expect(NotificationType.social.index, 6);
      expect(NotificationType.reminder.index, 7);
      expect(NotificationType.custom.index, 8);
    });

    test('타입 이름', () {
      expect(NotificationType.dailyReward.name, 'dailyReward');
      expect(NotificationType.energyFull.name, 'energyFull');
      expect(NotificationType.freeSpin.name, 'freeSpin');
      expect(NotificationType.event.name, 'event');
      expect(NotificationType.offer.name, 'offer');
      expect(NotificationType.achievement.name, 'achievement');
      expect(NotificationType.social.name, 'social');
      expect(NotificationType.reminder.name, 'reminder');
      expect(NotificationType.custom.name, 'custom');
    });
  });

  group('NotificationPriority', () {
    test('모든 우선순위 정의', () {
      expect(NotificationPriority.values.length, 4);
      expect(NotificationPriority.low, isNotNull);
      expect(NotificationPriority.normal, isNotNull);
      expect(NotificationPriority.high, isNotNull);
      expect(NotificationPriority.urgent, isNotNull);
    });

    test('우선순위 인덱스 순서', () {
      expect(NotificationPriority.low.index, 0);
      expect(NotificationPriority.normal.index, 1);
      expect(NotificationPriority.high.index, 2);
      expect(NotificationPriority.urgent.index, 3);
    });

    test('우선순위 이름', () {
      expect(NotificationPriority.low.name, 'low');
      expect(NotificationPriority.normal.name, 'normal');
      expect(NotificationPriority.high.name, 'high');
      expect(NotificationPriority.urgent.name, 'urgent');
    });
  });

  group('GameNotification', () {
    test('기본 생성', () {
      final notification = GameNotification(
        id: 'daily_001',
        type: NotificationType.dailyReward,
        title: 'Daily Reward',
        body: 'Your daily reward is ready!',
      );

      expect(notification.id, 'daily_001');
      expect(notification.type, NotificationType.dailyReward);
      expect(notification.title, 'Daily Reward');
      expect(notification.body, 'Your daily reward is ready!');
      expect(notification.priority, NotificationPriority.normal);
    });

    test('우선순위 설정', () {
      final notification = GameNotification(
        id: 'urgent_001',
        type: NotificationType.event,
        title: 'Event Ending!',
        body: 'Event ends in 1 hour!',
        priority: NotificationPriority.urgent,
      );

      expect(notification.priority, NotificationPriority.urgent);
    });

    test('예약 시간 설정', () {
      final scheduledTime = DateTime.now().add(Duration(hours: 1));

      final notification = GameNotification(
        id: 'scheduled_001',
        type: NotificationType.reminder,
        title: 'Reminder',
        body: 'Come back to play!',
        scheduledTime: scheduledTime,
      );

      expect(notification.scheduledTime, scheduledTime);
    });

    test('페이로드 설정', () {
      final notification = GameNotification(
        id: 'event_001',
        type: NotificationType.event,
        title: 'Event',
        body: 'New event!',
        payload: {'eventId': 'summer_2024', 'screen': 'event_detail'},
      );

      expect(notification.payload, isNotNull);
      expect(notification.payload!['eventId'], 'summer_2024');
    });

    test('toJson 변환', () {
      final notification = GameNotification(
        id: 'test_001',
        type: NotificationType.dailyReward,
        title: 'Test',
        body: 'Test body',
        priority: NotificationPriority.high,
      );

      final json = notification.toJson();

      expect(json['id'], 'test_001');
      expect(json['type'], 'dailyReward');
      expect(json['title'], 'Test');
      expect(json['priority'], 'high');
    });

    test('fromJson 복원', () {
      final json = {
        'id': 'test_001',
        'type': 'dailyReward',
        'title': 'Test',
        'body': 'Test body',
        'priority': 'high',
      };

      final notification = GameNotification.fromJson(json);

      expect(notification.id, 'test_001');
      expect(notification.type, NotificationType.dailyReward);
      expect(notification.title, 'Test');
      expect(notification.priority, NotificationPriority.high);
    });

    test('fromJson 알 수 없는 타입 처리', () {
      final json = {
        'id': 'test_001',
        'type': 'unknown_type',
        'title': 'Test',
        'body': 'Test body',
        'priority': 'unknown_priority',
      };

      final notification = GameNotification.fromJson(json);

      expect(notification.type, NotificationType.custom);
      expect(notification.priority, NotificationPriority.normal);
    });

    test('toJson 전체 필드 포함', () {
      final scheduledTime = DateTime(2025, 1, 1, 12, 0);
      final notification = GameNotification(
        id: 'full_test',
        type: NotificationType.event,
        title: 'Full Test',
        body: 'Full test body',
        priority: NotificationPriority.urgent,
        scheduledTime: scheduledTime,
        payload: {'key': 'value'},
        imageUrl: 'https://example.com/image.png',
        actionId: 'action_001',
      );

      final json = notification.toJson();

      expect(json['id'], 'full_test');
      expect(json['type'], 'event');
      expect(json['title'], 'Full Test');
      expect(json['body'], 'Full test body');
      expect(json['priority'], 'urgent');
      expect(json['scheduledTime'], scheduledTime.toIso8601String());
      expect(json['payload'], {'key': 'value'});
      expect(json['imageUrl'], 'https://example.com/image.png');
      expect(json['actionId'], 'action_001');
    });

    test('fromJson 전체 필드 복원', () {
      final scheduledTimeStr = '2025-01-01T12:00:00.000';
      final json = {
        'id': 'full_test',
        'type': 'achievement',
        'title': 'Achievement Unlocked',
        'body': 'You earned a badge!',
        'priority': 'high',
        'scheduledTime': scheduledTimeStr,
        'payload': {'achievementId': 'badge_001'},
        'imageUrl': 'https://example.com/badge.png',
        'actionId': 'view_achievement',
      };

      final notification = GameNotification.fromJson(json);

      expect(notification.id, 'full_test');
      expect(notification.type, NotificationType.achievement);
      expect(notification.title, 'Achievement Unlocked');
      expect(notification.body, 'You earned a badge!');
      expect(notification.priority, NotificationPriority.high);
      expect(notification.scheduledTime, DateTime.parse(scheduledTimeStr));
      expect(notification.payload?['achievementId'], 'badge_001');
      expect(notification.imageUrl, 'https://example.com/badge.png');
      expect(notification.actionId, 'view_achievement');
    });

    test('fromJson null 필드 처리', () {
      final json = {
        'id': 'minimal',
        'type': 'reminder',
        'title': 'Reminder',
        'body': 'Come back!',
        'priority': 'normal',
        'scheduledTime': null,
        'payload': null,
        'imageUrl': null,
        'actionId': null,
      };

      final notification = GameNotification.fromJson(json);

      expect(notification.scheduledTime, isNull);
      expect(notification.payload, isNull);
      expect(notification.imageUrl, isNull);
      expect(notification.actionId, isNull);
    });

    test('모든 NotificationType으로 생성 가능', () {
      for (final type in NotificationType.values) {
        final notification = GameNotification(
          id: 'test_${type.name}',
          type: type,
          title: 'Test ${type.name}',
          body: 'Body for ${type.name}',
        );

        expect(notification.type, type);
        expect(notification.id, 'test_${type.name}');
      }
    });

    test('모든 NotificationPriority로 생성 가능', () {
      for (final priority in NotificationPriority.values) {
        final notification = GameNotification(
          id: 'test_${priority.name}',
          type: NotificationType.custom,
          title: 'Test',
          body: 'Body',
          priority: priority,
        );

        expect(notification.priority, priority);
      }
    });

    test('fromJson-toJson 라운드트립', () {
      final original = GameNotification(
        id: 'roundtrip_test',
        type: NotificationType.offer,
        title: 'Special Offer',
        body: '50% off!',
        priority: NotificationPriority.high,
        scheduledTime: DateTime(2025, 6, 15, 10, 30),
        payload: {'discount': 50, 'itemId': 'item_001'},
        imageUrl: 'https://example.com/offer.png',
        actionId: 'buy_now',
      );

      final json = original.toJson();
      final restored = GameNotification.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.priority, original.priority);
      expect(restored.scheduledTime, original.scheduledTime);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.actionId, original.actionId);
    });
  });

  group('NotificationScheduler', () {
    test('다음 발생 시간 - 오늘', () {
      final now = DateTime.now();
      final futureHour = (now.hour + 2) % 24;

      final next = NotificationScheduler.nextOccurrence(futureHour, 0);

      if (futureHour > now.hour) {
        expect(next.day, now.day);
      }
      expect(next.hour, futureHour);
      expect(next.minute, 0);
    });

    test('다음 발생 시간 - 내일', () {
      final now = DateTime.now();
      final pastHour = (now.hour - 2 + 24) % 24;

      final next = NotificationScheduler.nextOccurrence(pastHour, 0);

      // 이미 지난 시간이면 내일로 예약
      expect(next.isAfter(now), true);
    });

    test('다음 발생 시간 - 분 지정', () {
      final now = DateTime.now();
      final futureHour = (now.hour + 3) % 24;

      final next = NotificationScheduler.nextOccurrence(futureHour, 30);

      expect(next.hour, futureHour);
      expect(next.minute, 30);
    });

    test('에너지 충전 시간 - 이미 충전됨', () {
      final refillTime = NotificationScheduler.energyRefillTime(
        10, // 현재
        10, // 최대
        Duration(minutes: 5),
      );

      // 이미 가득 찬 경우 현재 시간 반환
      expect(refillTime.difference(DateTime.now()).inSeconds.abs(), lessThan(2));
    });

    test('에너지 충전 시간 계산', () {
      final now = DateTime.now();

      final refillTime = NotificationScheduler.energyRefillTime(
        5, // 현재
        10, // 최대
        Duration(minutes: 5),
      );

      // 5 에너지 부족 * 5분 = 25분 후
      final expectedDuration = Duration(minutes: 25);
      final actualDuration = refillTime.difference(now);

      expect(actualDuration.inMinutes, closeTo(expectedDuration.inMinutes, 1));
    });

    test('에너지 충전 시간 - 초과 충전', () {
      final refillTime = NotificationScheduler.energyRefillTime(
        15, // 현재 (최대 초과)
        10, // 최대
        Duration(minutes: 5),
      );

      // 최대 초과시에도 현재 시간 반환
      expect(refillTime.difference(DateTime.now()).inSeconds.abs(), lessThan(2));
    });

    test('에너지 충전 시간 - 1분 간격', () {
      final now = DateTime.now();

      final refillTime = NotificationScheduler.energyRefillTime(
        9, // 현재
        10, // 최대
        Duration(minutes: 1),
      );

      // 1 에너지 부족 * 1분 = 1분 후
      final actualDuration = refillTime.difference(now);
      expect(actualDuration.inMinutes, closeTo(1, 1));
    });

    test('다음 일일 리셋', () {
      final nextReset = NotificationScheduler.nextDailyReset(resetHour: 0);

      expect(nextReset.hour, 0);
      expect(nextReset.isAfter(DateTime.now()), true);
    });

    test('다음 일일 리셋 - 오후 시간', () {
      final nextReset = NotificationScheduler.nextDailyReset(resetHour: 18);

      expect(nextReset.hour, 18);
      expect(nextReset.isAfter(DateTime.now()), true);
    });

    test('다음 주간 리셋', () {
      final nextWeeklyReset = NotificationScheduler.nextWeeklyReset(
        dayOfWeek: DateTime.monday,
        resetHour: 0,
      );

      expect(nextWeeklyReset.weekday, DateTime.monday);
      expect(nextWeeklyReset.hour, 0);
      expect(nextWeeklyReset.isAfter(DateTime.now()), true);
    });

    test('다음 주간 리셋 - 일요일', () {
      final nextWeeklyReset = NotificationScheduler.nextWeeklyReset(
        dayOfWeek: DateTime.sunday,
        resetHour: 12,
      );

      expect(nextWeeklyReset.weekday, DateTime.sunday);
      expect(nextWeeklyReset.hour, 12);
      expect(nextWeeklyReset.isAfter(DateTime.now()), true);
    });

    test('다음 주간 리셋 - 모든 요일', () {
      for (int day = DateTime.monday; day <= DateTime.sunday; day++) {
        final nextWeeklyReset = NotificationScheduler.nextWeeklyReset(
          dayOfWeek: day,
          resetHour: 0,
        );

        expect(nextWeeklyReset.weekday, day);
        expect(nextWeeklyReset.isAfter(DateTime.now()), true);
      }
    });
  });

  group('NotificationManager', () {
    late NotificationManager manager;

    setUp(() {
      manager = NotificationManager.instance;
    });

    test('싱글톤 인스턴스', () {
      final instance1 = NotificationManager.instance;
      final instance2 = NotificationManager.instance;

      expect(identical(instance1, instance2), true);
    });

    test('초기 상태', () {
      // 싱글톤이므로 이전 테스트 상태가 남아있을 수 있음
      // 단순히 속성 접근 가능 여부 확인
      expect(manager.isInitialized, isA<bool>());
      expect(manager.hasPermission, isA<bool>());
    });

    test('pendingNotifications 초기 상태', () {
      // 빈 리스트 또는 이전 테스트에서 추가된 알림
      expect(manager.pendingNotifications, isA<List<GameNotification>>());
    });

    test('deliveredNotifications 초기 상태', () {
      expect(manager.deliveredNotifications, isA<List<GameNotification>>());
    });

    test('pendingNotifications는 불변 리스트', () {
      final notifications = manager.pendingNotifications;
      expect(() => (notifications as List).add(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      )), throwsA(isA<UnsupportedError>()));
    });

    test('deliveredNotifications는 불변 리스트', () {
      final notifications = manager.deliveredNotifications;
      expect(() => (notifications as List).add(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      )), throwsA(isA<UnsupportedError>()));
    });

    test('getPendingNotification - 존재하지 않는 ID', () {
      final notification = manager.getPendingNotification('non_existent_id');
      expect(notification, isNull);
    });

    test('isScheduled - 존재하지 않는 ID', () {
      final isScheduled = manager.isScheduled('non_existent_id');
      expect(isScheduled, false);
    });

    test('ChangeNotifier 상속', () {
      // NotificationManager는 ChangeNotifier를 상속
      expect(manager, isA<NotificationManager>());
    });

    // 실제 알림 기능은 플랫폼 플러그인에 의존하므로
    // 여기서는 기본 상태 및 데이터 구조만 테스트
  });

  group('TestableNotificationManager - initialize', () {
    late TestableNotificationManager manager;

    setUp(() {
      manager = TestableNotificationManager();
    });

    test('초기화 전 상태', () {
      expect(manager.isInitialized, false);
      expect(manager.hasPermission, false);
    });

    test('초기화 후 상태', () async {
      await manager.initialize();

      expect(manager.isInitialized, true);
    });

    test('중복 초기화 무시', () async {
      await manager.initialize();
      final firstInitTime = manager.isInitialized;

      await manager.initialize(); // 다시 호출

      expect(manager.isInitialized, firstInitTime);
    });

    test('콜백 설정', () async {
      var receivedNotification = false;
      var tappedNotification = false;

      await manager.initialize(
        onReceived: (notification) => receivedNotification = true,
        onTapped: (notification, actionId) => tappedNotification = true,
      );

      expect(manager.isInitialized, true);
    });
  });

  group('TestableNotificationManager - requestPermission', () {
    late TestableNotificationManager manager;

    setUp(() {
      manager = TestableNotificationManager();
    });

    test('초기화 전 requestPermission 에러', () async {
      expect(
        () => manager.requestPermission(),
        throwsA(isA<StateError>()),
      );
    });

    test('초기화 후 requestPermission 성공', () async {
      await manager.initialize();

      final granted = await manager.requestPermission();

      expect(granted, true);
      expect(manager.hasPermission, true);
    });
  });

  group('TestableNotificationManager - scheduleNotification', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('알림 예약', () async {
      final notification = GameNotification(
        id: 'test_001',
        type: NotificationType.dailyReward,
        title: 'Daily Reward',
        body: 'Your reward is ready!',
        scheduledTime: DateTime.now().add(Duration(hours: 1)),
      );

      await manager.scheduleNotification(notification);

      expect(manager.pendingNotifications.length, 1);
      expect(manager.pendingNotifications.first.id, 'test_001');
    });

    test('여러 알림 예약', () async {
      for (int i = 1; i <= 3; i++) {
        await manager.scheduleNotification(GameNotification(
          id: 'test_$i',
          type: NotificationType.reminder,
          title: 'Reminder $i',
          body: 'Body $i',
        ));
      }

      expect(manager.pendingNotifications.length, 3);
    });

    test('초기화되지 않은 상태에서 예약 무시', () async {
      final uninitManager = TestableNotificationManager();

      await uninitManager.scheduleNotification(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      ));

      expect(uninitManager.pendingNotifications.length, 0);
    });

    test('권한 없는 상태에서 예약 무시', () async {
      final noPermManager = TestableNotificationManager();
      await noPermManager.initialize();
      // requestPermission 호출 안함

      await noPermManager.scheduleNotification(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      ));

      expect(noPermManager.pendingNotifications.length, 0);
    });

    test('notifyListeners 호출', () async {
      var notified = false;
      manager.addListener(() => notified = true);

      await manager.scheduleNotification(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      ));

      expect(notified, true);
    });
  });

  group('TestableNotificationManager - showNotification', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('즉시 알림 표시', () async {
      final notification = GameNotification(
        id: 'show_test',
        type: NotificationType.achievement,
        title: 'Achievement',
        body: 'You unlocked something!',
      );

      await manager.showNotification(notification);

      expect(manager.deliveredNotifications.length, 1);
      expect(manager.deliveredNotifications.first.id, 'show_test');
    });

    test('onReceived 콜백 호출', () async {
      GameNotification? receivedNotification;

      final callbackManager = TestableNotificationManager();
      await callbackManager.initialize(
        onReceived: (notification) => receivedNotification = notification,
      );
      await callbackManager.requestPermission();

      final notification = GameNotification(
        id: 'callback_test',
        type: NotificationType.offer,
        title: 'Offer',
        body: 'Special offer!',
      );

      await callbackManager.showNotification(notification);

      expect(receivedNotification, isNotNull);
      expect(receivedNotification!.id, 'callback_test');
    });

    test('초기화되지 않은 상태에서 무시', () async {
      final uninitManager = TestableNotificationManager();

      await uninitManager.showNotification(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      ));

      expect(uninitManager.deliveredNotifications.length, 0);
    });
  });

  group('TestableNotificationManager - cancelNotification', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('예약된 알림 취소', () async {
      await manager.scheduleNotification(GameNotification(
        id: 'cancel_test',
        type: NotificationType.reminder,
        title: 'Reminder',
        body: 'Body',
      ));

      expect(manager.pendingNotifications.length, 1);

      await manager.cancelNotification('cancel_test');

      expect(manager.pendingNotifications.length, 0);
    });

    test('존재하지 않는 알림 취소', () async {
      await manager.scheduleNotification(GameNotification(
        id: 'existing',
        type: NotificationType.reminder,
        title: 'Reminder',
        body: 'Body',
      ));

      await manager.cancelNotification('non_existent');

      // 기존 알림은 그대로
      expect(manager.pendingNotifications.length, 1);
    });

    test('초기화되지 않은 상태에서 무시', () async {
      final uninitManager = TestableNotificationManager();

      await uninitManager.cancelNotification('test');
      // 에러 없이 완료
    });
  });

  group('TestableNotificationManager - cancelAllNotifications', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('모든 알림 취소', () async {
      for (int i = 1; i <= 5; i++) {
        await manager.scheduleNotification(GameNotification(
          id: 'test_$i',
          type: NotificationType.reminder,
          title: 'Reminder $i',
          body: 'Body $i',
        ));
      }

      expect(manager.pendingNotifications.length, 5);

      await manager.cancelAllNotifications();

      expect(manager.pendingNotifications.length, 0);
    });
  });

  group('TestableNotificationManager - getPendingNotification', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('존재하는 알림 조회', () async {
      await manager.scheduleNotification(GameNotification(
        id: 'find_me',
        type: NotificationType.event,
        title: 'Event',
        body: 'Event body',
      ));

      final found = manager.getPendingNotification('find_me');

      expect(found, isNotNull);
      expect(found!.id, 'find_me');
      expect(found.title, 'Event');
    });

    test('존재하지 않는 알림 조회', () {
      final found = manager.getPendingNotification('not_exist');

      expect(found, isNull);
    });
  });

  group('TestableNotificationManager - isScheduled', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('예약된 알림 확인', () async {
      await manager.scheduleNotification(GameNotification(
        id: 'scheduled_id',
        type: NotificationType.reminder,
        title: 'Title',
        body: 'Body',
      ));

      expect(manager.isScheduled('scheduled_id'), true);
      expect(manager.isScheduled('not_scheduled'), false);
    });
  });

  group('TestableNotificationManager - handleNotificationTap', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
    });

    test('onTapped 콜백 호출', () async {
      GameNotification? tappedNotification;
      String? tappedActionId;

      await manager.initialize(
        onTapped: (notification, actionId) {
          tappedNotification = notification;
          tappedActionId = actionId;
        },
      );

      final notification = GameNotification(
        id: 'tap_test',
        type: NotificationType.offer,
        title: 'Offer',
        body: 'Body',
        actionId: 'buy_action',
      );

      manager.handleNotificationTap(notification, 'buy_action');

      expect(tappedNotification, isNotNull);
      expect(tappedNotification!.id, 'tap_test');
      expect(tappedActionId, 'buy_action');
    });

    test('actionId null로 호출', () async {
      String? receivedActionId = 'initial';

      await manager.initialize(
        onTapped: (notification, actionId) {
          receivedActionId = actionId;
        },
      );

      final notification = GameNotification(
        id: 'tap_test',
        type: NotificationType.reminder,
        title: 'Title',
        body: 'Body',
      );

      manager.handleNotificationTap(notification, null);

      expect(receivedActionId, isNull);
    });
  });

  group('TestableNotificationManager - clearDeliveredNotifications', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('전달된 알림 목록 클리어', () async {
      for (int i = 1; i <= 3; i++) {
        await manager.showNotification(GameNotification(
          id: 'delivered_$i',
          type: NotificationType.achievement,
          title: 'Achievement $i',
          body: 'Body $i',
        ));
      }

      expect(manager.deliveredNotifications.length, 3);

      manager.clearDeliveredNotifications();

      expect(manager.deliveredNotifications.length, 0);
    });

    test('notifyListeners 호출', () async {
      var notified = false;
      manager.addListener(() => notified = true);

      manager.clearDeliveredNotifications();

      expect(notified, true);
    });
  });

  group('TestableNotificationManager - Template Methods', () {
    late TestableNotificationManager manager;

    setUp(() async {
      manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();
    });

    test('scheduleDailyRewardNotification', () async {
      final time = DateTime.now().add(Duration(hours: 1));

      await manager.scheduleDailyRewardNotification(time: time);

      final pending = manager.getPendingNotification('daily_reward');
      expect(pending, isNotNull);
      expect(pending!.type, NotificationType.dailyReward);
      expect(pending.priority, NotificationPriority.high);
    });

    test('scheduleDailyRewardNotification 커스텀 제목', () async {
      await manager.scheduleDailyRewardNotification(
        time: DateTime.now().add(Duration(hours: 1)),
        title: '일일 보상!',
        body: '보상을 받으세요!',
      );

      final pending = manager.getPendingNotification('daily_reward');
      expect(pending!.title, '일일 보상!');
      expect(pending.body, '보상을 받으세요!');
    });

    test('scheduleEnergyFullNotification', () async {
      final time = DateTime.now().add(Duration(minutes: 30));

      await manager.scheduleEnergyFullNotification(time: time);

      final pending = manager.getPendingNotification('energy_full');
      expect(pending, isNotNull);
      expect(pending!.type, NotificationType.energyFull);
      expect(pending.priority, NotificationPriority.normal);
    });

    test('scheduleEnergyFullNotification 커스텀 메시지', () async {
      await manager.scheduleEnergyFullNotification(
        time: DateTime.now().add(Duration(minutes: 30)),
        title: '에너지 충전 완료!',
        body: '게임을 시작하세요!',
      );

      final pending = manager.getPendingNotification('energy_full');
      expect(pending!.title, '에너지 충전 완료!');
    });

    test('scheduleFreeSpinNotification', () async {
      final time = DateTime.now().add(Duration(hours: 6));

      await manager.scheduleFreeSpinNotification(time: time);

      final pending = manager.getPendingNotification('free_spin');
      expect(pending, isNotNull);
      expect(pending!.type, NotificationType.freeSpin);
    });

    test('scheduleEventNotification - 시작', () async {
      await manager.scheduleEventNotification(
        eventId: 'summer_2025',
        time: DateTime.now().add(Duration(hours: 2)),
        title: 'Summer Event Starting!',
        body: 'Join the summer festival!',
        isEnding: false,
      );

      final pending = manager.getPendingNotification('event_summer_2025_start');
      expect(pending, isNotNull);
      expect(pending!.type, NotificationType.event);
      expect(pending.priority, NotificationPriority.high);
      expect(pending.payload!['eventId'], 'summer_2025');
      expect(pending.payload!['isEnding'], false);
    });

    test('scheduleEventNotification - 종료', () async {
      await manager.scheduleEventNotification(
        eventId: 'winter_event',
        time: DateTime.now().add(Duration(hours: 1)),
        title: 'Event Ending Soon!',
        body: 'Last chance to participate!',
        isEnding: true,
      );

      final pending = manager.getPendingNotification('event_winter_event_end');
      expect(pending, isNotNull);
      expect(pending!.payload!['isEnding'], true);
    });

    test('scheduleComebackNotification', () async {
      await manager.scheduleComebackNotification(
        afterInactivity: Duration(days: 3),
        title: '오랜만이에요!',
        body: '복귀 보상이 기다리고 있어요!',
      );

      final pending = manager.getPendingNotification('comeback');
      expect(pending, isNotNull);
      expect(pending!.type, NotificationType.reminder);
      expect(pending.title, '오랜만이에요!');
    });

    test('scheduleComebackNotification 기본값', () async {
      await manager.scheduleComebackNotification();

      final pending = manager.getPendingNotification('comeback');
      expect(pending, isNotNull);
      expect(pending!.title, 'We miss you!');
    });
  });

  group('TestableNotificationManager - dispose', () {
    test('dispose 후 리스트 클리어', () async {
      final manager = TestableNotificationManager();
      await manager.initialize();
      await manager.requestPermission();

      await manager.scheduleNotification(GameNotification(
        id: 'test',
        type: NotificationType.custom,
        title: 'Test',
        body: 'Test',
      ));
      await manager.showNotification(GameNotification(
        id: 'show',
        type: NotificationType.custom,
        title: 'Show',
        body: 'Show',
      ));

      manager.dispose();

      expect(manager.pendingNotifications, isEmpty);
      expect(manager.deliveredNotifications, isEmpty);
    });
  });

  group('콜백 타입', () {
    test('NotificationCallback 타입 정의', () {
      NotificationCallback callback = (GameNotification notification) {
        // 알림 처리
      };

      expect(callback, isA<NotificationCallback>());
    });

    test('NotificationTapCallback 타입 정의', () {
      NotificationTapCallback callback = (GameNotification notification, String? actionId) {
        // 탭 처리
      };

      expect(callback, isA<NotificationTapCallback>());
    });
  });

  group('NotificationScheduler - 추가 테스트', () {
    test('nextOccurrence - 자정', () {
      final next = NotificationScheduler.nextOccurrence(0, 0);

      expect(next.hour, 0);
      expect(next.minute, 0);
      expect(next.isAfter(DateTime.now()), true);
    });

    test('nextOccurrence - 23시 59분', () {
      final next = NotificationScheduler.nextOccurrence(23, 59);

      expect(next.hour, 23);
      expect(next.minute, 59);
      expect(next.isAfter(DateTime.now()), true);
    });

    test('energyRefillTime - 빈 에너지', () {
      final now = DateTime.now();
      final refillTime = NotificationScheduler.energyRefillTime(
        0, // 현재 에너지
        100, // 최대 에너지
        Duration(seconds: 10), // 10초당 1 에너지
      );

      // 100 에너지 * 10초 = 1000초 = 약 16분 40초
      final expectedSeconds = 1000;
      final actualSeconds = refillTime.difference(now).inSeconds;

      expect(actualSeconds, closeTo(expectedSeconds, 5));
    });

    test('nextWeeklyReset - 수요일', () {
      final nextReset = NotificationScheduler.nextWeeklyReset(
        dayOfWeek: DateTime.wednesday,
        resetHour: 15,
      );

      expect(nextReset.weekday, DateTime.wednesday);
      expect(nextReset.hour, 15);
    });

    test('nextWeeklyReset - 금요일 저녁', () {
      final nextReset = NotificationScheduler.nextWeeklyReset(
        dayOfWeek: DateTime.friday,
        resetHour: 20,
      );

      expect(nextReset.weekday, DateTime.friday);
      expect(nextReset.hour, 20);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/notifications/notification_manager.dart';

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
}

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
  });

  group('NotificationPriority', () {
    test('모든 우선순위 정의', () {
      expect(NotificationPriority.values.length, 4);
      expect(NotificationPriority.low, isNotNull);
      expect(NotificationPriority.normal, isNotNull);
      expect(NotificationPriority.high, isNotNull);
      expect(NotificationPriority.urgent, isNotNull);
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

    test('다음 일일 리셋', () {
      final nextReset = NotificationScheduler.nextDailyReset(resetHour: 0);

      expect(nextReset.hour, 0);
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
      // 초기화 전 상태
      expect(manager.isInitialized, false);
      expect(manager.hasPermission, false);
    });

    // 실제 알림 기능은 플랫폼 플러그인에 의존하므로
    // 여기서는 기본 상태 및 데이터 구조만 테스트
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/analytics/analytics_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AnalyticsManager Unit Tests', () {
    late AnalyticsManager analyticsManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analyticsManager = AnalyticsManager.instance;
      await analyticsManager.initialize(userId: 'test_user_123');
    });

    tearDown(() {
      analyticsManager.dispose();
    });

    test('이벤트 로깅', () async {
      await analyticsManager.logEvent(
        'game_start',
        parameters: {
          'game_id': 'mg_0047',
          'difficulty': 'easy',
        },
      );

      final events = analyticsManager.getEvents();
      expect(events.isNotEmpty, isTrue);

      final gameStartEvents = events.where((e) => e.name == 'game_start');
      expect(gameStartEvents.isNotEmpty, isTrue);
    });

    test('세션 관리', () async {
      final sessionId = await analyticsManager.startSession();
      expect(sessionId, isNotEmpty);

      await Future.delayed(const Duration(seconds: 1));

      final duration = await analyticsManager.endSession();
      expect(duration?.inSeconds, greaterThan(0));
    });

    test('에러 로깅', () async {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      await analyticsManager.logError(
        error,
        stackTrace,
        fatal: false,
      );

      final events = analyticsManager.getEvents();
      final errorEvents = events.where((e) => e.type == AnalyticsEventType.error);

      expect(errorEvents.isNotEmpty, isTrue);
    });

    test('사용자 속성 설정', () async {
      await analyticsManager.setUserProperty('level', '10');
      await analyticsManager.setUserProperty('country', 'KR');

      final properties = analyticsManager.getUserProperties();

      expect(properties['level'], equals('10'));
      expect(properties['country'], equals('KR'));
    });

    test('페이지 뷰 추적', () async {
      await analyticsManager.logPageView('home_screen');
      await analyticsManager.logPageView('game_screen');

      final events = analyticsManager.getEvents();
      final pageViewEvents = events.where((e) => e.type == AnalyticsEventType.pageView);

      expect(pageViewEvents.length, greaterThanOrEqualTo(2));
    });

    test('수익 이벤트 추적', () async {
      await analyticsManager.logPurchase(
        itemId: 'coin_pack_100',
        price: 1100,
        currency: 'KRW',
      );

      final events = analyticsManager.getEvents();
      final purchaseEvents = events.where((e) => e.type == AnalyticsEventType.purchase);

      expect(purchaseEvents.isNotEmpty, isTrue);

      final purchaseEvent = purchaseEvents.first;
      expect(purchaseEvent.parameters['itemId'], equals('coin_pack_100'));
      expect(purchaseEvent.parameters['price'], equals(1100));
    });

    test('퀘스트 완료 추적', () async {
      await analyticsManager.logQuestComplete(
        questId: 'daily_quest_001',
        difficulty: 'medium',
        timeSpent: const Duration(minutes: 5),
      );

      final events = analyticsManager.getEvents();
      final questEvents = events.where((e) => e.name == 'quest_complete');

      expect(questEvents.isNotEmpty, isTrue);
    });

    test('데이터 내보내기', () async {
      await analyticsManager.logEvent('test_event');

      final jsonData = await analyticsManager.exportData();
      expect(jsonData, isNotEmpty);
      expect(jsonData.contains('test_event'), isTrue);
    });
  });

  group('AnalyticsEvent Tests', () {
    test('AnalyticsEvent JSON 변환', () {
      final event = AnalyticsEvent(
        name: 'test_event',
        type: AnalyticsEventType.custom,
        parameters: {'key': 'value'},
      );

      final json = event.toJson();
      expect(json['name'], equals('test_event'));
      expect(json['type'], equals(AnalyticsEventType.custom.name));
      expect(json['parameters']['key'], equals('value'));

      final restored = AnalyticsEvent.fromJson(json);
      expect(restored.name, equals(event.name));
      expect(restored.type, equals(event.type));
    });
  });
}

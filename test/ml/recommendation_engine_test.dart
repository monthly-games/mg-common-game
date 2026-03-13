import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ml/recommendation_engine.dart';

void main() {
  group('RecommendationEngine', () {
    late RecommendationEngine engine;

    setUp(() {
      engine = RecommendationEngine.instance;
      engine.clear();
    });

    test('아이템 등록 및 조회', () async {
      final item = RecommendableItem(
        id: 'game_001',
        type: 'game',
        name: '테스트 게임',
        features: {'action': 1.0, 'rpg': 0.8},
        tags: ['액션', 'RPG'],
        popularityScore: 100,
        averageRating: 4.5,
        ratingCount: 50,
      );

      await engine.registerItem(item);

      final retrieved = engine.getItem('game_001');
      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'game_001');
      expect(retrieved?.name, '테스트 게임');
    });

    test('사용자 프로필 업데이트', () async {
      await engine.updateUserProfile(
        userId: 'user_001',
        preferences: {'action': 1.0},
        behaviorHistory: [
          UserBehavior(
            itemId: 'game_001',
            action: BehaviorAction.play,
            timestamp: DateTime.now(),
            duration: const Duration(minutes: 30),
          ),
        ],
      );

      final profile = engine.getUserProfile('user_001');
      expect(profile, isNotNull);
      expect(profile?.preferences['action'], 1.0);
      expect(profile?.behaviorHistory.length, 1);
    });

    test('콘텐츠 기반 추천', () async {
      // 테스트 아이템 등록
      final items = [
        RecommendableItem(
          id: 'game_001',
          type: 'game',
          name: '액션 게임',
          features: {'action': 1.0, 'rpg': 0.2},
          tags: ['액션'],
          popularityScore: 100,
          averageRating: 4.5,
          ratingCount: 50,
        ),
        RecommendableItem(
          id: 'game_002',
          type: 'game',
          name: 'RPG 게임',
          features: {'action': 0.3, 'rpg': 1.0},
          tags: ['RPG'],
          popularityScore: 80,
          averageRating: 4.2,
          ratingCount: 40,
        ),
      ];

      for (final item in items) {
        await engine.registerItem(item);
      }

      // 사용자 프로필 생성
      await engine.updateUserProfile(
        userId: 'user_001',
        preferences: {'action': 1.0, 'rpg': 0.3},
        behaviorHistory: [],
      );

      final recommendations = await engine.recommendByContent(
        userId: 'user_001',
        itemType: 'game',
        limit: 2,
      );

      expect(recommendations.length, greaterThan(0));
      expect(recommendations.first.itemId, 'game_001');
    });

    test('협업 필터링 추천', () async {
      // 유사한 사용자들 생성
      for (int i = 1; i <= 5; i++) {
        await engine.updateUserProfile(
          userId: 'user_$i',
          preferences: {'action': 1.0},
          behaviorHistory: [
            UserBehavior(
              itemId: 'game_001',
              action: BehaviorAction.play,
              timestamp: DateTime.now(),
              duration: const Duration(minutes: 30),
            ),
          ],
        );

        await engine.recordRating(
          userId: 'user_$i',
          itemId: 'game_001',
          rating: 5.0,
        );
      }

      // 타겟 사용자
      await engine.updateUserProfile(
        userId: 'user_target',
        preferences: {'action': 0.9},
        behaviorHistory: [],
      );

      await engine.recordRating(
        userId: 'user_target',
        itemId: 'game_001',
        rating: 4.5,
      );

      final recommendations = await engine.recommendByCollaborative(
        userId: 'user_target',
        limit: 5,
      );

      expect(recommendations, isNotNull);
    });

    test('하이브리드 추천', () async {
      // 아이템 등록
      await engine.registerItem(
        RecommendableItem(
          id: 'game_001',
          type: 'game',
          name: '인기 액션 게임',
          features: {'action': 1.0},
          tags: ['액션'],
          popularityScore: 100,
          averageRating: 4.5,
          ratingCount: 50,
        ),
      );

      // 사용자 생성
      await engine.updateUserProfile(
        userId: 'user_001',
        preferences: {'action': 1.0},
        behaviorHistory: [],
      );

      final recommendations = await engine.recommendHybrid(
        userId: 'user_001',
        limit: 10,
        contentWeight: 0.5,
        collaborativeWeight: 0.3,
        popularityWeight: 0.2,
      );

      expect(recommendations, isNotNull);
    });

    test('평점 기록 및 조회', () async {
      await engine.recordRating(
        userId: 'user_001',
        itemId: 'game_001',
        rating: 4.5,
      );

      final ratings = engine.getUserRatings('user_001');
      expect(ratings['game_001'], 4.5);
    });

    test('AB 테스트 그룹 할당', () {
      const userId = 'user_001';
      const testName = 'recommendation_algorithm';

      final group1 = engine.getABTestGroup(userId, testName);
      final group2 = engine.getABTestGroup(userId, testName);

      expect(group1, group2); // 동일한 사용자는 동일한 그룹
      expect(['A', 'B'].contains(group1), true);
    });

    test('실시간 추천 업데이트', () async {
      await engine.registerItem(
        RecommendableItem(
          id: 'game_001',
          type: 'game',
          name: '실시간 게임',
          features: {'action': 1.0},
          tags: ['액션'],
          popularityScore: 100,
          averageRating: 4.5,
          ratingCount: 50,
        ),
      );

      await engine.updateUserProfile(
        userId: 'user_001',
        preferences: {'action': 1.0},
        behaviorHistory: [],
      );

      bool callbackCalled = false;
      engine.onRealtimeUpdate.listen((_) {
        callbackCalled = true;
      });

      await engine.recordRating(
        userId: 'user_001',
        itemId: 'game_001',
        rating: 5.0,
      );

      expect(callbackCalled, true);
    });
  });
}

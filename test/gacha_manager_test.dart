import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';

void main() {
  group('GachaPool', () {
    test('등급별 기본 확률', () {
      expect(GachaRarity.normal.baseRate, 50.0);
      expect(GachaRarity.rare.baseRate, 35.0);
      expect(GachaRarity.superRare.baseRate, 12.0);
      expect(GachaRarity.ultraRare.baseRate, 2.7);
      expect(GachaRarity.legendary.baseRate, 0.3);
    });

    test('풀 활성화 여부', () {
      final activePool = GachaPool(
        id: 'active',
        nameKr: '활성 풀',
        items: [],
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(activePool.isCurrentlyActive, isTrue);

      final inactivePool = GachaPool(
        id: 'inactive',
        nameKr: '비활성 풀',
        items: [],
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(inactivePool.isCurrentlyActive, isFalse);
    });
  });

  group('PityConfig', () {
    test('소프트 천장 확률 증가', () {
      const config = PityConfig(
        softPityStart: 70,
        hardPity: 80,
        softPityBonus: 6.0,
      );

      // 70회 미만: 기본 확률
      expect(config.calculateAdjustedRate(50, 2.7), 2.7);

      // 70회: 기본 + 6%
      expect(config.calculateAdjustedRate(70, 2.7), 8.7);

      // 75회: 기본 + 36%
      expect(config.calculateAdjustedRate(75, 2.7), 38.7);

      // 80회: 100% (하드 천장)
      expect(config.calculateAdjustedRate(80, 2.7), 100.0);
    });
  });

  group('GachaManager', () {
    late GachaManager manager;
    late GachaPool testPool;

    setUp(() {
      manager = GachaManager();

      testPool = GachaPool(
        id: 'test_pool',
        nameKr: '테스트 풀',
        items: [
          const GachaItem(id: 'n1', nameKr: 'N 캐릭터', rarity: GachaRarity.normal),
          const GachaItem(id: 'r1', nameKr: 'R 캐릭터', rarity: GachaRarity.rare),
          const GachaItem(id: 'sr1', nameKr: 'SR 캐릭터', rarity: GachaRarity.superRare),
          const GachaItem(id: 'ssr1', nameKr: 'SSR 캐릭터', rarity: GachaRarity.ultraRare),
          const GachaItem(id: 'ssr_pickup', nameKr: 'SSR 픽업', rarity: GachaRarity.ultraRare, isPickup: true),
        ],
        pickupItemIds: ['ssr_pickup'],
      );

      manager.registerPool(testPool);
    });

    test('풀 등록', () {
      expect(manager.pools.length, 1);
      expect(manager.activePools.length, 1);
    });

    test('단일 뽑기', () {
      final result = manager.pull('test_pool');

      expect(result, isNotNull);
      expect(result!.pullNumber, 1);
    });

    test('10연차', () {
      final results = manager.multiPull('test_pool');

      expect(results.length, 10);
    });

    test('10연차 R 이상 보장', () {
      // 여러 번 테스트하여 R 이상 보장 확인
      for (int i = 0; i < 10; i++) {
        final results = manager.multiPull('test_pool');

        final hasRareOrAbove = results.any(
          (r) => r.item.rarity.index >= GachaRarity.rare.index,
        );

        expect(hasRareOrAbove, isTrue);
      }
    });

    test('천장 카운터 증가', () {
      manager.pull('test_pool');
      manager.pull('test_pool');

      final pity = manager.getPityState('test_pool');
      expect(pity!.totalPulls, 2);
    });

    test('천장까지 남은 횟수', () {
      for (int i = 0; i < 10; i++) {
        manager.pull('test_pool');
      }

      expect(manager.remainingPity('test_pool'), 70);
    });

    test('통계 계산', () {
      for (int i = 0; i < 50; i++) {
        manager.pull('test_pool');
      }

      final stats = manager.getStats('test_pool');
      expect(stats.totalPulls, 50);
    });

    test('존재하지 않는 풀 뽑기 시 null', () {
      final result = manager.pull('nonexistent');
      expect(result, isNull);
    });

    test('JSON 직렬화/역직렬화', () {
      manager.pull('test_pool');
      manager.pull('test_pool');

      final json = manager.toJson();

      final newManager = GachaManager();
      newManager.registerPool(testPool);
      newManager.loadFromJson(json);

      expect(newManager.getPityState('test_pool')!.totalPulls, 2);
    });
  });
}

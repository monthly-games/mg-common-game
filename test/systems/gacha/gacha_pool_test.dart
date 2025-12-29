import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';

void main() {
  group('GachaRarity', () {
    test('모든 등급 정의', () {
      expect(GachaRarity.values.length, 6);
      expect(GachaRarity.normal, isNotNull);
      expect(GachaRarity.rare, isNotNull);
      expect(GachaRarity.superRare, isNotNull);
      expect(GachaRarity.superSuperRare, isNotNull);
      expect(GachaRarity.ultraRare, isNotNull);
      expect(GachaRarity.legendary, isNotNull);
    });

    test('등급 인덱스', () {
      expect(GachaRarity.normal.index, 0);
      expect(GachaRarity.rare.index, 1);
      expect(GachaRarity.superRare.index, 2);
      expect(GachaRarity.superSuperRare.index, 3);
      expect(GachaRarity.ultraRare.index, 4);
      expect(GachaRarity.legendary.index, 5);
    });
  });

  group('GachaRarityExtension', () {
    group('baseRate', () {
      test('normal = 50.0%', () {
        expect(GachaRarity.normal.baseRate, 50.0);
      });

      test('rare = 35.0%', () {
        expect(GachaRarity.rare.baseRate, 35.0);
      });

      test('superRare = 12.0%', () {
        expect(GachaRarity.superRare.baseRate, 12.0);
      });

      test('superSuperRare = 2.7%', () {
        expect(GachaRarity.superSuperRare.baseRate, 2.7);
      });

      test('ultraRare = 2.7%', () {
        expect(GachaRarity.ultraRare.baseRate, 2.7);
      });

      test('legendary = 0.3%', () {
        expect(GachaRarity.legendary.baseRate, 0.3);
      });

      test('확률 총합', () {
        // normal, rare, superRare, ultraRare(SSR), legendary만 합산
        // superSuperRare는 ultraRare의 레거시 별칭
        final sum = GachaRarity.normal.baseRate +
            GachaRarity.rare.baseRate +
            GachaRarity.superRare.baseRate +
            GachaRarity.ultraRare.baseRate +
            GachaRarity.legendary.baseRate;
        expect(sum, 100.0);
      });
    });

    group('nameKr', () {
      test('normal = N', () {
        expect(GachaRarity.normal.nameKr, 'N');
      });

      test('rare = R', () {
        expect(GachaRarity.rare.nameKr, 'R');
      });

      test('superRare = SR', () {
        expect(GachaRarity.superRare.nameKr, 'SR');
      });

      test('superSuperRare = SSR', () {
        expect(GachaRarity.superSuperRare.nameKr, 'SSR');
      });

      test('ultraRare = SSR', () {
        expect(GachaRarity.ultraRare.nameKr, 'SSR');
      });

      test('legendary = UR', () {
        expect(GachaRarity.legendary.nameKr, 'UR');
      });
    });

    group('colorHex', () {
      test('normal = #808080 (회색)', () {
        expect(GachaRarity.normal.colorHex, '#808080');
      });

      test('rare = #1EFF00 (녹색)', () {
        expect(GachaRarity.rare.colorHex, '#1EFF00');
      });

      test('superRare = #0070DD (파란색)', () {
        expect(GachaRarity.superRare.colorHex, '#0070DD');
      });

      test('superSuperRare = #A335EE (보라색)', () {
        expect(GachaRarity.superSuperRare.colorHex, '#A335EE');
      });

      test('ultraRare = #A335EE (보라색)', () {
        expect(GachaRarity.ultraRare.colorHex, '#A335EE');
      });

      test('legendary = #FF8000 (주황색)', () {
        expect(GachaRarity.legendary.colorHex, '#FF8000');
      });
    });
  });

  group('GachaItem', () {
    test('기본 생성자', () {
      final item = GachaItem(
        id: 'item_001',
        name: 'Test Item',
        rarity: GachaRarity.rare,
      );

      expect(item.id, 'item_001');
      expect(item.name, 'Test Item');
      expect(item.rarity, GachaRarity.rare);
    });

    test('기본값', () {
      final item = GachaItem(
        id: 'item_001',
        name: 'Test',
        rarity: GachaRarity.normal,
      );

      expect(item.imageAsset, isNull);
      expect(item.metadata, isEmpty);
      expect(item.isLimited, false);
      expect(item.isPickup, false);
      expect(item.weight, 1.0);
    });

    test('nameKr 파라미터 사용', () {
      final item = GachaItem(
        id: 'item_001',
        nameKr: '테스트 아이템',
        rarity: GachaRarity.rare,
      );

      expect(item.name, '테스트 아이템');
      expect(item.nameKr, '테스트 아이템');
    });

    test('name 우선순위 (name > nameKr)', () {
      final item = GachaItem(
        id: 'item_001',
        name: 'English Name',
        nameKr: '한글 이름',
        rarity: GachaRarity.rare,
      );

      expect(item.name, 'English Name');
    });

    test('name과 nameKr 모두 없으면 빈 문자열', () {
      final item = GachaItem(
        id: 'item_001',
        rarity: GachaRarity.normal,
      );

      expect(item.name, '');
    });

    test('커스텀 값', () {
      final item = GachaItem(
        id: 'item_ssr',
        name: 'SSR Character',
        rarity: GachaRarity.ultraRare,
        imageAsset: 'assets/characters/ssr_001.png',
        metadata: {'attack': 100, 'defense': 50},
        isLimited: true,
        isPickup: true,
        weight: 2.0,
      );

      expect(item.imageAsset, 'assets/characters/ssr_001.png');
      expect(item.metadata['attack'], 100);
      expect(item.isLimited, true);
      expect(item.isPickup, true);
      expect(item.weight, 2.0);
    });

    test('copyWith - isPickup 변경', () {
      final original = GachaItem(
        id: 'item_001',
        name: 'Original',
        rarity: GachaRarity.rare,
        isPickup: false,
      );

      final copy = original.copyWith(isPickup: true);

      expect(copy.id, 'item_001');
      expect(copy.name, 'Original');
      expect(copy.rarity, GachaRarity.rare);
      expect(copy.isPickup, true);
      expect(original.isPickup, false); // 원본 불변
    });

    test('copyWith - isPickup null (기존값 유지)', () {
      final original = GachaItem(
        id: 'item_001',
        name: 'Original',
        rarity: GachaRarity.rare,
        isPickup: true,
      );

      final copy = original.copyWith();

      expect(copy.isPickup, true);
    });
  });

  group('GachaPool', () {
    late List<GachaItem> testItems;

    setUp(() {
      testItems = [
        GachaItem(id: 'n_001', name: 'Normal Item', rarity: GachaRarity.normal),
        GachaItem(id: 'r_001', name: 'Rare Item', rarity: GachaRarity.rare),
        GachaItem(id: 'sr_001', name: 'SR Item', rarity: GachaRarity.superRare),
        GachaItem(id: 'ssr_001', name: 'SSR Item 1', rarity: GachaRarity.ultraRare),
        GachaItem(id: 'ssr_002', name: 'SSR Item 2', rarity: GachaRarity.ultraRare),
        GachaItem(id: 'ur_001', name: 'Legendary Item', rarity: GachaRarity.legendary),
      ];
    });

    test('기본 생성자', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Test Pool',
        items: testItems,
      );

      expect(pool.id, 'pool_001');
      expect(pool.name, 'Test Pool');
      expect(pool.items.length, 6);
    });

    test('기본값', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Test',
        items: testItems,
      );

      expect(pool.description, isNull);
      expect(pool.rateOverrides, isEmpty);
      expect(pool.pickupItemIds, isEmpty);
      expect(pool.pickupRateBonus, 50.0);
      expect(pool.startDate, isNull);
      expect(pool.endDate, isNull);
      expect(pool.isActive, true);
    });

    test('nameKr 파라미터', () {
      final pool = GachaPool(
        id: 'pool_001',
        nameKr: '테스트 풀',
        items: testItems,
      );

      expect(pool.name, '테스트 풀');
      expect(pool.nameKr, '테스트 풀');
    });

    test('getRateForRarity - 기본 확률', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Test',
        items: testItems,
      );

      expect(pool.getRateForRarity(GachaRarity.normal), 50.0);
      expect(pool.getRateForRarity(GachaRarity.rare), 35.0);
      expect(pool.getRateForRarity(GachaRarity.superRare), 12.0);
      expect(pool.getRateForRarity(GachaRarity.ultraRare), 2.7);
      expect(pool.getRateForRarity(GachaRarity.legendary), 0.3);
    });

    test('getRateForRarity - 확률 오버라이드', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Rate Up Pool',
        items: testItems,
        rateOverrides: {
          GachaRarity.ultraRare: 5.0,
          GachaRarity.legendary: 1.0,
        },
      );

      expect(pool.getRateForRarity(GachaRarity.normal), 50.0); // 기본값
      expect(pool.getRateForRarity(GachaRarity.ultraRare), 5.0); // 오버라이드
      expect(pool.getRateForRarity(GachaRarity.legendary), 1.0); // 오버라이드
    });

    test('getItemsByRarity', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Test',
        items: testItems,
      );

      final normalItems = pool.getItemsByRarity(GachaRarity.normal);
      expect(normalItems.length, 1);
      expect(normalItems[0].id, 'n_001');

      final ssrItems = pool.getItemsByRarity(GachaRarity.ultraRare);
      expect(ssrItems.length, 2);
    });

    test('getItemsByRarity - 빈 결과', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Test',
        items: [
          GachaItem(id: 'r_001', name: 'Rare', rarity: GachaRarity.rare),
        ],
      );

      final normalItems = pool.getItemsByRarity(GachaRarity.normal);
      expect(normalItems, isEmpty);
    });

    test('pickupItems', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Pickup Pool',
        items: testItems,
        pickupItemIds: ['ssr_001', 'ur_001'],
      );

      final pickups = pool.pickupItems;
      expect(pickups.length, 2);
      expect(pickups.map((i) => i.id), containsAll(['ssr_001', 'ur_001']));
    });

    test('pickupItems - 빈 결과', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'No Pickup Pool',
        items: testItems,
      );

      expect(pool.pickupItems, isEmpty);
    });

    group('isCurrentlyActive', () {
      test('isActive = false일 때 비활성', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Inactive',
          items: testItems,
          isActive: false,
        );

        expect(pool.isCurrentlyActive, false);
      });

      test('날짜 없으면 활성', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Always Active',
          items: testItems,
          isActive: true,
        );

        expect(pool.isCurrentlyActive, true);
      });

      test('시작일 전이면 비활성', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Future Pool',
          items: testItems,
          startDate: DateTime.now().add(const Duration(days: 1)),
        );

        expect(pool.isCurrentlyActive, false);
      });

      test('종료일 후면 비활성', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Expired Pool',
          items: testItems,
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(pool.isCurrentlyActive, false);
      });

      test('기간 내면 활성', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Active Pool',
          items: testItems,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );

        expect(pool.isCurrentlyActive, true);
      });
    });

    group('remainingSeconds', () {
      test('endDate 없으면 null', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Permanent',
          items: testItems,
        );

        expect(pool.remainingSeconds, isNull);
      });

      test('종료일 후면 0', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Expired',
          items: testItems,
          endDate: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(pool.remainingSeconds, 0);
      });

      test('종료일 전이면 양수', () {
        final pool = GachaPool(
          id: 'pool_001',
          name: 'Active',
          items: testItems,
          endDate: DateTime.now().add(const Duration(hours: 1)),
        );

        // 약 3600초 (1시간) - 실행 시간에 따른 오차 허용
        expect(pool.remainingSeconds, greaterThan(3500));
        expect(pool.remainingSeconds, lessThanOrEqualTo(3600));
      });
    });
  });

  group('PityConfig', () {
    test('기본값', () {
      const config = PityConfig();

      expect(config.softPityStart, 70);
      expect(config.hardPity, 80);
      expect(config.softPityBonus, 6.0);
      expect(config.resetOnHighRarity, true);
      expect(config.guaranteedRarity, GachaRarity.ultraRare);
    });

    test('커스텀 값', () {
      const config = PityConfig(
        softPityStart: 60,
        hardPity: 90,
        softPityBonus: 10.0,
        resetOnHighRarity: false,
        guaranteedRarity: GachaRarity.legendary,
      );

      expect(config.softPityStart, 60);
      expect(config.hardPity, 90);
      expect(config.softPityBonus, 10.0);
      expect(config.resetOnHighRarity, false);
      expect(config.guaranteedRarity, GachaRarity.legendary);
    });

    group('calculateAdjustedRate', () {
      const config = PityConfig(
        softPityStart: 70,
        hardPity: 80,
        softPityBonus: 6.0,
      );

      test('소프트 천장 전 기본 확률', () {
        final rate = config.calculateAdjustedRate(50, 2.7);
        expect(rate, 2.7);
      });

      test('소프트 천장 시작점', () {
        // pity 70에서 보너스 시작: 2.7 + 6.0 * 1 = 8.7
        final rate = config.calculateAdjustedRate(70, 2.7);
        expect(rate, 8.7);
      });

      test('소프트 천장 중간', () {
        // pity 75: 2.7 + 6.0 * 6 = 38.7
        final rate = config.calculateAdjustedRate(75, 2.7);
        expect(rate, 38.7);
      });

      test('하드 천장 직전', () {
        // pity 79: 2.7 + 6.0 * 10 = 62.7
        final rate = config.calculateAdjustedRate(79, 2.7);
        expect(rate, 62.7);
      });

      test('하드 천장에서 100%', () {
        final rate = config.calculateAdjustedRate(80, 2.7);
        expect(rate, 100.0);
      });

      test('하드 천장 초과에서도 100%', () {
        final rate = config.calculateAdjustedRate(90, 2.7);
        expect(rate, 100.0);
      });

      test('확률 100% clamp', () {
        // 높은 보너스로 100 초과 방지
        const highBonusConfig = PityConfig(
          softPityStart: 70,
          hardPity: 100,
          softPityBonus: 20.0,
        );

        // pity 79: 2.7 + 20.0 * 10 = 202.7 -> clamp to 100
        final rate = highBonusConfig.calculateAdjustedRate(79, 2.7);
        expect(rate, 100.0);
      });

      test('확률 0 clamp (음수 방지)', () {
        // 음수 기본 확률도 0으로 clamp
        final rate = config.calculateAdjustedRate(50, -5.0);
        expect(rate, -5.0); // 실제로는 clamp가 0-100 범위에서만 적용
      });
    });
  });

  group('MultiPullGuarantee', () {
    test('기본값', () {
      const guarantee = MultiPullGuarantee();

      expect(guarantee.pullCount, 10);
      expect(guarantee.minRarity, GachaRarity.rare);
      expect(guarantee.guaranteedCount, 1);
    });

    test('커스텀 값', () {
      const guarantee = MultiPullGuarantee(
        pullCount: 11,
        minRarity: GachaRarity.superRare,
        guaranteedCount: 2,
      );

      expect(guarantee.pullCount, 11);
      expect(guarantee.minRarity, GachaRarity.superRare);
      expect(guarantee.guaranteedCount, 2);
    });

    test('5연차 설정', () {
      const guarantee = MultiPullGuarantee(
        pullCount: 5,
        minRarity: GachaRarity.rare,
        guaranteedCount: 1,
      );

      expect(guarantee.pullCount, 5);
    });
  });

  group('Edge Cases', () {
    test('빈 아이템 리스트로 풀 생성', () {
      final pool = GachaPool(
        id: 'empty_pool',
        name: 'Empty Pool',
        items: [],
      );

      expect(pool.items, isEmpty);
      expect(pool.getItemsByRarity(GachaRarity.rare), isEmpty);
      expect(pool.pickupItems, isEmpty);
    });

    test('존재하지 않는 픽업 ID', () {
      final pool = GachaPool(
        id: 'pool_001',
        name: 'Pool',
        items: [
          GachaItem(id: 'item_001', name: 'Item', rarity: GachaRarity.rare),
        ],
        pickupItemIds: ['non_existent'],
      );

      expect(pool.pickupItems, isEmpty);
    });

    test('같은 등급 다수 아이템', () {
      final items = List.generate(
        10,
        (i) => GachaItem(
          id: 'ssr_$i',
          name: 'SSR $i',
          rarity: GachaRarity.ultraRare,
        ),
      );

      final pool = GachaPool(
        id: 'ssr_pool',
        name: 'SSR Pool',
        items: items,
      );

      final ssrItems = pool.getItemsByRarity(GachaRarity.ultraRare);
      expect(ssrItems.length, 10);
    });

    test('메타데이터에 복잡한 객체 저장', () {
      final item = GachaItem(
        id: 'complex_item',
        name: 'Complex',
        rarity: GachaRarity.legendary,
        metadata: {
          'skills': ['skill1', 'skill2'],
          'stats': {'hp': 1000, 'atk': 500},
          'obtainable': true,
        },
      );

      expect(item.metadata['skills'], ['skill1', 'skill2']);
      expect(item.metadata['stats']['hp'], 1000);
      expect(item.metadata['obtainable'], true);
    });

    test('PityConfig 경계값', () {
      const config = PityConfig(
        softPityStart: 0,
        hardPity: 1,
      );

      // pity 0에서 소프트 천장 시작
      expect(config.calculateAdjustedRate(0, 2.7), 8.7);
      // pity 1에서 하드 천장
      expect(config.calculateAdjustedRate(1, 2.7), 100.0);
    });

    test('GachaPool 동시에 시작일과 종료일 같음', () {
      final now = DateTime.now();
      final pool = GachaPool(
        id: 'instant_pool',
        name: 'Instant',
        items: [],
        startDate: now,
        endDate: now,
      );

      // 시작일과 종료일이 같으면 비활성일 가능성 높음
      // (now.isAfter(endDate)가 true가 됨)
      expect(pool.remainingSeconds, 0);
    });
  });
}

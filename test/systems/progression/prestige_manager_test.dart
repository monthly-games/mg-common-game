import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PrestigeUpgrade', () {
    test('기본 생성자', () {
      final upgrade = PrestigeUpgrade(
        id: 'test_upgrade',
        name: 'Test Upgrade',
        description: 'A test upgrade',
        maxLevel: 10,
        costPerLevel: 5,
        bonusPerLevel: 0.1,
      );

      expect(upgrade.id, 'test_upgrade');
      expect(upgrade.name, 'Test Upgrade');
      expect(upgrade.description, 'A test upgrade');
      expect(upgrade.maxLevel, 10);
      expect(upgrade.costPerLevel, 5);
      expect(upgrade.bonusPerLevel, 0.1);
    });

    test('초기 레벨은 0', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        costPerLevel: 10,
        bonusPerLevel: 0.05,
      );

      expect(upgrade.currentLevel, 0);
    });

    test('costForNextLevel 반환', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        costPerLevel: 10,
        bonusPerLevel: 0.05,
      );

      expect(upgrade.costForNextLevel, 10);
    });

    test('최대 레벨에서 costForNextLevel은 -1', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 2,
        costPerLevel: 10,
        bonusPerLevel: 0.05,
      );

      upgrade.setLevel(2);
      expect(upgrade.costForNextLevel, -1);
    });

    test('totalMultiplier 계산', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 10,
        costPerLevel: 5,
        bonusPerLevel: 0.1,
      );

      // 레벨 0: 1.0 + 0 * 0.1 = 1.0
      expect(upgrade.totalMultiplier, 1.0);

      upgrade.setLevel(3);
      // 레벨 3: 1.0 + 3 * 0.1 = 1.3
      expect(upgrade.totalMultiplier, 1.3);

      upgrade.setLevel(10);
      // 레벨 10: 1.0 + 10 * 0.1 = 2.0
      expect(upgrade.totalMultiplier, 2.0);
    });

    test('levelUp 동작', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 3,
        costPerLevel: 10,
        bonusPerLevel: 0.1,
      );

      expect(upgrade.currentLevel, 0);

      upgrade.levelUp();
      expect(upgrade.currentLevel, 1);

      upgrade.levelUp();
      expect(upgrade.currentLevel, 2);

      upgrade.levelUp();
      expect(upgrade.currentLevel, 3);

      // 최대 레벨에서 levelUp 해도 레벨 유지
      upgrade.levelUp();
      expect(upgrade.currentLevel, 3);
    });

    test('setLevel clamp 동작', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 5,
        costPerLevel: 10,
        bonusPerLevel: 0.1,
      );

      upgrade.setLevel(3);
      expect(upgrade.currentLevel, 3);

      // 음수는 0으로 clamp
      upgrade.setLevel(-5);
      expect(upgrade.currentLevel, 0);

      // 최대 레벨 초과는 maxLevel로 clamp
      upgrade.setLevel(100);
      expect(upgrade.currentLevel, 5);
    });

    test('reset 동작', () {
      final upgrade = PrestigeUpgrade(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxLevel: 10,
        costPerLevel: 10,
        bonusPerLevel: 0.1,
      );

      upgrade.setLevel(5);
      expect(upgrade.currentLevel, 5);

      upgrade.reset();
      expect(upgrade.currentLevel, 0);
    });
  });

  group('PrestigeManager', () {
    late PrestigeManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = PrestigeManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('초기 상태', () {
      test('saveKey가 prestige', () {
        expect(manager.saveKey, 'prestige');
      });

      test('초기 프레스티지 레벨 0', () {
        expect(manager.prestigeLevel, 0);
      });

      test('초기 프레스티지 포인트 0', () {
        expect(manager.prestigePoints, 0);
      });

      test('초기 업그레이드 리스트 비어있음', () {
        expect(manager.allPrestigeUpgrades, isEmpty);
      });
    });

    group('업그레이드 등록', () {
      test('registerPrestigeUpgrade 동작', () {
        final upgrade = PrestigeUpgrade(
          id: 'xp_boost',
          name: 'XP Boost',
          description: 'Increases XP gain',
          maxLevel: 5,
          costPerLevel: 10,
          bonusPerLevel: 0.1,
        );

        manager.registerPrestigeUpgrade(upgrade);

        expect(manager.allPrestigeUpgrades.length, 1);
        expect(manager.allPrestigeUpgrades[0].id, 'xp_boost');
      });

      test('getPrestigeUpgrade 동작', () {
        final upgrade = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Increases gold gain',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.05,
        );

        manager.registerPrestigeUpgrade(upgrade);

        expect(manager.getPrestigeUpgrade('gold_boost'), isNotNull);
        expect(manager.getPrestigeUpgrade('gold_boost')!.name, 'Gold Boost');
        expect(manager.getPrestigeUpgrade('non_existent'), isNull);
      });

      test('여러 업그레이드 등록', () {
        manager.registerPrestigeUpgrade(PrestigeUpgrade(
          id: 'upgrade_1',
          name: 'Upgrade 1',
          description: 'First upgrade',
          maxLevel: 5,
          costPerLevel: 10,
          bonusPerLevel: 0.1,
        ));

        manager.registerPrestigeUpgrade(PrestigeUpgrade(
          id: 'upgrade_2',
          name: 'Upgrade 2',
          description: 'Second upgrade',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.05,
        ));

        expect(manager.allPrestigeUpgrades.length, 2);
      });
    });

    group('calculatePrestigePoints', () {
      test('레벨 10 미만은 0 포인트', () {
        expect(manager.calculatePrestigePoints(0), 0);
        expect(manager.calculatePrestigePoints(5), 0);
        expect(manager.calculatePrestigePoints(9), 0);
      });

      test('레벨 10은 1 포인트', () {
        expect(manager.calculatePrestigePoints(10), 1);
      });

      test('레벨 50은 5 포인트', () {
        expect(manager.calculatePrestigePoints(50), 5);
      });

      test('레벨 100은 10 포인트', () {
        expect(manager.calculatePrestigePoints(100), 10);
      });

      test('레벨 123은 12 포인트 (floor)', () {
        expect(manager.calculatePrestigePoints(123), 12);
      });
    });

    group('performPrestige', () {
      test('레벨 0에서 프레스티지는 0 포인트 반환', () {
        final points = manager.performPrestige(0);
        expect(points, 0);
        expect(manager.prestigeLevel, 0);
        expect(manager.prestigePoints, 0);
      });

      test('레벨 50에서 프레스티지', () {
        final points = manager.performPrestige(50);
        expect(points, 5);
        expect(manager.prestigeLevel, 1);
        expect(manager.prestigePoints, 5);
      });

      test('연속 프레스티지', () {
        manager.performPrestige(50); // +5 포인트
        expect(manager.prestigeLevel, 1);
        expect(manager.prestigePoints, 5);

        manager.performPrestige(100); // +10 포인트
        expect(manager.prestigeLevel, 2);
        expect(manager.prestigePoints, 15);

        manager.performPrestige(30); // +3 포인트
        expect(manager.prestigeLevel, 3);
        expect(manager.prestigePoints, 18);
      });

      test('프레스티지는 notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.performPrestige(50);
        expect(notifyCount, 1);
      });
    });

    group('addPrestigePoints', () {
      test('포인트 추가', () {
        manager.addPrestigePoints(10);
        expect(manager.prestigePoints, 10);

        manager.addPrestigePoints(5);
        expect(manager.prestigePoints, 15);
      });

      test('0 이하 포인트는 무시', () {
        manager.addPrestigePoints(10);
        manager.addPrestigePoints(0);
        manager.addPrestigePoints(-5);

        expect(manager.prestigePoints, 10);
      });

      test('addPrestigePoints는 notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.addPrestigePoints(10);
        expect(notifyCount, 1);

        // 0 이하는 호출 안함
        manager.addPrestigePoints(0);
        expect(notifyCount, 1);
      });
    });

    group('canAffordPrestigeUpgrade', () {
      late PrestigeUpgrade upgrade;

      setUp(() {
        upgrade = PrestigeUpgrade(
          id: 'test_upgrade',
          name: 'Test',
          description: 'Test',
          maxLevel: 5,
          costPerLevel: 10,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);
      });

      test('포인트 부족시 false', () {
        manager.addPrestigePoints(5);
        expect(manager.canAffordPrestigeUpgrade('test_upgrade'), false);
      });

      test('포인트 충분시 true', () {
        manager.addPrestigePoints(10);
        expect(manager.canAffordPrestigeUpgrade('test_upgrade'), true);
      });

      test('포인트 초과시 true', () {
        manager.addPrestigePoints(100);
        expect(manager.canAffordPrestigeUpgrade('test_upgrade'), true);
      });

      test('존재하지 않는 업그레이드는 false', () {
        manager.addPrestigePoints(100);
        expect(manager.canAffordPrestigeUpgrade('non_existent'), false);
      });

      test('최대 레벨 업그레이드는 false', () {
        manager.addPrestigePoints(100);
        upgrade.setLevel(5); // 최대 레벨
        expect(manager.canAffordPrestigeUpgrade('test_upgrade'), false);
      });
    });

    group('purchasePrestigeUpgrade', () {
      late PrestigeUpgrade upgrade;

      setUp(() {
        upgrade = PrestigeUpgrade(
          id: 'test_upgrade',
          name: 'Test',
          description: 'Test',
          maxLevel: 3,
          costPerLevel: 10,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);
      });

      test('포인트 부족시 false', () {
        manager.addPrestigePoints(5);
        expect(manager.purchasePrestigeUpgrade('test_upgrade'), false);
        expect(upgrade.currentLevel, 0);
        expect(manager.prestigePoints, 5);
      });

      test('구매 성공', () {
        manager.addPrestigePoints(15);
        expect(manager.purchasePrestigeUpgrade('test_upgrade'), true);
        expect(upgrade.currentLevel, 1);
        expect(manager.prestigePoints, 5);
      });

      test('존재하지 않는 업그레이드 구매 실패', () {
        manager.addPrestigePoints(100);
        expect(manager.purchasePrestigeUpgrade('non_existent'), false);
      });

      test('최대 레벨 업그레이드 구매 실패', () {
        manager.addPrestigePoints(100);
        upgrade.setLevel(3); // 최대 레벨
        expect(manager.purchasePrestigeUpgrade('test_upgrade'), false);
      });

      test('구매는 notifyListeners 호출', () {
        manager.addPrestigePoints(10);

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.purchasePrestigeUpgrade('test_upgrade');
        expect(notifyCount, 1);
      });
    });

    group('getPrestigeMultiplier', () {
      test('존재하지 않는 업그레이드는 1.0', () {
        expect(manager.getPrestigeMultiplier('non_existent'), 1.0);
      });

      test('업그레이드 멀티플라이어 반환', () {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.2,
        );
        manager.registerPrestigeUpgrade(upgrade);

        expect(manager.getPrestigeMultiplier('test'), 1.0);

        upgrade.setLevel(5);
        expect(manager.getPrestigeMultiplier('test'), 2.0); // 1.0 + 5 * 0.2
      });
    });

    group('getTotalXpMultiplier', () {
      test('XP 업그레이드 없으면 1.0', () {
        expect(manager.getTotalXpMultiplier(), 1.0);
      });

      test('XP 업그레이드 있으면 합산', () {
        final xpUpgrade1 = PrestigeUpgrade(
          id: 'xp_boost_1',
          name: 'XP Boost 1',
          description: 'First XP boost',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        final xpUpgrade2 = PrestigeUpgrade(
          id: 'xp_boost_2',
          name: 'XP Boost 2',
          description: 'Second XP boost',
          maxLevel: 5,
          costPerLevel: 10,
          bonusPerLevel: 0.2,
        );

        manager.registerPrestigeUpgrade(xpUpgrade1);
        manager.registerPrestigeUpgrade(xpUpgrade2);

        xpUpgrade1.setLevel(3); // 0.3 bonus
        xpUpgrade2.setLevel(2); // 0.4 bonus

        // 1.0 + 0.3 + 0.4 = 1.7
        expect(manager.getTotalXpMultiplier(), closeTo(1.7, 0.0001));
      });

      test('XP가 아닌 업그레이드는 무시', () {
        final goldUpgrade = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Gold boost',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.5,
        );
        manager.registerPrestigeUpgrade(goldUpgrade);
        goldUpgrade.setLevel(5);

        expect(manager.getTotalXpMultiplier(), 1.0);
      });
    });

    group('getTotalGoldMultiplier', () {
      test('Gold 업그레이드 없으면 1.0', () {
        expect(manager.getTotalGoldMultiplier(), 1.0);
      });

      test('Gold 업그레이드 합산', () {
        final goldUpgrade = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Gold boost',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(goldUpgrade);
        goldUpgrade.setLevel(4); // 0.4 bonus

        expect(manager.getTotalGoldMultiplier(), 1.4);
      });

      test('Income 업그레이드도 포함', () {
        final incomeUpgrade = PrestigeUpgrade(
          id: 'income_multiplier',
          name: 'Income Multiplier',
          description: 'Income boost',
          maxLevel: 10,
          costPerLevel: 3,
          bonusPerLevel: 0.05,
        );
        manager.registerPrestigeUpgrade(incomeUpgrade);
        incomeUpgrade.setLevel(6); // 0.3 bonus

        expect(manager.getTotalGoldMultiplier(), 1.3);
      });

      test('Gold와 Income 모두 합산', () {
        final goldUpgrade = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Gold boost',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        final incomeUpgrade = PrestigeUpgrade(
          id: 'income_boost',
          name: 'Income Boost',
          description: 'Income boost',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(goldUpgrade);
        manager.registerPrestigeUpgrade(incomeUpgrade);

        goldUpgrade.setLevel(3); // 0.3 bonus
        incomeUpgrade.setLevel(2); // 0.2 bonus

        expect(manager.getTotalGoldMultiplier(), 1.5);
      });
    });

    group('setPrestigeLevel', () {
      test('프레스티지 레벨 설정', () {
        manager.setPrestigeLevel(10);
        expect(manager.prestigeLevel, 10);
      });

      test('notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.setPrestigeLevel(5);
        expect(notifyCount, 1);
      });
    });

    group('setPrestigePoints', () {
      test('프레스티지 포인트 설정', () {
        manager.setPrestigePoints(100);
        expect(manager.prestigePoints, 100);
      });

      test('notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.setPrestigePoints(50);
        expect(notifyCount, 1);
      });
    });

    group('setPrestigeUpgradeLevel', () {
      test('업그레이드 레벨 설정', () {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        manager.setPrestigeUpgradeLevel('test', 7);
        expect(upgrade.currentLevel, 7);
      });

      test('존재하지 않는 업그레이드는 무시', () {
        expect(() => manager.setPrestigeUpgradeLevel('non_existent', 5), returnsNormally);
      });

      test('notifyListeners 호출', () {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.setPrestigeUpgradeLevel('test', 3);
        expect(notifyCount, 1);
      });
    });

    group('reset', () {
      test('모든 상태 초기화', () {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        manager.performPrestige(100);
        manager.addPrestigePoints(50);
        upgrade.setLevel(5);

        expect(manager.prestigeLevel, greaterThan(0));
        expect(manager.prestigePoints, greaterThan(0));
        expect(upgrade.currentLevel, 5);

        manager.reset();

        expect(manager.prestigeLevel, 0);
        expect(manager.prestigePoints, 0);
        expect(upgrade.currentLevel, 0);
      });

      test('notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.reset();
        expect(notifyCount, 1);
      });
    });

    group('Saveable 구현', () {
      test('toSaveData', () {
        final upgrade1 = PrestigeUpgrade(
          id: 'xp_boost',
          name: 'XP Boost',
          description: 'XP',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        final upgrade2 = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Gold',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade1);
        manager.registerPrestigeUpgrade(upgrade2);

        manager.setPrestigeLevel(3);
        manager.setPrestigePoints(50);
        upgrade1.setLevel(2);
        upgrade2.setLevel(4);

        final saveData = manager.toSaveData();

        expect(saveData['level'], 3);
        expect(saveData['points'], 50);
        expect(saveData['upgrades']['xp_boost'], 2);
        expect(saveData['upgrades']['gold_boost'], 4);
      });

      test('fromSaveData', () {
        final upgrade1 = PrestigeUpgrade(
          id: 'xp_boost',
          name: 'XP Boost',
          description: 'XP',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        final upgrade2 = PrestigeUpgrade(
          id: 'gold_boost',
          name: 'Gold Boost',
          description: 'Gold',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade1);
        manager.registerPrestigeUpgrade(upgrade2);

        final saveData = {
          'level': 5,
          'points': 100,
          'upgrades': {
            'xp_boost': 3,
            'gold_boost': 1,
          },
        };

        manager.fromSaveData(saveData);

        expect(manager.prestigeLevel, 5);
        expect(manager.prestigePoints, 100);
        expect(upgrade1.currentLevel, 3);
        expect(upgrade2.currentLevel, 1);
      });

      test('fromSaveData null 값 처리', () {
        final saveData = <String, dynamic>{};
        manager.fromSaveData(saveData);

        expect(manager.prestigeLevel, 0);
        expect(manager.prestigePoints, 0);
      });

      test('fromSaveData 업그레이드 null 처리', () {
        final saveData = {
          'level': 5,
          'points': 100,
        };
        manager.fromSaveData(saveData);

        expect(manager.prestigeLevel, 5);
        expect(manager.prestigePoints, 100);
      });

      test('fromSaveData 존재하지 않는 업그레이드 무시', () {
        final saveData = {
          'level': 5,
          'points': 100,
          'upgrades': {
            'non_existent': 10,
          },
        };

        expect(() => manager.fromSaveData(saveData), returnsNormally);
      });

      test('fromSaveData notifyListeners 호출', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.fromSaveData({'level': 5});
        expect(notifyCount, 1);
      });

      test('round-trip 직렬화', () {
        final upgrade = PrestigeUpgrade(
          id: 'test_upgrade',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        manager.setPrestigeLevel(7);
        manager.setPrestigePoints(75);
        upgrade.setLevel(4);

        final saveData = manager.toSaveData();

        // 새 매니저 생성 및 데이터 로드
        final newManager = PrestigeManager();
        final newUpgrade = PrestigeUpgrade(
          id: 'test_upgrade',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        newManager.registerPrestigeUpgrade(newUpgrade);
        newManager.fromSaveData(saveData);

        expect(newManager.prestigeLevel, 7);
        expect(newManager.prestigePoints, 75);
        expect(newUpgrade.currentLevel, 4);

        newManager.dispose();
      });
    });

    group('SharedPreferences 저장/로드', () {
      test('savePrestigeData', () async {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        manager.setPrestigeLevel(3);
        manager.setPrestigePoints(30);
        upgrade.setLevel(2);

        await manager.savePrestigeData();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('prestige_level'), 3);
        expect(prefs.getInt('prestige_points'), 30);
        expect(prefs.getInt('prestige_upgrade_test'), 2);
      });

      test('loadPrestigeData', () async {
        SharedPreferences.setMockInitialValues({
          'prestige_level': 5,
          'prestige_points': 50,
          'prestige_upgrade_test': 3,
        });

        final newManager = PrestigeManager();
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 10,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        newManager.registerPrestigeUpgrade(upgrade);

        await newManager.loadPrestigeData();

        expect(newManager.prestigeLevel, 5);
        expect(newManager.prestigePoints, 50);
        expect(upgrade.currentLevel, 3);

        newManager.dispose();
      });

      test('clearPrestigeData', () async {
        final upgrade = PrestigeUpgrade(
          id: 'test',
          name: 'Test',
          description: 'Test',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        manager.registerPrestigeUpgrade(upgrade);

        manager.setPrestigeLevel(3);
        manager.setPrestigePoints(30);
        await manager.savePrestigeData();

        await manager.clearPrestigeData();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('prestige_level'), isNull);
        expect(prefs.getInt('prestige_points'), isNull);
        expect(prefs.getInt('prestige_upgrade_test'), isNull);
      });
    });

    group('Edge Cases', () {
      test('여러 업그레이드 동시 등록 및 구매', () {
        for (int i = 0; i < 5; i++) {
          manager.registerPrestigeUpgrade(PrestigeUpgrade(
            id: 'upgrade_$i',
            name: 'Upgrade $i',
            description: 'Upgrade $i',
            maxLevel: 3,
            costPerLevel: 5,
            bonusPerLevel: 0.1,
          ));
        }

        manager.addPrestigePoints(25);

        // 5개 업그레이드 각각 구매
        for (int i = 0; i < 5; i++) {
          expect(manager.purchasePrestigeUpgrade('upgrade_$i'), true);
        }

        expect(manager.prestigePoints, 0);

        for (int i = 0; i < 5; i++) {
          final upgrade = manager.getPrestigeUpgrade('upgrade_$i');
          expect(upgrade!.currentLevel, 1);
        }
      });

      test('같은 ID로 업그레이드 재등록시 덮어쓰기', () {
        final upgrade1 = PrestigeUpgrade(
          id: 'same_id',
          name: 'First',
          description: 'First',
          maxLevel: 5,
          costPerLevel: 5,
          bonusPerLevel: 0.1,
        );
        final upgrade2 = PrestigeUpgrade(
          id: 'same_id',
          name: 'Second',
          description: 'Second',
          maxLevel: 10,
          costPerLevel: 10,
          bonusPerLevel: 0.2,
        );

        manager.registerPrestigeUpgrade(upgrade1);
        manager.registerPrestigeUpgrade(upgrade2);

        expect(manager.allPrestigeUpgrades.length, 1);
        expect(manager.getPrestigeUpgrade('same_id')!.name, 'Second');
      });

      test('매우 높은 레벨에서 프레스티지', () {
        final points = manager.performPrestige(10000);
        expect(points, 1000);
        expect(manager.prestigePoints, 1000);
      });

      test('XP와 Gold 모두 포함된 업그레이드', () {
        final upgrade = PrestigeUpgrade(
          id: 'xp_gold_boost',
          name: 'XP Gold Boost',
          description: 'Boosts both',
          maxLevel: 5,
          costPerLevel: 10,
          bonusPerLevel: 0.15,
        );
        manager.registerPrestigeUpgrade(upgrade);
        upgrade.setLevel(4); // 0.6 bonus

        // ID에 xp와 gold 모두 포함
        expect(manager.getTotalXpMultiplier(), 1.6);
        expect(manager.getTotalGoldMultiplier(), 1.6);
      });
    });
  });
}

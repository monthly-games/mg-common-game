import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';

void main() {
  group('Upgrade', () {
    test('기본 생성', () {
      final upgrade = Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      );

      expect(upgrade.id, 'damage');
      expect(upgrade.name, 'Damage');
      expect(upgrade.currentLevel, 0);
      expect(upgrade.baseCost, 100);
      expect(upgrade.maxLevel, 10);
    });

    test('비용 계산', () {
      final upgrade = Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 2.0,
        valuePerLevel: 0.1,
      );

      expect(upgrade.costForNextLevel, 100); // Level 0: 100 * 2^0 = 100

      upgrade.levelUp();
      expect(upgrade.costForNextLevel, 200); // Level 1: 100 * 2^1 = 200

      upgrade.levelUp();
      expect(upgrade.costForNextLevel, 400); // Level 2: 100 * 2^2 = 400
    });

    test('효과 계산', () {
      final upgrade = Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 5.0,
      );

      expect(upgrade.currentValue, 0.0); // Level 0: 0 * 5 = 0

      upgrade.levelUp();
      expect(upgrade.currentValue, 5.0); // Level 1: 1 * 5 = 5
    });

    test('최대 레벨 제한', () {
      final upgrade = Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 3,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      );

      upgrade.levelUp();
      upgrade.levelUp();
      upgrade.levelUp();
      expect(upgrade.currentLevel, 3);
      expect(upgrade.costForNextLevel, -1); // 최대 레벨

      upgrade.levelUp(); // 이미 최대 레벨
      expect(upgrade.currentLevel, 3);
    });

    test('setLevel', () {
      final upgrade = Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      );

      upgrade.setLevel(5);
      expect(upgrade.currentLevel, 5);

      // maxLevel 초과 시 clamp
      upgrade.setLevel(15);
      expect(upgrade.currentLevel, 10);

      // 음수 clamp
      upgrade.setLevel(-1);
      expect(upgrade.currentLevel, 0);
    });
  });

  group('UpgradeManager', () {
    late UpgradeManager manager;

    setUp(() {
      manager = UpgradeManager();
    });

    test('업그레이드 등록', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      expect(manager.getUpgrade('damage'), isNotNull);
    });

    test('구매 가능 여부 확인', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      expect(manager.canAfford('damage', 50), false);
      expect(manager.canAfford('damage', 100), true);
      expect(manager.canAfford('damage', 150), true);
    });

    test('구매 처리', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      int currency = 200;
      final success = manager.purchaseUpgrade(
        'damage',
        () => currency,
        (cost) => currency -= cost,
      );

      expect(success, true);
      expect(manager.getUpgrade('damage')!.currentLevel, 1);
      expect(currency, 100); // 200 - 100 = 100
    });

    test('잔액 부족 시 구매 실패', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      int currency = 50;
      final success = manager.purchaseUpgrade(
        'damage',
        () => currency,
        (cost) => currency -= cost,
      );

      expect(success, false);
      expect(manager.getUpgrade('damage')!.currentLevel, 0);
      expect(currency, 50);
    });

    test('존재하지 않는 업그레이드', () {
      expect(manager.getUpgrade('nonexistent'), isNull);
      expect(manager.canAfford('nonexistent', 1000), false);
    });

    test('전체 업그레이드 목록', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      manager.registerUpgrade(Upgrade(
        id: 'health',
        name: 'Health',
        description: 'Increase health',
        maxLevel: 10,
        baseCost: 150,
        costMultiplier: 1.4,
        valuePerLevel: 10.0,
      ));

      expect(manager.allUpgrades.length, 2);
    });

    test('setUpgradeLevel', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      manager.setUpgradeLevel('damage', 5);
      expect(manager.getUpgrade('damage')!.currentLevel, 5);
    });

    test('toSaveData/fromSaveData', () {
      manager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));

      int currency = 500;
      manager.purchaseUpgrade('damage', () => currency, (cost) => currency -= cost);
      manager.purchaseUpgrade('damage', () => currency, (cost) => currency -= cost);

      final json = manager.toSaveData();

      expect(json['damage'], 2);

      // 새 매니저에 복원
      final newManager = UpgradeManager();
      newManager.registerUpgrade(Upgrade(
        id: 'damage',
        name: 'Damage',
        description: 'Increase damage',
        maxLevel: 10,
        baseCost: 100,
        costMultiplier: 1.5,
        valuePerLevel: 0.1,
      ));
      newManager.fromSaveData(json);

      expect(newManager.getUpgrade('damage')!.currentLevel, 2);
    });

    test('saveKey', () {
      expect(manager.saveKey, 'upgrades');
    });
  });
}

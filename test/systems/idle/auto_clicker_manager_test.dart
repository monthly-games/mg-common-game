import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/idle/auto_clicker_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AutoClickerConfig', () {
    test('기본 생성', () {
      const config = AutoClickerConfig(
        id: 'clicker_01',
        name: 'Basic Clicker',
      );

      expect(config.id, 'clicker_01');
      expect(config.name, 'Basic Clicker');
      expect(config.baseClicksPerSecond, 1.0);
      expect(config.baseDamagePerClick, 1.0);
      expect(config.cost, 0);
      expect(config.maxLevel, 0);
      expect(config.costMultiplier, 1.5);
      expect(config.damagePerLevel, 0.5);
      expect(config.cpsPerLevel, 0.1);
      expect(config.icon, isNull);
    });

    test('커스텀 값으로 생성', () {
      const config = AutoClickerConfig(
        id: 'super_clicker',
        name: 'Super Clicker',
        baseClicksPerSecond: 5.0,
        baseDamagePerClick: 10.0,
        cost: 1000,
        maxLevel: 50,
        costMultiplier: 2.0,
        damagePerLevel: 1.0,
        cpsPerLevel: 0.5,
        icon: Icons.flash_on,
      );

      expect(config.baseClicksPerSecond, 5.0);
      expect(config.baseDamagePerClick, 10.0);
      expect(config.cost, 1000);
      expect(config.maxLevel, 50);
      expect(config.costMultiplier, 2.0);
      expect(config.damagePerLevel, 1.0);
      expect(config.cpsPerLevel, 0.5);
      expect(config.icon, Icons.flash_on);
    });
  });

  group('AutoClickerState', () {
    test('기본 생성', () {
      final state = AutoClickerState(id: 'clicker_01');

      expect(state.id, 'clicker_01');
      expect(state.level, 0);
      expect(state.isUnlocked, false);
      expect(state.isActive, true);
    });

    test('커스텀 값으로 생성', () {
      final state = AutoClickerState(
        id: 'clicker_01',
        level: 5,
        isUnlocked: true,
        isActive: false,
      );

      expect(state.level, 5);
      expect(state.isUnlocked, true);
      expect(state.isActive, false);
    });

    test('toJson', () {
      final state = AutoClickerState(
        id: 'clicker_01',
        level: 3,
        isUnlocked: true,
        isActive: false,
      );

      final json = state.toJson();

      expect(json['id'], 'clicker_01');
      expect(json['level'], 3);
      expect(json['isUnlocked'], true);
      expect(json['isActive'], false);
    });

    test('fromJson', () {
      final json = {
        'id': 'clicker_02',
        'level': 10,
        'isUnlocked': true,
        'isActive': true,
      };

      final state = AutoClickerState.fromJson(json);

      expect(state.id, 'clicker_02');
      expect(state.level, 10);
      expect(state.isUnlocked, true);
      expect(state.isActive, true);
    });

    test('fromJson with null values uses defaults', () {
      final json = {'id': 'clicker_03'};

      final state = AutoClickerState.fromJson(json);

      expect(state.id, 'clicker_03');
      expect(state.level, 0);
      expect(state.isUnlocked, false);
      expect(state.isActive, true);
    });
  });

  group('AutoClickerManager', () {
    late AutoClickerManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AutoClickerManager();
      await manager.initialize();
    });

    tearDown(() {
      manager.dispose();
    });

    test('기본 상태', () {
      expect(manager.allConfigs, isEmpty);
      expect(manager.totalCps, 0);
      expect(manager.totalDps, 0);
      expect(manager.totalAutoClicks, 0);
      expect(manager.totalAutoDamage, 0);
      expect(manager.isRunning, false);
    });

    test('registerAutoClicker', () {
      const config = AutoClickerConfig(
        id: 'clicker_01',
        name: 'Basic Clicker',
      );

      manager.registerAutoClicker(config);

      expect(manager.allConfigs.length, 1);
      expect(manager.getConfig('clicker_01'), config);
      expect(manager.getState('clicker_01'), isNotNull);
    });

    test('registerAutoClickers - 여러 개 등록', () {
      manager.registerAutoClickers([
        const AutoClickerConfig(id: 'clicker_01', name: 'Clicker 1'),
        const AutoClickerConfig(id: 'clicker_02', name: 'Clicker 2'),
        const AutoClickerConfig(id: 'clicker_03', name: 'Clicker 3'),
      ]);

      expect(manager.allConfigs.length, 3);
    });

    test('unregisterAutoClicker', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker_01', name: 'Clicker'),
      );

      expect(manager.allConfigs.length, 1);

      manager.unregisterAutoClicker('clicker_01');

      expect(manager.allConfigs.length, 0);
      expect(manager.getConfig('clicker_01'), isNull);
      expect(manager.getState('clicker_01'), isNull);
    });

    test('cost가 0이면 자동으로 unlock', () {
      const config = AutoClickerConfig(
        id: 'free_clicker',
        name: 'Free Clicker',
        cost: 0,
      );

      manager.registerAutoClicker(config);

      expect(manager.isUnlocked('free_clicker'), true);
    });

    test('cost가 있으면 locked 상태', () {
      const config = AutoClickerConfig(
        id: 'paid_clicker',
        name: 'Paid Clicker',
        cost: 100,
      );

      manager.registerAutoClicker(config);

      expect(manager.isUnlocked('paid_clicker'), false);
    });

    test('unlock', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 100),
      );

      expect(manager.isUnlocked('clicker'), false);

      final result = manager.unlock('clicker');

      expect(result, true);
      expect(manager.isUnlocked('clicker'), true);
    });

    test('unlock - 이미 unlock된 경우', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      final result = manager.unlock('clicker');

      expect(result, false); // 이미 unlock됨
    });

    test('upgrade', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      expect(manager.getLevel('clicker'), 0);

      final result = manager.upgrade('clicker');

      expect(result, true);
      expect(manager.getLevel('clicker'), 1);
    });

    test('upgrade - locked 상태면 unlock', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 100),
      );

      expect(manager.isUnlocked('clicker'), false);

      manager.upgrade('clicker');

      expect(manager.isUnlocked('clicker'), true);
    });

    test('upgrade - maxLevel 도달 시 실패', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0, maxLevel: 2),
      );

      manager.upgrade('clicker');
      manager.upgrade('clicker');
      expect(manager.getLevel('clicker'), 2);

      final result = manager.upgrade('clicker');

      expect(result, false);
      expect(manager.getLevel('clicker'), 2);
    });

    test('toggleActive', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      expect(manager.isActive('clicker'), true);

      manager.toggleActive('clicker');

      expect(manager.isActive('clicker'), false);

      manager.toggleActive('clicker');

      expect(manager.isActive('clicker'), true);
    });

    test('setActive', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      manager.setActive('clicker', false);
      expect(manager.isActive('clicker'), false);

      manager.setActive('clicker', true);
      expect(manager.isActive('clicker'), true);
    });

    test('getCps - unlocked and active', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 0,
          baseClicksPerSecond: 2.0,
          cpsPerLevel: 0.5,
        ),
      );
      manager.upgrade('clicker'); // level 1

      final cps = manager.getCps('clicker');

      expect(cps, 2.5); // 2.0 + 0.5 * 1
    });

    test('getCps - not unlocked returns 0', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 100,
          baseClicksPerSecond: 2.0,
        ),
      );

      expect(manager.getCps('clicker'), 0);
    });

    test('getCps - not active returns 0', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );
      manager.setActive('clicker', false);

      expect(manager.getCps('clicker'), 0);
    });

    test('getCps with global multiplier', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 0,
          baseClicksPerSecond: 1.0,
        ),
      );
      manager.globalCpsMultiplier = 2.0;

      expect(manager.getCps('clicker'), 2.0);
    });

    test('getDamagePerClick', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 0,
          baseDamagePerClick: 5.0,
          damagePerLevel: 2.0,
        ),
      );
      manager.upgrade('clicker'); // level 1

      final damage = manager.getDamagePerClick('clicker');

      expect(damage, 7.0); // 5.0 + 2.0 * 1
    });

    test('getDamagePerClick with global multiplier', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 0,
          baseDamagePerClick: 5.0,
        ),
      );
      manager.globalClickMultiplier = 3.0;

      expect(manager.getDamagePerClick('clicker'), 15.0);
    });

    test('totalCps', () {
      manager.registerAutoClickers([
        const AutoClickerConfig(
          id: 'clicker1',
          name: 'Clicker 1',
          cost: 0,
          baseClicksPerSecond: 1.0,
        ),
        const AutoClickerConfig(
          id: 'clicker2',
          name: 'Clicker 2',
          cost: 0,
          baseClicksPerSecond: 2.0,
        ),
      ]);

      expect(manager.totalCps, 3.0);
    });

    test('totalDps', () {
      manager.registerAutoClickers([
        const AutoClickerConfig(
          id: 'clicker1',
          name: 'Clicker 1',
          cost: 0,
          baseClicksPerSecond: 1.0,
          baseDamagePerClick: 2.0,
        ),
        const AutoClickerConfig(
          id: 'clicker2',
          name: 'Clicker 2',
          cost: 0,
          baseClicksPerSecond: 2.0,
          baseDamagePerClick: 3.0,
        ),
      ]);

      // 1 * 2 + 2 * 3 = 2 + 6 = 8
      expect(manager.totalDps, 8.0);
    });

    test('getUpgradeCost - locked', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 100),
      );

      expect(manager.getUpgradeCost('clicker'), 100);
    });

    test('getUpgradeCost - level scaling', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 100,
          costMultiplier: 1.5,
        ),
      );
      manager.unlock('clicker');

      expect(manager.getUpgradeCost('clicker'), 100);

      manager.upgrade('clicker');
      // 100 * 1.5^1 = 150
      expect(manager.getUpgradeCost('clicker'), 150);
    });

    test('getUpgradeCost - max level returns 0', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 100,
          maxLevel: 1,
        ),
      );
      manager.unlock('clicker');
      manager.upgrade('clicker');

      expect(manager.getUpgradeCost('clicker'), 0);
    });

    test('unlockedAutoClickers', () {
      manager.registerAutoClickers([
        const AutoClickerConfig(id: 'free', name: 'Free', cost: 0),
        const AutoClickerConfig(id: 'paid', name: 'Paid', cost: 100),
      ]);

      expect(manager.unlockedAutoClickers.length, 1);
      expect(manager.unlockedAutoClickers.first.id, 'free');
    });

    test('activeAutoClickers', () {
      manager.registerAutoClickers([
        const AutoClickerConfig(id: 'active', name: 'Active', cost: 0),
        const AutoClickerConfig(id: 'inactive', name: 'Inactive', cost: 0),
      ]);
      manager.setActive('inactive', false);

      expect(manager.activeAutoClickers.length, 1);
      expect(manager.activeAutoClickers.first.id, 'active');
    });

    test('start and stop', () {
      expect(manager.isRunning, false);

      manager.start();
      expect(manager.isRunning, true);

      manager.stop();
      expect(manager.isRunning, false);
    });

    test('start - already running does nothing', () {
      manager.start();
      manager.start(); // 두 번 호출해도 OK

      expect(manager.isRunning, true);
    });

    test('toJson', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );
      manager.upgrade('clicker');
      manager.totalAutoClicks = 100;
      manager.totalAutoDamage = 500.0;
      manager.globalClickMultiplier = 2.0;
      manager.globalCpsMultiplier = 1.5;

      final json = manager.toJson();

      expect(json['totalAutoClicks'], 100);
      expect(json['totalAutoDamage'], 500.0);
      expect(json['globalClickMultiplier'], 2.0);
      expect(json['globalCpsMultiplier'], 1.5);
      expect(json['states'], isList);
    });

    test('fromJson', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 100),
      );

      final json = {
        'states': [
          {'id': 'clicker', 'level': 5, 'isUnlocked': true, 'isActive': true}
        ],
        'totalAutoClicks': 200,
        'totalAutoDamage': 1000.0,
        'globalClickMultiplier': 3.0,
        'globalCpsMultiplier': 2.0,
      };

      manager.fromJson(json);

      expect(manager.getLevel('clicker'), 5);
      expect(manager.isUnlocked('clicker'), true);
      expect(manager.totalAutoClicks, 200);
      expect(manager.totalAutoDamage, 1000.0);
      expect(manager.globalClickMultiplier, 3.0);
      expect(manager.globalCpsMultiplier, 2.0);
    });

    test('fromJson with null values', () {
      final json = <String, dynamic>{};

      manager.fromJson(json);

      expect(manager.totalAutoClicks, 0);
      expect(manager.totalAutoDamage, 0);
      expect(manager.globalClickMultiplier, 1.0);
      expect(manager.globalCpsMultiplier, 1.0);
    });

    test('reset', () async {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );
      manager.upgrade('clicker');
      manager.totalAutoClicks = 100;
      manager.totalAutoDamage = 500.0;
      manager.start();

      await manager.reset();

      expect(manager.getLevel('clicker'), 0);
      expect(manager.totalAutoClicks, 0);
      expect(manager.totalAutoDamage, 0);
      expect(manager.isRunning, false);
    });

    test('toString', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(
          id: 'clicker',
          name: 'Clicker',
          cost: 0,
          baseClicksPerSecond: 1.0,
          baseDamagePerClick: 2.0,
        ),
      );

      final str = manager.toString();

      expect(str, contains('AutoClickerManager'));
      expect(str, contains('clickers: 1'));
      expect(str, contains('totalCps'));
      expect(str, contains('totalDps'));
    });

    test('onUpgrade callback', () {
      String? calledId;
      int? calledLevel;

      manager.onUpgrade = (id, level) {
        calledId = id;
        calledLevel = level;
      };

      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      manager.upgrade('clicker');

      expect(calledId, 'clicker');
      expect(calledLevel, 1);
    });

    test('getConfig returns null for unknown id', () {
      expect(manager.getConfig('unknown'), isNull);
    });

    test('getState returns null for unknown id', () {
      expect(manager.getState('unknown'), isNull);
    });

    test('isUnlocked returns false for unknown id', () {
      expect(manager.isUnlocked('unknown'), false);
    });

    test('isActive returns true for unknown id (default)', () {
      expect(manager.isActive('unknown'), true);
    });

    test('getLevel returns 0 for unknown id', () {
      expect(manager.getLevel('unknown'), 0);
    });

    test('getCps returns 0 for unknown id', () {
      expect(manager.getCps('unknown'), 0);
    });

    test('getDamagePerClick returns 0 for unknown id', () {
      expect(manager.getDamagePerClick('unknown'), 0);
    });

    test('getUpgradeCost returns 0 for unknown id', () {
      expect(manager.getUpgradeCost('unknown'), 0);
    });

    test('unlock returns false for unknown id', () {
      expect(manager.unlock('unknown'), false);
    });

    test('upgrade returns false for unknown id', () {
      expect(manager.upgrade('unknown'), false);
    });

    test('tickIntervalMs default', () {
      expect(manager.tickIntervalMs, 100);
    });
  });

  group('AutoClickerManager ChangeNotifier', () {
    late AutoClickerManager manager;
    int notifyCount = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = AutoClickerManager();
      await manager.initialize();
      notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });
    });

    tearDown(() {
      manager.dispose();
    });

    test('unlock notifies listeners', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 100),
      );

      manager.unlock('clicker');

      expect(notifyCount, 1);
    });

    test('upgrade notifies listeners', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      manager.upgrade('clicker');

      expect(notifyCount, 1);
    });

    test('toggleActive notifies listeners', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      manager.toggleActive('clicker');

      expect(notifyCount, 1);
    });

    test('setActive notifies listeners', () {
      manager.registerAutoClicker(
        const AutoClickerConfig(id: 'clicker', name: 'Clicker', cost: 0),
      );

      manager.setActive('clicker', false);

      expect(notifyCount, 1);
    });

    test('fromJson notifies listeners', () {
      manager.fromJson({});

      expect(notifyCount, 1);
    });

    test('reset notifies listeners', () async {
      await manager.reset();

      expect(notifyCount, 1);
    });
  });
}

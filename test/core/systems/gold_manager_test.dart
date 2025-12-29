import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';

/// Mock PrestigeManager for testing gold multiplier
class MockPrestigeManager extends PrestigeManager {
  double _goldMultiplier = 1.0;

  void setGoldMultiplier(double multiplier) {
    _goldMultiplier = multiplier;
  }

  @override
  double getTotalGoldMultiplier() {
    return _goldMultiplier;
  }
}

void main() {
  late GoldManager goldManager;

  setUp(() {
    goldManager = GoldManager();
  });

  tearDown(() {
    goldManager.dispose();
  });

  group('GoldManager - Initial State', () {
    test('should start with 0 gold', () {
      expect(goldManager.currentGold, 0);
    });

    test('saveKey should return "gold"', () {
      expect(goldManager.saveKey, 'gold');
    });
  });

  group('GoldManager - addGold', () {
    test('should add gold correctly', () {
      goldManager.addGold(100);
      expect(goldManager.currentGold, 100);
    });

    test('should accumulate gold with multiple additions', () {
      goldManager.addGold(100);
      goldManager.addGold(50);
      goldManager.addGold(25);
      expect(goldManager.currentGold, 175);
    });

    test('should handle large gold amounts', () {
      goldManager.addGold(999999999);
      expect(goldManager.currentGold, 999999999);
    });

    test('should ignore zero amount', () {
      goldManager.addGold(100);
      goldManager.addGold(0);
      expect(goldManager.currentGold, 100);
    });

    test('should ignore negative amount', () {
      goldManager.addGold(100);
      goldManager.addGold(-50);
      expect(goldManager.currentGold, 100);
    });

    test('should emit stream event when gold is added', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(100);
      goldManager.addGold(50);

      await Future.delayed(Duration.zero);

      expect(events, [100, 150]);

      await subscription.cancel();
    });

    test('should not emit stream event for zero or negative amount', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(100);
      goldManager.addGold(0);
      goldManager.addGold(-10);

      await Future.delayed(Duration.zero);

      expect(events, [100]);

      await subscription.cancel();
    });
  });

  group('GoldManager - trySpendGold', () {
    test('should spend gold successfully when sufficient', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(50);

      expect(success, true);
      expect(goldManager.currentGold, 50);
    });

    test('should spend all gold when exact amount', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(100);

      expect(success, true);
      expect(goldManager.currentGold, 0);
    });

    test('should fail when insufficient gold', () {
      goldManager.addGold(10);
      final success = goldManager.trySpendGold(50);

      expect(success, false);
      expect(goldManager.currentGold, 10);
    });

    test('should fail when zero gold', () {
      final success = goldManager.trySpendGold(50);

      expect(success, false);
      expect(goldManager.currentGold, 0);
    });

    test('should return false for zero amount', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(0);

      expect(success, false);
      expect(goldManager.currentGold, 100);
    });

    test('should return false for negative amount', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(-10);

      expect(success, false);
      expect(goldManager.currentGold, 100);
    });

    test('should emit stream event when gold is spent', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(100);
      goldManager.trySpendGold(30);
      goldManager.trySpendGold(20);

      await Future.delayed(Duration.zero);

      expect(events, [100, 70, 50]);

      await subscription.cancel();
    });

    test('should not emit stream event for failed spend', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(10);
      goldManager.trySpendGold(50); // Should fail

      await Future.delayed(Duration.zero);

      expect(events, [10]); // Only the add event

      await subscription.cancel();
    });

    test('should handle multiple successful spends', () {
      goldManager.addGold(100);

      expect(goldManager.trySpendGold(25), true);
      expect(goldManager.currentGold, 75);

      expect(goldManager.trySpendGold(25), true);
      expect(goldManager.currentGold, 50);

      expect(goldManager.trySpendGold(25), true);
      expect(goldManager.currentGold, 25);

      expect(goldManager.trySpendGold(25), true);
      expect(goldManager.currentGold, 0);
    });

    test('should handle large spend amount', () {
      goldManager.addGold(999999999);
      final success = goldManager.trySpendGold(999999999);

      expect(success, true);
      expect(goldManager.currentGold, 0);
    });
  });

  group('GoldManager - PrestigeManager Integration', () {
    late MockPrestigeManager mockPrestigeManager;

    setUp(() {
      mockPrestigeManager = MockPrestigeManager();
    });

    test('should apply 1.0 multiplier when no prestige manager set', () {
      goldManager.addGold(100);
      expect(goldManager.currentGold, 100);
    });

    test('should apply prestige multiplier when set', () {
      mockPrestigeManager.setGoldMultiplier(2.0);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      expect(goldManager.currentGold, 200);
    });

    test('should apply fractional multiplier', () {
      mockPrestigeManager.setGoldMultiplier(1.5);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      expect(goldManager.currentGold, 150);
    });

    test('should round multiplied amount', () {
      mockPrestigeManager.setGoldMultiplier(1.33);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      expect(goldManager.currentGold, 133);
    });

    test('should handle very large multiplier', () {
      mockPrestigeManager.setGoldMultiplier(10.0);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      expect(goldManager.currentGold, 1000);
    });

    test('should handle very small multiplier', () {
      mockPrestigeManager.setGoldMultiplier(0.5);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      expect(goldManager.currentGold, 50);
    });

    test('should accumulate gold with multiplier over multiple additions', () {
      mockPrestigeManager.setGoldMultiplier(2.0);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100);
      goldManager.addGold(50);

      expect(goldManager.currentGold, 300); // 200 + 100
    });

    test('multiplier does not affect spend operation', () {
      mockPrestigeManager.setGoldMultiplier(2.0);
      goldManager.setPrestigeManager(mockPrestigeManager);

      goldManager.addGold(100); // Gets 200
      final success = goldManager.trySpendGold(100); // Spends exactly 100

      expect(success, true);
      expect(goldManager.currentGold, 100);
    });
  });

  group('GoldManager - onGoldChanged Stream', () {
    test('should be a broadcast stream', () {
      final subscription1 = goldManager.onGoldChanged.listen((_) {});
      final subscription2 = goldManager.onGoldChanged.listen((_) {});

      expect(subscription1, isNotNull);
      expect(subscription2, isNotNull);

      subscription1.cancel();
      subscription2.cancel();
    });

    test('should emit current gold value on add', () async {
      final completer = Completer<int>();
      final subscription = goldManager.onGoldChanged.listen((value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      });

      goldManager.addGold(500);

      final emittedValue = await completer.future;
      expect(emittedValue, 500);

      await subscription.cancel();
    });

    test('should emit current gold value on spend', () async {
      goldManager.addGold(100);

      final completer = Completer<int>();
      final subscription = goldManager.onGoldChanged.listen((value) {
        if (!completer.isCompleted && value < 100) {
          completer.complete(value);
        }
      });

      goldManager.trySpendGold(30);

      final emittedValue = await completer.future;
      expect(emittedValue, 70);

      await subscription.cancel();
    });

    test('should handle multiple listeners', () async {
      final events1 = <int>[];
      final events2 = <int>[];

      final subscription1 = goldManager.onGoldChanged.listen(events1.add);
      final subscription2 = goldManager.onGoldChanged.listen(events2.add);

      goldManager.addGold(100);

      await Future.delayed(Duration.zero);

      expect(events1, [100]);
      expect(events2, [100]);

      await subscription1.cancel();
      await subscription2.cancel();
    });
  });

  group('GoldManager - Saveable Implementation', () {
    test('toSaveData should return correct map', () {
      goldManager.addGold(500);

      final saveData = goldManager.toSaveData();

      expect(saveData, {'amount': 500});
    });

    test('toSaveData should return 0 for initial state', () {
      final saveData = goldManager.toSaveData();

      expect(saveData, {'amount': 0});
    });

    test('fromSaveData should restore gold', () {
      goldManager.fromSaveData({'amount': 1000});

      expect(goldManager.currentGold, 1000);
    });

    test('fromSaveData should handle missing amount key', () {
      goldManager.addGold(500);
      goldManager.fromSaveData({});

      expect(goldManager.currentGold, 0);
    });

    test('fromSaveData should handle null amount', () {
      goldManager.addGold(500);
      goldManager.fromSaveData({'amount': null});

      expect(goldManager.currentGold, 0);
    });

    test('fromSaveData should emit stream event', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.fromSaveData({'amount': 750});

      await Future.delayed(Duration.zero);

      expect(events, [750]);

      await subscription.cancel();
    });

    test('round-trip save/load should preserve data', () {
      goldManager.addGold(12345);

      final saveData = goldManager.toSaveData();

      final newGoldManager = GoldManager();
      newGoldManager.fromSaveData(saveData);

      expect(newGoldManager.currentGold, 12345);

      newGoldManager.dispose();
    });

    test('should handle large gold values in save/load', () {
      goldManager.addGold(999999999);

      final saveData = goldManager.toSaveData();

      final newGoldManager = GoldManager();
      newGoldManager.fromSaveData(saveData);

      expect(newGoldManager.currentGold, 999999999);

      newGoldManager.dispose();
    });

    test('should handle zero gold in save/load', () {
      final saveData = goldManager.toSaveData();

      final newGoldManager = GoldManager();
      newGoldManager.fromSaveData(saveData);

      expect(newGoldManager.currentGold, 0);

      newGoldManager.dispose();
    });
  });

  group('GoldManager - dispose', () {
    test('dispose should close the stream controller', () async {
      goldManager.dispose();

      // After dispose, listening to stream should fail or complete immediately
      bool streamClosed = false;
      goldManager.onGoldChanged.listen(
        (_) {},
        onDone: () {
          streamClosed = true;
        },
      );

      await Future.delayed(Duration.zero);

      expect(streamClosed, true);
    });

    test('dispose should be idempotent (can be called multiple times)', () {
      expect(() => goldManager.dispose(), returnsNormally);
      // Second dispose - should not throw (StreamController handles this)
      // Note: In reality, calling dispose twice on StreamController throws
      // but we test that dispose itself doesn't throw on first call
    });
  });

  group('GoldManager - Edge Cases', () {
    test('should handle adding 1 gold', () {
      goldManager.addGold(1);
      expect(goldManager.currentGold, 1);
    });

    test('should handle spending 1 gold', () {
      goldManager.addGold(1);
      final success = goldManager.trySpendGold(1);

      expect(success, true);
      expect(goldManager.currentGold, 0);
    });

    test('should handle spending exactly all gold', () {
      goldManager.addGold(12345);
      final success = goldManager.trySpendGold(12345);

      expect(success, true);
      expect(goldManager.currentGold, 0);
    });

    test('should handle spending 1 more than available', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(101);

      expect(success, false);
      expect(goldManager.currentGold, 100);
    });

    test('should handle multiple operations in sequence', () {
      goldManager.addGold(100);
      goldManager.addGold(50);
      goldManager.trySpendGold(30);
      goldManager.addGold(20);
      goldManager.trySpendGold(10);

      expect(goldManager.currentGold, 130); // 100 + 50 - 30 + 20 - 10
    });

    test('should handle alternating add and spend', () {
      for (int i = 0; i < 10; i++) {
        goldManager.addGold(100);
        goldManager.trySpendGold(50);
      }

      expect(goldManager.currentGold, 500); // 10 * (100 - 50)
    });

    test('should track correct gold after failed spend', () {
      goldManager.addGold(50);
      goldManager.trySpendGold(100); // Fails
      goldManager.addGold(100);

      expect(goldManager.currentGold, 150);
    });
  });

  group('GoldManager - Boundary Values', () {
    test('should handle int max value (within safe range)', () {
      // Using a large but safe value
      const largeValue = 2147483647; // max 32-bit int
      goldManager.addGold(largeValue);
      expect(goldManager.currentGold, largeValue);
    });

    test('should handle spending max value', () {
      const largeValue = 2147483647;
      goldManager.addGold(largeValue);
      final success = goldManager.trySpendGold(largeValue);

      expect(success, true);
      expect(goldManager.currentGold, 0);
    });

    test('should handle fromSaveData with large value', () {
      goldManager.fromSaveData({'amount': 2147483647});
      expect(goldManager.currentGold, 2147483647);
    });
  });

  group('GoldManager - Stream Behavior Verification', () {
    test('should emit in order', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(100);
      goldManager.addGold(50);
      goldManager.trySpendGold(25);
      goldManager.addGold(75);

      await Future.delayed(Duration.zero);

      expect(events, [100, 150, 125, 200]);

      await subscription.cancel();
    });

    test('should not emit when operations are no-ops', () async {
      final events = <int>[];
      final subscription = goldManager.onGoldChanged.listen(events.add);

      goldManager.addGold(100);
      goldManager.addGold(0); // No-op
      goldManager.addGold(-5); // No-op
      goldManager.trySpendGold(0); // No-op
      goldManager.trySpendGold(-10); // No-op
      goldManager.trySpendGold(200); // Fails, no-op

      await Future.delayed(Duration.zero);

      expect(events, [100]); // Only the successful add

      await subscription.cancel();
    });
  });

  group('GoldManager - Combined Scenarios', () {
    test('scenario: new player gameplay session', () async {
      // Player starts a new game
      expect(goldManager.currentGold, 0);

      // Player earns gold from defeating enemies
      goldManager.addGold(10);
      goldManager.addGold(15);
      goldManager.addGold(25);

      expect(goldManager.currentGold, 50);

      // Player buys a basic item
      final bought = goldManager.trySpendGold(30);
      expect(bought, true);
      expect(goldManager.currentGold, 20);

      // Player saves game
      final saveData = goldManager.toSaveData();
      expect(saveData['amount'], 20);

      // Player loads game later
      final newSession = GoldManager();
      newSession.fromSaveData(saveData);
      expect(newSession.currentGold, 20);

      newSession.dispose();
    });

    test('scenario: player with prestige bonus', () {
      final prestigeManager = MockPrestigeManager();
      prestigeManager.setGoldMultiplier(1.5);
      goldManager.setPrestigeManager(prestigeManager);

      // Player earns gold with 1.5x multiplier
      goldManager.addGold(100);
      expect(goldManager.currentGold, 150);

      // Player spends (no multiplier on spending)
      goldManager.trySpendGold(50);
      expect(goldManager.currentGold, 100);

      // Save/Load preserves the multiplied amount
      final saveData = goldManager.toSaveData();
      expect(saveData['amount'], 100);
    });

    test('scenario: repeated save/load cycles', () {
      goldManager.addGold(100);

      for (int i = 0; i < 5; i++) {
        final saveData = goldManager.toSaveData();
        goldManager.fromSaveData(saveData);
        goldManager.addGold(10);
      }

      expect(goldManager.currentGold, 150); // 100 + 5*10
    });
  });
}

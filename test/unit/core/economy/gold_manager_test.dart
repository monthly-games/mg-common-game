import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';

void main() {
  late GoldManager goldManager;

  setUp(() {
    goldManager = GoldManager();
  });

  group('GoldManager (Unit)', () {
    test('should start with 0 gold', () {
      expect(goldManager.currentGold, 0);
    });

    test('should add gold correctly', () {
      goldManager.addGold(100);
      expect(goldManager.currentGold, 100);
    });

    test('should remove gold correctly', () {
      goldManager.addGold(100);
      final success = goldManager.trySpendGold(50);

      expect(success, true);
      expect(goldManager.currentGold, 50);
    });

    test('should fail to spend if not enough gold', () {
      goldManager.addGold(10);
      final success = goldManager.trySpendGold(50);

      expect(success, false);
      expect(goldManager.currentGold, 10); // Unchanged
    });

    test('should notify listeners on change', () async {
      // Expecting 2 events: Initial 0 (maybe?) or just updates.
      // Usually StreamControllers don't emit initial unless BehaviorSubject.
      // Let's assume onGoldChanged emits the NEW value.

      expectLater(goldManager.onGoldChanged, emitsInOrder([100, 50]));

      goldManager.addGold(100);
      goldManager.trySpendGold(50);
    });
  });
}

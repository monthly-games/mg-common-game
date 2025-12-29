import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/systems/currency.dart';
import 'package:mg_common_game/core/systems/economy_system.dart';

void main() {
  late EventBus eventBus;
  late EconomySystem economySystem;

  setUp(() {
    eventBus = EventBus();
    economySystem = EconomySystem(eventBus);
  });

  tearDown(() {
    eventBus.dispose();
  });

  group('EconomySystem - Initialization', () {
    test('should start with zero balance for all currency types', () {
      expect(economySystem.getBalance(CurrencyType.gold), 0);
      expect(economySystem.getBalance(CurrencyType.gem), 0);
      expect(economySystem.getBalance(CurrencyType.energy), 0);
    });

    test('should start with zero balance for custom currency', () {
      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 0);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'stars'), 0);
    });
  });

  group('EconomySystem - getBalance', () {
    test('should return 0 for uninitialized currency', () {
      expect(economySystem.getBalance(CurrencyType.gold), 0);
    });

    test('should return correct balance after adding currency', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      expect(economySystem.getBalance(CurrencyType.gold), 100);
    });

    test('should throw ArgumentError when getting custom currency without id', () {
      expect(
        () => economySystem.getBalance(CurrencyType.custom),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when getting custom currency with empty id', () {
      expect(
        () => economySystem.getBalance(CurrencyType.custom, id: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return correct balance for custom currency with valid id', () {
      economySystem.addCurrency(CurrencyType.custom, 50, id: 'tokens');
      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 50);
    });

    test('should track different custom currencies separately', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'tokens');
      economySystem.addCurrency(CurrencyType.custom, 200, id: 'stars');

      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 100);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'stars'), 200);
    });
  });

  group('EconomySystem - addCurrency', () {
    test('should add currency to balance', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      expect(economySystem.getBalance(CurrencyType.gold), 100);
    });

    test('should accumulate multiple additions', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.gold, 50);
      economySystem.addCurrency(CurrencyType.gold, 25);

      expect(economySystem.getBalance(CurrencyType.gold), 175);
    });

    test('should throw ArgumentError for negative amount', () {
      expect(
        () => economySystem.addCurrency(CurrencyType.gold, -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should allow adding zero amount', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.gold, 0);

      expect(economySystem.getBalance(CurrencyType.gold), 100);
    });

    test('should add currency to different types independently', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.gem, 50);
      economySystem.addCurrency(CurrencyType.energy, 25);

      expect(economySystem.getBalance(CurrencyType.gold), 100);
      expect(economySystem.getBalance(CurrencyType.gem), 50);
      expect(economySystem.getBalance(CurrencyType.energy), 25);
    });

    test('should throw ArgumentError when adding custom currency without id', () {
      expect(
        () => economySystem.addCurrency(CurrencyType.custom, 100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when adding custom currency with empty id', () {
      expect(
        () => economySystem.addCurrency(CurrencyType.custom, 100, id: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should add custom currency with valid id', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'tokens');
      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 100);
    });

    test('should handle large amounts', () {
      economySystem.addCurrency(CurrencyType.gold, 1000000000);
      expect(economySystem.getBalance(CurrencyType.gold), 1000000000);
    });
  });

  group('EconomySystem - consumeCurrency', () {
    test('should consume currency when sufficient balance', () {
      economySystem.addCurrency(CurrencyType.gold, 100);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 50);

      expect(result, true);
      expect(economySystem.getBalance(CurrencyType.gold), 50);
    });

    test('should consume exact balance', () {
      economySystem.addCurrency(CurrencyType.gold, 100);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 100);

      expect(result, true);
      expect(economySystem.getBalance(CurrencyType.gold), 0);
    });

    test('should fail when insufficient balance', () {
      economySystem.addCurrency(CurrencyType.gold, 50);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 100);

      expect(result, false);
      expect(economySystem.getBalance(CurrencyType.gold), 50);
    });

    test('should fail when balance is zero', () {
      final result = economySystem.consumeCurrency(CurrencyType.gold, 10);

      expect(result, false);
      expect(economySystem.getBalance(CurrencyType.gold), 0);
    });

    test('should throw ArgumentError for negative amount', () {
      economySystem.addCurrency(CurrencyType.gold, 100);

      expect(
        () => economySystem.consumeCurrency(CurrencyType.gold, -10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should allow consuming zero amount', () {
      economySystem.addCurrency(CurrencyType.gold, 100);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 0);

      expect(result, true);
      expect(economySystem.getBalance(CurrencyType.gold), 100);
    });

    test('should consume from correct currency type', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.gem, 50);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 30);

      expect(result, true);
      expect(economySystem.getBalance(CurrencyType.gold), 70);
      expect(economySystem.getBalance(CurrencyType.gem), 50);
    });

    test('should throw ArgumentError when consuming custom currency without id', () {
      expect(
        () => economySystem.consumeCurrency(CurrencyType.custom, 10),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should consume custom currency with valid id', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'tokens');

      final result = economySystem.consumeCurrency(CurrencyType.custom, 30, id: 'tokens');

      expect(result, true);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 70);
    });

    test('should handle multiple consecutive consume operations', () {
      economySystem.addCurrency(CurrencyType.gold, 100);

      expect(economySystem.consumeCurrency(CurrencyType.gold, 25), true);
      expect(economySystem.consumeCurrency(CurrencyType.gold, 25), true);
      expect(economySystem.consumeCurrency(CurrencyType.gold, 25), true);
      expect(economySystem.consumeCurrency(CurrencyType.gold, 25), true);
      expect(economySystem.consumeCurrency(CurrencyType.gold, 1), false);

      expect(economySystem.getBalance(CurrencyType.gold), 0);
    });
  });

  group('EconomySystem - Custom Currency', () {
    test('should handle multiple custom currencies independently', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'tokens');
      economySystem.addCurrency(CurrencyType.custom, 200, id: 'stars');
      economySystem.addCurrency(CurrencyType.custom, 300, id: 'coins');

      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 100);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'stars'), 200);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'coins'), 300);
    });

    test('should consume from correct custom currency', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'tokens');
      economySystem.addCurrency(CurrencyType.custom, 200, id: 'stars');

      economySystem.consumeCurrency(CurrencyType.custom, 50, id: 'tokens');

      expect(economySystem.getBalance(CurrencyType.custom, id: 'tokens'), 50);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'stars'), 200);
    });

    test('should not affect standard currencies when using custom', () {
      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'gold');

      expect(economySystem.getBalance(CurrencyType.gold), 100);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'gold'), 100);
    });
  });

  group('EconomySystem - CurrencyUpdatedEvent', () {
    test('should emit event when adding currency', () async {
      final completer = Completer<CurrencyUpdatedEvent>();
      eventBus.on<CurrencyUpdatedEvent>().first.then(completer.complete);

      economySystem.addCurrency(CurrencyType.gold, 100);

      final event = await completer.future.timeout(Duration(seconds: 1));

      expect(event.type, CurrencyType.gold);
      expect(event.change, 100);
      expect(event.newAmount, 100);
      expect(event.customId, isNull);
    });

    test('should emit event when consuming currency', () async {
      economySystem.addCurrency(CurrencyType.gold, 100);

      final completer = Completer<CurrencyUpdatedEvent>();
      eventBus.on<CurrencyUpdatedEvent>().first.then(completer.complete);

      economySystem.consumeCurrency(CurrencyType.gold, 30);

      final event = await completer.future.timeout(Duration(seconds: 1));

      expect(event.type, CurrencyType.gold);
      expect(event.change, -30);
      expect(event.newAmount, 70);
    });

    test('should emit event with customId for custom currency', () async {
      final completer = Completer<CurrencyUpdatedEvent>();
      eventBus.on<CurrencyUpdatedEvent>().first.then(completer.complete);

      economySystem.addCurrency(CurrencyType.custom, 50, id: 'tokens');

      final event = await completer.future.timeout(Duration(seconds: 1));

      expect(event.type, CurrencyType.custom);
      expect(event.change, 50);
      expect(event.newAmount, 50);
      expect(event.customId, 'tokens');
    });

    test('should emit events for each currency operation', () async {
      final events = <CurrencyUpdatedEvent>[];
      final subscription = eventBus.on<CurrencyUpdatedEvent>().listen(events.add);

      economySystem.addCurrency(CurrencyType.gold, 100);
      economySystem.addCurrency(CurrencyType.gold, 50);
      economySystem.consumeCurrency(CurrencyType.gold, 25);

      await Future.delayed(Duration(milliseconds: 50));

      expect(events.length, 3);

      expect(events[0].change, 100);
      expect(events[0].newAmount, 100);

      expect(events[1].change, 50);
      expect(events[1].newAmount, 150);

      expect(events[2].change, -25);
      expect(events[2].newAmount, 125);

      await subscription.cancel();
    });

    test('should not emit event when consume fails', () async {
      final events = <CurrencyUpdatedEvent>[];
      final subscription = eventBus.on<CurrencyUpdatedEvent>().listen(events.add);

      final result = economySystem.consumeCurrency(CurrencyType.gold, 100);

      await Future.delayed(Duration(milliseconds: 50));

      expect(result, false);
      expect(events.length, 0);

      await subscription.cancel();
    });
  });

  group('EconomySystem - Edge Cases', () {
    test('should handle very large numbers', () {
      const largeAmount = 9007199254740991; // Max safe integer
      economySystem.addCurrency(CurrencyType.gold, largeAmount);

      expect(economySystem.getBalance(CurrencyType.gold), largeAmount);
    });

    test('should handle special characters in custom currency id', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: 'special-currency_v2.0');

      expect(
        economySystem.getBalance(CurrencyType.custom, id: 'special-currency_v2.0'),
        100,
      );
    });

    test('should handle unicode in custom currency id', () {
      economySystem.addCurrency(CurrencyType.custom, 100, id: '골드토큰');

      expect(economySystem.getBalance(CurrencyType.custom, id: '골드토큰'), 100);
    });

    test('should handle consume after failed consume', () {
      economySystem.addCurrency(CurrencyType.gold, 50);

      final failedResult = economySystem.consumeCurrency(CurrencyType.gold, 100);
      expect(failedResult, false);
      expect(economySystem.getBalance(CurrencyType.gold), 50);

      final successResult = economySystem.consumeCurrency(CurrencyType.gold, 50);
      expect(successResult, true);
      expect(economySystem.getBalance(CurrencyType.gold), 0);
    });

    test('should handle rapid add and consume operations', () {
      for (var i = 0; i < 100; i++) {
        economySystem.addCurrency(CurrencyType.gold, 10);
      }

      expect(economySystem.getBalance(CurrencyType.gold), 1000);

      for (var i = 0; i < 50; i++) {
        economySystem.consumeCurrency(CurrencyType.gold, 10);
      }

      expect(economySystem.getBalance(CurrencyType.gold), 500);
    });

    test('should handle all currency types', () {
      for (final type in CurrencyType.values) {
        if (type == CurrencyType.custom) {
          economySystem.addCurrency(type, 100, id: 'test-${type.name}');
          expect(economySystem.getBalance(type, id: 'test-${type.name}'), 100);
        } else {
          economySystem.addCurrency(type, 100);
          expect(economySystem.getBalance(type), 100);
        }
      }
    });
  });

  group('EconomySystem - Integration Scenarios', () {
    test('should simulate purchase flow', () {
      // Initial setup
      economySystem.addCurrency(CurrencyType.gold, 1000);
      economySystem.addCurrency(CurrencyType.gem, 100);

      // Purchase item costing 500 gold
      final goldPurchase = economySystem.consumeCurrency(CurrencyType.gold, 500);
      expect(goldPurchase, true);
      expect(economySystem.getBalance(CurrencyType.gold), 500);

      // Try to purchase expensive item
      final expensivePurchase = economySystem.consumeCurrency(CurrencyType.gold, 1000);
      expect(expensivePurchase, false);
      expect(economySystem.getBalance(CurrencyType.gold), 500);

      // Gems should be unaffected
      expect(economySystem.getBalance(CurrencyType.gem), 100);
    });

    test('should simulate reward flow', () {
      // Complete quest - receive multiple rewards
      economySystem.addCurrency(CurrencyType.gold, 500);
      economySystem.addCurrency(CurrencyType.gem, 10);
      economySystem.addCurrency(CurrencyType.custom, 5, id: 'questToken');

      expect(economySystem.getBalance(CurrencyType.gold), 500);
      expect(economySystem.getBalance(CurrencyType.gem), 10);
      expect(economySystem.getBalance(CurrencyType.custom, id: 'questToken'), 5);
    });

    test('should simulate energy system', () {
      // Full energy
      economySystem.addCurrency(CurrencyType.energy, 100);

      // Play game 5 times (20 energy each)
      for (var i = 0; i < 5; i++) {
        final result = economySystem.consumeCurrency(CurrencyType.energy, 20);
        expect(result, true);
      }

      expect(economySystem.getBalance(CurrencyType.energy), 0);

      // Cannot play anymore
      final result = economySystem.consumeCurrency(CurrencyType.energy, 20);
      expect(result, false);

      // Refill energy
      economySystem.addCurrency(CurrencyType.energy, 100);
      expect(economySystem.getBalance(CurrencyType.energy), 100);
    });
  });

  group('CurrencyUpdatedEvent', () {
    test('should create event with all required fields', () {
      final event = CurrencyUpdatedEvent(
        type: CurrencyType.gold,
        newAmount: 100,
        change: 50,
      );

      expect(event.type, CurrencyType.gold);
      expect(event.newAmount, 100);
      expect(event.change, 50);
      expect(event.customId, isNull);
    });

    test('should create event with customId', () {
      final event = CurrencyUpdatedEvent(
        type: CurrencyType.custom,
        newAmount: 100,
        change: 50,
        customId: 'tokens',
      );

      expect(event.type, CurrencyType.custom);
      expect(event.customId, 'tokens');
    });

    test('should allow negative change value', () {
      final event = CurrencyUpdatedEvent(
        type: CurrencyType.gold,
        newAmount: 50,
        change: -50,
      );

      expect(event.change, -50);
    });
  });
}

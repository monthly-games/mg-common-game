import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/systems/currency.dart';
import 'package:mg_common_game/core/systems/economy_system.dart';

void main() {
  late EventBus bus;
  late EconomySystem system;

  setUp(() {
    bus = EventBus();
    system = EconomySystem(bus);
  });

  group('EconomySystem', () {
    test('starts with 0 balance', () {
      expect(system.getBalance(CurrencyType.gold), 0);
    });

    test('addCurrency increases balance', () {
      system.addCurrency(CurrencyType.gold, 100);
      expect(system.getBalance(CurrencyType.gold), 100);
    });

    test('consumeCurrency decreases balance if sufficient', () {
      system.addCurrency(CurrencyType.gem, 50);

      final success = system.consumeCurrency(CurrencyType.gem, 30);
      expect(success, true);
      expect(system.getBalance(CurrencyType.gem), 20);
    });

    test('consumeCurrency fails if insufficient', () {
      system.addCurrency(CurrencyType.gem, 10);

      final success = system.consumeCurrency(CurrencyType.gem, 20);
      expect(success, false);
      expect(system.getBalance(CurrencyType.gem), 10);
    });

    test('custom currency requires ID', () {
      expect(() => system.addCurrency(CurrencyType.custom, 10),
          throwsArgumentError);
      expect(() => system.addCurrency(CurrencyType.custom, 10, id: 'token'),
          returnsNormally);
      expect(system.getBalance(CurrencyType.custom, id: 'token'), 10);
    });

    test('emits CurrencyUpdatedEvent', () {
      expectLater(
        bus.on<CurrencyUpdatedEvent>(),
        emits(predicate<CurrencyUpdatedEvent>((e) =>
            e.type == CurrencyType.gold &&
            e.change == 100 &&
            e.newAmount == 100)),
      );
      system.addCurrency(CurrencyType.gold, 100);
    });
  });
}

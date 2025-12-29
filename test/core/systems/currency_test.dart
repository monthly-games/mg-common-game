import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/systems/currency.dart';

void main() {
  group('CurrencyType', () {
    test('has all required values', () {
      expect(CurrencyType.values.length, 4);
      expect(CurrencyType.gold, isNotNull);
      expect(CurrencyType.gem, isNotNull);
      expect(CurrencyType.energy, isNotNull);
      expect(CurrencyType.custom, isNotNull);
    });
  });

  group('Currency', () {
    test('creates with default values', () {
      const currency = Currency(type: CurrencyType.gold);

      expect(currency.type, CurrencyType.gold);
      expect(currency.amount, 0);
      expect(currency.id, '');
    });

    test('creates with specified values', () {
      const currency = Currency(
        type: CurrencyType.gem,
        amount: 100,
        id: 'premium_gem',
      );

      expect(currency.type, CurrencyType.gem);
      expect(currency.amount, 100);
      expect(currency.id, 'premium_gem');
    });

    test('creates gold currency correctly', () {
      const gold = Currency(type: CurrencyType.gold, amount: 1000);

      expect(gold.type, CurrencyType.gold);
      expect(gold.amount, 1000);
    });

    test('creates gem currency correctly', () {
      const gem = Currency(type: CurrencyType.gem, amount: 50);

      expect(gem.type, CurrencyType.gem);
      expect(gem.amount, 50);
    });

    test('creates energy currency correctly', () {
      const energy = Currency(type: CurrencyType.energy, amount: 10);

      expect(energy.type, CurrencyType.energy);
      expect(energy.amount, 10);
    });

    test('creates custom currency correctly', () {
      const custom = Currency(
        type: CurrencyType.custom,
        id: 'seasonal_token',
        amount: 25,
      );

      expect(custom.type, CurrencyType.custom);
      expect(custom.id, 'seasonal_token');
      expect(custom.amount, 25);
    });

    group('copyWith', () {
      test('copies with new type', () {
        const original = Currency(type: CurrencyType.gold, amount: 100);
        final copied = original.copyWith(type: CurrencyType.gem);

        expect(copied.type, CurrencyType.gem);
        expect(copied.amount, 100);
        expect(copied.id, '');
      });

      test('copies with new amount', () {
        const original = Currency(type: CurrencyType.gold, amount: 100);
        final copied = original.copyWith(amount: 500);

        expect(copied.type, CurrencyType.gold);
        expect(copied.amount, 500);
      });

      test('copies with new id', () {
        const original = Currency(
          type: CurrencyType.custom,
          id: 'old_id',
          amount: 100,
        );
        final copied = original.copyWith(id: 'new_id');

        expect(copied.type, CurrencyType.custom);
        expect(copied.id, 'new_id');
        expect(copied.amount, 100);
      });

      test('copies with multiple fields', () {
        const original = Currency(type: CurrencyType.gold, amount: 100);
        final copied = original.copyWith(
          type: CurrencyType.gem,
          amount: 200,
          id: 'test',
        );

        expect(copied.type, CurrencyType.gem);
        expect(copied.amount, 200);
        expect(copied.id, 'test');
      });

      test('returns same values when no parameters provided', () {
        const original = Currency(
          type: CurrencyType.custom,
          id: 'test',
          amount: 50,
        );
        final copied = original.copyWith();

        expect(copied.type, original.type);
        expect(copied.id, original.id);
        expect(copied.amount, original.amount);
      });
    });
  });
}

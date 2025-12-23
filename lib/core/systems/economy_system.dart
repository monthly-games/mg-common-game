import 'package:injectable/injectable.dart';
import 'package:mg_common_game/core/engine/event_bus.dart';
import 'package:mg_common_game/core/systems/currency.dart';

class CurrencyUpdatedEvent {
  final CurrencyType type;
  final int newAmount;
  final int change;
  final String? customId;

  CurrencyUpdatedEvent({
    required this.type,
    required this.newAmount,
    required this.change,
    this.customId,
  });
}

@singleton
class EconomySystem {
  final EventBus _eventBus;

  // Store balances. Key is "type" or "type:id" for custom.
  final Map<String, int> _balances = {};

  EconomySystem(this._eventBus);

  String _getKey(CurrencyType type, String? id) {
    if (type == CurrencyType.custom) {
      if (id == null || id.isEmpty)
        throw ArgumentError('Custom currency requires ID');
      return 'custom:$id';
    }
    return type.name;
  }

  int getBalance(CurrencyType type, {String? id}) {
    final key = _getKey(type, id);
    return _balances[key] ?? 0;
  }

  void addCurrency(CurrencyType type, int amount, {String? id}) {
    if (amount < 0) throw ArgumentError('Amount must be positive');
    _updateBalance(type, amount, id: id);
  }

  bool consumeCurrency(CurrencyType type, int amount, {String? id}) {
    if (amount < 0) throw ArgumentError('Amount must be positive');
    final current = getBalance(type, id: id);
    if (current < amount) return false;

    _updateBalance(type, -amount, id: id);
    return true;
  }

  void _updateBalance(CurrencyType type, int change, {String? id}) {
    final key = _getKey(type, id);
    final current = _balances[key] ?? 0;
    final newAmount = current + change;
    _balances[key] = newAmount;

    _eventBus.fire(CurrencyUpdatedEvent(
      type: type,
      newAmount: newAmount,
      change: change,
      customId: id,
    ));
  }
}

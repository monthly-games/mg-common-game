enum CurrencyType {
  gold,
  gem,
  energy,
  custom,
}

class Currency {
  final CurrencyType type;
  final String id; // For custom currency
  final int amount;

  const Currency({
    required this.type,
    this.amount = 0,
    this.id = '',
  });

  Currency copyWith({
    CurrencyType? type,
    String? id,
    int? amount,
  }) {
    return Currency(
      type: type ?? this.type,
      id: id ?? this.id,
      amount: amount ?? this.amount,
    );
  }
}

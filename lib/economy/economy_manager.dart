import 'dart:async';
import 'package:flutter/material.dart';

enum CurrencyType {
  premium,
  basic,
  special,
  event,
  guild,
}

enum TransactionType {
  earn,
  spend,
  transfer,
  purchase,
  refund,
  reward,
  penalty,
  exchange,
  tax,
  bonus,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
}

class Currency {
  final String currencyId;
  final String name;
  final String symbol;
  final CurrencyType type;
  final String icon;
  final int maxBalance;
  final bool isTradeable;
  final bool isPurchasable;
  final Map<String, dynamic> metadata;

  const Currency({
    required this.currencyId,
    required this.name,
    required this.symbol,
    required this.type,
    required this.icon,
    required this.maxBalance,
    required this.isTradeable,
    required this.isPurchasable,
    required this.metadata,
  });
}

class Transaction {
  final String transactionId;
  final String currencyId;
  final TransactionType type;
  final TransactionStatus status;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String? userId;
  final String? description;
  final DateTime timestamp;
  final String? relatedTransactionId;
  final Map<String, dynamic> metadata;

  const Transaction({
    required this.transactionId,
    required this.currencyId,
    required this.type,
    required this.status,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.userId,
    this.description,
    required this.timestamp,
    this.relatedTransactionId,
    required this.metadata,
  });
}

class ExchangeRate {
  final String fromCurrencyId;
  final String toCurrencyId;
  final double rate;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int minAmount;
  final int maxAmount;
  final double feePercentage;

  const ExchangeRate({
    required this.fromCurrencyId,
    required this.toCurrencyId,
    required this.rate,
    this.validFrom,
    this.validUntil,
    required this.minAmount,
    required this.maxAmount,
    required this.feePercentage,
  });

  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    return true;
  }
}

class EconomyManager {
  static final EconomyManager _instance = EconomyManager._();
  static EconomyManager get instance => _instance;

  EconomyManager._();

  final Map<String, Currency> _currencies = {};
  final Map<String, Map<String, int>> _balances = {};
  final Map<String, List<Transaction>> _transactions = {};
  final Map<String, ExchangeRate> _exchangeRates = {};
  final StreamController<EconomyEvent> _eventController = StreamController.broadcast();

  Stream<EconomyEvent> get onEconomyEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultCurrencies();
    await _loadDefaultExchangeRates();
  }

  Future<void> _loadDefaultCurrencies() async {
    final currencies = [
      Currency(
        currencyId: 'gold',
        name: 'Gold',
        symbol: 'G',
        type: CurrencyType.basic,
        icon: 'gold_icon',
        maxBalance: 999999999,
        isTradeable: true,
        isPurchasable: false,
        metadata: {},
      ),
      Currency(
        currencyId: 'gems',
        name: 'Gems',
        symbol: '💎',
        type: CurrencyType.premium,
        icon: 'gems_icon',
        maxBalance: 999999,
        isTradeable: false,
        isPurchasable: true,
        metadata: {},
      ),
      Currency(
        currencyId: 'coins',
        name: 'Coins',
        symbol: 'C',
        type: CurrencyType.special,
        icon: 'coins_icon',
        maxBalance: 99999,
        isTradeable: false,
        isPurchasable: true,
        metadata: {},
      ),
    ];

    for (final currency in currencies) {
      _currencies[currency.currencyId] = currency;
    }
  }

  Future<void> _loadDefaultExchangeRates() async {
    final rates = [
      ExchangeRate(
        fromCurrencyId: 'gems',
        toCurrencyId: 'gold',
        rate: 100.0,
        minAmount: 1,
        maxAmount: 10000,
        feePercentage: 0.0,
      ),
      ExchangeRate(
        fromCurrencyId: 'coins',
        toCurrencyId: 'gold',
        rate: 1000.0,
        minAmount: 1,
        maxAmount: 1000,
        feePercentage: 0.0,
      ),
    ];

    for (final rate in rates) {
      _exchangeRates['${rate.fromCurrencyId}_${rate.toCurrencyId}'] = rate;
    }
  }

  int getBalance(String userId, String currencyId) {
    final userBalances = _balances[userId];
    if (userBalances == null) return 0;
    return userBalances[currencyId] ?? 0;
  }

  Map<String, int> getAllBalances(String userId) {
    return Map<String, int>.from(_balances[userId] ?? {});
  }

  Future<Transaction?> addCurrency({
    required String userId,
    required String currencyId,
    required int amount,
    TransactionType type = TransactionType.earn,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return null;

    final currency = _currencies[currencyId];
    if (currency == null) return null;

    _balances.putIfAbsent(userId, () => {});
    final balanceBefore = _balances[userId]![currencyId] ?? 0;
    final balanceAfter = balanceBefore + amount;

    if (balanceAfter > currency.maxBalance) {
      _eventController.add(EconomyEvent(
        type: EconomyEventType.transactionFailed,
        currencyId: currencyId,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'reason': 'max_balance_exceeded'},
      ));
      return null;
    }

    _balances[userId]![currencyId] = balanceAfter;

    final transaction = Transaction(
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      currencyId: currencyId,
      type: type,
      status: TransactionStatus.completed,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      userId: userId,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _addTransaction(userId, transaction);

    _eventController.add(EconomyEvent(
      type: EconomyEventType.currencyAdded,
      currencyId: currencyId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'amount': amount, 'balance': balanceAfter},
    ));

    return transaction;
  }

  Future<Transaction?> spendCurrency({
    required String userId,
    required String currencyId,
    required int amount,
    TransactionType type = TransactionType.spend,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return null;

    final currency = _currencies[currencyId];
    if (currency == null) return null;

    _balances.putIfAbsent(userId, () => {});
    final balanceBefore = _balances[userId]![currencyId] ?? 0;

    if (balanceBefore < amount) {
      _eventController.add(EconomyEvent(
        type: EconomyEventType.transactionFailed,
        currencyId: currencyId,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'reason': 'insufficient_funds'},
      ));
      return null;
    }

    final balanceAfter = balanceBefore - amount;
    _balances[userId]![currencyId] = balanceAfter;

    final transaction = Transaction(
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      currencyId: currencyId,
      type: type,
      status: TransactionStatus.completed,
      amount: -amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      userId: userId,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _addTransaction(userId, transaction);

    _eventController.add(EconomyEvent(
      type: EconomyEventType.currencySpent,
      currencyId: currencyId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'amount': amount, 'balance': balanceAfter},
    ));

    return transaction;
  }

  Future<bool> transferCurrency({
    required String fromUserId,
    required String toUserId,
    required String currencyId,
    required int amount,
    String? description,
  }) async {
    if (amount <= 0) return false;

    final currency = _currencies[currencyId];
    if (currency == null) return false;
    if (!currency.isTradeable) return false;

    final fromBalance = getBalance(fromUserId, currencyId);
    if (fromBalance < amount) return false;

    final fromTransaction = await spendCurrency(
      userId: fromUserId,
      currencyId: currencyId,
      amount: amount,
      type: TransactionType.transfer,
      description: description ?? 'Transfer to $toUserId',
    );

    if (fromTransaction == null) return false;

    await addCurrency(
      userId: toUserId,
      currencyId: currencyId,
      amount: amount,
      type: TransactionType.transfer,
      description: description ?? 'Transfer from $fromUserId',
    );

    return true;
  }

  Future<int?> exchangeCurrency({
    required String userId,
    required String fromCurrencyId,
    required String toCurrencyId,
    required int amount,
  }) async {
    if (amount <= 0) return null;

    final rateKey = '${fromCurrencyId}_$toCurrencyId';
    final exchangeRate = _exchangeRates[rateKey];
    if (exchangeRate == null) return null;
    if (!exchangeRate.isValid) return null;
    if (amount < exchangeRate.minAmount || amount > exchangeRate.maxAmount) return null;

    final fromBalance = getBalance(userId, fromCurrencyId);
    if (fromBalance < amount) return null;

    final toAmount = (amount * exchangeRate.rate).floor();
    final fee = (toAmount * exchangeRate.feePercentage / 100).floor();
    final finalAmount = toAmount - fee;

    final spent = await spendCurrency(
      userId: userId,
      currencyId: fromCurrencyId,
      amount: amount,
      type: TransactionType.exchange,
      description: 'Exchange to $toCurrencyId',
    );

    if (spent == null) return null;

    await addCurrency(
      userId: userId,
      currencyId: toCurrencyId,
      amount: finalAmount,
      type: TransactionType.exchange,
      description: 'Exchange from $fromCurrencyId',
      metadata: {'fromAmount': amount, 'fee': fee},
    );

    return finalAmount;
  }

  void _addTransaction(String userId, Transaction transaction) {
    _transactions.putIfAbsent(userId, () => []);
    _transactions[userId]!.insert(0, transaction);

    if (_transactions[userId]!.length > 1000) {
      _transactions[userId]!.removeLast();
    }
  }

  List<Transaction> getTransactions(String userId, {String? currencyId, int limit = 100}) {
    final transactions = _transactions[userId] ?? [];
    var filtered = transactions;

    if (currencyId != null) {
      filtered = filtered.where((t) => t.currencyId == currencyId).toList();
    }

    if (filtered.length > limit) {
      return filtered.sublist(0, limit);
    }

    return filtered;
  }

  Currency? getCurrency(String currencyId) {
    return _currencies[currencyId];
  }

  List<Currency> getAllCurrencies() {
    return _currencies.values.toList();
  }

  ExchangeRate? getExchangeRate(String fromCurrencyId, String toCurrencyId) {
    return _exchangeRates['${fromCurrencyId}_$toCurrencyId'];
  }

  int calculateExchangeAmount(String fromCurrencyId, String toCurrencyId, int amount) {
    final rate = getExchangeRate(fromCurrencyId, toCurrencyId);
    if (rate == null || !rate.isValid) return 0;

    final toAmount = (amount * rate.rate).floor();
    final fee = (toAmount * rate.feePercentage / 100).floor();
    return toAmount - fee;
  }

  Map<String, dynamic> getEconomyStats(String userId) {
    final balances = getAllBalances(userId);
    final transactions = getTransactions(userId);

    return {
      'balances': balances,
      'totalTransactions': transactions.length,
      'currencies': _currencies.length,
      'lastTransaction': transactions.isNotEmpty ? transactions.first.timestamp.toIso8601String() : null,
    };
  }

  void dispose() {
    _eventController.close();
  }
}

class EconomyEvent {
  final EconomyEventType type;
  final String? currencyId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const EconomyEvent({
    required this.type,
    this.currencyId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum EconomyEventType {
  currencyAdded,
  currencySpent,
  currencyTransferred,
  currencyExchanged,
  transactionFailed,
  balanceInsufficient,
  maxBalanceReached,
  exchangeRateChanged,
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 화폐 유형
enum CurrencyType {
  coin,
  gem,
  star,
  ticket,
}

/// 화폐 변동 이유/출처
enum TransactionSource {
  daily_quest,
  achievement,
  purchase,
  reward,
  penalty,
  event,
  custom,
}

/// 통화 시스템 관리자
/// 여러 화폐(코인, 보석, 별 등)를 통합 관리합니다.
class CurrencyManager extends ChangeNotifier {
  static final CurrencyManager _instance = CurrencyManager._();
  static CurrencyManager get instance => _instance;

  CurrencyManager._();

  SharedPreferences? _prefs;
  final Map<CurrencyType, int> _balances = {};
  final Map<CurrencyType, StreamController<int>> _controllers = {};
  bool _isInitialized = false;

  // ============================================
  // Getters
  // ============================================

  bool get isInitialized => _isInitialized;

  /// 특정 화폐 잔액 조회
  int getBalance(CurrencyType type) {
    return _balances[type] ?? 0;
  }

  /// 코인 잔액
  int get coins => getBalance(CurrencyType.coin);

  /// 보석 잔액
  int get gems => getBalance(CurrencyType.gem);

  /// 별 잔액
  int get stars => getBalance(CurrencyType.star);

  /// 티켓 잔액
  int get tickets => getBalance(CurrencyType.ticket);

  /// 특정 화폐 변경 스트림
  Stream<int> getBalanceStream(CurrencyType type) {
    if (!_controllers.containsKey(type)) {
      _controllers[type] = StreamController<int>.broadcast();
    }
    return _controllers[type]!.stream;
  }

  /// 코인 변경 스트림
  Stream<int> get onCoinsChanged => getBalanceStream(CurrencyType.coin);

  /// 보석 변경 스트림
  Stream<int> get onGemsChanged => getBalanceStream(CurrencyType.gem);

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadBalances();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadBalances() async {
    for (final type in CurrencyType.values) {
      final key = _getBalanceKey(type);
      final balance = _prefs!.getInt(key) ?? 0;
      _balances[type] = balance;
    }
  }

  String _getBalanceKey(CurrencyType type) => 'currency_${type.name}';

  // ============================================
  // 화폐 조작
  // ============================================

  /// 화폐 추가
  Future<bool> addCurrency(
    CurrencyType type,
    int amount, {
    String? source,
    TransactionSource transactionSource = TransactionSource.custom,
  }) async {
    if (amount <= 0) return false;

    final currentBalance = getBalance(type);
    final newBalance = currentBalance + amount;

    _balances[type] = newBalance;
    await _saveBalance(type, newBalance);

    // 변경 알림
    _notifyBalanceChanged(type, newBalance);
    notifyListeners();

    // 로그 출력 (debug mode)
    if (kDebugMode) {
      final sourceStr = source ?? transactionSource.name;
      debugPrint('[Currency] +$amount ${type.name} (source: $sourceStr)');
    }

    return true;
  }

  /// 화폐 차감
  Future<bool> spendCurrency(
    CurrencyType type,
    int amount, {
    String? source,
    TransactionSource transactionSource = TransactionSource.custom,
  }) async {
    if (amount <= 0) return false;

    final currentBalance = getBalance(type);
    if (currentBalance < amount) {
      if (kDebugMode) {
        debugPrint('[Currency] Insufficient ${type.name}: need $amount, have $currentBalance');
      }
      return false;
    }

    final newBalance = currentBalance - amount;
    _balances[type] = newBalance;
    await _saveBalance(type, newBalance);

    // 변경 알림
    _notifyBalanceChanged(type, newBalance);
    notifyListeners();

    // 로그 출력
    if (kDebugMode) {
      final sourceStr = source ?? transactionSource.name;
      debugPrint('[Currency] -$amount ${type.name} (source: $sourceStr)');
    }

    return true;
  }

  /// 화폐 설정 (직접 설정 - 주의 필요)
  Future<bool> setCurrency(
    CurrencyType type,
    int amount, {
    String? source,
  }) async {
    if (amount < 0) return false;

    _balances[type] = amount;
    await _saveBalance(type, amount);

    _notifyBalanceChanged(type, amount);
    notifyListeners();

    if (kDebugMode && source != null) {
      debugPrint('[Currency] Set ${type.name} to $amount (source: $source)');
    }

    return true;
  }

  /// 화폐 전체 초기화
  Future<void> resetAllBalances() async {
    for (final type in CurrencyType.values) {
      _balances[type] = 0;
      await _saveBalance(type, 0);
      _notifyBalanceChanged(type, 0);
    }

    notifyListeners();

    if (kDebugMode) {
      debugPrint('[Currency] All balances reset');
    }
  }

  /// 특정 화폐만 초기화
  Future<void> resetBalance(CurrencyType type) async {
    _balances[type] = 0;
    await _saveBalance(type, 0);
    _notifyBalanceChanged(type, 0);

    notifyListeners();
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 잔액 충분 여부 확인
  bool hasEnough(CurrencyType type, int amount) {
    return getBalance(type) >= amount;
  }

  /// 여러 화폐 잔액 한 번에 확인
  bool hasEnoughMultiple(Map<CurrencyType, int> requirements) {
    for (final entry in requirements.entries) {
      if (!hasEnough(entry.key, entry.value)) {
        return false;
      }
    }
    return true;
  }

  /// 모든 화폐 잔액 Map 반환
  Map<CurrencyType, int> getAllBalances() {
    return Map.unmodifiable(_balances);
  }

  // ============================================
  // 내부 헬퍼 메서드
  // ============================================

  Future<void> _saveBalance(CurrencyType type, int amount) async {
    final key = _getBalanceKey(type);
    await _prefs!.setInt(key, amount);
  }

  void _notifyBalanceChanged(CurrencyType type, int newBalance) {
    final controller = _controllers[type];
    if (controller != null && !controller.isClosed) {
      controller.add(newBalance);
    }
  }

  // ============================================
  // 리소스 정리
  // ============================================

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    super.dispose();
  }
}

/// 통화 거래 내역
class CurrencyTransaction {
  final CurrencyType currency;
  final int amount;
  final bool isAddition; // true면 추가, false면 차감
  final int balanceBefore;
  final int balanceAfter;
  final String source;
  final DateTime timestamp;

  const CurrencyTransaction({
    required this.currency,
    required this.amount,
    required this.isAddition,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'currency': currency.name,
        'amount': amount,
        'isAddition': isAddition,
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CurrencyTransaction.fromJson(Map<String, dynamic> json) =>
      CurrencyTransaction(
        currency: CurrencyType.values.firstWhere(
          (e) => e.name == json['currency'],
          orElse: () => CurrencyType.coin,
        ),
        amount: json['amount'] as int,
        isAddition: json['isAddition'] as bool,
        balanceBefore: json['balanceBefore'] as int,
        balanceAfter: json['balanceAfter'] as int,
        source: json['source'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// 보상 패키지
class RewardPackage {
  final String id;
  final String name;
  final Map<CurrencyType, int> rewards;
  final int price;
  final CurrencyType priceCurrency;
  final bool isLimited;
  final int? maxPurchaseCount;
  final DateTime? availableUntil;

  const RewardPackage({
    required this.id,
    required this.name,
    required this.rewards,
    required this.price,
    this.priceCurrency = CurrencyType.gem,
    this.isLimited = false,
    this.maxPurchaseCount,
    this.availableUntil,
  });

  /// 구매 가능 여부
  bool canPurchase(int currentBalance, int purchasedCount) {
    // 1. 시간 제한 확인
    if (availableUntil != null) {
      if (DateTime.now().isAfter(availableUntil!)) {
        return false;
      }
    }

    // 2. 횟수 제한 확인
    if (isLimited && maxPurchaseCount != null) {
      if (purchasedCount >= maxPurchaseCount!) {
        return false;
      }
    }

    // 3. 잔액 확인
    return currentBalance >= price;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rewards': rewards.map((k, v) => MapEntry(k.name, v)),
        'price': price,
        'priceCurrency': priceCurrency.name,
        'isLimited': isLimited,
        'maxPurchaseCount': maxPurchaseCount,
        'availableUntil': availableUntil?.toIso8601String(),
      };

  factory RewardPackage.fromJson(Map<String, dynamic> json) => RewardPackage(
        id: json['id'] as String,
        name: json['name'] as String,
        rewards: (json['rewards'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            CurrencyType.values.firstWhere(
              (e) => e.name == k,
              orElse: () => CurrencyType.coin,
            ),
            v as int,
          ),
        ),
        price: json['price'] as int,
        priceCurrency: CurrencyType.values.firstWhere(
          (e) => e.name == json['priceCurrency'],
          orElse: () => CurrencyType.gem,
        ),
        isLimited: json['isLimited'] as bool? ?? false,
        maxPurchaseCount: json['maxPurchaseCount'] as int?,
        availableUntil: json['availableUntil'] != null
            ? DateTime.parse(json['availableUntil'] as String)
            : null,
      );
}

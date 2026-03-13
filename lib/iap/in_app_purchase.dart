import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 상품 타입
enum ProductType {
  consumable,      // 소모성 (골드, 보너스 등)
  nonConsumable,    // 비소모성 (영구 해제 등)
  subscription,    // 구독
}

/// 상품
class StoreProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final double priceValue;
  final String? currencyCode;
  final ProductType type;
  final String? iconUrl;
  final Map<String, dynamic>? metadata;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceValue,
    this.currencyCode,
    required this.type,
    this.iconUrl,
    this.metadata,
  });

  /// 포맷된 가격 (예: "₩1,000")
  String get formattedPrice => price;
}

/// 구매 항목
class PurchaseItem {
  final String id;
  final String productId;
  final String transactionId;
  final PurchaseState state;
  final DateTime purchaseTime;
  final String? orderId;
  final String? developerPayload;
  final bool isAcknowledged;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.transactionId,
    required this.state,
    required this.purchaseTime,
    this.orderId,
    this.developerPayload,
    this.isAcknowledged = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'transactionId': transactionId,
        'state': state.name,
        'purchaseTime': purchaseTime.toIso8601String(),
        'orderId': orderId,
        'developerPayload': developerPayload,
        'isAcknowledged': isAcknowledged,
      };
}

/// 구매 상태
enum PurchaseState {
  pending,
  purchased,
  failed,
  restored,
  canceled,
}

/// 구독 상태
class SubscriptionStatus {
  final String productId;
  final bool isActive;
  final DateTime? expiresAt;
  final bool willRenew;
  final String? cancelReason;

  const SubscriptionStatus({
    required this.productId,
    required this.isActive,
    this.expiresAt,
    required this.willRenew,
    this.cancelReason,
  });
}

/// 프로모션 코드
class PromoCode {
  final String code;
  final String description;
  final double discountPercent;
  final DateTime? expiresAt;
  final int maxUses;
  final int currentUses;
  final bool isActive;

  const PromoCode({
    required this.code,
    required this.description,
    required this.discountPercent,
    this.expiresAt,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
  });

  bool get isValid =>
      isActive &&
      currentUses < maxUses &&
      (expiresAt == null || DateTime.now().isBefore(expiresAt!));
}

/// 인앱 결제 관리자
class InAppPurchaseManager {
  static final InAppPurchaseManager _instance = InAppPurchaseManager._();
  static InAppPurchaseManager get instance => _instance;

  InAppPurchaseManager._();

  final Map<String, StoreProduct> _products = {};
  final List<PurchaseItem> _purchases = [];
  final List<PromoCode> _promoCodes = [];

  final StreamController<PurchaseItem> _purchaseController =
      StreamController<PurchaseItem>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<PurchaseItem> get onPurchaseUpdate => _purchaseController.stream;
  Stream<String> get onError => _errorController.stream;

  SharedPreferences? _prefs;
  String? _currentUserId;

  bool _isAvailable = false;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 결제 가용성 확인
    await _checkAvailability();

    // 상품 로드
    await _loadProducts();

    // 프로모션 코드 로드
    _loadPromoCodes();

    debugPrint('[IAP] Initialized');
  }

  Future<void> _checkAvailability() async {
    // 실제 구현에서는 in_app_purchase 사용
    _isAvailable = true;
    debugPrint('[IAP] Available: $_isAvailable');
  }

  Future<void> _loadProducts() async {
    // 상품 목록 정의 (실제로는 Store에서 로드)
    _products.addAll({
      'coin_100': const StoreProduct(
        id: 'coin_100',
        name: '100 골드',
        description: '100골드 패키지',
        price: '₩1,000',
        priceValue: 1000.0,
        currencyCode: 'KRW',
        type: ProductType.consumable,
      ),
      'coin_500': const StoreProduct(
        id: 'coin_500',
        name: '500 골드',
        description: '500골드 패키지 (20% 할인)',
        price: '₩4,000',
        priceValue: 4000.0,
        currencyCode: 'KRW',
        type: ProductType.consumable,
      ),
      'coin_1000': const StoreProduct(
        id: 'coin_1000',
        name: '1,000 골드',
        description: '1000골드 패키지 (30% 할인)',
        price: '₩7,000',
        priceValue: 7000.0,
        currencyCode: 'KRW',
        type: ProductType.consumable,
      ),
      'premium_month': const StoreProduct(
        id: 'premium_month',
        name: '프리미엄 (월간)',
        description: '매월 혜택을 받으세요',
        price: '₩4,900',
        priceValue: 4900.0,
        currencyCode: 'KRW',
        type: ProductType.subscription,
      ),
      'remove_ads': const StoreProduct(
        id: 'remove_ads',
        name: '광고 제거',
        description: '영구적으로 광고를 제거합니다',
        price: '₩9,900',
        priceValue: 9900.0,
        currencyCode: 'KRW',
        type: ProductType.nonConsumable,
      ),
    });
  }

  void _loadPromoCodes() {
    _promoCodes.addAll([
      const PromoCode(
        code: 'WELCOME2024',
        description: '첫 구매 50% 할인',
        discountPercent: 0.5,
        maxUses: 1000,
        currentUses: 0,
        isActive: true,
      ),
      const PromoCode(
        code: 'VIP50',
        description: 'VIP 50% 할인',
        discountPercent: 0.5,
        maxUses: 100,
        currentUses: 0,
        isActive: true,
      ),
    ]);
  }

  /// 상품 목록 조회
  List<StoreProduct> getProducts({ProductType? type}) {
    var products = _products.values.toList();

    if (type != null) {
      products = products.where((p) => p.type == type).toList();
    }

    return products;
  }

  /// 상품 조회
  StoreProduct? getProduct(String productId) {
    return _products[productId];
  }

  /// 구매 시작
  Future<PurchaseItem?> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      _errorController.add('결제 서비스를 사용할 수 없습니다');
      return null;
    }

    final product = _products[productId];
    if (product == null) {
      _errorController.add('상품을 찾을 수 없습니다');
      return null;
    }

    debugPrint('[IAP] Purchasing: ${product.name}');

    // 실제 구매 처리 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 2));

    final purchase = PurchaseItem(
      id: 'purchase_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      state: PurchaseState.purchased,
      purchaseTime: DateTime.now(),
      isAcknowledged: false,
    );

    _purchases.add(purchase);
    _purchaseController.add(purchase);

    // 영수증 검증
    await _verifyPurchase(purchase);

    return purchase;
  }

  /// 구매 영수증 검증
  Future<bool> _verifyPurchase(PurchaseItem purchase) async {
    // 실제 구현에서는 서버에서 검증
    debugPrint('[IAP] Verifying purchase: ${purchase.transactionId}');

    await Future.delayed(const Duration(milliseconds: 500));

    return true;
  }

  /// 구매 승인 (소모성 아이템 소비)
  Future<void> acknowledgePurchase(String purchaseId) async {
    final index = _purchases.indexWhere((p) => p.id == purchaseId);
    if (index == -1) return;

    final purchase = _purchases[index];

    // 소모성 아이템 지급
    await _deliverProduct(purchase.productId);

    debugPrint('[IAP] Purchase acknowledged: $purchaseId');
  }

  /// 상품 지급
  Future<void> _deliverProduct(String productId) async {
    final product = _products[productId];
    if (product == null) return;

    switch (product.type) {
      case ProductType.consumable:
        // 소모성 아이템 지급 (골드 등)
        await _grantConsumable(productId);
        break;
      case ProductType.nonConsumable:
        // 비소모성 아이템 지급 (영구 해제 등)
        await _grantNonConsumable(productId);
        break;
      case ProductType.subscription:
        // 구독 시작
        await _activateSubscription(productId);
        break;
    }
  }

  Future<void> _grantConsumable(String productId) async {
    // 실제로는 게임 서버에 골드 지급 요청
    debugPrint('[IAP] Granted consumable: $productId');
  }

  Future<void> _grantNonConsumable(String productId) async {
    // 영구 아이템 저장
    await _prefs?.setBool('purchased_$productId', true);
    debugPrint('[IAP] Granted non-consumable: $productId');
  }

  Future<void> _activateSubscription(String productId) async {
    // 구독 활성화
    await _prefs?.setString('subscription', productId);
    debugPrint('[IAP] Subscription activated: $productId');
  }

  /// 구매 복원
  Future<List<PurchaseItem>> restorePurchases() async {
    debugPrint('[IAP] Restoring purchases...');

    await Future.delayed(const Duration(seconds: 1));

    // 실제 구현에서는 Store에서 복원
    final restored = _purchases
        .where((p) => p.state == PurchaseState.purchased)
        .map((p) => PurchaseItem(
              id: p.id,
              productId: p.productId,
              transactionId: p.transactionId,
              state: PurchaseState.restored,
              purchaseTime: p.purchaseTime,
              isAcknowledged: p.isAcknowledged,
            ))
        .toList();

    for (final purchase in restored) {
      _purchaseController.add(purchase);
    }

    return restored;
  }

  /// 프로모션 코드 적용
  double? applyPromoCode(String code) {
    final promo = _promoCodes.firstWhere(
      (p) => p.code.toUpperCase() == code.toUpperCase(),
      orElse: () => const PromoCode(
        code: '',
        description: '',
        discountPercent: 0,
        maxUses: 0,
        currentUses: 0,
        isActive: false,
      ),
    );

    if (!promo.isValid) {
      return null;
    }

    return promo.discountPercent;
  }

  /// 프로모션 코드 사용
  bool usePromoCode(String code) {
    final index = _promoCodes.indexWhere(
      (p) => p.code.toUpperCase() == code.toUpperCase(),
    );

    if (index == -1) return false;

    final promo = _promoCodes[index];
    if (!promo.isValid) return false;

    // 사용 횟수 증가
    // promo.currentUses++; // 불변 객체라 실제로는 별도 처리

    return true;
  }

  /// 구독 상태 조회
  SubscriptionStatus? getSubscriptionStatus(String productId) {
    // 실제 구현에서는 구독 상태 확인
    return const SubscriptionStatus(
      productId: 'premium_month',
      isActive: true,
      expiresAt: null,
      willRenew: true,
    );
  }

  /// 구매 내역 조회
  List<PurchaseItem> getPurchaseHistory() {
    return _purchases.toList()
      ..sort((a, b) => b.purchaseTime.compareTo(a.purchaseTime));
  }

  /// 비소모성 아이템 소유 여부
  Future<bool> isPurchased(String productId) async {
    return _prefs?.getBool('purchased_$productId') ?? false;
  }

  /// 상점 추천 상품
  List<StoreProduct> getFeaturedProducts() {
    return _products.values.take(3).toList();
  }

  /// 인기 상품
  List<StoreProduct> getPopularProducts() {
    return _products.values.where((p) => p.type == ProductType.consumable).toList()
      ..sort((a, b) => a.priceValue.compareTo(b.priceValue));
  }

  /// 특가 상품
  List<StoreProduct> getSaleProducts() {
    return _products.values.where((p) =>
        p.metadata?['sale'] == true ||
        p.priceValue < 5000).toList();
  }

  void dispose() {
    _purchaseController.close();
    _errorController.close();
  }
}

/// 장바구니 아이템
class CartItem {
  final StoreProduct product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.priceValue * quantity;
}

/// 장바구니 관리자
class CartManager {
  static final CartManager _instance = CartManager._();
  static CartManager get instance => _instance;

  CartManager._();

  final Map<String, CartItem> _items = {};
  String? _promoCode;
  double _discount = 0.0;

  final StreamController<Map<String, CartItem>> _cartController =
      StreamController<Map<String, CartItem>>.broadcast();

  Stream<Map<String, CartItem>> get onCartUpdate => _cartController.stream;

  /// 상품 추가
  void addItem(StoreProduct product, {int quantity = 1}) {
    final existing = _items[product.id];

    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }

    _cartController.add(Map.from(_items));
  }

  /// 상품 제거
  void removeItem(String productId) {
    _items.remove(productId);
    _cartController.add(Map.from(_items));
  }

  /// 수량 변경
  void updateQuantity(String productId, int quantity) {
    final item = _items[productId];
    if (item != null) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        item.quantity = quantity;
        _cartController.add(Map.from(_items));
      }
    }
  }

  /// 프로모션 코드 적용
  bool applyPromoCode(String code) {
    final discount = InAppPurchaseManager.instance.applyPromoCode(code);

    if (discount != null) {
      _promoCode = code;
      _discount = discount;
      return true;
    }

    return false;
  }

  /// 프로모션 코드 제거
  void clearPromoCode() {
    _promoCode = null;
    _discount = 0.0;
  }

  /// 총 금액
  double get subtotal {
    return _items.values.fold(0, (sum, item) => sum + item.total);
  }

  /// 할인 금액
  double get discountAmount => subtotal * _discount;

  /// 최종 금액
  double get total => subtotal - discountAmount;

  /// 항목 목록
  List<CartItem> get items => _items.values.toList();

  /// 비우기
  void clear() {
    _items.clear();
    _promoCode = null;
    _discount = 0.0;
    _cartController.add({});
  }

  void dispose() {
    _cartController.close();
  }
}

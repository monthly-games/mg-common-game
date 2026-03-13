import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// 구독 상태
enum SubscriptionStatus {
  active,
  expired,
  canceled,
  pending,
  inGracePeriod,
  onHold,
}

/// 상품 타입
enum ProductType {
  consumable,
  nonConsumable,
  subscription,
}

/// 구매 상품 정보
class PurchaseProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final String? introductoryPrice;
  final ProductType type;
  final String? subscriptionPeriod;

  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.introductoryPrice,
    required this.type,
    this.subscriptionPeriod,
  });

  factory PurchaseProduct.fromProductDetails(
    ProductDetails details,
  ) {
    ProductType type;

    if (details.id.contains('subscription')) {
      type = ProductType.subscription;
    } else if (details.id.contains('consumable')) {
      type = ProductType.consumable;
    } else {
      type = ProductType.nonConsumable;
    }

    return PurchaseProduct(
      id: details.id,
      title: details.title,
      description: details.description,
      price: details.price,
      introductoryPrice: details.introductoryPrice,
      type: type,
      subscriptionPeriod: details.subscriptionPeriod,
    );
  }
}

/// 구매 정보
class PurchaseInfo {
  final String productId;
  final String? transactionDate;
  final String? purchaseToken;
  final bool isVerified;
  final SubscriptionStatus? subscriptionStatus;

  const PurchaseInfo({
    required this.productId,
    this.transactionDate,
    this.purchaseToken,
    required this.isVerified,
    this.subscriptionStatus,
  });
}

/// 구매 매니저
class PurchaseManager {
  static final PurchaseManager _instance = PurchaseManager._();
  static PurchaseManager get instance => _instance;

  PurchaseManager._();

  // ============================================
  // 상태
  // ============================================
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final List<PurchaseProduct> _products = [];
  final List<PurchaseInfo> _purchases = [];

  final StreamController<PurchaseProduct> _productController =
      StreamController<PurchaseProduct>.broadcast();
  final StreamController<PurchaseInfo> _purchaseController =
      StreamController<PurchaseInfo>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isAvailable = false;
  bool _isInitialized = false;

  // Getters
  bool get isAvailable => _isAvailable;
  List<PurchaseProduct> get products => List.unmodifiable(_products);
  List<PurchaseInfo> get purchases => List.unmodifiable(_purchases);
  Stream<PurchaseProduct> get onProductUpdated => _productController.stream;
  Stream<PurchaseInfo> get onPurchase => _purchaseController.stream;
  Stream<String> get onError => _errorController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    // IAP 사용 가능 여부 확인
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('[PurchaseManager] In-app purchase not available');
      _errorController.add('인앱 결제를 사용할 수 없습니다.');
      return;
    }

    // 구매 리스너 설정
    final purchaseUpdated = _iap.purchaseStream;

    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdates,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    _isInitialized = true;

    // 상품 정보 로드
    await loadProducts();

    debugPrint('[PurchaseManager] Initialized');
  }

  // ============================================
  // 상품 관리
  // ============================================

  /// 상품 목록 로드
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final Set<ProductDetails> productDetails;

    try {
      // 상품 ID 목록 (실제 프로젝트에서는 설정에서 로드)
      const productIds = {
        'coin_pack_100',
        'coin_pack_500',
        'coin_pack_1000',
        'remove_ads',
        'premium_monthly',
        'premium_yearly',
      };

      final response = await _iap.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[PurchaseManager] Products not found: ${response.notFoundIDs}');
      }

      if (response.productDetails.isEmpty) {
        debugPrint('[PurchaseManager] No products found');
        _errorController.add('상품 정보를 불러오지 못했습니다.');
        return;
      }

      productDetails = response.productDetails;

      // 상품 정보 변환
      _products.clear();

      for (final details in productDetails) {
        final product = PurchaseProduct.fromProductDetails(details);
        _products.add(product);
        _productController.add(product);
      }

      debugPrint('[PurchaseManager] Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[PurchaseManager] Error loading products: $e');
      _errorController.add('상품 로드 실패: $e');
    }
  }

  /// 상품으로 구매 시작
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      _errorController.add('인앱 결제를 사용할 수 없습니다.');
      return false;
    }

    final productParam = ProductDetailsParam(
      productDetails: _products
          .where((p) => p.id == productId)
          .map((p) => _convertToProductDetails(p))
          .toList(),
    );

    try {
      final success = await _iap.buyNonConsumable(
        purchaseParam: productParam,
      );

      return success;
    } catch (e) {
      debugPrint('[PurchaseManager] Purchase error: $e');
      _errorController.add('구매 실패: $e');
      return false;
    }
  }

  /// 소비성 상품 구매
  Future<bool> purchaseConsumable(String productId) async {
    if (!_isAvailable) {
      _errorController.add('인앱 결제를 사용할 수 없습니다.');
      return false;
    }

    final productParam = ProductDetailsParam(
      productDetails: _products
          .where((p) => p.id == productId)
          .map((p) => _convertToProductDetails(p))
          .toList(),
    );

    try {
      final success = await _iap.buyConsumable(
        purchaseParam: productParam,
        autoConsume: true,
      );

      return success;
    } catch (e) {
      debugPrint('[PurchaseManager] Purchase error: $e');
      _errorController.add('구매 실패: $e');
      return false;
    }
  }

  ProductDetails _convertToProductDetails(PurchaseProduct product) {
    return ProductDetails(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      rawPrice: 0,
      currencyCode: 'KRW',
    );
  }

  // ============================================
  // 구매 핸들링
  // ============================================

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('[PurchaseManager] Purchase pending: ${purchaseDetails.productID}');
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // 구매 검증
        final isValid = await _verifyPurchase(purchaseDetails);

        if (isValid) {
          final purchaseInfo = PurchaseInfo(
            productId: purchaseDetails.productID,
            transactionDate: purchaseDetails.transactionDate,
            purchaseToken: purchaseDetails.purchaseToken,
            isVerified: true,
          );

          _purchases.add(purchaseInfo);
          _purchaseController.add(purchaseInfo);

          // 소비성 상품이면 소비
          if (purchaseDetails.productID.contains('consumable')) {
            await _iap.consume(purchaseDetails);
          }

          // 구매 완료 처리
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
        } else {
          debugPrint('[PurchaseManager] Purchase verification failed');
          _errorController.add('구매 검증 실패');
        }
        break;

      case PurchaseStatus.error:
        debugPrint('[PurchaseManager] Purchase error: ${purchaseDetails.error}');
        _errorController.add('구매 오류: ${purchaseDetails.error}');
        break;

      case PurchaseStatus.canceled:
        debugPrint('[PurchaseManager] Purchase canceled');
        break;
    }
  }

  /// 구매 검증 (서버 검증)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // 실제로는 서버에 검증 요청
    // 여기서는 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    return true; // 검증 성공 가정
  }

  /// 과거 구매 내역 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
      debugPrint('[PurchaseManager] Restoring purchases');
    } catch (e) {
      debugPrint('[PurchaseManager] Restore error: $e');
      _errorController.add('복원 실패: $e');
    }
  }

  /// 구매 내역 확인
  bool hasPurchased(String productId) {
    return _purchases.any((p) => p.productId == productId && p.isVerified);
  }

  /// 구독 상태 확인
  SubscriptionStatus? getSubscriptionStatus(String subscriptionId) {
    final purchase = _purchases.firstWhere(
      (p) => p.productId == subscriptionId,
      orElse: () => const PurchaseInfo(
        productId: '',
        isVerified: false,
      ),
    );

    return purchase.subscriptionStatus;
  }

  // ============================================
  // 유틸리티
  // ============================================

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    debugPrint('[PurchaseManager] Stream error: $error');
    _errorController.add('구매 스트림 오류: $error');
  }

  /// 상품 가격 포맷
  String formatPrice(String productId) {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => _products.isNotEmpty ? _products.first : throw Exception('Product not found'),
    );

    return product.price;
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _subscription?.cancel();
    _productController.close();
    _purchaseController.close();
    _errorController.close();
  }
}

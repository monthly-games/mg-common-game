import 'dart:async';
import 'package:flutter/material.dart';

enum ProductType {
  consumable,
  nonConsumable,
  subscription,
}

enum PurchaseStatus {
  pending,
  approved,
  failed,
  cancelled,
  restored,
  refunded,
}

class StoreProduct {
  final String productId;
  final String name;
  final String description;
  final String price;
  final double priceValue;
  final String currencyCode;
  final ProductType type;
  final String localizedPrice;
  final Map<String, dynamic> metadata;

  const StoreProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.priceValue,
    required this.currencyCode,
    required this.type,
    required this.localizedPrice,
    required this.metadata,
  });
}

class PurchaseItem {
  final String purchaseId;
  final String productId;
  final String? transactionId;
  final String? receipt;
  final PurchaseStatus status;
  final DateTime purchaseTime;
  final DateTime? transactionDate;
  final String? userId;
  final Map<String, dynamic> data;

  const PurchaseItem({
    required this.purchaseId,
    required this.productId,
    this.transactionId,
    this.receipt,
    required this.status,
    required this.purchaseTime,
    this.transactionDate,
    this.userId,
    required this.data,
  });

  bool get isPending => status == PurchaseStatus.pending;
  bool get isCompleted => status == PurchaseStatus.approved || status == PurchaseStatus.restored;
  bool get isFailed => status == PurchaseStatus.failed || status == PurchaseStatus.cancelled;
}

class PurchaseRequest {
  final String requestId;
  final String productId;
  final String userId;
  final Map<String, dynamic>? parameters;
  final DateTime createdAt;

  const PurchaseRequest({
    required this.requestId,
    required this.productId,
    required this.userId,
    this.parameters,
    required this.createdAt,
  });
}

class InAppPurchaseManager {
  static final InAppPurchaseManager _instance = InAppPurchaseManager._();
  static InAppPurchaseManager get instance => _instance;

  InAppPurchaseManager._();

  final Map<String, StoreProduct> _products = {};
  final Map<String, PurchaseItem> _purchases = {};
  final Map<String, PurchaseRequest> _pendingRequests = {};
  final StreamController<PurchaseEvent> _eventController = StreamController.broadcast();

  Stream<PurchaseEvent> get onPurchaseEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadProducts();
    await _restorePurchases();
  }

  Future<void> _loadProducts() async {
    final products = [
      StoreProduct(
        productId: 'com.game.coins.small',
        name: 'Small Coin Pack',
        description: '100 coins',
        price: '\$0.99',
        priceValue: 0.99,
        currencyCode: 'USD',
        type: ProductType.consumable,
        localizedPrice: '\$0.99',
        metadata: {'coins': 100},
      ),
      StoreProduct(
        productId: 'com.game.coins.medium',
        name: 'Medium Coin Pack',
        description: '500 coins',
        price: '\$4.99',
        priceValue: 4.99,
        currencyCode: 'USD',
        type: ProductType.consumable,
        localizedPrice: '\$4.99',
        metadata: {'coins': 500},
      ),
      StoreProduct(
        productId: 'com.game.coins.large',
        name: 'Large Coin Pack',
        description: '1000 coins',
        price: '\$9.99',
        priceValue: 9.99,
        currencyCode: 'USD',
        type: ProductType.consumable,
        localizedPrice: '\$9.99',
        metadata: {'coins': 1000},
      ),
      StoreProduct(
        productId: 'com.game.premium',
        name: 'Premium Pass',
        description: 'Unlock premium features',
        price: '\$19.99',
        priceValue: 19.99,
        currencyCode: 'USD',
        type: ProductType.nonConsumable,
        localizedPrice: '\$19.99',
        metadata: {'premium': true},
      ),
    ];

    for (final product in products) {
      _products[product.productId] = product;
    }
  }

  Future<void> _restorePurchases() async {
    await Future.delayed(const Duration(seconds: 1));

    _eventController.add(PurchaseEvent(
      type: PurchaseEventType.restored,
      timestamp: DateTime.now(),
    ));
  }

  List<StoreProduct> getProducts() {
    return _products.values.toList();
  }

  List<StoreProduct> getProductsByType(ProductType type) {
    return _products.values
        .where((product) => product.type == type)
        .toList();
  }

  StoreProduct? getProduct(String productId) {
    return _products[productId];
  }

  Future<PurchaseRequest> purchaseProduct({
    required String productId,
    required String userId,
    Map<String, dynamic>? parameters,
  }) async {
    final product = _products[productId];
    if (product == null) {
      throw Exception('Product not found: $productId');
    }

    final request = PurchaseRequest(
      requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      userId: userId,
      parameters: parameters,
      createdAt: DateTime.now(),
    );

    _pendingRequests[request.requestId] = request;

    _eventController.add(PurchaseEvent(
      type: PurchaseEventType.initiated,
      productId: productId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    await _processPurchase(request, product);

    return request;
  }

  Future<void> _processPurchase(
    PurchaseRequest request,
    StoreProduct product,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    final success = DateTime.now().millisecondsSinceEpoch % 10 > 2;

    if (success) {
      final purchase = PurchaseItem(
        purchaseId: 'purchase_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.productId,
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        status: PurchaseStatus.approved,
        purchaseTime: DateTime.now(),
        transactionDate: DateTime.now(),
        userId: request.userId,
        data: {
          'price': product.priceValue,
          'currency': product.currencyCode,
          'metadata': product.metadata,
        },
      );

      _purchases[purchase.purchaseId] = purchase;
      _pendingRequests.remove(request.requestId);

      _eventController.add(PurchaseEvent(
        type: PurchaseEventType.success,
        productId: product.productId,
        userId: request.userId,
        purchaseId: purchase.purchaseId,
        timestamp: DateTime.now(),
      ));
    } else {
      final purchase = PurchaseItem(
        purchaseId: 'purchase_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.productId,
        status: PurchaseStatus.failed,
        purchaseTime: DateTime.now(),
        userId: request.userId,
        data: {},
      );

      _purchases[purchase.purchaseId] = purchase;
      _pendingRequests.remove(request.requestId);

      _eventController.add(PurchaseEvent(
        type: PurchaseEventType.failed,
        productId: product.productId,
        userId: request.userId,
        purchaseId: purchase.purchaseId,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<bool> finishTransaction({
    required String purchaseId,
    required String userId,
  }) async {
    final purchase = _purchases[purchaseId];
    if (purchase == null) return false;
    if (purchase.userId != userId) return false;

    final updated = PurchaseItem(
      purchaseId: purchase.purchaseId,
      productId: purchase.productId,
      transactionId: purchase.transactionId,
      receipt: purchase.receipt,
      status: PurchaseStatus.approved,
      purchaseTime: purchase.purchaseTime,
      transactionDate: purchase.transactionDate,
      userId: purchase.userId,
      data: purchase.data,
    );

    _purchases[purchaseId] = updated;

    _eventController.add(PurchaseEvent(
      type: PurchaseEventType.finished,
      purchaseId: purchaseId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<List<PurchaseItem>> queryPurchaseHistory({
    required String userId,
  }) async {
    return _purchases.values
        .where((purchase) => purchase.userId == userId)
        .toList()
      ..sort((a, b) => b.purchaseTime.compareTo(a.purchaseTime));
  }

  List<PurchaseItem> getPurchases() {
    return _purchases.values.toList();
  }

  List<PurchaseItem> getPendingPurchases() {
    return _purchases.values
        .where((purchase) => purchase.isPending)
        .toList();
  }

  List<PurchaseItem> getCompletedPurchases() {
    return _purchases.values
        .where((purchase) => purchase.isCompleted)
        .toList();
  }

  Future<bool> validateReceipt({
    required String receipt,
    required String productId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return receipt.isNotEmpty;
  }

  Future<bool> consumeProduct({
    required String purchaseId,
    required String userId,
  }) async {
    final purchase = _purchases[purchaseId];
    if (purchase == null) return false;

    final product = _products[purchase.productId];
    if (product == null) return false;
    if (product.type != ProductType.consumable) return false;

    _purchases.remove(purchaseId);

    _eventController.add(PurchaseEvent(
      type: PurchaseEventType.consumed,
      purchaseId: purchaseId,
      productId: product.productId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<void> restorePurchases({
    required String userId,
  }) async {
    final userPurchases = await queryPurchaseHistory(userId: userId);

    for (final purchase in userPurchases) {
      if (purchase.isCompleted) {
        final updated = PurchaseItem(
          purchaseId: purchase.purchaseId,
          productId: purchase.productId,
          transactionId: purchase.transactionId,
          receipt: purchase.receipt,
          status: PurchaseStatus.restored,
          purchaseTime: purchase.purchaseTime,
          transactionDate: purchase.transactionDate,
          userId: userId,
          data: purchase.data,
        );

        _purchases[purchase.purchaseId] = updated;

        _eventController.add(PurchaseEvent(
          type: PurchaseEventType.restored,
          purchaseId: purchase.purchaseId,
          userId: userId,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Map<String, dynamic> getPurchaseStats() {
    final allPurchases = getPurchases();
    final completedPurchases = getCompletedPurchases();
    final failedPurchases = allPurchases
        .where((p) => p.isFailed)
        .length;

    double totalRevenue = 0;
    for (final purchase in completedPurchases) {
      final price = purchase.data['price'] as double?;
      totalRevenue += price ?? 0.0;
    }

    return {
      'totalPurchases': allPurchases.length,
      'completedPurchases': completedPurchases.length,
      'failedPurchases': failedPurchases,
      'totalRevenue': totalRevenue,
      'conversionRate': completedPurchases.length / (allPurchases.length > 0 ? allPurchases.length : 1),
    };
  }

  void dispose() {
    _eventController.close();
  }
}

class PurchaseEvent {
  final PurchaseEventType type;
  final String? productId;
  final String? userId;
  final String? purchaseId;
  final DateTime timestamp;

  const PurchaseEvent({
    required this.type,
    this.productId,
    this.userId,
    this.purchaseId,
    required this.timestamp,
  });
}

enum PurchaseEventType {
  initiated,
  success,
  failed,
  finished,
  restored,
  consumed,
  refunded,
}

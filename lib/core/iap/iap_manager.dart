/// IAP Manager for MG-Games
/// Unified IAP handling across 52 games

import 'dart:async';

import 'models/product.dart';
import 'models/purchase.dart';
import 'product_registry.dart';
import 'p2w_guard.dart';

/// IAP Manager callback types
typedef PurchaseCallback = void Function(Purchase purchase);
typedef ErrorCallback = void Function(String error, String? productId);

/// IAP Manager configuration
class IapConfig {
  /// Game ID
  final String gameId;

  /// Environment (debug/staging/production)
  final String environment;

  /// Receipt verification URL
  final String verificationUrl;

  /// Enable P2W guard
  final bool enableP2wGuard;

  /// Auto-consume consumables
  final bool autoConsumeConsumables;

  /// Verification timeout (milliseconds)
  final int verificationTimeoutMs;

  const IapConfig({
    required this.gameId,
    required this.verificationUrl,
    this.environment = 'production',
    this.enableP2wGuard = true,
    this.autoConsumeConsumables = true,
    this.verificationTimeoutMs = 10000,
  });
}

/// IAP Manager state
enum IapManagerState {
  /// Not initialized
  uninitialized,

  /// Initializing
  initializing,

  /// Ready for purchases
  ready,

  /// Store connection error
  error,

  /// Not available on this device
  unavailable,
}

/// IAP Manager implementation
class IapManager {
  /// Singleton instance per game
  static final Map<String, IapManager> _instances = {};

  /// Get instance for game
  static IapManager getInstance(String gameId) {
    return _instances.putIfAbsent(gameId, () => IapManager._internal(gameId));
  }

  IapManager._internal(this.gameId);

  /// Game ID
  final String gameId;

  /// Configuration
  IapConfig? _config;

  /// Current state
  IapManagerState _state = IapManagerState.uninitialized;
  IapManagerState get state => _state;

  /// Product registry
  final ProductRegistry _registry = ProductRegistry();

  /// P2W guard
  final P2wGuard _p2wGuard = P2wGuard();

  /// Pending purchases
  final Map<String, Purchase> _pendingPurchases = {};

  /// Purchase stream controller
  final StreamController<Purchase> _purchaseController =
      StreamController<Purchase>.broadcast();

  /// Purchase stream
  Stream<Purchase> get purchaseStream => _purchaseController.stream;

  /// Error stream controller
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Error stream
  Stream<String> get errorStream => _errorController.stream;

  /// Purchase callback
  PurchaseCallback? onPurchaseComplete;

  /// Error callback
  ErrorCallback? onError;

  /// Initialize IAP Manager
  Future<bool> initialize(IapConfig config) async {
    if (_state == IapManagerState.ready) {
      return true;
    }

    _state = IapManagerState.initializing;
    _config = config;

    try {
      // Initialize product registry
      final products = ProductRegistry.getAllGameProducts()
          .where((p) => p.gameId == gameId)
          .toList();
      _registry.initialize(products);

      // TODO: Connect to platform store (Google Play / App Store)
      // This would use in_app_purchase package in real implementation
      await _connectToStore();

      // Query available products from store
      await _queryProducts();

      // Restore pending purchases
      await _restorePurchases();

      _state = IapManagerState.ready;
      return true;
    } catch (e) {
      _state = IapManagerState.error;
      _errorController.add('Failed to initialize IAP: $e');
      return false;
    }
  }

  /// Connect to store (platform-specific)
  Future<void> _connectToStore() async {
    // Simulated connection - in real implementation:
    // - Android: BillingClient.startConnection()
    // - iOS: SKPaymentQueue.canMakePayments()
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Query available products from store
  Future<void> _queryProducts() async {
    // In real implementation, query products from store
    // and update registry with localized prices
    final productIds = _registry.getProductsForGame(gameId).map((p) => p.productId);

    // Simulated query - in real implementation:
    // - Android: querySkuDetails()
    // - iOS: SKProductsRequest
    for (final id in productIds) {
      _registry.updateAvailability(id, true);
    }
  }

  /// Restore purchases (for non-consumables and subscriptions)
  Future<void> _restorePurchases() async {
    // In real implementation, restore purchases from store
    // - Android: queryPurchases()
    // - iOS: restoreCompletedTransactions()
  }

  /// Get available products for current game
  List<IapProduct> getAvailableProducts() {
    return _registry
        .getProductsForGame(gameId)
        .where((p) => p.isAvailable)
        .toList();
  }

  /// Get product by ID
  IapProduct? getProduct(String productId) {
    return _registry.getProduct(productId);
  }

  /// Purchase a product
  Future<Purchase?> purchase({
    required String productId,
    required String userId,
  }) async {
    if (_state != IapManagerState.ready) {
      _errorController.add('IAP Manager not ready');
      return null;
    }

    final product = _registry.getProduct(productId);
    if (product == null) {
      _errorController.add('Product not found: $productId');
      return null;
    }

    if (!product.isAvailable) {
      _errorController.add('Product not available: $productId');
      return null;
    }

    // Check P2W spending limit
    if (_config?.enableP2wGuard == true) {
      final limitResult = _p2wGuard.checkSpendingLimit(
        userId: userId,
        purchaseAmountUsd: product.priceUsd,
      );

      if (!limitResult.isAllowed) {
        _errorController.add(limitResult.blockReason ?? 'Spending limit exceeded');
        return null;
      }

      if (limitResult.showWarning && limitResult.warningMessage != null) {
        // In real implementation, show warning UI before proceeding
        // For now, just log it
        print('P2W Warning: ${limitResult.warningMessage}');
      }
    }

    // Create pending purchase
    final purchase = Purchase(
      purchaseId: _generatePurchaseId(),
      productId: productId,
      userId: userId,
      gameId: gameId,
      platform: _getCurrentPlatform(),
      status: PurchaseStatus.pending,
      purchaseTimestamp: DateTime.now().millisecondsSinceEpoch,
      pricePaid: product.priceUsd, // Would be localized price in real impl
      currencyCode: 'USD',
      priceUsd: product.priceUsd,
    );

    _pendingPurchases[purchase.purchaseId] = purchase;

    try {
      // TODO: Launch platform purchase flow
      // - Android: BillingClient.launchBillingFlow()
      // - iOS: SKPaymentQueue.add(payment)

      // Simulate purchase success for now
      final completedPurchase = await _simulatePurchaseFlow(purchase, product);

      // Verify receipt
      final verifiedPurchase = await _verifyReceipt(completedPurchase);

      if (verifiedPurchase.status == PurchaseStatus.verified) {
        // Record in P2W guard
        if (_config?.enableP2wGuard == true) {
          _p2wGuard.recordPurchase(verifiedPurchase);
        }

        // Auto-consume if configured and consumable
        if (_config?.autoConsumeConsumables == true &&
            product.type == ProductType.consumable) {
          await _consumePurchase(verifiedPurchase);
        }

        // Notify listeners
        _purchaseController.add(verifiedPurchase);
        onPurchaseComplete?.call(verifiedPurchase);

        _pendingPurchases.remove(purchase.purchaseId);
        return verifiedPurchase;
      } else {
        _errorController.add('Purchase verification failed');
        return verifiedPurchase;
      }
    } catch (e) {
      final failedPurchase = purchase.copyWith(
        status: PurchaseStatus.failed,
        errorMessage: e.toString(),
      );
      _pendingPurchases.remove(purchase.purchaseId);
      _errorController.add('Purchase failed: $e');
      return failedPurchase;
    }
  }

  /// Restore purchases for user
  Future<List<Purchase>> restorePurchases(String userId) async {
    if (_state != IapManagerState.ready) {
      return [];
    }

    // TODO: Implement actual restore from platform
    // Return non-consumables and active subscriptions
    return [];
  }

  /// Check subscription status
  Future<SubscriptionStatus?> checkSubscriptionStatus({
    required String productId,
    required String userId,
  }) async {
    // TODO: Implement subscription status check
    // - Verify with server
    // - Return current status
    return null;
  }

  /// Verify receipt with server
  Future<Purchase> _verifyReceipt(Purchase purchase) async {
    if (_config?.verificationUrl == null) {
      // No verification URL, mark as verified (dev mode)
      return purchase.copyWith(
        status: PurchaseStatus.verified,
        verificationTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }

    try {
      // TODO: Call verification endpoint
      // POST to _config!.verificationUrl with purchase data

      // Simulate verification
      await Future.delayed(const Duration(milliseconds: 200));

      return purchase.copyWith(
        status: PurchaseStatus.verified,
        verificationTimestamp: DateTime.now().millisecondsSinceEpoch,
        verificationResponse: {'verified': true, 'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      return purchase.copyWith(
        status: PurchaseStatus.failed,
        errorMessage: 'Verification failed: $e',
      );
    }
  }

  /// Consume a consumable purchase
  Future<void> _consumePurchase(Purchase purchase) async {
    // TODO: Acknowledge/consume on platform
    // - Android: acknowledgePurchase() / consumePurchase()
    // - iOS: finishTransaction()
  }

  /// Simulate purchase flow (for development)
  Future<Purchase> _simulatePurchaseFlow(Purchase purchase, IapProduct product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return purchase.copyWith(
      status: PurchaseStatus.purchased,
      receiptData: 'simulated_receipt_${purchase.purchaseId}',
    );
  }

  /// Generate unique purchase ID
  String _generatePurchaseId() {
    return 'purchase_${DateTime.now().millisecondsSinceEpoch}_${_pendingPurchases.length}';
  }

  /// Get current platform
  PurchasePlatform _getCurrentPlatform() {
    // TODO: Detect actual platform
    return PurchasePlatform.googlePlay;
  }

  /// Dispose resources
  void dispose() {
    _purchaseController.close();
    _errorController.close();
    _instances.remove(gameId);
  }
}

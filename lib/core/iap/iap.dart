/// IAP Module for MG-Games
/// Unified In-App Purchase handling across 52 games
///
/// Features:
/// - Google Play Billing API 5.0+
/// - StoreKit 2 (iOS)
/// - Receipt verification via Firebase Functions
/// - P2W guard with spending limits
/// - Dynamic offer management
///
/// Usage:
/// ```dart
/// final iap = IapManager.getInstance('game_0037');
/// await iap.initialize(IapConfig(
///   gameId: 'game_0037',
///   verificationUrl: 'https://api.mg-games.com/verify',
/// ));
///
/// final products = iap.getAvailableProducts();
/// final purchase = await iap.purchase(
///   productId: 'com.mg.game0037.coins_500',
///   userId: 'user_123',
/// );
/// ```

library iap;

export 'models/product.dart';
export 'models/purchase.dart';
export 'iap_manager.dart';
export 'product_registry.dart';
export 'p2w_guard.dart';

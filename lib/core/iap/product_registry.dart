/// Product Registry for MG-Games
/// Central registry for all IAP products across 52 games

import 'models/product.dart';

/// Product registry configuration
class ProductRegistry {
  /// Singleton instance
  static final ProductRegistry _instance = ProductRegistry._internal();
  factory ProductRegistry() => _instance;
  ProductRegistry._internal();

  /// All registered products
  final Map<String, IapProduct> _products = {};

  /// Products by game ID
  final Map<String, List<IapProduct>> _productsByGame = {};

  /// Initialize registry with products
  void initialize(List<IapProduct> products) {
    _products.clear();
    _productsByGame.clear();

    for (final product in products) {
      _products[product.productId] = product;

      _productsByGame.putIfAbsent(product.gameId, () => []);
      _productsByGame[product.gameId]!.add(product);
    }
  }

  /// Get product by ID
  IapProduct? getProduct(String productId) => _products[productId];

  /// Get all products for a game
  List<IapProduct> getProductsForGame(String gameId) {
    return _productsByGame[gameId] ?? [];
  }

  /// Get products by type
  List<IapProduct> getProductsByType(ProductType type) {
    return _products.values.where((p) => p.type == type).toList();
  }

  /// Get all product IDs
  List<String> get allProductIds => _products.keys.toList();

  /// Update product availability
  void updateAvailability(String productId, bool isAvailable) {
    final product = _products[productId];
    if (product != null) {
      product.isAvailable = isAvailable;
    }
  }

  /// Update localized price from store
  void updateLocalizedPrice(
    String productId,
    String localizedPrice,
    String currencyCode,
  ) {
    final product = _products[productId];
    if (product != null) {
      product.localizedPrice = localizedPrice;
      product.currencyCode = currencyCode;
    }
  }

  /// Standard product templates for casual games
  static List<IapProduct> getCasualGameProducts(String gameId, String gamePrefix) {
    return [
      // Consumables
      IapProduct(
        productId: '$gamePrefix.coins_500',
        displayName: '500 Coins',
        description: 'Get 500 coins for in-game purchases',
        type: ProductType.consumable,
        tier: ProductTier.tier1,
        priceUsd: 0.99,
        gameId: gameId,
      ),
      IapProduct(
        productId: '$gamePrefix.coins_1500',
        displayName: '1,500 Coins',
        description: 'Get 1,500 coins (20% bonus!)',
        type: ProductType.consumable,
        tier: ProductTier.tier2,
        priceUsd: 1.99,
        gameId: gameId,
      ),
      IapProduct(
        productId: '$gamePrefix.starter_pack',
        displayName: 'Starter Pack',
        description: 'Best value for new players!',
        type: ProductType.consumable,
        tier: ProductTier.tier1,
        priceUsd: 0.99,
        gameId: gameId,
        metadata: {'isLimitedOffer': true, 'maxPurchases': 1},
      ),

      // Non-consumables
      IapProduct(
        productId: '$gamePrefix.remove_ads',
        displayName: 'Remove Ads',
        description: 'Enjoy ad-free gameplay forever!',
        type: ProductType.nonConsumable,
        tier: ProductTier.tier2,
        priceUsd: 1.99,
        gameId: gameId,
      ),

      // Subscriptions
      SubscriptionProduct(
        productId: '$gamePrefix.season_pass',
        displayName: 'Season Pass',
        description: 'Unlock premium rewards for 28 days',
        tier: ProductTier.tier2,
        priceUsd: 1.99,
        gameId: gameId,
        period: SubscriptionPeriod.monthly,
        durationDays: 28,
      ),
      SubscriptionProduct(
        productId: '$gamePrefix.vip_pass',
        displayName: 'VIP Pass',
        description: 'Ultimate benefits for 30 days',
        tier: ProductTier.tier4,
        priceUsd: 4.99,
        gameId: gameId,
        period: SubscriptionPeriod.monthly,
        durationDays: 30,
        freeTrialDays: 3,
      ),
    ];
  }

  /// Standard product templates for Level A games (JRPG)
  static List<IapProduct> getLevelAGameProducts(String gameId, String gamePrefix) {
    return [
      // Consumables - Premium Currency
      IapProduct(
        productId: '$gamePrefix.gems_100',
        displayName: '100 Gems',
        description: 'Premium currency for gacha',
        type: ProductType.consumable,
        tier: ProductTier.tier1,
        priceUsd: 0.99,
        gameId: gameId,
      ),
      IapProduct(
        productId: '$gamePrefix.gems_500',
        displayName: '500 Gems',
        description: 'Premium currency (10% bonus)',
        type: ProductType.consumable,
        tier: ProductTier.tier4,
        priceUsd: 4.99,
        gameId: gameId,
      ),
      IapProduct(
        productId: '$gamePrefix.gems_1200',
        displayName: '1,200 Gems',
        description: 'Premium currency (20% bonus)',
        type: ProductType.consumable,
        tier: ProductTier.tier5,
        priceUsd: 9.99,
        gameId: gameId,
      ),

      // Gacha Tickets
      IapProduct(
        productId: '$gamePrefix.gacha_ticket_1',
        displayName: 'Gacha Ticket',
        description: 'One gacha summon',
        type: ProductType.consumable,
        tier: ProductTier.tier1,
        priceUsd: 0.99,
        gameId: gameId,
      ),
      IapProduct(
        productId: '$gamePrefix.gacha_ticket_10',
        displayName: '10 Gacha Tickets',
        description: '10-pull with 1 guaranteed SR+',
        type: ProductType.consumable,
        tier: ProductTier.tier5,
        priceUsd: 9.99,
        gameId: gameId,
      ),

      // Starter Pack
      IapProduct(
        productId: '$gamePrefix.starter_pack',
        displayName: 'Starter Pack',
        description: 'Gems + SR Character + Resources',
        type: ProductType.consumable,
        tier: ProductTier.tier3,
        priceUsd: 2.99,
        gameId: gameId,
        metadata: {'isLimitedOffer': true, 'maxPurchases': 1},
      ),

      // Growth Pack
      IapProduct(
        productId: '$gamePrefix.growth_pack',
        displayName: 'Growth Pack',
        description: 'Resources for leveling',
        type: ProductType.consumable,
        tier: ProductTier.tier4,
        priceUsd: 4.99,
        gameId: gameId,
      ),

      // Battle Pass (Monthly)
      SubscriptionProduct(
        productId: '$gamePrefix.battle_pass',
        displayName: 'Battle Pass',
        description: 'Premium track rewards for 28 days',
        tier: ProductTier.tier4,
        priceUsd: 4.99,
        gameId: gameId,
        period: SubscriptionPeriod.monthly,
        durationDays: 28,
      ),

      // Monthly Card
      SubscriptionProduct(
        productId: '$gamePrefix.monthly_card',
        displayName: 'Monthly Card',
        description: 'Daily gems for 30 days',
        tier: ProductTier.tier4,
        priceUsd: 4.99,
        gameId: gameId,
        period: SubscriptionPeriod.monthly,
        durationDays: 30,
        metadata: {'dailyReward': 'gems_50'},
      ),
    ];
  }

  /// Get products for all 52 games
  static List<IapProduct> getAllGameProducts() {
    final products = <IapProduct>[];

    // Year 1 Core (MG-0001~0012) - Casual
    for (var i = 1; i <= 12; i++) {
      final id = i.toString().padLeft(4, '0');
      products.addAll(getCasualGameProducts('game_$id', 'com.mg.game$id'));
    }

    // Year 2 Core (MG-0013~0024) - Casual/Midcore
    for (var i = 13; i <= 24; i++) {
      final id = i.toString().padLeft(4, '0');
      products.addAll(getCasualGameProducts('game_$id', 'com.mg.game$id'));
    }

    // Level A JRPG (MG-0025~0036)
    for (var i = 25; i <= 36; i++) {
      final id = i.toString().padLeft(4, '0');
      products.addAll(getLevelAGameProducts('game_$id', 'com.mg.game$id'));
    }

    // Casual Emerging (MG-0037~0052) - Regional Casual
    for (var i = 37; i <= 52; i++) {
      final id = i.toString().padLeft(4, '0');
      products.addAll(getCasualGameProducts('game_$id', 'com.mg.game$id'));
    }

    return products;
  }
}

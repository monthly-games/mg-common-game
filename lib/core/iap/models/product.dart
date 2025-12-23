/// IAP Product Model for MG-Games
/// Supports 52 games across all regions

/// Product type enumeration
enum ProductType {
  /// One-time purchase (coins, gems, starter pack)
  consumable,

  /// Permanent purchase (ad removal, premium features)
  nonConsumable,

  /// Time-limited subscription (season pass, VIP)
  subscription,
}

/// Product tier for pricing strategy
enum ProductTier {
  /// $0.99 tier
  tier1,

  /// $1.99 tier
  tier2,

  /// $2.99 tier
  tier3,

  /// $4.99 tier
  tier4,

  /// $9.99 tier
  tier5,
}

/// IAP Product definition
class IapProduct {
  /// Unique product identifier (e.g., "com.mg.game0037.coins_500")
  final String productId;

  /// Display name for UI
  final String displayName;

  /// Description for store listing
  final String description;

  /// Product type
  final ProductType type;

  /// Price tier
  final ProductTier tier;

  /// Actual price in USD (base currency)
  final double priceUsd;

  /// Localized price string (from store)
  String? localizedPrice;

  /// Currency code (from store)
  String? currencyCode;

  /// Whether product is available for purchase
  bool isAvailable;

  /// Game ID this product belongs to
  final String gameId;

  /// Region-specific product (null = global)
  final String? region;

  /// Custom metadata
  final Map<String, dynamic>? metadata;

  IapProduct({
    required this.productId,
    required this.displayName,
    required this.description,
    required this.type,
    required this.tier,
    required this.priceUsd,
    required this.gameId,
    this.localizedPrice,
    this.currencyCode,
    this.isAvailable = true,
    this.region,
    this.metadata,
  });

  /// Get tier price in USD
  static double getTierPrice(ProductTier tier) {
    switch (tier) {
      case ProductTier.tier1:
        return 0.99;
      case ProductTier.tier2:
        return 1.99;
      case ProductTier.tier3:
        return 2.99;
      case ProductTier.tier4:
        return 4.99;
      case ProductTier.tier5:
        return 9.99;
    }
  }

  /// Create from JSON
  factory IapProduct.fromJson(Map<String, dynamic> json) {
    return IapProduct(
      productId: json['productId'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      type: ProductType.values.byName(json['type'] as String),
      tier: ProductTier.values.byName(json['tier'] as String),
      priceUsd: (json['priceUsd'] as num).toDouble(),
      gameId: json['gameId'] as String,
      localizedPrice: json['localizedPrice'] as String?,
      currencyCode: json['currencyCode'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      region: json['region'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'displayName': displayName,
      'description': description,
      'type': type.name,
      'tier': tier.name,
      'priceUsd': priceUsd,
      'gameId': gameId,
      'localizedPrice': localizedPrice,
      'currencyCode': currencyCode,
      'isAvailable': isAvailable,
      'region': region,
      'metadata': metadata,
    };
  }

  @override
  String toString() => 'IapProduct($productId, $displayName, \$$priceUsd)';
}

/// Subscription period
enum SubscriptionPeriod {
  /// 7-day subscription
  weekly,

  /// 28-day subscription (season pass)
  monthly,

  /// 365-day subscription
  yearly,
}

/// Subscription product extension
class SubscriptionProduct extends IapProduct {
  /// Subscription period
  final SubscriptionPeriod period;

  /// Duration in days
  final int durationDays;

  /// Free trial days (0 = no trial)
  final int freeTrialDays;

  /// Auto-renew enabled
  final bool autoRenew;

  SubscriptionProduct({
    required super.productId,
    required super.displayName,
    required super.description,
    required super.tier,
    required super.priceUsd,
    required super.gameId,
    required this.period,
    required this.durationDays,
    this.freeTrialDays = 0,
    this.autoRenew = true,
    super.localizedPrice,
    super.currencyCode,
    super.isAvailable,
    super.region,
    super.metadata,
  }) : super(type: ProductType.subscription);

  /// Get period duration in days
  static int getPeriodDays(SubscriptionPeriod period) {
    switch (period) {
      case SubscriptionPeriod.weekly:
        return 7;
      case SubscriptionPeriod.monthly:
        return 28;
      case SubscriptionPeriod.yearly:
        return 365;
    }
  }

  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionProduct(
      productId: json['productId'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      tier: ProductTier.values.byName(json['tier'] as String),
      priceUsd: (json['priceUsd'] as num).toDouble(),
      gameId: json['gameId'] as String,
      period: SubscriptionPeriod.values.byName(json['period'] as String),
      durationDays: json['durationDays'] as int,
      freeTrialDays: json['freeTrialDays'] as int? ?? 0,
      autoRenew: json['autoRenew'] as bool? ?? true,
      localizedPrice: json['localizedPrice'] as String?,
      currencyCode: json['currencyCode'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      region: json['region'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'period': period.name,
      'durationDays': durationDays,
      'freeTrialDays': freeTrialDays,
      'autoRenew': autoRenew,
    };
  }
}

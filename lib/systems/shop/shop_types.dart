/// Shop System Types
library shop_types;

/// Currency type for shop items
enum CurrencyType {
  /// Free soft currency (gold, coins)
  softCurrency,
  /// Premium hard currency (gems, diamonds)
  hardCurrency,
  /// Real money (IAP)
  realMoney,
  /// Event-specific currency
  eventCurrency,
  /// Ad-watching currency
  adCurrency,
}

/// Shop item category
enum ShopCategory {
  currency,
  resources,
  characters,
  equipment,
  cosmetics,
  bundles,
  subscriptions,
  special,
}

/// Purchase result
enum PurchaseResult {
  success,
  insufficientFunds,
  itemNotFound,
  soldOut,
  limitReached,
  error,
}

/// Shop item model
class ShopItem {
  final String id;
  final String name;
  final String description;
  final ShopCategory category;
  final CurrencyType currencyType;
  final int price;
  final int? originalPrice; // For discounts
  final String? iconUrl;
  final int? stock; // null = unlimited
  final int? purchaseLimit; // Per user limit
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final Map<String, int> rewards; // itemType -> amount
  final Map<String, dynamic> metadata;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.currencyType,
    required this.price,
    this.originalPrice,
    this.iconUrl,
    this.stock,
    this.purchaseLimit,
    this.availableFrom,
    this.availableUntil,
    this.rewards = const {},
    this.metadata = const {},
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercent => hasDiscount
      ? ((1 - price / originalPrice!) * 100).round()
      : 0;

  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    if (stock != null && stock! <= 0) return false;
    return true;
  }

  bool get isLimitedTime => availableUntil != null;

  Duration? get remainingTime {
    if (availableUntil == null) return null;
    final now = DateTime.now();
    if (now.isAfter(availableUntil!)) return Duration.zero;
    return availableUntil!.difference(now);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.index,
    'currencyType': currencyType.index,
    'price': price,
    'originalPrice': originalPrice,
    'iconUrl': iconUrl,
    'stock': stock,
    'purchaseLimit': purchaseLimit,
    'availableFrom': availableFrom?.millisecondsSinceEpoch,
    'availableUntil': availableUntil?.millisecondsSinceEpoch,
    'rewards': rewards,
    'metadata': metadata,
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: ShopCategory.values[json['category'] as int],
    currencyType: CurrencyType.values[json['currencyType'] as int],
    price: json['price'] as int,
    originalPrice: json['originalPrice'] as int?,
    iconUrl: json['iconUrl'] as String?,
    stock: json['stock'] as int?,
    purchaseLimit: json['purchaseLimit'] as int?,
    availableFrom: json['availableFrom'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['availableFrom'] as int)
        : null,
    availableUntil: json['availableUntil'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['availableUntil'] as int)
        : null,
    rewards: Map<String, int>.from(json['rewards'] as Map? ?? {}),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
  );
}

/// Bundle offer with multiple items
class BundleOffer {
  final String id;
  final String name;
  final String description;
  final List<ShopItem> items;
  final CurrencyType currencyType;
  final int bundlePrice;
  final int totalOriginalPrice;
  final DateTime? availableUntil;
  final int? purchaseLimit;
  final String? bannerUrl;

  const BundleOffer({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    required this.currencyType,
    required this.bundlePrice,
    required this.totalOriginalPrice,
    this.availableUntil,
    this.purchaseLimit,
    this.bannerUrl,
  });

  int get savingsPercent => totalOriginalPrice > 0
      ? ((1 - bundlePrice / totalOriginalPrice) * 100).round()
      : 0;

  bool get isAvailable {
    if (availableUntil != null && DateTime.now().isAfter(availableUntil!)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'items': items.map((i) => i.toJson()).toList(),
    'currencyType': currencyType.index,
    'bundlePrice': bundlePrice,
    'totalOriginalPrice': totalOriginalPrice,
    'availableUntil': availableUntil?.millisecondsSinceEpoch,
    'purchaseLimit': purchaseLimit,
    'bannerUrl': bannerUrl,
  };

  factory BundleOffer.fromJson(Map<String, dynamic> json) => BundleOffer(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    items: (json['items'] as List<dynamic>)
        .map((i) => ShopItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    currencyType: CurrencyType.values[json['currencyType'] as int],
    bundlePrice: json['bundlePrice'] as int,
    totalOriginalPrice: json['totalOriginalPrice'] as int,
    availableUntil: json['availableUntil'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['availableUntil'] as int)
        : null,
    purchaseLimit: json['purchaseLimit'] as int?,
    bannerUrl: json['bannerUrl'] as String?,
  );
}

/// Daily/Refresh shop section
class RefreshShopSection {
  final String id;
  final String name;
  final List<ShopItem> items;
  final DateTime nextRefresh;
  final Duration refreshInterval;
  final int? manualRefreshCost;
  final CurrencyType? refreshCurrencyType;

  const RefreshShopSection({
    required this.id,
    required this.name,
    required this.items,
    required this.nextRefresh,
    this.refreshInterval = const Duration(days: 1),
    this.manualRefreshCost,
    this.refreshCurrencyType,
  });

  bool get needsRefresh => DateTime.now().isAfter(nextRefresh);

  Duration get timeUntilRefresh {
    final now = DateTime.now();
    if (now.isAfter(nextRefresh)) return Duration.zero;
    return nextRefresh.difference(now);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((i) => i.toJson()).toList(),
    'nextRefresh': nextRefresh.millisecondsSinceEpoch,
    'refreshInterval': refreshInterval.inSeconds,
    'manualRefreshCost': manualRefreshCost,
    'refreshCurrencyType': refreshCurrencyType?.index,
  };

  factory RefreshShopSection.fromJson(Map<String, dynamic> json) => RefreshShopSection(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>)
        .map((i) => ShopItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    nextRefresh: DateTime.fromMillisecondsSinceEpoch(json['nextRefresh'] as int),
    refreshInterval: Duration(seconds: json['refreshInterval'] as int? ?? 86400),
    manualRefreshCost: json['manualRefreshCost'] as int?,
    refreshCurrencyType: json['refreshCurrencyType'] != null
        ? CurrencyType.values[json['refreshCurrencyType'] as int]
        : null,
  );
}

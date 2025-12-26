import 'package:flutter/foundation.dart';
import 'shop_types.dart';

/// Shop Manager
/// Manages in-game shops, bundles, and purchases
class ShopManager extends ChangeNotifier {
  final Map<String, ShopItem> _items = {};
  final Map<String, BundleOffer> _bundles = {};
  final Map<String, RefreshShopSection> _refreshSections = {};
  final Map<String, int> _purchaseCounts = {}; // itemId -> count

  // Currency balances (can be connected to external currency manager)
  final Map<CurrencyType, int> _currencies = {};

  // Callbacks
  Future<bool> Function(ShopItem item)? onPurchaseItem;
  Future<bool> Function(BundleOffer bundle)? onPurchaseBundle;
  void Function(String itemId, Map<String, int> rewards)? onRewardsGranted;

  // === Items ===

  List<ShopItem> get allItems => _items.values.toList();

  List<ShopItem> get availableItems =>
      _items.values.where((i) => i.isAvailable).toList();

  List<ShopItem> getItemsByCategory(ShopCategory category) =>
      _items.values.where((i) => i.category == category).toList();

  ShopItem? getItem(String itemId) => _items[itemId];

  void registerItem(ShopItem item) {
    _items[item.id] = item;
    notifyListeners();
  }

  void registerItems(List<ShopItem> items) {
    for (final item in items) {
      _items[item.id] = item;
    }
    notifyListeners();
  }

  // === Bundles ===

  List<BundleOffer> get allBundles => _bundles.values.toList();

  List<BundleOffer> get availableBundles =>
      _bundles.values.where((b) => b.isAvailable).toList();

  BundleOffer? getBundle(String bundleId) => _bundles[bundleId];

  void registerBundle(BundleOffer bundle) {
    _bundles[bundle.id] = bundle;
    notifyListeners();
  }

  // === Refresh Sections ===

  List<RefreshShopSection> get refreshSections => _refreshSections.values.toList();

  RefreshShopSection? getRefreshSection(String sectionId) =>
      _refreshSections[sectionId];

  void registerRefreshSection(RefreshShopSection section) {
    _refreshSections[section.id] = section;
    notifyListeners();
  }

  void updateRefreshSection(RefreshShopSection section) {
    _refreshSections[section.id] = section;
    notifyListeners();
  }

  // === Currency ===

  int getCurrency(CurrencyType type) => _currencies[type] ?? 0;

  void setCurrency(CurrencyType type, int amount) {
    _currencies[type] = amount.clamp(0, 999999999);
    notifyListeners();
  }

  void addCurrency(CurrencyType type, int amount) {
    _currencies[type] = (getCurrency(type) + amount).clamp(0, 999999999);
    notifyListeners();
  }

  bool spendCurrency(CurrencyType type, int amount) {
    final current = getCurrency(type);
    if (current < amount) return false;
    _currencies[type] = current - amount;
    notifyListeners();
    return true;
  }

  bool canAfford(CurrencyType type, int price) => getCurrency(type) >= price;

  // === Purchase ===

  int getPurchaseCount(String itemId) => _purchaseCounts[itemId] ?? 0;

  bool canPurchase(ShopItem item) {
    if (!item.isAvailable) return false;
    if (!canAfford(item.currencyType, item.price)) return false;
    if (item.purchaseLimit != null) {
      if (getPurchaseCount(item.id) >= item.purchaseLimit!) return false;
    }
    return true;
  }

  Future<PurchaseResult> purchaseItem(String itemId) async {
    final item = _items[itemId];
    if (item == null) return PurchaseResult.itemNotFound;
    if (!item.isAvailable) {
      if (item.stock != null && item.stock! <= 0) return PurchaseResult.soldOut;
      return PurchaseResult.error;
    }
    if (!canAfford(item.currencyType, item.price)) {
      return PurchaseResult.insufficientFunds;
    }
    if (item.purchaseLimit != null) {
      if (getPurchaseCount(item.id) >= item.purchaseLimit!) {
        return PurchaseResult.limitReached;
      }
    }

    // External purchase handler
    if (onPurchaseItem != null) {
      final success = await onPurchaseItem!(item);
      if (!success) return PurchaseResult.error;
    }

    // Deduct currency
    spendCurrency(item.currencyType, item.price);

    // Track purchase
    _purchaseCounts[itemId] = getPurchaseCount(itemId) + 1;

    // Grant rewards
    if (item.rewards.isNotEmpty) {
      onRewardsGranted?.call(itemId, item.rewards);
    }

    // Update stock if limited
    if (item.stock != null) {
      _items[itemId] = ShopItem(
        id: item.id,
        name: item.name,
        description: item.description,
        category: item.category,
        currencyType: item.currencyType,
        price: item.price,
        originalPrice: item.originalPrice,
        iconUrl: item.iconUrl,
        stock: item.stock! - 1,
        purchaseLimit: item.purchaseLimit,
        availableFrom: item.availableFrom,
        availableUntil: item.availableUntil,
        rewards: item.rewards,
        metadata: item.metadata,
      );
    }

    notifyListeners();
    return PurchaseResult.success;
  }

  Future<PurchaseResult> purchaseBundle(String bundleId) async {
    final bundle = _bundles[bundleId];
    if (bundle == null) return PurchaseResult.itemNotFound;
    if (!bundle.isAvailable) return PurchaseResult.error;
    if (!canAfford(bundle.currencyType, bundle.bundlePrice)) {
      return PurchaseResult.insufficientFunds;
    }
    if (bundle.purchaseLimit != null) {
      if (getPurchaseCount(bundleId) >= bundle.purchaseLimit!) {
        return PurchaseResult.limitReached;
      }
    }

    // External purchase handler
    if (onPurchaseBundle != null) {
      final success = await onPurchaseBundle!(bundle);
      if (!success) return PurchaseResult.error;
    }

    // Deduct currency
    spendCurrency(bundle.currencyType, bundle.bundlePrice);

    // Track purchase
    _purchaseCounts[bundleId] = getPurchaseCount(bundleId) + 1;

    // Grant all bundle item rewards
    for (final item in bundle.items) {
      if (item.rewards.isNotEmpty) {
        onRewardsGranted?.call(item.id, item.rewards);
      }
    }

    notifyListeners();
    return PurchaseResult.success;
  }

  // === Featured/Special Offers ===

  List<ShopItem> get discountedItems =>
      availableItems.where((i) => i.hasDiscount).toList();

  List<ShopItem> get limitedTimeItems =>
      availableItems.where((i) => i.isLimitedTime).toList();

  // === Persistence ===

  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((k, v) => MapEntry(k, v.toJson())),
      'bundles': _bundles.map((k, v) => MapEntry(k, v.toJson())),
      'refreshSections': _refreshSections.map((k, v) => MapEntry(k, v.toJson())),
      'purchaseCounts': _purchaseCounts,
      'currencies': _currencies.map((k, v) => MapEntry(k.index.toString(), v)),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _items.clear();
    if (json['items'] != null) {
      final itemsMap = json['items'] as Map<String, dynamic>;
      for (final entry in itemsMap.entries) {
        _items[entry.key] = ShopItem.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _bundles.clear();
    if (json['bundles'] != null) {
      final bundlesMap = json['bundles'] as Map<String, dynamic>;
      for (final entry in bundlesMap.entries) {
        _bundles[entry.key] = BundleOffer.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _refreshSections.clear();
    if (json['refreshSections'] != null) {
      final sectionsMap = json['refreshSections'] as Map<String, dynamic>;
      for (final entry in sectionsMap.entries) {
        _refreshSections[entry.key] = RefreshShopSection.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    _purchaseCounts.clear();
    if (json['purchaseCounts'] != null) {
      _purchaseCounts.addAll(Map<String, int>.from(json['purchaseCounts'] as Map));
    }

    _currencies.clear();
    if (json['currencies'] != null) {
      final currMap = json['currencies'] as Map<String, dynamic>;
      for (final entry in currMap.entries) {
        final type = CurrencyType.values[int.parse(entry.key)];
        _currencies[type] = entry.value as int;
      }
    }

    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _items.clear();
    _bundles.clear();
    _refreshSections.clear();
    _purchaseCounts.clear();
    _currencies.clear();
    notifyListeners();
  }
}

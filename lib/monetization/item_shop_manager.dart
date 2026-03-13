import 'dart:async';
import 'package:flutter/material.dart';

enum ShopType {
  general,
  premium,
  limited,
  event,
  guild,
  blackmarket,
}

enum CurrencyType {
  premium,
  basic,
  special,
}

enum PurchaseStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
}

enum DiscountType {
  percentage,
  fixed,
  bogo,
}

class ShopItem {
  final String itemId;
  final String name;
  final String description;
  final String icon;
  final String itemType;
  final int quantity;
  final int basePrice;
  final String currencyId;
  final int maxPurchaseLimit;
  final int currentPurchaseCount;
  final bool isLimited;
  final bool isExclusive;
  final bool isFeatured;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final int sortOrder;
  final String? requiredLevel;

  const ShopItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.icon,
    required this.itemType,
    required this.quantity,
    required this.basePrice,
    required this.currencyId,
    required this.maxPurchaseLimit,
    required this.currentPurchaseCount,
    required this.isLimited,
    required this.isExclusive,
    required this.isFeatured,
    this.availableFrom,
    this.availableUntil,
    required this.tags,
    required this.metadata,
    required this.sortOrder,
    this.requiredLevel,
  });

  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    if (isLimited && currentPurchaseCount >= maxPurchaseLimit) return false;
    return true;
  }

  int get remainingStock => isLimited ? maxPurchaseLimit - currentPurchaseCount : -1;
}

class ShopDiscount {
  final String discountId;
  final String itemId;
  final DiscountType type;
  final double value;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? code;
  final int maxUses;
  final int currentUses;
  final List<String> applicableItems;

  const ShopDiscount({
    required this.discountId,
    required this.itemId,
    required this.type,
    required this.value,
    this.startTime,
    this.endTime,
    this.code,
    required this.maxUses,
    required this.currentUses,
    required this.applicableItems,
  });

  bool get isActive {
    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    if (maxUses > 0 && currentUses >= maxUses) return false;
    return true;
  }

  int calculateDiscount(int originalPrice) {
    switch (type) {
      case DiscountType.percentage:
        return (originalPrice * value / 100).floor();
      case DiscountType.fixed:
        return value.floor();
      case DiscountType.bogo:
        return originalPrice;
    }
  }
}

class ShopBundle {
  final String bundleId;
  final String name;
  final String description;
  final String icon;
  final List<BundleItem> items;
  final int totalPrice;
  final int discountedPrice;
  final int savings;
  final String currencyId;
  final bool isLimited;
  final int purchaseLimit;
  final int purchaseCount;
  final DateTime? availableUntil;
  final List<String> tags;

  const ShopBundle({
    required this.bundleId,
    required this.name,
    required this.description,
    required this.icon,
    required this.items,
    required this.totalPrice,
    required this.discountedPrice,
    required this.savings,
    required this.currencyId,
    required this.isLimited,
    required this.purchaseLimit,
    required this.purchaseCount,
    this.availableUntil,
    required this.tags,
  });

  double get discountPercentage => totalPrice > 0 ? (savings / totalPrice * 100) : 0.0;
  bool get isAvailable => !isLimited || purchaseCount < purchaseLimit;
}

class BundleItem {
  final String itemId;
  final String name;
  final int quantity;
  final String icon;
  final Map<String, dynamic> metadata;

  const BundleItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.icon,
    required this.metadata,
  });
}

class ShopRotation {
  final String rotationId;
  final String name;
  final List<String> itemIds;
  final DateTime startTime;
  final DateTime endTime;
  final int durationHours;
  final bool isActive;

  const ShopRotation({
    required this.rotationId,
    required this.name,
    required this.itemIds,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.isActive,
  });

  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}

class Purchase {
  final String purchaseId;
  final String userId;
  final String itemId;
  final String itemType;
  final int quantity;
  final int price;
  final String currencyId;
  final PurchaseStatus status;
  final DateTime timestamp;
  final String? discountId;
  final int? originalPrice;
  final Map<String, dynamic> metadata;

  const Purchase({
    required this.purchaseId,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.quantity,
    required this.price,
    required this.currencyId,
    required this.status,
    required this.timestamp,
    this.discountId,
    this.originalPrice,
    required this.metadata,
  });
}

class ItemShopManager {
  static final ItemShopManager _instance = ItemShopManager._();
  static ItemShopManager get instance => _instance;

  ItemShopManager._();

  final Map<String, ShopItem> _shopItems = {};
  final Map<String, ShopBundle> _shopBundles = {};
  final Map<String, ShopDiscount> _discounts = {};
  final Map<String, ShopRotation> _rotations = {};
  final Map<String, List<Purchase>> _purchaseHistory = {};
  final Map<String, int> _userPurchaseCounts = {};
  final StreamController<ShopEvent> _eventController = StreamController.broadcast();
  Timer? _rotationTimer;

  Stream<ShopEvent> get onShopEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultItems();
    await _loadDefaultBundles();
    await _loadDefaultDiscounts();
    await _loadDefaultRotations();
    _startRotationTimer();
  }

  Future<void> _loadDefaultItems() async {
    final items = [
      ShopItem(
        itemId: 'health_potion_10',
        name: 'Health Potion x10',
        description: 'Bundle of 10 health potions',
        icon: 'health_potion_icon',
        itemType: 'consumable',
        quantity: 10,
        basePrice: 100,
        currencyId: 'gold',
        maxPurchaseLimit: -1,
        currentPurchaseCount: 0,
        isLimited: false,
        isExclusive: false,
        isFeatured: false,
        tags: ['consumable', 'heal'],
        metadata: {},
        sortOrder: 1,
      ),
      ShopItem(
        itemId: 'premium_pack',
        name: 'Premium Pack',
        description: 'Exclusive premium items',
        icon: 'premium_pack_icon',
        itemType: 'bundle',
        quantity: 1,
        basePrice: 500,
        currencyId: 'gems',
        maxPurchaseLimit: 5,
        currentPurchaseCount: 0,
        isLimited: true,
        isExclusive: true,
        isFeatured: true,
        tags: ['premium', 'exclusive'],
        metadata: {},
        sortOrder: 0,
      ),
    ];

    for (final item in items) {
      _shopItems[item.itemId] = item;
    }
  }

  Future<void> _loadDefaultBundles() async {
    final bundles = [
      ShopBundle(
        bundleId: 'starter_pack',
        name: 'Starter Pack',
        description: 'Perfect for new players',
        icon: 'starter_pack_icon',
        items: const [
          BundleItem(
            itemId: 'health_potion',
            name: 'Health Potion',
            quantity: 50,
            icon: 'health_potion_icon',
            metadata: {},
          ),
          BundleItem(
            itemId: 'gold',
            name: 'Gold',
            quantity: 1000,
            icon: 'gold_icon',
            metadata: {},
          ),
        ],
        totalPrice: 1500,
        discountedPrice: 500,
        savings: 1000,
        currencyId: 'gems',
        isLimited: true,
        purchaseLimit: 1,
        purchaseCount: 0,
        tags: ['starter', 'bundle'],
      ),
    ];

    for (final bundle in bundles) {
      _shopBundles[bundle.bundleId] = bundle;
    }
  }

  Future<void> _loadDefaultDiscounts() async {
    final discounts = [
      ShopDiscount(
        discountId: 'daily_20',
        itemId: 'all',
        type: DiscountType.percentage,
        value: 20,
        maxUses: 0,
        currentUses: 0,
        applicableItems: ['health_potion_10'],
      ),
    ];

    for (final discount in discounts) {
      _discounts[discount.discountId] = discount;
    }
  }

  Future<void> _loadDefaultRotations() async {
    final now = DateTime.now();
    final rotations = [
      ShopRotation(
        rotationId: 'daily_rotation',
        name: 'Daily Special',
        itemIds: ['health_potion_10'],
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        durationHours: 24,
        isActive: true,
      ),
    ];

    for (final rotation in rotations) {
      _rotations[rotation.rotationId] = rotation;
    }
  }

  void _startRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkRotations(),
    );
  }

  void _checkRotations() {
    final now = DateTime.now();
    for (final rotation in _rotations.values) {
      if (rotation.isCurrent && !rotation.isActive) {
        _activateRotation(rotation.rotationId);
      }
    }
  }

  void _activateRotation(String rotationId) {
    _eventController.add(ShopEvent(
      type: ShopEventType.rotationUpdated,
      timestamp: DateTime.now(),
      data: {'rotationId': rotationId},
    ));
  }

  List<ShopItem> getAllItems() {
    return _shopItems.values.where((item) => item.isAvailable).toList();
  }

  List<ShopItem> getFeaturedItems() {
    return _shopItems.values
        .where((item) => item.isFeatured && item.isAvailable)
        .toList();
  }

  List<ShopItem> getItemsByTag(String tag) {
    return _shopItems.values
        .where((item) => item.tags.contains(tag) && item.isAvailable)
        .toList();
  }

  ShopItem? getItem(String itemId) {
    return _shopItems[itemId];
  }

  List<ShopBundle> getAllBundles() {
    return _shopBundles.values.where((bundle) => bundle.isAvailable).toList();
  }

  ShopBundle? getBundle(String bundleId) {
    return _shopBundles[bundleId];
  }

  ShopDiscount? getDiscount(String discountId) {
    return _discounts[discountId];
  }

  ShopDiscount? getApplicableDiscount(String itemId, String? discountCode) {
    for (final discount in _discounts.values) {
      if (!discount.isActive) continue;
      if (discountCode != null && discount.code != discountCode) continue;
      if (discount.applicableItems.contains(itemId) || discount.applicableItems.contains('all')) {
        return discount;
      }
    }
    return null;
  }

  int calculatePrice(String itemId, {String? discountCode}) {
    final item = _shopItems[itemId];
    if (item == null) return 0;

    var price = item.basePrice;
    final discount = getApplicableDiscount(itemId, discountCode);
    if (discount != null) {
      price -= discount.calculateDiscount(price);
    }

    return price.clamp(0, price);
  }

  Future<Purchase?> purchaseItem({
    required String userId,
    required String itemId,
    String? discountCode,
  }) async {
    final item = _shopItems[itemId];
    if (item == null) return null;
    if (!item.isAvailable) return null;

    final price = calculatePrice(itemId, discountCode: discountCode);
    final discount = getApplicableDiscount(itemId, discountCode);

    final userPurchases = _userPurchaseCounts[userId] ?? {};
    final purchaseCount = userPurchases[itemId] ?? 0;

    if (item.isLimited && purchaseCount >= item.maxPurchaseLimit) {
      _eventController.add(ShopEvent(
        type: ShopEventType.purchaseFailed,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'reason': 'limit_exceeded', 'itemId': itemId},
      ));
      return null;
    }

    final purchase = Purchase(
      purchaseId: 'purchase_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      itemId: itemId,
      itemType: item.itemType,
      quantity: item.quantity,
      price: price,
      currencyId: item.currencyId,
      status: PurchaseStatus.completed,
      timestamp: DateTime.now(),
      discountId: discount?.discountId,
      originalPrice: item.basePrice,
      metadata: {},
    );

    _addPurchase(userId, purchase);
    _updatePurchaseCount(userId, itemId);

    _eventController.add(ShopEvent(
      type: ShopEventType.purchaseCompleted,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'itemId': itemId, 'price': price},
    ));

    return purchase;
  }

  Future<Purchase?> purchaseBundle({
    required String userId,
    required String bundleId,
  }) async {
    final bundle = _shopBundles[bundleId];
    if (bundle == null) return null;
    if (!bundle.isAvailable) return null;

    final userPurchases = _userPurchaseCounts[userId] ?? {};
    final purchaseCount = userPurchases[bundleId] ?? 0;

    if (bundle.isLimited && purchaseCount >= bundle.purchaseLimit) {
      _eventController.add(ShopEvent(
        type: ShopEventType.purchaseFailed,
        userId: userId,
        timestamp: DateTime.now(),
        data: {'reason': 'limit_exceeded', 'bundleId': bundleId},
      ));
      return null;
    }

    final purchase = Purchase(
      purchaseId: 'purchase_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      itemId: bundleId,
      itemType: 'bundle',
      quantity: 1,
      price: bundle.discountedPrice,
      currencyId: bundle.currencyId,
      status: PurchaseStatus.completed,
      timestamp: DateTime.now(),
      metadata: {'bundleItems': bundle.items.map((i) => i.itemId).toList()},
    );

    _addPurchase(userId, purchase);
    _updatePurchaseCount(userId, bundleId);

    _eventController.add(ShopEvent(
      type: ShopEventType.bundlePurchased,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'bundleId': bundleId, 'price': bundle.discountedPrice},
    ));

    return purchase;
  }

  void _addPurchase(String userId, Purchase purchase) {
    _purchaseHistory.putIfAbsent(userId, () => []);
    _purchaseHistory[userId]!.insert(0, purchase);

    if (_purchaseHistory[userId]!.length > 1000) {
      _purchaseHistory[userId]!.removeLast();
    }
  }

  void _updatePurchaseCount(String userId, String itemId) {
    _userPurchaseCounts.putIfAbsent(userId, () => {});
    _userPurchaseCounts[userId]![itemId] = (_userPurchaseCounts[userId]![itemId] ?? 0) + 1;
  }

  List<Purchase> getPurchaseHistory(String userId, {int limit = 100}) {
    final purchases = _purchaseHistory[userId] ?? [];
    if (purchases.length > limit) {
      return purchases.sublist(0, limit);
    }
    return purchases;
  }

  int getRemainingPurchases(String userId, String itemId) {
    final item = _shopItems[itemId];
    if (item == null || !item.isLimited) return -1;

    final userPurchases = _userPurchaseCounts[userId] ?? {};
    final purchaseCount = userPurchases[itemId] ?? 0;
    return item.maxPurchaseLimit - purchaseCount;
  }

  Map<String, dynamic> getShopStats(String userId) {
    final purchases = getPurchaseHistory(userId);
    final totalSpent = purchases.fold<int>(0, (sum, p) => sum + p.price);

    return {
      'totalPurchases': purchases.length,
      'totalSpent': totalSpent,
      'availableItems': getAllItems().length,
      'availableBundles': getAllBundles().length,
      'activeDiscounts': _discounts.values.where((d) => d.isActive).length,
    };
  }

  void dispose() {
    _rotationTimer?.cancel();
    _eventController.close();
  }
}

class ShopEvent {
  final ShopEventType type;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const ShopEvent({
    required this.type,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum ShopEventType {
  itemAdded,
  itemRemoved,
  priceChanged,
  discountAdded,
  discountExpired,
  rotationUpdated,
  purchaseCompleted,
  purchaseFailed,
  bundlePurchased,
  shopRefreshed,
}

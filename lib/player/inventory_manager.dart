import 'dart:async';
import 'package:flutter/material.dart';

enum ItemType {
  weapon,
  armor,
  accessory,
  consumable,
  material,
  quest,
  currency,
  special,
}

enum ItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum ItemCategory {
  equipment,
  consumables,
  materials,
  questItems,
  currencies,
  special,
}

class InventorySlot {
  final int slotIndex;
  final String? itemId;
  final int quantity;
  final bool isLocked;
  final DateTime? lockedUntil;

  const InventorySlot({
    required this.slotIndex,
    this.itemId,
    required this.quantity,
    required this.isLocked,
    this.lockedUntil,
  });

  bool get isEmpty => itemId == null || quantity <= 0;
  bool get isExpired => lockedUntil != null && DateTime.now().isAfter(lockedUntil!);
}

class Item {
  final String itemId;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final ItemCategory category;
  final String icon;
  final int maxStackSize;
  final bool isStackable;
  final bool isTradeable;
  final bool isSellable;
  final int sellPrice;
  final Map<String, dynamic> stats;
  final List<String> tags;
  final int levelRequirement;
  final DateTime? expiryDate;

  const Item({
    required this.itemId,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.category,
    required this.icon,
    required this.maxStackSize,
    required this.isStackable,
    required this.isTradeable,
    required this.isSellable,
    required this.sellPrice,
    required this.stats,
    required this.tags,
    required this.levelRequirement,
    this.expiryDate,
  });
}

class InventoryItem {
  final String inventoryItemId;
  final String itemId;
  final String name;
  final ItemType type;
  final ItemRarity rarity;
  final int quantity;
  final int slotIndex;
  final DateTime? acquiredAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final bool isLocked;
  final int durability;
  final int maxDurability;

  const InventoryItem({
    required this.inventoryItemId,
    required this.itemId,
    required this.name,
    required this.type,
    required this.rarity,
    required this.quantity,
    required this.slotIndex,
    this.acquiredAt,
    this.expiresAt,
    required this.metadata,
    required this.isLocked,
    required this.durability,
    required this.maxDurability,
  });

  double get durabilityPercent => maxDurability > 0 ? durability / maxDurability : 1.0;
  bool get isBroken => durability <= 0;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class InventoryTab {
  final String tabId;
  final String name;
  final String icon;
  final List<ItemCategory> categories;
  final int slotCount;
  final int unlockedSlots;

  const InventoryTab({
    required this.tabId,
    required this.name,
    required this.icon,
    required this.categories,
    required this.slotCount,
    required this.unlockedSlots,
  });

  double get unlockProgress => slotCount > 0 ? unlockedSlots / slotCount : 1.0;
}

class InventoryManager {
  static final InventoryManager _instance = InventoryManager._();
  static InventoryManager get instance => _instance;

  InventoryManager._();

  final Map<String, List<InventoryItem>> _inventories = {};
  final Map<String, Item> _itemDefinitions = {};
  final Map<String, List<InventoryTab>> _inventoryTabs = {};
  final StreamController<InventoryEvent> _eventController = StreamController.broadcast();
  Timer? _cleanupTimer;

  Stream<InventoryEvent> get onInventoryEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultItems();
    await _loadDefaultTabs();
    _startCleanupTimer();
  }

  Future<void> _loadDefaultItems() async {
    final items = [
      Item(
        itemId: 'health_potion',
        name: 'Health Potion',
        description: 'Restores 100 HP',
        type: ItemType.consumable,
        rarity: ItemRarity.common,
        category: ItemCategory.consumables,
        icon: 'health_potion_icon',
        maxStackSize: 99,
        isStackable: true,
        isTradeable: true,
        isSellable: true,
        sellPrice: 10,
        stats: {'healAmount': 100},
        tags: ['heal', 'consumable'],
        levelRequirement: 1,
      ),
      Item(
        itemId: 'iron_sword',
        name: 'Iron Sword',
        description: 'A basic iron sword',
        type: ItemType.weapon,
        rarity: ItemRarity.common,
        category: ItemCategory.equipment,
        icon: 'iron_sword_icon',
        maxStackSize: 1,
        isStackable: false,
        isTradeable: true,
        isSellable: true,
        sellPrice: 50,
        stats: {'attack': 15, 'speed': 5},
        tags: ['weapon', 'melee'],
        levelRequirement: 1,
      ),
      Item(
        itemId: 'gold_coin',
        name: 'Gold Coin',
        description: 'Currency',
        type: ItemType.currency,
        rarity: ItemRarity.common,
        category: ItemCategory.currencies,
        icon: 'gold_coin_icon',
        maxStackSize: 999999,
        isStackable: true,
        isTradeable: true,
        isSellable: false,
        sellPrice: 0,
        stats: {},
        tags: ['currency', 'gold'],
        levelRequirement: 1,
      ),
    ];

    for (final item in items) {
      _itemDefinitions[item.itemId] = item;
    }
  }

  Future<void> _loadDefaultTabs() async {
    final tabs = [
      InventoryTab(
        tabId: 'all',
        name: 'All',
        icon: 'all_icon',
        categories: ItemCategory.values,
        slotCount: 100,
        unlockedSlots: 20,
      ),
      InventoryTab(
        tabId: 'equipment',
        name: 'Equipment',
        icon: 'equipment_icon',
        categories: [ItemCategory.equipment],
        slotCount: 50,
        unlockedSlots: 10,
      ),
      InventoryTab(
        tabId: 'consumables',
        name: 'Consumables',
        icon: 'consumables_icon',
        categories: [ItemCategory.consumables],
        slotCount: 50,
        unlockedSlots: 10,
      ),
    ];

    for (final userId in _inventories.keys) {
      _inventoryTabs[userId] = tabs;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredItems(),
    );
  }

  List<InventoryItem> getInventory(String userId) {
    return _inventories[userId] ?? [];
  }

  List<InventoryItem> getItemsByType(String userId, ItemType type) {
    final inventory = getInventory(userId);
    return inventory.where((item) => item.type == type).toList();
  }

  List<InventoryItem> getItemsByRarity(String userId, ItemRarity rarity) {
    final inventory = getInventory(userId);
    return inventory.where((item) => item.rarity == rarity).toList();
  }

  List<InventoryItem> getItemsByCategory(String userId, ItemCategory category) {
    final inventory = getInventory(userId);
    return inventory.where((item) => _itemDefinitions[item.itemId]?.category == category).toList();
  }

  InventoryItem? getItem(String userId, String inventoryItemId) {
    final inventory = getInventory(userId);
    try {
      return inventory.firstWhere((item) => item.inventoryItemId == inventoryItemId);
    } catch (e) {
      return null;
    }
  }

  int getItemCount(String userId, String itemId) {
    final inventory = getInventory(userId);
    return inventory
        .where((item) => item.itemId == itemId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<bool> addItem({
    required String userId,
    required String itemId,
    required int quantity,
    Map<String, dynamic>? metadata,
  }) async {
    final itemDef = _itemDefinitions[itemId];
    if (itemDef == null) return false;

    _inventories.putIfAbsent(userId, () => []);
    final inventory = _inventories[userId]!;

    if (itemDef.isStackable) {
      final existingIndex = inventory.indexWhere((item) => item.itemId == itemId);
      if (existingIndex >= 0) {
        final existing = inventory[existingIndex];
        final newQuantity = (existing.quantity + quantity).clamp(0, itemDef.maxStackSize);

        final updated = InventoryItem(
          inventoryItemId: existing.inventoryItemId,
          itemId: existing.itemId,
          name: existing.name,
          type: existing.type,
          rarity: existing.rarity,
          quantity: newQuantity,
          slotIndex: existing.slotIndex,
          acquiredAt: existing.acquiredAt,
          expiresAt: existing.expiresAt,
          metadata: existing.metadata,
          isLocked: existing.isLocked,
          durability: existing.durability,
          maxDurability: existing.maxDurability,
        );

        inventory[existingIndex] = updated;
      } else {
        final slotIndex = _findFirstAvailableSlot(userId);
        if (slotIndex < 0) return false;

        final newItem = InventoryItem(
          inventoryItemId: 'inv_${DateTime.now().millisecondsSinceEpoch}',
          itemId: itemId,
          name: itemDef.name,
          type: itemDef.type,
          rarity: itemDef.rarity,
          quantity: quantity.clamp(0, itemDef.maxStackSize),
          slotIndex: slotIndex,
          acquiredAt: DateTime.now(),
          expiresAt: itemDef.expiryDate,
          metadata: metadata ?? {},
          isLocked: false,
          durability: itemDef.type == ItemType.weapon || itemDef.type == ItemType.armor ? 100 : 0,
          maxDurability: itemDef.type == ItemType.weapon || itemDef.type == ItemType.armor ? 100 : 0,
        );

        inventory.add(newItem);
      }
    } else {
      for (int i = 0; i < quantity; i++) {
        final slotIndex = _findFirstAvailableSlot(userId);
        if (slotIndex < 0) return false;

        final newItem = InventoryItem(
          inventoryItemId: 'inv_${DateTime.now().millisecondsSinceEpoch}_$i',
          itemId: itemId,
          name: itemDef.name,
          type: itemDef.type,
          rarity: itemDef.rarity,
          quantity: 1,
          slotIndex: slotIndex,
          acquiredAt: DateTime.now(),
          expiresAt: itemDef.expiryDate,
          metadata: metadata ?? {},
          isLocked: false,
          durability: itemDef.type == ItemType.weapon || itemDef.type == ItemType.armor ? 100 : 0,
          maxDurability: itemDef.type == ItemType.weapon || itemDef.type == ItemType.armor ? 100 : 0,
        );

        inventory.add(newItem);
      }
    }

    _eventController.add(InventoryEvent(
      type: InventoryEventType.itemAdded,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'itemId': itemId, 'quantity': quantity},
    ));

    return true;
  }

  int _findFirstAvailableSlot(String userId) {
    final inventory = getInventory(userId);
    final usedSlots = inventory.map((item) => item.slotIndex).toSet();

    for (int i = 0; i < 100; i++) {
      if (!usedSlots.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  Future<bool> removeItem({
    required String userId,
    required String inventoryItemId,
    required int quantity,
  }) async {
    final inventory = _inventories[userId];
    if (inventory == null) return false;

    final index = inventory.indexWhere((item) => item.inventoryItemId == inventoryItemId);
    if (index < 0) return false;

    final item = inventory[index];
    if (item.quantity < quantity) return false;

    if (item.quantity <= quantity) {
      inventory.removeAt(index);
    } else {
      final updated = InventoryItem(
        inventoryItemId: item.inventoryItemId,
        itemId: item.itemId,
        name: item.name,
        type: item.type,
        rarity: item.rarity,
        quantity: item.quantity - quantity,
        slotIndex: item.slotIndex,
        acquiredAt: item.acquiredAt,
        expiresAt: item.expiresAt,
        metadata: item.metadata,
        isLocked: item.isLocked,
        durability: item.durability,
        maxDurability: item.maxDurability,
      );

      inventory[index] = updated;
    }

    _eventController.add(InventoryEvent(
      type: InventoryEventType.itemRemoved,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'inventoryItemId': inventoryItemId, 'quantity': quantity},
    ));

    return true;
  }

  Future<bool> moveItem({
    required String userId,
    required String inventoryItemId,
    required int newSlotIndex,
  }) async {
    final inventory = _inventories[userId];
    if (inventory == null) return false;

    final index = inventory.indexWhere((item) => item.inventoryItemId == inventoryItemId);
    if (index < 0) return false;

    final item = inventory[index];
    final existingInSlot = inventory.indexWhere((i) => i.slotIndex == newSlotIndex);

    final updated = InventoryItem(
      inventoryItemId: item.inventoryItemId,
      itemId: item.itemId,
      name: item.name,
      type: item.type,
      rarity: item.rarity,
      quantity: item.quantity,
      slotIndex: newSlotIndex,
      acquiredAt: item.acquiredAt,
      expiresAt: item.expiresAt,
      metadata: item.metadata,
      isLocked: item.isLocked,
      durability: item.durability,
      maxDurability: item.maxDurability,
    );

    inventory[index] = updated;

    if (existingInSlot >= 0 && existingInSlot != index) {
      final otherItem = inventory[existingInSlot];
      final updatedOther = InventoryItem(
        inventoryItemId: otherItem.inventoryItemId,
        itemId: otherItem.itemId,
        name: otherItem.name,
        type: otherItem.type,
        rarity: otherItem.rarity,
        quantity: otherItem.quantity,
        slotIndex: item.slotIndex,
        acquiredAt: otherItem.acquiredAt,
        expiresAt: otherItem.expiresAt,
        metadata: otherItem.metadata,
        isLocked: otherItem.isLocked,
        durability: otherItem.durability,
        maxDurability: otherItem.maxDurability,
      );

      inventory[existingInSlot] = updatedOther;
    }

    _eventController.add(InventoryEvent(
      type: InventoryEventType.itemMoved,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'inventoryItemId': inventoryItemId, 'newSlotIndex': newSlotIndex},
    ));

    return true;
  }

  Future<bool> lockItem({
    required String userId,
    required String inventoryItemId,
    required bool lock,
  }) async {
    final inventory = _inventories[userId];
    if (inventory == null) return false;

    final index = inventory.indexWhere((item) => item.inventoryItemId == inventoryItemId);
    if (index < 0) return false;

    final item = inventory[index];
    if (item.isLocked == lock) return true;

    final updated = InventoryItem(
      inventoryItemId: item.inventoryItemId,
      itemId: item.itemId,
      name: item.name,
      type: item.type,
      rarity: item.rarity,
      quantity: item.quantity,
      slotIndex: item.slotIndex,
      acquiredAt: item.acquiredAt,
      expiresAt: item.expiresAt,
      metadata: item.metadata,
      isLocked: lock,
      durability: item.durability,
      maxDurability: item.maxDurability,
    );

    inventory[index] = updated;

    _eventController.add(InventoryEvent(
      type: InventoryEventType.itemLocked,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'inventoryItemId': inventoryItemId, 'locked': lock},
    ));

    return true;
  }

  bool hasItem(String userId, String itemId, {int quantity = 1}) {
    return getItemCount(userId, itemId) >= quantity;
  }

  bool hasSpace(String userId, {int slots = 1}) {
    final inventory = getInventory(userId);
    return (100 - inventory.length) >= slots;
  }

  int getAvailableSlots(String userId) {
    final inventory = getInventory(userId);
    return 100 - inventory.length;
  }

  Map<String, dynamic> getInventoryStats(String userId) {
    final inventory = getInventory(userId);
    final byType = <ItemType, int>{};
    final byRarity = <ItemRarity, int>{};

    for (final item in inventory) {
      byType[item.type] = (byType[item.type] ?? 0) + item.quantity;
      byRarity[item.rarity] = (byRarity[item.rarity] ?? 0) + 1;
    }

    return {
      'totalItems': inventory.length,
      'totalSlots': 100,
      'usedSlots': inventory.length,
      'availableSlots': 100 - inventory.length,
      'itemsByType': byType.map((k, v) => MapEntry(k.name, v)),
      'itemsByRarity': byRarity.map((k, v) => MapEntry(k.name, v)),
    };
  }

  void _cleanupExpiredItems() {
    for (final userId in _inventories.keys) {
      final inventory = _inventories[userId];
      if (inventory == null) continue;

      inventory.removeWhere((item) => item.isExpired);
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();
  }
}

class InventoryEvent {
  final InventoryEventType type;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const InventoryEvent({
    required this.type,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum InventoryEventType {
  itemAdded,
  itemRemoved,
  itemMoved,
  itemLocked,
  itemExpired,
  itemUsed,
  itemCrafted,
  slotUnlocked,
  inventoryFull,
}

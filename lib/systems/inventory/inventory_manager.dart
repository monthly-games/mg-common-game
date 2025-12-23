import 'inventory_item.dart';

/// Result of an inventory operation
class InventoryResult {
  final bool success;
  final String? message;
  final int? actualAmount; // Actual amount added/removed

  const InventoryResult({
    required this.success,
    this.message,
    this.actualAmount,
  });

  factory InventoryResult.success({int? actualAmount}) {
    return InventoryResult(
      success: true,
      actualAmount: actualAmount,
    );
  }

  factory InventoryResult.failure(String message) {
    return InventoryResult(
      success: false,
      message: message,
    );
  }
}

/// Manager for inventory system
class InventoryManager {
  final Map<String, InventoryItem> _items = {};
  int _maxSlots;
  int _maxStackSize;

  InventoryManager({
    int maxSlots = 100,
    int maxStackSize = 999,
  })  : _maxSlots = maxSlots,
        _maxStackSize = maxStackSize;

  /// Get max slots
  int get maxSlots => _maxSlots;

  /// Set max slots
  void setMaxSlots(int slots) {
    _maxSlots = slots;
  }

  /// Get max stack size
  int get maxStackSize => _maxStackSize;

  /// Get all items
  Map<String, InventoryItem> get items => Map.unmodifiable(_items);

  /// Get item by ID
  InventoryItem? getItem(String itemId) {
    return _items[itemId];
  }

  /// Get item amount
  int getAmount(String itemId) {
    return _items[itemId]?.amount ?? 0;
  }

  /// Check if item exists
  bool hasItem(String itemId, [int amount = 1]) {
    final item = _items[itemId];
    if (item == null) return false;
    return item.amount >= amount;
  }

  /// Get current slot count (unique items)
  int get slotCount => _items.length;

  /// Check if inventory is full
  bool get isFull => slotCount >= _maxSlots;

  /// Get available slots
  int get availableSlots => _maxSlots - slotCount;

  /// Get total item count across all stacks
  int get totalItemCount {
    return _items.values.fold(0, (sum, item) => sum + item.amount);
  }

  /// Add item to inventory
  InventoryResult addItem(
    String itemId,
    int amount, {
    Map<String, dynamic>? metadata,
  }) {
    if (amount <= 0) {
      return InventoryResult.failure('Amount must be positive');
    }

    // Check if item exists
    if (_items.containsKey(itemId)) {
      // Add to existing stack
      final item = _items[itemId]!;
      final newAmount = item.amount + amount;

      // Check max stack size
      if (newAmount > _maxStackSize) {
        final actualAmount = _maxStackSize - item.amount;
        item.amount = _maxStackSize;
        return InventoryResult.success(actualAmount: actualAmount);
      }

      item.amount = newAmount;
      return InventoryResult.success(actualAmount: amount);
    } else {
      // Check if slots available
      if (isFull) {
        return InventoryResult.failure('Inventory is full');
      }

      // Create new item
      _items[itemId] = InventoryItem(
        id: itemId,
        amount: amount.clamp(0, _maxStackSize),
        acquiredTime: DateTime.now(),
        metadata: metadata,
      );

      return InventoryResult.success(
          actualAmount: amount.clamp(0, _maxStackSize));
    }
  }

  /// Remove item from inventory
  InventoryResult removeItem(String itemId, int amount) {
    if (amount <= 0) {
      return InventoryResult.failure('Amount must be positive');
    }

    if (!_items.containsKey(itemId)) {
      return InventoryResult.failure('Item not found');
    }

    final item = _items[itemId]!;

    if (item.amount < amount) {
      return InventoryResult.failure('Not enough items');
    }

    item.amount -= amount;

    // Remove item if amount reaches 0
    if (item.amount <= 0) {
      _items.remove(itemId);
    }

    return InventoryResult.success(actualAmount: amount);
  }

  /// Remove all of an item
  InventoryResult removeAllItem(String itemId) {
    if (!_items.containsKey(itemId)) {
      return InventoryResult.failure('Item not found');
    }

    final amount = _items[itemId]!.amount;
    _items.remove(itemId);

    return InventoryResult.success(actualAmount: amount);
  }

  /// Transfer item to another inventory
  InventoryResult transferItem(
    String itemId,
    int amount,
    InventoryManager targetInventory,
  ) {
    // Check if we have the item
    if (!hasItem(itemId, amount)) {
      return InventoryResult.failure('Not enough items to transfer');
    }

    // Try to add to target
    final addResult = targetInventory.addItem(itemId, amount);
    if (!addResult.success) {
      return addResult;
    }

    // Remove from source
    final actualAmount = addResult.actualAmount ?? amount;
    final removeResult = removeItem(itemId, actualAmount);

    if (!removeResult.success) {
      // Rollback target
      targetInventory.removeItem(itemId, actualAmount);
      return removeResult;
    }

    return InventoryResult.success(actualAmount: actualAmount);
  }

  /// Sort items by ID
  List<InventoryItem> getSortedItems({
    int Function(InventoryItem a, InventoryItem b)? comparator,
  }) {
    final items = _items.values.toList();

    if (comparator != null) {
      items.sort(comparator);
    } else {
      // Default: sort by ID
      items.sort((a, b) => a.id.compareTo(b.id));
    }

    return items;
  }

  /// Filter items by predicate
  List<InventoryItem> filterItems(bool Function(InventoryItem) predicate) {
    return _items.values.where(predicate).toList();
  }

  /// Get items by category (requires metadata)
  List<InventoryItem> getItemsByCategory(String category) {
    return filterItems((item) {
      return item.metadata?['category'] == category;
    });
  }

  /// Clear all items
  void clear() {
    _items.clear();
  }

  /// Get storage percentage (0.0 to 1.0)
  double get storagePercentage => slotCount / _maxSlots;

  /// Check if can add item (considering slots)
  bool canAddItem(String itemId, int amount) {
    if (_items.containsKey(itemId)) {
      // Can add to existing stack
      final item = _items[itemId]!;
      return item.amount + amount <= _maxStackSize;
    } else {
      // Need new slot
      return !isFull;
    }
  }

  /// Batch add items
  Map<String, InventoryResult> addItems(Map<String, int> itemsToAdd) {
    final results = <String, InventoryResult>{};

    for (final entry in itemsToAdd.entries) {
      results[entry.key] = addItem(entry.key, entry.value);
    }

    return results;
  }

  /// Batch remove items
  Map<String, InventoryResult> removeItems(Map<String, int> itemsToRemove) {
    // First check if we have all items
    for (final entry in itemsToRemove.entries) {
      if (!hasItem(entry.key, entry.value)) {
        return {
          for (final key in itemsToRemove.keys)
            key: InventoryResult.failure('Not enough items'),
        };
      }
    }

    // Remove all items
    final results = <String, InventoryResult>{};
    for (final entry in itemsToRemove.entries) {
      results[entry.key] = removeItem(entry.key, entry.value);
    }

    return results;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((key, value) => MapEntry(key, value.toJson())),
      'maxSlots': _maxSlots,
      'maxStackSize': _maxStackSize,
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    _items.clear();

    if (json['items'] != null) {
      final itemsJson = json['items'] as Map<String, dynamic>;
      for (final entry in itemsJson.entries) {
        _items[entry.key] =
            InventoryItem.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _maxSlots = json['maxSlots'] as int? ?? 100;
    _maxStackSize = json['maxStackSize'] as int? ?? 999;
  }

  @override
  String toString() {
    return 'InventoryManager(slots: $slotCount/$_maxSlots, '
        'items: $totalItemCount)';
  }
}

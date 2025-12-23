import 'dart:async';
import 'package:mg_common_game/core/systems/rpg/item_data.dart';

class InventorySlot {
  final ItemData item;
  int quantity;

  InventorySlot(this.item, this.quantity);
}

class InventorySystem {
  final int capacity;
  final List<InventorySlot> _slots = [];
  final _controller = StreamController<List<InventorySlot>>.broadcast();

  InventorySystem({this.capacity = 20});

  List<InventorySlot> get slots => List.unmodifiable(_slots);
  Stream<List<InventorySlot>> get onInventoryChanged => _controller.stream;

  /// Returns total count of a specific item ID
  int getItemCount(String itemId) {
    return _slots
        .where((slot) => slot.item.id == itemId)
        .fold(0, (sum, slot) => sum + slot.quantity);
  }

  /// Adds an item to the inventory.
  /// Handles stacking and splitting items if they exceed maxStack.
  /// Returns true if all items were added, false if inventory full.
  bool addItem(ItemData item, int amount) {
    int remaining = amount;
    bool changed = false;

    // 1. Try to stack with existing slots
    for (final slot in _slots) {
      if (slot.item.id == item.id) {
        final space = item.maxStack - slot.quantity;
        if (space > 0) {
          final toAdd = remaining < space ? remaining : space;
          slot.quantity += toAdd;
          remaining -= toAdd;
          changed = true;
          if (remaining == 0) break;
        }
      }
    }

    // 2. Add as new slots
    if (remaining > 0) {
      while (remaining > 0) {
        if (_slots.length >= capacity) {
          if (changed) _notify();
          return false; // Inventory full
        }

        final toAdd = remaining < item.maxStack ? remaining : item.maxStack;
        _slots.add(InventorySlot(item, toAdd));
        remaining -= toAdd;
        changed = true;
      }
    }

    if (changed) _notify();
    return true;
  }

  /// Removes items by ID.
  /// Returns the actual amount removed.
  int removeItem(String itemId, int amount) {
    int remainingToRemove = amount;
    int actuallyRemoved = 0;
    bool changed = false;

    // Iterate backwards safely to remove slots
    for (int i = _slots.length - 1; i >= 0; i--) {
      if (remainingToRemove <= 0) break;

      final slot = _slots[i];
      if (slot.item.id == itemId) {
        changed = true;
        if (slot.quantity <= remainingToRemove) {
          // Consume entire slot
          actuallyRemoved += slot.quantity;
          remainingToRemove -= slot.quantity;
          _slots.removeAt(i);
        } else {
          // Partial remove
          slot.quantity -= remainingToRemove;
          actuallyRemoved += remainingToRemove;
          remainingToRemove = 0;
        }
      }
    }

    if (changed) _notify();
    return actuallyRemoved;
  }

  void _notify() {
    _controller.add(slots);
  }

  void dispose() {
    _controller.close();
  }
}

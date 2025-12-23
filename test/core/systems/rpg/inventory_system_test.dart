import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/systems/rpg/inventory_system.dart';
import 'package:mg_common_game/core/systems/rpg/item_data.dart';

void main() {
  group('InventorySystem', () {
    late InventorySystem inventory;
    final testItem =
        ItemData(id: 'potion_1', name: 'Health Potion', maxStack: 5);
    final swordItem = ItemData(id: 'sword_1', name: 'Iron Sword', maxStack: 1);

    setUp(() {
      inventory = InventorySystem(capacity: 10);
    });

    test('addItem adds new item correctly', () {
      inventory.addItem(testItem, 2);
      expect(inventory.getItemCount('potion_1'), 2);
    });

    test('addItem stacks existing items', () {
      inventory.addItem(testItem, 2);
      inventory.addItem(testItem, 1);
      expect(inventory.getItemCount('potion_1'), 3);
      expect(inventory.slots.length, 1); // Should still be 1 slot
    });

    test('addItem respects maxStack and splits into new slot', () {
      // Add 4 potions (maxStack 5)
      inventory.addItem(testItem, 4);
      // Add 2 more -> Total 6. Slot 1 (5), Slot 2 (1)
      inventory.addItem(testItem, 2);

      expect(inventory.getItemCount('potion_1'), 6);
      expect(inventory.slots.length, 2);
      expect(inventory.slots[0].quantity, 5);
      expect(inventory.slots[1].quantity, 1);
    });

    test('addItem fails if full', () {
      // Fill inventory with 10 different items
      for (int i = 0; i < 10; i++) {
        inventory.addItem(
            ItemData(id: 'item_$i', name: 'Item $i', maxStack: 1), 1);
      }

      // Try add 11th
      final success = inventory.addItem(testItem, 1);
      expect(success, false);
      expect(inventory.getItemCount('potion_1'), 0);
    });

    test('removeItem removes correctly', () {
      inventory.addItem(testItem, 5);
      inventory.removeItem('potion_1', 2);
      expect(inventory.getItemCount('potion_1'), 3);
    });

    test('removeItem removes slot when empty', () {
      inventory.addItem(testItem, 2);
      inventory.removeItem('potion_1', 2);
      expect(inventory.getItemCount('potion_1'), 0);
      expect(inventory.slots.isEmpty, true);
    });
  });
}

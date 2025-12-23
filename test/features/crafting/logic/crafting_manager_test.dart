import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/systems/rpg/inventory_system.dart';
import 'package:mg_common_game/core/systems/rpg/item_data.dart';
import 'package:mg_common_game/features/crafting/logic/crafting_manager.dart';
import 'package:mg_common_game/features/crafting/logic/recipe.dart';

void main() {
  group('CraftingManager', () {
    late InventorySystem inventory;
    late CraftingManager manager;

    final wood = ItemData(id: 'wood', name: 'Wood', maxStack: 10);
    final stick = ItemData(id: 'stick', name: 'Stick', maxStack: 10);

    // Recipe: 2 Wood -> 1 Stick, takes 5 seconds
    final recipe = Recipe(
      id: 'make_stick',
      inputs: {'wood': 2},
      outputs: {'stick': 1},
      durationSeconds: 5,
    );

    setUp(() {
      inventory = InventorySystem(capacity: 10);
      manager = CraftingManager(inventory);
    });

    test('canCraft checks inventory correctly', () {
      expect(manager.canCraft(recipe), false);

      inventory.addItem(wood, 1);
      expect(manager.canCraft(recipe), false);

      inventory.addItem(wood, 1); // Total 2
      expect(manager.canCraft(recipe), true);
    });

    test('startCraft consumes items and creates job', () {
      inventory.addItem(wood, 5);

      final job = manager.startCraft(recipe);
      expect(job, isNotNull);

      // Should have consumed 2 wood (5-2=3)
      expect(inventory.getItemCount('wood'), 3);

      // Job details
      expect(job!.recipeId, 'make_stick');
      expect(job.isFinished, false);
    });

    test('claim rewards item only when finished', () {
      inventory.addItem(wood, 2);
      final job = manager.startCraft(recipe)!; // 5 sec duration

      // Try claim immediately
      expect(manager.claim(job), false);
      expect(inventory.getItemCount('stick'), 0);

      // Simulate time passing (Hack: modifying finishTime for test)
      // Ideally we inject a Clock, but for simple logic test we can cheat or wait
      job.finishTime = DateTime.now().subtract(const Duration(seconds: 1));

      expect(manager.claim(job), true);
      expect(inventory.getItemCount('stick'), 1);
      expect(job.isClaimed, true);
    });
  });
}

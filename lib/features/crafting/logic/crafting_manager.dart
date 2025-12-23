import 'package:mg_common_game/core/systems/rpg/inventory_system.dart';
import 'package:mg_common_game/core/systems/rpg/item_data.dart';
import 'package:mg_common_game/features/crafting/logic/recipe.dart';

class CraftingJob {
  final String recipeId;
  DateTime finishTime; // Mutable for testing
  final Map<String, int> pendingOutputs;
  bool isClaimed = false;

  CraftingJob({
    required this.recipeId,
    required this.finishTime,
    required this.pendingOutputs,
  });

  bool get isFinished => DateTime.now().isAfter(finishTime);
}

class CraftingManager {
  final InventorySystem _inventory;
  final List<CraftingJob> _jobs = [];

  CraftingManager(this._inventory);

  List<CraftingJob> get activeJobs => _jobs.where((j) => !j.isClaimed).toList();

  bool canCraft(Recipe recipe) {
    for (final entry in recipe.inputs.entries) {
      if (_inventory.getItemCount(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }

  CraftingJob? startCraft(Recipe recipe) {
    if (!canCraft(recipe)) return null;

    // Consume ingredients
    for (final entry in recipe.inputs.entries) {
      _inventory.removeItem(entry.key, entry.value);
    }

    // Create Job
    final finishTime =
        DateTime.now().add(Duration(seconds: recipe.durationSeconds));
    final job = CraftingJob(
      recipeId: recipe.id,
      finishTime: finishTime,
      pendingOutputs: recipe.outputs,
    );

    _jobs.add(job);
    return job;
  }

  bool claim(CraftingJob job) {
    if (job.isClaimed) return false;
    if (!job.isFinished) return false;

    // Check if we can add to inventory (capacity check)
    // For simplicity, we assume we can add (or fail safely if full).
    // Ideally check capacity first.

    bool allAdded = true;
    // We iterate outputs. Note: ItemData is needed to add.
    // Since Recipe only holds IDs, we need a way to lookup ItemData.
    // For this generic system, we assume access to a Registry or we pass ItemData in Recipe?
    // Or we construct temporary ItemData?
    // The test constructs ItemData outside.
    // Let's assume we construct dummy ItemData or check specific IDs.
    // In a real game, use an ItemRegistry singleton.
    // HERE: We will construct basic ItemData from ID for logic.

    for (final entry in job.pendingOutputs.entries) {
      final item = ItemData(id: entry.key, name: entry.key); // Placeholder name
      final added = _inventory.addItem(item, entry.value);
      if (!added) allAdded = false;
    }

    if (allAdded) {
      job.isClaimed = true;
      _jobs.remove(job); // Or keep in history? removing for now.
    }

    return allAdded;
  }
}

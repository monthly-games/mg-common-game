import 'package:flutter/foundation.dart';
import 'package:mg_common_game/core/systems/save_manager.dart';
import 'collection.dart';
import 'collection_item.dart';
import 'collection_reward.dart';

/// Manager for collection system
/// 
/// Handles collection registration, item unlocking, progress tracking,
/// and milestone/completion reward claiming.
class CollectionManager extends ChangeNotifier implements Saveable {
  @override
  String get saveKey => 'collection';

  /// Registered collections by ID
  final Map<String, Collection> _collections = {};

  /// Unlocked items per collection: collectionId -> Set<itemId>
  final Map<String, Set<String>> _unlockedItems = {};

  /// Claimed milestone rewards: "collectionId:milestone"
  final Set<String> _claimedMilestones = {};

  /// Claimed completion rewards
  final Set<String> _claimedCompletions = {};

  /// Callback when item is unlocked
  void Function(String collectionId, String itemId)? onItemUnlocked;

  /// Callback when milestone reward is earned (not claimed)
  void Function(String collectionId, int milestone, CollectionReward reward)?
      onMilestoneEarned;

  /// Callback when collection is completed
  void Function(String collectionId, CollectionReward? reward)?
      onCollectionCompleted;

  /// Register a new collection
  void registerCollection(Collection collection) {
    if (_collections.containsKey(collection.id)) {
      debugPrint(
          'CollectionManager: Collection ${collection.id} already registered');
      return;
    }

    _collections[collection.id] = collection;
    _unlockedItems.putIfAbsent(collection.id, () => {});
    notifyListeners();
  }

  /// Register multiple collections at once
  void registerCollections(List<Collection> collections) {
    for (final collection in collections) {
      registerCollection(collection);
    }
  }

  /// Unlock an item in a collection
  /// Returns true if item was newly unlocked, false if already unlocked or invalid
  bool unlockItem(String collectionId, String itemId) {
    final collection = _collections[collectionId];
    if (collection == null) {
      debugPrint(
          'CollectionManager: Collection $collectionId not found');
      return false;
    }

    if (!collection.containsItem(itemId)) {
      debugPrint(
          'CollectionManager: Item $itemId not found in collection $collectionId');
      return false;
    }

    final unlockedSet = _unlockedItems[collectionId]!;
    if (unlockedSet.contains(itemId)) {
      return false; // Already unlocked
    }

    // Unlock the item
    unlockedSet.add(itemId);

    // Trigger callback
    onItemUnlocked?.call(collectionId, itemId);

    // Check for milestone rewards
    _checkMilestones(collectionId);

    // Check for completion
    _checkCompletion(collectionId);

    notifyListeners();
    return true;
  }

  /// Unlock multiple items at once
  /// Returns number of newly unlocked items
  int unlockItems(String collectionId, List<String> itemIds) {
    int unlockedCount = 0;
    for (final itemId in itemIds) {
      if (unlockItem(collectionId, itemId)) {
        unlockedCount++;
      }
    }
    return unlockedCount;
  }

  /// Check if an item is unlocked
  bool isItemUnlocked(String collectionId, String itemId) {
    return _unlockedItems[collectionId]?.contains(itemId) ?? false;
  }

  /// Get collection progress (0.0 to 1.0)
  double getProgress(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null || collection.totalItems == 0) {
      return 0.0;
    }

    final unlockedCount = _unlockedItems[collectionId]?.length ?? 0;
    return unlockedCount / collection.totalItems;
  }

  /// Get unlocked item count for a collection
  int getUnlockedCount(String collectionId) {
    return _unlockedItems[collectionId]?.length ?? 0;
  }

  /// Get total item count for a collection
  int getTotalCount(String collectionId) {
    return _collections[collectionId]?.totalItems ?? 0;
  }

  /// Check if collection is complete
  bool isCollectionComplete(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null) return false;

    // Empty collections cannot be completed
    if (collection.totalItems == 0) return false;

    final unlockedCount = _unlockedItems[collectionId]?.length ?? 0;
    return unlockedCount >= collection.totalItems;
  }

  /// Get unlocked items for a collection
  List<CollectionItem> getUnlockedItems(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null) return [];

    final unlockedSet = _unlockedItems[collectionId] ?? {};
    return collection.items
        .where((item) => unlockedSet.contains(item.id))
        .toList();
  }

  /// Get locked items for a collection
  List<CollectionItem> getLockedItems(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null) return [];

    final unlockedSet = _unlockedItems[collectionId] ?? {};
    return collection.items
        .where((item) => !unlockedSet.contains(item.id))
        .toList();
  }

  /// Get available (unclaimed) milestone rewards for a collection
  List<int> getAvailableMilestones(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null || collection.milestoneRewards == null) {
      return [];
    }

    final unlockedCount = _unlockedItems[collectionId]?.length ?? 0;
    final percentage = (unlockedCount / collection.totalItems * 100).floor();

    final available = <int>[];
    for (final milestone in collection.milestoneRewards!.keys) {
      final key = '$collectionId:$milestone';
      if (percentage >= milestone && !_claimedMilestones.contains(key)) {
        available.add(milestone);
      }
    }

    return available;
  }

  /// Claim a milestone reward
  /// Returns the reward if successfully claimed, null otherwise
  CollectionReward? claimMilestoneReward(String collectionId, int milestone) {
    final collection = _collections[collectionId];
    if (collection == null || collection.milestoneRewards == null) {
      return null;
    }

    final reward = collection.milestoneRewards![milestone];
    if (reward == null) {
      return null;
    }

    final key = '$collectionId:$milestone';
    if (_claimedMilestones.contains(key)) {
      return null; // Already claimed
    }

    // Check if milestone is actually reached
    final unlockedCount = _unlockedItems[collectionId]?.length ?? 0;
    final percentage = (unlockedCount / collection.totalItems * 100).floor();

    if (percentage < milestone) {
      return null; // Milestone not reached yet
    }

    // Claim the reward
    _claimedMilestones.add(key);
    notifyListeners();

    return reward;
  }

  /// Claim completion reward for a collection
  /// Returns the reward if successfully claimed, null otherwise
  CollectionReward? claimCompletionReward(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null || collection.completionReward == null) {
      return null;
    }

    if (_claimedCompletions.contains(collectionId)) {
      return null; // Already claimed
    }

    if (!isCollectionComplete(collectionId)) {
      return null; // Not complete yet
    }

    // Claim the reward
    _claimedCompletions.add(collectionId);
    notifyListeners();

    return collection.completionReward;
  }

  /// Check if completion reward has been claimed
  bool isCompletionRewardClaimed(String collectionId) {
    return _claimedCompletions.contains(collectionId);
  }

  /// Check if milestone reward has been claimed
  bool isMilestoneRewardClaimed(String collectionId, int milestone) {
    return _claimedMilestones.contains('$collectionId:$milestone');
  }

  /// Get collection by ID
  Collection? getCollection(String id) {
    return _collections[id];
  }

  /// Get all registered collections
  List<Collection> getAllCollections() {
    return _collections.values.toList();
  }

  /// Get collections by category
  List<Collection> getCollectionsByCategory(String category) {
    return _collections.values
        .where((collection) => collection.category == category)
        .toList();
  }

  /// Get visible collections (considering prerequisites and hidden status)
  List<Collection> getVisibleCollections() {
    return _collections.values.where((collection) {
      // If hidden and no items unlocked, don't show
      if (collection.hidden) {
        final unlockedCount = _unlockedItems[collection.id]?.length ?? 0;
        if (unlockedCount == 0) {
          return false;
        }
      }

      // Check prerequisites
      if (collection.prerequisites != null &&
          collection.prerequisites!.isNotEmpty) {
        for (final prereqId in collection.prerequisites!) {
          if (!isCollectionComplete(prereqId)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  /// Get total unlocked items across all collections
  int getTotalUnlockedItems() {
    return _unlockedItems.values
        .fold(0, (sum, set) => sum + set.length);
  }

  /// Get total items across all collections
  int getTotalItems() {
    return _collections.values
        .fold(0, (sum, collection) => sum + collection.totalItems);
  }

  /// Get overall progress across all collections (0.0 to 1.0)
  double getOverallProgress() {
    final total = getTotalItems();
    if (total == 0) return 0.0;

    final unlocked = getTotalUnlockedItems();
    return unlocked / total;
  }

  /// Reset a collection (for testing or prestige)
  void resetCollection(String collectionId) {
    _unlockedItems[collectionId]?.clear();
    _claimedMilestones.removeWhere((key) => key.startsWith('$collectionId:'));
    _claimedCompletions.remove(collectionId);
    notifyListeners();
  }

  /// Reset all collections
  void resetAll() {
    _unlockedItems.clear();
    _claimedMilestones.clear();
    _claimedCompletions.clear();
    
    // Reinitialize unlocked sets for registered collections
    for (final collectionId in _collections.keys) {
      _unlockedItems[collectionId] = {};
    }
    
    notifyListeners();
  }

  /// Check for new milestones reached
  void _checkMilestones(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null || collection.milestoneRewards == null) {
      return;
    }

    final unlockedCount = _unlockedItems[collectionId]?.length ?? 0;
    final percentage = (unlockedCount / collection.totalItems * 100).floor();

    for (final entry in collection.milestoneRewards!.entries) {
      final milestone = entry.key;
      final reward = entry.value;
      final key = '$collectionId:$milestone';

      if (percentage >= milestone && !_claimedMilestones.contains(key)) {
        // Milestone reached but not yet claimed
        onMilestoneEarned?.call(collectionId, milestone, reward);
      }
    }
  }

  /// Check for collection completion
  void _checkCompletion(String collectionId) {
    final collection = _collections[collectionId];
    if (collection == null) return;

    if (isCollectionComplete(collectionId) &&
        !_claimedCompletions.contains(collectionId)) {
      // Collection completed but reward not yet claimed
      onCollectionCompleted?.call(collectionId, collection.completionReward);
    }
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    return {
      'unlockedItems': _unlockedItems.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'claimedMilestones': _claimedMilestones.toList(),
      'claimedCompletions': _claimedCompletions.toList(),
    };
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    _unlockedItems.clear();
    _claimedMilestones.clear();
    _claimedCompletions.clear();

    // Load unlocked items
    if (data['unlockedItems'] != null) {
      final unlockedData = data['unlockedItems'] as Map<String, dynamic>;
      for (final entry in unlockedData.entries) {
        _unlockedItems[entry.key] =
            Set<String>.from(entry.value as List<dynamic>);
      }
    }

    // Load claimed milestones
    if (data['claimedMilestones'] != null) {
      _claimedMilestones.addAll(
        Set<String>.from(data['claimedMilestones'] as List<dynamic>),
      );
    }

    // Load claimed completions
    if (data['claimedCompletions'] != null) {
      _claimedCompletions.addAll(
        Set<String>.from(data['claimedCompletions'] as List<dynamic>),
      );
    }

    notifyListeners();
  }

  @override
  String toString() {
    return 'CollectionManager('
        'collections: ${_collections.length}, '
        'totalUnlocked: $getTotalUnlockedItems/$getTotalItems'
        ')';
  }
}

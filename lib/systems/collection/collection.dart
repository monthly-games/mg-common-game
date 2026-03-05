import 'collection_item.dart';
import 'collection_reward.dart';

/// A collection of items that can be completed for rewards
class Collection {
  /// Unique identifier for the collection
  final String id;

  /// Display name of the collection
  final String name;

  /// Description of the collection
  final String description;

  /// List of items in this collection
  final List<CollectionItem> items;

  /// Reward given when collection is 100% complete
  final CollectionReward? completionReward;

  /// Optional milestone rewards (e.g., at 25%, 50%, 75%)
  final Map<int, CollectionReward>? milestoneRewards;

  /// Category for grouping collections
  final String? category;

  /// Is this collection hidden until first item is unlocked?
  final bool hidden;

  /// Required collection IDs that must be completed before this one is visible
  final List<String>? prerequisites;

  const Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.items,
    this.completionReward,
    this.milestoneRewards,
    this.category,
    this.hidden = false,
    this.prerequisites,
  });

  /// Get total number of items in collection
  int get totalItems => items.length;

  /// Get item by ID
  CollectionItem? getItem(String itemId) {
    try {
      return items.firstWhere((item) => item.id == itemId);
    } catch (_) {
      return null;
    }
  }

  /// Check if collection contains item
  bool containsItem(String itemId) {
    return items.any((item) => item.id == itemId);
  }

  /// Get items by rarity
  List<CollectionItem> getItemsByRarity(String rarity) {
    return items.where((item) => item.rarity == rarity).toList();
  }

  /// Get items by category
  List<CollectionItem> getItemsByCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  /// Calculate percentage for milestone reward
  int? getMilestonePercentage(int unlockedCount) {
    if (milestoneRewards == null || milestoneRewards!.isEmpty) {
      return null;
    }

    final percentage = (unlockedCount / totalItems * 100).floor();

    // Find the highest milestone that has been reached
    final sortedMilestones = milestoneRewards!.keys.toList()..sort();

    for (int i = sortedMilestones.length - 1; i >= 0; i--) {
      if (percentage >= sortedMilestones[i]) {
        return sortedMilestones[i];
      }
    }

    return null;
  }

  /// Create from JSON
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      completionReward: json['completionReward'] != null
          ? CollectionReward.fromJson(
              json['completionReward'] as Map<String, dynamic>)
          : null,
      milestoneRewards: (json['milestoneRewards'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                int.parse(key),
                CollectionReward.fromJson(value as Map<String, dynamic>),
              )),
      category: json['category'] as String?,
      hidden: json['hidden'] as bool? ?? false,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      if (completionReward != null)
        'completionReward': completionReward!.toJson(),
      if (milestoneRewards != null)
        'milestoneRewards': milestoneRewards!.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      if (category != null) 'category': category,
      'hidden': hidden,
      if (prerequisites != null) 'prerequisites': prerequisites,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Collection(id: $id, name: $name, items: ${items.length})';
}

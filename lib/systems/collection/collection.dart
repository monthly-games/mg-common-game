import 'package:mg_common_game/systems/collection/collection_item.dart';
import 'package:mg_common_game/systems/collection/collection_reward.dart';

export 'package:mg_common_game/systems/collection/collection_item.dart';
export 'package:mg_common_game/systems/collection/collection_rarity.dart';
export 'package:mg_common_game/systems/collection/collection_reward.dart';
export 'package:mg_common_game/systems/collection/reward_type.dart';

/// A collection of items that can be completed for rewards.
class Collection {
  /// Stable collection identifier.
  final String id;

  /// Collection display name.
  final String name;

  /// Collection description text.
  final String description;

  /// Collection category used for grouping.
  final String category;

  /// List of items included in this collection.
  final List<CollectionItem> items;

  /// Milestone rewards keyed by completion percentage.
  final Map<int, CollectionReward>? milestoneRewards;

  /// Reward granted when the collection is fully completed.
  final CollectionReward? completionReward;

  /// Whether this collection stays hidden until progress starts.
  final bool hidden;

  /// Collection IDs that must be completed first.
  final List<String>? prerequisites;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'general',
    required this.items,
    this.milestoneRewards,
    this.completionReward,
    this.prerequisites,
    this.hidden = false,
  })  : assert(id != '', 'id must not be empty'),
        assert(name != '', 'name must not be empty'),
        assert(description != '', 'description must not be empty'),
        assert(category != '', 'category must not be empty'),
        assert(items.isNotEmpty, 'items must not be empty'),
        assert(
          milestoneRewards == null ||
              milestoneRewards.keys.every(
                (milestone) => milestone >= 0 && milestone <= 100,
              ),
          'milestone percentages must be in range 0..100',
        );

  /// Total number of items in this collection.
  int get totalItems => items.length;

  /// Returns true when this collection contains the given item ID.
  bool containsItem(String itemId) {
    return items.any((item) => item.id == itemId);
  }

  /// Creates a [Collection] from JSON data.
  factory Collection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawMilestones = json['milestoneRewards'] as Map<String, dynamic>?;

    return Collection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      items: rawItems
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(CollectionItem.fromJson)
          .toList(growable: false),
      milestoneRewards: rawMilestones?.map(
        (key, value) => MapEntry(
          int.parse(key),
          CollectionReward.fromJson((value as Map).cast<String, dynamic>()),
        ),
      ),
      completionReward: json['completionReward'] is Map
          ? CollectionReward.fromJson(
              (json['completionReward'] as Map).cast<String, dynamic>(),
            )
          : null,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.whereType<String>()
          .toList(growable: false),
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  /// Serializes this collection to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      if (milestoneRewards != null)
        'milestoneRewards': milestoneRewards!.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      if (completionReward != null)
        'completionReward': completionReward!.toJson(),
      if (prerequisites != null) 'prerequisites': prerequisites,
      'hidden': hidden,
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
      'Collection(id: $id, category: $category, items: ${items.length})';
}

/// Collection item model representing a single collectible item
class CollectionItem {
  /// Unique identifier for the item
  final String id;

  /// Display name of the item
  final String name;

  /// Description of the item
  final String description;

  /// Rarity tier (common, rare, epic, legendary, mythic)
  final String rarity;

  /// Optional icon asset path
  final String? iconPath;

  /// Optional category for grouping items
  final String? category;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const CollectionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    this.iconPath,
    this.category,
    this.metadata,
  });

  /// Create from JSON
  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rarity: json['rarity'] as String,
      iconPath: json['iconPath'] as String?,
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity,
      if (iconPath != null) 'iconPath': iconPath,
      if (category != null) 'category': category,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CollectionItem(id: $id, name: $name, rarity: $rarity)';
}

/// Predefined rarity tiers
class CollectionRarity {
  static const String common = 'common';
  static const String rare = 'rare';
  static const String epic = 'epic';
  static const String legendary = 'legendary';
  static const String mythic = 'mythic';

  /// Get rarity display color
  static int getColor(String rarity) {
    switch (rarity) {
      case common:
        return 0xFF9E9E9E; // Gray
      case rare:
        return 0xFF2196F3; // Blue
      case epic:
        return 0xFF9C27B0; // Purple
      case legendary:
        return 0xFFFFC107; // Gold
      case mythic:
        return 0xFFFF5722; // Red-Orange
      default:
        return 0xFF9E9E9E;
    }
  }

  /// Get rarity sort order (lower = more common)
  static int getSortOrder(String rarity) {
    switch (rarity) {
      case common:
        return 0;
      case rare:
        return 1;
      case epic:
        return 2;
      case legendary:
        return 3;
      case mythic:
        return 4;
      default:
        return -1;
    }
  }
}

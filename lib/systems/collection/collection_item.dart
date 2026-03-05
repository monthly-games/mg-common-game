import 'package:mg_common_game/systems/collection/collection_rarity.dart';

/// Individual item definition used in a [Collection].
class CollectionItem {
  /// Stable item identifier.
  final String id;

  /// Item display name.
  final String name;

  /// Item description text.
  final String description;

  /// Rarity tier.
  final CollectionRarity rarity;

  /// Optional icon asset path.
  final String? iconPath;

  /// Optional hint shown before the item is unlocked.
  final String? unlockHint;

  /// Optional custom metadata for game-specific usage.
  final Map<String, dynamic>? metadata;

  const CollectionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    this.iconPath,
    this.unlockHint,
    this.metadata,
  })  : assert(id != '', 'id must not be empty'),
        assert(name != '', 'name must not be empty'),
        assert(description != '', 'description must not be empty');

  /// Creates a [CollectionItem] from JSON data.
  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];

    return CollectionItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rarity: CollectionRarity.fromName(json['rarity'] as String?),
      iconPath: json['iconPath'] as String?,
      unlockHint: json['unlockHint'] as String?,
      metadata: rawMetadata is Map
          ? rawMetadata.cast<String, dynamic>()
          : null,
    );
  }

  /// Serializes this item to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.name,
      if (iconPath != null) 'iconPath': iconPath,
      if (unlockHint != null) 'unlockHint': unlockHint,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CollectionItem && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CollectionItem(id: $id, name: $name, rarity: ${rarity.name})';
  }
}

/// Reward given for completing a collection
class CollectionReward {
  /// Gold reward amount
  final int gold;

  /// Gems (premium currency) reward amount
  final int gems;

  /// Item rewards (item IDs)
  final List<String> items;

  /// Experience points reward
  final int experience;

  /// Custom rewards (key-value pairs for game-specific rewards)
  final Map<String, dynamic>? customRewards;

  const CollectionReward({
    this.gold = 0,
    this.gems = 0,
    this.items = const [],
    this.experience = 0,
    this.customRewards,
  });

  /// Check if reward is empty (no rewards)
  bool get isEmpty =>
      gold == 0 &&
      gems == 0 &&
      items.isEmpty &&
      experience == 0 &&
      (customRewards == null || customRewards!.isEmpty);

  /// Create from JSON
  factory CollectionReward.fromJson(Map<String, dynamic> json) {
    return CollectionReward(
      gold: json['gold'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      experience: json['experience'] as int? ?? 0,
      customRewards: json['customRewards'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gold': gold,
      'gems': gems,
      'items': items,
      'experience': experience,
      if (customRewards != null) 'customRewards': customRewards,
    };
  }

  /// Create a copy with updated values
  CollectionReward copyWith({
    int? gold,
    int? gems,
    List<String>? items,
    int? experience,
    Map<String, dynamic>? customRewards,
  }) {
    return CollectionReward(
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      items: items ?? this.items,
      experience: experience ?? this.experience,
      customRewards: customRewards ?? this.customRewards,
    );
  }

  @override
  String toString() {
    final parts = <String>[];
    if (gold > 0) parts.add('Gold: $gold');
    if (gems > 0) parts.add('Gems: $gems');
    if (items.isNotEmpty) parts.add('Items: ${items.length}');
    if (experience > 0) parts.add('XP: $experience');
    return 'CollectionReward(${parts.join(', ')})';
  }
}

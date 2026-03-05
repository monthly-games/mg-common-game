import 'package:mg_common_game/systems/collection/reward_type.dart';

/// Reward payload for collection milestone and completion rewards.
class CollectionReward {
  /// Reward category.
  final RewardType type;

  /// Reward amount.
  final int amount;

  /// Item identifier when [type] is [RewardType.item] or [RewardType.unlock].
  final String? itemId;

  const CollectionReward({
    required this.type,
    required this.amount,
    this.itemId,
  })  : assert(amount >= 0, 'amount must be non-negative'),
        assert(
          type != RewardType.item && type != RewardType.unlock ||
              (itemId != null && itemId != ''),
          'itemId is required for item and unlock rewards',
        );

  /// Human readable reward description.
  String get displayText {
    return switch (type) {
      RewardType.gold => '$amount Gold',
      RewardType.gems => '$amount Gems',
      RewardType.xp => '$amount XP',
      RewardType.item => '${itemId ?? 'Item'} x$amount',
      RewardType.currency => '$amount Currency',
      RewardType.unlock => 'Unlock ${itemId ?? 'content'}',
    };
  }

  /// Creates a [CollectionReward] from serialized data.
  factory CollectionReward.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];

    return CollectionReward(
      type: RewardType.fromName(json['type'] as String?),
      amount: rawAmount is num ? rawAmount.toInt() : 0,
      itemId: json['itemId'] as String?,
    );
  }

  /// Serializes this reward to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
      if (itemId != null) 'itemId': itemId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CollectionReward &&
        type == other.type &&
        amount == other.amount &&
        itemId == other.itemId;
  }

  @override
  int get hashCode => Object.hash(type, amount, itemId);

  @override
  String toString() {
    return 'CollectionReward(type: ${type.name}, amount: $amount, itemId: $itemId)';
  }
}

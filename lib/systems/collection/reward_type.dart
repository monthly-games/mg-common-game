import 'package:flutter/material.dart';

/// Reward type used by collection and battle pass rewards.
enum RewardType {
  gold,
  gems,
  xp,
  item,
  currency,
  unlock;

  /// Display label for UI and debug output.
  String get displayName {
    return switch (this) {
      RewardType.gold => 'Gold',
      RewardType.gems => 'Gems',
      RewardType.xp => 'XP',
      RewardType.item => 'Item',
      RewardType.currency => 'Currency',
      RewardType.unlock => 'Unlock',
    };
  }

  /// Material icon associated with this reward type.
  IconData get icon {
    return switch (this) {
      RewardType.gold => Icons.monetization_on_rounded,
      RewardType.gems => Icons.diamond_rounded,
      RewardType.xp => Icons.trending_up_rounded,
      RewardType.item => Icons.inventory_2_rounded,
      RewardType.currency => Icons.payments_rounded,
      RewardType.unlock => Icons.lock_open_rounded,
    };
  }

  /// Parses a reward type from serialized data.
  static RewardType fromName(String? value) {
    final normalized = value?.trim().toLowerCase();

    return switch (normalized) {
      'gold' || 'coin' || 'coins' => RewardType.gold,
      'gem' || 'gems' => RewardType.gems,
      'xp' || 'experience' => RewardType.xp,
      'item' || 'items' => RewardType.item,
      'unlock' || 'unlockable' => RewardType.unlock,
      'currency' => RewardType.currency,
      _ => RewardType.currency,
    };
  }
}

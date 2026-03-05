import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';

/// Rarity tier used by collection items.
enum CollectionRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// UI color associated with this rarity.
  Color get color {
    return switch (this) {
      CollectionRarity.common => MGColors.common,
      CollectionRarity.uncommon => MGColors.uncommon,
      CollectionRarity.rare => MGColors.rare,
      CollectionRarity.epic => MGColors.epic,
      CollectionRarity.legendary => MGColors.legendary,
    };
  }

  /// Human readable rarity label.
  String get displayName {
    return switch (this) {
      CollectionRarity.common => 'Common',
      CollectionRarity.uncommon => 'Uncommon',
      CollectionRarity.rare => 'Rare',
      CollectionRarity.epic => 'Epic',
      CollectionRarity.legendary => 'Legendary',
    };
  }

  /// Numeric tier level where higher means rarer.
  int get tierLevel {
    return switch (this) {
      CollectionRarity.common => 1,
      CollectionRarity.uncommon => 2,
      CollectionRarity.rare => 3,
      CollectionRarity.epic => 4,
      CollectionRarity.legendary => 5,
    };
  }

  /// Parses a rarity from serialized data.
  static CollectionRarity fromName(String? value) {
    final normalized = value?.trim().toLowerCase();

    return CollectionRarity.values.firstWhere(
      (rarity) => rarity.name == normalized,
      orElse: () => CollectionRarity.common,
    );
  }
}

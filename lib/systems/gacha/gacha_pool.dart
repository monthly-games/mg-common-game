/// 가챠 풀 정의 - MG Common Game
///
/// 뽑기 풀, 확률 테이블, 천장 시스템 정의
library;

// ignore_for_file: unused_import
import 'package:flutter/foundation.dart';

/// 아이템 등급
enum GachaRarity {
  normal,        // N - 일반
  rare,          // R - 레어
  superRare,     // SR - 슈퍼레어
  superSuperRare,// SSR - 울트라레어 (레거시 별칭, ultraRare와 동일)
  ultraRare,     // SSR - 울트라레어
  legendary,     // UR - 레전더리
}

/// 등급별 기본 확률 (%)
extension GachaRarityExtension on GachaRarity {
  double get baseRate {
    switch (this) {
      case GachaRarity.normal:
        return 50.0;
      case GachaRarity.rare:
        return 35.0;
      case GachaRarity.superRare:
        return 12.0;
      case GachaRarity.superSuperRare:
      case GachaRarity.ultraRare:
        return 2.7;
      case GachaRarity.legendary:
        return 0.3;
    }
  }

  String get nameKr {
    switch (this) {
      case GachaRarity.normal:
        return 'N';
      case GachaRarity.rare:
        return 'R';
      case GachaRarity.superRare:
        return 'SR';
      case GachaRarity.superSuperRare:
      case GachaRarity.ultraRare:
        return 'SSR';
      case GachaRarity.legendary:
        return 'UR';
    }
  }

  String get colorHex {
    switch (this) {
      case GachaRarity.normal:
        return '#808080';
      case GachaRarity.rare:
        return '#1EFF00';
      case GachaRarity.superRare:
        return '#0070DD';
      case GachaRarity.superSuperRare:
      case GachaRarity.ultraRare:
        return '#A335EE';
      case GachaRarity.legendary:
        return '#FF8000';
    }
  }
}

/// 가챠 아이템
class GachaItem {
  final String id;
  final String _name;
  final GachaRarity rarity;
  final String? imageAsset;
  final Map<String, dynamic> metadata;
  final bool isLimited;
  final bool isPickup;
  final double weight;

  String get name => _name;
  String get nameKr => _name;

  /// name 또는 nameKr 파라미터를 사용하여 생성
  GachaItem({
    required this.id,
    String? name,
    String? nameKr,
    required this.rarity,
    this.imageAsset,
    this.metadata = const {},
    this.isLimited = false,
    this.isPickup = false,
    this.weight = 1.0,
  }) : _name = name ?? nameKr ?? '';

  GachaItem copyWith({bool? isPickup}) => GachaItem(
    id: id,
    name: _name,
    rarity: rarity,
    imageAsset: imageAsset,
    metadata: metadata,
    isLimited: isLimited,
    isPickup: isPickup ?? this.isPickup,
    weight: weight,
  );
}

/// 가챠 풀 (배너)
class GachaPool {
  final String id;
  final String _name;
  final String? description;
  final List<GachaItem> items;
  final Map<GachaRarity, double> rateOverrides;
  final List<String> pickupItemIds;
  final double pickupRateBonus;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  String get name => _name;
  String get nameKr => _name;

  GachaPool({
    required this.id,
    String? name,
    String? nameKr,
    this.description,
    required this.items,
    this.rateOverrides = const {},
    this.pickupItemIds = const [],
    this.pickupRateBonus = 50.0,
    this.startDate,
    this.endDate,
    this.isActive = true,
  }) : _name = name ?? nameKr ?? '';

  double getRateForRarity(GachaRarity rarity) {
    return rateOverrides[rarity] ?? rarity.baseRate;
  }

  List<GachaItem> getItemsByRarity(GachaRarity rarity) {
    return items.where((item) => item.rarity == rarity).toList();
  }

  List<GachaItem> get pickupItems {
    return items.where((item) => pickupItemIds.contains(item.id)).toList();
  }

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  int? get remainingSeconds {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds;
  }
}

/// 천장 설정
class PityConfig {
  final int softPityStart;
  final int hardPity;
  final double softPityBonus;
  final bool resetOnHighRarity;
  final GachaRarity guaranteedRarity;

  const PityConfig({
    this.softPityStart = 70,
    this.hardPity = 80,
    this.softPityBonus = 6.0,
    this.resetOnHighRarity = true,
    this.guaranteedRarity = GachaRarity.ultraRare,
  });

  double calculateAdjustedRate(int currentPity, double baseRate) {
    if (currentPity >= hardPity) {
      return 100.0;
    }
    if (currentPity >= softPityStart) {
      final bonusMultiplier = currentPity - softPityStart + 1;
      return (baseRate + softPityBonus * bonusMultiplier).clamp(0, 100);
    }
    return baseRate;
  }
}

/// 10연차 보장 설정
class MultiPullGuarantee {
  final int pullCount;
  final GachaRarity minRarity;
  final int guaranteedCount;

  const MultiPullGuarantee({
    this.pullCount = 10,
    this.minRarity = GachaRarity.rare,
    this.guaranteedCount = 1,
  });
}

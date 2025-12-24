/// 가챠 풀 정의 - MG Common Game
///
/// 뽑기 풀, 확률 테이블, 천장 시스템 정의
library;

import 'package:flutter/foundation.dart';

/// 아이템 등급
enum GachaRarity {
  normal,   // N - 일반
  rare,     // R - 레어
  superRare,// SR - 슈퍼레어
  ultraRare,// SSR - 울트라레어
  legendary,// UR - 레전더리
}

/// 등급별 기본 확률 (%)
extension GachaRarityExtension on GachaRarity {
  /// 기본 확률
  double get baseRate {
    switch (this) {
      case GachaRarity.normal:
        return 50.0;
      case GachaRarity.rare:
        return 35.0;
      case GachaRarity.superRare:
        return 12.0;
      case GachaRarity.ultraRare:
        return 2.7;
      case GachaRarity.legendary:
        return 0.3;
    }
  }

  /// 한글명
  String get nameKr {
    switch (this) {
      case GachaRarity.normal:
        return 'N';
      case GachaRarity.rare:
        return 'R';
      case GachaRarity.superRare:
        return 'SR';
      case GachaRarity.ultraRare:
        return 'SSR';
      case GachaRarity.legendary:
        return 'UR';
    }
  }

  /// 색상 (Hex)
  String get colorHex {
    switch (this) {
      case GachaRarity.normal:
        return '#808080';
      case GachaRarity.rare:
        return '#1EFF00';
      case GachaRarity.superRare:
        return '#0070DD';
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
  final String nameKr;
  final GachaRarity rarity;
  final String? imageAsset;
  final Map<String, dynamic> metadata;
  final bool isLimited; // 한정 캐릭터
  final bool isPickup;  // 픽업 대상

  const GachaItem({
    required this.id,
    required this.nameKr,
    required this.rarity,
    this.imageAsset,
    this.metadata = const {},
    this.isLimited = false,
    this.isPickup = false,
  });

  GachaItem copyWith({bool? isPickup}) => GachaItem(
    id: id,
    nameKr: nameKr,
    rarity: rarity,
    imageAsset: imageAsset,
    metadata: metadata,
    isLimited: isLimited,
    isPickup: isPickup ?? this.isPickup,
  );
}

/// 가챠 풀 (배너)
class GachaPool {
  final String id;
  final String nameKr;
  final String? description;
  final List<GachaItem> items;
  final Map<GachaRarity, double> rateOverrides; // 확률 오버라이드
  final List<String> pickupItemIds; // 픽업 아이템 ID
  final double pickupRateBonus; // 픽업 확률 증가 (%, SSR 중에서)
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const GachaPool({
    required this.id,
    required this.nameKr,
    this.description,
    required this.items,
    this.rateOverrides = const {},
    this.pickupItemIds = const [],
    this.pickupRateBonus = 50.0, // 픽업 시 50% 확률로 픽업 캐릭터
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  /// 특정 등급의 확률
  double getRateForRarity(GachaRarity rarity) {
    return rateOverrides[rarity] ?? rarity.baseRate;
  }

  /// 특정 등급의 아이템 목록
  List<GachaItem> getItemsByRarity(GachaRarity rarity) {
    return items.where((item) => item.rarity == rarity).toList();
  }

  /// 픽업 아이템 목록
  List<GachaItem> get pickupItems {
    return items.where((item) => pickupItemIds.contains(item.id)).toList();
  }

  /// 현재 활성화 여부
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  /// 남은 시간 (초)
  int? get remainingSeconds {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds;
  }
}

/// 천장 설정
class PityConfig {
  final int softPityStart;  // 소프트 천장 시작 (확률 증가)
  final int hardPity;       // 하드 천장 (확정)
  final double softPityBonus; // 소프트 천장 후 확률 증가 (%)
  final bool resetOnHighRarity; // 고등급 획득 시 리셋
  final GachaRarity guaranteedRarity; // 보장 등급

  const PityConfig({
    this.softPityStart = 70,
    this.hardPity = 80,
    this.softPityBonus = 6.0,
    this.resetOnHighRarity = true,
    this.guaranteedRarity = GachaRarity.ultraRare,
  });

  /// 현재 확률 계산 (천장 보정 포함)
  double calculateAdjustedRate(int currentPity, double baseRate) {
    if (currentPity >= hardPity) {
      return 100.0; // 확정
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
  final int pullCount;         // 연차 수 (보통 10)
  final GachaRarity minRarity; // 최소 보장 등급
  final int guaranteedCount;   // 보장 수량

  const MultiPullGuarantee({
    this.pullCount = 10,
    this.minRarity = GachaRarity.rare,
    this.guaranteedCount = 1,
  });
}

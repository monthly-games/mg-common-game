/// 가챠 매니저 - MG Common Game
///
/// 뽑기 실행, 천장 관리, 히스토리 추적
library;

import 'dart:math';
import 'package:flutter/foundation.dart';

import 'gacha_pool.dart';

/// 뽑기 결과
class GachaResult {
  final GachaItem item;
  final bool isPityTriggered;
  final bool isPickupWon;
  final int pullNumber; // 몇 번째 뽑기

  const GachaResult({
    required this.item,
    this.isPityTriggered = false,
    this.isPickupWon = false,
    required this.pullNumber,
  });
}

/// 풀별 천장 상태
class PityState {
  final String poolId;
  int currentPity;
  int totalPulls;
  bool guaranteedPickup; // 50/50 실패 시 다음 확정

  PityState({
    required this.poolId,
    this.currentPity = 0,
    this.totalPulls = 0,
    this.guaranteedPickup = false,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'currentPity': currentPity,
    'totalPulls': totalPulls,
    'guaranteedPickup': guaranteedPickup,
  };

  factory PityState.fromJson(Map<String, dynamic> json) => PityState(
    poolId: json['poolId'] ?? '',
    currentPity: json['currentPity'] ?? 0,
    totalPulls: json['totalPulls'] ?? 0,
    guaranteedPickup: json['guaranteedPickup'] ?? false,
  );
}

/// 뽑기 히스토리 항목
class GachaHistoryEntry {
  final String poolId;
  final String itemId;
  final GachaRarity rarity;
  final DateTime timestamp;
  final int pullNumber;

  const GachaHistoryEntry({
    required this.poolId,
    required this.itemId,
    required this.rarity,
    required this.timestamp,
    required this.pullNumber,
  });

  Map<String, dynamic> toJson() => {
    'poolId': poolId,
    'itemId': itemId,
    'rarity': rarity.index,
    'timestamp': timestamp.toIso8601String(),
    'pullNumber': pullNumber,
  };

  factory GachaHistoryEntry.fromJson(Map<String, dynamic> json) =>
    GachaHistoryEntry(
      poolId: json['poolId'] ?? '',
      itemId: json['itemId'] ?? '',
      rarity: GachaRarity.values[json['rarity'] ?? 0],
      timestamp: DateTime.parse(json['timestamp']),
      pullNumber: json['pullNumber'] ?? 0,
    );
}

/// 가챠 매니저
class GachaManager extends ChangeNotifier {
  final Map<String, GachaPool> _pools = {};
  final Map<String, PityState> _pityStates = {};
  final List<GachaHistoryEntry> _history = [];
  final Random _random = Random();

  PityConfig pityConfig;
  MultiPullGuarantee multiPullGuarantee;

  /// 콜백
  void Function(GachaResult)? onPull;
  void Function(List<GachaResult>)? onMultiPull;

  GachaManager({
    this.pityConfig = const PityConfig(),
    this.multiPullGuarantee = const MultiPullGuarantee(),
  });

  /// 등록된 풀 목록
  List<GachaPool> get pools => _pools.values.toList();

  /// 활성화된 풀 목록
  List<GachaPool> get activePools =>
      _pools.values.where((p) => p.isCurrentlyActive).toList();

  /// 히스토리 (최근 100개)
  List<GachaHistoryEntry> get history =>
      _history.reversed.take(100).toList();

  /// 풀 등록
  void registerPool(GachaPool pool) {
    _pools[pool.id] = pool;
    if (!_pityStates.containsKey(pool.id)) {
      _pityStates[pool.id] = PityState(poolId: pool.id);
    }
  }

  /// 풀 제거
  void unregisterPool(String poolId) {
    _pools.remove(poolId);
  }

  /// 천장 상태 조회
  PityState? getPityState(String poolId) => _pityStates[poolId];

  /// 단일 뽑기
  GachaResult? pull(String poolId) {
    final pool = _pools[poolId];
    if (pool == null || !pool.isCurrentlyActive) return null;

    final pity = _pityStates.putIfAbsent(
      poolId,
      () => PityState(poolId: poolId),
    );

    final result = _executePull(pool, pity);

    // 히스토리 추가
    _history.add(GachaHistoryEntry(
      poolId: poolId,
      itemId: result.item.id,
      rarity: result.item.rarity,
      timestamp: DateTime.now(),
      pullNumber: pity.totalPulls,
    ));

    onPull?.call(result);
    notifyListeners();

    return result;
  }

  /// 10연차
  List<GachaResult> multiPull(String poolId, {int count = 10}) {
    final pool = _pools[poolId];
    if (pool == null || !pool.isCurrentlyActive) return [];

    final results = <GachaResult>[];
    bool hasGuaranteedRarity = false;

    for (int i = 0; i < count; i++) {
      final pity = _pityStates.putIfAbsent(
        poolId,
        () => PityState(poolId: poolId),
      );

      GachaResult result;

      // 마지막 뽑기에서 보장 등급 체크
      if (i == count - 1 && !hasGuaranteedRarity) {
        result = _executePullWithGuarantee(pool, pity);
      } else {
        result = _executePull(pool, pity);
      }

      if (result.item.rarity.index >= multiPullGuarantee.minRarity.index) {
        hasGuaranteedRarity = true;
      }

      results.add(result);

      // 히스토리
      _history.add(GachaHistoryEntry(
        poolId: poolId,
        itemId: result.item.id,
        rarity: result.item.rarity,
        timestamp: DateTime.now(),
        pullNumber: pity.totalPulls,
      ));
    }

    onMultiPull?.call(results);
    notifyListeners();

    return results;
  }

  /// 실제 뽑기 실행
  GachaResult _executePull(GachaPool pool, PityState pity) {
    pity.currentPity++;
    pity.totalPulls++;

    // 등급 결정
    final rarity = _rollRarity(pool, pity);

    // 천장 리셋 체크
    bool isPityTriggered = false;
    if (rarity.index >= pityConfig.guaranteedRarity.index) {
      isPityTriggered = pity.currentPity >= pityConfig.softPityStart;
      pity.currentPity = 0;
    }

    // 아이템 선택
    final item = _selectItem(pool, rarity, pity);

    return GachaResult(
      item: item,
      isPityTriggered: isPityTriggered,
      isPickupWon: pool.pickupItemIds.contains(item.id),
      pullNumber: pity.totalPulls,
    );
  }

  /// 보장 등급 포함 뽑기
  GachaResult _executePullWithGuarantee(GachaPool pool, PityState pity) {
    pity.currentPity++;
    pity.totalPulls++;

    // 최소 보장 등급
    var rarity = _rollRarity(pool, pity);
    if (rarity.index < multiPullGuarantee.minRarity.index) {
      rarity = multiPullGuarantee.minRarity;
    }

    // 천장 리셋 체크
    bool isPityTriggered = false;
    if (rarity.index >= pityConfig.guaranteedRarity.index) {
      isPityTriggered = pity.currentPity >= pityConfig.softPityStart;
      pity.currentPity = 0;
    }

    final item = _selectItem(pool, rarity, pity);

    return GachaResult(
      item: item,
      isPityTriggered: isPityTriggered,
      isPickupWon: pool.pickupItemIds.contains(item.id),
      pullNumber: pity.totalPulls,
    );
  }

  /// 등급 롤
  GachaRarity _rollRarity(GachaPool pool, PityState pity) {
    final roll = _random.nextDouble() * 100;
    double cumulative = 0;

    // 역순 (높은 등급부터)
    for (final rarity in GachaRarity.values.reversed) {
      var rate = pool.getRateForRarity(rarity);

      // 천장 보정 (SSR 이상)
      if (rarity == pityConfig.guaranteedRarity) {
        rate = pityConfig.calculateAdjustedRate(pity.currentPity, rate);
      }

      cumulative += rate;
      if (roll < cumulative) {
        return rarity;
      }
    }

    return GachaRarity.normal;
  }

  /// 아이템 선택
  GachaItem _selectItem(GachaPool pool, GachaRarity rarity, PityState pity) {
    final candidates = pool.getItemsByRarity(rarity);
    if (candidates.isEmpty) {
      // 해당 등급 없으면 한 단계 낮은 등급
      final lowerRarity = GachaRarity.values[max(0, rarity.index - 1)];
      return _selectItem(pool, lowerRarity, pity);
    }

    // 픽업 처리 (SSR 등급)
    if (rarity == GachaRarity.ultraRare && pool.pickupItemIds.isNotEmpty) {
      final pickupItems = pool.pickupItems.where((i) => i.rarity == rarity).toList();

      if (pickupItems.isNotEmpty) {
        // 50/50 또는 확정
        if (pity.guaranteedPickup) {
          pity.guaranteedPickup = false;
          return pickupItems[_random.nextInt(pickupItems.length)];
        }

        // 50/50 롤
        if (_random.nextDouble() * 100 < pool.pickupRateBonus) {
          return pickupItems[_random.nextInt(pickupItems.length)];
        } else {
          // 50/50 실패 - 다음 확정
          pity.guaranteedPickup = true;
        }
      }
    }

    // 일반 랜덤
    return candidates[_random.nextInt(candidates.length)];
  }

  /// 천장까지 남은 횟수
  int remainingPity(String poolId) {
    final pity = _pityStates[poolId];
    if (pity == null) return pityConfig.hardPity;
    return pityConfig.hardPity - pity.currentPity;
  }

  /// 특정 등급 통계
  GachaStats getStats(String poolId) {
    final poolHistory = _history.where((h) => h.poolId == poolId).toList();

    final counts = <GachaRarity, int>{};
    for (final entry in poolHistory) {
      counts[entry.rarity] = (counts[entry.rarity] ?? 0) + 1;
    }

    return GachaStats(
      totalPulls: poolHistory.length,
      countByRarity: counts,
    );
  }

  /// 저장
  Map<String, dynamic> toJson() => {
    'pityStates': _pityStates.map((k, v) => MapEntry(k, v.toJson())),
    'history': _history.map((h) => h.toJson()).toList(),
  };

  /// 불러오기
  void loadFromJson(Map<String, dynamic> json) {
    _pityStates.clear();
    final states = json['pityStates'] as Map<String, dynamic>? ?? {};
    for (final entry in states.entries) {
      _pityStates[entry.key] = PityState.fromJson(entry.value);
    }

    _history.clear();
    final historyData = json['history'] as List? ?? [];
    for (final data in historyData) {
      _history.add(GachaHistoryEntry.fromJson(data));
    }

    notifyListeners();
  }

  /// 히스토리 초기화 (디버그용)
  @visibleForTesting
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// 천장 초기화 (디버그용)
  @visibleForTesting
  void resetPity(String poolId) {
    _pityStates[poolId] = PityState(poolId: poolId);
    notifyListeners();
  }
}

/// 가챠 통계
class GachaStats {
  final int totalPulls;
  final Map<GachaRarity, int> countByRarity;

  const GachaStats({
    required this.totalPulls,
    required this.countByRarity,
  });

  /// 특정 등급 확률 (실제)
  double getRateForRarity(GachaRarity rarity) {
    if (totalPulls == 0) return 0;
    return ((countByRarity[rarity] ?? 0) / totalPulls) * 100;
  }
}

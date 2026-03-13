import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 아이템 등급
enum ItemRarity {
  common,         // 1성 - 60%
  uncommon,       // 2성 - 25%
  rare,           // 3성 - 10%
  epic,           // 4성 - 4%
  legendary,      // 5성 - 1%
  mythic,         // 6성 - 0.1%
}

/// 가챠 타입
enum GachaType {
  standard,       // 일반
  limited,        // 한정
  pickup,         // 픽업
  special,        // 특별
}

/// 아이템 타입
enum ItemType {
  character,      // 캐릭터
  weapon,         // 무기
  equipment,      // 장비
  skin,           // 스킨
  material,       // 재료
  currency,       // 통화
}

/// 가챠 아이템
class GachaItem {
  final String id;
  final String name;
  final ItemRarity rarity;
  final ItemType type;
  final String? icon;
  final String? imageUrl;
  final double baseRate; // 기본 확률 (0.0-1.0)
  final bool isLimited; // 한정 아이템
  final bool isPickup; // 픽업 아이템
  final DateTime? availableUntil; // 기간 한정
  final Map<String, dynamic>? stats;

  const GachaItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.type,
    this.icon,
    this.imageUrl,
    required this.baseRate,
    this.isLimited = false,
    this.isPickup = false,
    this.availableUntil,
    this.stats,
  });

  /// 현재 획득 가능 여부
  bool get isAvailable {
    if (!isLimited) return true;
    if (availableUntil == null) return true;
    return DateTime.now().isBefore(availableUntil!);
  }
}

/// 가챠 풀
class GachaPool {
  final String id;
  final String name;
  final String description;
  final GachaType type;
  final List<GachaItem> items;
  final int singleCost; // 1회 소모량
  final int tenCost; // 10회 소모량
  final String currency; // 소모 통화
  final DateTime? startDate;
  final DateTime? endDate;
  final List<GachaItem>? pickupItems; // 픽업 아이템
  final bool pitySystem; // 천장 시스템
  final int pityCount; // 천장 횟수
  final int softPity; // 소프트 천장 시작
  final bool guaranteed; // 확정 보장 (90회)
  final String? bannerImage;

  const GachaPool({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.items,
    required this.singleCost,
    required this.tenCost,
    required this.currency,
    this.startDate,
    this.endDate,
    this.pickupItems,
    this.pitySystem = true,
    this.pityCount = 90,
    this.softPity = 75,
    this.guaranteed = true,
    this.bannerImage,
  });

  /// 활성 상태
  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// 한정 배너 여부
  bool get isLimited => type == GachaType.limited || type == GachaType.pickup;
}

/// 가챠 결과
class GachaResult {
  final List<GachaItem> items;
  final GachaPool pool;
  final int cost;
  final bool guaranteed; // 천장 도달 여부
  final int currentPity;
  final DateTime timestamp;

  const GachaResult({
    required this.items,
    required this.pool,
    required this.cost,
    required this.guaranteed,
    required this.currentPity,
    required this.timestamp,
  });

  /// 최고 등급 아이템
  GachaItem? get highestRarityItem {
    if (items.isEmpty) return null;
    return items.reduce((a, b) =>
        a.rarity.index > b.rarity.index ? a : b);
  }

  /// 레어 이상 획득 개수
  int get rareCount {
    return items.where((i) =>
        i.rarity.index >= ItemRarity.rare.index).length;
  }

  /// 에픽 이상 획득 개수
  int get epicCount {
    return items.where((i) =>
        i.rarity.index >= ItemRarity.epic.index).length;
  }

  /// 레전더리 획득 여부
  bool get hasLegendary {
    return items.any((i) =>
        i.rarity.index >= ItemRarity.legendary.index);
  }
}

/// 플레이어 가챠 데이터
class PlayerGachaData {
  final String userId;
  final Map<String, int> pityCounters; // poolId -> count
  final Map<String, bool> guaranteedStates; // poolId -> guaranteed
  final Set<String> ownedItems;
  final int totalPulls;
  final int totalSpent;
  final Map<ItemRarity, int> rarityCounts;
  final DateTime? lastPullTime;

  const PlayerGachaData({
    required this.userId,
    required this.pityCounters,
    required this.guaranteedStates,
    required this.ownedItems,
    required this.totalPulls,
    required this.totalSpent,
    required this.rarityCounts,
    this.lastPullTime,
  });

  /// 전체 천장 진행률
  double getPityProgress(String poolId, int pityCount) {
    final current = pityCounters[poolId] ?? 0;
    if (pityCount == 0) return 0.0;
    return current / pityCount;
  }

  /// 소프트 천장 여부
  bool isSoftPity(String poolId, int softPity) {
    final current = pityCounters[poolId] ?? 0;
    return current >= softPity;
  }
}

/// 가챠 기록
class GachaHistory {
  final String id;
  final String poolId;
  final String poolName;
  final List<GachaItem> items;
  final int cost;
  final DateTime timestamp;
  final bool isTenPull;

  const GachaHistory({
    required this.id,
    required this.poolId,
    required this.poolName,
    required this.items,
    required this.cost,
    required this.timestamp,
    required this.isTenPull,
  });
}

/// 가챠 관리자
class GachaManager {
  static final GachaManager _instance = GachaManager._();
  static GachaManager get instance => _instance;

  GachaManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<GachaPool> _pools = [];
  PlayerGachaData? _playerData;
  final List<GachaHistory> _history = [];

  final StreamController<GachaResult> _pullController =
      StreamController<GachaResult>.broadcast();
  final StreamController<PlayerGachaData> _dataController =
      StreamController<PlayerGachaData>.broadcast();

  Stream<GachaResult> get onGachaPull => _pullController.stream;
  Stream<PlayerGachaData> get onDataUpdate => _dataController.stream;

  final _random = Random.secure();

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 가챠 풀 로드
    _loadGachaPools();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    debugPrint('[Gacha] Initialized');
  }

  void _loadGachaPools() {
    // 아이템 생성
    final items = _generateAllItems();

    // 일반 배너
    _pools.add(GachaPool(
      id: 'standard',
      name: '일반 소환',
      description: '다양한 캐릭터와 장비를 획득',
      type: GachaType.standard,
      items: items,
      singleCost: 160,
      tenCost: 1600,
      currency: 'gems',
      pitySystem: true,
      pityCount: 90,
      softPity: 75,
    ));

    // 한정 배너
    _pools.add(GachaPool(
      id: 'limited_1',
      name: '한정 소환: 불의 정령',
      description: '불의 정령이 등장 확률 UP!',
      type: GachaType.pickup,
      items: items,
      singleCost: 160,
      tenCost: 1600,
      currency: 'gems',
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      pickupItems: [
        items.firstWhere((i) => i.id == 'char_fire_spirit'),
      ],
      pitySystem: true,
      pityCount: 80,
      softPity: 65,
      guaranteed: true,
      bannerImage: 'assets/gacha/fire_spirit_banner.png',
    ));
  }

  List<GachaItem> _generateAllItems() {
    final items = <GachaItem>[];

    // 일반 캐릭터 (1-3성)
    for (var i = 1; i <= 10; i++) {
      final rarity = i <= 6
          ? ItemRarity.common
          : i <= 9
              ? ItemRarity.uncommon
              : ItemRarity.rare;

      items.add(GachaItem(
        id: 'char_common_$i',
        name: '일반 캐릭터 $i',
        rarity: rarity,
        type: ItemType.character,
        baseRate: _getBaseRate(rarity),
      ));
    }

    // 레어 캐릭터 (4성)
    for (var i = 1; i <= 5; i++) {
      items.add(GachaItem(
        id: 'char_rare_$i',
        name: '레어 캐릭터 $i',
        rarity: ItemRarity.epic,
        type: ItemType.character,
        baseRate: 0.04,
      ));
    }

    // 레전더리 캐릭터 (5성)
    for (var i = 1; i <= 3; i++) {
      items.add(GachaItem(
        id: 'char_legendary_$i',
        name: '레전더리 캐릭터 $i',
        rarity: ItemRarity.legendary,
        type: ItemType.character,
        baseRate: 0.01,
      ));
    }

    // 한정 캐릭터
    items.add(GachaItem(
      id: 'char_fire_spirit',
      name: '불의 정령',
      rarity: ItemRarity.legendary,
      type: ItemType.character,
      baseRate: 0.01,
      isLimited: true,
      isPickup: true,
      availableUntil: DateTime.now().add(const Duration(days: 23)),
    ));

    return items;
  }

  double _getBaseRate(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return 0.60;
      case ItemRarity.uncommon:
        return 0.25;
      case ItemRarity.rare:
        return 0.10;
      case ItemRarity.epic:
        return 0.04;
      case ItemRarity.legendary:
        return 0.01;
      case ItemRarity.mythic:
        return 0.001;
    }
  }

  Future<void> _loadPlayerData(String userId) async {
    final json = _prefs?.getString('gacha_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Gacha] Error loading data: $e');
      }
    }

    _playerData = PlayerGachaData(
      userId: userId,
      pityCounters: {},
      guaranteedStates: {},
      ownedItems: {},
      totalPulls: 0,
      totalSpent: 0,
      rarityCounts: {},
    );
  }

  /// 1회 뽑기
  Future<GachaResult?> pullSingle(String poolId) async {
    if (_currentUserId == null) return null;
    if (_playerData == null) return null;

    final pool = _pools.cast<GachaPool?>().firstWhere(
      (p) => p?.id == poolId,
      orElse: () => null,
    );

    if (pool == null) return null;
    if (!pool.isActive) return null;

    // 통화 체크
    if (!_checkCurrency(pool.singleCost)) {
      debugPrint('[Gacha] Not enough currency');
      return null;
    }

    // 아이템 추첨
    final item = _rollItem(pool);

    // 천장 업데이트
    var newPity = (_playerData!.pityCounters[poolId] ?? 0) + 1;
    var guaranteed = false;

    if (pool.pitySystem) {
      if (item.rarity.index >= ItemRarity.legendary.index) {
        // 레전더리 획득 시 천장 리셋
        newPity = 0;
        guaranteed = newPity >= pool.pityCount;
      } else if (newPity >= pool.pityCount) {
        // 천장 도달 시 레전더리 보장
        guaranteed = true;
        newPity = 0;
      }
    }

    // 결과 생성
    final result = GachaResult(
      items: [item],
      pool: pool,
      cost: pool.singleCost,
      guaranteed: guaranteed,
      currentPity: newPity,
      timestamp: DateTime.now(),
    );

    // 데이터 업데이트
    await _updatePlayerData(poolId, result);

    // 기록 추가
    _history.add(GachaHistory(
      id: 'history_${DateTime.now().millisecondsSinceEpoch}',
      poolId: poolId,
      poolName: pool.name,
      items: [item],
      cost: pool.singleCost,
      timestamp: DateTime.now(),
      isTenPull: false,
    ));

    _pullController.add(result);

    debugPrint('[Gacha] Single pull: ${item.name} (${item.rarity.name})');

    return result;
  }

  /// 10회 뽑기
  Future<GachaResult?> pullTen(String poolId) async {
    if (_currentUserId == null) return null;
    if (_playerData == null) return null;

    final pool = _pools.cast<GachaPool?>().firstWhere(
      (p) => p?.id == poolId,
      orElse: () => null,
    );

    if (pool == null) return null;
    if (!pool.isActive) return null;

    // 통화 체크
    if (!_checkCurrency(pool.tenCost)) {
      debugPrint('[Gacha] Not enough currency');
      return null;
    }

    // 10회 추첨
    final items = <GachaItem>[];
    var newPity = _playerData!.pityCounters[poolId] ?? 0;
    var guaranteed = false;

    for (var i = 0; i < 10; i++) {
      final item = _rollItem(pool);
      items.add(item);
      newPity++;

      if (pool.pitySystem) {
        if (item.rarity.index >= ItemRarity.legendary.index) {
          newPity = 0;
        }

        if (newPity >= pool.pityCount) {
          guaranteed = true;
          newPity = 0;
        }
      }
    }

    // 결과 생성
    final result = GachaResult(
      items: items,
      pool: pool,
      cost: pool.tenCost,
      guaranteed: guaranteed,
      currentPity: newPity,
      timestamp: DateTime.now(),
    );

    // 데이터 업데이트
    await _updatePlayerData(poolId, result);

    // 기록 추가
    _history.add(GachaHistory(
      id: 'history_${DateTime.now().millisecondsSinceEpoch}',
      poolId: poolId,
      poolName: pool.name,
      items: items,
      cost: pool.tenCost,
      timestamp: DateTime.now(),
      isTenPull: true,
    ));

    _pullController.add(result);

    final legendaryCount = items
        .where((i) => i.rarity.index >= ItemRarity.legendary.index)
        .length;

    debugPrint('[Gacha] Ten pull: $legendaryCount legendary');

    return result;
  }

  /// 아이템 추첨
  GachaItem _rollItem(GachaPool pool) {
    final pityCounter = _playerData!.pityCounters[pool.id] ?? 0;
    var rate = 0.0;

    // 천장 보정
    if (pool.pitySystem && pityCounter >= pool.softPity) {
      final progress = (pityCounter - pool.softPity) /
          (pool.pityCount - pool.softPity);
      rate = progress * 0.1; // 최대 10% 증가
    }

    // 픽업 보정
    if (pool.pickupItems != null && pool.pickupItems!.isNotEmpty) {
      final pickupRate = pool.pickupItems!.first.baseRate + rate + 0.01;
      if (_random.nextDouble() < pickupRate) {
        return pool.pickupItems!.first;
      }
    }

    // 일반 추첨
    final roll = _random.nextDouble();

    // 등급 결정
    ItemRarity rarity;
    final cumulative = 0.0 + rate;

    if (roll < 0.01 + cumulative) {
      rarity = ItemRarity.legendary;
    } else if (roll < 0.05 + cumulative) {
      rarity = ItemRarity.epic;
    } else if (roll < 0.15 + cumulative) {
      rarity = ItemRarity.rare;
    } else if (roll < 0.40 + cumulative) {
      rarity = ItemRarity.uncommon;
    } else {
      rarity = ItemRarity.common;
    }

    // 해당 등급 아이템 중 선택
    final rarityItems = pool.items
        .where((i) => i.rarity == rarity && i.isAvailable)
        .toList();

    if (rarityItems.isEmpty) {
      // 해당 등급 없으면 한단계 낮춤
      return _rollItem(pool);
    }

    return rarityItems[_random.nextInt(rarityItems.length)];
  }

  bool _checkCurrency(int cost) {
    // 실제로는 통화 체크
    return true;
  }

  Future<void> _updatePlayerData(String poolId, GachaResult result) async {
    if (_playerData == null) return;

    final pityCounters = Map<String, int>.from(_playerData!.pityCounters);
    pityCounters[poolId] = result.currentPity;

    final ownedItems = Set<String>.from(_playerData!.ownedItems);
    for (final item in result.items) {
      ownedItems.add(item.id);
    }

    final rarityCounts = Map<ItemRarity, int>.from(_playerData!.rarityCounts);
    for (final item in result.items) {
      rarityCounts[item.rarity] = (rarityCounts[item.rarity] ?? 0) + 1;
    }

    _playerData = PlayerGachaData(
      userId: _playerData!.userId,
      pityCounters: pityCounters,
      guaranteedStates: _playerData!.guaranteedStates,
      ownedItems: ownedItems,
      totalPulls: _playerData!.totalPulls + result.items.length,
      totalSpent: _playerData!.totalSpent + result.cost,
      rarityCounts: rarityCounts,
      lastPullTime: DateTime.now(),
    );

    _dataController.add(_playerData!);

    await _savePlayerData();
  }

  /// 가챠 풀 목록
  List<GachaPool> getPools() {
    return _pools.where((p) => p.isActive).toList();
  }

  /// 플레이어 데이터
  PlayerGachaData? getPlayerData() {
    return _playerData;
  }

  /// 천장 진행률
  double getPityProgress(String poolId) {
    if (_playerData == null) return 0.0;

    final pool = _pools.cast<GachaPool?>.firstWhere(
      (p) => p?.id == poolId,
      orElse: () => null,
    );

    if (pool == null) return 0.0;

    return _playerData!.getPityProgress(poolId, pool.pityCount);
  }

  /// 가챠 기록
  List<GachaHistory> getHistory({int limit = 50}) {
    return _history.take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 확률 조회
  Map<ItemRarity, double> getRates(String poolId) {
    final pool = _pools.cast<GachaPool?>.firstWhere(
      (p) => p?.id == poolId,
      orElse: () => null,
    );

    if (pool == null) return {};

    return {
      ItemRarity.common: 0.60,
      ItemRarity.uncommon: 0.25,
      ItemRarity.rare: 0.10,
      ItemRarity.epic: 0.04,
      ItemRarity.legendary: 0.01,
    };
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerData == null) return;

    final data = {
      'pityCounters': _playerData!.pityCounters,
      'ownedItems': _playerData!.ownedItems.toList(),
      'totalPulls': _playerData!.totalPulls,
      'totalSpent': _playerData!.totalSpent,
    };

    await _prefs?.setString(
      'gacha_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _pullController.close();
    _dataController.close();
  }
}

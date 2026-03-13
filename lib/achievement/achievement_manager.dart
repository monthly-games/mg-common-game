import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 업적 카테고리
enum AchievementCategory {
  combat,         // 전투
  exploration,    // 탐험
  social,         // 소셜
  collection,     // 컬렉션
  crafting,       // 제작
  trading,        // 거래
  leaderboard,    // 리더보드
  special,        // 특별
}

/// 업적 등급
enum AchievementTier {
  bronze,         // 브론즈
  silver,         // 실버
  gold,           // 골드
  platinum,       // 플래티넘
  diamond,        // 다이아몬드
  legendary,      // 레전더리
}

/// 업적 타입
enum AchievementType {
  count,          // 횟수 기반
  level,          // 레벨 기반
  collection,     // 컬렉션 기반
  time,           // 시간 기반
  streak,         // 스트릭 기반
  special,        // 특별 이벤트
}

/// 업적 진행 상태
enum AchievementStatus {
  locked,         // 잠김
  inProgress,     // 진행 중
  completed,      // 완료
  claimed,        // 보상 수령
}

/// 업적
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final List<AchievementReward> rewards;
  final String? prerequisiteId; // 선수 업적
  final bool isHidden; // 숨겨진 업적
  final DateTime? startDate;
  final DateTime? endDate;
  final int? maxProgress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.type,
    required this.criteria,
    required this.rewards,
    this.prerequisiteId,
    this.isHidden = false,
    this.startDate,
    this.endDate,
    this.maxProgress,
  });

  /// 활성 상태 확인
  bool get isActive {
    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    return true;
  }
}

/// 업적 보상
class AchievementReward {
  final RewardType type;
  final int amount;
  final String? itemId;
  final int? itemQuantity;

  const AchievementReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.itemQuantity,
  });
}

enum RewardType {
  gold,
  gems,
  experience,
  item,
  title,
  badge,
  currency,
}

/// 배지
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final DateTime? earnedAt;
  final int? displayOrder;
  final bool isShowcase; // 프로필 전시 가능 여부

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.earnedAt,
    this.displayOrder,
    this.isShowcase = false,
  });
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// 플레이어 업적 진행
class PlayerAchievement {
  final String achievementId;
  final AchievementStatus status;
  final int currentProgress;
  final int maxProgress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;
  final Map<String, dynamic> metadata;

  const PlayerAchievement({
    required this.achievementId,
    required this.status,
    required this.currentProgress,
    required this.maxProgress,
    this.startedAt,
    this.completedAt,
    this.claimedAt,
    this.metadata = const {},
  });

  /// 진행률
  double get progress {
    if (maxProgress == 0) return 0.0;
    return currentProgress / maxProgress;
  }

  /// 완료 가능
  bool get isCompleted => currentProgress >= maxProgress;

  /// 보상 수령 가능
  bool get canClaim => status == AchievementStatus.completed;
}

/// 업적 통계
class AchievementStatistics {
  final int totalAchievements;
  final int completedAchievements;
  final int claimedAchievements;
  final int inProgressAchievements;
  final int lockedAchievements;
  final Map<AchievementCategory, int> categoryProgress;
  final Map<AchievementTier, int> tierProgress;
  final int totalPoints;
  final int globalRank;

  const AchievementStatistics({
    required this.totalAchievements,
    required this.completedAchievements,
    required this.claimedAchievements,
    required this.inProgressAchievements,
    required this.lockedAchievements,
    required this.categoryProgress,
    required this.tierProgress,
    required this.totalPoints,
    required this.globalRank,
  });

  /// 완료율
  double get completionRate {
    if (totalAchievements == 0) return 0.0;
    return completedAchievements / totalAchievements;
  }
}

/// 업적 관리자
class AchievementManager {
  static final AchievementManager _instance = AchievementManager._();
  static AchievementManager get instance => _instance;

  AchievementManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Achievement> _achievements = {};
  final Map<String, PlayerAchievement> _playerAchievements = {};
  final Map<String, List<Badge>> _playerBadges = {};

  final StreamController<PlayerAchievement> _progressController =
      StreamController<PlayerAchievement>.broadcast();
  final StreamController<Achievement> _unlockController =
      StreamController<Achievement>.broadcast();
  final StreamController<Badge> _badgeController =
      StreamController<Badge>.broadcast();

  Stream<PlayerAchievement> get onProgressUpdate => _progressController.stream;
  Stream<Achievement> get onAchievementUnlock => _unlockController.stream;
  Stream<Badge> get onBadgeEarn => _badgeController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 업적 로드
    await _loadAchievements();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    debugPrint('[Achievement] Initialized');
  }

  Future<void> _loadAchievements() async {
    // 전투 업적
    _achievements['combat_100_kills'] = Achievement(
      id: 'combat_100_kills',
      name: '처치의 달인',
      description: '적 100마리 처치',
      category: AchievementCategory.combat,
      tier: AchievementTier.bronze,
      type: AchievementType.count,
      criteria: {'target': 100, 'type': 'kills'},
      rewards: const [
        AchievementReward(type: RewardType.gold, amount: 1000),
        AchievementReward(type: RewardType.experience, amount: 500),
      ],
      maxProgress: 100,
    );

    _achievements['combat_1000_kills'] = Achievement(
      id: 'combat_1000_kills',
      name: '전쟁 영웅',
      description: '적 1,000마리 처치',
      category: AchievementCategory.combat,
      tier: AchievementTier.gold,
      type: AchievementType.count,
      criteria: {'target': 1000, 'type': 'kills'},
      rewards: const [
        AchievementReward(type: RewardType.gold, amount: 10000),
        AchievementReward(type: RewardType.badge, amount: 1),
      ],
       prerequisiteId: 'combat_100_kills',
      maxProgress: 1000,
    );

    // 탐험 업적
    _achievements['explore_10_areas'] = Achievement(
      id: 'explore_10_areas',
      name: '세계의 발견',
      description: '10개 지역 탐험',
      category: AchievementCategory.exploration,
      tier: AchievementTier.silver,
      type: AchievementType.collection,
      criteria: {'target': 10, 'type': 'areas'},
      rewards: const [
        AchievementReward(type: RewardType.experience, amount: 2000),
      ],
      maxProgress: 10,
    );

    // 소셜 업적
    _achievements['social_10_friends'] = Achievement(
      id: 'social_10_friends',
      name: '인기 스타',
      description: '친구 10명 추가',
      category: AchievementCategory.social,
      tier: AchievementTier.bronze,
      type: AchievementType.count,
      criteria: {'target': 10, 'type': 'friends'},
      rewards: const [
        AchievementReward(type: RewardType.gems, amount: 50),
      ],
      maxProgress: 10,
    );

    // 컬렉션 업적
    _achievements['collection_100_items'] = Achievement(
      id: 'collection_100_items',
      name: '수집가',
      description: '아이템 100개 수집',
      category: AchievementCategory.collection,
      tier: AchievementTier.silver,
      type: AchievementType.collection,
      criteria: {'target': 100, 'type': 'items'},
      rewards: const [
        AchievementReward(type: RewardType.gold, amount: 5000),
        AchievementReward(type: RewardType.title, amount: 1),
      ],
      maxProgress: 100,
    );

    // 시간 기반 업적
    _achievements['play_7_days'] = Achievement(
      id: 'play_7_days',
      name: '충성스러운 플레이어',
      description: '7일 연속 게임 접속',
      category: AchievementCategory.special,
      tier: AchievementTier.silver,
      type: AchievementType.streak,
      criteria: {'target': 7, 'type': 'daily_login'},
      rewards: const [
        AchievementReward(type: RewardType.gems, amount: 100),
        AchievementReward(type: RewardType.badge, amount: 1),
      ],
      maxProgress: 7,
    );

    // 특별 업적
    _achievements['special_first_kill'] = Achievement(
      id: 'special_first_kill',
      name: '첫 번째 처치',
      description: '첫 번째 적 처치',
      category: AchievementCategory.combat,
      tier: AchievementTier.bronze,
      type: AchievementType.special,
      criteria: {'type': 'first_kill'},
      rewards: const [
        AchievementReward(type: RewardType.experience, amount: 100),
      ],
      maxProgress: 1,
      isHidden: false,
    );

    // 레전더리 업적
    _achievements['legendary_perfect'] = Achievement(
      id: 'legendary_perfect',
      name: '완벽한 승리',
      description: '피해 없이 던전 클리어',
      category: AchievementCategory.special,
      tier: AchievementTier.legendary,
      type: AchievementType.special,
      criteria: {'type': 'perfect_dungeon'},
      rewards: const [
        AchievementReward(type: RewardType.gems, amount: 1000),
        AchievementReward(type: RewardType.badge, amount: 1),
        AchievementReward(type: RewardType.title, amount: 1),
      ],
      maxProgress: 1,
      isHidden: true,
    );
  }

  Future<void> _loadPlayerData(String userId) async {
    final playerJson = _prefs?.getString('achievements_$userId');
    if (playerJson != null) {
      // 파싱
    }

    // 기본 업적 진행 생성
    for (final achievement in _achievements.values) {
      if (!_playerAchievements.containsKey(achievement.id)) {
        _playerAchievements[achievement.id] = PlayerAchievement(
          achievementId: achievement.id,
          status: AchievementStatus.locked,
          currentProgress: 0,
          maxProgress: achievement.maxProgress ?? 1,
          startedAt: null,
          completedAt: null,
          claimedAt: null,
        );
      }
    }
  }

  /// 업적 진행 업데이트
  Future<PlayerAchievement?> updateProgress({
    required String achievementId,
    required int progress,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null) return null;

    final achievement = _achievements[achievementId];
    if (achievement == null) return null;

    var playerAchievement = _playerAchievements[achievementId];
    if (playerAchievement == null) {
      playerAchievement = PlayerAchievement(
        achievementId: achievementId,
        status: AchievementStatus.inProgress,
        currentProgress: progress,
        maxProgress: achievement.maxProgress ?? 1,
        startedAt: DateTime.now(),
        metadata: metadata ?? {},
      );
    } else {
      // 진행 업데이트
      playerAchievement = PlayerAchievement(
        achievementId: achievementId,
        status: playerAchievement.status,
        currentProgress: progress,
        maxProgress: playerAchievement.maxProgress,
        startedAt: playerAchievement.startedAt,
        completedAt: playerAchievement.completedAt,
        claimedAt: playerAchievement.claimedAt,
        metadata: metadata ?? playerAchievement.metadata,
      );
    }

    // 완료 체크
    if (playerAchievement.isCompleted &&
        playerAchievement.status != AchievementStatus.completed) {
      playerAchievement = PlayerAchievement(
        achievementId: achievementId,
        status: AchievementStatus.completed,
        currentProgress: playerAchievement.currentProgress,
        maxProgress: playerAchievement.maxProgress,
        startedAt: playerAchievement.startedAt,
        completedAt: DateTime.now(),
        claimedAt: playerAchievement.claimedAt,
        metadata: playerAchievement.metadata,
      );

      _unlockController.add(achievement);

      debugPrint('[Achievement] Unlocked: ${achievement.name}');
    }

    _playerAchievements[achievementId] = playerAchievement;
    _progressController.add(playerAchievement);

    await _savePlayerData();

    return playerAchievement;
  }

  /// 이벤트 기반 업적 진행
  Future<void> trackEvent({
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    // 관련 업적 찾기
    final relevantAchievements = _achievements.values.where((a) =>
        a.criteria['type']?.toString() == eventType &&
        a.isActive
    ).toList();

    for (final achievement in relevantAchievements) {
      var current = _playerAchievements[achievement.id]?.currentProgress ?? 0;

       // 진행 계산
       switch (achievement.type) {
         case AchievementType.count:
           current += (data?['count'] as int?) ?? 1;
           break;
         case AchievementType.collection:
           current += (data?['collected'] as int?) ?? 0;
           break;
         case AchievementType.streak:
           current = (data?['streak'] as int?) ?? current;
           break;
         default:
           break;
       }

      await updateProgress(
        achievementId: achievement.id,
        progress: current,
        metadata: data,
      );
    }
  }

  /// 업적 보상 수령
  Future<bool> claimReward(String achievementId) async {
    if (_currentUserId == null) return false;

    final playerAchievement = _playerAchievements[achievementId];
    if (playerAchievement == null) return false;
    if (!playerAchievement.canClaim) return false;

     // 보상 지급 (실제로는 인벤토리 등에 추가)
     final achievement = _achievements[achievementId];
     if (achievement != null) {
       for (final reward in achievement.rewards) {
         await _grantReward(reward);
       }

       // 배지 지급
       if (achievement.rewards.any((r) => r.type == RewardType.badge)) {
         await _grantBadge(achievement);
       }
     }

    final updated = PlayerAchievement(
      achievementId: achievementId,
      status: AchievementStatus.claimed,
      currentProgress: playerAchievement.currentProgress,
      maxProgress: playerAchievement.maxProgress,
      startedAt: playerAchievement.startedAt,
      completedAt: playerAchievement.completedAt,
      claimedAt: DateTime.now(),
      metadata: playerAchievement.metadata,
    );

    _playerAchievements[achievementId] = updated;

    await _savePlayerData();

    debugPrint('[Achievement] Reward claimed: $achievementId');

    return true;
  }

  Future<void> _grantReward(AchievementReward reward) async {
    // 실제 보상 지급 로직
    debugPrint('[Achievement] Granting reward: ${reward.type} x${reward.amount}');
  }

  Future<void> _grantBadge(Achievement achievement) async {
    final badge = Badge(
      id: 'badge_${achievement.id}',
      name: achievement.name,
      description: achievement.description,
      icon: 'assets/badges/${achievement.id}.png',
      rarity: _tierToRarity(achievement.tier),
      earnedAt: DateTime.now(),
      isShowcase: achievement.tier.index >= AchievementTier.gold.index,
    );

    _playerBadges.putIfAbsent(_currentUserId!, () => []).add(badge);
    _badgeController.add(badge);

    debugPrint('[Achievement] Badge earned: ${badge.name}');
  }

  BadgeRarity _tierToRarity(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return BadgeRarity.common;
      case AchievementTier.silver:
        return BadgeRarity.uncommon;
      case AchievementTier.gold:
        return BadgeRarity.rare;
      case AchievementTier.platinum:
        return BadgeRarity.epic;
      case AchievementTier.diamond:
        return BadgeRarity.legendary;
      case AchievementTier.legendary:
        return BadgeRarity.mythic;
    }
  }

  /// 업적 조회
  Achievement? getAchievement(String id) {
    return _achievements[id];
  }

  /// 카테고리별 업적
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values
        .where((a) => a.category == category)
        .toList()
      ..sort((a, b) => a.tier.index.compareTo(b.tier.index));
  }

  /// 플레이어 업적 진행
  PlayerAchievement? getPlayerAchievement(String achievementId) {
    return _playerAchievements[achievementId];
  }

  /// 완료된 업적
  List<Achievement> getCompletedAchievements() {
    return _playerAchievements.entries
        .where((e) => e.value.status == AchievementStatus.claimed)
        .map((e) => _achievements[e.key])
        .whereType<Achievement>()
        .toList();
  }

  /// 진행 중인 업적
  List<Achievement> getInProgressAchievements() {
    return _playerAchievements.entries
        .where((e) => e.value.status == AchievementStatus.inProgress ||
                     e.value.status == AchievementStatus.completed)
        .map((e) => _achievements[e.key])
        .whereType<Achievement>()
        .toList()
      ..sort((a, b) {
        final progressA = _playerAchievements[a.id]?.progress ?? 0;
        final progressB = _playerAchievements[b.id]?.progress ?? 0;
        return progressB.compareTo(progressA);
      });
  }

  /// 보상 수령 가능 업적
  List<Achievement> getClaimableAchievements() {
    return _playerAchievements.entries
        .where((e) => e.value.canClaim)
        .map((e) => _achievements[e.key])
        .whereType<Achievement>()
        .toList();
  }

  /// 플레이어 배지
  List<Badge> getPlayerBadges() {
    return _playerBadges[_currentUserId] ?? [];
  }

  /// 전시 가능 배지
  List<Badge> getShowcaseBadges() {
    return getPlayerBadges().where((b) => b.isShowcase).toList()
      ..sort((a, b) {
        if (a.earnedAt == null || b.earnedAt == null) return 0;
        return b.earnedAt!.compareTo(a.earnedAt!);
      });
  }

  /// 업적 통계
  AchievementStatistics getStatistics() {
    final total = _achievements.length;
    final completed = _playerAchievements.values
        .where((p) => p.status == AchievementStatus.claimed)
        .length;
    final claimed = completed;
    final inProgress = _playerAchievements.values
        .where((p) => p.status == AchievementStatus.inProgress ||
                     p.status == AchievementStatus.completed)
        .length;
    final locked = _playerAchievements.values
        .where((p) => p.status == AchievementStatus.locked)
        .length;

    // 카테고리별 진행
    final categoryProgress = <AchievementCategory, int>{};
    for (final category in AchievementCategory.values) {
      final categoryAchievements = _achievements.values
          .where((a) => a.category == category)
          .length;
      final categoryCompleted = _playerAchievements.entries
          .where((e) =>
              _achievements[e.key]?.category == category &&
              e.value.status == AchievementStatus.claimed)
          .length;
      categoryProgress[category] = categoryCompleted;
    }

    // 등급별 진행
    final tierProgress = <AchievementTier, int>{};
    for (final tier in AchievementTier.values) {
      tierProgress[tier] = _playerAchievements.entries
          .where((e) =>
              _achievements[e.key]?.tier == tier &&
              e.value.status == AchievementStatus.claimed)
          .length;
    }

    // 포인트 계산
    var points = 0;
    for (final entry in _playerAchievements.entries) {
      if (entry.value.status == AchievementStatus.claimed) {
        final achievement = _achievements[entry.key];
        if (achievement != null) {
          points += _getTierPoints(achievement.tier);
        }
      }
    }

    return AchievementStatistics(
      totalAchievements: total,
      completedAchievements: completed,
      claimedAchievements: claimed,
      inProgressAchievements: inProgress,
      lockedAchievements: locked,
      categoryProgress: categoryProgress,
      tierProgress: tierProgress,
      totalPoints: points,
      globalRank: 0, // 실제로는 서버에서 가져옴
    );
  }

  int _getTierPoints(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 10;
      case AchievementTier.silver:
        return 25;
      case AchievementTier.gold:
        return 50;
      case AchievementTier.platinum:
        return 100;
      case AchievementTier.diamond:
        return 200;
      case AchievementTier.legendary:
        return 500;
    }
  }

  /// 업적 검색
  List<Achievement> searchAchievements(String query) {
    final lowerQuery = query.toLowerCase();
    return _achievements.values
        .where((a) =>
            a.name.toLowerCase().contains(lowerQuery) ||
            a.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null) return;

    final data = {
      'achievements': _playerAchievements.map((k, v) =>
          MapEntry(k, {
            'status': v.status.name,
            'currentProgress': v.currentProgress,
            'maxProgress': v.maxProgress,
          })),
    };

    await _prefs?.setString(
      'achievements_${_currentUserId!}',
      jsonEncode(data),
    );
  }

  void dispose() {
    _progressController.close();
    _unlockController.close();
    _badgeController.close();
  }
}

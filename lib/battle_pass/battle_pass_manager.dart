import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 배틀패스 트랙
enum BattlePassTrack {
  free,           // 무료 트랙
  premium,        // 프리미엄 트랙
}

/// 배틀패스 상태
enum BattlePassStatus {
  notPurchased,   // 미구매
  active,         // 활성
  expired,        // 만료
  completed,      // 완료
}

/// 시즌 상태
enum SeasonStatus {
  upcoming,       // 예정
  active,         // 활성
  ended,          // 종료
}

/// 보상 타입
enum RewardType {
  item,           // 아이템
  currency,       // 통화
  experience,     // 경험치
  title,          // 칭호
  badge,          // 배지
  skin,           // 스킨
  emote,          // 이모티콘
  booster,        // 부스터
}

/// 배틀패스 보상
class BattlePassReward {
  final RewardType type;
  final String id;
  final String name;
  final int? quantity;
  final String? icon;
  final int? rarity; // 1-5
  final Map<String, dynamic>? metadata;

  const BattlePassReward({
    required this.type,
    required this.id,
    required this.name,
    this.quantity,
    this.icon,
    this.rarity,
    this.metadata,
  });
}

/// 배틀패스 레벨
class BattlePassLevel {
  final int level;
  final int requiredXP;
  final BattlePassReward? freeReward;
  final BattlePassReward? premiumReward;
  final bool isBonusLevel; // 보너스 레벨 (프리미엄만)

  const BattlePassLevel({
    required this.level,
    required this.requiredXP,
    this.freeReward,
    this.premiumReward,
    this.isBonusLevel = false,
  });

  /// 보상 수령 가능 여부
  bool hasReward(BattlePassTrack track) {
    if (isBonusLevel) {
      return track == BattlePassTrack.premium && premiumReward != null;
    }
    return track == BattlePassTrack.free
        ? freeReward != null
        : premiumReward != null;
  }
}

/// 배틀패스 시즌
class BattlePassSeason {
  final String id;
  final String name;
  final String description;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final int maxLevel;
  final int totalXP;
  final List<BattlePassLevel> levels;
  final BattlePassReward? seasonEndReward;
  final String? backgroundImage;
  final String? premiumPrice;

  const BattlePassSeason({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.maxLevel,
    required this.totalXP,
    required this.levels,
    this.seasonEndReward,
    this.backgroundImage,
    this.premiumPrice,
  });

  /// 활성 상태
  SeasonStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return SeasonStatus.upcoming;
    if (now.isAfter(endDate)) return SeasonStatus.ended;
    return SeasonStatus.active;
  }

  /// 남은 일수
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }
}

/// 플레이어 배틀패스 데이터
class PlayerBattlePass {
  final String seasonId;
  final BattlePassStatus status;
  final int currentLevel;
  final int currentXP;
  final bool isPremiumPurchased;
  final Set<int> claimedFreeLevels;
  final Set<int> claimedPremiumLevels;
  final DateTime? purchasedAt;
  final DateTime? completedAt;

  const PlayerBattlePass({
    required this.seasonId,
    required this.status,
    required this.currentLevel,
    required this.currentXP,
    required this.isPremiumPurchased,
    required this.claimedFreeLevels,
    required this.claimedPremiumLevels,
    this.purchasedAt,
    this.completedAt,
  });

  /// 현재 레벨 진행률
  double get levelProgress {
    if (currentLevel >= 100) return 1.0;
    // 다음 레벨 필요 경험치 (레벨당 1000xp라고 가정)
    final requiredXP = 1000;
    return currentXP / requiredXP;
  }

  /// 전체 진행률
  double get totalProgress {
    if (currentLevel >= 100) return 1.0;
    return currentLevel / 100;
  }

  /// 무료 보상 수령 가능
  List<int> get claimableFreeLevels {
    final claimable = <int>[];
    for (var i = 1; i <= currentLevel; i++) {
      if (!claimedFreeLevels.contains(i)) {
        claimable.add(i);
      }
    }
    return claimable;
  }

  /// 프리미엄 보상 수령 가능
  List<int> get claimablePremiumLevels {
    if (!isPremiumPurchased) return [];
    final claimable = <int>[];
    for (var i = 1; i <= currentLevel; i++) {
      if (!claimedPremiumLevels.contains(i)) {
        claimable.add(i);
      }
    }
    return claimable;
  }

  /// 수령 가능한 보상 총개수
  int get totalClaimable {
    return claimableFreeLevels.length + claimablePremiumLevels.length;
  }
}

/// 일일/주간 퀘스트
class Quest {
  final String id;
  final String name;
  final String description;
  final QuestType type;
  final int xpReward;
  final Map<String, dynamic> criteria;
  final int currentProgress;
  final int maxProgress;
  final bool isCompleted;
  final bool isClaimed;
  final DateTime? expiresAt;

  const Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.xpReward,
    required this.criteria,
    required this.currentProgress,
    required this.maxProgress,
    required this.isCompleted,
    required this.isClaimed,
    this.expiresAt,
  });

  /// 진행률
  double get progress {
    if (maxProgress == 0) return 0.0;
    return currentProgress / maxProgress;
  }

  /// 완료 가능
  bool get canClaim => isCompleted && !isClaimed;

  /// 만료 여부
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

enum QuestType {
  daily,          // 일일
  weekly,         // 주간
  premium,        // 프리미엄 전용
}

/// 배틀패스 관리자
class BattlePassManager {
  static final BattlePassManager _instance = BattlePassManager._();
  static BattlePassManager get instance => _instance;

  BattlePassManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  BattlePassSeason? _currentSeason;
  PlayerBattlePass? _playerBattlePass;

  final List<Quest> _dailyQuests = [];
  final List<Quest> _weeklyQuests = [];
  final List<Quest> _premiumQuests = [];

  final StreamController<PlayerBattlePass> _progressController =
      StreamController<PlayerBattlePass>.broadcast();
  final StreamController<BattlePassReward> _rewardController =
      StreamController<BattlePassReward>.broadcast();
  final StreamController<Quest> _questController =
      StreamController<Quest>.broadcast();

  Stream<PlayerBattlePass> get onProgressUpdate => _progressController.stream;
  Stream<BattlePassReward> get onRewardClaim => _rewardController.stream;
  Stream<Quest> get onQuestUpdate => _questController.stream;

  Timer? _questResetTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 시즌 로드
    await _loadSeason();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    // 퀘스트 로드 및 초기화
    await _initializeQuests();

    // 리셋 타이머 시작
    _startQuestResetTimer();

    debugPrint('[BattlePass] Initialized');
  }

  Future<void> _loadSeason() async {
    _currentSeason = BattlePassSeason(
      id: 'season_1',
      name: '시즌 1: 새로운 시작',
      description: '첫 번째 배틀패스 시즌',
      theme: 'fantasy',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      maxLevel: 100,
      totalXP: 100000,
      levels: _generateSeasonLevels(),
      seasonEndReward: const BattlePassReward(
        type: RewardType.title,
        id: 'title_season1',
        name: '시즌 1 베테랑',
        rarity: 5,
      ),
      backgroundImage: 'assets/battle_pass/season1_bg.png',
      premiumPrice: '\$9.99',
    );
  }

  List<BattlePassLevel> _generateSeasonLevels() {
    final levels = <BattlePassLevel>[];

    for (var i = 1; i <= 100; i++) {
      final xp = i * 1000;
      final level = BattlePassLevel(
        level: i,
        requiredXP: xp,
        freeReward: i % 5 == 0 ? _generateFreeReward(i) : null,
        premiumReward: _generatePremiumReward(i),
        isBonusLevel: i % 10 == 0,
      );
      levels.add(level);
    }

    return levels;
  }

  BattlePassReward _generateFreeReward(int level) {
    if (level % 20 == 0) {
      return const BattlePassReward(
        type: RewardType.item,
        id: 'item_rare_$level',
        name: '희귀 아이템 상자',
        rarity: 3,
        quantity: 1,
      );
    }

    return BattlePassReward(
      type: RewardType.currency,
      id: 'gold_$level',
      name: '골드',
      quantity: 100 * level,
    );
  }

  BattlePassReward _generatePremiumReward(int level) {
    if (level % 10 == 0) {
      return const BattlePassReward(
        type: RewardType.skin,
        id: 'skin_epic_$level',
        name: '에픽 스킨',
        rarity: 4,
      );
    }

    if (level % 5 == 0) {
      return const BattlePassReward(
        type: RewardType.emote,
        id: 'emote_$level',
        name: '특별 이모티콘',
      );
    }

    return BattlePassReward(
      type: RewardType.currency,
      id: 'gems_$level',
      name: '젬',
      quantity: 10 + level,
    );
  }

  Future<void> _loadPlayerData(String userId) async {
    final playerJson = _prefs?.getString('battle_pass_$userId');
    if (playerJson != null) {
      // 파싱
    }

    // 기본 데이터 생성
    if (_playerBattlePass == null && _currentSeason != null) {
      _playerBattlePass = PlayerBattlePass(
        seasonId: _currentSeason!.id,
        status: BattlePassStatus.notPurchased,
        currentLevel: 1,
        currentXP: 0,
        isPremiumPurchased: false,
        claimedFreeLevels: {},
        claimedPremiumLevels: {},
      );
    }
  }

  Future<void> _initializeQuests() async {
    // 일일 퀘스트
    _dailyQuests.clear();
    _dailyQuests.addAll([
      Quest(
        id: 'daily_login',
        name: '로그인',
        description: '게임에 접속',
        type: QuestType.daily,
        xpReward: 500,
        criteria: {'type': 'login'},
        currentProgress: 1,
        maxProgress: 1,
        isCompleted: true,
        isClaimed: false,
      ),
      Quest(
        id: 'daily_play_3_games',
        name: '3게임 플레이',
        description: '3게임 완료',
        type: QuestType.daily,
        xpReward: 1000,
        criteria: {'type': 'complete_games', 'count': 3},
        currentProgress: 0,
        maxProgress: 3,
        isCompleted: false,
        isClaimed: false,
        expiresAt: _getEndOfDay(),
      ),
      Quest(
        id: 'daily_kill_50',
        name: '50처치',
        description: '적 50마리 처치',
        type: QuestType.daily,
        xpReward: 1500,
        criteria: {'type': 'kills', 'count': 50},
        currentProgress: 0,
        maxProgress: 50,
        isCompleted: false,
        isClaimed: false,
        expiresAt: _getEndOfDay(),
      ),
    ]);

    // 주간 퀘스트
    _weeklyQuests.clear();
    _weeklyQuests.addAll([
      Quest(
        id: 'weekly_play_20_games',
        name: '20게임 플레이',
        description: '주간 20게임 완료',
        type: QuestType.weekly,
        xpReward: 5000,
        criteria: {'type': 'complete_games', 'count': 20},
        currentProgress: 0,
        maxProgress: 20,
        isCompleted: false,
        isClaimed: false,
        expiresAt: _getEndOfWeek(),
      ),
      Quest(
        id: 'weekly_earn_10000_gold',
        name: '10,000골드 획득',
        description: '주간 10,000골드 획득',
        type: QuestType.weekly,
        xpReward: 3000,
        criteria: {'type': 'earn_gold', 'count': 10000},
        currentProgress: 0,
        maxProgress: 10000,
        isCompleted: false,
        isClaimed: false,
        expiresAt: _getEndOfWeek(),
      ),
    ]);

    // 프리미엄 퀘스트
    _premiumQuests.clear();
    _premiumQuests.addAll([
      Quest(
        id: 'premium_play_5_games',
        name: '5게임 플레이 (프리미엄)',
        description: '프리미엄 플레이어 5게임',
        type: QuestType.premium,
        xpReward: 2000,
        criteria: {'type': 'complete_games', 'count': 5},
        currentProgress: 0,
        maxProgress: 5,
        isCompleted: false,
        isClaimed: false,
        expiresAt: _getEndOfDay(),
      ),
    ]);
  }

  DateTime _getEndOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  DateTime _getEndOfWeek() {
    final now = DateTime.now();
    final daysUntilSunday = DateTime.sunday - now.weekday;
    return now.add(Duration(days: daysUntilSunday));
  }

  void _startQuestResetTimer() {
    _questResetTimer?.cancel();
    _questResetTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkQuestReset();
    });
  }

  void _checkQuestReset() {
    // 매일 자정 리셋
    // 매주 일요일 리셋
  }

  /// 프리미엄 구매
  Future<bool> purchasePremium() async {
    if (_currentUserId == null) return false;
    if (_playerBattlePass == null) return false;
    if (_playerBattlePass!.isPremiumPurchased) return false;

    // 결제 처리 (실제로는 IAP 연동)
    final paymentSuccess = await _processPayment();

    if (!paymentSuccess) return false;

    final updated = PlayerBattlePass(
      seasonId: _playerBattlePass!.seasonId,
      status: BattlePassStatus.active,
      currentLevel: _playerBattlePass!.currentLevel,
      currentXP: _playerBattlePass!.currentXP,
      isPremiumPurchased: true,
      claimedFreeLevels: _playerBattlePass!.claimedFreeLevels,
      claimedPremiumLevels: _playerBattlePass!.claimedPremiumLevels,
      purchasedAt: DateTime.now(),
    );

    _playerBattlePass = updated;
    _progressController.add(updated);

    await _savePlayerData();

    debugPrint('[BattlePass] Premium purchased');

    return true;
  }

  Future<bool> _processPayment() async {
    // 실제 결제 처리
    return true;
  }

  /// 경험치 추가
  Future<void> addXP(int xp) async {
    if (_playerBattlePass == null) return;
    if (_playerBattlePass!.status == BattlePassStatus.notPurchased) return;

    var newXP = _playerBattlePass!.currentXP + xp;
    var newLevel = _playerBattlePass!.currentLevel;

    // 레벨업 체크
    while (newXP >= 1000 && newLevel < 100) {
      newXP -= 1000;
      newLevel++;
    }

    final updated = PlayerBattlePass(
      seasonId: _playerBattlePass!.seasonId,
      status: newLevel >= 100
          ? BattlePassStatus.completed
          : _playerBattlePass!.status,
      currentLevel: newLevel,
      currentXP: newXP,
      isPremiumPurchased: _playerBattlePass!.isPremiumPurchased,
      claimedFreeLevels: _playerBattlePass!.claimedFreeLevels,
      claimedPremiumLevels: _playerBattlePass!.claimedPremiumLevels,
      purchasedAt: _playerBattlePass!.purchasedAt,
      completedAt: newLevel >= 100 ? DateTime.now() : null,
    );

    _playerBattlePass = updated;
    _progressController.add(updated);

    await _savePlayerData();

    debugPrint('[BattlePass] XP added: $xp, Level: $newLevel');
  }

  /// 보상 수령
  Future<BattlePassReward?> claimReward(int level) async {
    if (_playerBattlePass == null) return null;
    if (_currentSeason == null) return null;
    if (level > _playerBattlePass!.currentLevel) return null;

    BattlePassReward? reward;
    Set<int> claimedLevels;

    // 무료 보상
    if (!_playerBattlePass!.claimedFreeLevels.contains(level)) {
      final levelData = _currentSeason!.levels.firstWhere((l) => l.level == level);
      reward = levelData.freeReward;

      if (reward != null) {
        claimedLevels = Set<int>.from(_playerBattlePass!.claimedFreeLevels);
        claimedLevels.add(level);

        _playerBattlePass = PlayerBattlePass(
          seasonId: _playerBattlePass!.seasonId,
          status: _playerBattlePass!.status,
          currentLevel: _playerBattlePass!.currentLevel,
          currentXP: _playerBattlePass!.currentXP,
          isPremiumPurchased: _playerBattlePass!.isPremiumPurchased,
          claimedFreeLevels: claimedLevels,
          claimedPremiumLevels: _playerBattlePass!.claimedPremiumLevels,
          purchasedAt: _playerBattlePass!.purchasedAt,
          completedAt: _playerBattlePass!.completedAt,
        );

        _grantReward(reward);
        _rewardController.add(reward);

        debugPrint('[BattlePass] Free reward claimed: Level $level');

        await _savePlayerData();
        return reward;
      }
    }

    // 프리미엄 보상
    if (_playerBattlePass!.isPremiumPurchased &&
        !_playerBattlePass!.claimedPremiumLevels.contains(level)) {
      final levelData = _currentSeason!.levels.firstWhere((l) => l.level == level);
      reward = levelData.premiumReward;

      if (reward != null) {
        claimedLevels = Set<int>.from(_playerBattlePass!.claimedPremiumLevels);
        claimedLevels.add(level);

        _playerBattlePass = PlayerBattlePass(
          seasonId: _playerBattlePass!.seasonId,
          status: _playerBattlePass!.status,
          currentLevel: _playerBattlePass!.currentLevel,
          currentXP: _playerBattlePass!.currentXP,
          isPremiumPurchased: _playerBattlePass!.isPremiumPurchased,
          claimedFreeLevels: _playerBattlePass!.claimedFreeLevels,
          claimedPremiumLevels: claimedLevels,
          purchasedAt: _playerBattlePass!.purchasedAt,
          completedAt: _playerBattlePass!.completedAt,
        );

        _grantReward(reward);
        _rewardController.add(reward);

        debugPrint('[BattlePass] Premium reward claimed: Level $level');

        await _savePlayerData();
        return reward;
      }
    }

    return null;
  }

  Future<void> _grantReward(BattlePassReward reward) async {
    // 실제 보상 지급
    debugPrint('[BattlePass] Granting reward: ${reward.name}');
  }

  /// 퀘스트 진행 업데이트
  Future<void> updateQuestProgress({
    required String questId,
    required int progress,
  }) async {
    Quest? targetQuest;
    List<Quest>? questList;

    // 퀘스트 찾기
    targetQuest = _dailyQuests.cast<Quest?>().firstWhere(
      (q) => q?.id == questId,
      orElse: () => _weeklyQuests.cast<Quest?>().firstWhere(
        (q) => q?.id == questId,
        orElse: () => _premiumQuests.cast<Quest?>().firstWhere(
          (q) => q?.id == questId,
          orElse: () => null,
        ),
      ),
    );

    if (targetQuest == null) return;

    final updated = Quest(
      id: targetQuest.id,
      name: targetQuest.name,
      description: targetQuest.description,
      type: targetQuest.type,
      xpReward: targetQuest.xpReward,
      criteria: targetQuest.criteria,
      currentProgress: progress,
      maxProgress: targetQuest.maxProgress,
      isCompleted: progress >= targetQuest.maxProgress,
      isClaimed: targetQuest.isClaimed,
      expiresAt: targetQuest.expiresAt,
    );

    // 퀘스트 업데이트
    _dailyQuests.removeWhere((q) => q.id == questId);
    _weeklyQuests.removeWhere((q) => q.id == questId);
    _premiumQuests.removeWhere((q) => q.id == questId);

    switch (targetQuest.type) {
      case QuestType.daily:
        _dailyQuests.add(updated);
        break;
      case QuestType.weekly:
        _weeklyQuests.add(updated);
        break;
      case QuestType.premium:
        _premiumQuests.add(updated);
        break;
    }

    _questController.add(updated);

    // 완료 시 자동 보상
    if (updated.isCompleted && !updated.isClaimed) {
      await addQuestXP(updated);
    }
  }

  /// 퀘스트 보상 수령
  Future<void> claimQuestReward(String questId) async {
    Quest? targetQuest = _findQuest(questId);
    if (targetQuest == null) return;
    if (!targetQuest.canClaim) return;

    await addQuestXP(targetQuest);

    // 퀘스트 완료 처리
    final claimed = Quest(
      id: targetQuest.id,
      name: targetQuest.name,
      description: targetQuest.description,
      type: targetQuest.type,
      xpReward: targetQuest.xpReward,
      criteria: targetQuest.criteria,
      currentProgress: targetQuest.currentProgress,
      maxProgress: targetQuest.maxProgress,
      isCompleted: targetQuest.isCompleted,
      isClaimed: true,
      expiresAt: targetQuest.expiresAt,
    );

    _updateQuest(claimed);
  }

  Future<void> addQuestXP(Quest quest) async {
    await addXP(quest.xpReward);
    debugPrint('[BattlePass] Quest XP added: ${quest.xpReward}');
  }

  Quest? _findQuest(String questId) {
    return _dailyQuests.cast<Quest?>().firstWhere(
      (q) => q?.id == questId,
      orElse: () => _weeklyQuests.cast<Quest?>().firstWhere(
        (q) => q?.id == questId,
        orElse: () => _premiumQuests.cast<Quest?>().firstWhere(
          (q) => q?.id == questId,
          orElse: () => null,
        ),
      ),
    );
  }

  void _updateQuest(Quest updated) {
    _dailyQuests.removeWhere((q) => q.id == updated.id);
    _weeklyQuests.removeWhere((q) => q.id == updated.id);
    _premiumQuests.removeWhere((q) => q.id == updated.id);

    switch (updated.type) {
      case QuestType.daily:
        _dailyQuests.add(updated);
        break;
      case QuestType.weekly:
        _weeklyQuests.add(updated);
        break;
      case QuestType.premium:
        _premiumQuests.add(updated);
        break;
    }
  }

  /// 현재 시즌
  BattlePassSeason? getCurrentSeason() {
    return _currentSeason;
  }

  /// 플레이어 배틀패스
  PlayerBattlePass? getPlayerBattlePass() {
    return _playerBattlePass;
  }

  /// 일일 퀘스트
  List<Quest> getDailyQuests() {
    return _dailyQuests.toList();
  }

  /// 주간 퀘스트
  List<Quest> getWeeklyQuests() {
    return _weeklyQuests.toList();
  }

  /// 프리미엄 퀘스트
  List<Quest> getPremiumQuests() {
    return _playerBattlePass?.isPremiumPurchased == true
        ? _premiumQuests.toList()
        : [];
  }

  /// 수령 가능 보상 개수
  int getTotalClaimableRewards() {
    if (_playerBattlePass == null) return 0;
    return _playerBattlePass!.totalClaimable;
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerBattlePass == null) return;

    final data = {
      'seasonId': _playerBattlePass!.seasonId,
      'status': _playerBattlePass!.status.name,
      'currentLevel': _playerBattlePass!.currentLevel,
      'currentXP': _playerBattlePass!.currentXP,
      'isPremiumPurchased': _playerBattlePass!.isPremiumPurchased,
      'claimedFreeLevels': _playerBattlePass!.claimedFreeLevels.toList(),
      'claimedPremiumLevels': _playerBattlePass!.claimedPremiumLevels.toList(),
    };

    await _prefs?.setString(
      'battle_pass_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _progressController.close();
    _rewardController.close();
    _questController.close();
    _questResetTimer?.cancel();
  }
}

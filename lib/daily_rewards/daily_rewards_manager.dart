import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 보상 타입
enum DailyRewardType {
  currency,       // 통화
  item,           // 아이템
  experience,     // 경험치
  booster,        // 부스터
  special,        // 특별 보상
}

/// 일일 보상
class DailyReward {
  final int day;
  final List<RewardItem> rewards;
  final bool isSpecial; // 특별 보상일
  final String? icon;
  final String? description;

  const DailyReward({
    required this.day,
    required this.rewards,
    this.isSpecial = false,
    this.icon,
    this.description,
  });

  /// 총 보상 가치 (점수)
  int get totalValue {
    return rewards.fold<int>(0, (sum, r) => sum + (r.value ?? 0));
  }
}

/// 보상 아이템
class RewardItem {
  final DailyRewardType type;
  final String id;
  final String name;
  final int quantity;
  final int? rarity; // 1-5
  final int? value;  // 가치 점수
  final Map<String, dynamic>? metadata;

  const RewardItem({
    required this.type,
    required this.id,
    required this.name,
    required this.quantity,
    this.rarity,
    this.value,
    this.metadata,
  });
}

/// 스트릭 보너스
class StreakBonus {
  final int streakDays;
  final double multiplier; // 보상 배율
  final List<RewardItem> bonusRewards;
  final String? title;

  const StreakBonus({
    required this.streakDays,
    required this.multiplier,
    required this.bonusRewards,
    this.title,
  });
}

/// 플레이어 일일 보상 데이터
class PlayerDailyRewardData {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int totalClaimedDays;
  final DateTime? lastClaimDate;
  final Set<int> claimedDays; // 현재 월의 수령한 날짜
  final bool canClaimToday;
  final DateTime? nextClaimTime;
  final bool usedMissedRecovery; // 복구 사용 여부

  const PlayerDailyRewardData({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalClaimedDays,
    this.lastClaimDate,
    required this.claimedDays,
    required this.canClaimToday,
    this.nextClaimTime,
    this.usedMissedRecovery = false,
  });

  /// 다음 보상 날짜 (1-based)
  int get nextRewardDay {
    if (canClaimToday) return currentStreak + 1;
    return currentStreak + 1;
  }

  /// 남은 시간
  Duration? get timeUntilNextClaim {
    if (nextClaimTime == null) return null;
    final diff = nextClaimTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 진행률 (현재 월)
  double get monthlyProgress {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    return claimedDays.length / daysInMonth;
  }
}

/// 월간 보상
class MonthlyReward {
  final int month; // 1-12
  final int requiredDays; // 필요한 일수
  final List<RewardItem> rewards;
  final bool isClaimed;

  const MonthlyReward({
    required this.month,
    required this.requiredDays,
    required this.rewards,
    this.isClaimed = false,
  });

  /// 달성 가능 여부
  bool isAchievable(int claimedDays) {
    return claimedDays >= requiredDays;
  }
}

/// 일일 보상 관리자
class DailyRewardsManager {
  static final DailyRewardsManager _instance = DailyRewardsManager._();
  static DailyRewardsManager get instance => _instance;

  DailyRewardsManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  PlayerDailyRewardData? _playerData;

  final List<DailyReward> _dailyRewards = [];
  final List<StreakBonus> _streakBonuses = [];
  final List<MonthlyReward> _monthlyRewards = [];

  final StreamController<PlayerDailyRewardData> _dataController =
      StreamController<PlayerDailyRewardData>.broadcast();
  final StreamController<List<RewardItem>> _claimController =
      StreamController<List<RewardItem>>.broadcast();

  Stream<PlayerDailyRewardData> get onDataUpdate => _dataController.stream;
  Stream<List<RewardItem>> get onRewardClaim => _claimController.stream;

  Timer? _resetTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 보상 로드
    _loadRewards();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    // 리셋 타이머 시작
    _startResetTimer();

    debugPrint('[DailyRewards] Initialized');
  }

  void _loadRewards() {
    // 30일간의 일일 보상
    _dailyRewards.clear();

    for (var day = 1; day <= 30; day++) {
      final rewards = _generateDayRewards(day);
      final isSpecial = day % 7 == 0; // 7일마다 특별 보상

      _dailyRewards.add(DailyReward(
        day: day,
        rewards: rewards,
        isSpecial: isSpecial,
        icon: isSpecial ? 'assets/rewards/special_$day.png' : null,
        description: isSpecial ? '$day일 특별 보상!' : null,
      ));
    }

    // 스트릭 보너스
    _streakBonuses.clear();
    _streakBonuses.addAll([
      const StreakBonus(
        streakDays: 7,
        multiplier: 1.5,
        bonusRewards: [
          RewardItem(
            type: DailyRewardType.currency,
            id: 'gems',
            name: '젬',
            quantity: 50,
            value: 50,
          ),
        ],
        title: '주간 보너스',
      ),
      const StreakBonus(
        streakDays: 14,
        multiplier: 2.0,
        bonusRewards: [
          RewardItem(
            type: DailyRewardType.item,
            id: 'rare_box',
            name: '희귀 상자',
            quantity: 1,
            rarity: 3,
            value: 300,
          ),
        ],
        title: '2주 보너스',
      ),
      const StreakBonus(
        streakDays: 30,
        multiplier: 3.0,
        bonusRewards: [
          RewardItem(
            type: DailyRewardType.special,
            id: 'legendary_box',
            name: '레전더리 상자',
            quantity: 1,
            rarity: 5,
            value: 1000,
          ),
          RewardItem(
            type: DailyRewardType.currency,
            id: 'gems',
            name: '젬',
            quantity: 500,
            value: 500,
          ),
        ],
        title: '월간 보너스',
      ),
    ]);

    // 월간 보상
    _monthlyRewards.clear();
    _monthlyRewards.addAll([
      MonthlyReward(
        month: 1,
        requiredDays: 25,
        rewards: const [
          RewardItem(
            type: DailyRewardType.currency,
            id: 'gold',
            name: '골드',
            quantity: 10000,
            value: 1000,
          ),
        ],
      ),
      MonthlyReward(
        month: 2,
        requiredDays: 25,
        rewards: const [
          RewardItem(
            type: DailyRewardType.item,
            id: 'epic_box',
            name: '에픽 상자',
            quantity: 1,
            rarity: 4,
            value: 500,
          ),
        ],
      ),
      MonthlyReward(
        month: 3,
        requiredDays: 28,
        rewards: const [
          RewardItem(
            type: DailyRewardType.special,
            id: 'exclusive_skin',
            name: '독점 스킨',
            quantity: 1,
            rarity: 5,
            value: 2000,
          ),
        ],
      ),
    ]);
  }

  List<RewardItem> _generateDayRewards(int day) {
    final rewards = <RewardItem>[];

    // 기본 보상: 골드
    final goldAmount = 100 * day;
    rewards.add(RewardItem(
      type: DailyRewardType.currency,
      id: 'gold',
      name: '골드',
      quantity: goldAmount,
      value: goldAmount ~/ 10,
    ));

    // 5일마다 젬
    if (day % 5 == 0) {
      rewards.add(RewardItem(
        type: DailyRewardType.currency,
        id: 'gems',
        name: '젬',
        quantity: 10 + (day ~/ 5) * 5,
        value: 10 + (day ~/ 5) * 5,
      ));
    }

    // 10일마다 아이템
    if (day % 10 == 0) {
      rewards.add(RewardItem(
        type: DailyRewardType.item,
        id: 'common_box',
        name: '일반 상자',
        quantity: 1,
        rarity: 1,
        value: 50,
      ));
    }

    // 30일차 특별 보상
    if (day == 30) {
      rewards.add(RewardItem(
        type: DailyRewardType.special,
        id: 'exclusive_title',
        name: '독점 칭호',
        quantity: 1,
        rarity: 5,
        value: 1500,
      ));
    }

    return rewards;
  }

  Future<void> _loadPlayerData(String userId) async {
    final json = _prefs?.getString('daily_rewards_$userId');
    int currentStreak = 0;
    int longestStreak = 0;
    int totalClaimedDays = 0;
    DateTime? lastClaimDate;
    Set<int> claimedDays = {};
    bool usedMissedRecovery = false;

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        currentStreak = data['currentStreak'] ?? 0;
        longestStreak = data['longestStreak'] ?? 0;
        totalClaimedDays = data['totalClaimedDays'] ?? 0;
        usedMissedRecovery = data['usedMissedRecovery'] ?? false;

        if (data['lastClaimDate'] != null) {
          lastClaimDate = DateTime.parse(data['lastClaimDate']);
        }

        if (data['claimedDays'] != null) {
          claimedDays = (data['claimedDays'] as List)
              .map((e) => e as int)
              .toSet();
        }
      } catch (e) {
        debugPrint('[DailyRewards] Error loading data: $e');
      }
    }

    // 오늘 수령 가능 여부 확인
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final canClaim = lastClaimDate == null ||
        today.isAfter(DateTime(
          lastClaimDate.year,
          lastClaimDate.month,
          lastClaimDate.day,
        ));

    // 자정 기준 다음 수령 시간
    final nextClaim = canClaim
        ? null
        : DateTime(now.year, now.month, now.day + 1);

    _playerData = PlayerDailyRewardData(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalClaimedDays: totalClaimedDays,
      lastClaimDate: lastClaimDate,
      claimedDays: claimedDays,
      canClaimToday: canClaim,
      nextClaimTime: nextClaim,
      usedMissedRecovery: usedMissedRecovery,
    );

    // 월간 보상 클레임 상태 업데이트
    _updateMonthlyRewardsClaimed();

    _dataController.add(_playerData!);
  }

  void _updateMonthlyRewardsClaimed() {
    // 실제로는 서버에서 클레임 상태를 가져옴
    // 여기서는 시뮬레이션
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkReset();
    });
  }

  void _checkReset() {
    if (_playerData == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 마지막 수령일이 오늘이 아니면 수령 가능
    if (_playerData!.lastClaimDate != null) {
      final lastClaim = DateTime(
        _playerData!.lastClaimDate!.year,
        _playerData!.lastClaimDate!.month,
        _playerData!.lastClaimDate!.day,
      );

      if (today.isAfter(lastClaim) && !_playerData!.canClaimToday) {
        _playerData = PlayerDailyRewardData(
          userId: _playerData!.userId,
          currentStreak: _playerData!.currentStreak,
          longestStreak: _playerData!.longestStreak,
          totalClaimedDays: _playerData!.totalClaimedDays,
          lastClaimDate: _playerData!.lastClaimDate,
          claimedDays: _playerData!.claimedDays,
          canClaimToday: true,
          nextClaimTime: null,
          usedMissedRecovery: _playerData!.usedMissedRecovery,
        );

        _dataController.add(_playerData!);
        _savePlayerData();
      }
    }
  }

  /// 보상 수령
  Future<List<RewardItem>> claimReward() async {
    if (_currentUserId == null) return [];
    if (_playerData == null) return [];
    if (!_playerData!.canClaimToday) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 스트릭 계산
    var newStreak = _playerData!.currentStreak + 1;

    // 어제 수급했으면 스트릭 유지
    if (_playerData!.lastClaimDate != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      final lastClaim = DateTime(
        _playerData!.lastClaimDate!.year,
        _playerData!.lastClaimDate!.month,
        _playerData!.lastClaimDate!.day,
      );

      if (lastClaim.isAtSameMomentAs(yesterday)) {
        newStreak = _playerData!.currentStreak + 1;
      } else if (lastClaim.isBefore(yesterday)) {
        // 연속이 끊김
        newStreak = 1;
      }
    }

    // 보상 계산
    final rewardDay = newStreak > 30 ? 30 : newStreak;
    final dailyReward = _dailyRewards.firstWhere(
      (r) => r.day == rewardDay,
      orElse: () => _dailyRewards.last,
    );

    var finalRewards = <RewardItem>[...dailyReward.rewards];

    // 스트릭 보너스 확인
    for (final bonus in _streakBonuses) {
      if (newStreak % bonus.streakDays == 0) {
        // 배율 적용
        final multipliedRewards = finalRewards.map((r) => RewardItem(
          type: r.type,
          id: r.id,
          name: r.name,
          quantity: (r.quantity * bonus.multiplier).toInt(),
          rarity: r.rarity,
          value: r.value,
          metadata: r.metadata,
        )).toList();

        finalRewards = [...multipliedRewards, ...bonus.bonusRewards];

        debugPrint('[DailyRewards] Streak bonus: ${bonus.title}');
      }
    }

    // 데이터 업데이트
    final newClaimedDays = Set<int>.from(_playerData!.claimedDays);
    newClaimedDays.add(now.day);

    final newLongestStreak = newStreak > _playerData!.longestStreak
        ? newStreak
        : _playerData!.longestStreak;

    final updated = PlayerDailyRewardData(
      userId: _playerData!.userId,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      totalClaimedDays: _playerData!.totalClaimedDays + 1,
      lastClaimDate: now,
      claimedDays: newClaimedDays,
      canClaimToday: false,
      nextClaimTime: DateTime(now.year, now.month, now.day + 1),
      usedMissedRecovery: false,
    );

    _playerData = updated;
    _dataController.add(updated);
    _claimController.add(finalRewards);

    await _savePlayerData();

    // 보상 지급
    await _grantRewards(finalRewards);

    debugPrint('[DailyRewards] Claimed: Day $newStreak, ${finalRewards.length} items');

    return finalRewards;
  }

  /// 빠진 날 복구
  Future<bool> recoverMissedDay() async {
    if (_playerData == null) return false;
    if (_playerData!.usedMissedRecovery) return false;
    if (_playerData!.canClaimToday) return false;

    // 어제 수령하지 않았으면 복구 가능
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_playerData!.lastClaimDate != null) {
      final lastClaim = DateTime(
        _playerData!.lastClaimDate!.year,
        _playerData!.lastClaimDate!.month,
        _playerData!.lastClaimDate!.day,
      );

      if (lastClaim.isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day))) {
        // 복구 불가 (너무 오래됨)
        return false;
      }
    }

    // 복구 처리
    final updated = PlayerDailyRewardData(
      userId: _playerData!.userId,
      currentStreak: _playerData!.currentStreak,
      longestStreak: _playerData!.longestStreak,
      totalClaimedDays: _playerData!.totalClaimedDays,
      lastClaimDate: _playerData!.lastClaimDate,
      claimedDays: _playerData!.claimedDays,
      canClaimToday: true,
      nextClaimTime: null,
      usedMissedRecovery: true,
    );

    _playerData = updated;
    _dataController.add(updated);

    await _savePlayerData();

    debugPrint('[DailyRewards] Missed day recovered');

    return true;
  }

  Future<void> _grantRewards(List<RewardItem> rewards) async {
    // 실제 보상 지급
    for (final reward in rewards) {
      debugPrint('[DailyRewards] Granted: ${reward.name} x${reward.quantity}');
    }
  }

  /// 월간 보상 수령
  Future<bool> claimMonthlyReward(int month) async {
    if (_playerData == null) return false;

    final monthlyReward = _monthlyRewards.cast<MonthlyReward?>().firstWhere(
      (r) => r?.month == month,
      orElse: () => null,
    );

    if (monthlyReward == null) return false;
    if (monthlyReward.isClaimed) return false;
    if (!monthlyReward.isAchievable(_playerData!.claimedDays.length)) return false;

    // 수령 처리
    await _grantRewards(monthlyReward.rewards);

    debugPrint('[DailyRewards] Monthly reward claimed: Month $month');

    return true;
  }

  /// 일일 보상 목록
  List<DailyReward> getDailyRewards() {
    return _dailyRewards.toList();
  }

  /// 다음 보상
  DailyReward? getNextReward() {
    if (_playerData == null) return null;
    final day = _playerData!.nextRewardDay;
    return _dailyRewards.cast<DailyReward?>().firstWhere(
      (r) => r?.day == day,
      orElse: () => null,
    );
  }

  /// 스트릭 보너스 목록
  List<StreakBonus> getStreakBonuses() {
    return _streakBonuses.toList();
  }

  /// 다음 스트릭 보너스
  StreakBonus? getNextStreakBonus() {
    if (_playerData == null) return null;

    for (final bonus in _streakBonuses) {
      if (_playerData!.currentStreak < bonus.streakDays) {
        return bonus;
      }
    }

    return null;
  }

  /// 월간 보상 목록
  List<MonthlyReward> getMonthlyRewards() {
    return _monthlyRewards.toList();
  }

  /// 플레이어 데이터
  PlayerDailyRewardData? getPlayerData() {
    return _playerData;
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerData == null) return;

    final data = {
      'currentStreak': _playerData!.currentStreak,
      'longestStreak': _playerData!.longestStreak,
      'totalClaimedDays': _playerData!.totalClaimedDays,
      'lastClaimDate': _playerData!.lastClaimDate?.toIso8601String(),
      'claimedDays': _playerData!.claimedDays.toList(),
      'usedMissedRecovery': _playerData!.usedMissedRecovery,
    };

    await _prefs?.setString(
      'daily_rewards_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _dataController.close();
    _claimController.close();
    _resetTimer?.cancel();
  }
}

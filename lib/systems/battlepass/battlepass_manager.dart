/// 배틀패스 매니저 - MG Common Game
///
/// 시즌 진행, 경험치 관리, 보상 수령
library;

import 'package:flutter/foundation.dart';

import 'battlepass_config.dart';

/// 미션 진행 상태
class MissionProgress {
  final String missionId;
  int currentValue;
  bool isClaimed;

  MissionProgress({
    required this.missionId,
    this.currentValue = 0,
    this.isClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'currentValue': currentValue,
    'isClaimed': isClaimed,
  };

  factory MissionProgress.fromJson(Map<String, dynamic> json) => MissionProgress(
    missionId: json['missionId'] ?? '',
    currentValue: json['currentValue'] ?? 0,
    isClaimed: json['isClaimed'] ?? false,
  );
}

/// 배틀패스 상태
class BattlePassState {
  final String seasonId;
  int currentLevel;
  int currentExp;
  bool isPremium;
  Set<int> claimedFreeLevels;
  Set<int> claimedPremiumLevels;
  Map<String, MissionProgress> missionProgress;
  DateTime? premiumPurchaseDate;

  BattlePassState({
    required this.seasonId,
    this.currentLevel = 1,
    this.currentExp = 0,
    this.isPremium = false,
    Set<int>? claimedFreeLevels,
    Set<int>? claimedPremiumLevels,
    Map<String, MissionProgress>? missionProgress,
    this.premiumPurchaseDate,
  }) : claimedFreeLevels = claimedFreeLevels ?? {},
       claimedPremiumLevels = claimedPremiumLevels ?? {},
       missionProgress = missionProgress ?? {};

  Map<String, dynamic> toJson() => {
    'seasonId': seasonId,
    'currentLevel': currentLevel,
    'currentExp': currentExp,
    'isPremium': isPremium,
    'claimedFreeLevels': claimedFreeLevels.toList(),
    'claimedPremiumLevels': claimedPremiumLevels.toList(),
    'missionProgress': missionProgress.map((k, v) => MapEntry(k, v.toJson())),
    'premiumPurchaseDate': premiumPurchaseDate?.toIso8601String(),
  };

  factory BattlePassState.fromJson(Map<String, dynamic> json) => BattlePassState(
    seasonId: json['seasonId'] ?? '',
    currentLevel: json['currentLevel'] ?? 1,
    currentExp: json['currentExp'] ?? 0,
    isPremium: json['isPremium'] ?? false,
    claimedFreeLevels: (json['claimedFreeLevels'] as List?)
        ?.map((e) => e as int).toSet() ?? {},
    claimedPremiumLevels: (json['claimedPremiumLevels'] as List?)
        ?.map((e) => e as int).toSet() ?? {},
    missionProgress: (json['missionProgress'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, MissionProgress.fromJson(v))) ?? {},
    premiumPurchaseDate: json['premiumPurchaseDate'] != null
        ? DateTime.parse(json['premiumPurchaseDate'])
        : null,
  );
}

/// 배틀패스 매니저
class BattlePassManager extends ChangeNotifier {
  BPSeasonConfig? _currentSeason;
  BattlePassState? _state;
  List<BPMission> _dailyMissions = [];
  List<BPMission> _weeklyMissions = [];
  List<BPMission> _seasonalMissions = [];

  /// 콜백
  void Function(int level)? onLevelUp;
  void Function(List<BPReward> rewards)? onRewardClaimed;
  void Function(BPMission mission)? onMissionComplete;

  /// 현재 시즌
  BPSeasonConfig? get currentSeason => _currentSeason;

  /// 현재 상태
  BattlePassState? get state => _state;

  /// 현재 레벨
  int get currentLevel => _state?.currentLevel ?? 1;

  /// 현재 경험치
  int get currentExp => _state?.currentExp ?? 0;

  /// 프리미엄 여부
  bool get isPremium => _state?.isPremium ?? false;

  /// 일일 미션
  List<BPMission> get dailyMissions => _dailyMissions;

  /// 주간 미션
  List<BPMission> get weeklyMissions => _weeklyMissions;

  /// 시즌 설정
  void setSeason(BPSeasonConfig season) {
    _currentSeason = season;

    // 기존 상태가 다른 시즌이면 리셋
    if (_state == null || _state!.seasonId != season.id) {
      _state = BattlePassState(seasonId: season.id);
    }

    notifyListeners();
  }

  /// 미션 설정
  void setMissions({
    List<BPMission>? daily,
    List<BPMission>? weekly,
    List<BPMission>? seasonal,
  }) {
    if (daily != null) _dailyMissions = daily;
    if (weekly != null) _weeklyMissions = weekly;
    if (seasonal != null) _seasonalMissions = seasonal;

    // 미션 진행 상태 초기화
    for (final mission in [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]) {
      _state?.missionProgress.putIfAbsent(
        mission.id,
        () => MissionProgress(missionId: mission.id),
      );
    }

    notifyListeners();
  }

  /// 경험치 추가
  void addExp(int amount) {
    if (_state == null || _currentSeason == null) return;
    if (_state!.currentLevel >= _currentSeason!.maxLevel) return;

    _state!.currentExp += amount;

    // 레벨업 체크
    while (_state!.currentLevel < _currentSeason!.maxLevel) {
      final tier = _currentSeason!.getTier(_state!.currentLevel);
      final requiredExp = tier?.requiredExp ?? _currentSeason!.expPerLevel;

      if (_state!.currentExp >= requiredExp) {
        _state!.currentExp -= requiredExp;
        _state!.currentLevel++;
        onLevelUp?.call(_state!.currentLevel);
      } else {
        break;
      }
    }

    // 최대 레벨에서 경험치 캡
    if (_state!.currentLevel >= _currentSeason!.maxLevel) {
      _state!.currentExp = 0;
    }

    notifyListeners();
  }

  /// 레벨업까지 필요한 경험치
  int get expToNextLevel {
    if (_state == null || _currentSeason == null) return 0;
    if (_state!.currentLevel >= _currentSeason!.maxLevel) return 0;

    final tier = _currentSeason!.getTier(_state!.currentLevel);
    final required = tier?.requiredExp ?? _currentSeason!.expPerLevel;
    return required - _state!.currentExp;
  }

  /// 현재 레벨 진행률 (0.0 ~ 1.0)
  double get levelProgress {
    if (_state == null || _currentSeason == null) return 0;
    if (_state!.currentLevel >= _currentSeason!.maxLevel) return 1.0;

    final tier = _currentSeason!.getTier(_state!.currentLevel);
    final required = tier?.requiredExp ?? _currentSeason!.expPerLevel;
    return _state!.currentExp / required;
  }

  /// 보상 수령 가능 여부
  bool canClaimReward(int level, {required bool isPremiumReward}) {
    if (_state == null || _currentSeason == null) return false;
    if (level > _state!.currentLevel) return false;

    if (isPremiumReward) {
      if (!_state!.isPremium) return false;
      return !_state!.claimedPremiumLevels.contains(level);
    } else {
      return !_state!.claimedFreeLevels.contains(level);
    }
  }

  /// 보상 수령
  List<BPReward> claimReward(int level, {required bool isPremiumReward}) {
    if (!canClaimReward(level, isPremiumReward: isPremiumReward)) {
      return [];
    }

    final tier = _currentSeason!.getTier(level);
    if (tier == null) return [];

    List<BPReward> rewards;
    if (isPremiumReward) {
      rewards = tier.premiumRewards;
      _state!.claimedPremiumLevels.add(level);
    } else {
      rewards = tier.freeRewards;
      _state!.claimedFreeLevels.add(level);
    }

    onRewardClaimed?.call(rewards);
    notifyListeners();

    return rewards;
  }

  /// 모든 수령 가능한 보상 일괄 수령
  List<BPReward> claimAllAvailable() {
    final allRewards = <BPReward>[];

    for (int level = 1; level <= currentLevel; level++) {
      if (canClaimReward(level, isPremiumReward: false)) {
        allRewards.addAll(claimReward(level, isPremiumReward: false));
      }
      if (canClaimReward(level, isPremiumReward: true)) {
        allRewards.addAll(claimReward(level, isPremiumReward: true));
      }
    }

    return allRewards;
  }

  /// 미수령 보상 수
  int get unclaimedRewardCount {
    if (_state == null) return 0;

    int count = 0;
    for (int level = 1; level <= currentLevel; level++) {
      if (canClaimReward(level, isPremiumReward: false)) count++;
      if (canClaimReward(level, isPremiumReward: true)) count++;
    }
    return count;
  }

  /// 프리미엄 구매
  void purchasePremium() {
    if (_state == null) return;

    _state!.isPremium = true;
    _state!.premiumPurchaseDate = DateTime.now();
    notifyListeners();
  }

  /// 미션 진행도 업데이트
  void updateMissionProgress(String trackingKey, int value) {
    if (_state == null) return;

    final missions = [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]
        .where((m) => m.trackingKey == trackingKey);

    for (final mission in missions) {
      final progress = _state!.missionProgress.putIfAbsent(
        mission.id,
        () => MissionProgress(missionId: mission.id),
      );

      if (progress.isClaimed) continue;

      progress.currentValue = value;

      // 완료 체크
      if (progress.currentValue >= mission.targetValue && !progress.isClaimed) {
        onMissionComplete?.call(mission);
      }
    }

    notifyListeners();
  }

  /// 미션 진행도 증가
  void incrementMissionProgress(String trackingKey, {int amount = 1}) {
    if (_state == null) return;

    final missions = [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]
        .where((m) => m.trackingKey == trackingKey);

    for (final mission in missions) {
      final progress = _state!.missionProgress.putIfAbsent(
        mission.id,
        () => MissionProgress(missionId: mission.id),
      );

      if (progress.isClaimed) continue;

      progress.currentValue += amount;

      if (progress.currentValue >= mission.targetValue) {
        onMissionComplete?.call(mission);
      }
    }

    notifyListeners();
  }

  /// 미션 보상 수령
  bool claimMissionReward(String missionId) {
    if (_state == null) return false;

    final mission = [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]
        .firstWhere((m) => m.id == missionId, orElse: () => throw Exception('Mission not found'));

    final progress = _state!.missionProgress[missionId];
    if (progress == null) return false;
    if (progress.isClaimed) return false;
    if (progress.currentValue < mission.targetValue) return false;

    progress.isClaimed = true;
    addExp(mission.expReward);

    notifyListeners();
    return true;
  }

  /// 미션 완료 여부
  bool isMissionCompleted(String missionId) {
    final mission = [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]
        .firstWhere((m) => m.id == missionId, orElse: () => throw Exception('Mission not found'));

    final progress = _state?.missionProgress[missionId];
    if (progress == null) return false;

    return progress.currentValue >= mission.targetValue;
  }

  /// 미션 진행률
  double getMissionProgress(String missionId) {
    final mission = [..._dailyMissions, ..._weeklyMissions, ..._seasonalMissions]
        .firstWhere((m) => m.id == missionId, orElse: () => throw Exception('Mission not found'));

    final progress = _state?.missionProgress[missionId];
    if (progress == null) return 0;

    return (progress.currentValue / mission.targetValue).clamp(0.0, 1.0);
  }

  /// 일일 미션 리셋
  void resetDailyMissions() {
    for (final mission in _dailyMissions) {
      _state?.missionProgress[mission.id] = MissionProgress(missionId: mission.id);
    }
    notifyListeners();
  }

  /// 주간 미션 리셋
  void resetWeeklyMissions() {
    for (final mission in _weeklyMissions) {
      _state?.missionProgress[mission.id] = MissionProgress(missionId: mission.id);
    }
    notifyListeners();
  }

  /// 저장
  Map<String, dynamic> toJson() => {
    'state': _state?.toJson(),
  };

  /// 불러오기
  void loadFromJson(Map<String, dynamic> json) {
    if (json['state'] != null) {
      _state = BattlePassState.fromJson(json['state']);
    }
    notifyListeners();
  }

  /// 시즌 종료 처리
  void endSeason() {
    _state = null;
    _currentSeason = null;
    notifyListeners();
  }
}

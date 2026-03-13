import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 난이도 조정 타입
enum DifficultyAdjustmentType {
  enemyStats,       // 적 스탯
  playerStats,      // 플레이어 스탯
  levelDesign,      // 레벨 디자인
  rewards,          // 보상
  timeLimit,        // 시간 제한
  aiBehavior,       // AI 행동
}

/// 플레이어 실력 레벨
enum SkillLevel {
  beginner,        // 초보자
  novice,          // 초급
  intermediate,    // 중급
  advanced,        // 고급
  expert,          // 전문가
}

/// 난이도 계수
class DifficultyFactor {
  final String name;
  final double currentValue; // 0.0 - 2.0 (1.0 = 기본)
  final double minValue;
  final double maxValue;
  final double adjustmentSpeed; // 0.0 - 1.0

  const DifficultyFactor({
    required this.name,
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.adjustmentSpeed,
  });
}

/// 플레이어 성과
class PlayerPerformance {
  final String userId;
  final String sessionId;
  final int wins;
  final int losses;
  final double averageHealth; // 남은 HP 비율 평균
  final double averageCompletionTime; // 목표 달성 시간
  final int deaths;
  final int restarts;
  final double accuracy;
  final DateTime timestamp;

  const PlayerPerformance({
    required this.userId,
    required this.sessionId,
    required this.wins,
    required this.losses,
    required this.averageHealth,
    required this.averageCompletionTime,
    required this.deaths,
    required this.restarts,
    required this.accuracy,
    required this.timestamp,
  });

  /// 승률
  double get winRate {
    final total = wins + losses;
    return total > 0 ? wins / total : 0.5;
  }

  /// 종합 점수
  double get overallScore {
    var score = 0.0;

    // 승률 (40%)
    score += winRate * 0.4;

    // 생존률 (20%)
    score += averageHealth * 0.2;

    // 정확도 (20%)
    score += accuracy * 0.2;

    // 죽음 페널티 (10%)
    score -= (deaths * 0.05);

    // 재시작 페널티 (10%)
    score -= (restarts * 0.1);

    return score.clamp(0.0, 1.0);
  }

  /// 실력 레벨
  SkillLevel get skillLevel {
    final score = overallScore;
    if (score >= 0.9) return SkillLevel.expert;
    if (score >= 0.7) return SkillLevel.advanced;
    if (score >= 0.5) return SkillLevel.intermediate;
    if (score >= 0.3) return SkillLevel.novice;
    return SkillLevel.beginner;
  }
}

/// 난이도 설정
class DifficultySettings {
  final Map<String, double> enemyHealthMultipliers; // enemyId -> multiplier
  final Map<String, double> enemyDamageMultipliers;
  final Map<String, double> playerBuffMultipliers;
  final double timeLimitMultiplier;
  final double rewardMultiplier;
  final double aiDifficulty; // 0.0 - 1.0
  final DateTime appliedAt;

  const DifficultySettings({
    required this.enemyHealthMultipliers,
    required this.enemyDamageMultipliers,
    required this.playerBuffMultipliers,
    required this.timeLimitMultiplier,
    required this.rewardMultiplier,
    required this.aiDifficulty,
    required this.appliedAt,
  });
}

/// 난이도 조정 이벤트
class DifficultyAdjustmentEvent {
  final String id;
  final String sessionId;
  final DifficultyAdjustmentType type;
  final double previousValue;
  final double newValue;
  final String reason;
  final DateTime timestamp;

  const DifficultyAdjustmentEvent({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.previousValue,
    required this.newValue,
    required this.reason,
    required this.timestamp,
  });
}

/// 동적 난이도 관리자
class DynamicDifficultyManager {
  static final DynamicDifficultyManager _instance =
      DynamicDifficultyManager._();
  static DynamicDifficultyManager get instance => _instance;

  DynamicDifficultyManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, PlayerPerformance> _performanceHistory = {};
  final Map<String, DifficultyFactor> _factors = {};
  final Map<String, DifficultySettings> _activeSettings = {};
  final List<DifficultyAdjustmentEvent> _adjustmentEvents = [];

  final StreamController<PlayerPerformance> _performanceController =
      StreamController<PlayerPerformance>.broadcast();
  final StreamController<DifficultySettings> _settingsController =
      StreamController<DifficultySettings>.broadcast();
  final StreamController<DifficultyAdjustmentEvent> _adjustmentController =
      StreamController<DifficultyAdjustmentEvent>.broadcast();

  Stream<PlayerPerformance> get onPerformanceUpdate =>
      _performanceController.stream;
  Stream<DifficultySettings> get onSettingsUpdate => _settingsController.stream;
  Stream<DifficultyAdjustmentEvent> get onAdjustment =>
      _adjustmentController.stream;

  Timer? _monitorTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 난이도 계수 초기화
    _initializeFactors();

    // 모니터링 시작
    _startMonitoring();

    debugPrint('[DynamicDifficulty] Initialized');
  }

  void _initializeFactors() {
    _factors['enemy_health'] = const DifficultyFactor(
      name: 'enemy_health',
      currentValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
      adjustmentSpeed: 0.1,
    );

    _factors['enemy_damage'] = const DifficultyFactor(
      name: 'enemy_damage',
      currentValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
      adjustmentSpeed: 0.1,
    );

    _factors['player_buff'] = const DifficultyFactor(
      name: 'player_buff',
      currentValue: 1.0,
      minValue: 0.8,
      maxValue: 1.5,
      adjustmentSpeed: 0.15,
    );

    _factors['time_limit'] = const DifficultyFactor(
      name: 'time_limit',
      currentValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
      adjustmentSpeed: 0.1,
    );

    _factors['ai_difficulty'] = const DifficultyFactor(
      name: 'ai_difficulty',
      currentValue: 0.5,
      minValue: 0.0,
      maxValue: 1.0,
      adjustmentSpeed: 0.1,
    );

    _factors['reward'] = const DifficultyFactor(
      name: 'reward',
      currentValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
      adjustmentSpeed: 0.05,
    );
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _monitorPerformance();
    });
  }

  /// 플레이어 성과 기록
  Future<void> recordPerformance(PlayerPerformance performance) async {
    _performanceHistory[performance.sessionId] = performance;
    _performanceController.add(performance);

    // 실력 레벨 로그
    debugPrint('[DynamicDifficulty] Performance: ${performance.skillLevel.name} (${performance.overallScore.toStringAsFixed(2)})');

    // 난이도 조정
    await _adjustDifficulty(performance);
  }

  /// 성과 모니터링
  void _monitorPerformance() {
    if (_currentUserId == null) return;

    // 최근 성과 분석
    final recentPerformances = _performanceHistory.values
        .where((p) => p.userId == _currentUserId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (recentPerformances.isEmpty) return;

    final recent = recentPerformances.take(10).toList();

    // 평균 성과 계산
    final avgScore = recent
        .map((p) => p.overallScore)
        .reduce((a, b) => a + b) / recent.length;

    // 연속 승리/패배 체크
    final streaks = _analyzeStreaks(recent);

    // 동향 분석
    if (streaks['winningStreak'] >= 3 || avgScore > 0.7) {
      _increaseDifficulty('consistently_performing_well');
    } else if (streaks['losingStreak'] >= 3 || avgScore < 0.3) {
      _decreaseDifficulty('struggling_to_progress');
    }
  }

  /// 스트릭 분석
  Map<String, int> _analyzeStreaks(List<PlayerPerformance> performances) {
    var winningStreak = 0;
    var losingStreak = 0;
    var currentStreak = 0;
    bool? lastWasWin;

    for (final perf in performances) {
      final isWin = perf.winRate > 0.5;

      if (lastWasWin == null) {
        currentStreak = 1;
        lastWasWin = isWin;
      } else if (lastWasWin == isWin) {
        currentStreak++;
      } else {
        if (lastWasWin!) {
          winningStreak = winningStreak > currentStreak ? winningStreak : currentStreak;
        } else {
          losingStreak = losingStreak > currentStreak ? losingStreak : currentStreak;
        }
        currentStreak = 1;
        lastWasWin = isWin;
      }
    }

    if (lastWasWin != null) {
      if (lastWasWin!) {
        winningStreak = winningStreak > currentStreak ? winningStreak : currentStreak;
      } else {
        losingStreak = losingStreak > currentStreak ? losingStreak : currentStreak;
      }
    }

    return {
      'winningStreak': winningStreak,
      'losingStreak': losingStreak,
    };
  }

  /// 난이도 조정
  Future<void> _adjustDifficulty(PlayerPerformance performance) async {
    final sessionId = performance.sessionId;
    final skillLevel = performance.skillLevel;

    // 실력 레벨에 따른 난이도 계산
    final targetMultipliers = _getTargetMultipliers(skillLevel);

    final settings = DifficultySettings(
      enemyHealthMultipliers: targetMultipliers['enemy_health'] ?? {},
      enemyDamageMultipliers: targetMultipliers['enemy_damage'] ?? {},
      playerBuffMultipliers: targetMultipliers['player_buff'] ?? {},
      timeLimitMultiplier: targetMultipliers['time_limit'] ?? 1.0,
      rewardMultiplier: targetMultipliers['reward'] ?? 1.0,
      aiDifficulty: targetMultipliers['ai_difficulty'] ?? 0.5,
      appliedAt: DateTime.now(),
    );

    _activeSettings[sessionId] = settings;
    _settingsController.add(settings);

    // 조정 이벤트 기록
    final event = DifficultyAdjustmentEvent(
      id: 'adjust_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      type: DifficultyAdjustmentType.aiBehavior,
      previousValue: 0.5,
      newValue: settings.aiDifficulty,
      reason: 'Skill level: ${skillLevel.name}',
      timestamp: DateTime.now(),
    );

    _adjustmentEvents.add(event);
    _adjustmentController.add(event);

    debugPrint('[DynamicDifficulty] Adjusted for: ${skillLevel.name}');
  }

  /// 목표 계수
  Map<String, dynamic> _getTargetMultipliers(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return {
          'enemy_health': {'default': 0.7},
          'enemy_damage': {'default': 0.7},
          'player_buff': {'default': 1.2},
          'time_limit': 1.5,
          'ai_difficulty': 0.2,
          'reward': 0.8,
        };

      case SkillLevel.novice:
        return {
          'enemy_health': {'default': 0.85},
          'enemy_damage': {'default': 0.85},
          'player_buff': {'default': 1.1},
          'time_limit': 1.3,
          'ai_difficulty': 0.3,
          'reward': 0.9,
        };

      case SkillLevel.intermediate:
        return {
          'enemy_health': {'default': 1.0},
          'enemy_damage': {'default': 1.0},
          'player_buff': {'default': 1.0},
          'time_limit': 1.0,
          'ai_difficulty': 0.5,
          'reward': 1.0,
        };

      case SkillLevel.advanced:
        return {
          'enemy_health': {'default': 1.2},
          'enemy_damage': {'default': 1.15},
          'player_buff': {'default': 0.95},
          'time_limit': 0.9,
          'ai_difficulty': 0.7,
          'reward': 1.2,
        };

      case SkillLevel.expert:
        return {
          'enemy_health': {'default': 1.5},
          'enemy_damage': {'default': 1.3},
          'player_buff': {'default': 0.9},
          'time_limit': 0.8,
          'ai_difficulty': 0.9,
          'reward': 1.5,
        };
    }
  }

  /// 난이도 증가
  void _increaseDifficulty(String reason) {
    for (final factor in _factors.values.toList()) {
      final newValue = (factor.currentValue + factor.adjustmentSpeed)
          .clamp(factor.minValue, factor.maxValue);

      _factors[factor.name] = DifficultyFactor(
        name: factor.name,
        currentValue: newValue,
        minValue: factor.minValue,
        maxValue: factor.maxValue,
        adjustmentSpeed: factor.adjustmentSpeed,
      );

      final event = DifficultyAdjustmentEvent(
        id: 'adjust_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentUserId ?? '',
        type: DifficultyAdjustmentType.aiBehavior,
        previousValue: factor.currentValue,
        newValue: newValue,
        reason: reason,
        timestamp: DateTime.now(),
      );

      _adjustmentEvents.add(event);
      _adjustmentController.add(event);
    }

    debugPrint('[DynamicDifficulty] Difficulty increased: $reason');
  }

  /// 난이도 감소
  void _decreaseDifficulty(String reason) {
    for (final factor in _factors.values.toList()) {
      final newValue = (factor.currentValue - factor.adjustmentSpeed)
          .clamp(factor.minValue, factor.maxValue);

      _factors[factor.name] = DifficultyFactor(
        name: factor.name,
        currentValue: newValue,
        minValue: factor.minValue,
        maxValue: factor.maxValue,
        adjustmentSpeed: factor.adjustmentSpeed,
      );

      final event = DifficultyAdjustmentEvent(
        id: 'adjust_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentUserId ?? '',
        type: DifficultyAdjustmentType.aiBehavior,
        previousValue: factor.currentValue,
        newValue: newValue,
        reason: reason,
        timestamp: DateTime.now(),
      );

      _adjustmentEvents.add(event);
      _adjustmentController.add(event);
    }

    debugPrint('[DynamicDifficulty] Difficulty decreased: $reason');
  }

  /// 세션 난이도 설정 조회
  DifficultySettings? getSessionSettings(String sessionId) {
    return _activeSettings[sessionId];
  }

  /// 실시간 난이도 계수
  Map<String, double> getCurrentFactors() {
    return _factors.map((key, factor) => MapEntry(key, factor.currentValue));
  }

  /// 플레이어 실력 레벨 조회
  SkillLevel? getPlayerSkillLevel(String userId) {
    final performances = _performanceHistory.values
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (performances.isEmpty) return null;

    final recent = performances.take(10).toList();
    final avgScore = recent
        .map((p) => p.overallScore)
        .reduce((a, b) => a + b) / recent.length;

    if (avgScore >= 0.9) return SkillLevel.expert;
    if (avgScore >= 0.7) return SkillLevel.advanced;
    if (avgScore >= 0.5) return SkillLevel.intermediate;
    if (avgScore >= 0.3) return SkillLevel.novice;
    return SkillLevel.beginner;
  }

  /// 난이도 프리셋 적용
  Future<DifficultySettings> applyPreset({
    required String sessionId,
    required SkillLevel skillLevel,
  }) async {
    final targetMultipliers = _getTargetMultipliers(skillLevel);

    final settings = DifficultySettings(
      enemyHealthMultipliers: targetMultipliers['enemy_health'] ?? {},
      enemyDamageMultipliers: targetMultipliers['enemy_damage'] ?? {},
      playerBuffMultipliers: targetMultipliers['player_buff'] ?? {},
      timeLimitMultiplier: targetMultipliers['time_limit'] ?? 1.0,
      rewardMultiplier: targetMultipliers['reward'] ?? 1.0,
      aiDifficulty: targetMultipliers['ai_difficulty'] ?? 0.5,
      appliedAt: DateTime.now(),
    );

    _activeSettings[sessionId] = settings;
    _settingsController.add(settings);

    debugPrint('[DynamicDifficulty] Preset applied: ${skillLevel.name}');

    return settings;
  }

  /// 맞춤형 난이도 계산
  Future<Map<String, dynamic>> calculatePersonalizedDifficulty({
    required String userId,
    required String contentId,
  }) async {
    final skillLevel = getPlayerSkillLevel(userId);
    if (skillLevel == null) return {};

    final multipliers = _getTargetMultipliers(skillLevel);

    return {
      'userId': userId,
      'contentId': contentId,
      'skillLevel': skillLevel.name,
      'enemyHealthMultiplier': multipliers['enemy_health'],
      'enemyDamageMultiplier': multipliers['enemy_damage'],
      'playerBuffMultiplier': multipliers['player_buff'],
      'timeLimitMultiplier': multipliers['time_limit'],
      'aiDifficulty': multipliers['ai_difficulty'],
      'recommended': true,
    };
  }

  /// 난이도 조정 이력
  List<DifficultyAdjustmentEvent> getAdjustmentHistory({
    String? sessionId,
    int limit = 50,
  }) {
    var events = _adjustmentEvents.toList();

    if (sessionId != null) {
      events = events.where((e) => e.sessionId == sessionId).toList();
    }

    return events.take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final avgSkillLevel = _performanceHistory.values.isEmpty
        ? 0.0
        : _performanceHistory.values
                .map((p) => p.overallScore)
                .reduce((a, b) => a + b) / _performanceHistory.values.length;

    final skillDistribution = <SkillLevel, int>{};
    for (final level in SkillLevel.values) {
      skillDistribution[level] = _performanceHistory.values
          .where((p) => p.skillLevel == level)
          .length;
    }

    return {
      'totalSessions': _performanceHistory.length,
      'averageSkillScore': avgSkillLevel,
      'skillDistribution': skillDistribution.map((k, v) => MapEntry(k.name, v)),
      'totalAdjustments': _adjustmentEvents.length,
      'currentDifficulty': _factors['enemy_health']?.currentValue ?? 1.0,
    };
  }

  void dispose() {
    _performanceController.close();
    _settingsController.close();
    _adjustmentController.close();
    _monitorTimer?.cancel();
  }
}

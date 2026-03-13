import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 리더보드 타입
enum LeaderboardType {
  global,
  friends,
  guild,
  weekly,
  monthly,
  allTime,
}

/// 업적 상태
enum AchievementStatus {
  locked,
  unlocked,
  inProgress,
}

/// 리더보드 엔트리
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int score;
  final int rank;
  final Map<String, dynamic>? stats;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.score,
    required this.rank,
    this.stats,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'score': score,
        'rank': rank,
        'stats': stats,
      };
}

/// 업적
class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final int reward;
  final String rewardType;
  final AchievementStatus status;
  final double progress;
  final double maxProgress;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.reward,
    required this.rewardType,
    required this.status,
    this.progress = 0.0,
    this.maxProgress = 100.0,
    this.unlockedAt,
  });

  /// 진행률
  double get progressPercent => maxProgress > 0 ? progress / maxProgress : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'reward': reward,
        'rewardType': rewardType,
        'status': status.name,
        'progress': progress,
        'maxProgress': maxProgress,
        'unlockedAt': unlockedAt?.toIso8601String(),
    };
}

/// 도전 과제
class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int targetScore;
  final int? reward;
  final List<ChallengeReward> rewards;
  final bool isActive;
  final bool isCompleted;
  final double progress;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.targetScore,
    this.reward,
    required this.rewards,
    required this.isActive,
    required this.isCompleted,
    this.progress = 0.0,
  });
}

/// 도전 과제 보상
class ChallengeReward {
  final String type;
  final int amount;
  final String? itemId;

  const ChallengeReward({
    required this.type,
    required this.amount,
    this.itemId,
  });
}

/// 리더보드 관리자
class LeaderboardManager {
  static final LeaderboardManager _instance = LeaderboardManager._();
  static LeaderboardManager get instance => _instance;

  LeaderboardManager._();

  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  final Map<String, Achievement> _achievements = {};
  final Map<String, Challenge> _challenges = {};

  final StreamController<List<LeaderboardEntry>> _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();
  final StreamController<Achievement> _achievementController =
      StreamController<Achievement>.broadcast();
  final StreamController<Challenge> _challengeController =
      StreamController<Challenge>.broadcast();

  Stream<List<LeaderboardEntry>> get onLeaderboardUpdate =>
      _leaderboardController.stream;
  Stream<Achievement> get onAchievementUnlock => _achievementController.stream;
  Stream<Challenge> get onChallengeUpdate => _challengeController.stream;

  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// 초기화
  Future<void> initialize() async {
    // 업적 로드
    _loadAchievements();

    // 도전 과제 로드
    _loadChallenges();

    // 리더보드 로드
    _loadLeaderboards();

    debugPrint('[Leaderboard] Initialized');
  }

  void _loadAchievements() {
    _achievements.addAll({
      'first_win': Achievement(
        id: 'first_win',
        name: '첫 승리',
        description: '첫 번째 승리 기록',
        reward: 100,
        rewardType: 'gold',
        status: AchievementStatus.locked,
        maxProgress: 1.0,
      ),
      'win_streak_10': Achievement(
        id: 'win_streak_10',
        name: '10연승',
        description: '10연승 달성',
        reward: 500,
        rewardType: 'gold',
        status: AchievementStatus.locked,
        maxProgress: 10.0,
      ),
      'play_100_games': Achievement(
        id: 'play_100_games',
        name: '베테랑',
        description: '100게임 플레이',
        reward: 1000,
        rewardType: 'gold',
        status: AchievementStatus.locked,
        maxProgress: 100.0,
      ),
      'max_level': Achievement(
        id: 'max_level',
        name: '최고 레벨',
        description: '레벨 100 달성',
        reward: 2000,
        rewardType: 'gold',
        status: AchievementStatus.locked,
        maxProgress: 100.0,
      ),
      'social_butterfly': Achievement(
        id: 'social_butterfly',
        name: '소셜 버터플라이',
        description: '친구 100명 추가',
        reward: 500,
        rewardType: 'gold',
        status: AchievementStatus.locked,
        maxProgress: 100.0,
      ),
    });
  }

  void _loadChallenges() {
    final now = DateTime.now();

    _challenges.addAll({
      'daily_01': Challenge(
        id: 'daily_01',
        title: '일일 도전: 5승',
        description: '오늘 5번 승리하세요',
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        targetScore: 5,
        rewards: const [
          ChallengeReward(type: 'gold', amount: 100),
          ChallengeReward(type: 'exp', amount: 50),
        ],
        isActive: true,
        isCompleted: false,
      ),
      'weekly_01': Challenge(
        id: 'weekly_01',
        title: '주간 도전: 50게임',
        description: '이번 주 50게임 플레이',
        startTime: now,
        endTime: now.add(const Duration(days: 7)),
        targetScore: 50,
        rewards: const [
          ChallengeReward(type: 'gold', amount: 1000),
          ChallengeReward(type: 'item', amount: 1, itemId: 'rare_box'),
        ],
        isActive: true,
        isCompleted: false,
      ),
    });
  }

  void _loadLeaderboards() {
    // 샘플 리더보드 데이터
    _leaderboards['global'] = List.generate(
      100,
      (index) => LeaderboardEntry(
        userId: 'user_$index',
        username: 'Player${index + 1}',
        score: 10000 - (index * 100),
        rank: index + 1,
        stats: {
          'wins': 100 - index,
          'losses': index,
        },
      ),
    );
  }

  /// 리더보드 조회
  List<LeaderboardEntry> getLeaderboard({
    required LeaderboardType type,
    String? guildId,
    int limit = 100,
  }) {
    String key = type.name;

    if (type == LeaderboardType.guild && guildId != null) {
      key = '${type.name}_$guildId';
    }

    final leaderboard = _leaderboards[key];

    if (leaderboard == null) {
      // 기본 글로벌 리더보드 반환
      return _leaderboards['global']?.take(limit).toList() ?? [];
    }

    return leaderboard.take(limit).toList();
  }

  /// 내 순위 조회
  LeaderboardEntry? getMyRank(LeaderboardType type) {
    if (_currentUserId == null) return null;

    final leaderboard = getLeaderboard(type: type);

    try {
      return leaderboard.firstWhere((e) => e.userId == _currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// 점수 업데이트
  Future<void> updateScore({
    required LeaderboardType type,
    required int score,
    Map<String, dynamic>? stats,
  }) async {
    if (_currentUserId == null) return;

    final key = type.name;
    final leaderboard = _leaderboards.putIfAbsent(key, () => []);

    // 기존 엔트리 찾기
    final index = leaderboard.indexWhere((e) => e.userId == _currentUserId);

    if (index != -1) {
      // 기존 엔트리 업데이트
      final existing = leaderboard[index];
      leaderboard[index] = LeaderboardEntry(
        userId: existing.userId,
        username: existing.username,
        avatarUrl: existing.avatarUrl,
        score: score,
        rank: 0, // 순위 재계산 필요
        stats: stats,
      );
    } else {
      // 새 엔트리 추가
      leaderboard.add(LeaderboardEntry(
        userId: _currentUserId!,
        username: '현재 사용자',
        score: score,
        rank: 0,
        stats: stats,
      ));
    }

    // 순위 재계산
    leaderboard.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < leaderboard.length; i++) {
      // 순위 업데이트 (불변 객체라 실제로는 별도 처리 필요)
    }

    _leaderboardController.add(leaderboard);

    debugPrint('[Leaderboard] Score updated: $score for $type');
  }

  /// 업적 목록 조회
  List<Achievement> getAchievements({AchievementStatus? status}) {
    var achievements = _achievements.values.toList();

    if (status != null) {
      achievements = achievements.where((a) => a.status == status).toList();
    }

    return achievements;
  }

  /// 업적 진행 업데이트
  Future<void> updateAchievementProgress({
    required String achievementId,
    required double progress,
  }) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return;

    final newProgress = (achievement.progress + progress).clamp(0.0, achievement.maxProgress);

    if (newProgress >= achievement.maxProgress && achievement.status != AchievementStatus.unlocked) {
      // 업적 해제
      await _unlockAchievement(achievementId);
    } else {
      // 진행률 업데이트 (불변 객체라 실제로는 별도 처리 필요)
      debugPrint('[Achievement] Progress: $achievementId - ${newProgress.toInt()}');
    }
  }

  /// 업적 해제
  Future<void> _unlockAchievement(String achievementId) async {
    final achievement = _achievements[achievementId];
    if (achievement == null) return;

    final unlocked = Achievement(
      id: achievement.id,
      name: achievement.name,
      description: achievement.description,
      iconUrl: achievement.iconUrl,
      reward: achievement.reward,
      rewardType: achievement.rewardType,
      status: AchievementStatus.unlocked,
      progress: achievement.maxProgress,
      maxProgress: achievement.maxProgress,
      unlockedAt: DateTime.now(),
    );

    _achievements[achievementId] = unlocked;
    _achievementController.add(unlocked);

    // 보상 지급
    await _grantReward(achievement.rewardType, achievement.reward);

    debugPrint('[Achievement] Unlocked: ${achievement.name}');
  }

  Future<void> _grantReward(String type, int amount) async {
    // 실제 보상 지급 로직
    debugPrint('[Achievement] Reward granted: $type $amount');
  }

  /// 도전 과제 목록 조회
  List<Challenge> getChallenges({bool? isActive}) {
    var challenges = _challenges.values.toList();

    // 만료된 도전 과제 필터링
    final now = DateTime.now();
    challenges = challenges.where((c) => c.endTime.isAfter(now)).toList();

    if (isActive != null) {
      challenges = challenges.where((c) => c.isActive == isActive).toList();
    }

    return challenges;
  }

  /// 도전 과제 진행 업데이트
  Future<void> updateChallengeProgress({
    required String challengeId,
    required double progress,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) return;

    final newProgress = (challenge.progress + progress).clamp(0.0, challenge.targetScore.toDouble());

    if (newProgress >= challenge.targetScore && !challenge.isCompleted) {
      // 도전 과제 완료
      await _completeChallenge(challengeId);
    } else {
      // 진행률 업데이트 (불변 객체라 실제로는 별도 처리 필요)
      debugPrint('[Challenge] Progress: $challengeId - ${newProgress.toInt()}/${challenge.targetScore}');
    }
  }

  /// 도전 과제 완료
  Future<void> _completeChallenge(String challengeId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || challenge.isCompleted) return;

    final completed = Challenge(
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      startTime: challenge.startTime,
      endTime: challenge.endTime,
      targetScore: challenge.targetScore,
      reward: challenge.reward,
      rewards: challenge.rewards,
      isActive: challenge.isActive,
      isCompleted: true,
      progress: challenge.targetScore.toDouble(),
    );

    _challenges[challengeId] = completed;
    _challengeController.add(completed);

    // 보상 지급
    for (final reward in challenge.rewards) {
      await _grantReward(reward.type, reward.amount);
    }

    debugPrint('[Challenge] Completed: ${challenge.title}');
  }

  /// 탑 플레이어 조회
  List<LeaderboardEntry> getTopPlayers({int count = 10}) {
    return _leaderboards['global']?.take(count).toList() ?? [];
  }

  /// 친구 리더보드
  List<LeaderboardEntry> getFriendsLeaderboard(List<String> friendIds) {
    final global = _leaderboards['global'] ?? [];

    return global.where((e) => friendIds.contains(e.userId)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  void dispose() {
    _leaderboardController.close();
    _achievementController.close();
    _challengeController.close();
  }
}

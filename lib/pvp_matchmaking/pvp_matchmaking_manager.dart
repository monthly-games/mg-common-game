import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 매치모딩 타입
enum MatchType {
  ranked,       // 랭크
  casual,       // 캐주얼
  friendly,     // 친선
  tournament,   // 토너먼트
}

/// 리그 티어
enum LeagueTier {
  bronze,       // 브론즈
  silver,       // 실버
  gold,         // 골드
  platinum,     // 플래티넘
  diamond,      // 다이아몬드
  master,       // 마스터
  grandmaster,  // 그랜드마스터,
  challenger,   // 챌린저
}

/// 티어 구간
enum TierDivision {
  iv,           // 4단계
  iii,          // 3단계
  ii,           // 2단계
  i,            // 1단계
}

/// TrueSkill 등급
class TrueSkillRating {
  final double mu;        // 평균 (μ)
  final double sigma;     // 표준편차 (σ)
  final double beta;      // 동적 요인
  final double tau;       // 드래프 요인
  final double drawProbability; // 무승부 확률

  const TrueSkillRating({
    required this.mu,
    required this.sigma,
    this.beta = 1.0,
    this.tau = 0.08,
    this.drawProbability = 0.1,
  });

  /// 보수 점수
  double get conservativeRating => mu - 3 * sigma;

  TrueSkillRating copyWith({
    double? mu,
    double? sigma,
    double? beta,
    double? tau,
    double? drawProbability,
  }) {
    return TrueSkillRating(
      mu: mu ?? this.mu,
      sigma: sigma ?? this.sigma,
      beta: beta ?? this.beta,
      tau: tau ?? this.tau,
      drawProbability: drawProbability ?? this.drawProbability,
    );
  }
}

/// MMR 기록
class MatchHistory {
  final String matchId;
  final DateTime timestamp;
  final String opponentId;
  final bool isWin;
  final int mmrChange;
  final MatchType type;
  final int? streakCount;

  const MatchHistory({
    required this.matchId,
    required this.timestamp,
    required this.opponentId,
    required this.isWin,
    required this.mmrChange,
    required this.type,
    this.streakCount,
  });
}

/// 플레이어 등급
class PlayerRating {
  final String userId;
  final LeagueTier tier;
  final TierDivision division;
  final int leaguePoints;
  final TrueSkillRating trueSkill;
  final int wins;
  final int losses;
  final int? winningStreak;
  final int? losingStreak;
  final DateTime lastPlayed;

  const PlayerRating({
    required this.userId,
    required this.tier,
    required this.division,
    required this.leaguePoints,
    required this.trueSkill,
    required this.wins,
    required this.losses,
    this.winningStreak,
    this.losingStreak,
    required this.lastPlayed,
  });

  /// 승률
  double get winRate => wins + losses > 0 ? wins / (wins + losses) : 0.0;

  /// 티어 포인트 (0-100)
  int get tierPoints => leaguePoints.clamp(0, 100);

  /// 다음 티어로 승격 가능 여부
  bool get canPromote => tierPoints >= 100 && division != TierDivision.i;

  /// 강등 위험 여부
  bool get atRiskOfDemotion => tierPoints <= 0 && division != TierDivision.iv;
}

/// 매치 후보
class MatchCandidate {
  final String userId;
  final String username;
  final PlayerRating rating;
  final int ping;
  final bool isAvailable;

  const MatchCandidate({
    required this.userId,
    required this.username,
    required this.rating,
    required this.ping,
    required this.isAvailable,
  });
}

/// 매치
class Match {
  final String id;
  final MatchType type;
  final List<MatchCandidate> team1;
  final List<MatchCandidate> team2;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Map<String, int>? results;

  const Match({
    required this.id,
    required this.type,
    required this.team1,
    required this.team2,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.results,
  });

  /// 매치 완료 여부
  bool get isCompleted => endedAt != null;

  /// 예상 승률
  double getPredictedWinRate(String userId) {
    final userRating = [...team1, ...team2]
        .firstWhere((c) => c.userId == userId)
        .rating;

    final opponentRatings = [...team1, ...team2]
        .where((c) => c.userId != userId)
        .map((c) => c.rating.trueSkill.mu)
        .toList();

    if (opponentRatings.isEmpty) return 0.5;

    final avgOpponentRating = opponentRatings.reduce((a, b) => a + b) / opponentRatings.length;

    // 로지스틱 함수로 예상 승률 계산
    final diff = userRating.trueSkill.mu - avgOpponentRating;
    return 1.0 / (1.0 + exp(-diff / 100.0));
  }
}

/// 매칭 대기열
class MatchmakingQueue {
  final String userId;
  final MatchType type;
  final DateTime joinedAt;
  final int? minRating;
  final int? maxRating;

  const MatchmakingQueue({
    required this.userId,
    required this.type,
    required this.joinedAt,
    this.minRating,
    this.maxRating,
  });

  /// 대기 시간
  Duration get waitTime => DateTime.now().difference(joinedAt);
}

/// PvP 매치메이킹 관리자
class PvPMatchmakingManager {
  static final PvPMatchmakingManager _instance = PvPMatchmakingManager._();
  static PvPMatchmakingManager get instance => _instance;

  PvPMatchmakingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, PlayerRating> _playerRatings = {};
  final Map<String, List<MatchHistory>> _matchHistory = {};
  final List<MatchmakingQueue> _queues = [];
  final List<Match> _matches = [];

  final StreamController<Match> _matchController =
      StreamController<Match>.broadcast();
  final StreamController<PlayerRating> _ratingController =
      StreamController<PlayerRating>.broadcast();

  Stream<Match> get onMatchFound => _matchController.stream;
  Stream<PlayerRating> get onRatingUpdate => _ratingController.stream;

  Timer? _matchmakingTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 플레이어 등급 로드
    await _loadPlayerRatings();

    // 매칭 타이머 시작
    _startMatchmaking();

    debugPrint('[PvPMatchmaking] Initialized');
  }

  Future<void> _loadPlayerRatings() async {
    if (_currentUserId != null) {
      _playerRatings[_currentUserId!] = PlayerRating(
        userId: _currentUserId!,
        tier: LeagueTier.silver,
        division: TierDivision.ii,
        leaguePoints: 50,
        trueSkill: const TrueSkillRating(
          mu: 25.0,
          sigma: 8.33,
        ),
        wins: 50,
        losses: 40,
        winningStreak: 3,
        lastPlayed: DateTime.now(),
      );
    }
  }

  void _startMatchmaking() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _processMatchmaking();
    });
  }

  /// 큐에 입장
  Future<void> joinQueue({
    required String userId,
    required MatchType type,
    int? minRating,
    int? maxRating,
  }) async {
    final existing = _queues.indexWhere((q) => q.userId == userId);
    if (existing != -1) {
      _queues.removeAt(existing);
    }

    final queue = MatchmakingQueue(
      userId: userId,
      type: type,
      joinedAt: DateTime.now(),
      minRating: minRating,
      maxRating: maxRating,
    );

    _queues.add(queue);

    debugPrint('[PvPMatchmaking] Joined queue: $userId - ${type.name}');
  }

  /// 큐에서 퇴장
  Future<void> leaveQueue(String userId) async {
    _queues.removeWhere((q) => q.userId == userId);
    debugPrint('[PvPMatchmaking] Left queue: $userId');
  }

  /// 매칭 처리
  void _processMatchmaking() {
    if (_queues.length < 2) return;

    // 타입별로 분리
    final queuesByType = <MatchType, List<MatchmakingQueue>>{};
    for (final queue in _queues) {
      queuesByType.putIfAbsent(queue.type, () => []).add(queue);
    }

    // 각 타입별로 매칭 시도
    for (final entry in queuesByType.entries) {
      final type = entry.key;
      final queues = entry.value;

      if (queues.length >= 2) {
        // 적절한 상대 찾기
        final candidates = _findMatchCandidates(queues);

        if (candidates != null) {
          _createMatch(type, candidates);

          // 큐에서 제거
          _queues.removeWhere((q) =>
              candidates.any((c) => c.userId == q.userId));
        }
      }
    }
  }

  List<MatchmakingQueue>? _findMatchCandidates(List<MatchmakingQueue> queues) {
    if (queues.length < 2) return null;

    // MMR 기반 매칭
    final sorted = queues.toList()
      ..sort((a, b) {
        final ratingA = _playerRatings[a.userId]?.trueSkill.mu ?? 0.0;
        final ratingB = _playerRatings[b.userId]?.trueSkill.mu ?? 0.0;
        return ratingA.compareTo(ratingB);
      });

    // 가장 가까운 등급의 2명 선택
    for (int i = 0; i < sorted.length - 1; i++) {
      final queue1 = sorted[i];
      final queue2 = sorted[i + 1];

      final rating1 = _playerRatings[queue1.userId];
      final rating2 = _playerRatings[queue2.userId];

      if (rating1 == null || rating2 == null) continue;

      // 등급 차이 체크
      final ratingDiff = (rating1.trueSkill.mu - rating2.trueSkill.mu).abs();

      if (ratingDiff <= 200.0) { // 200 이하면 매칭
        return [queue1, queue2];
      }
    }

    return null;
  }

  void _createMatch(MatchType type, List<MatchmakingQueue> queues) {
    final candidates = queues.map((q) => MatchCandidate(
      userId: q.userId,
      username: 'Player ${q.userId}',
      rating: _playerRatings[q.userId]!,
      ping: 50 + Random().nextInt(100),
      isAvailable: true,
    )).toList();

    // 팀 분배
    final team1 = [candidates[0]];
    final team2 = [candidates[1]];

    final match = Match(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      team1: team1,
      team2: team2,
      createdAt: DateTime.now(),
    );

    _matches.add(match);
    _matchController.add(match);

    debugPrint('[PvPMatchmaking] Match created: ${match.id}');
  }

  /// 매치 결과 처리
  Future<void> processMatchResult({
    required String matchId,
    required Map<String, bool> results, // userId -> isWin
    required MatchType type,
  }) async {
    final matchIndex = _matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return;

    final match = _matches[matchIndex];

    // 각 플레이어의 등급 업데이트
    for (final entry in results.entries) {
      final userId = entry.key;
      final isWin = entry.value;

      await _updateRating(userId, isWin, type);
    }

    // 매치 완료 표시
    final updated = Match(
      id: match.id,
      type: match.type,
      team1: match.team1,
      team2: match.team2,
      createdAt: match.createdAt,
      startedAt: match.startedAt,
      endedAt: DateTime.now(),
      results: results,
    );

    _matches[matchIndex] = updated;
    _matchController.add(updated);

    debugPrint('[PvPMatchmaking] Match result processed: $matchId');
  }

  /// 등급 업데이트 (TrueSkill)
  Future<void> _updateRating(
    String userId,
    bool isWin,
    MatchType type,
  ) async {
    final rating = _playerRatings[userId];
    if (rating == null) return;

    // TrueSkill 업데이트
    final newTrueSkill = _updateTrueSkill(rating.trueSkill, isWin);

    // 티어 포인트 업데이트
    int newLeaguePoints = rating.leaguePoints;
    LeagueTier newTier = rating.tier;
    TierDivision newDivision = rating.division;

    if (isWin) {
      newLeaguePoints += 20;

      // 승격 체크
      if (newLeaguePoints >= 100) {
        if (rating.division != TierDivision.i) {
          // 다음 구간으로
          final divisions = TierDivision.values;
          final currentIndex = divisions.indexOf(rating.division);
          newDivision = divisions[currentIndex - 1];
          newLeaguePoints = 0;
        } else {
          // 다음 티어로
          final tiers = LeagueTier.values;
          final currentTierIndex = tiers.indexOf(rating.tier);
          if (currentTierIndex < tiers.length - 1) {
            newTier = tiers[currentTierIndex + 1];
            newDivision = TierDivision.iv;
            newLeaguePoints = 0;
          }
        }
      }
    } else {
      newLeaguePoints -= 20;

      // 강등 체크
      if (newLeaguePoints <= 0) {
        if (rating.division != TierDivision.iv) {
          // 이전 구간으로
          final divisions = TierDivision.values;
          final currentIndex = divisions.indexOf(rating.division);
          newDivision = divisions[currentIndex + 1];
          newLeaguePoints = 60; // 보너스 포인트
        } else {
          // 이전 티어로
          final tiers = LeagueTier.values;
          final currentTierIndex = tiers.indexOf(rating.tier);
          if (currentTierIndex > 0) {
            newTier = tiers[currentTierIndex - 1];
            newDivision = TierDivision.iii;
            newLeaguePoints = 60;
          }
        }
      }
    }

    // 전적 업데이트
    final newWins = rating.wins + (isWin ? 1 : 0);
    final newLosses = rating.losses + (isWin ? 0 : 1);

    // 승/패 스트릭 업데이트
    int? newWinningStreak;
    int? newLosingStreak;

    if (isWin) {
      newWinningStreak = (rating.winningStreak ?? 0) + 1;
      newLosingStreak = null;
    } else {
      newLosingStreak = (rating.losingStreak ?? 0) + 1;
      newWinningStreak = null;
    }

    final updated = PlayerRating(
      userId: rating.userId,
      tier: newTier,
      division: newDivision,
      leaguePoints: newLeaguePoints,
      trueSkill: newTrueSkill,
      wins: newWins,
      losses: newLosses,
      winningStreak: newWinningStreak,
      losingStreak: newLosingStreak,
      lastPlayed: DateTime.now(),
    );

    _playerRatings[userId] = updated;
    _ratingController.add(updated);

    // 매치 기록 추가
    final history = MatchHistory(
      matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      opponentId: 'opponent', // 실제로는 상대 ID
      isWin: isWin,
      mmrChange: isWin ? 20 : -20,
      type: type,
      streakCount: isWin ? newWinningStreak : newLosingStreak,
    );

    _matchHistory.putIfAbsent(userId, () => []).add(history);

    debugPrint('[PvPMatchmaking] Rating updated: $userId - ${newTier.name} ${newDivision.name} ($newLeaguePoints LP)');
  }

  /// TrueSkill 업데이트
  TrueSkillRating _updateTrueSkill(TrueSkillRating rating, bool isWin) {
    // 간단한 TrueSkill 업데이트
    final outcome = isWin ? 1.0 : 0.0;
    final c = sqrt(pow(rating.sigma, 2) + pow(rating.beta, 2));

    final newMu = rating.mu + (pow(rating.sigma, 2) / c) * (outcome - rating.mu);

    final newSigma = sqrt(pow(rating.sigma, 2) * (1 - pow(rating.sigma, 2) / c));

    return rating.copyWith(mu: newMu, sigma: newSigma);
  }

  /// 리그 정보 조회
  Map<String, dynamic> getLeagueInfo(String userId) {
    final rating = _playerRatings[userId];
    if (rating == null) return {};

    return {
      'tier': rating.tier.name,
      'division': rating.division.name,
      'leaguePoints': rating.leaguePoints,
      'wins': rating.wins,
      'losses': rating.losses,
      'winRate': rating.winRate,
      'winningStreak': rating.winningStreak,
      'losingStreak': rating.losingStreak,
      'trueSkill': {
        'mu': rating.trueSkill.mu,
        'sigma': rating.trueSkill.sigma,
        'conservativeRating': rating.trueSkill.conservativeRating,
      },
    };
  }

  /// 리그 순위
  List<Map<String, dynamic>> getLeaderboard({LeagueTier? tier}) {
    var ratings = _playerRatings.values.toList();

    if (tier != null) {
      ratings = ratings.where((r) => r.tier == tier).toList();
    }

    // 보수 점수 기준 정렬
    ratings.sort((a, b) =>
        b.trueSkill.conservativeRating.compareTo(a.trueSkill.conservativeRating));

    return ratings.asMap().entries.map((entry) {
      final index = entry.key;
      final rating = entry.value;

      return {
        'rank': index + 1,
        'userId': rating.userId,
        'tier': rating.tier.name,
        'division': rating.division.name,
        'leaguePoints': rating.leaguePoints,
        'wins': rating.wins,
        'losses': rating.losses,
        'winRate': rating.winRate,
        'conservativeRating': rating.trueSkill.conservativeRating,
      };
    }).toList();
  }

  /// 플레이어 등급 조회
  PlayerRating? getPlayerRating(String userId) {
    return _playerRatings[userId];
  }

  /// 매치 기록 조회
  List<MatchHistory> getMatchHistory(String userId, {int limit = 10}) {
    return (_matchHistory[userId] ?? []).take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 현재 큐 상태
  Map<MatchType, int> getQueueStatus() {
    final status = <MatchType, int>{};

    for (final type in MatchType.values) {
      status[type] = _queues.where((q) => q.type == type).length;
    }

    return status;
  }

  void dispose() {
    _matchmakingTimer?.cancel();
    _matchController.close();
    _ratingController.close();
  }
}

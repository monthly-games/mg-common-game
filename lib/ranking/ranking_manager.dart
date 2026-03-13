import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 리그 티어
enum LeagueTier {
  bronze,         // 브론즈
  silver,         // 실버
  gold,           // 골드
  platinum,       // 플래티넘
  diamond,        // 다이아몬드
  master,         // 마스터
  grandmaster,    // 그랜드마스터
  champion,       // 챔피언
}

/// 랭킹 기간
enum RankingPeriod {
  daily,          // 일일
  weekly,         // 주간
  monthly,        // 월간
  seasonal,       // 시즌
  allTime,        // 전체
}

/// 랭킹 카테고리
enum RankingCategory {
  overall,        // 종합
  combat,         // 전투
  collection,     // 컬렉션
  social,         // 소셜
  achievement,    // 업적
}

/// 토너먼트 상태
enum TournamentStatus {
  upcoming,       // 예정
  registration,   // 접수 중
  inProgress,     // 진행 중
  completed,      // 완료
  cancelled,      // 취소
}

/// 토너먼트 타입
enum TournamentType {
  elimination,    // 토너먼트
  league,         // 리그
  roundRobin,     // 라운드 로빈
  swiss,          // 스위스
}

/// 랭킹 엔트리
class RankingEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatar;
  final int score;
  final LeagueTier tier;
  final int wins;
  final int losses;
  final double winRate;
  final int streak; // 연승/연패
  final Map<String, dynamic>? metadata;

  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.score,
    required this.tier,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.streak,
    this.metadata,
  });

  /// 포인트 계산
  double get points {
    var base = score.toDouble();
    final tierBonus = tier.index * 100;
    final winBonus = wins * 10;
    final streakBonus = streak > 0 ? streak.abs() * 5 : 0;
    return base + tierBonus + winBonus + streakBonus;
  }

  /// 리그 아이콘
  String get tierIcon {
    switch (tier) {
      case LeagueTier.bronze:
        return '🥉';
      case LeagueTier.silver:
        return '🥈';
      case LeagueTier.gold:
        return '🥇';
      case LeagueTier.platinum:
        return '💎';
      case LeagueTier.diamond:
        return '💠';
      case LeagueTier.master:
        return '👑';
      case LeagueTier.grandmaster:
        return '🏆';
      case LeagueTier.champion:
        return '⭐';
    }
  }
}

/// 플레이어 랭킹 데이터
class PlayerRankingData {
  final String userId;
  final LeagueTier currentTier;
  final int currentRank;
  final int points;
  final int tierPoints; // 현재 티어 포인트
  final int maxTierPoints; // 다음 티어까지 필요 포인트
  final int wins;
  final int losses;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastPlayedAt;
  final List<RankingHistory> history;

  const PlayerRankingData({
    required this.userId,
    required this.currentTier,
    required this.currentRank,
    required this.points,
    required this.tierPoints,
    required this.maxTierPoints,
    required this.wins,
    required this.losses,
    required this.currentStreak,
    required this.bestStreak,
    this.lastPlayedAt,
    required this.history,
  });

  /// 승률
  double get winRate {
    final total = wins + losses;
    if (total == 0) return 0.0;
    return wins / total;
  }

  /// 다음 티어까지 진행률
  double get tierProgress {
    if (maxTierPoints == 0) return 0.0;
    return tierPoints / maxTierPoints;
  }

  /// 티어 업 가능 여부
  bool get canTierUp => tierPoints >= maxTierPoints;
}

/// 랭킹 기록
class RankingHistory {
  final DateTime date;
  final LeagueTier tier;
  final int rank;
  final int points;

  const RankingHistory({
    required this.date,
    required this.tier,
    required this.rank,
    required this.points,
  });
}

/// 토너먼트
class Tournament {
  final String id;
  final String name;
  final String description;
  final TournamentType type;
  final TournamentStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final int maxParticipants;
  final int currentParticipants;
  final List<TournamentReward> rewards;
  final List<TournamentMatch> matches;
  final Map<String, dynamic> rules;
  final String? bannerImage;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.rewards,
    required this.matches,
    required this.rules,
    this.bannerImage,
  });

  /// 참가 가능 여부
  bool get canRegister {
    return status == TournamentStatus.registration &&
        currentParticipants < maxParticipants &&
        (registrationDeadline == null ||
         DateTime.now().isBefore(registrationDeadline!));
  }

  /// 진행 중 여부
  bool get isActive => status == TournamentStatus.inProgress;

  /// 남은 시간
  Duration? get timeUntilStart {
    if (DateTime.now().isAfter(startDate)) return null;
    return startDate.difference(DateTime.now());
  }
}

/// 토너먼트 보상
class TournamentReward {
  final int rank; // 1, 2, 3, or 0 for participation
  final List<RewardItem> items;
  final String? title;

  const TournamentReward({
    required this.rank,
    required this.items,
    this.title,
  });
}

class RewardItem {
  final String type;
  final String id;
  final String name;
  final int quantity;
  final int? rarity;

  const RewardItem({
    required this.type,
    required this.id,
    required this.name,
    required this.quantity,
    this.rarity,
  });
}

/// 토너먼트 매치
class TournamentMatch {
  final String id;
  final String? player1Id;
  final String? player2Id;
  final String? player1Name;
  final String? player2Name;
  final String? winnerId;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int? player1Score;
  final int? player2Score;
  final int round;

  const TournamentMatch({
    required this.id,
    this.player1Id,
    this.player2Id,
    this.player1Name,
    this.player2Name,
    this.winnerId,
    required this.status,
    this.scheduledTime,
    this.player1Score,
    this.player2Score,
    required this.round,
  });
}

enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

/// 랭킹 관리자
class RankingManager {
  static final RankingManager _instance = RankingManager._();
  static RankingManager get instance => _instance;

  RankingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  PlayerRankingData? _playerRanking;
  final List<RankingEntry> _rankings = [];
  final List<Tournament> _tournaments = [];

  final StreamController<PlayerRankingData> _rankingController =
      StreamController<PlayerRankingData>.broadcast();
  final StreamController<List<RankingEntry>> _leaderboardController =
      StreamController<List<RankingEntry>>.broadcast();
  final StreamController<Tournament> _tournamentController =
      StreamController<Tournament>.broadcast();

  Stream<PlayerRankingData> get onRankingUpdate => _rankingController.stream;
  Stream<List<RankingEntry>> get onLeaderboardUpdate => _leaderboardController.stream;
  Stream<Tournament> get onTournamentUpdate => _tournamentController.stream;

  Timer? _updateTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 랭킹 로드
    await _loadRankings();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    // 토너먼트 로드
    await _loadTournaments();

    // 업데이트 타이머 시작
    _startUpdateTimer();

    debugPrint('[Ranking] Initialized');
  }

  Future<void> _loadRankings() async {
    // 시뮬레이션 랭킹 데이터
    _rankings.clear();

    final tiers = LeagueTier.values;
    final names = [
      'ProGamer123', 'ShadowMaster', 'DragonSlayer', 'NightHawk',
      'StarPlayer', 'LegendKiller', 'ThunderBolt', 'IceQueen',
      'FireStorm', 'WindWalker', 'EarthShaker', 'LightStrike',
    ];

    for (var i = 0; i < 100; i++) {
      final tier = i < 10
          ? tiers[tiers.length - 1 - (i ~/ 3)]
          : tiers[(i ~/ 15).clamp(0, tiers.length - 1)];

      final wins = 50 + (99 - i) * 5;
      final losses = 30 + (99 - i) * 3;
      final winRate = wins / (wins + losses);

      _rankings.add(RankingEntry(
        rank: i + 1,
        userId: 'user_$i',
        username: names[i % names.length],
        avatar: 'assets/avatars/$i.png',
        score: 1000 - i * 10,
        tier: tier,
        wins: wins,
        losses: losses,
        winRate: winRate,
        streak: (i % 7) - 3,
      ));
    }
  }

  Future<void> _loadPlayerData(String userId) async {
    final json = _prefs?.getString('ranking_$userId');
    RankingHistory history = RankingHistory(
      date: DateTime.now(),
      tier: LeagueTier.bronze,
      rank: 100,
      points: 0,
    );

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Ranking] Error loading player data: $e');
      }
    }

    // 현재 플레이어 랭킹
    final playerEntry = _rankings.cast<RankingEntry?>().firstWhere(
      (e) => e?.userId == userId,
      orElse: () => null,
    );

    _playerRanking = PlayerRankingData(
      userId: userId,
      currentTier: playerEntry?.tier ?? LeagueTier.bronze,
      currentRank: playerEntry?.rank ?? 100,
      points: playerEntry?.score ?? 0,
      tierPoints: 500,
      maxTierPoints: 1000,
      wins: playerEntry?.wins ?? 0,
      losses: playerEntry?.losses ?? 0,
      currentStreak: playerEntry?.streak ?? 0,
      bestStreak: 5,
      history: [history],
    );
  }

  Future<void> _loadTournaments() async {
    _tournaments.clear();

    // 주간 토너먼트
    _tournaments.add(Tournament(
      id: 'weekly_1',
      name: '주간 챔피언십',
      description: '매주 열리는 챔피언십',
      type: TournamentType.elimination,
      status: TournamentStatus.registration,
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      registrationDeadline: DateTime.now().add(const Duration(days: 1)),
      maxParticipants: 64,
      currentParticipants: 32,
      rewards: const [
        TournamentReward(
          rank: 1,
          items: [
            RewardItem(
              type: 'currency',
              id: 'gems',
              name: '젬',
              quantity: 1000,
              rarity: 5,
            ),
          ],
          title: '우승',
        ),
        TournamentReward(
          rank: 2,
          items: [
            RewardItem(
              type: 'currency',
              id: 'gems',
              name: '젬',
              quantity: 500,
              rarity: 4,
            ),
          ],
          title: '준우승',
        ),
      ],
      matches: [],
      rules: {
        'format': 'single_elimination',
        'bestOf': 3,
      },
      bannerImage: 'assets/tournaments/weekly.png',
    ));

    // 시즌 토너먼트
    _tournaments.add(Tournament(
      id: 'season_1',
      name: '시즌 1 그랜드 파이널',
      description: '시즌 1의 최강자를 가립니다',
      type: TournamentType.league,
      status: TournamentStatus.upcoming,
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 37)),
      registrationDeadline: DateTime.now().add(const Duration(days: 25)),
      maxParticipants: 128,
      currentParticipants: 0,
      rewards: const [
        TournamentReward(
          rank: 1,
          items: [
            RewardItem(
              type: 'special',
              id: 'champion_title',
              name: '챔피언 칭호',
              quantity: 1,
              rarity: 5,
            ),
            RewardItem(
              type: 'currency',
              id: 'gems',
              name: '젬',
              quantity: 5000,
            ),
          ],
          title: '그랜드 챔피언',
        ),
      ],
      matches: [],
      rules: {
        'format': 'league',
        'rounds': 7,
      },
      bannerImage: 'assets/tournaments/season1.png',
    ));
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateRankings();
    });
  }

  void _updateRankings() {
    // 실제로는 서버에서 랭킹 업데이트
    _leaderboardController.add(_rankings);
  }

  /// 경기 결과 기록
  Future<void> recordMatchResult({
    required bool isWin,
    int? opponentRank,
  }) async {
    if (_playerRanking == null) return;

    // 포인트 계산
    var pointsChange = 0;
    if (isWin) {
      pointsChange = 20;
      if (opponentRank != null && opponentRank < _playerRanking!.currentRank) {
        pointsChange += 10; // 상위 플레이어 승리 보너스
      }
    } else {
      pointsChange = -10;
    }

    // 스트릭 업데이트
    final newStreak = isWin
        ? (_playerRanking!.currentStreak > 0
            ? _playerRanking!.currentStreak + 1
            : 1)
        : (_playerRanking!.currentStreak < 0
            ? _playerRanking!.currentStreak - 1
            : -1);

    // 승패 업데이트
    final newWins = isWin
        ? _playerRanking!.wins + 1
        : _playerRanking!.wins;
    final newLosses = !isWin
        ? _playerRanking!.losses + 1
        : _playerRanking!.losses;

    // 티어 포인트 업데이트
    var newTierPoints = _playerRanking!.tierPoints + pointsChange;
    var newTier = _playerRanking!.currentTier;
    var maxPoints = _playerRanking!.maxTierPoints;

    if (newTierPoints >= maxPoints && newTier.index < LeagueTier.champion.index) {
      // 티어 업
      newTier = LeagueTier.values[newTier.index + 1];
      newTierPoints = 0;
      maxPoints = 1000;

      debugPrint('[Ranking] Tier up: ${newTier.name}');
    } else if (newTierPoints < 0 && newTier.index > LeagueTier.bronze.index) {
      // 티어 다운
      newTier = LeagueTier.values[newTier.index - 1];
      newTierPoints = 500;
      maxPoints = 1000;

      debugPrint('[Ranking] Tier down: ${newTier.name}');
    }

    // 기록 추가
    final history = RankingHistory(
      date: DateTime.now(),
      tier: newTier,
      rank: _playerRanking!.currentRank,
      points: _playerRanking!.points + pointsChange,
    );

    final updated = PlayerRankingData(
      userId: _playerRanking!.userId,
      currentTier: newTier,
      currentRank: _playerRanking!.currentRank,
      points: _playerRanking!.points + pointsChange,
      tierPoints: newTierPoints.clamp(0, maxPoints),
      maxTierPoints: maxPoints,
      wins: newWins,
      losses: newLosses,
      currentStreak: newStreak,
      bestStreak: newStreak.abs() > _playerRanking!.bestStreak
          ? newStreak.abs()
          : _playerRanking!.bestStreak,
      lastPlayedAt: DateTime.now(),
      history: [..._playerRanking!.history, history],
    );

    _playerRanking = updated;
    _rankingController.add(updated);

    await _savePlayerData();

    debugPrint('[Ranking] Match recorded: ${isWin ? "Win" : "Loss"}, $pointsChange points');
  }

  /// 토너먼트 참가
  Future<bool> joinTournament(String tournamentId) async {
    final tournament = _tournaments.cast<Tournament?>().firstWhere(
      (t) => t?.id == tournamentId,
      orElse: () => null,
    );

    if (tournament == null) return false;
    if (!tournament.canRegister) return false;

    // 참가 처리
    final updated = Tournament(
      id: tournament.id,
      name: tournament.name,
      description: tournament.description,
      type: tournament.type,
      status: tournament.status,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      registrationDeadline: tournament.registrationDeadline,
      maxParticipants: tournament.maxParticipants,
      currentParticipants: tournament.currentParticipants + 1,
      rewards: tournament.rewards,
      matches: tournament.matches,
      rules: tournament.rules,
      bannerImage: tournament.bannerImage,
    );

    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    _tournaments[index] = updated;
    _tournamentController.add(updated);

    debugPrint('[Ranking] Joined tournament: ${tournament.name}');

    return true;
  }

  /// 리더보드 조회
  List<RankingEntry> getLeaderboard({
    RankingCategory? category,
    RankingPeriod? period,
    int? limit,
  }) {
    var leaderboard = _rankings.toList();

    // 카테고리 필터 (실제로는 다른 데이터)
    if (category != null && category != RankingCategory.overall) {
      // 필터링 로직
    }

    // 기간 필터 (실제로는 다른 데이터)
    if (period != null && period != RankingPeriod.allTime) {
      // 필터링 로직
    }

    if (limit != null) {
      leaderboard = leaderboard.take(limit).toList();
    }

    return leaderboard;
  }

  /// 내 랭킹
  RankingEntry? getMyRanking() {
    if (_currentUserId == null) return null;
    return _rankings.cast<RankingEntry?>().firstWhere(
      (e) => e?.userId == _currentUserId,
      orElse: () => null,
    );
  }

  /// 플레이어 랭킹 데이터
  PlayerRankingData? getPlayerRanking() {
    return _playerRanking;
  }

  /// 토너먼트 목록
  List<Tournament> getTournaments({TournamentStatus? status}) {
    var tournaments = _tournaments.toList();

    if (status != null) {
      tournaments = tournaments.where((t) => t.status == status).toList();
    }

    return tournaments..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// 토너먼트 조회
  Tournament? getTournament(String id) {
    return _tournaments.cast<Tournament?>().firstWhere(
      (t) => t?.id == id,
      orElse: () => null,
    );
  }

  /// 토너먼트 매치 업데이트
  Future<void> updateMatch({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    int? player1Score,
    int? player2Score,
  }) async {
    final tournament = _tournaments.cast<Tournament?>().firstWhere(
      (t) => t?.id == tournamentId,
      orElse: () => null,
    );

    if (tournament == null) return;

    final match = tournament.matches.cast<TournamentMatch?>().firstWhere(
      (m) => m?.id == matchId,
      orElse: () => null,
    );

    if (match == null) return;

    final updated = TournamentMatch(
      id: match.id,
      player1Id: match.player1Id,
      player2Id: match.player2Id,
      player1Name: match.player1Name,
      player2Name: match.player2Name,
      winnerId: winnerId,
      status: MatchStatus.completed,
      scheduledTime: match.scheduledTime,
      player1Score: player1Score,
      player2Score: player2Score,
      round: match.round,
    );

    // 매치 업데이트 로직
    debugPrint('[Ranking] Match updated: $matchId, Winner: $winnerId');
  }

  /// 시즌 보상
  Future<void> claimSeasonReward() async {
    if (_playerRanking == null) return;

    // 시즌 보상 지급
    final rank = _playerRanking!.currentRank;

    if (rank <= 10) {
      debugPrint('[Ranking] Season reward claimed: Rank $rank');
      // 보상 지급 로직
    }
  }

  /// 랭킹 검색
  List<RankingEntry> searchRankings(String query) {
    final lowerQuery = query.toLowerCase();
    return _rankings
        .where((e) => e.username.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerRanking == null) return;

    final data = {
      'currentTier': _playerRanking!.currentTier.name,
      'currentRank': _playerRanking!.currentRank,
      'points': _playerRanking!.points,
      'tierPoints': _playerRanking!.tierPoints,
      'wins': _playerRanking!.wins,
      'losses': _playerRanking!.losses,
      'currentStreak': _playerRanking!.currentStreak,
      'bestStreak': _playerRanking!.bestStreak,
    };

    await _prefs?.setString(
      'ranking_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _rankingController.close();
    _leaderboardController.close();
    _tournamentController.close();
    _updateTimer?.cancel();
  }
}

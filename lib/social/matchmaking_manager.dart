import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 매칭 모드
enum MatchMode {
  ranked,      // 랭크된 매칭
  casual,      // 캐주얼 매칭
  friendly,    // 친선 매칭
  tournament,  // 토너먼트
}

/// 플레이어 스킬 레벨
enum SkillLevel {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  challenger,
}

/// 매칭 티어
class MatchTier {
  final SkillLevel skillLevel;
  final int minRating;
  final int maxRating;
  final String name;
  final Color color;

  const MatchTier({
    required this.skillLevel,
    required this.minRating,
    required this.maxRating,
    required this.name,
    required this.color,
  });

  static const List<MatchTier> all = [
    MatchTier(
      skillLevel: SkillLevel.bronze,
      minRating: 0,
      maxRating: 1199,
      name: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    MatchTier(
      skillLevel: SkillLevel.silver,
      minRating: 1200,
      maxRating: 1599,
      name: 'Silver',
      color: Color(0xFFC0C0C0),
    ),
    MatchTier(
      skillLevel: SkillLevel.gold,
      minRating: 1600,
      maxRating: 1999,
      name: 'Gold',
      color: Color(0xFFFFD700),
    ),
    MatchTier(
      skillLevel: SkillLevel.platinum,
      minRating: 2000,
      maxRating: 2399,
      name: 'Platinum',
      color: Color(0xFFE5E4E2),
    ),
    MatchTier(
      skillLevel: SkillLevel.diamond,
      minRating: 2400,
      maxRating: 2799,
      name: 'Diamond',
      color: Color(0xFFB9F2FF),
    ),
    MatchTier(
      skillLevel: SkillLevel.master,
      minRating: 2800,
      maxRating: 3199,
      name: 'Master',
      color: Color(0xFFFF00FF),
    ),
    MatchTier(
      skillLevel: SkillLevel.challenger,
      minRating: 3200,
      maxRating: 99999,
      name: 'Challenger',
      color: Color(0xFF00FF00),
    ),
  ];

  /// 레이팅으로 티어 찾기
  static MatchTier? fromRating(int rating) {
    return all.firstWhere(
      (tier) => rating >= tier.minRating && rating <= tier.maxRating,
      orElse: () => all.first,
    );
  }
}

/// 매칭 요청
class MatchRequest {
  final String id;
  final String userId;
  final String gameId;
  final MatchMode mode;
  final int rating;
  final DateTime createdAt;
  final Duration timeout;

  const MatchRequest({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.mode,
    required this.rating,
    required this.createdAt,
    this.timeout = const Duration(minutes: 5),
  });

  bool get isExpired =>
    DateTime.now().difference(createdAt) > timeout;
}

/// 매칭 결과
class MatchResult {
  final String matchId;
  final List<String> team1;
  final List<String> team2;
  final DateTime createdAt;
  final MatchMode mode;
  final Map<String, dynamic> metadata;

  const MatchResult({
    required this.matchId,
    required this.team1,
    required this.team2,
    required this.createdAt,
    required this.mode,
    this.metadata = const {},
  });
}

/// 매치메이킹 매니저
class MatchmakingManager {
  static final MatchmakingManager _instance = MatchmakingManager._();
  static MatchmakingManager get instance => _instance;

  MatchmakingManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;

  final List<MatchRequest> _pendingRequests = [];
  final Map<String, MatchResult> _activeMatches = {};
  final Map<String, int> _playerRatings = {}; // userId -> rating

  final StreamController<MatchResult> _matchFoundController =
      StreamController<MatchResult>.broadcast();
  final StreamController<String> _matchCancelController =
      StreamController<String>.broadcast();

  Timer? _matchmakingTimer;
  static const Duration _matchmakingInterval = Duration(seconds: 5);

  // Getters
  Stream<MatchResult> get onMatchFound => _matchFoundController.stream;
  Stream<String> get onMatchCancel => _matchCancelController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 데이터 로드
    await _loadPlayerRatings();

    // 매치메이킹 시작
    _startMatchmaking();

    debugPrint('[Matchmaking] Initialized');
  }

  Future<void> _loadPlayerRatings() async {
    final ratingsJson = _prefs!.getString('player_ratings');
    if (ratingsJson != null) {
      final json = jsonDecode(ratingsJson) as Map<String, dynamic>;
      _playerRatings.addEntries(
        json.entries.map((e) => MapEntry(e.key, e.value as int))
      );
    }
  }

  void _startMatchmaking() {
    _matchmakingTimer?.cancel();

    _matchmakingTimer = Timer.periodic(_matchmakingInterval, (_) {
      _processMatchmaking();
    });
  }

  void _stopMatchmaking() {
    _matchmakingTimer?.cancel();
  }

  // ============================================
  // 매칭 요청
  // ============================================

  /// 매칭 요청
  Future<String> requestMatch({
    required String userId,
    required String gameId,
    required MatchMode mode,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final rating = _playerRatings[userId] ?? 1200;

    final request = MatchRequest(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      gameId: gameId,
      mode: mode,
      rating: rating,
      createdAt: DateTime.now(),
    );

    _pendingRequests.add(request);

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('match_requested', parameters: {
      'user_id': userId,
      'game_id': gameId,
      'mode': mode.name,
      'rating': rating,
    });

    debugPrint('[Matchmaking] Request: $userId (${mode.name})');
    return request.id;
  }

  /// 매칭 취소
  Future<void> cancelMatch(String requestId) async {
    _pendingRequests.removeWhere((r) => r.id == requestId);

    _matchCancelController.add(requestId);

    debugPrint('[Matchmaking] Cancelled: $requestId');
  }

  // ============================================
  // 매칭 처리
  // ============================================

  void _processMatchmaking() {
    // 만료된 요청 제거
    _pendingRequests.removeWhere((r) => r.isExpired);

    // 게임별/모드별로 그룹화
    final grouped = <String, List<MatchRequest>>{};

    for (final request in _pendingRequests) {
      final key = '${request.gameId}_${request.mode.name}';
      grouped.putIfAbsent(key, () => []).add(request);
    }

    // 각 그룹에서 매칭 시도
    for (final entry in grouped.entries) {
      final requests = entry.value;

      // 최소 2명 필요
      if (requests.length < 2) continue;

      // 유사한 레이팅끼리 매칭
      final matches = _findMatches(requests);

      for (final match in matches) {
        _createMatch(match);
      }
    }
  }

  /// 매칭 찾기
  List<List<MatchRequest>> _findMatches(List<MatchRequest> requests) {
    final matches = <List<MatchRequest>>[];
    final matched = <String>{};

    // 레이팅 기준 정렬
    final sorted = List<MatchRequest>.from(requests)
      ..sort((a, b) => a.rating.compareTo(b.rating));

    for (int i = 0; i < sorted.length; i++) {
      final request1 = sorted[i];

      if (matched.contains(request1.id)) continue;

      for (int j = i + 1; j < sorted.length; j++) {
        final request2 = sorted[j];

        if (matched.contains(request2.id)) continue;

        // 레이팅 차이 계산
        final ratingDiff = (request1.rating - request2.rating).abs();

        // 허용 가능한 레이팅 차이
        final maxDiff = _getMaxRatingDiff(request1.rating, request2.rating);

        if (ratingDiff <= maxDiff) {
          matches.add([request1, request2]);
          matched.add(request1.id);
          matched.add(request2.id);
          break;
        }
      }
    }

    return matches;
  }

  /// 허용 가능한 레이팅 차이 계산
  int _getMaxRatingDiff(int rating1, int rating2) {
    final avg = (rating1 + rating2) / 2;

    // 높은 레이팅일수록 더 넓은 범위 허용
    if (avg >= 2500) {
      return 500; // 마스터 이상
    } else if (avg >= 2000) {
      return 300; // 다이아몬드
    } else if (avg >= 1600) {
      return 200; // 플래티넘
    } else {
      return 150; // 골드 이하
    }
  }

  /// 매치 생성
  void _createMatch(List<MatchRequest> matchedRequests) {
    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';

    // 팀 배정
    final team1 = [matchedRequests[0].userId];
    final team2 = [matchedRequests[1].userId];

    final match = MatchResult(
      matchId: matchId,
      team1: team1,
      team2: team2,
      createdAt: DateTime.now(),
      mode: matchedRequests[0].mode,
      metadata: {
        'game_id': matchedRequests[0].gameId,
        'avg_rating': (matchedRequests[0].rating + matchedRequests[1].rating) / 2,
      },
    );

    _activeMatches[matchId] = match;

    // 대기열에서 제거
    for (final request in matchedRequests) {
      _pendingRequests.remove(request);
    }

    // 알림
    _matchFoundController.add(match);

    // 애널리틱스
    AnalyticsManager.instance.logEvent('match_found', parameters: {
      'match_id': matchId,
      'mode': match.mode.name,
    });

    debugPrint('[Matchmaking] Match found: $matchId');
  }

  // ============================================
  // 매치 결과
  // ============================================

  /// 매치 결과 보고
  Future<void> reportMatchResult({
    required String matchId,
    required String userId,
    required bool won,
    required int? opponentRating,
  }) async {
    final match = _activeMatches[matchId];
    if (match == null) return;

    final currentRating = _playerRatings[userId] ?? 1200;

    // ELO 점수 계산
    final newRating = _calculateNewRating(
      currentRating,
      won,
      opponentRating ?? currentRating,
    );

    _playerRatings[userId] = newRating;

    await _savePlayerRatings();

    // 티어 확인
    final oldTier = MatchTier.fromRating(currentRating);
    final newTier = MatchTier.fromRating(newRating);

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('match_completed', parameters: {
      'user_id': userId,
      'match_id': matchId,
      'won': won,
      'old_rating': currentRating,
      'new_rating': newRating,
      'old_tier': oldTier?.name,
      'new_tier': newTier?.name,
    });

    debugPrint('[Matchmaking] Result: $userId - ${won ? "WIN" : "LOSS"} ($currentRating -> $newRating)');
  }

  /// ELO 레이팅 계산
  int _calculateNewRating(int currentRating, bool won, int opponentRating) {
    const kFactor = 32;

    final expectedScore = 1 / (1 + pow(10, (opponentRating - currentRating) / 400));

    final actualScore = won ? 1 : 0;

    final newRating = (currentRating + kFactor * (actualScore - expectedScore)).round();

    return newRating.clamp(0, 9999);
  }

  // ============================================
  // 플레이어 정보
  // ============================================

  /// 플레이어 레이팅 가져오기
  int getPlayerRating(String userId) {
    return _playerRatings[userId] ?? 1200;
  }

  /// 플레이어 티어 가져오기
  MatchTier? getPlayerTier(String userId) {
    final rating = getPlayerRating(userId);
    return MatchTier.fromRating(rating);
  }

  /// 랭킹 정보
  Map<String, dynamic> getRankingInfo(String userId) {
    final rating = getPlayerRating(userId);
    final tier = MatchTier.fromRating(rating);
    final allRatings = _playerRatings.values.toList()..sort((a, b) => b.compareTo(a));
    final rank = allRatings.indexOf(rating) + 1;

    return {
      'rating': rating,
      'tier': tier?.name,
      'tier_color': tier?.color.value,
      'rank': rank,
      'total_players': _playerRatings.length,
      'percentile': (1 - rank / _playerRatings.length) * 100,
    };
  }

  /// 상위 N명 랭킹
  List<Map<String, dynamic>> getTopRankings({int limit = 100}) {
    final sorted = _playerRatings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((entry) {
      final tier = MatchTier.fromRating(entry.value);
      return {
        'user_id': entry.key,
        'rating': entry.value,
        'tier': tier?.name,
        'tier_color': tier?.color.value,
      };
    }).toList();
  }

  // ============================================
  // 저장/로드
  // ============================================

  Future<void> _savePlayerRatings() async {
    await _prefs!.setString('player_ratings', jsonEncode(_playerRatings));
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _stopMatchmaking();
    _matchFoundController.close();
    _matchCancelController.close();
  }

  bool get _isInitialized => _prefs != null;
}

/// 실시간 멀티플레이어 세션
class MultiplayerSession {
  final String sessionId;
  final List<String> players;
  final String gameId;
  final bool isHost;
  final DateTime createdAt;

  const MultiplayerSession({
    required this.sessionId,
    required this.players,
    required this.gameId,
    required this.isHost,
    required this.createdAt,
  });

  /// 세션 생성
  static Future<MultiplayerSession> create({
    required String hostId,
    required String gameId,
    int maxPlayers = 2,
  }) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    return MultiplayerSession(
      sessionId: sessionId,
      players: [hostId],
      gameId: gameId,
      isHost: true,
      createdAt: DateTime.now(),
    );
  }

  /// 플레이어 참여
  MultiplayerSession addPlayer(String playerId) {
    return MultiplayerSession(
      sessionId: sessionId,
      players: [...players, playerId],
      gameId: gameId,
      isHost: isHost,
      createdAt: createdAt,
    );
  }

  /// 세션 만료 확인
  bool get isExpired =>
    DateTime.now().difference(createdAt) > const Duration(minutes: 10);
}

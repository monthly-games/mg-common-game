import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 매칭 모드
enum MatchMode {
  quick,          // 빠른 매칭
  ranked,         // 랭크 매칭
  casual,         // 캐주얼
  custom,         // 커스텀
  tournament,     // 토너먼트
}

/// 매칭 타입
enum MatchType {
  solo,           // 솔로 (1v1)
  duo,            // 듀오 (2v2)
  squad,          // 스쿼드 (3v3)
  team,           // 팀 (5v5)
  raid,           // 레이드
}

/// 매칭 상태
enum MatchStatus {
  searching,      // 검색 중
  found,          // 매칭 찾음
  confirmed,      // 확정
  cancelled,      // 취소됨
  expired,        // 만료됨
  failed,         // 실패
}

/// 플레이어 스킬 레벨
enum SkillLevel {
  beginner,       // 초급
  novice,         // 중급
  intermediate,   // 중상급
  advanced,       // 고급
  expert,         // 전문가
  master,         // 마스터
}

/// 플레이어 정보
class MatchPlayer {
  final String playerId;
  final String username;
  final String? avatar;
  final int level;
  final SkillLevel skillLevel;
  final double elo; // ELO 점수
  final String? region; // 지역
  final String? partyId; // 파티 ID
  final Map<String, dynamic>? stats;
  final bool isReady; // 레디 확인

  const MatchPlayer({
    required this.playerId,
    required this.username,
    this.avatar,
    required this.level,
    required this.skillLevel,
    required this.elo,
    this.region,
    this.partyId,
    this.stats,
    this.isReady = false,
  });

  /// 매칭 점수 계산
  double get matchScore {
    var score = elo;
    if (skillLevel == SkillLevel.master) score += 500;
    if (skillLevel == SkillLevel.expert) score += 300;
    if (skillLevel == SkillLevel.advanced) score += 150;
    return score;
  }
}

/// 매칭 티켓
class MatchTicket {
  final String ticketId;
  final String playerId;
  final MatchMode mode;
  final MatchType type;
  final DateTime createdAt;
  final Duration? timeout;
  final List<MatchPreference> preferences;
  final int priority; // 우선순위

  const MatchTicket({
    required this.ticketId,
    required this.playerId,
    required this.mode,
    required this.type,
    required this.createdAt,
    this.timeout,
    required this.preferences,
    this.priority = 0,
  });

  /// 만료 여부
  bool get isExpired {
    if (timeout == null) return false;
    return DateTime.now().isAfter(createdAt.add(timeout!));
  }

  /// 대기 시간
  Duration get waitTime => DateTime.now().difference(createdAt);
}

/// 매칭 선호도
class MatchPreference {
  final String type; // map, mode, region, etc.
  final String? value;
  final bool isRequired;

  const MatchPreference({
    required this.type,
    this.value,
    this.isRequired = false,
  });
}

/// 매칭 결과
class MatchResult {
  final String matchId;
  final MatchMode mode;
  final MatchType type;
  final List<MatchPlayer> team1;
  final List<MatchPlayer> team2;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? serverId;
  final Map<String, dynamic>? metadata;

  const MatchResult({
    required this.matchId,
    required this.mode,
    required this.type,
    required this.team1,
    required this.team2,
    required this.createdAt,
    this.expiresAt,
    this.serverId,
    this.metadata,
  });

  /// 매칭 밸런스 점수
  double get balanceScore {
    final team1Score = team1.fold<double>(0, (sum, p) => sum + p.matchScore);
    final team2Score = team2.fold<double>(0, (sum, p) => sum + p.matchScore);
    final avg1 = team1Score / team1.length;
    final avg2 = team2Score / team2.length;
    return (avg1 - avg2).abs();
  }

  /// 공정 여부
  bool get isFair => balanceScore < 100;

  /// 전체 플레이어
  List<MatchPlayer> get allPlayers => [...team1, ...team2];
}

/// 매칭 풀
class MatchPool {
  final List<MatchTicket> tickets;
  final Map<String, MatchPlayer> players;

  const MatchPool({
    required this.tickets,
    required this.players,
  });

  /// 대기 중인 플레이어 수
  int get waitingCount => tickets.length;
}

/// 매칭 관리자
class MatchmakingManager {
  static final MatchmakingManager _instance = MatchmakingManager._();
  static MatchmakingManager get instance => _instance;

  MatchmakingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  MatchTicket? _currentTicket;
  MatchResult? _currentMatch;
  final Map<String, MatchPool> _pools = {};

  final StreamController<MatchTicket> _ticketController =
      StreamController<MatchTicket>.broadcast();
  final StreamController<MatchResult> _matchController =
      StreamController<MatchResult>.broadcast();
  final StreamController<int> _waitingController =
      StreamController<int>.broadcast(); // 대기 인원

  Stream<MatchTicket> get onTicketUpdate => _ticketController.stream;
  Stream<MatchResult> get onMatchFound => _matchController.stream;
  Stream<int> get onWaitingUpdate => _waitingController.stream;

  Timer? _matchmakingTimer;
  Timer? _poolUpdateTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 매칭 풀 초기화
    _initializePools();

    // 주기 업데이트 시작
    _startPoolUpdate();

    debugPrint('[Matchmaking] Initialized');
  }

  void _initializePools() {
    final modes = MatchMode.values;
    final types = MatchType.values;

    for (final mode in modes) {
      for (final type in types) {
        final key = '${mode.name}_${type.name}';
        _pools[key] = const MatchPool(
          tickets: [],
          players: {},
        );
      }
    }
  }

  void _startPoolUpdate() {
    _poolUpdateTimer?.cancel();
    _poolUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updatePools();
      _updateWaiting();
    });
  }

  void _updatePools() {
    // 실제로는 서버에서 풀 업데이트
    for (final key in _pools.keys) {
      final pool = _pools[key];
      // 대기 인원 시뮬레이션
      final waiting = Random().nextInt(100);
      _waitingController.add(waiting);
    }
  }

  void _updateWaiting() {
    // 대기 인원 업데이트 (시뮬레이션)
    final waiting = Random().nextInt(50) + 10;
    _waitingController.add(waiting);
  }

  /// 매칭 시작
  Future<MatchTicket?> startMatchmaking({
    required MatchMode mode,
    required MatchType type,
    List<MatchPreference>? preferences,
    Duration? timeout,
  }) async {
    if (_currentUserId == null) return null;

    // 기존 티켓 취소
    await cancelMatchmaking();

    // 티켓 생성
    final ticket = MatchTicket(
      ticketId: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
      playerId: _currentUserId!,
      mode: mode,
      type: type,
      createdAt: DateTime.now(),
      timeout: timeout ?? const Duration(minutes: 5),
      preferences: preferences ?? [],
    );

    _currentTicket = ticket;
    _ticketController.add(ticket);

    // 매칭 시작
    _startMatchmaking(ticket);

    debugPrint('[Matchmaking] Started: ${mode.name}/${type.name}');

    return ticket;
  }

  void _startMatchmaking(MatchTicket ticket) {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (ticket.isExpired) {
        timer.cancel();
        _onMatchmakingExpired(ticket);
        return;
      }

      // 매칭 시도
      _attemptMatch(ticket);
    });
  }

  void _attemptMatch(MatchTicket ticket) {
    final poolKey = '${ticket.mode.name}_${ticket.type.name}';
    final pool = _pools[poolKey];

    if (pool == null || pool.waitingCount < _getRequiredPlayers(ticket.type)) {
      return; // 충분한 플레이어 없음
    }

    // 매칭 생성 (시뮬레이션)
    final match = _createMatch(ticket, pool);
    if (match != null) {
      _matchmakingTimer?.cancel();
      _currentMatch = match;
      _matchController.add(match);

      debugPrint('[Matchmaking] Match found: ${match.matchId}');
    }
  }

  int _getRequiredPlayers(MatchType type) {
    switch (type) {
      case MatchType.solo:
        return 2; // 1v1
      case MatchType.duo:
        return 4; // 2v2
      case MatchType.squad:
        return 6; // 3v3
      case MatchType.team:
        return 10; // 5v5
      case MatchType.raid:
        return 10; // 10인 레이드
    }
  }

  MatchResult? _createMatch(MatchTicket ticket, MatchPool pool) {
    final requiredPlayers = _getRequiredPlayers(ticket.type);
    if (pool.waitingCount < requiredPlayers) return null;

    // 팀 분배
    final availablePlayers = pool.players.values.toList();
    final teamSize = requiredPlayers ~/ 2;

    // ELO 기반 팀 밸런싱
    availablePlayers.shuffle();
    availablePlayers.sort((a, b) => b.elo.compareTo(a.elo));

    // 번갈아가며 팀 배정
    final team1 = <MatchPlayer>[];
    final team2 = <MatchPlayer>[];

    for (var i = 0; i < teamSize; i++) {
      if (i < availablePlayers.length) {
        team1.add(availablePlayers[i]);
      }
      if (i + teamSize < availablePlayers.length) {
        team2.add(availablePlayers[i + teamSize]);
      }
    }

    final match = MatchResult(
      matchId: 'match_${DateTime.now().millisecondsSinceEpoch}',
      mode: ticket.mode,
      type: ticket.type,
      team1: team1,
      team2: team2,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 1)),
      serverId: 'server_${Random().nextInt(10)}',
    );

    return match;
  }

  void _onMatchmakingExpired(MatchTicket ticket) {
    if (_currentTicket?.ticketId == ticket.ticketId) {
      _currentTicket = null;

      final expired = MatchTicket(
        ticketId: ticket.ticketId,
        playerId: ticket.playerId,
        mode: ticket.mode,
        type: ticket.type,
        createdAt: ticket.createdAt,
        timeout: ticket.timeout,
        preferences: ticket.preferences,
      );

      _ticketController.add(expired);

      debugPrint('[Matchmaking] Expired');
    }
  }

  /// 매칭 수락
  Future<bool> acceptMatch(String matchId) async {
    if (_currentMatch?.matchId != matchId) return false;

    // 실제로는 서버에 수락 전송
    debugPrint('[Matchmaking] Accepted: $matchId');

    return true;
  }

  /// 매칭 거절
  Future<bool> declineMatch(String matchId) async {
    if (_currentMatch?.matchId != matchId) return false;

    _currentMatch = null;

    debugPrint('[Matchmaking] Declined: $matchId');

    return true;
  }

  /// 매칭 취소
  Future<bool> cancelMatchmaking() async {
    if (_currentTicket == null) return false;

    _matchmakingTimer?.cancel();
    _currentTicket = null;

    debugPrint('[Matchmaking] Cancelled');

    return true;
  }

  /// 레디 체크
  Future<bool> setReady(bool isReady) async {
    if (_currentMatch == null) return false;

    // 실제로는 서버에 레디 상태 전송
    debugPrint('[Matchmaking] Ready: $isReady');

    return true;
  }

  /// ELO 계산
  int calculateELO({
    required int currentELO,
    required bool isWin,
    required double opponentELO,
  }) {
    final expected = 1 / (1 + pow(10, (opponentELO - currentELO) / 400));
    final kFactor = 32;
    final newELO = (currentELO + kFactor * (1 - expected)).round();

    return newELO;
  }

  /// 스킬 레벨 계산
  SkillLevel calculateSkillLevel(double elo) {
    if (elo >= 2500) return SkillLevel.master;
    if (elo >= 2000) return SkillLevel.expert;
    if (elo >= 1500) return SkillLevel.advanced;
    if (elo >= 1000) return SkillLevel.intermediate;
    if (elo >= 500) return SkillLevel.novice;
    return SkillLevel.beginner;
  }

  /// 매칭 풀 조회
  MatchPool? getMatchPool(MatchMode mode, MatchType type) {
    final key = '${mode.name}_${type.name}';
    return _pools[key];
  }

  /// 대기 인원 조회
  int getWaitingCount(MatchMode mode, MatchType type) {
    final pool = getMatchPool(mode, type);
    return pool?.waitingCount ?? 0;
  }

  /// 현재 티켓
  MatchTicket? get currentTicket => _currentTicket;

  /// 현재 매치
  MatchResult? get currentMatch => _currentMatch;

  /// 예상 대기 시간
  Duration? getEstimatedWaitTime(MatchMode mode, MatchType type) {
    final waiting = getWaitingCount(mode, type);
    final required = _getRequiredPlayers(type);

    if (waiting >= required) {
      return Duration.zero;
    }

    // 간단 예측: 1명당 10초
    final remaining = required - waiting;
    return Duration(seconds: remaining * 10);
  }

  /// 매칭 품질 평가
  double getMatchQuality(MatchResult match) {
    final balance = match.balanceScore;
    if (balance < 50) return 1.0; // 매우 좋음
    if (balance < 100) return 0.8; // 좋음
    if (balance < 200) return 0.5; // 보통
    return 0.3; // 나쁨
  }

  void dispose() {
    _ticketController.close();
    _matchController.close();
    _waitingController.close();
    _matchmakingTimer?.cancel();
    _poolUpdateTimer?.cancel();
  }
}

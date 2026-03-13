import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토너먼트 타입
enum TournamentType {
  singleElimination,   // 싱글 엘리미네이션
  doubleElimination,   // 더블 엘리미네이션
  roundRobin,          // 라운드 로빈
  swiss,               // 스위스
  groupStage,          // 조별 리그
}

/// 매치 상태
enum MatchStatus {
  scheduled,    // 예정
  inProgress,   // 진행 중
  completed,    // 완료
  cancelled,    // 취소됨
}

/// 시드 타입
enum SeedType {
  random,           // 무작위
  manual,           // 수동
  ranked,           // 순위 기반
  balanced,         // 밸런스
}

/// 토너먼트 참가자
class TournamentParticipant {
  final String id;
  final String name;
  final String? teamName;
  final int seed;
  final int rank;
  final String? avatarUrl;
  final Map<String, dynamic>? stats;

  const TournamentParticipant({
    required this.id,
    required this.name,
    this.teamName,
    required this.seed,
    this.rank = 0,
    this.avatarUrl,
    this.stats,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teamName': teamName,
        'seed': seed,
        'rank': rank,
        'avatarUrl': avatarUrl,
        'stats': stats,
      };
}

/// 토너먼트 매치
class TournamentMatch {
  final String id;
  final int round;
  final int? matchNumber;
  final TournamentParticipant? participant1;
  final TournamentParticipant? participant2;
  final int? score1;
  final int? score2;
  final TournamentParticipant? winner;
  final MatchStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? metadata;

  const TournamentMatch({
    required this.id,
    required this.round,
    this.matchNumber,
    this.participant1,
    this.participant2,
    this.score1,
    this.score2,
    this.winner,
    required this.status,
    this.startTime,
    this.endTime,
    this.metadata,
  });

  /// 매치 완료 여부
  bool get isCompleted => status == MatchStatus.completed;
  bool get isScheduled => status == MatchStatus.scheduled;
  bool get isInProgress => status == MatchStatus.inProgress;

  /// 승자 결정
  TournamentMatch withWinner(TournamentParticipant winner) {
    return TournamentMatch(
      id: id,
      round: round,
      matchNumber: matchNumber,
      participant1: participant1,
      participant2: participant2,
      score1: winner == participant1 ? (score1 ?? 0) + 1 : score1,
      score2: winner == participant2 ? (score2 ?? 0) + 1 : score2,
      winner: winner,
      status: MatchStatus.completed,
      startTime: startTime,
      endTime: DateTime.now(),
      metadata: metadata,
    );
  }
}

/// 브래킷 라운드
class BracketRound {
  final int roundNumber;
  final String name;
  final List<TournamentMatch> matches;

  const BracketRound({
    required this.roundNumber,
    required this.name,
    required this.matches,
  });

  /// 라운드 완료 여부
  bool get isCompleted => matches.every((m) => m.isCompleted);
}

/// 토너먼트 브래킷
class TournamentBracket {
  final String id;
  final String name;
  final TournamentType type;
  final List<BracketRound> rounds;
  final List<TournamentParticipant> participants;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const TournamentBracket({
    required this.id,
    required this.name,
    required this.type,
    required this.rounds,
    required this.participants,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.isActive = false,
  });

  /// 총 라운드 수
  int get totalRounds => rounds.length;

  /// 현재 라운드
  int get currentRound {
    for (int i = 0; i < rounds.length; i++) {
      if (!rounds[i].isCompleted) {
        return i + 1;
      }
    }
    return rounds.length;
  }

  /// 진행 중인 매치
  List<TournamentMatch> get inProgressMatches {
    return rounds
        .expand((round) => round.matches)
        .where((match) => match.isInProgress)
        .toList();
  }
}

/// 그룹 스테이지 그룹
class TournamentGroup {
  final String id;
  final String name;
  final List<TournamentParticipant> participants;
  final List<TournamentMatch> matches;
  final Map<String, int> standings;

  const TournamentGroup({
    required this.id,
    required this.name,
    required this.participants,
    required this.matches,
    required this.standings,
  });
}

/// 토너먼트 관리자
class TournamentManager {
  static final TournamentManager _instance = TournamentManager._();
  static TournamentManager get instance => _instance;

  TournamentManager._();

  SharedPreferences? _prefs;
  final Map<String, TournamentBracket> _brackets = {};
  final Map<String, TournamentGroup> _groups = {};

  final StreamController<TournamentBracket> _bracketController =
      StreamController<TournamentBracket>.broadcast();
  final StreamController<TournamentMatch> _matchController =
      StreamController<TournamentMatch>.broadcast();

  Stream<TournamentBracket> get onBracketUpdate => _bracketController.stream;
  Stream<TournamentMatch> get onMatchUpdate => _matchController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 토너먼트 브래킷 로드
    _loadBrackets();

    debugPrint('[Tournament] Initialized');
  }

  void _loadBrackets() {
    // 시뮬레이션: 기본 브래킷 생성
  }

  /// 싱글 엘리미네이션 토너먼트 생성
  TournamentBracket createSingleElimination({
    required String name,
    required List<TournamentParticipant> participants,
    SeedType seedType = SeedType.random,
  }) {
    // 참가자 수가 2의 거듭제곱이 되도록 패딩
    final paddedParticipants = _padParticipants(participants);

    // 시딩
    final seededParticipants = _seedParticipants(paddedParticipants, seedType);

    // 라운드 수 계산
    final totalRounds = (log(paddedParticipants.length) / log(2)).toInt();

    // 브래킷 생성
    final rounds = <BracketRound>[];

    for (int round = 1; round <= totalRounds; round++) {
      final matchCount = paddedParticipants.length ~/ pow(2, round);
      final matches = <TournamentMatch>[];

      for (int i = 0; i < matchCount; i++) {
        matches.add(TournamentMatch(
          id: 'match_${round}_${i}',
          round: round,
          matchNumber: i + 1,
          status: MatchStatus.scheduled,
        ));
      }

      rounds.add(BracketRound(
        roundNumber: round,
        name: _getRoundName(round, totalRounds),
        matches: matches,
      ));
    }

    // 첫 라운드 참가자 배정
    _assignFirstRoundParticipants(rounds, seededParticipants);

    final bracket = TournamentBracket(
      id: 'bracket_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: TournamentType.singleElimination,
      rounds: rounds,
      participants: seededParticipants,
      createdAt: DateTime.now(),
      isActive: true,
    );

    _brackets[bracket.id] = bracket;
    _bracketController.add(bracket);

    return bracket;
  }

  /// 더블 엘리미네이션 토너먼트 생성
  TournamentBracket createDoubleElimination({
    required String name,
    required List<TournamentParticipant> participants,
    SeedType seedType = SeedType.random,
  }) {
    // 승자조 패자조 모두 생성
    final winnersBracket = createSingleElimination(
      name: '$name (Winners)',
      participants: participants,
      seedType: seedType,
    );

    // 패자조는 승자조의 절반 크기
    final losersBracket = TournamentBracket(
      id: '${winnersBracket.id}_losers',
      name: '$name (Losers)',
      type: TournamentType.doubleElimination,
      rounds: [],
      participants: [],
      createdAt: DateTime.now(),
      isActive: true,
    );

    return winnersBracket;
  }

  /// 라운드 로빈 토너먼트 생성
  TournamentBracket createRoundRobin({
    required String name,
    required List<TournamentParticipant> participants,
  }) {
    final matches = <TournamentMatch>[];
    int matchNumber = 0;

    // 모든 참가자끼리 매치
    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        matches.add(TournamentMatch(
          id: 'match_${i}_${j}',
          round: 1,
          matchNumber: ++matchNumber,
          participant1: participants[i],
          participant2: participants[j],
          status: MatchStatus.scheduled,
        ));
      }
    }

    final bracket = TournamentBracket(
      id: 'bracket_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: TournamentType.roundRobin,
      rounds: [
        BracketRound(
          roundNumber: 1,
          name: 'League Stage',
          matches: matches,
        ),
      ],
      participants: participants,
      createdAt: DateTime.now(),
      isActive: true,
    );

    _brackets[bracket.id] = bracket;
    _bracketController.add(bracket);

    return bracket;
  }

  /// 그룹 스테이지 생성
  List<TournamentGroup> createGroupStage({
    required List<TournamentParticipant> participants,
    required int groupsCount,
    required String tournamentId,
  }) {
    final groups = <TournamentGroup>[];
    final participantsPerGroup = participants.length ~/ groupsCount;

    // 참가자를 그룹에 배정
    for (int i = 0; i < groupsCount; i++) {
      final start = i * participantsPerGroup;
      final end = start + participantsPerGroup;
      final groupParticipants = participants.sublist(start, end);

      final groupMatches = <TournamentMatch>[];
      int matchNumber = 0;

      // 그룹 내 라운드 로빈
      for (int j = 0; j < groupParticipants.length; j++) {
        for (int k = j + 1; k < groupParticipants.length; k++) {
          groupMatches.add(TournamentMatch(
            id: '${tournamentId}_group${i}_match_${j}_${k}',
            round: i + 1,
            matchNumber: ++matchNumber,
            participant1: groupParticipants[j],
            participant2: groupParticipants[k],
            status: MatchStatus.scheduled,
          ));
        }
      }

      final group = TournamentGroup(
        id: '${tournamentId}_group_$i',
        name: 'Group ${String.fromCharCode(65 + i)}',
        participants: groupParticipants,
        matches: groupMatches,
        standings: {},
      );

      groups.add(group);
      _groups[group.id] = group;
    }

    return groups;
  }

  /// 매치 결과 업데이트
  Future<void> updateMatchResult({
    required String bracketId,
    required String matchId,
    required TournamentParticipant winner,
    int? score1,
    int? score2,
  }) async {
    final bracket = _brackets[bracketId];
    if (bracket == null) return;

    // 매치 찾기 및 업데이트
    for (final round in bracket.rounds) {
      final matchIndex = round.matches.indexWhere((m) => m.id == matchId);
      if (matchIndex != -1) {
        final match = round.matches[matchIndex];
        final updatedMatch = match.withWinner(winner);

        round.matches[matchIndex] = updatedMatch;
        _matchController.add(updatedMatch);

        // 다음 라운드에 승자 배정
        _advanceWinner(bracket, match, winner);

        // 브래킷 업데이트
        _bracketController.add(bracket);

        debugPrint('[Tournament] Match result updated: $matchId');
        return;
      }
    }
  }

  /// 승자 다음 라운드 배정
  void _advanceWinner(
    TournamentBracket bracket,
    TournamentMatch match,
    TournamentParticipant winner,
  ) {
    final currentRound = match.round;
    final nextRound = currentRound + 1;

    if (nextRound > bracket.rounds.length) return;

    final nextRoundMatches = bracket.rounds[nextRound - 1].matches;
    final matchIndex = match.matchNumber!;

    // 다음 라운드의 해당 매치 찾기
    final nextMatchIndex = matchIndex ~/ 2;
    if (nextMatchIndex < nextRoundMatches.length) {
      final nextMatch = nextRoundMatches[nextMatchIndex];

      // 첫 번째 참가자 또는 두 번째 참가자로 배정
      TournamentMatch updatedMatch;
      if (matchIndex % 2 == 0) {
        updatedMatch = TournamentMatch(
          id: nextMatch.id,
          round: nextMatch.round,
          matchNumber: nextMatch.matchNumber,
          participant1: winner,
          participant2: nextMatch.participant2,
          status: nextMatch.status,
          startTime: nextMatch.startTime,
          endTime: nextMatch.endTime,
          metadata: nextMatch.metadata,
        );
      } else {
        updatedMatch = TournamentMatch(
          id: nextMatch.id,
          round: nextMatch.round,
          matchNumber: nextMatch.matchNumber,
          participant1: nextMatch.participant1,
          participant2: winner,
          status: nextMatch.status,
          startTime: nextMatch.startTime,
          endTime: nextMatch.endTime,
          metadata: nextMatch.metadata,
        );
      }

      nextRoundMatches[nextMatchIndex] = updatedMatch;
    }
  }

  /// 참가자 패딩
  List<TournamentParticipant> _padParticipants(
    List<TournamentParticipant> participants,
  ) {
    final count = participants.length;
    final nextPower = pow(2, (log(count) / log(2)).ceil()).toInt();

    if (count == nextPower) return participants;

    final padded = List<TournamentParticipant>.from(participants);

    for (int i = count; i < nextPower; i++) {
      padded.add(const TournamentParticipant(
        id: 'bye_$i',
        name: 'BYE',
        seed: i + 1,
        rank: 0,
      ));
    }

    return padded;
  }

  /// 참가자 시딩
  List<TournamentParticipant> _seedParticipants(
    List<TournamentParticipant> participants,
    SeedType seedType,
  ) {
    switch (seedType) {
      case SeedType.random:
        final shuffled = List<TournamentParticipant>.from(participants);
        shuffled.shuffle();
        return shuffled;

      case SeedType.ranked:
        final sorted = List<TournamentParticipant>.from(participants);
        sorted.sort((a, b) => a.rank.compareTo(b.rank));
        return sorted;

      case SeedType.balanced:
        // 순위별로 상하 배정
        final sorted = List<TournamentParticipant>.from(participants);
        sorted.sort((a, b) => a.rank.compareTo(b.rank));

        final balanced = <TournamentParticipant>[];
        final top = sorted.sublist(0, sorted.length ~/ 2);
        final bottom = sorted.sublist(sorted.length ~/ 2);

        for (int i = 0; i < top.length; i++) {
          balanced.add(top[i]);
          if (i < bottom.length) {
            balanced.add(bottom[i]);
          }
        }

        return balanced;

      default:
        return participants;
    }
  }

  /// 첫 라운드 참가자 배정
  void _assignFirstRoundParticipants(
    List<BracketRound> rounds,
    List<TournamentParticipant> participants,
  ) {
    final firstRound = rounds.first.matches;

    for (int i = 0; i < firstRound.length; i++) {
      final match = firstRound[i];

      final participant1 = i * 2 < participants.length
          ? participants[i * 2]
          : null;
      final participant2 = i * 2 + 1 < participants.length
          ? participants[i * 2 + 1]
          : null;

      firstRound[i] = TournamentMatch(
        id: match.id,
        round: match.round,
        matchNumber: match.matchNumber,
        participant1: participant1,
        participant2: participant2,
        status: participant1?.name == 'BYE' || participant2?.name == 'BYE'
            ? MatchStatus.completed
            : MatchStatus.scheduled,
        startTime: match.startTime,
        endTime: match.endTime,
        metadata: match.metadata,
      );

      // BYE 처리
      if (participant1?.name == 'BYE' && participant2 != null) {
        firstRound[i] = firstRound[i].withWinner(participant2);
      } else if (participant2?.name == 'BYE' && participant1 != null) {
        firstRound[i] = firstRound[i].withWinner(participant1);
      }
    }
  }

  /// 라운드 이름
  String _getRoundName(int round, int totalRounds) {
    if (round == totalRounds) return 'Finals';
    if (round == totalRounds - 1) return 'Semi Finals';
    if (round == totalRounds - 2) return 'Quarter Finals';
    return 'Round $round';
  }

  /// 브래킷 조회
  TournamentBracket? getBracket(String bracketId) {
    return _brackets[bracketId];
  }

  /// 모든 브래킷 조회
  List<TournamentBracket> getBrackets() {
    return _brackets.values.toList();
  }

  /// 그룹 조회
  TournamentGroup? getGroup(String groupId) {
    return _groups[groupId];
  }

  /// 토너먼트 시작
  Future<void> startTournament(String bracketId) async {
    final bracket = _brackets[bracketId];
    if (bracket == null) return;

    final updated = TournamentBracket(
      id: bracket.id,
      name: bracket.name,
      type: bracket.type,
      rounds: bracket.rounds,
      participants: bracket.participants,
      createdAt: bracket.createdAt,
      startDate: DateTime.now(),
      endDate: bracket.endDate,
      isActive: true,
    );

    _brackets[bracketId] = updated;
    _bracketController.add(updated);

    debugPrint('[Tournament] Tournament started: $bracketId');
  }

  /// 토너먼트 종료
  Future<void> endTournament(String bracketId) async {
    final bracket = _brackets[bracketId];
    if (bracket == null) return;

    final updated = TournamentBracket(
      id: bracket.id,
      name: bracket.name,
      type: bracket.type,
      rounds: bracket.rounds,
      participants: bracket.participants,
      createdAt: bracket.createdAt,
      startDate: bracket.startDate,
      endDate: DateTime.now(),
      isActive: false,
    );

    _brackets[bracketId] = updated;
    _bracketController.add(updated);

    debugPrint('[Tournament] Tournament ended: $bracketId');
  }

  /// 우승자 조회
  TournamentParticipant? getWinner(String bracketId) {
    final bracket = _brackets[bracketId];
    if (bracket == null) return null;

    final finalRound = bracket.rounds.last.matches;
    if (finalRound.isEmpty) return null;

    return finalRound.first.winner;
  }

  /// 브래킷 시각화 데이터
  Map<String, dynamic> getBracketVisualizationData(String bracketId) {
    final bracket = _brackets[bracketId];
    if (bracket == null) return {};

    return {
      'id': bracket.id,
      'name': bracket.name,
      'type': bracket.type.name,
      'rounds': bracket.rounds.map((round) => {
        'roundNumber': round.roundNumber,
        'name': round.name,
        'matches': round.matches.map((match) => {
          'id': match.id,
          'round': match.round,
          'participant1': match.participant1?.toJson(),
          'participant2': match.participant2?.toJson(),
          'score1': match.score1,
          'score2': match.score2,
          'winner': match.winner?.toJson(),
          'status': match.status.name,
          'startTime': match.startTime?.toIso8601String(),
          'endTime': match.endTime?.toIso8601String(),
        }).toList(),
      }).toList(),
      'currentRound': bracket.currentRound,
      'isActive': bracket.isActive,
    };
  }

  void dispose() {
    _bracketController.close();
    _matchController.close();
  }
}

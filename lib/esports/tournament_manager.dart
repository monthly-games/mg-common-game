import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토너먼트 형식
enum TournamentFormat {
  singleElimination,  // 단순 토너먼트
  doubleElimination,  // 더블 토너먼트
  roundRobin,        // 리그전
  groupStage,        // 조별 예선
}

/// 토너먼트 상태
enum TournamentStatus {
  registration,
  scheduled,
  inProgress,
  completed,
  cancelled,
}

/// 매치 결과
enum MatchResult {
  pending,
  team1Win,
  team2Win,
  draw,
  walkover,
}

/// 토너먼트 참가자
class TournamentParticipant {
  final String id;
  final String name;
  final String? avatarUrl;
  final int seed; // 시드 순위
  final Map<String, dynamic> stats;

  const TournamentParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.seed = 0,
    this.stats = const {},
  });
}

/// 토너먼트 매치
class TournamentMatch {
  final String id;
  final String roundId;
  final TournamentParticipant? team1;
  final TournamentParticipant? team2;
  final DateTime scheduledTime;
  final MatchResult result;
  final int? team1Score;
  final int? team2Score;

  const TournamentMatch({
    required this.id,
    required this.roundId,
    this.team1,
    this.team2,
    required this.scheduledTime,
    this.result = MatchResult.pending,
    this.team1Score,
    this.team2Score,
  });

  /// 토너먼트 브래킷 정보
  Map<String, dynamic> toBracketData() => {
        'match_id': id,
        'team1_id': team1?.id,
        'team2_id': team2?.id,
        'team1_score': team1Score,
        'team2_score': team2Score,
        'winner': result == MatchResult.team1Win
            ? team1?.id
            : result == MatchResult.team2Win
                ? team2?.id
                : null,
      };
}

/// 토너먼트
class Tournament {
  final String id;
  final String name;
  final String description;
  final TournamentFormat format;
  final TournamentStatus status;
  final int maxParticipants;
  final List<TournamentParticipant> participants;
  final List<TournamentMatch> matches;
  final DateTime registrationStart;
  final DateTime registrationEnd;
  final DateTime startDate;
  final DateTime? endDate;
  final int prizePool;
  final String? currency; // 상금 통화

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.status,
    required this.maxParticipants,
    required this.participants,
    required this.matches,
    required this.registrationStart,
    required this.registrationEnd,
    required this.startDate,
    this.endDate,
    this.prizePool = 0,
    this.currency,
  });

  /// 브래킷 생성
  List<Map<String, dynamic>> generateBracket() {
    final bracket = <Map<String, dynamic>>[];

    switch (format) {
      case TournamentFormat.singleElimination:
        final matchCount = (participants.length / 2).ceil();
        for (int i = 0; i < matchCount; i++) {
          bracket.add({
            'round': 1,
            'match': i + 1,
            'team1': i < participants.length ? participants[i * 2].id : null,
            'team2': i < participants.length && (i * 2 + 1) < participants.length
                ? participants[i * 2 + 1].id
                : null,
          });
        }
        break;

      case TournamentFormat.roundRobin:
        // 리그전 스케줄 생성
        for (int i = 0; i < participants.length; i++) {
          for (int j = i + 1; j < participants.length; j++) {
            bracket.add({
              'round': 1,
              'match': bracket.length + 1,
              'team1': participants[i].id,
              'team2': participants[j].id,
            });
          }
        }
        break;

      default:
        break;
    }

    return bracket;
  }

  /// 순위 계산
  List<TournamentParticipant> calculateStandings() {
    final standings = List<TournamentParticipant>.from(participants);

    standings.sort((a, b) {
      final scoreA = (a.stats['wins'] ?? 0) as int;
      final scoreB = (b.stats['wins'] ?? 0) as int;

      if (scoreA != scoreB) return scoreB.compareTo(scoreA);

      // 동점자 처리 (상대 전적, 점수차 등)
      return 0;
    });

    return standings;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'format': format.name,
        'status': status.name,
        'maxParticipants': maxParticipants,
        'participants': participants.map((p) => p.id).toList(),
        'matches': matches.length,
        'registrationStart': registrationStart.toIso8601String(),
        'registrationEnd': registrationEnd.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'prizePool': prizePool,
        'currency': currency,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        format: TournamentFormat.values.firstWhere(
          (e) => e.name == json['format'],
          orElse: () => TournamentFormat.singleElimination,
        ),
        status: TournamentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TournamentStatus.registration,
        ),
        maxParticipants: json['maxParticipants'] as int,
        participants: const [], // 실제로는 로드
        matches: const [],
        registrationStart: DateTime.parse(json['registrationStart'] as String),
        registrationEnd: DateTime.parse(json['registrationEnd'] as String),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        prizePool: json['prizePool'] as int? ?? 0,
        currency: json['currency'] as String?,
      );
}

/// E-Sports 매니저
class EsportsManager {
  static final EsportsManager _instance = EsportsManager._();
  static EsportsManager get instance => _instance;

  EsportsManager._();

  SharedPreferences? _prefs;
  final Map<String, Tournament> _tournaments = {};

  final StreamController<Tournament> _tournamentController =
      StreamController<Tournament>.broadcast();
  final StreamController<TournamentMatch> _matchController =
      StreamController<TournamentMatch>.broadcast();

  Stream<Tournament> get onTournamentUpdate => _tournamentController.stream;
  Stream<TournamentMatch> get onMatchUpdate => _matchController.stream;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    final tournamentsJson = _prefs!.getStringList('tournaments');
    if (tournamentsJson != null) {
      for (final json in tournamentsJson) {
        final tournament = Tournament.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _tournaments[tournament.id] = tournament;
      }
    }
  }

  Future<Tournament> createTournament({
    required String name,
    required String description,
    required TournamentFormat format,
    required DateTime startDate,
    int maxParticipants = 16,
    int prizePool = 0,
  }) async {
    final now = DateTime.now();
    final tournament = Tournament(
      id: 'tournament_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      format: format,
      status: TournamentStatus.registration,
      maxParticipants: maxParticipants,
      participants: [],
      matches: [],
      registrationStart: now,
      registrationEnd: startDate.subtract(const Duration(days: 7)),
      startDate: startDate,
      prizePool: prizePool,
    );

    _tournaments[tournament.id] = tournament;
    await _saveTournaments();

    _tournamentController.add(tournament);
    return tournament;
  }

  Future<void> registerParticipant({
    required String tournamentId,
    required TournamentParticipant participant,
  }) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return;

    if (tournament.participants.length >= tournament.maxParticipants) {
      debugPrint('[Esports] Tournament is full');
      return;
    }

    final updated = Tournament(
      id: tournament.id,
      name: tournament.name,
      description: tournament.description,
      format: tournament.format,
      status: tournament.status,
      maxParticipants: tournament.maxParticipants,
      participants: [...tournament.participants, participant],
      matches: tournament.matches,
      registrationStart: tournament.registrationStart,
      registrationEnd: tournament.registrationEnd,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      prizePool: tournament.prizePool,
      currency: tournament.currency,
    );

    _tournaments[tournamentId] = updated;
    await _saveTournaments();

    _tournamentController.add(updated);
  }

  Future<void> updateMatch({
    required String tournamentId,
    required String matchId,
    required MatchResult result,
    int? team1Score,
    int? team2Score,
  }) async {
    final tournament = _tournaments[tournamentId];
    if (tournament == null) return;

    final matchIndex = tournament.matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return;

    final match = tournament.matches[matchIndex];
    final updatedMatch = TournamentMatch(
      id: match.id,
      roundId: match.roundId,
      team1: match.team1,
      team2: match.team2,
      scheduledTime: match.scheduledTime,
      result: result,
      team1Score: team1Score,
      team2Score: team2Score,
    );

    final updatedMatches = List<TournamentMatch>.from(tournament.matches);
    updatedMatches[matchIndex] = updatedMatch;

    _tournaments[tournamentId] = Tournament(
      id: tournament.id,
      name: tournament.name,
      description: tournament.description,
      format: tournament.format,
      status: tournament.status,
      maxParticipants: tournament.maxParticipants,
      participants: tournament.participants,
      matches: updatedMatches,
      registrationStart: tournament.registrationStart,
      registrationEnd: tournament.registrationEnd,
      startDate: tournament.startDate,
      endDate: tournament.endDate,
      prizePool: tournament.prizePool,
      currency: tournament.currency,
    );

    await _saveTournaments();

    _matchController.add(updatedMatch);
  }

  Tournament? getTournament(String tournamentId) {
    return _tournaments[tournamentId];
  }

  Future<void> _saveTournaments() async {
    final tournamentsJson = _tournaments.values.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs!.setStringList('tournaments', tournamentsJson);
  }

  void dispose() {
    _tournamentController.close();
    _matchController.close();
  }
}

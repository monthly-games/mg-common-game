import 'dart:async';
import 'package:flutter/material.dart';

enum PVPMatchType {
  oneVsOne,
  twoVsTwo,
  threeVsThree,
  fiveVsFive,
}

enum PVPRank {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
  challenger,
}

enum PVPMatchStatus {
  waiting,
  matched,
  inProgress,
  completed,
  cancelled,
}

class PVPRating {
  final String playerId;
  final PVPRank rank;
  final int rating;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int streak;
  final int peakRating;
  final DateTime lastPlayed;

  const PVPRating({
    required this.playerId,
    required this.rank,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.streak,
    required this.peakRating,
    required this.lastPlayed,
  });

  int get totalGames => wins + losses + draws;
}

class PVPMatchRequest {
  final String requestId;
  final String playerId;
  final PVPMatchType type;
  final int minRating;
  final int maxRating;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  const PVPMatchRequest({
    required this.requestId,
    required this.playerId,
    required this.type,
    required this.minRating,
    required this.maxRating,
    required this.createdAt,
    required this.preferences,
  });

  Duration get waitTime => DateTime.now().difference(createdAt);
}

class PVPMatch {
  final String matchId;
  final PVPMatchType type;
  final List<String> team1Players;
  final List<String> team2Players;
  final PVPMatchStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? winner;
  final Map<String, int> team1Score;
  final Map<String, int> team2Score;
  final Map<String, dynamic> matchData;

  const PVPMatch({
    required this.matchId,
    required this.type,
    required this.team1Players,
    required this.team2Players,
    required this.status,
    required this.startTime,
    this.endTime,
    this.winner,
    required this.team1Score,
    required this.team2Score,
    required this.matchData,
  });

  Duration get duration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  String? getLoser() {
    if (winner == 'team1') return 'team2';
    if (winner == 'team2') return 'team1';
    return null;
  }
}

class PVPReward {
  final String rewardId;
  final PVPRank rank;
  final int ratingChange;
  final Map<String, int> currencyRewards;
  final List<String> itemRewards;

  const PVPReward({
    required this.rewardId,
    required this.rank,
    required this.ratingChange,
    required this.currencyRewards,
    required this.itemRewards,
  });
}

class PVPSeason {
  final String seasonId;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final Map<String, PVPRating> rankings;

  const PVPSeason({
    required this.seasonId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.rankings,
  });

  Duration get remainingTime {
    if (!isActive) return Duration.zero;
    return endTime.difference(DateTime.now());
  }
}

class PVPSystemManager {
  static final PVPSystemManager _instance = PVPSystemManager._();
  static PVPSystemManager get instance => _instance;

  PVPSystemManager._();

  final Map<String, PVPRating> _ratings = {};
  final Map<String, PVPMatchRequest> _matchRequests = {};
  final Map<String, PVPMatch> _activeMatches = {};
  final Map<String, PVPSeason> _seasons = {};
  final List<PVPMatch> _matchHistory = [];
  final StreamController<PVPEvent> _eventController = StreamController.broadcast();

  Stream<PVPEvent> get onPVPEvent => _eventController.stream;

  PVPSeason? createSeason({
    required String seasonId,
    required String name,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final season = PVPSeason(
      seasonId: seasonId,
      name: name,
      startTime: startTime,
      endTime: endTime,
      isActive: true,
      rankings: {},
    );

    _seasons[seasonId] = season;

    _eventController.add(PVPEvent(
      type: PVPEventType.seasonStarted,
      seasonId: seasonId,
      timestamp: DateTime.now(),
    ));

    return season;
  }

  PVPSeason? getCurrentSeason() {
    return _seasons.values
        .where((season) => season.isActive)
        .FirstOrDefault((s) => true);
  }

  PVPRating? getPlayerRating(String playerId) {
    return _ratings[playerId];
  }

  void initializeRating({
    required String playerId,
    required int initialRating,
  }) {
    if (_ratings.containsKey(playerId)) return;

    _ratings[playerId] = PVPRating(
      playerId: playerId,
      rank: _getRankFromRating(initialRating),
      rating: initialRating,
      wins: 0,
      losses: 0,
      draws: 0,
      winRate: 0.0,
      streak: 0,
      peakRating: initialRating,
      lastPlayed: DateTime.now(),
    );
  }

  PVPRank _getRankFromRating(int rating) {
    if (rating >= 2500) return PVPRank.challenger;
    if (rating >= 2000) return PVPRank.grandmaster;
    if (rating >= 1800) return PVPRank.master;
    if (rating >= 1600) return PVPRank.diamond;
    if (rating >= 1400) return PVPRank.platinum;
    if (rating >= 1200) return PVPRank.gold;
    if (rating >= 1000) return PVPRank.silver;
    return PVPRank.bronze;
  }

  Future<String?> requestMatch({
    required String playerId,
    required PVPMatchType type,
    Map<String, dynamic>? preferences,
  }) async {
    final rating = _ratings[playerId];
    if (rating == null) return null;

    final request = PVPMatchRequest(
      requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
      playerId: playerId,
      type: type,
      minRating: (rating.rating - 200).clamp(0, double.infinity).toInt(),
      maxRating: rating.rating + 200,
      createdAt: DateTime.now(),
      preferences: preferences ?? {},
    );

    _matchRequests[request.requestId] = request;

    _eventController.add(PVPEvent(
      type: PVPEventType.matchRequested,
      playerId: playerId,
      timestamp: DateTime.now(),
    ));

    return request.requestId;
  }

  Future<PVPMatch?> findMatch(String requestId) async {
    final request = _matchRequests[requestId];
    if (request == null) return null;

    final opponent = _findOpponent(request);
    if (opponent == null) return null;

    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
    final match = PVPMatch(
      matchId: matchId,
      type: request.type,
      team1Players: [request.playerId],
      team2Players: [opponent.playerId],
      status: PVPMatchStatus.matched,
      startTime: DateTime.now(),
      team1Score: {},
      team2Score: {},
      matchData: {},
    );

    _activeMatches[matchId] = match;
    _matchRequests.remove(requestId);
    _matchRequests.removeWhere((key, req) => req.playerId == opponent.playerId);

    _eventController.add(PVPEvent(
      type: PVPEventType.matchFound,
      matchId: matchId,
      timestamp: DateTime.now(),
    ));

    return match;
  }

  PVPMatchRequest? _findOpponent(PVPMatchRequest request) {
    final candidates = _matchRequests.values
        .where((req) =>
            req.requestId != request.requestId &&
            req.type == request.type &&
            req.playerId != request.playerId &&
            _isRatingMatch(request, req))
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) =>
        a.createdAt.compareTo(b.createdAt));

    return candidates.first;
  }

  bool _isRatingMatch(PVPMatchRequest req1, PVPMatchRequest req2) {
    final rating1 = _ratings[req1.playerId]?.rating ?? 0;
    final rating2 = _ratings[req2.playerId]?.rating ?? 0;
    final difference = (rating1 - rating2).abs();
    return difference <= 200;
  }

  Future<void> startMatch(String matchId) async {
    final match = _activeMatches[matchId];
    if (match == null) return;

    _activeMatches[matchId] = PVPMatch(
      matchId: match.matchId,
      type: match.type,
      team1Players: match.team1Players,
      team2Players: match.team2Players,
      status: PVPMatchStatus.inProgress,
      startTime: DateTime.now(),
      team1Score: match.team1Score,
      team2Score: match.team2Score,
      matchData: match.matchData,
    );

    _eventController.add(PVPEvent(
      type: PVPEventType.matchStarted,
      matchId: matchId,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> endMatch({
    required String matchId,
    required String winner,
    Map<String, int>? team1FinalScore,
    Map<String, int>? team2FinalScore,
  }) async {
    final match = _activeMatches[matchId];
    if (match == null) return;

    final updatedMatch = PVPMatch(
      matchId: match.matchId,
      type: match.type,
      team1Players: match.team1Players,
      team2Players: match.team2Players,
      status: PVPMatchStatus.completed,
      startTime: match.startTime,
      endTime: DateTime.now(),
      winner: winner,
      team1Score: team1FinalScore ?? match.team1Score,
      team2Score: team2FinalScore ?? match.team2Score,
      matchData: match.matchData,
    );

    _activeMatches.remove(matchId);
    _matchHistory.add(updatedMatch);

    for (final playerId in match.team1Players) {
      _updateRating(playerId, playerId == 'team1' ? 'win' : 'loss', match);
    }

    for (final playerId in match.team2Players) {
      _updateRating(playerId, playerId == 'team2' ? 'win' : 'loss', match);
    }

    _eventController.add(PVPEvent(
      type: PVPEventType.matchEnded,
      matchId: matchId,
      data: {'winner': winner},
      timestamp: DateTime.now(),
    ));
  }

  void _updateRating(String playerId, String result, PVPMatch match) {
    final rating = _ratings[playerId];
    if (rating == null) return;

    int ratingChange = 0;
    switch (result) {
      case 'win':
        ratingChange = 25;
        break;
      case 'loss':
        ratingChange = -20;
        break;
      case 'draw':
        ratingChange = 0;
        break;
    }

    final newRating = (rating.rating + ratingChange).clamp(0, 3000);
    final newRank = _getRankFromRating(newRating);

    final newWins = result == 'win' ? rating.wins + 1 : rating.wins;
    final newLosses = result == 'loss' ? rating.losses + 1 : rating.losses;
    final newDraws = result == 'draw' ? rating.draws + 1 : rating.draws;
    final newWinRate = newWins / (newWins + newLosses + newDraws);

    int newStreak = rating.streak;
    if (result == 'win') {
      newStreak = rating.streak > 0 ? rating.streak + 1 : 1;
    } else if (result == 'loss') {
      newStreak = rating.streak < 0 ? rating.streak - 1 : -1;
    }

    _ratings[playerId] = PVPRating(
      playerId: playerId,
      rank: newRank,
      rating: newRating,
      wins: newWins,
      losses: newLosses,
      draws: newDraws,
      winRate: newWinRate,
      streak: newStreak,
      peakRating: newRating > rating.peakRating ? newRating : rating.peakRating,
      lastPlayed: DateTime.now(),
    );
  }

  void cancelMatchRequest(String requestId) {
    _matchRequests.remove(requestId);

    _eventController.add(PVPEvent(
      type: PVPEventType.matchCancelled,
      data: {'requestId': requestId},
      timestamp: DateTime.now(),
    ));
  }

  List<PVPMatch> getMatchHistory(String playerId, {int limit = 20}) {
    return _matchHistory
        .where((match) =>
            match.team1Players.contains(playerId) ||
            match.team2Players.contains(playerId))
        .take(limit)
        .toList();
  }

  List<PVPRating> getRankings({int limit = 100}) {
    return _ratings.values.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating))
      ..take(limit);
  }

  int getPlayerRank(String playerId) {
    final sorted = getRankings();
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].playerId == playerId) {
        return i + 1;
      }
    }
    return -1;
  }

  PVPReward calculateReward(PVPRank rank, bool isWin) {
    final ratingChange = isWin ? 25 : -20;
    final currencyRewards = isWin
        ? {'gold': 100, 'gems': 10}
        : {'gold': 20, 'gems': 2};

    return PVPReward(
      rewardId: 'reward_${rank.name}_${isWin ? 'win' : 'loss'}',
      rank: rank,
      ratingChange: ratingChange,
      currencyRewards: currencyRewards,
      itemRewards: [],
    );
  }

  void dispose() {
    _eventController.close();
  }
}

class PVPEvent {
  final PVPEventType type;
  final String? playerId;
  final String? matchId;
  final String? seasonId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const PVPEvent({
    required this.type,
    this.playerId,
    this.matchId,
    this.seasonId,
    this.data,
    required this.timestamp,
  });
}

enum PVPEventType {
  seasonStarted,
  seasonEnded,
  matchRequested,
  matchFound,
  matchStarted,
  matchEnded,
  matchCancelled,
  ratingChanged,
}

extension ListExtension<T> on List<T> {
  T? FirstOrDefault(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

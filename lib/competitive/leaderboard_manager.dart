import 'dart:async';
import 'package:flutter/material.dart';

enum LeaderboardType {
  global,
  friends,
  guild,
  regional,
  seasonal,
}

enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
  seasonal,
}

enum SortOrder {
  ascending,
  descending,
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatar;
  final int rank;
  final double score;
  final Map<String, dynamic> stats;
  final DateTime? lastUpdated;
  final int streak;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatar,
    required this.rank,
    required this.score,
    required this.stats,
    this.lastUpdated,
    required this.streak,
  });
}

class Leaderboard {
  final String leaderboardId;
  final String name;
  final String description;
  final LeaderboardType type;
  final LeaderboardPeriod period;
  final String metric;
  final List<LeaderboardEntry> entries;
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxEntries;
  final DateTime lastUpdated;
  final bool isActive;

  const Leaderboard({
    required this.leaderboardId,
    required this.name,
    required this.description,
    required this.type,
    required this.period,
    required this.metric,
    required this.entries,
    this.startDate,
    this.endDate,
    required this.maxEntries,
    required this.lastUpdated,
    required this.isActive,
  });

  bool get hasExpired => endDate != null && DateTime.now().isAfter(endDate!);
  LeaderboardEntry? get getTopEntry => entries.isNotEmpty ? entries.first : null;
}

class LeaderboardReward {
  final String rewardId;
  final int rankStart;
  final int rankEnd;
  final String type;
  final int amount;
  final String itemId;
  final String itemName;

  const LeaderboardReward({
    required this.rewardId,
    required this.rankStart,
    required this.rankEnd,
    required this.type,
    required this.amount,
    required this.itemId,
    required this.itemName,
  });
}

class LeaderboardManager {
  static final LeaderboardManager _instance = LeaderboardManager._();
  static LeaderboardManager get instance => _instance;

  LeaderboardManager._();

  final Map<String, Leaderboard> _leaderboards = {};
  final Map<String, List<LeaderboardReward>> _rewards = {};
  final StreamController<LeaderboardEvent> _eventController = StreamController.broadcast();
  Timer? _refreshTimer;

  Stream<LeaderboardEvent> get onLeaderboardEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultLeaderboards();
    await _loadDefaultRewards();
    _startRefreshTimer();
  }

  Future<void> _loadDefaultLeaderboards() async {
    final leaderboards = [
      Leaderboard(
        leaderboardId: 'global_level',
        name: 'Global Level Ranking',
        description: 'Highest level players worldwide',
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        metric: 'level',
        entries: [],
        maxEntries: 100,
        lastUpdated: DateTime.now(),
        isActive: true,
      ),
      Leaderboard(
        leaderboardId: 'weekly_score',
        name: 'Weekly Score',
        description: 'Top scores this week',
        type: LeaderboardType.global,
        period: LeaderboardPeriod.weekly,
        metric: 'score',
        startDate: _getWeekStart(),
        endDate: _getWeekEnd(),
        entries: [],
        maxEntries: 50,
        lastUpdated: DateTime.now(),
        isActive: true,
      ),
      Leaderboard(
        leaderboardId: 'friends_score',
        name: 'Friends Ranking',
        description: 'Your friends ranking',
        type: LeaderboardType.friends,
        period: LeaderboardPeriod.allTime,
        metric: 'score',
        entries: [],
        maxEntries: 50,
        lastUpdated: DateTime.now(),
        isActive: true,
      ),
    ];

    for (final leaderboard in leaderboards) {
      _leaderboards[leaderboard.leaderboardId] = leaderboard;
    }
  }

  Future<void> _loadDefaultRewards() async {
    final rewards = {
      'global_level': [
        const LeaderboardReward(
          rewardId: 'rank_1',
          rankStart: 1,
          rankEnd: 1,
          type: 'premium_currency',
          amount: 1000,
          itemId: 'gems',
          itemName: 'Gems',
        ),
        const LeaderboardReward(
          rewardId: 'rank_2_3',
          rankStart: 2,
          rankEnd: 3,
          type: 'premium_currency',
          amount: 500,
          itemId: 'gems',
          itemName: 'Gems',
        ),
        const LeaderboardReward(
          rewardId: 'rank_4_10',
          rankStart: 4,
          rankEnd: 10,
          type: 'currency',
          amount: 1000,
          itemId: 'coins',
          itemName: 'Coins',
        ),
      ],
    };

    for (final entry in rewards.entries) {
      _rewards[entry.key] = entry.value;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshLeaderboards(),
    );
  }

  DateTime _getWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime _getWeekEnd() {
    final now = DateTime.now();
    return now.add(Duration(days: 7 - now.weekday));
  }

  void _refreshLeaderboards() {
    for (final leaderboard in _leaderboards.values) {
      if (leaderboard.isActive && !leaderboard.hasExpired) {
        _eventController.add(LeaderboardEvent(
          type: LeaderboardEventType.leaderboardUpdated,
          leaderboardId: leaderboard.leaderboardId,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  List<Leaderboard> getAllLeaderboards() {
    return _leaderboards.values.toList();
  }

  Leaderboard? getLeaderboard(String leaderboardId) {
    return _leaderboards[leaderboardId];
  }

  List<LeaderboardEntry> getEntries(String leaderboardId, {int limit = 100}) {
    final leaderboard = _leaderboards[leaderboardId];
    if (leaderboard == null) return [];

    final entries = leaderboard.entries.toList();
    if (entries.length > limit) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  LeaderboardEntry? getEntry(String leaderboardId, String userId) {
    final entries = getEntries(leaderboardId);
    try {
      return entries.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  LeaderboardEntry? getUserRank(String leaderboardId, String userId) {
    return getEntry(leaderboardId, userId);
  }

  int getRank(String leaderboardId, String userId) {
    final entry = getEntry(leaderboardId, userId);
    return entry?.rank ?? 0;
  }

  Future<bool> submitScore({
    required String leaderboardId,
    required String userId,
    required String username,
    required double score,
    Map<String, dynamic>? stats,
  }) async {
    final leaderboard = _leaderboards[leaderboardId];
    if (leaderboard == null) return false;
    if (!leaderboard.isActive) return false;
    if (leaderboard.hasExpired) return false;

    final entry = LeaderboardEntry(
      userId: userId,
      username: username,
      rank: 0,
      score: score,
      stats: stats ?? {},
      lastUpdated: DateTime.now(),
      streak: 0,
    );

    final updated = Leaderboard(
      leaderboardId: leaderboard.leaderboardId,
      name: leaderboard.name,
      description: leaderboard.description,
      type: leaderboard.type,
      period: leaderboard.period,
      metric: leaderboard.metric,
      entries: [...leaderboard.entries, entry]
        ..sort((a, b) => b.score.compareTo(a.score))
        ..take(leaderboard.maxEntries)
        .toList(),
      startDate: leaderboard.startDate,
      endDate: leaderboard.endDate,
      maxEntries: leaderboard.maxEntries,
      lastUpdated: DateTime.now(),
      isActive: leaderboard.isActive,
    );

    _leaderboards[leaderboardId] = updated;

    for (int i = 0; i < updated.entries.length; i++) {
      final oldEntry = leaderboard.entries[i];
      final newEntry = updated.entries[i];

      if (oldEntry.userId != newEntry.userId || oldEntry.rank != i + 1) {
        final rankedEntry = LeaderboardEntry(
          userId: newEntry.userId,
          username: newEntry.username,
          avatar: newEntry.avatar,
          rank: i + 1,
          score: newEntry.score,
          stats: newEntry.stats,
          lastUpdated: newEntry.lastUpdated,
          streak: newEntry.streak,
        );

        updated.entries[i] = rankedEntry;
      }
    }

    _leaderboards[leaderboardId] = updated;

    _eventController.add(LeaderboardEvent(
      type: LeaderboardEventType.scoreSubmitted,
      leaderboardId: leaderboardId,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'score': score},
    ));

    return true;
  }

  List<LeaderboardReward> getRewards(String leaderboardId) {
    return _rewards[leaderboardId] ?? [];
  }

  LeaderboardReward? getReward(String leaderboardId, int rank) {
    final rewards = getRewards(leaderboardId);
    for (final reward in rewards) {
      if (rank >= reward.rankStart && rank <= reward.rankEnd) {
        return reward;
      }
    }
    return null;
  }

  Leaderboard createLeaderboard({
    required String leaderboardId,
    required String name,
    required String description,
    required LeaderboardType type,
    required LeaderboardPeriod period,
    required String metric,
    DateTime? startDate,
    DateTime? endDate,
    int maxEntries = 100,
  }) {
    final leaderboard = Leaderboard(
      leaderboardId: leaderboardId,
      name: name,
      description: description,
      type: type,
      period: period,
      metric: metric,
      entries: [],
      startDate: startDate,
      endDate: endDate,
      maxEntries: maxEntries,
      lastUpdated: DateTime.now(),
      isActive: true,
    );

    _leaderboards[leaderboardId] = leaderboard;

    _eventController.add(LeaderboardEvent(
      type: LeaderboardEventType.leaderboardCreated,
      leaderboardId: leaderboardId,
      timestamp: DateTime.now(),
    ));

    return leaderboard;
  }

  Map<String, dynamic> getLeaderboardStats(String leaderboardId) {
    final leaderboard = _leaderboards[leaderboardId];
    if (leaderboard == null) return {};

    return {
      'totalEntries': leaderboard.entries.length,
      'maxEntries': leaderboard.maxEntries,
      'lastUpdated': leaderboard.lastUpdated.toIso8601String(),
      'isActive': leaderboard.isActive,
      'hasExpired': leaderboard.hasExpired,
    };
  }

  void dispose() {
    _refreshTimer?.cancel();
    _eventController.close();
  }
}

class LeaderboardEvent {
  final LeaderboardEventType type;
  final String? leaderboardId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const LeaderboardEvent({
    required this.type,
    this.leaderboardId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum LeaderboardEventType {
  leaderboardCreated,
  leaderboardUpdated,
  leaderboardExpired,
  scoreSubmitted,
  rankChanged,
  rewardClaimed,
}

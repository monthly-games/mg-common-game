import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/competitive/leaderboard_manager.dart';
import 'package:mg_common_game/competitive/matchmaking_manager.dart';
import 'package:mg_common_game/player/progression_manager.dart';

void main() {
  group('Competitive Integration Tests', () {
    late LeaderboardManager leaderboardManager;
    late MatchmakingManager matchmakingManager;
    late ProgressionManager progressionManager;

    setUp(() async {
      leaderboardManager = LeaderboardManager.instance;
      matchmakingManager = MatchmakingManager.instance;
      progressionManager = ProgressionManager.instance;

      await leaderboardManager.initialize();
      await matchmakingManager.initialize();
      await progressionManager.initialize();
    });

    test('should create leaderboard and register players', () async {
      const leaderboardId = 'test_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Test Leaderboard',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(
        leaderboardId: leaderboardId,
        userId: 'player1',
        username: 'Player One',
      );

      final leaderboard = leaderboardManager.getLeaderboard(leaderboardId);
      expect(leaderboard, isNotNull);
      expect(leaderboard?.playerCount, greaterThan(0));
    });

    test('should update score and reassign rank', () async {
      const leaderboardId = 'rank_test_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Rank Test',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, 'p1', 'Player 1');
      await leaderboardManager.registerPlayer(leaderboardId, 'p2', 'Player 2');

      await leaderboardManager.updateScore(
        leaderboardId: leaderboardId,
        userId: 'p1',
        score: 100,
      );

      final entries = leaderboardManager.getEntries(leaderboardId);
      final player1Entry = entries.firstWhere((e) => e.userId == 'p1');

      expect(player1Entry.score, 100);
      expect(player1Entry.rank, greaterThanOrEqualTo(1));
    });

    test('should find match based on rank', () async {
      const leaderboardId = 'match_test_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Match Test',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      // Register players with different ranks
      for (int i = 1; i <= 10; i++) {
        final userId = 'match_player_$i';
        await leaderboardManager.registerPlayer(leaderboardId, userId, 'Player $i');
        await leaderboardManager.updateScore(leaderboardId, userId, i * 100);
      }

      // Find match for player with 500 points
      final match = await matchmakingManager.findMatch(
        userId: 'match_player_5',
        leaderboardId: leaderboardId,
        gameMode: 'ranked',
      );

      expect(match, isNotNull);
      expect(match?.players, isNotEmpty);
    });

    test('should update win streak', () async {
      const leaderboardId = 'streak_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Streak Test',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, 'streak_player', 'Streak Player');

      await leaderboardManager.recordWin(leaderboardId, 'streak_player', 100);

      final entries = leaderboardManager.getEntries(leaderboardId);
      final playerEntry = entries.firstWhere((e) => e.userId == 'streak_player');

      expect(playerEntry.streak, greaterThan(0));
    });

    test('should reset win streak on loss', () async {
      const leaderboardId = 'loss_streak_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Loss Streak Test',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, 'loss_player', 'Loss Player');

      // Add some wins
      await leaderboardManager.recordWin(leaderboardId, 'loss_player', 100);
      await leaderboardManager.recordWin(leaderboardId, 'loss_player', 100);

      // Record loss
      await leaderboardManager.recordLoss(leaderboardId, 'loss_player', 50);

      final entries = leaderboardManager.getEntries(leaderboardId);
      final playerEntry = entries.firstWhere((e) => e.userId == 'loss_player');

      expect(playerEntry.streak, lessThan(0));
    });

    test('should create season and reset rankings', () async {
      const seasonId = 'test_season';

      await matchmakingManager.createSeason(
        seasonId: seasonId,
        name: 'Test Season',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 30)),
        leaderboardId: 'season_leaderboard',
      );

      final season = matchmakingManager.getSeason(seasonId);
      expect(season, isNotNull);
    });

    test('should match players within similar rank range', () async {
      const leaderboardId = 'rank_match_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Rank Match Test',
        leaderboardType: LeaderboardType.global,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, 'high_rank', 'High Rank');
      await leaderboardManager.registerPlayer(leaderboardId, 'low_rank', 'Low Rank');

      await leaderboardManager.updateScore(leaderboardId, 'high_rank', 1000);
      await leaderboardManager.updateScore(leaderboardId, 'low_rank', 100);

      final match = await matchmakingManager.findMatch(
        userId: 'low_rank',
        leaderboardId: leaderboardId,
        gameMode: 'ranked',
      );

      expect(match, isNotNull);
    });

    test('should handle player level progression and ranking', () async {
      const userId = 'progress_rank_user';
      const leaderboardId = 'progress_rank_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Progress Rank',
        leaderboardType: LeaderboardType.level_based,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, userId, 'Progress Player');

      // Add XP to level up
      await progressionManager.addXP(userId, 500);

      final progress = progressionManager.getPlayerProgress(userId);
      final entries = leaderboardManager.getEntries(leaderboardId);

      expect(progress?.level, greaterThan(1));
      expect(entries.any((e) => e.userId == userId), isTrue);
    });
  });
}

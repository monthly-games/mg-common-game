import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/competitive/leaderboard_manager.dart';
import 'package:mg_common_game/competitive/matchmaking_manager.dart';
import 'package:mg_common_game/player/progression_manager.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/player/currency_manager.dart';

void main() {
  group('Battle & Competitive Golden Test', () {
    late LeaderboardManager leaderboardManager;
    late MatchmakingManager matchmakingManager;
    late ProgressionManager progressionManager;
    late InventoryManager inventoryManager;
    late CurrencyManager currencyManager;

    setUp(() async {
      leaderboardManager = LeaderboardManager.instance;
      matchmakingManager = MatchmakingManager.instance;
      progressionManager = ProgressionManager.instance;
      inventoryManager = InventoryManager.instance;
      currencyManager = CurrencyManager.instance;

      await leaderboardManager.initialize();
      await matchmakingManager.initialize();
      await progressionManager.initialize();
      await inventoryManager.initialize(maxSlots: 100);
      await currencyManager.initialize();
    });

    test('complete ranked match flow', () async {
      const player1Id = 'ranked_player_1';
      const player2Id = 'ranked_player_2';
      const leaderboardId = 'ranked_season_1';

      // Create ranked leaderboard
      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Ranked Season 1',
        leaderboardType: LeaderboardType.seasonal,
        scoringType: ScoringType.points,
        seasonId: 'season_2024_1',
      );

      // Register both players
      await leaderboardManager.registerPlayer(leaderboardId, player1Id, 'Player One');
      await leaderboardManager.registerPlayer(leaderboardId, player2Id, 'Player Two');

      // Both players play matches and gain points
      for (int i = 0; i < 10; i++) {
        await leaderboardManager.updateScore(
          leaderboardId: leaderboardId,
          userId: player1Id,
          score: 100 * (i + 1),
        );
        await leaderboardManager.updateScore(
          leaderboardId: leaderboardId,
          userId: player2Id,
          score: 90 * (i + 1),
        );
      }

      // Check rankings
      final entries = leaderboardManager.getEntries(leaderboardId);
      expect(entries, isNotEmpty);

      final player1Entry = entries.firstWhere((e) => e.userId == player1Id);
      final player2Entry = entries.firstWhere((e) => e.userId == player2Id);

      expect(player1Entry.rank, notEqual(player2Entry.rank));
    });

    test('tournament progression flow', () async {
      const tournamentId = 'tournament_championship_2024';

      // Create tournament
      await matchmakingManager.createSeason(
        seasonId: tournamentId,
        name: 'Championship 2024',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 30)),
        leaderboardId: 'tournament_leaderboard',
      );

      // Register 8 players for tournament
      final players = List.generate(8, (i) => 'tournament_player_$i');

      for (final player in players) {
        await leaderboardManager.registerPlayer(
          'tournament_leaderboard',
          player,
          'Player $i',
        );
      }

      // Simulate tournament rounds
      for (int round = 0; round < 3; round++) {
        for (final player in players) {
          final score = (round + 1) * 100 + (player.hashCode % 50);
          await leaderboardManager.updateScore(
            leaderboardId: 'tournament_leaderboard',
            userId: player,
            score: score.toDouble(),
          );
        }
      }

      // Verify tournament standings
      final finalEntries = leaderboardManager.getEntries('tournament_leaderboard');
      expect(finalEntries.length, greaterThanOrEqualTo(players.length));

      // Award prizes to top 3
      final top3 = finalEntries.take(3).toList();
      expect(top3.length, 3);

      // Give prizes
      for (int i = 0; i < top3.length; i++) {
        final prizeAmount = [1000, 500, 250][i];
        await currencyManager.addCurrency(
          userId: top3[i].userId,
          currencyId: 'gems',
          amount: prizeAmount,
        );
      }
    });

    test('win streak bonus flow', () async {
      const playerId = 'streak_bonus_player';
      const leaderboardId = 'streak_bonus_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Streak Bonus Challenge',
        leaderboardType: LeaderboardType.event,
        scoringType: ScoringType.points,
      );

      await leaderboardManager.registerPlayer(leaderboardId, playerId, 'Streak Player');

      // Build up a win streak
      for (int i = 0; i < 5; i++) {
        await leaderboardManager.recordWin(leaderboardId, playerId, 100);
      }

      final entries = leaderboardManager.getEntries(leaderboardId);
      final playerEntry = entries.firstWhere((e) => e.userId == playerId);

      expect(playerEntry.streak, 5);

      // Award streak bonus
      if (playerEntry.streak >= 5) {
        await currencyManager.addCurrency(
          userId: playerId,
          currencyId: 'gold',
          amount: 500, // Streak bonus
        );
      }

      final goldBalance = currencyManager.getBalance(playerId, 'gold');
      expect(goldBalance, greaterThanOrEqualTo(500));
    });

    test('matchmaking by skill level', () async {
      const leaderboardId = 'skill_match_leaderboard';

      await leaderboardManager.createLeaderboard(
        leaderboardId: leaderboardId,
        name: 'Skill Based Matchmaking',
        leaderboardType: LeaderboardType.rank_based,
        scoringType: ScoringType.mmr,
      );

      // Create players with different skill levels
      final beginners = ['beginner_1', 'beginner_2', 'beginner_3'];
      final intermediates = ['intermediate_1', 'intermediate_2', 'intermediate_3'];
      final experts = ['expert_1', 'expert_2', 'expert_3'];

      // Register and score players
      for (final player in beginners) {
        await leaderboardManager.registerPlayer(leaderboardId, player, player);
        await leaderboardManager.updateScore(leaderboardId, player, 500);
      }

      for (final player in intermediates) {
        await leaderboardManager.registerPlayer(leaderboardId, player, player);
        await leaderboardManager.updateScore(leaderboardId, player, 1500);
      }

      for (final player in experts) {
        await leaderboardManager.registerPlayer(leaderboardId, player, player);
        await leaderboardManager.updateScore(leaderboardId, player, 3000);
      }

      // Find match for beginner (should match with other beginners)
      final beginnerMatch = await matchmakingManager.findMatch(
        userId: 'beginner_1',
        leaderboardId: leaderboardId,
        gameMode: 'ranked',
      );

      expect(beginnerMatch, isNotNull);
      expect(beginnerMatch?.players, isNotEmpty);
    });

    test('season transition and reset flow', () async {
      const season1Id = 'season_1_2024';
      const season2Id = 'season_2_2024';
      const playerId = 'season_player';

      // Create season 1
      await matchmakingManager.createSeason(
        seasonId: season1Id,
        name: 'Season 1',
        startTime: DateTime.now().subtract(const Duration(days: 90)),
        endTime: DateTime.now().subtract(const Duration(days: 1)),
        leaderboardId: 'season1_leaderboard',
      );

      await leaderboardManager.createLeaderboard(
        leaderboardId: 'season1_leaderboard',
        name: 'Season 1 Leaderboard',
        leaderboardType: LeaderboardType.seasonal,
        scoringType: ScoringType.points,
        seasonId: season1Id,
      );

      // Player achieves rank in season 1
      await leaderboardManager.registerPlayer('season1_leaderboard', playerId, 'Season Player');
      await leaderboardManager.updateScore('season1_leaderboard', playerId, 5000);

      final season1Stats = progressionManager.getProgressionStats(playerId);
      expect(season1Stats, isNotNull);

      // Create season 2
      await matchmakingManager.createSeason(
        seasonId: season2Id,
        name: 'Season 2',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 90)),
        leaderboardId: 'season2_leaderboard',
      );

      await leaderboardManager.createLeaderboard(
        leaderboardId: 'season2_leaderboard',
        name: 'Season 2 Leaderboard',
        leaderboardType: LeaderboardType.seasonal,
        scoringType: ScoringType.points,
        seasonId: season2Id,
      );

      // Register for season 2 (score should reset)
      await leaderboardManager.registerPlayer('season2_leaderboard', playerId, 'Season Player');

      final season2Entries = leaderboardManager.getEntries('season2_leaderboard');
      final playerEntry = season2Entries.firstWhere((e) => e.userId == playerId);

      expect(playerEntry.score, 0); // Should start fresh
    });
  });
}

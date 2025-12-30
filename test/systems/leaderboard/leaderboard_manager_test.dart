import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/leaderboard/leaderboard.dart';

void main() {
  group('LeaderboardConfig', () {
    test('기본 생성', () {
      const config = LeaderboardConfig(
        id: 'high_score',
        name: 'High Score',
      );

      expect(config.id, 'high_score');
      expect(config.name, 'High Score');
      expect(config.timeScope, LeaderboardTimeScope.allTime);
      expect(config.scope, LeaderboardScope.global);
      expect(config.sortOrder, ScoreSortOrder.descending);
      expect(config.maxEntries, 100);
    });

    test('JSON 직렬화', () {
      const config = LeaderboardConfig(
        id: 'daily_score',
        name: 'Daily Score',
        timeScope: LeaderboardTimeScope.daily,
        scope: LeaderboardScope.friends,
        sortOrder: ScoreSortOrder.ascending,
        maxEntries: 50,
      );

      final json = config.toJson();
      final restored = LeaderboardConfig.fromJson(json);

      expect(restored.id, config.id);
      expect(restored.name, config.name);
      expect(restored.timeScope, config.timeScope);
      expect(restored.scope, config.scope);
      expect(restored.sortOrder, config.sortOrder);
      expect(restored.maxEntries, config.maxEntries);
    });
  });

  group('LeaderboardEntry', () {
    test('기본 생성', () {
      final entry = LeaderboardEntry(
        odId: 'user1',
        displayName: 'Player1',
        score: 1000,
        rank: 1,
        submittedAt: DateTime(2024, 1, 1),
      );

      expect(entry.odId, 'user1');
      expect(entry.displayName, 'Player1');
      expect(entry.score, 1000);
      expect(entry.rank, 1);
      expect(entry.isCurrentPlayer, false);
    });

    test('copyWith', () {
      final entry = LeaderboardEntry(
        odId: 'user1',
        displayName: 'Player1',
        score: 1000,
        rank: 5,
        submittedAt: DateTime(2024, 1, 1),
      );

      final updated = entry.copyWith(score: 2000, rank: 1);

      expect(updated.score, 2000);
      expect(updated.rank, 1);
      expect(updated.odId, entry.odId);
    });

    test('JSON 직렬화', () {
      final entry = LeaderboardEntry(
        odId: 'user1',
        displayName: 'Player1',
        score: 1000,
        rank: 1,
        submittedAt: DateTime(2024, 1, 1),
        metadata: {'level': 10},
      );

      final json = entry.toJson();
      final restored = LeaderboardEntry.fromJson(json);

      expect(restored.odId, entry.odId);
      expect(restored.displayName, entry.displayName);
      expect(restored.score, entry.score);
      expect(restored.rank, entry.rank);
    });

    test('toString', () {
      final entry = LeaderboardEntry(
        odId: 'user1',
        displayName: 'Player1',
        score: 1000,
        rank: 1,
        submittedAt: DateTime(2024, 1, 1),
      );

      expect(entry.toString(), 'LeaderboardEntry(#1 Player1: 1000)');
    });
  });

  group('LeaderboardData', () {
    late LeaderboardConfig config;
    late List<LeaderboardEntry> entries;

    setUp(() {
      config = const LeaderboardConfig(
        id: 'test',
        name: 'Test Leaderboard',
      );

      entries = List.generate(
        20,
        (i) => LeaderboardEntry(
          odId: 'user$i',
          displayName: 'Player$i',
          score: 1000 - i * 10,
          rank: i + 1,
          submittedAt: DateTime(2024, 1, 1),
        ),
      );
    });

    test('getTopEntries', () {
      final data = LeaderboardData(
        leaderboardId: 'test',
        config: config,
        entries: entries,
        lastUpdated: DateTime.now(),
      );

      final top5 = data.getTopEntries(5);
      expect(top5.length, 5);
      expect(top5.first.rank, 1);
      expect(top5.last.rank, 5);
    });

    test('getEntriesAroundPlayer', () {
      final data = LeaderboardData(
        leaderboardId: 'test',
        config: config,
        entries: entries,
        lastUpdated: DateTime.now(),
      );

      final around = data.getEntriesAroundPlayer('user10', range: 2);
      expect(around.length, 5); // 10번 ± 2 = 5명
      expect(around.first.odId, 'user8');
      expect(around.last.odId, 'user12');
    });

    test('getEntriesAroundPlayer - 시작 근처', () {
      final data = LeaderboardData(
        leaderboardId: 'test',
        config: config,
        entries: entries,
        lastUpdated: DateTime.now(),
      );

      final around = data.getEntriesAroundPlayer('user1', range: 3);
      expect(around.first.odId, 'user0');
    });

    test('getEntriesAroundPlayer - 존재하지 않는 유저', () {
      final data = LeaderboardData(
        leaderboardId: 'test',
        config: config,
        entries: entries,
        lastUpdated: DateTime.now(),
      );

      final around = data.getEntriesAroundPlayer('nonexistent', range: 3);
      expect(around, isEmpty);
    });
  });

  group('ScoreSubmitResult', () {
    test('success factory', () {
      final result = ScoreSubmitResult.success(
        newRank: 5,
        previousRank: 10,
        isNewHighScore: true,
      );

      expect(result.success, true);
      expect(result.newRank, 5);
      expect(result.previousRank, 10);
      expect(result.rankChange, 5);
      expect(result.isNewHighScore, true);
    });

    test('failure factory', () {
      final result = ScoreSubmitResult.failure('Connection error');

      expect(result.success, false);
      expect(result.errorMessage, 'Connection error');
    });
  });

  group('LeaderboardRewardTier', () {
    test('containsRank', () {
      const tier = LeaderboardRewardTier(
        minRank: 1,
        maxRank: 10,
        rewards: {'gold': 1000},
        title: 'Top 10',
      );

      expect(tier.containsRank(1), true);
      expect(tier.containsRank(5), true);
      expect(tier.containsRank(10), true);
      expect(tier.containsRank(11), false);
      expect(tier.containsRank(0), false);
    });

    test('JSON 직렬화', () {
      const tier = LeaderboardRewardTier(
        minRank: 1,
        maxRank: 3,
        rewards: {'gold': 1000, 'gems': 100},
        title: 'Podium',
      );

      final json = tier.toJson();
      final restored = LeaderboardRewardTier.fromJson(json);

      expect(restored.minRank, tier.minRank);
      expect(restored.maxRank, tier.maxRank);
      expect(restored.rewards, tier.rewards);
      expect(restored.title, tier.title);
    });
  });

  group('LeaderboardManager', () {
    late LeaderboardManager manager;

    setUp(() {
      manager = LeaderboardManager();
      manager.setPlayer('player1', displayName: 'TestPlayer');
    });

    tearDown(() {
      manager.dispose();
    });

    test('플레이어 설정', () {
      expect(manager.currentPlayerId, 'player1');
    });

    test('리더보드 등록', () {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      expect(manager.leaderboardIds, contains('score'));
      expect(manager.getConfig('score')?.name, 'High Score');
    });

    test('여러 리더보드 등록', () {
      manager.registerLeaderboards([
        const LeaderboardConfig(id: 'daily', name: 'Daily'),
        const LeaderboardConfig(id: 'weekly', name: 'Weekly'),
        const LeaderboardConfig(id: 'allTime', name: 'All Time'),
      ]);

      expect(manager.leaderboardIds.length, 3);
    });

    test('리더보드 등록 해제', () {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'temp',
        name: 'Temp',
      ));

      manager.unregisterLeaderboard('temp');

      expect(manager.getConfig('temp'), isNull);
    });

    test('점수 제출 - 로컬 모드', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      final result = await manager.submitScore('score', 1000);

      expect(result.success, true);
      expect(manager.getLocalHighScore('score'), 1000);
    });

    test('점수 제출 - 새 최고 점수', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 1000);
      final result = await manager.submitScore('score', 2000);

      expect(result.isNewPersonalBest, true);
      expect(manager.getLocalHighScore('score'), 2000);
    });

    test('점수 제출 - 낮은 점수는 최고 점수 아님', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 2000);
      final result = await manager.submitScore('score', 1000);

      expect(result.isNewPersonalBest, false);
      expect(manager.getLocalHighScore('score'), 2000);
    });

    test('점수 제출 - 오름차순 정렬 (시간 기록)', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'time',
        name: 'Best Time',
        sortOrder: ScoreSortOrder.ascending,
      ));

      await manager.submitScore('time', 100);
      final result = await manager.submitScore('time', 50);

      expect(result.isNewPersonalBest, true);
      expect(manager.getLocalHighScore('time'), 50);
    });

    test('점수 제출 - 플레이어 미설정', () async {
      final emptyManager = LeaderboardManager();
      emptyManager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      final result = await emptyManager.submitScore('score', 1000);

      expect(result.success, false);
      expect(result.errorMessage, contains('Player not set'));

      emptyManager.dispose();
    });

    test('점수 제출 - 미등록 리더보드', () async {
      final result = await manager.submitScore('nonexistent', 1000);

      expect(result.success, false);
      expect(result.errorMessage, contains('Leaderboard not found'));
    });

    test('로컬 리더보드 업데이트', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 1000);

      final cached = manager.getCachedData('score');
      expect(cached, isNotNull);
      expect(cached!.entries.length, 1);
      expect(cached.entries.first.odId, 'player1');
      expect(cached.entries.first.rank, 1);
    });

    test('테스트 엔트리 추가', () {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      manager.addTestEntry(
        'score',
        LeaderboardEntry(
          odId: 'bot1',
          displayName: 'Bot1',
          score: 500,
          rank: 0,
          submittedAt: DateTime.now(),
        ),
      );

      final cached = manager.getCachedData('score');
      expect(cached?.entries.length, 1);
      expect(cached?.entries.first.rank, 1);
    });

    test('순위 정렬 - 내림차순', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
        sortOrder: ScoreSortOrder.descending,
      ));

      manager.addTestEntry(
        'score',
        LeaderboardEntry(
          odId: 'bot1',
          displayName: 'Bot1',
          score: 500,
          rank: 0,
          submittedAt: DateTime.now(),
        ),
      );
      manager.addTestEntry(
        'score',
        LeaderboardEntry(
          odId: 'bot2',
          displayName: 'Bot2',
          score: 800,
          rank: 0,
          submittedAt: DateTime.now(),
        ),
      );

      await manager.submitScore('score', 600);

      final cached = manager.getCachedData('score');
      expect(cached!.entries[0].odId, 'bot2'); // 800
      expect(cached.entries[1].odId, 'player1'); // 600
      expect(cached.entries[2].odId, 'bot1'); // 500
    });

    test('순위 정렬 - 오름차순', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'time',
        name: 'Best Time',
        sortOrder: ScoreSortOrder.ascending,
      ));

      manager.addTestEntry(
        'time',
        LeaderboardEntry(
          odId: 'bot1',
          displayName: 'Bot1',
          score: 100,
          rank: 0,
          submittedAt: DateTime.now(),
        ),
      );

      await manager.submitScore('time', 50);

      final cached = manager.getCachedData('time');
      expect(cached!.entries[0].odId, 'player1'); // 50 (1등)
      expect(cached.entries[1].odId, 'bot1'); // 100 (2등)
    });

    test('범위 엔트리 가져오기', () {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      for (int i = 0; i < 20; i++) {
        manager.addTestEntry(
          'score',
          LeaderboardEntry(
            odId: 'user$i',
            displayName: 'Player$i',
            score: 1000 - i * 10,
            rank: 0,
            submittedAt: DateTime.now(),
          ),
        );
      }

      final range = manager.getEntriesInRange('score', 5, 10);
      expect(range.length, 6);
      expect(range.first.rank, 5);
      expect(range.last.rank, 10);
    });

    test('보상 티어 찾기', () {
      const tiers = [
        LeaderboardRewardTier(minRank: 1, maxRank: 1, rewards: {'gold': 1000}),
        LeaderboardRewardTier(minRank: 2, maxRank: 3, rewards: {'gold': 500}),
        LeaderboardRewardTier(minRank: 4, maxRank: 10, rewards: {'gold': 100}),
      ];

      expect(manager.getRewardTierForRank(tiers, 1)?.rewards['gold'], 1000);
      expect(manager.getRewardTierForRank(tiers, 2)?.rewards['gold'], 500);
      expect(manager.getRewardTierForRank(tiers, 3)?.rewards['gold'], 500);
      expect(manager.getRewardTierForRank(tiers, 5)?.rewards['gold'], 100);
      expect(manager.getRewardTierForRank(tiers, 11), isNull);
    });

    test('JSON 저장/복원', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 1000);

      final json = manager.toJson();

      final newManager = LeaderboardManager();
      newManager.fromJson(json);

      expect(newManager.currentPlayerId, 'player1');
      expect(newManager.getLocalHighScore('score'), 1000);

      newManager.dispose();
    });

    test('캐시 클리어', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 1000);
      expect(manager.getCachedData('score'), isNotNull);

      manager.clearCache();
      expect(manager.getCachedData('score'), isNull);
    });

    test('전체 클리어', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      await manager.submitScore('score', 1000);

      manager.clear();

      expect(manager.currentPlayerId, isNull);
      expect(manager.leaderboardIds, isEmpty);
      expect(manager.getLocalHighScore('score'), isNull);
    });

    test('ChangeNotifier 동작', () async {
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));

      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      await manager.submitScore('score', 1000);

      expect(notifyCount, greaterThan(0));
    });
  });

  group('LeaderboardManager - 백엔드 콜백', () {
    late LeaderboardManager manager;

    setUp(() {
      manager = LeaderboardManager();
      manager.setPlayer('player1', displayName: 'TestPlayer');
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
      ));
    });

    tearDown(() {
      manager.dispose();
    });

    test('점수 제출 콜백 성공', () async {
      manager.onSubmitScore = (id, score, metadata) async {
        return ScoreSubmitResult.success(
          newRank: 5,
          previousRank: 10,
          isNewHighScore: true,
        );
      };

      final result = await manager.submitScore('score', 1000);

      expect(result.success, true);
      expect(result.newRank, 5);
      expect(result.rankChange, 5);
    });

    test('점수 제출 콜백 실패 - 대기열 추가', () async {
      manager.onSubmitScore = (id, score, metadata) async {
        throw Exception('Network error');
      };

      final result = await manager.submitScore('score', 1000);

      expect(result.success, true);
      expect(result.errorMessage, contains('Offline'));
      expect(manager.pendingScoreCount, 1);
    });

    test('대기 중인 점수 제출', () async {
      // 먼저 오프라인으로 저장
      manager.onSubmitScore = (id, score, metadata) async {
        throw Exception('Network error');
      };

      await manager.submitScore('score', 1000);
      await manager.submitScore('score', 2000);

      expect(manager.pendingScoreCount, 2);

      // 온라인으로 전환
      manager.onSubmitScore = (id, score, metadata) async {
        return ScoreSubmitResult.success(newRank: 1);
      };

      final submitted = await manager.submitPendingScores();

      expect(submitted, 2);
      expect(manager.pendingScoreCount, 0);
    });

    test('리더보드 조회 콜백', () async {
      manager.onFetchLeaderboard = (id, {int limit = 100, LeaderboardScope? scope}) async {
        return LeaderboardData(
          leaderboardId: id,
          config: manager.getConfig(id)!,
          entries: [
            LeaderboardEntry(
              odId: 'user1',
              displayName: 'Player1',
              score: 1000,
              rank: 1,
              submittedAt: DateTime.now(),
            ),
          ],
          lastUpdated: DateTime.now(),
          totalPlayers: 100,
        );
      };

      final data = await manager.fetchLeaderboard('score');

      expect(data, isNotNull);
      expect(data!.entries.length, 1);
      expect(data.totalPlayers, 100);
    });

    test('플레이어 엔트리 조회', () async {
      manager.onFetchPlayerEntry = (leaderboardId, odId) async {
        return LeaderboardEntry(
          odId: odId,
          displayName: 'Player',
          score: 500,
          rank: 50,
          submittedAt: DateTime.now(),
          isCurrentPlayer: true,
        );
      };

      final entry = await manager.fetchPlayerEntry('score');

      expect(entry, isNotNull);
      expect(entry!.rank, 50);
      expect(entry.isCurrentPlayer, true);
    });

    test('주변 순위 조회', () async {
      manager.onFetchEntriesAroundPlayer = (leaderboardId, odId, range) async {
        return List.generate(
          range * 2 + 1,
          (i) => LeaderboardEntry(
            odId: 'user${48 + i}',
            displayName: 'Player${48 + i}',
            score: 520 - i * 10,
            rank: 48 + i,
            submittedAt: DateTime.now(),
          ),
        );
      };

      final entries = await manager.fetchEntriesAroundPlayer('score', range: 5);

      expect(entries.length, 11);
    });

    test('캐시 사용 여부', () async {
      int callCount = 0;

      manager.onFetchLeaderboard = (id, {int limit = 100, LeaderboardScope? scope}) async {
        callCount++;
        return LeaderboardData(
          leaderboardId: id,
          config: manager.getConfig(id)!,
          entries: [],
          lastUpdated: DateTime.now(),
        );
      };

      // 첫 호출
      await manager.fetchLeaderboard('score');
      expect(callCount, 1);

      // 캐시 사용
      await manager.fetchLeaderboard('score', useCache: true);
      expect(callCount, 1);

      // 캐시 미사용
      await manager.fetchLeaderboard('score', useCache: false);
      expect(callCount, 2);
    });
  });

  group('LeaderboardManager - maxEntries 제한', () {
    late LeaderboardManager manager;

    setUp(() {
      manager = LeaderboardManager();
      manager.setPlayer('player1', displayName: 'TestPlayer');
      manager.registerLeaderboard(const LeaderboardConfig(
        id: 'score',
        name: 'High Score',
        maxEntries: 10,
      ));
    });

    tearDown(() {
      manager.dispose();
    });

    test('최대 엔트리 수 제한', () {
      // 15개 엔트리 추가
      for (int i = 0; i < 15; i++) {
        manager.addTestEntry(
          'score',
          LeaderboardEntry(
            odId: 'user$i',
            displayName: 'Player$i',
            score: 1000 - i * 10,
            rank: 0,
            submittedAt: DateTime.now(),
          ),
        );
      }

      final cached = manager.getCachedData('score');
      expect(cached!.entries.length, 10);
    });
  });
}

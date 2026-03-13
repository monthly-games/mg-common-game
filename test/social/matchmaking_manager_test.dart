import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/social/matchmaking_manager.dart';

void main() {
  group('MatchmakingManager', () {
    late MatchmakingManager matchmaker;

    setUp(() {
      matchmaker = MatchmakingManager.instance;
    });

    test('매칭 요청', () async {
      final request = MatchRequest(
        id: 'req_001',
        userId: 'user_001',
        username: '테스터',
        gameMode: 'ranked',
        rating: 1200,
        requestedAt: DateTime.now(),
      );

      await matchmaker.requestMatch(request);

      final active = matchmaker.getActiveRequest('user_001');
      expect(active, isNotNull);
      expect(active?.userId, 'user_001');
    });

    test('ELO 등급 계산', () {
      const currentRating = 1500;
      const opponentRating = 1600;

      final newRatingWin = matchmaker.calculateNewRating(
        currentRating: currentRating,
        won: true,
        opponentRating: opponentRating,
      );

      final newRatingLoss = matchmaker.calculateNewRating(
        currentRating: currentRating,
        won: false,
        opponentRating: opponentRating,
      );

      expect(newRatingWin, greaterThan(currentRating));
      expect(newRatingLoss, lessThan(currentRating));
    });

    test('티어 계산', () {
      expect(matchmaker.getTierForRating(0), MatchTier.bronze);
      expect(matchmaker.getTierForRating(1200), MatchTier.silver);
      expect(matchmaker.getTierForRating(1600), MatchTier.gold);
      expect(matchmaker.getTierForRating(2000), MatchTier.platinum);
      expect(matchmaker.getTierForRating(2400), MatchTier.diamond);
      expect(matchmaker.getTierForRating(2800), MatchTier.master);
      expect(matchmaker.getTierForRating(3200), MatchTier.challenger);
    });

    test('자동 매칭', () async {
      // 비슷한 등급의 플레이어 2명 매칭 요청
      final request1 = MatchRequest(
        id: 'req_001',
        userId: 'user_001',
        username: '플레이어1',
        gameMode: 'ranked',
        rating: 1500,
        requestedAt: DateTime.now(),
      );

      final request2 = MatchRequest(
        id: 'req_002',
        userId: 'user_002',
        username: '플레이어2',
        gameMode: 'ranked',
        rating: 1520,
        requestedAt: DateTime.now(),
      );

      await matchmaker.requestMatch(request1);
      await matchmaker.requestMatch(request2);

      final match = await matchmaker.findMatch(
        userId: 'user_001',
        timeout: const Duration(seconds: 5),
      );

      expect(match, isNotNull);
    });

    test('매칭 취소', () async {
      final request = MatchRequest(
        id: 'req_001',
        userId: 'user_001',
        username: '테스터',
        gameMode: 'ranked',
        rating: 1500,
        requestedAt: DateTime.now(),
      );

      await matchmaker.requestMatch(request);

      final cancelled = await matchmaker.cancelMatch('user_001');
      expect(cancelled, true);

      final active = matchmaker.getActiveRequest('user_001');
      expect(active, isNull);
    });

    test('매치 결과 기록', () async {
      await matchmaker.recordMatchResult(
        matchId: 'match_001',
        winnerId: 'user_001',
        loserId: 'user_002',
        winnerRating: 1500,
        loserRating: 1450,
        duration: const Duration(minutes: 15),
      );

      final winnerStats = matchmaker.getPlayerStats('user_001');
      final loserStats = matchmaker.getPlayerStats('user_002');

      expect(winnerStats?.wins, 1);
      expect(loserStats?.losses, 1);
    });

    test('랭킹 조회', () async {
      // 여러 플레이어 결과 기록
      for (int i = 1; i <= 10; i++) {
        await matchmaker.recordMatchResult(
          matchId: 'match_$i',
          winnerId: 'user_00$i',
          loserId: 'user_00${i + 1}',
          winnerRating: 1500 + (i * 10),
          loserRating: 1400 + (i * 10),
          duration: const Duration(minutes: 10),
        );
      }

      final rankings = matchmaker.getRankings(
        gameMode: 'ranked',
        limit: 10,
      );

      expect(rankings.length, greaterThan(0));
    });

    test('레디 체크', () async {
      final matchId = 'match_001';

      // 플레이어 레디 상태 설정
      await matchmaker.setPlayerReady(matchId, 'user_001', true);
      await matchmaker.setPlayerReady(matchId, 'user_002', true);

      final allReady = await matchmaker.checkAllReady(matchId);
      expect(allReady, true);
    });
  });
}

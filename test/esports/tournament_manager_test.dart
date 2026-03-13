import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/esports/tournament_manager.dart';

void main() {
  group('TournamentManager', () {
    late EsportsManager esportsManager;

    setUp(() async {
      esportsManager = EsportsManager.instance;
      await esportsManager.initialize();
    });

    test('토너먼트 생성', () async {
      final tournament = await esportsManager.createTournament(
        name: '테스트 토너먼트',
        description: '테스트용 토너먼트',
        format: TournamentFormat.singleElimination,
        startDate: DateTime.now().add(const Duration(days: 7)),
        maxParticipants: 16,
        prizePool: 1000000,
      );

      expect(tournament.id, startsWith('tournament_'));
      expect(tournament.name, '테스트 토너먼트');
      expect(tournament.format, TournamentFormat.singleElimination);
      expect(tournament.status, TournamentStatus.registration);
    });

    test('참가자 등록', () async {
      final tournament = await esportsManager.createTournament(
        name: '참가자 테스트',
        description: '',
        format: TournamentFormat.singleElimination,
        startDate: DateTime.now().add(const Duration(days: 7)),
      );

      final participant = const TournamentParticipant(
        id: 'player_001',
        name: '테스터',
        seed: 1,
      );

      await esportsManager.registerParticipant(
        tournamentId: tournament.id,
        participant: participant,
      );

      final updated = esportsManager.getTournament(tournament.id);
      expect(updated?.participants.length, 1);
    });

    test('브래킷 생성', () async {
      final tournament = await esportsManager.createTournament(
        name: '브래킷 테스트',
        description: '',
        format: TournamentFormat.singleElimination,
        startDate: DateTime.now().add(const Duration(days: 7)),
      );

      // 4명 참가
      for (int i = 1; i <= 4; i++) {
        await esportsManager.registerParticipant(
          tournamentId: tournament.id,
          participant: TournamentParticipant(
            id: 'player_$i',
            name: '플레이어$i',
            seed: i,
          ),
        );
      }

      final updated = esportsManager.getTournament(tournament.id);
      final bracket = updated?.generateBracket();

      expect(bracket?.length, 2); // 4명 = 2매치
    });

    test('매치 업데이트', () async {
      final tournament = await esportsManager.createTournament(
        name: '매치 업데이트 테스트',
        description: '',
        format: TournamentFormat.singleElimination,
        startDate: DateTime.now().add(const Duration(days: 7)),
      );

      // 참가자 등록
      await esportsManager.registerParticipant(
        tournamentId: tournament.id,
        participant: const TournamentParticipant(
          id: 'player_001',
          name: '플레이어1',
        ),
      );

      await esportsManager.registerParticipant(
        tournamentId: tournament.id,
        participant: const TournamentParticipant(
          id: 'player_002',
          name: '플레이어2',
        ),
      );

      final updated = esportsManager.getTournament(tournament.id);

      // 첫 번째 매치 업데이트
      if (updated?.matches.isNotEmpty == true) {
        await esportsManager.updateMatch(
          tournamentId: tournament.id,
          matchId: updated!.matches.first.id,
          result: MatchResult.team1Win,
          team1Score: 2,
          team2Score: 1,
        );

        final finalUpdated = esportsManager.getTournament(tournament.id);
        expect(finalUpdated?.matches.first.result, MatchResult.team1Win);
      }
    });

    test('순위 계산', () async {
      final tournament = await esportsManager.createTournament(
        name: '순위 계산 테스트',
        description: '',
        format: TournamentFormat.roundRobin,
        startDate: DateTime.now().add(const Duration(days: 7)),
      );

      // 참가자 등록
      for (int i = 1; i <= 3; i++) {
        await esportsManager.registerParticipant(
          tournamentId: tournament.id,
          participant: TournamentParticipant(
            id: 'player_$i',
            name: '플레이어$i',
            seed: i,
            stats: {'wins': 3 - i}, // 역순으로 승수
          ),
        );
      }

      final updated = esportsManager.getTournament(tournament.id);
      final standings = updated?.calculateStandings();

      expect(standings?.first.stats['wins'], 2); // 가장 많은 승수
    });

    test('토너먼트 스트림', () async {
      final tournament = await esportsManager.createTournament(
        name: '스트림 테스트',
        description: '',
        format: TournamentFormat.singleElimination,
        startDate: DateTime.now().add(const Duration(days: 7)),
      );

      bool eventReceived = false;
      final subscription = esportsManager.onTournamentUpdate.listen((t) {
        if (t.id == tournament.id) {
          eventReceived = true;
        }
      });

      await esportsManager.registerParticipant(
        tournamentId: tournament.id,
        participant: const TournamentParticipant(
          id: 'player_001',
          name: '테스터',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(eventReceived, true);

      await subscription.cancel();
    });

    test('매치 결과 변환', () {
      const match = TournamentMatch(
        id: 'match_001',
        roundId: 'round_001',
        team1: TournamentParticipant(id: 't1', name: '팀1'),
        team2: TournamentParticipant(id: 't2', name: '팀2'),
        scheduledTime: DateTime(2024),
        result: MatchResult.team1Win,
        team1Score: 2,
        team2Score: 1,
      );

      final bracketData = match.toBracketData();

      expect(bracketData['match_id'], 'match_001');
      expect(bracketData['team1_id'], 't1');
      expect(bracketData['team2_id'], 't2');
      expect(bracketData['winner'], 't1');
    });
  });
}

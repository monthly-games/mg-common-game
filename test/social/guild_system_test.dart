import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/social/guild_system.dart';

void main() {
  group('GuildSystem', () {
    late GuildManager guildManager;

    setUp(() {
      guildManager = GuildManager.instance;
    });

    test('길드 생성', () async {
      final guild = await guildManager.createGuild(
        userId: 'user_001',
        name: '테스트 길드',
        description: '테스트용 길드입니다',
        emblemUrl: 'https://example.com/emblem.png',
      );

      expect(guild, isNotNull);
      expect(guild?.name, '테스트 길드');
      expect(guild?.leaderId, 'user_001');
      expect(guild?.members.length, 1);
    });

    test('길드 가입 신청', () async {
      // 길드 생성
      final guild = await guildManager.createGuild(
        userId: 'user_001',
        name: '테스트 길드',
        description: '테스트용 길드',
        emblemUrl: '',
      );

      expect(guild, isNotNull);

      // 가입 신청
      await guildManager.applyToGuild(
        guildId: guild!.id,
        userId: 'user_002',
        username: '테스터2',
        message: '가입하고 싶습니다',
      );

      final updatedGuild = guildManager.getGuild(guild.id);
      expect(updatedGuild?.pendingApplications.length, 1);
      expect(updatedGuild?.pendingApplications.first.userId, 'user_002');
    });

    test('길드 가입 승인', () async {
      // 길드 생성
      final guild = await guildManager.createGuild(
        userId: 'user_001',
        name: '테스트 길드',
        description: '테스트용 길드',
        emblemUrl: '',
      );

      // 가입 신청
      await guildManager.applyToGuild(
        guildId: guild!.id,
        userId: 'user_002',
        username: '테스터2',
        message: '가입하고 싶습니다',
      );

      // 가입 승인
      await guildManager.approveApplication(
        guildId: guild.id,
        userId: 'user_002',
        approvedBy: 'user_001',
      );

      final updatedGuild = guildManager.getGuild(guild.id);
      expect(updatedGuild?.members.length, 2);
      expect(updatedGuild?.pendingApplications.length, 0);
    });

    test('길드원 추방', () async {
      // 길드 생성
      final guild = await guildManager.createGuild(
        userId: 'user_001',
        name: '테스트 길드',
        description: '테스트용 길드',
        emblemUrl: '',
      );

      // 멤버 추가
      await guildManager.addMember(
        guildId: guild!.id,
        userId: 'user_002',
        username: '테스터2',
        role: GuildMemberRole.member,
      );

      expect(guildManager.getGuild(guild.id)?.members.length, 2);

      // 추방
      await guildManager.kickMember(
        guildId: guild.id,
        userId: 'user_002',
        kickedBy: 'user_001',
      );

      expect(guildManager.getGuild(guild.id)?.members.length, 1);
    });

    test('길드 전 선전', () async {
      // 두 길드 생성
      final guild1 = await guildManager.createGuild(
        userId: 'user_001',
        name: '길드1',
        description: '첫번째 길드',
        emblemUrl: '',
      );

      final guild2 = await guildManager.createGuild(
        userId: 'user_002',
        name: '길드2',
        description: '두번째 길드',
        emblemUrl: '',
      );

      // 전쟁 선언
      final warId = await guildManager.declareWar(
        guildId1: guild1!.id,
        guildId2: guild2!.id,
        startTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(warId, isNotNull);

      final war = guildManager.getGuildWar(warId!);
      expect(war, isNotNull);
      expect(war?.guild1Id, guild1.id);
      expect(war?.guild2Id, guild2.id);
    });

    test('길드 전 기록', () async {
      // 길드 생성 및 전쟁
      final guild1 = await guildManager.createGuild(
        userId: 'user_001',
        name: '길드1',
        description: '첫번째 길드',
        emblemUrl: '',
      );

      final guild2 = await guildManager.createGuild(
        userId: 'user_002',
        name: '길드2',
        description: '두번째 길드',
        emblemUrl: '',
      );

      final warId = await guildManager.declareWar(
        guildId1: guild1!.id,
        guildId2: guild2!.id,
        startTime: DateTime.now().add(const Duration(hours: 1)),
      );

      // 전쟁 기록
      await guildManager.recordWarResult(
        warId: warId!,
        winnerGuildId: guild1.id,
        results: {
          'guild1_score': 100,
          'guild2_score': 80,
        },
      );

      final war = guildManager.getGuildWar(warId);
      expect(war?.winnerGuildId, guild1.id);
      expect(war?.status, GuildWarStatus.completed);
    });

    test('길드 랭킹', () async {
      // 여러 길드 생성
      for (int i = 1; i <= 5; i++) {
        await guildManager.createGuild(
          userId: 'user_00$i',
          name: '길드$i',
          description: '$i번째 길드',
          emblemUrl: '',
        );
      }

      final rankings = guildManager.getGuildRankings(limit: 10);
      expect(rankings.length, 5);
    });

    test('길드 해산', () async {
      final guild = await guildManager.createGuild(
        userId: 'user_001',
        name: '해산될 길드',
        description: '곧 해산',
        emblemUrl: '',
      );

      await guildManager.disbandGuild(
        guildId: guild!.id,
        userId: 'user_001',
      );

      final disbandedGuild = guildManager.getGuild(guild.id);
      expect(disbandedGuild, isNull);
    });
  });
}

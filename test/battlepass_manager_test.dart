import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_config.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_manager.dart';

void main() {
  group('BPSeasonConfig', () {
    test('28일 시즌 생성', () {
      final season = BPSeasonBuilder.create28DaySeason(
        id: 'season_1',
        nameKr: '시즌 1',
        startDate: DateTime.now(),
      );

      expect(season.maxLevel, 50);
      expect(season.totalDays, 28);
      expect(season.tiers.length, 50);
    });

    test('시즌 활성화 체크', () {
      final activeSeason = BPSeasonConfig(
        id: 'active',
        nameKr: '활성 시즌',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 27)),
        tiers: [],
      );

      expect(activeSeason.isActive, isTrue);
      // remainingDays는 시간대에 따라 26 또는 27이 될 수 있음
      expect(activeSeason.remainingDays, greaterThanOrEqualTo(26));
      expect(activeSeason.remainingDays, lessThanOrEqualTo(27));
    });

    test('티어 경험치 증가 (21+ 레벨)', () {
      final season = BPSeasonBuilder.create28DaySeason(
        id: 'test',
        nameKr: '테스트',
        startDate: DateTime.now(),
        expPerLevel: 1000,
      );

      expect(season.getTier(1)!.requiredExp, 1000);
      expect(season.getTier(25)!.requiredExp, 1500); // 1.5배
      expect(season.getTier(45)!.requiredExp, 2000); // 2배
    });
  });

  group('BattlePassManager', () {
    late BattlePassManager manager;
    late BPSeasonConfig season;

    setUp(() {
      manager = BattlePassManager();
      season = BPSeasonBuilder.create28DaySeason(
        id: 'test_season',
        nameKr: '테스트 시즌',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expPerLevel: 100, // 테스트용 낮은 값
      );

      manager.setSeason(season);
      manager.setMissions(
        daily: BPSeasonBuilder.createDefaultDailyMissions(),
        weekly: BPSeasonBuilder.createDefaultWeeklyMissions(),
      );
    });

    test('시즌 설정', () {
      expect(manager.currentSeason, isNotNull);
      expect(manager.currentLevel, 1);
      expect(manager.currentExp, 0);
    });

    test('경험치 추가', () {
      manager.addExp(50);
      expect(manager.currentExp, 50);
    });

    test('레벨업', () {
      manager.addExp(100);
      expect(manager.currentLevel, 2);
      expect(manager.currentExp, 0);
    });

    test('여러 레벨 동시 업', () {
      manager.addExp(350);
      expect(manager.currentLevel, 4);
      expect(manager.currentExp, 50);
    });

    test('최대 레벨 도달', () {
      manager.addExp(100000); // 큰 값
      expect(manager.currentLevel, 50);
      expect(manager.currentExp, 0); // 최대 레벨에서 캡
    });

    test('다음 레벨까지 경험치', () {
      manager.addExp(30);
      expect(manager.expToNextLevel, 70);
    });

    test('레벨 진행률', () {
      manager.addExp(50);
      expect(manager.levelProgress, 0.5);
    });

    test('보상 수령 가능 여부 - 무료', () {
      manager.addExp(100); // 레벨 2

      // 레벨 1에 무료 보상이 없으면 false, 있으면 true (5레벨마다 보상이 있음)
      // 레벨 5 미만이므로 무료 보상 없음
      expect(manager.canClaimReward(5, isPremiumReward: false), isFalse); // 아직 도달 안함
      expect(manager.canClaimReward(10, isPremiumReward: false), isFalse); // 아직 도달 안함
    });

    test('프리미엄 구매', () {
      expect(manager.isPremium, isFalse);

      manager.purchasePremium();

      expect(manager.isPremium, isTrue);
    });

    test('미션 진행도 업데이트', () {
      manager.incrementMissionProgress('login');

      final progress = manager.getMissionProgress('daily_login');
      expect(progress, 1.0); // 1/1 = 완료
    });

    test('미션 완료 체크', () {
      manager.incrementMissionProgress('login');

      expect(manager.isMissionCompleted('daily_login'), isTrue);
    });

    test('미션 보상 수령', () {
      manager.incrementMissionProgress('login');

      final claimed = manager.claimMissionReward('daily_login');
      expect(claimed, isTrue);
      // 미션 보상 100 exp -> 레벨업(100 exp 필요)하여 레벨 2, exp 0
      expect(manager.currentLevel, 2);
    });

    test('중복 보상 수령 불가', () {
      manager.incrementMissionProgress('login');
      manager.claimMissionReward('daily_login');

      final claimedAgain = manager.claimMissionReward('daily_login');
      expect(claimedAgain, isFalse);
    });

    test('일일 미션 리셋', () {
      manager.incrementMissionProgress('login');
      manager.claimMissionReward('daily_login');

      manager.resetDailyMissions();

      expect(manager.isMissionCompleted('daily_login'), isFalse);
    });

    test('JSON 직렬화/역직렬화', () {
      manager.addExp(250);
      manager.purchasePremium();

      final json = manager.toJson();

      final newManager = BattlePassManager();
      newManager.loadFromJson(json);

      expect(newManager.currentLevel, 3);
      expect(newManager.isPremium, isTrue);
    });

    test('시즌 종료', () {
      manager.endSeason();

      expect(manager.currentSeason, isNull);
      expect(manager.state, isNull);
    });
  });

  group('BPMission', () {
    test('미션 타입', () {
      const daily = BPMission(
        id: 'test',
        titleKr: '테스트',
        descriptionKr: '설명',
        type: BPMissionType.daily,
        targetValue: 1,
        expReward: 100,
      );

      expect(daily.type, BPMissionType.daily);
    });
  });

  group('BPReward', () {
    test('보상 JSON 직렬화', () {
      const reward = BPReward(
        id: 'gold_100',
        nameKr: '골드',
        type: BPRewardType.currency,
        amount: 100,
      );

      final json = reward.toJson();
      final restored = BPReward.fromJson(json);

      expect(restored.id, reward.id);
      expect(restored.amount, 100);
    });
  });
}

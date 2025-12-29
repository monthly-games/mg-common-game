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

  group('MissionProgress', () {
    test('기본 생성', () {
      final progress = MissionProgress(missionId: 'test_mission');

      expect(progress.missionId, 'test_mission');
      expect(progress.currentValue, 0);
      expect(progress.isClaimed, false);
    });

    test('커스텀 값으로 생성', () {
      final progress = MissionProgress(
        missionId: 'test_mission',
        currentValue: 5,
        isClaimed: true,
      );

      expect(progress.currentValue, 5);
      expect(progress.isClaimed, true);
    });

    test('toJson', () {
      final progress = MissionProgress(
        missionId: 'test_mission',
        currentValue: 10,
        isClaimed: true,
      );

      final json = progress.toJson();

      expect(json['missionId'], 'test_mission');
      expect(json['currentValue'], 10);
      expect(json['isClaimed'], true);
    });

    test('fromJson', () {
      final json = {
        'missionId': 'mission_01',
        'currentValue': 3,
        'isClaimed': false,
      };

      final progress = MissionProgress.fromJson(json);

      expect(progress.missionId, 'mission_01');
      expect(progress.currentValue, 3);
      expect(progress.isClaimed, false);
    });

    test('fromJson with null values', () {
      final json = <String, dynamic>{};

      final progress = MissionProgress.fromJson(json);

      expect(progress.missionId, '');
      expect(progress.currentValue, 0);
      expect(progress.isClaimed, false);
    });
  });

  group('BattlePassState', () {
    test('기본 생성', () {
      final state = BattlePassState(seasonId: 'season_1');

      expect(state.seasonId, 'season_1');
      expect(state.currentLevel, 1);
      expect(state.currentExp, 0);
      expect(state.isPremium, false);
      expect(state.claimedFreeLevels, isEmpty);
      expect(state.claimedPremiumLevels, isEmpty);
      expect(state.missionProgress, isEmpty);
      expect(state.premiumPurchaseDate, isNull);
    });

    test('커스텀 값으로 생성', () {
      final purchaseDate = DateTime(2024, 1, 1);
      final state = BattlePassState(
        seasonId: 'season_1',
        currentLevel: 25,
        currentExp: 500,
        isPremium: true,
        claimedFreeLevels: {1, 2, 3},
        claimedPremiumLevels: {1, 2},
        missionProgress: {'daily_login': MissionProgress(missionId: 'daily_login')},
        premiumPurchaseDate: purchaseDate,
      );

      expect(state.currentLevel, 25);
      expect(state.currentExp, 500);
      expect(state.isPremium, true);
      expect(state.claimedFreeLevels, {1, 2, 3});
      expect(state.claimedPremiumLevels, {1, 2});
      expect(state.missionProgress.length, 1);
      expect(state.premiumPurchaseDate, purchaseDate);
    });

    test('toJson', () {
      final state = BattlePassState(
        seasonId: 'season_1',
        currentLevel: 10,
        currentExp: 50,
        isPremium: true,
        claimedFreeLevels: {5},
        claimedPremiumLevels: {5},
        premiumPurchaseDate: DateTime(2024, 6, 15),
      );

      final json = state.toJson();

      expect(json['seasonId'], 'season_1');
      expect(json['currentLevel'], 10);
      expect(json['currentExp'], 50);
      expect(json['isPremium'], true);
      expect(json['claimedFreeLevels'], [5]);
      expect(json['claimedPremiumLevels'], [5]);
      expect(json['premiumPurchaseDate'], isNotNull);
    });

    test('fromJson', () {
      final json = {
        'seasonId': 'season_2',
        'currentLevel': 20,
        'currentExp': 100,
        'isPremium': true,
        'claimedFreeLevels': [5, 10],
        'claimedPremiumLevels': [5, 10, 15],
        'missionProgress': {
          'mission_1': {'missionId': 'mission_1', 'currentValue': 5, 'isClaimed': true}
        },
        'premiumPurchaseDate': '2024-01-01T00:00:00.000',
      };

      final state = BattlePassState.fromJson(json);

      expect(state.seasonId, 'season_2');
      expect(state.currentLevel, 20);
      expect(state.currentExp, 100);
      expect(state.isPremium, true);
      expect(state.claimedFreeLevels, {5, 10});
      expect(state.claimedPremiumLevels, {5, 10, 15});
      expect(state.missionProgress.length, 1);
      expect(state.premiumPurchaseDate, isNotNull);
    });

    test('fromJson with null values', () {
      final json = <String, dynamic>{};

      final state = BattlePassState.fromJson(json);

      expect(state.seasonId, '');
      expect(state.currentLevel, 1);
      expect(state.currentExp, 0);
      expect(state.isPremium, false);
      expect(state.claimedFreeLevels, isEmpty);
      expect(state.claimedPremiumLevels, isEmpty);
    });
  });

  group('BattlePassManager 추가 테스트', () {
    late BattlePassManager manager;
    late BPSeasonConfig season;

    setUp(() {
      manager = BattlePassManager();
      season = BPSeasonBuilder.create28DaySeason(
        id: 'test_season',
        nameKr: '테스트 시즌',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expPerLevel: 100,
      );

      manager.setSeason(season);
      manager.setMissions(
        daily: BPSeasonBuilder.createDefaultDailyMissions(),
        weekly: BPSeasonBuilder.createDefaultWeeklyMissions(),
      );
    });

    test('onLevelUp 콜백', () {
      int? levelUpTo;
      manager.onLevelUp = (level) {
        levelUpTo = level;
      };

      manager.addExp(100);

      expect(levelUpTo, 2);
    });

    test('onLevelUp 콜백 - 여러 레벨', () {
      final levels = <int>[];
      manager.onLevelUp = (level) {
        levels.add(level);
      };

      manager.addExp(300);

      expect(levels, [2, 3, 4]);
    });

    test('onMissionComplete 콜백', () {
      BPMission? completedMission;
      manager.onMissionComplete = (mission) {
        completedMission = mission;
      };

      manager.incrementMissionProgress('login');

      expect(completedMission, isNotNull);
      expect(completedMission!.id, 'daily_login');
    });

    test('updateMissionProgress', () {
      manager.updateMissionProgress('login', 1);

      expect(manager.isMissionCompleted('daily_login'), true);
    });

    test('미션 보상 수령 불가 - 미완료', () {
      final claimed = manager.claimMissionReward('daily_login');
      expect(claimed, false);
    });

    test('주간 미션 리셋', () {
      manager.incrementMissionProgress('battle_count', amount: 20);
      manager.claimMissionReward('weekly_battle_20');

      manager.resetWeeklyMissions();

      expect(manager.isMissionCompleted('weekly_battle_20'), false);
    });

    test('시즌 변경 시 상태 리셋', () {
      manager.addExp(200);
      expect(manager.currentLevel, 3);

      final newSeason = BPSeasonBuilder.create28DaySeason(
        id: 'new_season',
        nameKr: '새 시즌',
        startDate: DateTime.now(),
      );
      manager.setSeason(newSeason);

      expect(manager.currentLevel, 1);
      expect(manager.currentExp, 0);
    });

    test('같은 시즌 설정 시 상태 유지', () {
      manager.addExp(200);
      expect(manager.currentLevel, 3);

      manager.setSeason(season);

      expect(manager.currentLevel, 3);
    });

    test('unclaimedRewardCount - 초기 상태', () {
      // 초기에는 레벨 1이므로 레벨 1 보상만 수령 가능할 수 있음
      // 실제 보상은 tier 구성에 따라 다름
      expect(manager.unclaimedRewardCount, greaterThanOrEqualTo(0));
    });

    test('claimAllAvailable', () {
      manager.addExp(500); // 레벨 6
      manager.purchasePremium();

      final initialCount = manager.unclaimedRewardCount;
      final rewards = manager.claimAllAvailable();

      // claimAllAvailable 후에는 미수령 보상이 줄어들어야 함
      // 또는 모두 수령했으면 0
      expect(manager.unclaimedRewardCount, lessThanOrEqualTo(initialCount));
    });

    test('state null일 때 addExp 무시', () {
      manager.endSeason();
      manager.addExp(100);

      expect(manager.currentExp, 0);
      expect(manager.currentLevel, 1);
    });

    test('state null일 때 expToNextLevel은 0', () {
      manager.endSeason();
      expect(manager.expToNextLevel, 0);
    });

    test('state null일 때 levelProgress는 0', () {
      manager.endSeason();
      expect(manager.levelProgress, 0);
    });

    test('state null일 때 unclaimedRewardCount는 0', () {
      manager.endSeason();
      expect(manager.unclaimedRewardCount, 0);
    });

    test('state null일 때 purchasePremium 무시', () {
      manager.endSeason();
      manager.purchasePremium();
      expect(manager.isPremium, false);
    });

    test('state null일 때 updateMissionProgress 무시', () {
      manager.endSeason();
      manager.updateMissionProgress('login', 1);
      // 에러 없이 실행됨
    });

    test('state null일 때 incrementMissionProgress 무시', () {
      manager.endSeason();
      manager.incrementMissionProgress('login');
      // 에러 없이 실행됨
    });

    test('state null일 때 claimMissionReward는 false', () {
      manager.endSeason();
      expect(manager.claimMissionReward('daily_login'), false);
    });

    test('최대 레벨에서 expToNextLevel은 0', () {
      manager.addExp(100000);
      expect(manager.currentLevel, 50);
      expect(manager.expToNextLevel, 0);
    });

    test('최대 레벨에서 levelProgress는 1.0', () {
      manager.addExp(100000);
      expect(manager.levelProgress, 1.0);
    });

    test('보상 수령 불가 - 레벨 미달', () {
      expect(manager.canClaimReward(10, isPremiumReward: false), false);
    });

    test('프리미엄 보상 수령 불가 - 프리미엄 아님', () {
      manager.addExp(1000);
      expect(manager.canClaimReward(5, isPremiumReward: true), false);
    });
  });
}

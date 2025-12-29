import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/idle/idle_achievements.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('IdleAchievementCategory', () {
    test('모든 카테고리 정의', () {
      expect(IdleAchievementCategory.values.length, 7);
      expect(IdleAchievementCategory.collection, isNotNull);
      expect(IdleAchievementCategory.playtime, isNotNull);
      expect(IdleAchievementCategory.prestige, isNotNull);
      expect(IdleAchievementCategory.clicking, isNotNull);
      expect(IdleAchievementCategory.upgrades, isNotNull);
      expect(IdleAchievementCategory.milestone, isNotNull);
      expect(IdleAchievementCategory.secret, isNotNull);
    });

    test('카테고리 인덱스', () {
      expect(IdleAchievementCategory.collection.index, 0);
      expect(IdleAchievementCategory.playtime.index, 1);
      expect(IdleAchievementCategory.prestige.index, 2);
      expect(IdleAchievementCategory.clicking.index, 3);
      expect(IdleAchievementCategory.upgrades.index, 4);
      expect(IdleAchievementCategory.milestone.index, 5);
      expect(IdleAchievementCategory.secret.index, 6);
    });
  });

  group('AchievementTier', () {
    test('모든 티어 정의', () {
      expect(AchievementTier.values.length, 5);
      expect(AchievementTier.bronze, isNotNull);
      expect(AchievementTier.silver, isNotNull);
      expect(AchievementTier.gold, isNotNull);
      expect(AchievementTier.platinum, isNotNull);
      expect(AchievementTier.diamond, isNotNull);
    });

    test('티어 인덱스', () {
      expect(AchievementTier.bronze.index, 0);
      expect(AchievementTier.silver.index, 1);
      expect(AchievementTier.gold.index, 2);
      expect(AchievementTier.platinum.index, 3);
      expect(AchievementTier.diamond.index, 4);
    });
  });

  group('AchievementReward', () {
    test('기본 생성자', () {
      const reward = AchievementReward(type: 'gems', amount: 50);
      expect(reward.type, 'gems');
      expect(reward.amount, 50);
      expect(reward.resourceId, isNull);
    });

    test('resourceId 포함 생성자', () {
      const reward = AchievementReward(
        type: 'resource',
        amount: 100,
        resourceId: 'gold',
      );
      expect(reward.type, 'resource');
      expect(reward.amount, 100);
      expect(reward.resourceId, 'gold');
    });

    test('미리 정의된 상수 - gems10', () {
      expect(AchievementReward.gems10.type, 'gems');
      expect(AchievementReward.gems10.amount, 10);
    });

    test('미리 정의된 상수 - gems25', () {
      expect(AchievementReward.gems25.type, 'gems');
      expect(AchievementReward.gems25.amount, 25);
    });

    test('미리 정의된 상수 - gems50', () {
      expect(AchievementReward.gems50.type, 'gems');
      expect(AchievementReward.gems50.amount, 50);
    });

    test('미리 정의된 상수 - gems100', () {
      expect(AchievementReward.gems100.type, 'gems');
      expect(AchievementReward.gems100.amount, 100);
    });

    test('gold 팩토리', () {
      final reward = AchievementReward.gold(500);
      expect(reward.type, 'gold');
      expect(reward.amount, 500);
    });

    test('multiplier 팩토리', () {
      final reward = AchievementReward.multiplier(1.5);
      expect(reward.type, 'multiplier');
      expect(reward.amount, 150); // 1.5 * 100
    });

    test('multiplier 정수 값', () {
      final reward = AchievementReward.multiplier(2.0);
      expect(reward.amount, 200);
    });

    test('multiplier 소수 값', () {
      final reward = AchievementReward.multiplier(0.25);
      expect(reward.amount, 25);
    });
  });

  group('IdleAchievementConfig', () {
    test('기본 생성자', () {
      const config = IdleAchievementConfig(
        id: 'test_achievement',
        name: 'Test Achievement',
        description: 'Test description',
        category: IdleAchievementCategory.collection,
      );

      expect(config.id, 'test_achievement');
      expect(config.name, 'Test Achievement');
      expect(config.description, 'Test description');
      expect(config.category, IdleAchievementCategory.collection);
    });

    test('기본값', () {
      const config = IdleAchievementConfig(
        id: 'test',
        name: 'Test',
        description: 'Test',
        category: IdleAchievementCategory.milestone,
      );

      expect(config.tier, AchievementTier.bronze);
      expect(config.icon, Icons.emoji_events);
      expect(config.targetValue, 1);
      expect(config.isHidden, false);
      expect(config.reward, isNull);
      expect(config.prestigeBonus, 0);
      expect(config.prerequisites, isEmpty);
    });

    test('커스텀 값', () {
      const config = IdleAchievementConfig(
        id: 'custom',
        name: 'Custom',
        description: 'Custom achievement',
        category: IdleAchievementCategory.secret,
        tier: AchievementTier.gold,
        icon: Icons.star,
        targetValue: 1000,
        isHidden: true,
        reward: AchievementReward.gems50,
        prestigeBonus: 5,
        prerequisites: ['prereq_1', 'prereq_2'],
      );

      expect(config.tier, AchievementTier.gold);
      expect(config.icon, Icons.star);
      expect(config.targetValue, 1000);
      expect(config.isHidden, true);
      expect(config.reward, isNotNull);
      expect(config.prestigeBonus, 5);
      expect(config.prerequisites, ['prereq_1', 'prereq_2']);
    });

    group('tierColor', () {
      test('bronze 색상', () {
        const config = IdleAchievementConfig(
          id: 'bronze',
          name: 'Bronze',
          description: 'Bronze tier',
          category: IdleAchievementCategory.collection,
          tier: AchievementTier.bronze,
        );
        expect(config.tierColor, const Color(0xFFCD7F32));
      });

      test('silver 색상', () {
        const config = IdleAchievementConfig(
          id: 'silver',
          name: 'Silver',
          description: 'Silver tier',
          category: IdleAchievementCategory.collection,
          tier: AchievementTier.silver,
        );
        expect(config.tierColor, const Color(0xFFC0C0C0));
      });

      test('gold 색상', () {
        const config = IdleAchievementConfig(
          id: 'gold',
          name: 'Gold',
          description: 'Gold tier',
          category: IdleAchievementCategory.collection,
          tier: AchievementTier.gold,
        );
        expect(config.tierColor, const Color(0xFFFFD700));
      });

      test('platinum 색상', () {
        const config = IdleAchievementConfig(
          id: 'platinum',
          name: 'Platinum',
          description: 'Platinum tier',
          category: IdleAchievementCategory.collection,
          tier: AchievementTier.platinum,
        );
        expect(config.tierColor, const Color(0xFFE5E4E2));
      });

      test('diamond 색상', () {
        const config = IdleAchievementConfig(
          id: 'diamond',
          name: 'Diamond',
          description: 'Diamond tier',
          category: IdleAchievementCategory.collection,
          tier: AchievementTier.diamond,
        );
        expect(config.tierColor, const Color(0xFFB9F2FF));
      });
    });
  });

  group('IdleAchievementState', () {
    test('기본 생성자', () {
      final state = IdleAchievementState(id: 'test');

      expect(state.id, 'test');
      expect(state.currentProgress, 0);
      expect(state.isUnlocked, false);
      expect(state.unlockedAt, isNull);
      expect(state.rewardClaimed, false);
    });

    test('커스텀 값 생성', () {
      final now = DateTime.now();
      final state = IdleAchievementState(
        id: 'custom',
        currentProgress: 50,
        isUnlocked: true,
        unlockedAt: now,
        rewardClaimed: true,
      );

      expect(state.id, 'custom');
      expect(state.currentProgress, 50);
      expect(state.isUnlocked, true);
      expect(state.unlockedAt, now);
      expect(state.rewardClaimed, true);
    });

    test('toJson', () {
      final now = DateTime.now();
      final state = IdleAchievementState(
        id: 'test',
        currentProgress: 100,
        isUnlocked: true,
        unlockedAt: now,
        rewardClaimed: true,
      );

      final json = state.toJson();

      expect(json['id'], 'test');
      expect(json['currentProgress'], 100);
      expect(json['isUnlocked'], true);
      expect(json['unlockedAt'], now.millisecondsSinceEpoch);
      expect(json['rewardClaimed'], true);
    });

    test('toJson - unlockedAt null', () {
      final state = IdleAchievementState(id: 'test');
      final json = state.toJson();

      expect(json['unlockedAt'], isNull);
    });

    test('fromJson', () {
      final now = DateTime.now();
      final json = {
        'id': 'test',
        'currentProgress': 75,
        'isUnlocked': true,
        'unlockedAt': now.millisecondsSinceEpoch,
        'rewardClaimed': false,
      };

      final state = IdleAchievementState.fromJson(json);

      expect(state.id, 'test');
      expect(state.currentProgress, 75);
      expect(state.isUnlocked, true);
      expect(state.unlockedAt!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(state.rewardClaimed, false);
    });

    test('fromJson - 기본값', () {
      final json = {'id': 'test'};
      final state = IdleAchievementState.fromJson(json);

      expect(state.id, 'test');
      expect(state.currentProgress, 0);
      expect(state.isUnlocked, false);
      expect(state.unlockedAt, isNull);
      expect(state.rewardClaimed, false);
    });

    test('round-trip 직렬화', () {
      final now = DateTime.now();
      final original = IdleAchievementState(
        id: 'roundtrip',
        currentProgress: 200,
        isUnlocked: true,
        unlockedAt: now,
        rewardClaimed: true,
      );

      final json = original.toJson();
      final restored = IdleAchievementState.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.currentProgress, original.currentProgress);
      expect(restored.isUnlocked, original.isUnlocked);
      expect(restored.unlockedAt!.millisecondsSinceEpoch,
          original.unlockedAt!.millisecondsSinceEpoch);
      expect(restored.rewardClaimed, original.rewardClaimed);
    });

    test('mutable 상태 변경', () {
      final state = IdleAchievementState(id: 'mutable');

      state.currentProgress = 50;
      expect(state.currentProgress, 50);

      state.isUnlocked = true;
      expect(state.isUnlocked, true);

      final now = DateTime.now();
      state.unlockedAt = now;
      expect(state.unlockedAt, now);

      state.rewardClaimed = true;
      expect(state.rewardClaimed, true);
    });
  });

  group('IdleAchievementManager', () {
    late IdleAchievementManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = IdleAchievementManager();
      await manager.initialize();
    });

    tearDown(() async {
      await manager.reset();
      manager.dispose();
    });

    group('초기 상태', () {
      test('초기 업적 없음', () {
        expect(manager.allAchievements, isEmpty);
      });

      test('초기 해금 업적 없음', () {
        expect(manager.unlockedAchievements, isEmpty);
      });

      test('초기 포인트 0', () {
        expect(manager.totalAchievementPoints, 0);
      });

      test('초기 완료율 0', () {
        expect(manager.completionPercentage, 0);
      });
    });

    group('업적 등록', () {
      test('registerAchievement 동작', () {
        const config = IdleAchievementConfig(
          id: 'test',
          name: 'Test',
          description: 'Test',
          category: IdleAchievementCategory.collection,
        );

        manager.registerAchievement(config);

        expect(manager.allAchievements.length, 1);
        expect(manager.allAchievements[0].id, 'test');
      });

      test('registerAchievements 동작', () {
        final configs = [
          const IdleAchievementConfig(
            id: 'test1',
            name: 'Test 1',
            description: 'Test 1',
            category: IdleAchievementCategory.collection,
          ),
          const IdleAchievementConfig(
            id: 'test2',
            name: 'Test 2',
            description: 'Test 2',
            category: IdleAchievementCategory.clicking,
          ),
        ];

        manager.registerAchievements(configs);

        expect(manager.allAchievements.length, 2);
      });

      test('registerCommonAchievements 동작', () {
        manager.registerCommonAchievements();

        // 최소 10개 이상의 공통 업적이 등록되어야 함
        expect(manager.allAchievements.length, greaterThanOrEqualTo(10));
      });

      test('같은 ID 재등록시 상태 유지', () {
        const config = IdleAchievementConfig(
          id: 'test',
          name: 'Test',
          description: 'Test',
          category: IdleAchievementCategory.collection,
          targetValue: 100,
        );

        manager.registerAchievement(config);
        manager.updateProgress('test', 50);

        // 같은 ID로 재등록
        manager.registerAchievement(config);

        // 상태 유지
        expect(manager.getProgress('test'), 50);
      });
    });

    group('카테고리별 조회', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'col1',
            name: 'Collection 1',
            description: 'Collection',
            category: IdleAchievementCategory.collection,
          ),
          const IdleAchievementConfig(
            id: 'col2',
            name: 'Collection 2',
            description: 'Collection',
            category: IdleAchievementCategory.collection,
          ),
          const IdleAchievementConfig(
            id: 'click1',
            name: 'Click 1',
            description: 'Click',
            category: IdleAchievementCategory.clicking,
          ),
        ]);
      });

      test('getByCategory - collection', () {
        final achievements = manager.getByCategory(IdleAchievementCategory.collection);
        expect(achievements.length, 2);
        expect(achievements.every((a) => a.category == IdleAchievementCategory.collection), true);
      });

      test('getByCategory - clicking', () {
        final achievements = manager.getByCategory(IdleAchievementCategory.clicking);
        expect(achievements.length, 1);
        expect(achievements[0].id, 'click1');
      });

      test('getByCategory - 빈 카테고리', () {
        final achievements = manager.getByCategory(IdleAchievementCategory.secret);
        expect(achievements, isEmpty);
      });
    });

    group('진행 상황', () {
      setUp(() {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'progress_test',
          name: 'Progress Test',
          description: 'Test progress',
          category: IdleAchievementCategory.collection,
          targetValue: 100,
        ));
      });

      test('updateProgress 동작', () {
        manager.updateProgress('progress_test', 50);
        expect(manager.getProgress('progress_test'), 50);
      });

      test('incrementProgress 동작', () {
        manager.incrementProgress('progress_test');
        expect(manager.getProgress('progress_test'), 1);

        manager.incrementProgress('progress_test', 10);
        expect(manager.getProgress('progress_test'), 11);
      });

      test('getProgressPercentage 동작', () {
        expect(manager.getProgressPercentage('progress_test'), 0.0);

        manager.updateProgress('progress_test', 50);
        expect(manager.getProgressPercentage('progress_test'), 0.5);

        manager.updateProgress('progress_test', 100);
        expect(manager.getProgressPercentage('progress_test'), 1.0);
      });

      test('존재하지 않는 업적 진행', () {
        manager.updateProgress('non_existent', 50);
        expect(manager.getProgress('non_existent'), 0);
      });

      test('존재하지 않는 업적 퍼센티지', () {
        expect(manager.getProgressPercentage('non_existent'), 0);
      });
    });

    group('업적 해금', () {
      setUp(() {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'unlock_test',
          name: 'Unlock Test',
          description: 'Test unlock',
          category: IdleAchievementCategory.collection,
          targetValue: 100,
          reward: AchievementReward.gems50,
        ));
      });

      test('목표 달성시 자동 해금', () {
        expect(manager.isUnlocked('unlock_test'), false);

        manager.updateProgress('unlock_test', 100);

        expect(manager.isUnlocked('unlock_test'), true);
      });

      test('목표 초과시 해금', () {
        manager.updateProgress('unlock_test', 150);
        expect(manager.isUnlocked('unlock_test'), true);
      });

      test('forceUnlock 동작', () {
        manager.forceUnlock('unlock_test');
        expect(manager.isUnlocked('unlock_test'), true);
      });

      test('해금 콜백 호출', () {
        IdleAchievementConfig? unlockedConfig;
        IdleAchievementState? unlockedState;

        manager.onAchievementUnlocked = (config, state) {
          unlockedConfig = config;
          unlockedState = state;
        };

        manager.updateProgress('unlock_test', 100);

        expect(unlockedConfig, isNotNull);
        expect(unlockedConfig!.id, 'unlock_test');
        expect(unlockedState, isNotNull);
        expect(unlockedState!.isUnlocked, true);
      });

      test('이미 해금된 업적은 진행 무시', () {
        manager.updateProgress('unlock_test', 100);
        expect(manager.isUnlocked('unlock_test'), true);

        // 이미 해금된 상태에서 추가 진행 시도
        manager.updateProgress('unlock_test', 50);
        // 진행은 변경되지 않음 (해금 상태 유지)
        expect(manager.isUnlocked('unlock_test'), true);
      });
    });

    group('선행 조건', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'prereq',
            name: 'Prerequisite',
            description: 'Prerequisite',
            category: IdleAchievementCategory.collection,
            targetValue: 50,
          ),
          const IdleAchievementConfig(
            id: 'dependent',
            name: 'Dependent',
            description: 'Dependent on prereq',
            category: IdleAchievementCategory.collection,
            targetValue: 100,
            prerequisites: ['prereq'],
          ),
        ]);
      });

      test('선행 조건 미충족시 진행 안됨', () {
        manager.updateProgress('dependent', 100);
        expect(manager.isUnlocked('dependent'), false);
      });

      test('선행 조건 충족 후 진행 가능', () {
        // 선행 조건 충족
        manager.updateProgress('prereq', 50);
        expect(manager.isUnlocked('prereq'), true);

        // 이제 dependent 진행 가능
        manager.updateProgress('dependent', 100);
        expect(manager.isUnlocked('dependent'), true);
      });
    });

    group('보상', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'with_reward',
            name: 'With Reward',
            description: 'Has reward',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
            reward: AchievementReward.gems50,
          ),
          const IdleAchievementConfig(
            id: 'no_reward',
            name: 'No Reward',
            description: 'No reward',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
        ]);
      });

      test('해금 전 보상 수령 불가', () {
        final reward = manager.claimReward('with_reward');
        expect(reward, isNull);
      });

      test('해금 후 보상 수령', () {
        manager.forceUnlock('with_reward');

        final reward = manager.claimReward('with_reward');
        expect(reward, isNotNull);
        expect(reward!.type, 'gems');
        expect(reward.amount, 50);
      });

      test('중복 보상 수령 불가', () {
        manager.forceUnlock('with_reward');

        final reward1 = manager.claimReward('with_reward');
        expect(reward1, isNotNull);

        final reward2 = manager.claimReward('with_reward');
        expect(reward2, isNull);
      });

      test('보상 없는 업적 수령 시도', () {
        manager.forceUnlock('no_reward');
        final reward = manager.claimReward('no_reward');
        expect(reward, isNull);
      });

      test('achievementsWithUnclaimedRewards', () {
        manager.forceUnlock('with_reward');
        manager.forceUnlock('no_reward');

        final unclaimed = manager.achievementsWithUnclaimedRewards;
        expect(unclaimed.length, 1);
        expect(unclaimed[0].id, 'with_reward');
      });

      test('claimAllRewards 동작', () {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'reward2',
          name: 'Reward 2',
          description: 'Another reward',
          category: IdleAchievementCategory.collection,
          targetValue: 10,
          reward: AchievementReward.gems25,
        ));

        manager.forceUnlock('with_reward');
        manager.forceUnlock('reward2');

        final rewards = manager.claimAllRewards();
        expect(rewards.length, 2);
      });

      test('보상 수령 콜백', () {
        IdleAchievementConfig? callbackConfig;
        AchievementReward? callbackReward;

        manager.onRewardClaimed = (config, reward) {
          callbackConfig = config;
          callbackReward = reward;
        };

        manager.forceUnlock('with_reward');
        manager.claimReward('with_reward');

        expect(callbackConfig, isNotNull);
        expect(callbackConfig!.id, 'with_reward');
        expect(callbackReward, isNotNull);
        expect(callbackReward!.amount, 50);
      });
    });

    group('포인트 계산', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'bronze_ach',
            name: 'Bronze',
            description: 'Bronze tier',
            category: IdleAchievementCategory.collection,
            tier: AchievementTier.bronze,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'silver_ach',
            name: 'Silver',
            description: 'Silver tier',
            category: IdleAchievementCategory.collection,
            tier: AchievementTier.silver,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'gold_ach',
            name: 'Gold',
            description: 'Gold tier',
            category: IdleAchievementCategory.collection,
            tier: AchievementTier.gold,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'platinum_ach',
            name: 'Platinum',
            description: 'Platinum tier',
            category: IdleAchievementCategory.collection,
            tier: AchievementTier.platinum,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'diamond_ach',
            name: 'Diamond',
            description: 'Diamond tier',
            category: IdleAchievementCategory.collection,
            tier: AchievementTier.diamond,
            targetValue: 10,
          ),
        ]);
      });

      test('bronze = 10 포인트', () {
        manager.forceUnlock('bronze_ach');
        expect(manager.totalAchievementPoints, 10);
      });

      test('silver = 25 포인트', () {
        manager.forceUnlock('silver_ach');
        expect(manager.totalAchievementPoints, 25);
      });

      test('gold = 50 포인트', () {
        manager.forceUnlock('gold_ach');
        expect(manager.totalAchievementPoints, 50);
      });

      test('platinum = 100 포인트', () {
        manager.forceUnlock('platinum_ach');
        expect(manager.totalAchievementPoints, 100);
      });

      test('diamond = 200 포인트', () {
        manager.forceUnlock('diamond_ach');
        expect(manager.totalAchievementPoints, 200);
      });

      test('총 포인트 합산', () {
        manager.forceUnlock('bronze_ach');
        manager.forceUnlock('silver_ach');
        manager.forceUnlock('gold_ach');

        // 10 + 25 + 50 = 85
        expect(manager.totalAchievementPoints, 85);
      });
    });

    group('완료율', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'ach1',
            name: 'Ach 1',
            description: 'Ach 1',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'ach2',
            name: 'Ach 2',
            description: 'Ach 2',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'ach3',
            name: 'Ach 3',
            description: 'Ach 3',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'ach4',
            name: 'Ach 4',
            description: 'Ach 4',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
        ]);
      });

      test('0% 완료', () {
        expect(manager.completionPercentage, 0.0);
      });

      test('25% 완료', () {
        manager.forceUnlock('ach1');
        expect(manager.completionPercentage, 0.25);
      });

      test('50% 완료', () {
        manager.forceUnlock('ach1');
        manager.forceUnlock('ach2');
        expect(manager.completionPercentage, 0.5);
      });

      test('100% 완료', () {
        manager.forceUnlock('ach1');
        manager.forceUnlock('ach2');
        manager.forceUnlock('ach3');
        manager.forceUnlock('ach4');
        expect(manager.completionPercentage, 1.0);
      });
    });

    group('숨김 업적', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'visible',
            name: 'Visible',
            description: 'Visible achievement',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
            isHidden: false,
          ),
          const IdleAchievementConfig(
            id: 'hidden',
            name: 'Hidden',
            description: 'Hidden achievement',
            category: IdleAchievementCategory.secret,
            targetValue: 10,
            isHidden: true,
          ),
        ]);
      });

      test('lockedAchievements에서 숨김 업적 제외', () {
        final locked = manager.lockedAchievements;
        expect(locked.length, 1);
        expect(locked[0].id, 'visible');
      });

      test('숨김 업적도 해금 가능', () {
        manager.forceUnlock('hidden');
        expect(manager.isUnlocked('hidden'), true);
      });

      test('해금된 숨김 업적은 unlockedAchievements에 포함', () {
        manager.forceUnlock('hidden');
        final unlocked = manager.unlockedAchievements;
        expect(unlocked.any((a) => a.id == 'hidden'), true);
      });
    });

    group('직렬화', () {
      setUp(() {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'save_test',
            name: 'Save Test',
            description: 'Save Test',
            category: IdleAchievementCategory.collection,
            targetValue: 100,
            reward: AchievementReward.gems25,
          ),
        ]);
      });

      test('toJson', () {
        manager.updateProgress('save_test', 50);

        final json = manager.toJson();

        expect(json['states'], isNotNull);
        expect(json['states'], isA<List>());
      });

      test('fromJson', () {
        final json = {
          'states': [
            {
              'id': 'save_test',
              'currentProgress': 75,
              'isUnlocked': false,
              'unlockedAt': null,
              'rewardClaimed': false,
            }
          ]
        };

        manager.fromJson(json);

        expect(manager.getProgress('save_test'), 75);
      });

      test('round-trip 직렬화', () {
        manager.updateProgress('save_test', 100);
        manager.claimReward('save_test');

        final json = manager.toJson();

        // 새 매니저 생성
        final newManager = IdleAchievementManager();
        newManager.registerAchievement(const IdleAchievementConfig(
          id: 'save_test',
          name: 'Save Test',
          description: 'Save Test',
          category: IdleAchievementCategory.collection,
          targetValue: 100,
          reward: AchievementReward.gems25,
        ));
        newManager.fromJson(json);

        expect(newManager.isUnlocked('save_test'), true);

        newManager.dispose();
      });
    });

    group('리셋', () {
      test('reset 동작', () async {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'reset_test',
          name: 'Reset Test',
          description: 'Reset Test',
          category: IdleAchievementCategory.collection,
          targetValue: 50,
        ));

        manager.forceUnlock('reset_test');
        expect(manager.isUnlocked('reset_test'), true);

        await manager.reset();

        expect(manager.isUnlocked('reset_test'), false);
        expect(manager.getProgress('reset_test'), 0);
      });
    });

    group('ChangeNotifier', () {
      test('updateProgress notifyListeners', () {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'notify_test',
          name: 'Notify Test',
          description: 'Notify Test',
          category: IdleAchievementCategory.collection,
          targetValue: 100,
        ));

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.updateProgress('notify_test', 50);
        expect(notifyCount, 1);
      });

      test('claimReward notifyListeners', () {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'notify_test',
          name: 'Notify Test',
          description: 'Notify Test',
          category: IdleAchievementCategory.collection,
          targetValue: 10,
          reward: AchievementReward.gems10,
        ));

        manager.forceUnlock('notify_test');

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.claimReward('notify_test');
        expect(notifyCount, 1);
      });

      test('fromJson notifyListeners', () {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        manager.fromJson({'states': []});
        expect(notifyCount, 1);
      });

      test('reset notifyListeners', () async {
        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        await manager.reset();
        expect(notifyCount, 1);
      });
    });

    group('toString', () {
      test('toString 포맷', () {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'ach1',
            name: 'Ach 1',
            description: 'Ach 1',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'ach2',
            name: 'Ach 2',
            description: 'Ach 2',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
        ]);

        manager.forceUnlock('ach1');

        final str = manager.toString();
        expect(str, contains('total: 2'));
        expect(str, contains('unlocked: 1'));
      });
    });

    group('Edge Cases', () {
      test('존재하지 않는 ID로 forceUnlock', () {
        expect(() => manager.forceUnlock('non_existent'), returnsNormally);
      });

      test('존재하지 않는 ID로 claimReward', () {
        final reward = manager.claimReward('non_existent');
        expect(reward, isNull);
      });

      test('존재하지 않는 ID로 incrementProgress', () {
        expect(() => manager.incrementProgress('non_existent'), returnsNormally);
      });

      test('빈 prerequisites', () {
        manager.registerAchievement(const IdleAchievementConfig(
          id: 'no_prereq',
          name: 'No Prerequisite',
          description: 'No prerequisites',
          category: IdleAchievementCategory.collection,
          targetValue: 10,
          prerequisites: [],
        ));

        manager.forceUnlock('no_prereq');
        expect(manager.isUnlocked('no_prereq'), true);
      });

      test('여러 prerequisites', () {
        manager.registerAchievements([
          const IdleAchievementConfig(
            id: 'prereq1',
            name: 'Prereq 1',
            description: 'Prereq 1',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'prereq2',
            name: 'Prereq 2',
            description: 'Prereq 2',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
          ),
          const IdleAchievementConfig(
            id: 'multi_prereq',
            name: 'Multi Prereq',
            description: 'Multiple prerequisites',
            category: IdleAchievementCategory.collection,
            targetValue: 10,
            prerequisites: ['prereq1', 'prereq2'],
          ),
        ]);

        // 하나만 충족
        manager.forceUnlock('prereq1');
        manager.updateProgress('multi_prereq', 10);
        expect(manager.isUnlocked('multi_prereq'), false);

        // 모두 충족
        manager.forceUnlock('prereq2');
        manager.updateProgress('multi_prereq', 10);
        expect(manager.isUnlocked('multi_prereq'), true);
      });
    });
  });
}

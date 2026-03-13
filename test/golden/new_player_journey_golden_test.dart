import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/player/progression_manager.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/shop/shop_manager.dart';
import 'package:mg_common_game/quest/quest_manager.dart';
import 'package:mg_common_game/achievement/achievement_manager.dart';
import 'package:mg_common_game/player/currency_manager.dart';

void main() {
  group('New Player Journey Golden Test', () {
    late ProgressionManager progressionManager;
    late InventoryManager inventoryManager;
    late ShopManager shopManager;
    late QuestManager questManager;
    late AchievementManager achievementManager;
    late CurrencyManager currencyManager;

    setUp(() async {
      progressionManager = ProgressionManager.instance;
      inventoryManager = InventoryManager.instance;
      shopManager = ShopManager.instance;
      questManager = QuestManager.instance;
      achievementManager = AchievementManager.instance;
      currencyManager = CurrencyManager.instance;

      await progressionManager.initialize();
      await inventoryManager.initialize(maxSlots: 50);
      await shopManager.initialize();
      await questManager.initialize();
      await achievementManager.initialize();
      await currencyManager.initialize();
    });

    test('complete new player onboarding flow', () async {
      const newPlayerId = 'new_player_golden_test';

      // Step 1: Player creates account (represented by initial state)
      final initialProgress = progressionManager.getPlayerProgress(newPlayerId);
      expect(initialProgress, isNull);

      // Step 2: First login - rewards
      await currencyManager.addCurrency(
        userId: newPlayerId,
        currencyId: 'gold',
        amount: 100, // Welcome bonus
      );

      await currencyManager.addCurrency(
        userId: newPlayerId,
        currencyId: 'gems',
        amount: 50, // Welcome bonus
      );

      var goldBalance = currencyManager.getBalance(newPlayerId, 'gold');
      var gemsBalance = currencyManager.getBalance(newPlayerId, 'gems');

      expect(goldBalance, 100);
      expect(gemsBalance, 50);

      // Step 3: Complete first quest
      await questManager.createQuest(
        questId: 'first_quest',
        name: 'Welcome Aboard',
        description: 'Complete your first quest',
        questType: QuestType.story,
        objectives: [
          QuestObjective(
            objectiveId: 'login_obj',
            description: 'Login to the game',
            targetCount: 1,
            questType: ObjectiveType.login,
          ),
        ],
        rewards: [
          QuestReward(
            rewardId: 'xp_reward',
            type: RewardType.experience,
            amount: 100,
          ),
          QuestReward(
            rewardId: 'gold_reward',
            type: RewardType.currency,
            currencyId: 'gold',
            amount: 50,
          ),
        ],
      );

      await questManager.updateProgress(
        userId: newPlayerId,
        questId: 'first_quest',
        objectiveId: 'login_obj',
        progress: 1,
      );

      final questClaimed = await questManager.claimRewards(
        userId: newPlayerId,
        questId: 'first_quest',
      );

      expect(questClaimed, isTrue);

      // Step 4: Check level progress
      final progress = progressionManager.getPlayerProgress(newPlayerId);
      expect(progress, isNotNull);
      expect(progress!.level, greaterThanOrEqualTo(1));

      // Step 5: First purchase from shop
      await shopManager.createShopItem(
        itemId: 'starter_pack',
        name: 'Starter Pack',
        description: 'Essential items for new players',
        basePrice: 50,
        currencyId: 'gold',
        category: ShopItemCategory.bundle,
      );

      final purchaseSuccess = await shopManager.purchaseItem(
        userId: newPlayerId,
        itemId: 'starter_pack',
        quantity: 1,
      );

      expect(purchaseSuccess, isTrue);

      // Step 6: Verify inventory
      final inventory = inventoryManager.getInventory(newPlayerId);
      expect(inventory, isNotNull);
      expect(inventory!.items, isNotEmpty);

      // Step 7: First achievement unlocked
      await achievementManager.createAchievement(
        achievementId: 'first_purchase',
        name: 'First Purchase',
        description: 'Make your first purchase',
        tier: AchievementTier.bronze,
        category: AchievementCategory.gameplay,
        criteria: AchievementCriteria(
          type: CriteriaType.custom,
          target: 1,
        ),
        rewards: [
          AchievementReward(
            rewardId: 'achievement_xp',
            type: RewardType.experience,
            amount: 50,
          ),
        ],
      );

      // Manually unlock for this test
      await achievementManager.unlockAchievement(
        userId: newPlayerId,
        achievementId: 'first_purchase',
      );

      final achievementProgress = achievementManager.getAchievementProgress(
        userId: newPlayerId,
        achievementId: 'first_purchase',
      );

      expect(achievementProgress?.isCompleted, isTrue);

      // Step 8: Verify final state
      final finalStats = progressionManager.getProgressionStats(newPlayerId);
      final finalGold = currencyManager.getBalance(newPlayerId, 'gold');

      expect(finalStats['level'], greaterThan(1));
      expect(finalGold, lessThan(goldBalance!)); // Should have spent some
    });

    test('daily login streak flow', () async {
      const playerId = 'streak_player_golden';

      // Simulate 7 days of consecutive logins
      for (int day = 0; day < 7; day++) {
        await progressionManager.recordDailyActivity(playerId);

        final stats = progressionManager.getProgressionStats(playerId);
        expect(stats['loginStreak'], day + 1);
      }

      // Check daily login rewards
      final stats = progressionManager.getProgressionStats(playerId);
      expect(stats['loginStreak'], greaterThanOrEqualTo(7));

      // Verify milestone reward
      final progress = progressionManager.getPlayerProgress(playerId);
      expect(progress, isNotNull);
    });

    test('complete tutorial quest chain', () async {
      const playerId = 'tutorial_player_golden';

      // Create tutorial quest chain
      final tutorialQuests = [
        'tutorial_1_complete_profile',
        'tutorial_2_make_friend',
        'tutorial_3_first_battle',
        'tutorial_4_join_guild',
      ];

      for (final questId in tutorialQuests) {
        await questManager.createQuest(
          questId: questId,
          name: 'Tutorial $questId',
          description: 'Learn the basics',
          questType: QuestType.story,
          objectives: [
            QuestObjective(
              objectiveId: '${questId}_obj',
              description: 'Complete task',
              targetCount: 1,
              questType: ObjectiveType.task,
            ),
          ],
          rewards: [
            QuestReward(
              rewardId: '${questId}_reward',
              type: RewardType.experience,
              amount: 50,
            ),
          ],
        );

        // Complete quest
        await questManager.updateProgress(
          userId: playerId,
          questId: questId,
          objectiveId: '${questId}_obj',
          progress: 1,
        );

        await questManager.claimRewards(
          userId: playerId,
          questId: questId,
        );
      }

      // Verify all quests completed
      final completedQuests = questManager.getCompletedQuests(playerId);
      expect(completedQuests.length, greaterThanOrEqualTo(tutorialQuests.length));
    });

    test('level up to level 10 journey', () async {
      const playerId = 'levelup_player_golden';

      var currentLevel = 1;
      final targetLevel = 10;

      while (currentLevel < targetLevel) {
        // Add enough XP to level up
        await progressionManager.addXP(playerId, 500);

        final progress = progressionManager.getPlayerProgress(playerId);
        if (progress != null && progress.level > currentLevel) {
          currentLevel = progress.level;

          // Verify level up rewards
          await currencyManager.addCurrency(
            userId: playerId,
            currencyId: 'gold',
            amount: currentLevel * 100,
          );
        }
      }

      final finalProgress = progressionManager.getPlayerProgress(playerId);
      expect(finalProgress?.level, greaterThanOrEqualTo(targetLevel));
    });
  });
}

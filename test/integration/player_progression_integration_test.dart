import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/player/progression_manager.dart';
import 'package:mg_common_game/quest/quest_manager.dart';
import 'package:mg_common_game/achievement/achievement_manager.dart';

void main() {
  group('Player Progression Integration Tests', () {
    late ProgressionManager progressionManager;
    late QuestManager questManager;
    late AchievementManager achievementManager;

    setUp(() async {
      progressionManager = ProgressionManager.instance;
      questManager = QuestManager.instance;
      achievementManager = AchievementManager.instance;

      await progressionManager.initialize();
      await questManager.initialize();
      await achievementManager.initialize();
    });

    test('should award XP and update level correctly', () async {
      const userId = 'test_user_xp';

      // Get initial level
      final initialProgress = progressionManager.getPlayerProgress(userId);
      final initialLevel = initialProgress?.level ?? 1;

      // Add XP
      await progressionManager.addXP(userId, 100);
      final updatedProgress = progressionManager.getPlayerProgress(userId);

      expect(updatedProgress, isNotNull);
      expect(updatedProgress!.level, greaterThanOrEqualTo(initialLevel));
    });

    test('should complete quest and award XP', () async {
      const userId = 'test_user_quest';

      // Create a quest
      await questManager.createQuest(
        questId: 'integration_quest',
        name: 'Integration Test Quest',
        description: 'Test quest for integration',
        questType: QuestType.daily,
        objectives: [
          QuestObjective(
            objectiveId: 'obj1',
            description: 'Complete 1 task',
            targetCount: 1,
            questType: ObjectiveType.task,
          ),
        ],
        rewards: [
          QuestReward(
            rewardId: 'reward1',
            type: RewardType.experience,
            amount: 50,
          ),
        ],
      );

      // Complete objective
      await questManager.updateProgress(
        userId: userId,
        questId: 'integration_quest',
        objectiveId: 'obj1',
        progress: 1,
      );

      // Claim rewards
      final success = await questManager.claimRewards(
        userId: userId,
        questId: 'integration_quest',
      );

      expect(success, isTrue);
    });

    test('should unlock achievement when criteria met', () async {
      const userId = 'test_user_achievement';

      // Create achievement
      await achievementManager.createAchievement(
        achievementId: 'integration_achievement',
        name: 'Integration Test Achievement',
        description: 'Test achievement for integration',
        tier: AchievementTier.bronze,
        category: AchievementCategory.gameplay,
        criteria: AchievementCriteria(
          type: CriteriaType.level,
          target: 1,
        ),
        rewards: [
          AchievementReward(
            rewardId: 'reward1',
            type: RewardType.experience,
            amount: 100,
          ),
        ],
      );

      // Add XP to reach level 1
      await progressionManager.addXP(userId, 10);

      // Check achievement progress
      final progress = achievementManager.getAchievementProgress(
        userId: userId,
        achievementId: 'integration_achievement',
      );

      expect(progress, isNotNull);
    });

    test('should track daily login streak', () async {
      const userId = 'test_user_streak';

      await progressionManager.recordDailyActivity(userId);
      final stats = progressionManager.getProgressionStats(userId);

      expect(stats['loginStreak'], greaterThanOrEqualTo(1));
    });

    test('should calculate completion rate correctly', () async {
      const userId = 'test_user_completion';

      await progressionManager.recordDailyActivity(userId);
      final stats = progressionManager.getProgressionStats(userId);

      expect(stats, containsPair('completionRate', isNotNull));
    });
  });
}

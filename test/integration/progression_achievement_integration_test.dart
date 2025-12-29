import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration test for Progression + Achievement systems
/// Tests scenarios where leveling up triggers achievement unlocks
void main() {
  group('Progression + Achievement Integration Tests', () {
    late ProgressionManager progressionManager;
    late AchievementManager achievementManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      progressionManager = ProgressionManager();
      achievementManager = AchievementManager();

      // Register common achievements
      achievementManager.registerAchievement(Achievement(
        id: 'first_level',
        title: 'First Steps',
        description: 'Reach level 2',
        iconAsset: 'assets/achievements/first_level.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'level_5',
        title: 'Novice',
        description: 'Reach level 5',
        iconAsset: 'assets/achievements/level_5.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'level_10',
        title: 'Apprentice',
        description: 'Reach level 10',
        iconAsset: 'assets/achievements/level_10.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'level_25',
        title: 'Master',
        description: 'Reach level 25',
        iconAsset: 'assets/achievements/level_25.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'xp_grinder',
        title: 'XP Grinder',
        description: 'Gain 1000 XP in one session',
        iconAsset: 'assets/achievements/xp_grinder.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'quick_learner',
        title: 'Quick Learner',
        description: 'Level up 3 times in a row',
        iconAsset: 'assets/achievements/quick_learner.png',
        hidden: true,
      ));
    });

    tearDown(() {
      progressionManager.reset();
    });

    test('Level up triggers achievement unlock', () {
      // Track unlocked achievements
      final unlockedAchievements = <String>[];

      achievementManager.onAchievementUnlocked = (achievement) {
        unlockedAchievements.add(achievement.id);
      };

      progressionManager.onLevelUp = (newLevel) {
        // Check level-based achievements
        if (newLevel == 2) {
          achievementManager.unlock('first_level');
        } else if (newLevel == 5) {
          achievementManager.unlock('level_5');
        } else if (newLevel == 10) {
          achievementManager.unlock('level_10');
        } else if (newLevel == 25) {
          achievementManager.unlock('level_25');
        }
      };

      // 1. Gain enough XP to reach level 2
      progressionManager.addXp(150);

      expect(progressionManager.currentLevel, 2);
      expect(achievementManager.isUnlocked('first_level'), isTrue);
      expect(unlockedAchievements, contains('first_level'));
    });

    test('Multiple level ups unlock multiple achievements', () {
      final unlockedAchievements = <String>[];

      achievementManager.onAchievementUnlocked = (achievement) {
        unlockedAchievements.add(achievement.id);
      };

      progressionManager.onLevelUp = (newLevel) {
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
        if (newLevel == 10) achievementManager.unlock('level_10');
      };

      // 1. Gain massive XP to level up multiple times
      progressionManager.addXp(5000);

      // Should have unlocked multiple achievements
      expect(progressionManager.currentLevel, greaterThanOrEqualTo(4));
      expect(unlockedAchievements.length, greaterThanOrEqualTo(2));
      expect(achievementManager.isUnlocked('first_level'), isTrue);
      expect(achievementManager.isUnlocked('level_5'), isTrue);
    });

    test('XP milestone achievement', () {
      var totalXpGained = 0;

      // Track total XP gained
      progressionManager.onLevelUp = (newLevel) {
        // XP used for level up is tracked
      };

      // Simulate gaining XP in chunks
      final xpGains = [100, 200, 150, 300, 250];

      for (final xp in xpGains) {
        progressionManager.addXp(xp);
        totalXpGained += xp;
      }

      // Check if XP grinder achievement should unlock
      if (totalXpGained >= 1000) {
        achievementManager.unlock('xp_grinder');
      }

      expect(totalXpGained, greaterThanOrEqualTo(1000));
      expect(achievementManager.isUnlocked('xp_grinder'), isTrue);
    });

    test('Quick learner achievement for consecutive level ups', () {
      var consecutiveLevelUps = 0;

      progressionManager.onLevelUp = (newLevel) {
        consecutiveLevelUps++;

        // Check for quick learner achievement
        if (consecutiveLevelUps >= 3) {
          achievementManager.unlock('quick_learner');
        }
      };

      // Add enough XP to level up 3 times quickly
      // Level 1->2: 100 XP
      // Level 2->3: ~150 XP
      // Level 3->4: ~225 XP
      progressionManager.addXp(1000);

      expect(consecutiveLevelUps, greaterThanOrEqualTo(3));
      expect(achievementManager.isUnlocked('quick_learner'), isTrue);
    });

    test('Hidden achievement revealed when unlocked', () {
      // Hidden achievement should not show details until unlocked
      final quickLearner =
          achievementManager.allAchievements.firstWhere((a) => a.id == 'quick_learner');

      expect(quickLearner.hidden, isTrue);
      expect(quickLearner.unlocked, isFalse);

      // Unlock it
      achievementManager.unlock('quick_learner');

      expect(quickLearner.unlocked, isTrue);
      // Game UI can now show details
    });

    test('Achievement progress tracking', () {
      // Simulate tracking progress toward level 10 achievement
      var currentProgress = progressionManager.currentLevel;
      const targetLevel = 10;

      final progress = (currentProgress / targetLevel).clamp(0.0, 1.0);

      expect(progress, lessThanOrEqualTo(1.0));

      // Level up toward goal
      progressionManager.addXp(2000);

      final newProgress =
          (progressionManager.currentLevel / targetLevel).clamp(0.0, 1.0);

      expect(newProgress, greaterThan(progress));
    });

    test('Achievement unlocks are idempotent', () {
      var unlockCount = 0;

      achievementManager.onAchievementUnlocked = (achievement) {
        unlockCount++;
      };

      // Try to unlock same achievement multiple times
      achievementManager.unlock('first_level');
      achievementManager.unlock('first_level');
      achievementManager.unlock('first_level');

      // Should only count as one unlock
      expect(unlockCount, 1);
      expect(achievementManager.isUnlocked('first_level'), isTrue);
    });

    test('Save and load progression with achievements', () async {
      // 1. Progress and unlock achievements
      progressionManager.onLevelUp = (newLevel) {
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
      };

      progressionManager.addXp(1000);

      final saveData = {
        'progression': progressionManager.toSaveData(),
        'achievements': achievementManager.toSaveData(),
      };

      // 2. Reset managers (simulate new session)
      final oldLevel = progressionManager.currentLevel;
      final wasFirstLevelUnlocked = achievementManager.isUnlocked('first_level');

      progressionManager.reset();
      expect(progressionManager.currentLevel, 1);

      // Reset achievements by loading empty save
      achievementManager.fromSaveData({'unlocked': ''});
      expect(achievementManager.isUnlocked('first_level'), isFalse);

      // 3. Load saved data
      progressionManager.fromSaveData(saveData['progression'] as Map<String, dynamic>);
      achievementManager.fromSaveData(saveData['achievements'] as Map<String, dynamic>);

      // 4. Verify restoration
      expect(progressionManager.currentLevel, oldLevel);
      expect(achievementManager.isUnlocked('first_level'), wasFirstLevelUnlocked);
    });

    test('Edge case: level up at exactly required XP', () {
      // Get exact XP needed for next level
      final xpNeeded = progressionManager.xpToNextLevel;

      var leveledUp = false;
      progressionManager.onLevelUp = (newLevel) {
        leveledUp = true;
      };

      // Add exact amount
      progressionManager.addXp(xpNeeded);

      expect(leveledUp, isTrue);
      expect(progressionManager.currentLevel, 2);
      expect(progressionManager.currentXp, 0);
    });

    test('Edge case: massive XP gain levels up many times', () {
      final levelUpEvents = <int>[];

      progressionManager.onLevelUp = (newLevel) {
        levelUpEvents.add(newLevel);

        // Unlock achievements at milestones
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
        if (newLevel == 10) achievementManager.unlock('level_10');
        if (newLevel == 25) achievementManager.unlock('level_25');
      };

      // Massive XP dump
      progressionManager.addXp(50000);

      // Should have leveled up many times
      expect(levelUpEvents.length, greaterThanOrEqualTo(10));
      expect(progressionManager.currentLevel, greaterThanOrEqualTo(10));

      // Multiple achievements unlocked
      expect(achievementManager.unlockedCount, greaterThanOrEqualTo(3));
    });

    test('Edge case: zero XP gain', () {
      final initialLevel = progressionManager.currentLevel;

      progressionManager.addXp(0);

      expect(progressionManager.currentLevel, initialLevel);
    });

    test('Edge case: negative XP gain (should be ignored)', () {
      final initialLevel = progressionManager.currentLevel;
      final initialXp = progressionManager.currentXp;

      progressionManager.addXp(-100);

      expect(progressionManager.currentLevel, initialLevel);
      expect(progressionManager.currentXp, initialXp);
    });

    test('Real-world: complete gameplay loop', () {
      // Simulate a real game session

      final sessionEvents = <String>[];
      final sessionAchievements = <String>[];

      progressionManager.onLevelUp = (newLevel) {
        sessionEvents.add('Level up to $newLevel');

        // Check achievements
        if (newLevel == 2) {
          achievementManager.unlock('first_level');
        } else if (newLevel == 5) {
          achievementManager.unlock('level_5');
        } else if (newLevel == 10) {
          achievementManager.unlock('level_10');
        }
      };

      achievementManager.onAchievementUnlocked = (achievement) {
        sessionEvents.add('Achievement: ${achievement.title}');
        sessionAchievements.add(achievement.id);
      };

      // Player completes quests/battles
      sessionEvents.add('Quest completed');
      progressionManager.addXp(50);

      sessionEvents.add('Battle won');
      progressionManager.addXp(75);

      sessionEvents.add('Boss defeated');
      progressionManager.addXp(150);

      sessionEvents.add('Daily challenge completed');
      progressionManager.addXp(150);

      sessionEvents.add('Bonus XP from streak');
      progressionManager.addXp(125);

      // Check session results
      expect(progressionManager.currentLevel, greaterThanOrEqualTo(2));
      expect(sessionAchievements, isNotEmpty);
      expect(sessionEvents.length, greaterThan(5));

      // Display session summary
      final summary = {
        'finalLevel': progressionManager.currentLevel,
        'achievementsUnlocked': sessionAchievements.length,
        'events': sessionEvents.length,
      };

      expect(summary['finalLevel'], greaterThanOrEqualTo(2));
    });

    test('Real-world: achievement notification queue', () {
      // When multiple achievements unlock, queue them for display

      final achievementQueue = <Achievement>[];

      achievementManager.onAchievementUnlocked = (achievement) {
        achievementQueue.add(achievement);
      };

      progressionManager.onLevelUp = (newLevel) {
        // Multiple achievements can unlock at once
        if (newLevel == 5) {
          achievementManager.unlock('first_level'); // Retroactive
          achievementManager.unlock('level_5');
        }
      };

      // Massive XP gain
      progressionManager.addXp(5000);

      // Process achievement queue
      expect(achievementQueue.length, greaterThanOrEqualTo(1));

      // Show achievements one by one in UI
      for (final achievement in achievementQueue) {
        expect(achievement.unlocked, isTrue);
      }
    });

    test('Real-world: achievement categories and progress', () {
      // Group achievements by category
      final levelAchievements = [
        'first_level',
        'level_5',
        'level_10',
        'level_25'
      ];
      final progressAchievements = ['xp_grinder'];
      final hiddenAchievements = ['quick_learner'];

      // Track category completion
      int getLevelAchievementCount() {
        return levelAchievements
            .where((id) => achievementManager.isUnlocked(id))
            .length;
      }

      // Progress
      progressionManager.onLevelUp = (newLevel) {
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
        if (newLevel == 10) achievementManager.unlock('level_10');
      };

      progressionManager.addXp(3000);

      final levelCategory = getLevelAchievementCount();
      final totalProgress =
          levelCategory / levelAchievements.length;

      expect(totalProgress, greaterThan(0.0));
      expect(levelCategory, greaterThanOrEqualTo(1));
    });

    test('Real-world: prestige unlocks achievement', () {
      // Simulate reaching max level unlocking a special achievement

      achievementManager.registerAchievement(Achievement(
        id: 'max_level',
        title: 'Legend',
        description: 'Reach level 50',
        iconAsset: 'assets/achievements/max_level.png',
      ));

      achievementManager.registerAchievement(Achievement(
        id: 'prestige_ready',
        title: 'Ready to Prestige',
        description: 'Reach level 25 and unlock prestige',
        iconAsset: 'assets/achievements/prestige.png',
      ));

      progressionManager.onLevelUp = (newLevel) {
        if (newLevel >= 25) {
          achievementManager.unlock('prestige_ready');
        }
      };

      // Level to 25
      progressionManager.addXp(100000);

      expect(progressionManager.currentLevel, greaterThanOrEqualTo(25));
      expect(achievementManager.isUnlocked('prestige_ready'), isTrue);
    });

    test('Real-world: achievement rewards bonus XP', () {
      // Some games give bonus XP for unlocking achievements

      var bonusXpEarned = 0;

      achievementManager.onAchievementUnlocked = (achievement) {
        // Award bonus XP based on achievement
        const bonusXpPerAchievement = 50;
        bonusXpEarned += bonusXpPerAchievement;
      };

      progressionManager.onLevelUp = (newLevel) {
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
      };

      // Level up
      progressionManager.addXp(1000);

      // Achievements should have awarded bonus XP
      expect(bonusXpEarned, greaterThan(0));

      // Apply bonus XP
      progressionManager.addXp(bonusXpEarned);

      // Player gets extra progression
      expect(progressionManager.currentLevel, greaterThanOrEqualTo(4));
    });

    test('Real-world: achievement completion percentage', () {
      // Calculate overall achievement completion

      final totalAchievements = achievementManager.totalCount;
      final unlockedAchievements = achievementManager.unlockedCount;

      // Initial state
      expect(unlockedAchievements, 0);

      // Progress and unlock some
      progressionManager.onLevelUp = (newLevel) {
        if (newLevel == 2) achievementManager.unlock('first_level');
        if (newLevel == 5) achievementManager.unlock('level_5');
        if (newLevel == 10) achievementManager.unlock('level_10');
      };

      progressionManager.addXp(5000);

      final finalUnlocked = achievementManager.unlockedCount;
      final completionPercentage =
          (finalUnlocked / totalAchievements) * 100;

      expect(completionPercentage, greaterThan(0.0));
      expect(completionPercentage, lessThanOrEqualTo(100.0));
    });
  });
}

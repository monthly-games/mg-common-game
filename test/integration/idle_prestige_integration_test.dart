import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/idle/idle_manager.dart';
import 'package:mg_common_game/systems/idle/idle_resource.dart';
import 'package:mg_common_game/systems/idle/offline_progress_manager.dart';
import 'package:mg_common_game/systems/idle/prestige_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration test for Idle + Prestige systems
/// Tests offline progression and prestige mechanics working together
void main() {
  group('Idle + Prestige Integration Tests', () {
    late IdleManager idleManager;
    late PrestigeManager prestigeManager;
    late OfflineProgressManager offlineProgressManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      idleManager = IdleManager();
      prestigeManager = PrestigeManager(
        config: const PrestigeConfig(
          minResourceForPrestige: 1000,
          prestigeResourceId: 'gold',
          formula: PrestigeFormula.logarithmic,
          formulaBase: 10.0,
          pointMultiplier: 1.0,
          bonusPerPoint: 0.01, // 1% per point
        ),
      );
      offlineProgressManager = OfflineProgressManager(idleManager: idleManager);

      await prestigeManager.initialize();
      await offlineProgressManager.initialize();

      // Register test resources
      idleManager.registerResource(IdleResource(
        id: 'gold',
        name: 'Gold',
        baseProductionRate: 100.0, // 100 gold per hour
        maxStorage: 10000,
        tier: 1,
      ));

      idleManager.registerResource(IdleResource(
        id: 'gems',
        name: 'Gems',
        baseProductionRate: 10.0, // 10 gems per hour
        maxStorage: 1000,
        tier: 2,
      ));
    });

    tearDown(() {
      idleManager.clear();
    });

    test('Offline progress accumulates resources', () async {
      // 1. Set last login time to 2 hours ago
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));

      // Manually set last login (for testing)
      offlineProgressManager.fromJson({
        'lastLoginTime': twoHoursAgo.millisecondsSinceEpoch,
      });

      // 2. Check offline progress
      final offlineData = await offlineProgressManager.checkOfflineProgress();

      expect(offlineData, isNotNull);
      expect(offlineData!.hasRewards, isTrue);
      expect(offlineData.offlineDuration.inHours, greaterThanOrEqualTo(1));

      // 3. Verify gold was produced (100/hour * 2 hours = 200)
      expect(offlineData.rewards['gold'], greaterThan(0));
    });

    test('Prestige becomes available after earning enough resources', () {
      // 1. Initial state - cannot prestige
      expect(prestigeManager.canPrestige, isFalse);

      // 2. Earn resources through idle production
      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(1500);

      // 3. Update prestige manager with current resource
      prestigeManager.updateResource(goldResource.currentAmount);

      // 4. Now can prestige
      expect(prestigeManager.canPrestige, isTrue);
      expect(prestigeManager.currentResource, greaterThanOrEqualTo(1000));
    });

    test('Prestige resets resources but provides permanent bonus', () async {
      // 1. Accumulate resources
      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(5000);
      prestigeManager.updateResource(goldResource.currentAmount);

      // 2. Check prestige points before
      final pointsToEarn = prestigeManager.calculatePrestigePoints();
      expect(pointsToEarn, greaterThan(0));

      final initialBonus = prestigeManager.prestigeBonus;

      // 3. Perform prestige
      final prestigeData = await prestigeManager.performPrestige();

      expect(prestigeData, isNotNull);
      expect(prestigeData!.currentPrestigeLevel, 1);
      expect(prestigeData.pointsEarnedThisRun, pointsToEarn);

      // 4. Bonus should increase
      final newBonus = prestigeManager.prestigeBonus;
      expect(newBonus, greaterThan(initialBonus));

      // 5. Game should reset resources (handled by game code)
      goldResource.currentAmount = 0;
      prestigeManager.updateResource(0);

      expect(prestigeManager.canPrestige, isFalse);
    });

    test('Prestige bonus multiplies idle production', () {
      // 1. First run without prestige
      idleManager.setGlobalModifier(1.0);

      final goldResource = idleManager.getResource('gold');
      final baseProduction = goldResource!.calculateProduction(
        const Duration(hours: 1),
        modifier: idleManager.globalModifier,
      );

      expect(baseProduction, 100); // 100 gold/hour

      // 2. Simulate prestige bonus (e.g., 10 points = 10% bonus)
      prestigeManager.fromJson({
        'prestigeLevel': 5,
        'prestigePoints': 10,
      });

      final prestigeBonus = prestigeManager.prestigeBonus; // 1.0 + (10 * 0.01) = 1.1
      expect(prestigeBonus, 1.1);

      // 3. Apply prestige bonus to idle production
      idleManager.setGlobalModifier(prestigeBonus);

      final boostedProduction = goldResource.calculateProduction(
        const Duration(hours: 1),
        modifier: idleManager.globalModifier,
      );

      expect(boostedProduction, greaterThan(baseProduction));
      expect(boostedProduction, 110); // 100 * 1.1 = 110
    });

    test('Offline progress with prestige bonus', () async {
      // 1. Apply prestige bonus
      prestigeManager.fromJson({
        'prestigeLevel': 2,
        'prestigePoints': 5,
      });

      final prestigeBonus = prestigeManager.prestigeBonus; // 1.05
      idleManager.setGlobalModifier(prestigeBonus);

      // 2. Set last login to 1 hour ago
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      offlineProgressManager.fromJson({
        'lastLoginTime': oneHourAgo.millisecondsSinceEpoch,
      });

      // 3. Calculate offline rewards with prestige bonus
      final offlineData = await offlineProgressManager.checkOfflineProgress();

      expect(offlineData, isNotNull);

      // Gold production: 100/hour * 1.05 prestige bonus = 105
      final goldEarned = offlineData!.rewards['gold'] ?? 0;
      expect(goldEarned, greaterThanOrEqualTo(100));
    });

    test('Multiple prestige cycles with increasing bonuses', () async {
      // Simulate multiple prestige loops

      final prestigeHistory = <PrestigeData>[];

      for (int cycle = 1; cycle <= 3; cycle++) {
        // Earn resources (each cycle should be faster with bonuses)
        final goldResource = idleManager.getResource('gold');
        goldResource!.addProduction(2000 * cycle);
        prestigeManager.updateResource(goldResource.currentAmount);

        // Prestige
        if (prestigeManager.canPrestige) {
          final data = await prestigeManager.performPrestige();
          if (data != null) {
            prestigeHistory.add(data);
          }

          // Reset for next cycle
          goldResource.currentAmount = 0;
          prestigeManager.updateResource(0);

          // Apply new bonus
          idleManager.setGlobalModifier(prestigeManager.prestigeBonus);
        }
      }

      // Verify prestige progression
      expect(prestigeHistory.length, greaterThanOrEqualTo(2));
      expect(prestigeManager.prestigeLevel, greaterThanOrEqualTo(2));
      expect(prestigeManager.prestigeBonus, greaterThan(1.0));
    });

    test('Offline progress capped at maximum hours', () async {
      // 1. Set last login to 24 hours ago
      final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
      offlineProgressManager.fromJson({
        'lastLoginTime': dayAgo.millisecondsSinceEpoch,
      });

      // 2. Check offline progress (should cap at maxOfflineHours = 8)
      final offlineData = await offlineProgressManager.checkOfflineProgress();

      expect(offlineData, isNotNull);

      // Gold production capped at 8 hours: 100/hour * 8 = 800
      final goldEarned = offlineData!.rewards['gold'] ?? 0;
      expect(goldEarned, lessThanOrEqualTo(800));
    });

    test('Prestige calculation with different formulas', () async {
      // Test different prestige formulas

      // 1. Logarithmic formula
      prestigeManager.updateConfig(const PrestigeConfig(
        minResourceForPrestige: 1000,
        formula: PrestigeFormula.logarithmic,
        formulaBase: 10.0,
      ));

      prestigeManager.updateResource(10000);
      final logPoints = prestigeManager.calculatePrestigePoints();

      // 2. Linear formula
      prestigeManager.updateConfig(const PrestigeConfig(
        minResourceForPrestige: 1000,
        formula: PrestigeFormula.linear,
        formulaBase: 1000.0,
      ));

      prestigeManager.updateResource(10000);
      final linearPoints = prestigeManager.calculatePrestigePoints();

      // 3. Square root formula
      prestigeManager.updateConfig(const PrestigeConfig(
        minResourceForPrestige: 1000,
        formula: PrestigeFormula.squareRoot,
        formulaBase: 100.0,
      ));

      prestigeManager.updateResource(10000);
      final sqrtPoints = prestigeManager.calculatePrestigePoints();

      // Different formulas should give different results
      expect(logPoints, greaterThan(0));
      expect(linearPoints, greaterThan(0));
      expect(sqrtPoints, greaterThan(0));
    });

    test('Offline rewards with efficiency modifier', () async {
      // Some games reduce offline efficiency to encourage active play

      // 1. Set offline efficiency to 50%
      offlineProgressManager.offlineEfficiency = 0.5;

      // 2. Set last login to 2 hours ago
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      offlineProgressManager.fromJson({
        'lastLoginTime': twoHoursAgo.millisecondsSinceEpoch,
      });

      // 3. Calculate offline rewards
      final offlineData = await offlineProgressManager.checkOfflineProgress();

      // Gold: 100/hour * 2 hours * 0.5 efficiency = 100
      final goldEarned = offlineData!.rewards['gold'] ?? 0;
      expect(goldEarned, lessThanOrEqualTo(100));
    });

    test('Claim offline rewards with multiplier (ad bonus)', () async {
      // Scenario: Watch ad to double offline rewards

      // 1. Setup offline progress
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      offlineProgressManager.fromJson({
        'lastLoginTime': oneHourAgo.millisecondsSinceEpoch,
      });

      await offlineProgressManager.checkOfflineProgress();

      expect(offlineProgressManager.hasPendingRewards, isTrue);

      // 2. Claim with 2x multiplier
      final rewards = offlineProgressManager.claimRewardsWithMultiplier(2.0);

      expect(rewards['gold'], greaterThan(0));

      // Resources should have received extra amount
      final goldResource = idleManager.getResource('gold');
      expect(goldResource!.currentAmount, greaterThan(0));
    });

    test('Edge case: prestige at exact minimum', () async {
      // Prestige exactly at minimum resource requirement

      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(1000); // Exact minimum

      prestigeManager.updateResource(1000);

      expect(prestigeManager.canPrestige, isTrue);

      final data = await prestigeManager.performPrestige();
      expect(data, isNotNull);
    });

    test('Edge case: prestige below minimum', () async {
      // Cannot prestige below minimum

      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(999);

      prestigeManager.updateResource(999);

      expect(prestigeManager.canPrestige, isFalse);

      final data = await prestigeManager.performPrestige();
      expect(data, isNull);
    });

    test('Edge case: no offline time', () async {
      // Player returns immediately

      offlineProgressManager.minOfflineSeconds = 60; // 1 minute minimum

      // Set last login to 30 seconds ago
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      offlineProgressManager.fromJson({
        'lastLoginTime': recent.millisecondsSinceEpoch,
      });

      final offlineData = await offlineProgressManager.checkOfflineProgress();

      // Should not give rewards for short absence
      expect(offlineData, isNull);
    });

    test('Edge case: storage overflow prevention', () {
      // Offline rewards should not exceed storage capacity

      final goldResource = idleManager.getResource('gold');
      expect(goldResource!.maxStorage, 10000);

      // Simulate massive offline time (would overflow)
      final offlineDuration = const Duration(hours: 200);
      final produced = goldResource.calculateProduction(offlineDuration);

      // Add to resource (should cap at max storage)
      final added = goldResource.addProduction(produced);

      expect(goldResource.currentAmount, lessThanOrEqualTo(goldResource.maxStorage));
      expect(added, lessThanOrEqualTo(goldResource.maxStorage));
    });

    test('Real-world: first prestige tutorial flow', () async {
      // Simulate first-time prestige experience

      final events = <String>[];

      // 1. Player starts game
      events.add('Game started');
      expect(prestigeManager.prestigeLevel, 0);
      expect(prestigeManager.prestigeBonus, 1.0);

      // 2. Idle production accumulates
      events.add('Idle production running');
      idleManager.startProduction();
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Player accumulates resources
      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(1500);
      prestigeManager.updateResource(goldResource.currentAmount);

      events.add('Earned ${goldResource.currentAmount} gold');

      // 4. Prestige becomes available
      if (prestigeManager.canPrestige) {
        events.add('Prestige available!');
        final points = prestigeManager.calculatePrestigePoints();
        events.add('Can earn $points prestige points');

        // 5. Player prestiges
        final data = await prestigeManager.performPrestige();
        events.add('Prestige complete! Level: ${data!.currentPrestigeLevel}');

        // 6. Reset game state
        goldResource.currentAmount = 0;
        prestigeManager.updateResource(0);
        events.add('Resources reset, bonus active: ${prestigeManager.prestigeBonusPercentage}');
      }

      // 7. Second run with bonus
      idleManager.setGlobalModifier(prestigeManager.prestigeBonus);
      events.add('Production now boosted by ${prestigeManager.prestigeBonusPercentage}');

      expect(events.length, greaterThanOrEqualTo(5));
      expect(prestigeManager.prestigeLevel, greaterThanOrEqualTo(1));
    });

    test('Real-world: complete idle session with prestige', () async {
      // Full gameplay loop

      // 1. Login after being offline
      final fourHoursAgo = DateTime.now().subtract(const Duration(hours: 4));
      offlineProgressManager.fromJson({
        'lastLoginTime': fourHoursAgo.millisecondsSinceEpoch,
      });

      final offlineData = await offlineProgressManager.checkOfflineProgress();
      expect(offlineData, isNotNull);

      // 2. Claim offline rewards
      final rewards = offlineProgressManager.claimRewards();
      expect(rewards, isNotEmpty);

      // 3. Apply rewards to resources
      for (final entry in rewards.entries) {
        final resource = idleManager.getResource(entry.key);
        resource?.addProduction(entry.value);
      }

      // 4. Check if can prestige
      final goldResource = idleManager.getResource('gold');
      prestigeManager.updateResource(goldResource!.currentAmount);

      if (prestigeManager.canPrestige) {
        // Show prestige dialog
        final points = prestigeManager.calculatePrestigePoints();
        final bonus = (points * prestigeManager.config.bonusPerPoint * 100);

        expect(points, greaterThan(0));

        // Player decides to prestige
        await prestigeManager.performPrestige();

        // Reset resources
        goldResource.currentAmount = 0;
        idleManager.getResource('gems')?.collectAll();

        // Apply new bonus
        idleManager.setGlobalModifier(prestigeManager.prestigeBonus);
      }

      // 5. Continue playing with bonus
      expect(idleManager.globalModifier, greaterThanOrEqualTo(1.0));
    });

    test('Real-world: prestige progression curve', () async {
      // Test prestige point scaling over multiple cycles

      final prestigeCurve = <int, int>{}; // level -> points earned

      for (int level = 0; level < 5; level++) {
        // Simulate earning resources
        final resourceAmount = 1000 * (level + 1) * (level + 1);
        prestigeManager.updateResource(resourceAmount);

        if (prestigeManager.canPrestige) {
          final points = prestigeManager.calculatePrestigePoints(resourceAmount);
          prestigeCurve[level] = points;

          await prestigeManager.performPrestige();
          prestigeManager.updateResource(0);
        }
      }

      // Points should generally increase with more resources
      expect(prestigeCurve.length, greaterThanOrEqualTo(3));
    });

    test('Real-world: offline progress notification system', () async {
      // Test notification triggers for offline rewards

      final notifications = <String>[];

      offlineProgressManager.onOfflineProgress = (data) {
        if (data.hasRewards) {
          notifications.add('You earned ${data.totalRewards} total resources while away!');
          notifications.add('Offline time: ${data.formattedDuration}');

          for (final entry in data.rewards.entries) {
            notifications.add('${entry.key}: +${entry.value}');
          }
        }
      };

      // Trigger offline progress
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      offlineProgressManager.fromJson({
        'lastLoginTime': twoHoursAgo.millisecondsSinceEpoch,
      });

      await offlineProgressManager.checkOfflineProgress();

      expect(notifications, isNotEmpty);
    });

    test('Real-world: prestige milestone achievements', () async {
      // Track prestige milestones

      final milestones = <String>[];

      for (int i = 0; i < 10; i++) {
        final goldResource = idleManager.getResource('gold');
        goldResource!.addProduction(5000);
        prestigeManager.updateResource(goldResource.currentAmount);

        if (prestigeManager.canPrestige) {
          final data = await prestigeManager.performPrestige();

          if (data!.currentPrestigeLevel == 1) {
            milestones.add('First Prestige!');
          } else if (data.currentPrestigeLevel == 5) {
            milestones.add('Prestige Master!');
          } else if (data.currentPrestigeLevel == 10) {
            milestones.add('Prestige Legend!');
          }

          goldResource.currentAmount = 0;
          prestigeManager.updateResource(0);
        }
      }

      expect(milestones, isNotEmpty);
    });

    test('Real-world: save and load complete state', () async {
      // Save entire game state

      // 1. Setup game state
      final goldResource = idleManager.getResource('gold');
      goldResource!.addProduction(3000);

      prestigeManager.updateResource(3000);
      await prestigeManager.performPrestige();

      idleManager.setGlobalModifier(prestigeManager.prestigeBonus);

      // 2. Save state
      final saveData = {
        'idle': idleManager.toJson(),
        'prestige': prestigeManager.toJson(),
        'offline': offlineProgressManager.toJson(),
      };

      // 3. Clear state
      idleManager.clear();
      await prestigeManager.reset();
      await offlineProgressManager.reset();

      // 4. Restore state
      idleManager.fromJson(saveData['idle'] as Map<String, dynamic>);
      prestigeManager.fromJson(saveData['prestige'] as Map<String, dynamic>);
      offlineProgressManager.fromJson(saveData['offline'] as Map<String, dynamic>);

      // 5. Verify restoration
      expect(idleManager.globalModifier, greaterThan(1.0));
      expect(prestigeManager.prestigeLevel, greaterThanOrEqualTo(1));
    });
  });
}

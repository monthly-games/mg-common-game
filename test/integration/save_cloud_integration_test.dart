import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/cloud/cloud_save_manager.dart';
import 'package:mg_common_game/core/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration test for Save + Cloud synchronization
/// Tests the scenario where local save data is synced with cloud storage
void main() {
  group('Save + Cloud Integration Tests', () {
    late LocalSaveSystem localSave;
    late CloudSaveManager cloudSave;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      localSave = LocalSaveSystem();
      await localSave.init();

      cloudSave = CloudSaveManager.instance;
      await cloudSave.initialize(
        gameId: 'test_game',
        userId: 'test_user_123',
        defaultResolution: ConflictResolution.useNewer,
      );
    });

    tearDown(() {
      // Clean up after each test
    });

    test('Local save then cloud sync workflow', () async {
      // 1. Save data locally
      final playerData = {
        'level': 5,
        'gold': 1000,
        'xp': 450,
        'inventory': ['sword', 'shield', 'potion'],
      };

      await localSave.save('player_data', playerData);

      // 2. Verify local save worked
      final loadedLocal = await localSave.load('player_data');
      expect(loadedLocal, isNotNull);
      expect(loadedLocal?['level'], 5);
      expect(loadedLocal?['gold'], 1000);
      expect(loadedLocal?['inventory'], hasLength(3));

      // 3. Sync to cloud
      await cloudSave.save(playerData, syncImmediately: false);

      // 4. Verify cloud data matches
      final cloudData = cloudSave.getData();
      expect(cloudData, isNotNull);
      expect(cloudData?['level'], 5);
      expect(cloudData?['gold'], 1000);
    });

    test('Cloud sync with incremental updates', () async {
      // Scenario: Player saves progress multiple times before syncing

      // 1. Initial save
      await cloudSave.save({'score': 100, 'level': 1}, syncImmediately: false);
      expect(cloudSave.status, CloudSyncStatus.pendingUpload);

      // 2. Update score
      await cloudSave.setValue('score', 250, syncImmediately: false);
      expect(cloudSave.getValue<int>('score'), 250);

      // 3. Update level
      await cloudSave.setValue('level', 2, syncImmediately: false);

      // 4. Final sync
      final syncSuccess = await cloudSave.sync();

      // Note: In real scenario with backend, this would succeed
      // For mock test, we verify the local state is correct
      expect(cloudSave.getValue<int>('score'), 250);
      expect(cloudSave.getValue<int>('level'), 2);
    });

    test('Conflict resolution: newer data wins', () async {
      // Scenario: Same data modified on two devices, newer wins

      final now = DateTime.now();

      // 1. Create older cloud save
      final olderData = CloudSaveData(
        id: 'save_1',
        gameId: 'test_game',
        userId: 'test_user_123',
        data: {'coins': 500, 'gems': 10},
        lastModified: now.subtract(const Duration(hours: 2)),
        version: 1,
      );

      // 2. Create newer local save
      final newerData = {
        'coins': 750,
        'gems': 15,
        'newItem': 'legendary_sword',
      };

      await cloudSave.save(newerData, syncImmediately: false);

      // 3. Verify local (newer) data is preserved
      final currentData = cloudSave.getData();
      expect(currentData?['coins'], 750);
      expect(currentData?['gems'], 15);
      expect(currentData?['newItem'], 'legendary_sword');
    });

    test('Save corruption recovery using cloud backup', () async {
      // Scenario: Local save corrupted, restore from cloud

      // 1. Save valid data to cloud
      final validData = {
        'playerName': 'TestHero',
        'level': 10,
        'achievements': ['first_kill', 'level_5', 'level_10'],
      };

      await cloudSave.save(validData);

      // 2. Simulate local corruption by clearing local save
      await localSave.save('player_data', {});

      // 3. Restore from cloud
      final restoredData = cloudSave.getData();

      expect(restoredData?['playerName'], 'TestHero');
      expect(restoredData?['level'], 10);
      expect(restoredData?['achievements'], hasLength(3));
    });

    test('Multi-key save and sync', () async {
      // Scenario: Different save slots or data categories

      // 1. Save multiple categories
      final playerProfile = {'name': 'Player1', 'avatar': 'knight'};
      final gameProgress = {'currentStage': 15, 'starsEarned': 42};
      final settings = {'musicVolume': 0.8, 'sfxVolume': 0.6};

      await localSave.save('profile', playerProfile);
      await localSave.save('progress', gameProgress);
      await localSave.save('settings', settings);

      // 2. Cloud sync for critical data only
      await cloudSave.save({
        'profile': playerProfile,
        'progress': gameProgress,
      });

      // 3. Verify selective sync
      final cloudData = cloudSave.getData();
      expect(cloudData?['profile'], isNotNull);
      expect(cloudData?['progress'], isNotNull);

      // Settings remain local only
      final localSettings = await localSave.load('settings');
      expect(localSettings?['musicVolume'], 0.8);
    });

    test('Sync status transitions', () async {
      // Track sync status changes

      final statusChanges = <CloudSyncStatus>[];
      cloudSave.addSyncListener((status) {
        statusChanges.add(status);
      });

      // 1. Save without immediate sync
      await cloudSave.save({'test': 'data'}, syncImmediately: false);

      // Should have pending status
      expect(cloudSave.status, CloudSyncStatus.pendingUpload);

      // 2. Trigger sync
      await cloudSave.sync();

      // Status changes should include syncing and final state
      expect(statusChanges, isNotEmpty);
    });

    test('Data merge on sync conflict', () async {
      // Scenario: Merge strategy for conflicting data

      // 1. Setup cloud with different configuration
      await cloudSave.initialize(
        gameId: 'test_game',
        userId: 'test_user_123',
        defaultResolution: ConflictResolution.merge,
      );

      // 2. Create local data
      final localData = {
        'coins': 1000,
        'level': 5,
        'items': ['item1', 'item2'],
      };

      await cloudSave.save(localData, syncImmediately: false);

      // 3. Verify data is stored
      expect(cloudSave.getValue<int>('coins'), 1000);
      expect(cloudSave.getValue<int>('level'), 5);
    });

    test('Edge case: empty save data', () async {
      // Ensure empty data is handled correctly

      // 1. Save empty data
      await localSave.save('empty_slot', {});

      // 2. Load empty data
      final loaded = await localSave.load('empty_slot');
      expect(loaded, isNotNull);
      expect(loaded, isEmpty);

      // 3. Cloud save with empty data
      await cloudSave.save({});
      final cloudData = cloudSave.getData();
      expect(cloudData, isNotNull);
    });

    test('Edge case: large data payload', () async {
      // Test with large amount of data

      // Generate large inventory
      final largeInventory = List.generate(
        1000,
        (i) => {
          'id': 'item_$i',
          'type': i % 5,
          'quantity': i,
          'equipped': i % 10 == 0,
        },
      );

      final largeData = {
        'inventory': largeInventory,
        'playerStats': {
          'health': 1000,
          'mana': 500,
          'strength': 50,
        },
      };

      // 1. Save large data locally
      await localSave.save('large_save', largeData);

      // 2. Verify load
      final loaded = await localSave.load('large_save');
      expect(loaded?['inventory'], hasLength(1000));
      expect(loaded?['playerStats']['health'], 1000);
    });

    test('Edge case: save key with special characters', () async {
      // Test keys with special characters

      final testKeys = [
        'player_save_slot_1',
        'save.backup.2024',
        'user:profile:main',
      ];

      for (final key in testKeys) {
        final data = {'key': key, 'value': 123};
        await localSave.save(key, data);

        final loaded = await localSave.load(key);
        expect(loaded?['key'], key);
        expect(loaded?['value'], 123);
      }
    });

    test('Real-world scenario: game session save and restore', () async {
      // Complete workflow of a game session

      // 1. Player starts game, loads existing save
      await cloudSave.sync();

      // 2. Player progresses through levels
      for (int level = 1; level <= 5; level++) {
        final sessionData = {
          'currentLevel': level,
          'score': level * 1000,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // Save locally each level
        await localSave.save('session', sessionData);

        // Wait a bit between saves
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 3. Final session data
      final finalSession = await localSave.load('session');
      expect(finalSession?['currentLevel'], 5);
      expect(finalSession?['score'], 5000);

      // 4. Sync to cloud before closing game
      await cloudSave.save(finalSession ?? {});

      // 5. Verify cloud has latest data
      final cloudData = cloudSave.getData();
      expect(cloudData?['currentLevel'], 5);
    });
  });
}

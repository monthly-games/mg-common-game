import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/systems/save_manager.dart';

/// Mock implementation of Saveable for testing
class MockSaveable implements Saveable {
  @override
  final String saveKey;

  Map<String, dynamic> data;
  int toSaveDataCallCount = 0;
  int fromSaveDataCallCount = 0;

  MockSaveable({
    required this.saveKey,
    Map<String, dynamic>? initialData,
  }) : data = initialData ?? {};

  @override
  Map<String, dynamic> toSaveData() {
    toSaveDataCallCount++;
    return Map.from(data);
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    fromSaveDataCallCount++;
    this.data = Map.from(data);
  }
}

void main() {
  late SaveManager saveManager;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    saveManager = SaveManager();
  });

  tearDown(() {
    saveManager.dispose();
  });

  group('SaveManager - Registration', () {
    test('registerSaveable adds system to registered systems', () {
      final saveable = MockSaveable(saveKey: 'test_system');

      saveManager.registerSaveable(saveable);

      final keys = saveManager.getRegisteredKeys();
      expect(keys, contains('test_system'));
      expect(keys.length, 1);
    });

    test('registerSaveable allows multiple systems with different keys', () {
      final saveable1 = MockSaveable(saveKey: 'system_1');
      final saveable2 = MockSaveable(saveKey: 'system_2');
      final saveable3 = MockSaveable(saveKey: 'system_3');

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);
      saveManager.registerSaveable(saveable3);

      final keys = saveManager.getRegisteredKeys();
      expect(keys.length, 3);
      expect(keys, containsAll(['system_1', 'system_2', 'system_3']));
    });

    test('registerSaveable replaces system with same key', () {
      final saveable1 = MockSaveable(
        saveKey: 'duplicate_key',
        initialData: {'value': 1},
      );
      final saveable2 = MockSaveable(
        saveKey: 'duplicate_key',
        initialData: {'value': 2},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      final keys = saveManager.getRegisteredKeys();
      expect(keys.length, 1);
      expect(keys, contains('duplicate_key'));
    });

    test('unregisterSaveable removes system from registered systems', () {
      final saveable = MockSaveable(saveKey: 'test_system');

      saveManager.registerSaveable(saveable);
      expect(saveManager.getRegisteredKeys(), contains('test_system'));

      saveManager.unregisterSaveable('test_system');
      expect(saveManager.getRegisteredKeys(), isEmpty);
    });

    test('unregisterSaveable does nothing for non-existent key', () {
      final saveable = MockSaveable(saveKey: 'existing_system');
      saveManager.registerSaveable(saveable);

      saveManager.unregisterSaveable('non_existent');

      expect(saveManager.getRegisteredKeys(), contains('existing_system'));
      expect(saveManager.getRegisteredKeys().length, 1);
    });

    test('getRegisteredKeys returns empty list when no systems registered', () {
      expect(saveManager.getRegisteredKeys(), isEmpty);
    });
  });

  group('SaveManager - Auto-save Configuration', () {
    test('autoSaveEnabled defaults to true', () {
      expect(saveManager.autoSaveEnabled, true);
    });

    test('autoSaveIntervalSeconds defaults to 30', () {
      expect(saveManager.autoSaveIntervalSeconds, 30);
    });

    test('setAutoSaveEnabled updates enabled state', () {
      saveManager.setAutoSaveEnabled(false);
      expect(saveManager.autoSaveEnabled, false);

      saveManager.setAutoSaveEnabled(true);
      expect(saveManager.autoSaveEnabled, true);
    });

    test('setAutoSaveEnabled notifies listeners', () {
      int notifyCount = 0;
      saveManager.addListener(() => notifyCount++);

      saveManager.setAutoSaveEnabled(false);
      expect(notifyCount, 1);

      saveManager.setAutoSaveEnabled(true);
      expect(notifyCount, 2);
    });

    test('setAutoSaveInterval updates interval', () {
      saveManager.setAutoSaveInterval(60);
      expect(saveManager.autoSaveIntervalSeconds, 60);
    });

    test('setAutoSaveInterval enforces minimum of 5 seconds', () {
      saveManager.setAutoSaveInterval(3);
      expect(saveManager.autoSaveIntervalSeconds, 5);

      saveManager.setAutoSaveInterval(1);
      expect(saveManager.autoSaveIntervalSeconds, 5);

      saveManager.setAutoSaveInterval(0);
      expect(saveManager.autoSaveIntervalSeconds, 5);
    });

    test('setAutoSaveInterval notifies listeners', () {
      int notifyCount = 0;
      saveManager.addListener(() => notifyCount++);

      saveManager.setAutoSaveInterval(45);
      expect(notifyCount, 1);
    });

    test('setAutoSaveInterval accepts values at or above minimum', () {
      saveManager.setAutoSaveInterval(5);
      expect(saveManager.autoSaveIntervalSeconds, 5);

      saveManager.setAutoSaveInterval(10);
      expect(saveManager.autoSaveIntervalSeconds, 10);

      saveManager.setAutoSaveInterval(120);
      expect(saveManager.autoSaveIntervalSeconds, 120);
    });
  });

  group('SaveManager - Save All', () {
    test('saveAll saves all registered systems', () async {
      final saveable1 = MockSaveable(
        saveKey: 'system_1',
        initialData: {'gold': 100},
      );
      final saveable2 = MockSaveable(
        saveKey: 'system_2',
        initialData: {'level': 5},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      await saveManager.saveAll();

      expect(saveable1.toSaveDataCallCount, 1);
      expect(saveable2.toSaveDataCallCount, 1);
    });

    test('saveAll updates lastSaveTime', () async {
      expect(saveManager.lastSaveTime, isNull);

      await saveManager.saveAll();

      expect(saveManager.lastSaveTime, isNotNull);
      expect(
        saveManager.lastSaveTime!.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('saveAll notifies listeners', () async {
      int notifyCount = 0;
      saveManager.addListener(() => notifyCount++);

      await saveManager.saveAll();

      expect(notifyCount, 1);
    });

    test('saveAll persists data to SharedPreferences', () async {
      final saveable = MockSaveable(
        saveKey: 'test_system',
        initialData: {'score': 42, 'name': 'Player1'},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('save_test_system'), true);
    });

    test('saveAll with no registered systems completes without error', () async {
      await expectLater(saveManager.saveAll(), completes);
      expect(saveManager.lastSaveTime, isNotNull);
    });
  });

  group('SaveManager - Load All', () {
    test('loadAll loads all registered systems', () async {
      // First save some data
      final saveable1 = MockSaveable(
        saveKey: 'system_1',
        initialData: {'gold': 100},
      );
      final saveable2 = MockSaveable(
        saveKey: 'system_2',
        initialData: {'level': 5},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);
      await saveManager.saveAll();

      // Clear and re-register with empty data
      saveable1.data = {};
      saveable2.data = {};
      saveable1.fromSaveDataCallCount = 0;
      saveable2.fromSaveDataCallCount = 0;

      await saveManager.loadAll();

      expect(saveable1.fromSaveDataCallCount, 1);
      expect(saveable2.fromSaveDataCallCount, 1);
    });

    test('loadAll restores saved data', () async {
      final saveable = MockSaveable(
        saveKey: 'test_system',
        initialData: {'gold': 500, 'gems': 25},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      // Simulate app restart by clearing data
      saveable.data = {};

      await saveManager.loadAll();

      expect(saveable.data['gold'], 500);
      expect(saveable.data['gems'], 25);
    });

    test('loadAll updates lastLoadTime', () async {
      expect(saveManager.lastLoadTime, isNull);

      await saveManager.loadAll();

      expect(saveManager.lastLoadTime, isNotNull);
      expect(
        saveManager.lastLoadTime!.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('loadAll notifies listeners', () async {
      int notifyCount = 0;
      saveManager.addListener(() => notifyCount++);

      await saveManager.loadAll();

      expect(notifyCount, 1);
    });

    test('loadAll does not call fromSaveData for systems without saved data', () async {
      final saveable = MockSaveable(saveKey: 'new_system');
      saveManager.registerSaveable(saveable);

      await saveManager.loadAll();

      expect(saveable.fromSaveDataCallCount, 0);
    });

    test('loadAll with no registered systems completes without error', () async {
      await expectLater(saveManager.loadAll(), completes);
      expect(saveManager.lastLoadTime, isNotNull);
    });

    test('loadAll restores lastSaveTime from storage', () async {
      final saveable = MockSaveable(
        saveKey: 'test',
        initialData: {'value': 1},
      );
      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      final savedTime = saveManager.lastSaveTime;

      // Create new SaveManager instance
      final newSaveManager = SaveManager();
      newSaveManager.registerSaveable(saveable);
      await newSaveManager.loadAll();

      expect(newSaveManager.lastSaveTime, isNotNull);
      expect(
        newSaveManager.lastSaveTime!.toIso8601String(),
        savedTime!.toIso8601String(),
      );

      newSaveManager.dispose();
    });
  });

  group('SaveManager - Save System', () {
    test('saveSystem saves specific system', () async {
      final saveable1 = MockSaveable(
        saveKey: 'system_1',
        initialData: {'value': 1},
      );
      final saveable2 = MockSaveable(
        saveKey: 'system_2',
        initialData: {'value': 2},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      await saveManager.saveSystem('system_1');

      expect(saveable1.toSaveDataCallCount, 1);
      expect(saveable2.toSaveDataCallCount, 0);
    });

    test('saveSystem persists data for specific system', () async {
      final saveable = MockSaveable(
        saveKey: 'specific_system',
        initialData: {'score': 100},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveSystem('specific_system');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('save_specific_system'), true);
    });

    test('saveSystem does nothing for non-existent key', () async {
      final saveable = MockSaveable(saveKey: 'existing');
      saveManager.registerSaveable(saveable);

      await saveManager.saveSystem('non_existent');

      expect(saveable.toSaveDataCallCount, 0);
    });
  });

  group('SaveManager - Load System', () {
    test('loadSystem loads specific system', () async {
      final saveable1 = MockSaveable(
        saveKey: 'system_1',
        initialData: {'value': 1},
      );
      final saveable2 = MockSaveable(
        saveKey: 'system_2',
        initialData: {'value': 2},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);
      await saveManager.saveAll();

      saveable1.fromSaveDataCallCount = 0;
      saveable2.fromSaveDataCallCount = 0;

      await saveManager.loadSystem('system_1');

      expect(saveable1.fromSaveDataCallCount, 1);
      expect(saveable2.fromSaveDataCallCount, 0);
    });

    test('loadSystem restores data for specific system', () async {
      final saveable = MockSaveable(
        saveKey: 'specific_system',
        initialData: {'level': 10},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveSystem('specific_system');

      saveable.data = {};

      await saveManager.loadSystem('specific_system');

      expect(saveable.data['level'], 10);
    });

    test('loadSystem does nothing for non-existent key', () async {
      final saveable = MockSaveable(saveKey: 'existing');
      saveManager.registerSaveable(saveable);

      await saveManager.loadSystem('non_existent');

      expect(saveable.fromSaveDataCallCount, 0);
    });

    test('loadSystem does nothing when no saved data exists', () async {
      final saveable = MockSaveable(saveKey: 'no_saved_data');
      saveManager.registerSaveable(saveable);

      await saveManager.loadSystem('no_saved_data');

      expect(saveable.fromSaveDataCallCount, 0);
    });
  });

  group('SaveManager - Clear All', () {
    test('clearAll removes all saved data', () async {
      final saveable1 = MockSaveable(
        saveKey: 'system_1',
        initialData: {'value': 1},
      );
      final saveable2 = MockSaveable(
        saveKey: 'system_2',
        initialData: {'value': 2},
      );

      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);
      await saveManager.saveAll();

      await saveManager.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('save_system_1'), false);
      expect(prefs.containsKey('save_system_2'), false);
      expect(prefs.containsKey('save_last_save_time'), false);
    });

    test('clearAll resets lastSaveTime and lastLoadTime', () async {
      await saveManager.saveAll();
      await saveManager.loadAll();

      expect(saveManager.lastSaveTime, isNotNull);
      expect(saveManager.lastLoadTime, isNotNull);

      await saveManager.clearAll();

      expect(saveManager.lastSaveTime, isNull);
      expect(saveManager.lastLoadTime, isNull);
    });

    test('clearAll notifies listeners', () async {
      int notifyCount = 0;
      saveManager.addListener(() => notifyCount++);

      await saveManager.clearAll();

      expect(notifyCount, 1);
    });

    test('clearAll with no registered systems completes without error', () async {
      await expectLater(saveManager.clearAll(), completes);
    });
  });

  group('SaveManager - Has Save Data', () {
    test('hasSaveData returns true for existing save', () async {
      final saveable = MockSaveable(
        saveKey: 'existing_save',
        initialData: {'data': 123},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      final hasSave = await saveManager.hasSaveData('existing_save');
      expect(hasSave, true);
    });

    test('hasSaveData returns false for non-existent save', () async {
      final hasSave = await saveManager.hasSaveData('non_existent_key');
      expect(hasSave, false);
    });

    test('hasSaveData returns false after clearAll', () async {
      final saveable = MockSaveable(
        saveKey: 'cleared_save',
        initialData: {'data': 456},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      expect(await saveManager.hasSaveData('cleared_save'), true);

      await saveManager.clearAll();

      expect(await saveManager.hasSaveData('cleared_save'), false);
    });
  });

  group('SaveManager - JSON Encoding/Decoding', () {
    test('correctly encodes and decodes string values', () async {
      final saveable = MockSaveable(
        saveKey: 'string_test',
        initialData: {'name': 'TestPlayer', 'guild': 'Heroes'},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['name'], 'TestPlayer');
      expect(saveable.data['guild'], 'Heroes');
    });

    test('correctly encodes and decodes integer values', () async {
      final saveable = MockSaveable(
        saveKey: 'int_test',
        initialData: {'score': 1000, 'level': 42, 'health': 100},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['score'], 1000);
      expect(saveable.data['level'], 42);
      expect(saveable.data['health'], 100);
    });

    test('correctly encodes and decodes double values', () async {
      final saveable = MockSaveable(
        saveKey: 'double_test',
        initialData: {'multiplier': 1.5, 'percentage': 0.75},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['multiplier'], 1.5);
      expect(saveable.data['percentage'], 0.75);
    });

    test('correctly encodes and decodes boolean values', () async {
      final saveable = MockSaveable(
        saveKey: 'bool_test',
        initialData: {'isActive': true, 'isPremium': false},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['isActive'], true);
      expect(saveable.data['isPremium'], false);
    });

    test('correctly encodes and decodes null values', () async {
      final saveable = MockSaveable(
        saveKey: 'null_test',
        initialData: {'emptyField': null, 'name': 'test'},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['emptyField'], isNull);
      expect(saveable.data['name'], 'test');
    });

    test('correctly encodes and decodes mixed data types', () async {
      final saveable = MockSaveable(
        saveKey: 'mixed_test',
        initialData: {
          'name': 'Player',
          'score': 5000,
          'multiplier': 2.5,
          'isPremium': true,
          'lastLogin': null,
        },
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['name'], 'Player');
      expect(saveable.data['score'], 5000);
      expect(saveable.data['multiplier'], 2.5);
      expect(saveable.data['isPremium'], true);
      expect(saveable.data['lastLogin'], isNull);
    });

    test('correctly encodes strings with special characters', () async {
      final saveable = MockSaveable(
        saveKey: 'special_chars',
        initialData: {'message': 'Hello, "World"!'},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['message'], 'Hello, "World"!');
    });

    test('correctly handles empty map', () async {
      final saveable = MockSaveable(
        saveKey: 'empty_map',
        initialData: {},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {'temp': 'value'};
      await saveManager.loadAll();

      expect(saveable.data, isEmpty);
    });

    test('correctly handles large integer values', () async {
      final saveable = MockSaveable(
        saveKey: 'large_int',
        initialData: {'bigNumber': 9999999999},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['bigNumber'], 9999999999);
    });

    test('correctly handles negative numbers', () async {
      final saveable = MockSaveable(
        saveKey: 'negative_test',
        initialData: {'negInt': -100, 'negDouble': -3.14},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['negInt'], -100);
      expect(saveable.data['negDouble'], -3.14);
    });
  });

  group('SaveManager - Listener Notifications', () {
    test('addListener and removeListener work correctly', () {
      int notifyCount = 0;
      void listener() => notifyCount++;

      saveManager.addListener(listener);
      saveManager.setAutoSaveEnabled(false);
      expect(notifyCount, 1);

      saveManager.removeListener(listener);
      saveManager.setAutoSaveEnabled(true);
      expect(notifyCount, 1); // Should not increase
    });

    test('multiple listeners are notified', () {
      int listener1Count = 0;
      int listener2Count = 0;

      saveManager.addListener(() => listener1Count++);
      saveManager.addListener(() => listener2Count++);

      saveManager.setAutoSaveEnabled(false);

      expect(listener1Count, 1);
      expect(listener2Count, 1);
    });
  });

  group('SaveManager - Dispose', () {
    test('dispose stops auto-save timer', () {
      final manager = SaveManager();
      manager.setAutoSaveEnabled(true);
      manager.setAutoSaveInterval(5);

      // Should not throw
      expect(() => manager.dispose(), returnsNormally);
    });

    test('dispose completes successfully', () {
      final manager = SaveManager();
      manager.setAutoSaveEnabled(true);

      // Dispose should complete without error
      expect(() => manager.dispose(), returnsNormally);
    });
  });

  group('SaveManager - Edge Cases', () {
    test('save and load with zero integer', () async {
      final saveable = MockSaveable(
        saveKey: 'zero_test',
        initialData: {'count': 0},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {'count': 999};
      await saveManager.loadAll();

      expect(saveable.data['count'], 0);
    });

    test('save and load with empty string', () async {
      final saveable = MockSaveable(
        saveKey: 'empty_string_test',
        initialData: {'text': ''},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {'text': 'not empty'};
      await saveManager.loadAll();

      expect(saveable.data['text'], '');
    });

    test('multiple save operations overwrite previous data', () async {
      final saveable = MockSaveable(
        saveKey: 'overwrite_test',
        initialData: {'value': 1},
      );

      saveManager.registerSaveable(saveable);
      await saveManager.saveAll();

      saveable.data = {'value': 2};
      await saveManager.saveAll();

      saveable.data = {'value': 3};
      await saveManager.saveAll();

      saveable.data = {};
      await saveManager.loadAll();

      expect(saveable.data['value'], 3);
    });

    test('registering same saveable twice only keeps one reference', () async {
      final saveable = MockSaveable(
        saveKey: 'duplicate_register',
        initialData: {'value': 1},
      );

      saveManager.registerSaveable(saveable);
      saveManager.registerSaveable(saveable);

      await saveManager.saveAll();

      // toSaveData should only be called once per saveAll
      expect(saveable.toSaveDataCallCount, 1);
    });
  });

  group('SaveManager - Integration Scenarios', () {
    test('full save/load cycle with multiple systems', () async {
      final inventorySystem = MockSaveable(
        saveKey: 'inventory',
        initialData: {'slots': 20, 'items': 5},
      );

      final progressSystem = MockSaveable(
        saveKey: 'progress',
        initialData: {'level': 10, 'exp': 2500},
      );

      final settingsSystem = MockSaveable(
        saveKey: 'settings',
        initialData: {'musicVolume': 0.8, 'sfxEnabled': true},
      );

      saveManager.registerSaveable(inventorySystem);
      saveManager.registerSaveable(progressSystem);
      saveManager.registerSaveable(settingsSystem);

      // Save all systems
      await saveManager.saveAll();

      // Simulate app restart - clear all data
      inventorySystem.data = {};
      progressSystem.data = {};
      settingsSystem.data = {};

      // Load all systems
      await saveManager.loadAll();

      // Verify all data restored
      expect(inventorySystem.data['slots'], 20);
      expect(inventorySystem.data['items'], 5);
      expect(progressSystem.data['level'], 10);
      expect(progressSystem.data['exp'], 2500);
      expect(settingsSystem.data['musicVolume'], 0.8);
      expect(settingsSystem.data['sfxEnabled'], true);
    });

    test('unregistering system prevents its save but not others', () async {
      final system1 = MockSaveable(
        saveKey: 'system1',
        initialData: {'value': 1},
      );
      final system2 = MockSaveable(
        saveKey: 'system2',
        initialData: {'value': 2},
      );

      saveManager.registerSaveable(system1);
      saveManager.registerSaveable(system2);

      // First save
      await saveManager.saveAll();

      // Unregister system1
      saveManager.unregisterSaveable('system1');

      // Update and save again
      system2.data = {'value': 22};
      await saveManager.saveAll();

      // Only system2 should be called
      expect(system1.toSaveDataCallCount, 1); // Only from first save
      expect(system2.toSaveDataCallCount, 2); // From both saves
    });

    test('saveKey property returns correct key', () {
      final saveable = MockSaveable(saveKey: 'my_unique_key');
      expect(saveable.saveKey, 'my_unique_key');
    });
  });
}

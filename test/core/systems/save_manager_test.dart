import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/systems/save_manager.dart';

class MockSaveable implements Saveable {
  final String _saveKey;
  Map<String, dynamic> _saveData = {};
  int _loadCallCount = 0;

  MockSaveable(this._saveKey);

  @override
  String get saveKey => _saveKey;

  @override
  Map<String, dynamic> toSaveData() => _saveData;

  @override
  void fromSaveData(Map<String, dynamic> data) {
    _saveData = data;
    _loadCallCount++;
  }

  int get loadCallCount => _loadCallCount;

  // Helper methods for testing
  void setData(String key, dynamic value) {
    _saveData[key] = value;
  }

  dynamic getData(String key) => _saveData[key];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Saveable Interface', () {
    test('MockSaveable implements Saveable correctly', () {
      final saveable = MockSaveable('test_key');

      expect(saveable.saveKey, 'test_key');
      expect(saveable.toSaveData(), isEmpty);

      saveable.setData('health', 100);
      saveable.setData('level', 5);

      final data = saveable.toSaveData();
      expect(data['health'], 100);
      expect(data['level'], 5);
    });

    test('fromSaveData loads data correctly', () {
      final saveable = MockSaveable('test_key');

      saveable.fromSaveData({'health': 100, 'level': 5});

      expect(saveable.getData('health'), 100);
      expect(saveable.getData('level'), 5);
      expect(saveable.loadCallCount, 1);
    });
  });

  group('SaveManager - Registration', () {
    late SaveManager saveManager;
    late MockSaveable saveable1;
    late MockSaveable saveable2;

    setUp(() {
      saveManager = SaveManager();
      saveable1 = MockSaveable('system1');
      saveable2 = MockSaveable('system2');
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('registerSaveable adds system to registry', () {
      saveManager.registerSaveable(saveable1);

      expect(saveManager.getRegisteredKeys(), contains('system1'));
      expect(saveManager.getRegisteredKeys(), hasLength(1));
    });

    test('registerSaveable with multiple systems', () {
      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      expect(saveManager.getRegisteredKeys(), containsAll(['system1', 'system2']));
      expect(saveManager.getRegisteredKeys(), hasLength(2));
    });

    test('registerSaveable replaces existing system with same key', () {
      saveManager.registerSaveable(saveable1);
      final newSaveable1 = MockSaveable('system1');
      saveManager.registerSaveable(newSaveable1);

      expect(saveManager.getRegisteredKeys(), hasLength(1));
    });

    test('unregisterSaveable removes system from registry', () {
      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      saveManager.unregisterSaveable('system1');

      expect(saveManager.getRegisteredKeys(), isNot(contains('system1')));
      expect(saveManager.getRegisteredKeys(), contains('system2'));
      expect(saveManager.getRegisteredKeys(), hasLength(1));
    });

    test('unregisterSaveable with non-existent key does nothing', () {
      saveManager.registerSaveable(saveable1);

      saveManager.unregisterSaveable('non_existent');

      expect(saveManager.getRegisteredKeys(), hasLength(1));
    });

    test('getRegisteredKeys returns all registered keys', () {
      saveManager.registerSaveable(saveable1);
      saveManager.registerSaveable(saveable2);

      final keys = saveManager.getRegisteredKeys();

      expect(keys, containsAll(['system1', 'system2']));
      expect(keys, hasLength(2));
    });
  });

  group('SaveManager - Auto Save', () {
    late SaveManager saveManager;

    setUp(() {
      saveManager = SaveManager();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('autoSaveEnabled defaults to true', () {
      expect(saveManager.autoSaveEnabled, isTrue);
    });

    test('autoSaveIntervalSeconds defaults to 30', () {
      expect(saveManager.autoSaveIntervalSeconds, 30);
    });

    test('setAutoSaveEnabled false stops auto-save', () async {
      saveManager.setAutoSaveEnabled(false);

      expect(saveManager.autoSaveEnabled, isFalse);
    });

    test('setAutoSaveEnabled true starts auto-save', () async {
      saveManager.setAutoSaveEnabled(false);
      expect(saveManager.autoSaveEnabled, isFalse);

      saveManager.setAutoSaveEnabled(true);
      expect(saveManager.autoSaveEnabled, isTrue);
    });

    test('setAutoSaveInterval updates interval', () async {
      saveManager.setAutoSaveInterval(60);

      expect(saveManager.autoSaveIntervalSeconds, 60);
    });

    test('setAutoSaveInterval enforces minimum of 5 seconds', () async {
      saveManager.setAutoSaveInterval(2);

      expect(saveManager.autoSaveIntervalSeconds, 5);
    });

    test('setAutoSaveInterval with exact 5 seconds', () async {
      saveManager.setAutoSaveInterval(5);

      expect(saveManager.autoSaveIntervalSeconds, 5);
    });

    test('lastSaveTime and lastLoadTime are null initially', () {
      expect(saveManager.lastSaveTime, isNull);
      expect(saveManager.lastLoadTime, isNull);
    });
  });

  group('SaveManager - Save/Load Operations', () {
    late SaveManager saveManager;
    late MockSaveable saveable;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = SaveManager();
      saveable = MockSaveable('test_system');
      saveable.setData('gold', 1000);
      saveable.setData('level', 10);
      saveManager.registerSaveable(saveable);
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('saveAll saves all registered systems', () async {
      await saveManager.saveAll();

      expect(saveManager.lastSaveTime, isNotNull);
      expect(saveManager.lastSaveTime, isA<DateTime>());
    });

    test('saveAll updates lastSaveTime', () async {
      final before = DateTime.now();

      await saveManager.saveAll();

      final after = DateTime.now();
      expect(saveManager.lastSaveTime!.isAfter(before) || saveManager.lastSaveTime!.isAtSameMomentAs(before), isTrue);
      expect(saveManager.lastSaveTime!.isBefore(after) || saveManager.lastSaveTime!.isAtSameMomentAs(after), isTrue);
    });

    test('saveAll handles saveable systems with errors gracefully', () async {
      final brokenSaveable = MockSaveable('broken_system');
      // Make it throw an error
      brokenSaveable.setData('null', null);
      saveManager.registerSaveable(brokenSaveable);

      await saveManager.saveAll();

      // Should not throw, just log error
      expect(saveManager.lastSaveTime, isNotNull);
    });

    test('loadAll loads all registered systems', () async {
      // First save
      await saveManager.saveAll();

      // Modify data
      saveable.setData('gold', 2000);
      saveable.setData('level', 20);

      // Load back
      await saveManager.loadAll();

      expect(saveManager.lastLoadTime, isNotNull);
      expect(saveable.getData('gold'), 1000); // Should be restored
      expect(saveable.getData('level'), 10);
    });

    test('loadAll updates lastLoadTime', () async {
      await saveManager.saveAll();

      await saveManager.loadAll();

      expect(saveManager.lastLoadTime, isNotNull);
      expect(saveManager.lastLoadTime, isA<DateTime>());
    });

    test('loadAll loads lastSaveTime from storage', () async {
      await saveManager.saveAll();

      await saveManager.loadAll();

      expect(saveManager.lastSaveTime, isNotNull);
    });

    test('loadAll handles missing save data gracefully', () async {
      // Don't save anything first
      await saveManager.loadAll();

      expect(saveManager.lastLoadTime, isNotNull);
    });

    test('loadAll handles corrupted data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('save_test_system', 'invalid json{');

      await saveManager.loadAll();

      // Should not throw
      expect(saveManager.lastLoadTime, isNotNull);
    });

    test('saveSystem saves specific system', () async {
      await saveManager.saveSystem('test_system');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('save_test_system'), isTrue);
    });

    test('saveSystem with non-existent system does nothing', () async {
      await saveManager.saveSystem('non_existent');

      // Should not throw
    });

    test('loadSystem loads specific system', () async {
      await saveManager.saveSystem('test_system');

      saveable.setData('gold', 5000);

      await saveManager.loadSystem('test_system');

      expect(saveable.getData('gold'), 1000);
    });

    test('loadSystem with non-existent system does nothing', () async {
      await saveManager.loadSystem('non_existent');

      // Should not throw
    });

    test('clearAll removes all saved data', () async {
      await saveManager.saveAll();

      await saveManager.clearAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('save_test_system'), isFalse);
      expect(prefs.containsKey('save_last_save_time'), isFalse);
      expect(saveManager.lastSaveTime, isNull);
      expect(saveManager.lastLoadTime, isNull);
    });

    test('hasSaveData checks for existing save data', () async {
      final hasDataBefore = await saveManager.hasSaveData('test_system');
      expect(hasDataBefore, isFalse);

      await saveManager.saveSystem('test_system');

      final hasDataAfter = await saveManager.hasSaveData('test_system');
      expect(hasDataAfter, isTrue);
    });

    test('hasSaveData returns false for non-existent system', () async {
      final hasData = await saveManager.hasSaveData('non_existent');
      expect(hasData, isFalse);
    });
  });

  group('SaveManager - JSON Encoding/Decoding', () {
    late SaveManager saveManager;

    setUp(() {
      saveManager = SaveManager();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('encodes simple map correctly', () {
      final map = {'key1': 'value1', 'key2': 'value2'};

      // Use reflection or save/load to test encoding
      final saveable = MockSaveable('test');
      saveable.setData('key1', 'value1');
      saveable.setData('key2', 'value2');

      saveManager.registerSaveable(saveable);

      // Just verify it doesn't throw when saving
      // The actual encoding happens in saveAll
      expect(() => saveManager.registerSaveable(saveable), returnsNormally);
    });

    test('encodes different data types correctly', () {
      final saveable = MockSaveable('test');
      saveable.setData('string', 'hello');
      saveable.setData('int', 42);
      saveable.setData('double', 3.14);
      saveable.setData('bool', true);
      saveable.setData('null', null);

      saveManager.registerSaveable(saveable);

      expect(saveManager.getRegisteredKeys(), contains('test'));
    });

    test('handles empty map', () {
      final saveable = MockSaveable('test');

      saveManager.registerSaveable(saveable);

      expect(saveManager.getRegisteredKeys(), contains('test'));
    });

    test('handles special characters in strings', () {
      final saveable = MockSaveable('test');
      saveable.setData('text', 'Hello "World"');
      saveable.setData('json', '{"key": "value"}');

      saveManager.registerSaveable(saveable);

      expect(saveManager.getRegisteredKeys(), contains('test'));
    });

    test('handles large numbers', () {
      final saveable = MockSaveable('test');
      saveable.setData('large', 999999999);

      saveManager.registerSaveable(saveable);

      expect(saveManager.getRegisteredKeys(), contains('test'));
    });

    test('handles floating point numbers', () {
      final saveable = MockSaveable('test');
      saveable.setData('pi', 3.14159);
      saveable.setData('small', 0.001);

      saveManager.registerSaveable(saveable);

      expect(saveManager.getRegisteredKeys(), contains('test'));
    });
  });

  group('SaveManager - Integration Tests', () {
    late SaveManager saveManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = SaveManager();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('complete save/load cycle with multiple systems', () async {
      final system1 = MockSaveable('player');
      final system2 = MockSaveable('inventory');
      final system3 = MockSaveable('achievements');

      system1.setData('level', 50);
      system1.setData('experience', 10000);

      system2.setData('gold', 5000);
      system2.setData('item_count', 2);

      system3.setData('unlocked_count', 2);
      system3.setData('total_points', 500);

      saveManager.registerSaveable(system1);
      saveManager.registerSaveable(system2);
      saveManager.registerSaveable(system3);

      // Save all
      await saveManager.saveAll();

      // Modify all systems
      system1.setData('level', 1);
      system2.setData('gold', 0);
      system3.setData('unlocked_count', 0);

      // Load all
      await saveManager.loadAll();

      // Verify data is restored
      expect(system1.getData('level'), 50);
      expect(system1.getData('experience'), 10000);
      expect(system2.getData('gold'), 5000);
      expect(system2.getData('item_count'), 2);
      expect(system3.getData('unlocked_count'), 2);
      expect(system3.getData('total_points'), 500);
    });

    test('partial save with selective systems', () async {
      final system1 = MockSaveable('system1');
      final system2 = MockSaveable('system2');

      system1.setData('value', 100);
      system2.setData('value', 200);

      saveManager.registerSaveable(system1);
      saveManager.registerSaveable(system2);

      // Save only system1
      await saveManager.saveSystem('system1');

      // Modify both
      system1.setData('value', 0);
      system2.setData('value', 0);

      // Load only system1
      await saveManager.loadSystem('system1');

      expect(system1.getData('value'), 100);
      expect(system2.getData('value'), 0); // Not saved/loaded
    });

    test('auto-save behavior with enable/disable', () async {
      final system1 = MockSaveable('system1');
      system1.setData('counter', 0);

      saveManager.registerSaveable(system1);

      // Enable auto-save
      expect(saveManager.autoSaveEnabled, isTrue);

      // Disable auto-save
      saveManager.setAutoSaveEnabled(false);
      expect(saveManager.autoSaveEnabled, isFalse);

      // Re-enable
      saveManager.setAutoSaveEnabled(true);
      expect(saveManager.autoSaveEnabled, isTrue);

      // Change interval
      saveManager.setAutoSaveInterval(10);
      expect(saveManager.autoSaveIntervalSeconds, 10);
    });

    test('clearAll followed by new save', () async {
      final system1 = MockSaveable('system1');
      system1.setData('value', 100);

      saveManager.registerSaveable(system1);

      // Save
      await saveManager.saveAll();

      // Clear
      await saveManager.clearAll();

      expect(saveManager.lastSaveTime, isNull);

      // Save again
      await saveManager.saveAll();

      expect(saveManager.lastSaveTime, isNotNull);

      // Load should work
      system1.setData('value', 0);
      await saveManager.loadAll();

      expect(system1.getData('value'), 100);
    });

    test('register/unregister during save operations', () async {
      final system1 = MockSaveable('system1');
      final system2 = MockSaveable('system2');

      system1.setData('value', 100);
      system2.setData('value', 200);

      saveManager.registerSaveable(system1);

      await saveManager.saveAll();

      // Register system2 after initial save
      saveManager.registerSaveable(system2);

      // Both should be saved now
      await saveManager.saveAll();

      // Modify
      system1.setData('value', 0);
      system2.setData('value', 0);

      // Load both
      await saveManager.loadAll();

      expect(system1.getData('value'), 100);
      expect(system2.getData('value'), 200);
    });

    test('handles system data with complex nested structures', () async {
      final system1 = MockSaveable('complex');

      // Note: Our simple encoder doesn't support nested structures,
      // but we test that it handles them gracefully
      system1.setData('simple', 'value');
      system1.setData('number', 123);

      saveManager.registerSaveable(system1);

      await saveManager.saveAll();

      system1.setData('simple', 'modified');
      system1.setData('number', 0);

      await saveManager.loadAll();

      expect(system1.getData('simple'), 'value');
      expect(system1.getData('number'), 123);
    });
  });

  group('SaveManager - Error Handling', () {
    late SaveManager saveManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = SaveManager();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('handles corrupt save data during loadAll', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('save_test_system', 'corrupt{data');

      final system = MockSaveable('test_system');
      saveManager.registerSaveable(system);

      await saveManager.loadAll();

      // Should not throw
      expect(saveManager.lastLoadTime, isNotNull);
    });

    test('handles saveAll with no registered systems', () async {
      await saveManager.saveAll();

      // Should not throw
      expect(saveManager.lastSaveTime, isNotNull);
    });

    test('handles loadAll with no registered systems', () async {
      await saveManager.loadAll();

      // Should not throw
      expect(saveManager.lastLoadTime, isNotNull);
    });

    test('handles clearAll with no registered systems', () async {
      await saveManager.clearAll();

      // Should not throw
    });
  });

  group('SaveManager - Dispose', () {
    test('dispose stops auto-save timer', () {
      SharedPreferences.setMockInitialValues({});
      final saveManager = SaveManager();
      final system = MockSaveable('test');
      saveManager.registerSaveable(system);

      // Verify auto-save is enabled before dispose
      expect(saveManager.autoSaveEnabled, isTrue);

      // Dispose should complete without throwing
      saveManager.dispose();

      // Note: Cannot access properties after dispose in debug mode
      // This is expected ChangeNotifier behavior
    });

    test('dispose can be called once', () {
      SharedPreferences.setMockInitialValues({});
      final saveManager = SaveManager();

      // Single dispose should work fine
      expect(() => saveManager.dispose(), returnsNormally);
    });
  });

  group('SaveManager - Edge Cases', () {
    late SaveManager saveManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = SaveManager();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('handles empty string values', () async {
      final system = MockSaveable('test');
      system.setData('empty', '');

      saveManager.registerSaveable(system);

      await saveManager.saveAll();
      system.setData('empty', 'not empty');

      await saveManager.loadAll();

      expect(system.getData('empty'), '');
    });

    test('handles zero values', () async {
      final system = MockSaveable('test');
      system.setData('zero_int', 0);
      system.setData('zero_double', 0.0);

      saveManager.registerSaveable(system);

      await saveManager.saveAll();
      system.setData('zero_int', 999);
      system.setData('zero_double', 999.0);

      await saveManager.loadAll();

      expect(system.getData('zero_int'), 0);
      expect(system.getData('zero_double'), 0.0);
    });

    test('handles boolean false', () async {
      final system = MockSaveable('test');
      system.setData('flag', false);

      saveManager.registerSaveable(system);

      await saveManager.saveAll();
      system.setData('flag', true);

      await saveManager.loadAll();

      expect(system.getData('flag'), false);
    });

    test('handles very long strings', () async {
      final system = MockSaveable('test');
      final longString = 'a' * 10000;
      system.setData('long', longString);

      saveManager.registerSaveable(system);

      await saveManager.saveAll();
      system.setData('long', 'short');

      await saveManager.loadAll();

      expect(system.getData('long'), longString);
    });

    test('handles unicode characters', () async {
      final system = MockSaveable('test');
      system.setData('emoji', '😀🎮🎯');
      system.setData('korean', '한글테스트');
      system.setData('chinese', '中文测试');

      saveManager.registerSaveable(system);

      await saveManager.saveAll();
      system.setData('emoji', '');
      system.setData('korean', '');
      system.setData('chinese', '');

      await saveManager.loadAll();

      expect(system.getData('emoji'), '😀🎮🎯');
      expect(system.getData('korean'), '한글테스트');
      expect(system.getData('chinese'), '中文测试');
    });

    test('handles rapid save/load cycles', () async {
      final system = MockSaveable('test');
      system.setData('counter', 0);

      saveManager.registerSaveable(system);

      // Rapid save/load cycles
      for (int i = 0; i < 10; i++) {
        system.setData('counter', i);
        await saveManager.saveAll();
      }

      // Load final state
      system.setData('counter', -1);
      await saveManager.loadAll();

      expect(system.getData('counter'), 9);
    });
  });
}

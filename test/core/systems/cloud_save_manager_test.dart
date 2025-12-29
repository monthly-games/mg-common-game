import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/systems/cloud_save_manager.dart';

void main() {
  late CloudSaveManager manager;
  late MockCloudStorageProvider mockProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockProvider = MockCloudStorageProvider();
    manager = CloudSaveManager(cloudProvider: mockProvider);
  });

  tearDown(() {
    manager.dispose();
    mockProvider.clear();
  });

  group('CloudSaveManager - Initialization', () {
    test('should start with notInitialized status', () {
      expect(manager.syncStatus, SyncStatus.notInitialized);
      expect(manager.isInitialized, false);
    });

    test('should initialize successfully', () async {
      await manager.initialize();

      expect(manager.isInitialized, true);
      expect(manager.syncStatus, SyncStatus.synced);
    });

    test('should not reinitialize if already initialized', () async {
      await manager.initialize();
      final firstStatus = manager.syncStatus;

      await manager.initialize();

      expect(manager.syncStatus, firstStatus);
      expect(manager.isInitialized, true);
    });

    test('should fail initialization when provider fails', () async {
      mockProvider.setShouldFail(true);

      await expectLater(manager.initialize(), throwsException);
      expect(manager.isInitialized, false);
    });

    test('should load cached data on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'cloud_save_cache':
            '{"testKey":{"key":"testKey","data":{"value":123},"lastModified":"2024-01-01T00:00:00.000","version":1}}',
        'cloud_save_last_sync': '2024-01-01T00:00:00.000',
      });
      manager = CloudSaveManager(cloudProvider: mockProvider);

      await manager.initialize();

      expect(manager.cachedKeys.contains('testKey'), true);
      expect(manager.lastSyncTime, isNotNull);
    });
  });

  group('CloudSaveManager - Save Operations', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should save data locally', () async {
      final result = await manager.saveToCloud('testKey', {'value': 100});

      expect(result, true);
      expect(manager.cachedKeys.contains('testKey'), true);
    });

    test('should queue upload after save', () async {
      await manager.saveToCloud('testKey', {'value': 100});

      expect(manager.pendingUploads.contains('testKey'), true);
      expect(manager.syncStatus, SyncStatus.pendingUpload);
    });

    test('should increment version on save', () async {
      await manager.saveToCloud('testKey', {'value': 100});
      final firstVersion = manager.getLocalData('testKey')!.version;

      await manager.saveToCloud('testKey', {'value': 200});
      final secondVersion = manager.getLocalData('testKey')!.version;

      expect(secondVersion, firstVersion + 1);
    });

    test('should calculate checksum on save', () async {
      await manager.saveToCloud('testKey', {'value': 100});

      final data = manager.getLocalData('testKey');
      expect(data?.checksum, isNotNull);
      expect(data!.checksum!.isNotEmpty, true);
    });

    test('should fail save when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result =
          await uninitializedManager.saveToCloud('testKey', {'value': 100});

      expect(result, false);
    });

    test('should persist cache to SharedPreferences', () async {
      await manager.saveToCloud('testKey', {'value': 100});

      final prefs = await SharedPreferences.getInstance();
      final cache = prefs.getString('cloud_save_cache');

      expect(cache, isNotNull);
      expect(cache!.contains('testKey'), true);
    });
  });

  group('CloudSaveManager - Load Operations', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should load from local cache', () async {
      await manager.saveToCloud('testKey', {'value': 100});

      final data = await manager.loadFromCloud('testKey');

      expect(data, isNotNull);
      expect(data!['value'], 100);
    });

    test('should return null for missing key', () async {
      final data = await manager.loadFromCloud('nonexistent');

      expect(data, isNull);
    });

    test('should fetch from cloud when not in cache', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'cloudKey',
        data: {'value': 200},
        lastModified: DateTime.now(),
      ));

      final data = await manager.loadFromCloud('cloudKey');

      expect(data, isNotNull);
      expect(data!['value'], 200);
    });

    test('should cache data fetched from cloud', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'cloudKey',
        data: {'value': 200},
        lastModified: DateTime.now(),
      ));

      await manager.loadFromCloud('cloudKey');

      expect(manager.cachedKeys.contains('cloudKey'), true);
    });

    test('should return null when cloud fetch fails', () async {
      mockProvider.setShouldFail(true);

      final data = await manager.loadFromCloud('anyKey');

      expect(data, isNull);
    });

    test('should fail load when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.loadFromCloud('testKey');

      expect(result, isNull);
    });
  });

  group('CloudSaveManager - Sync Operations', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should sync key successfully', () async {
      await manager.saveToCloud('testKey', {'value': 100});

      final result = await manager.syncKey('testKey');

      expect(result.success, true);
      expect(result.status, SyncStatus.synced);
    });

    test('should return success for non-existent key', () async {
      final result = await manager.syncKey('nonexistent');

      expect(result.success, true);
    });

    test('should download cloud-only data on sync', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'cloudOnly',
        data: {'value': 300},
        lastModified: DateTime.now(),
      ));

      final result = await manager.syncKey('cloudOnly');

      expect(result.success, true);
      expect(manager.cachedKeys.contains('cloudOnly'), true);
    });

    test('should upload local-only data on sync', () async {
      await manager.saveToCloud('localOnly', {'value': 400});

      final result = await manager.syncKey('localOnly');

      expect(result.success, true);
      expect(manager.pendingUploads.contains('localOnly'), false);
    });

    test('should fail sync when cloud is unavailable', () async {
      mockProvider.setAvailable(false);

      final result = await manager.syncKey('testKey');

      expect(result.success, false);
      expect(result.error, 'Cloud not available');
    });

    test('should fail sync when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.syncKey('testKey');

      expect(result.success, false);
      expect(result.error, 'Not initialized');
    });
  });

  group('CloudSaveManager - Sync All', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should sync all pending uploads', () async {
      await manager.saveToCloud('key1', {'value': 1});
      await manager.saveToCloud('key2', {'value': 2});
      await manager.saveToCloud('key3', {'value': 3});

      final result = await manager.syncAll();

      expect(result.success, true);
      expect(manager.pendingUploads.isEmpty, true);
    });

    test('should download all cloud keys', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'cloud1',
        data: {'value': 10},
        lastModified: DateTime.now(),
      ));
      await mockProvider.upload(CloudSaveData(
        key: 'cloud2',
        data: {'value': 20},
        lastModified: DateTime.now(),
      ));

      await manager.syncAll();

      expect(manager.cachedKeys.contains('cloud1'), true);
      expect(manager.cachedKeys.contains('cloud2'), true);
    });

    test('should update lastSyncTime after sync', () async {
      expect(manager.lastSyncTime, isNull);

      await manager.syncAll();

      expect(manager.lastSyncTime, isNotNull);
    });

    test('should set status to syncing during sync', () async {
      mockProvider.setLatency(100);
      final syncFuture = manager.syncAll();

      await Future.delayed(const Duration(milliseconds: 50));
      expect(manager.syncStatus, SyncStatus.syncing);

      await syncFuture;
    });

    test('should handle partial sync failure', () async {
      await manager.saveToCloud('key1', {'value': 1});

      mockProvider.setShouldFail(true);

      final result = await manager.syncAll();

      expect(result.success, false);
      expect(manager.syncStatus, SyncStatus.failed);
    });

    test('should fail syncAll when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.syncAll();

      expect(result.success, false);
    });
  });

  group('CloudSaveManager - Conflict Resolution', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should use local data when resolution is useLocal', () async {
      manager.setConflictResolution(ConflictResolution.useLocal);

      await manager.saveToCloud('conflictKey', {'source': 'local'});
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      ));

      final result = await manager.syncKey('conflictKey');

      expect(result.success, true);
      final data = await manager.loadFromCloud('conflictKey');
      expect(data!['source'], 'local');
    });

    test('should use cloud data when resolution is useCloud', () async {
      manager.setConflictResolution(ConflictResolution.useCloud);

      await manager.saveToCloud('conflictKey', {'source': 'local'});
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      ));

      final result = await manager.syncKey('conflictKey');

      expect(result.success, true);
      final data = await manager.loadFromCloud('conflictKey');
      expect(data!['source'], 'cloud');
    });

    test('should use newest data when resolution is useNewest', () async {
      manager.setConflictResolution(ConflictResolution.useNewest);

      // Local data is newer
      await manager.saveToCloud('conflictKey', {'source': 'local'});
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      ));

      final result = await manager.syncKey('conflictKey');

      expect(result.success, true);
      final data = await manager.loadFromCloud('conflictKey');
      expect(data!['source'], 'local');
    });

    test('should use cloud when cloud is newer with useNewest', () async {
      manager.setConflictResolution(ConflictResolution.useNewest);

      // Set up older local data first
      await manager.saveToCloud('conflictKey', {'source': 'local'});

      // Cloud data is newer
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now().add(const Duration(hours: 1)),
      ));

      final result = await manager.syncKey('conflictKey');

      expect(result.success, true);
      final data = await manager.loadFromCloud('conflictKey');
      expect(data!['source'], 'cloud');
    });

    test('should return conflict status for merge resolution', () async {
      manager.setConflictResolution(ConflictResolution.merge);

      await manager.saveToCloud('conflictKey', {'source': 'local'});
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now(),
      ));

      final result = await manager.syncKey('conflictKey');

      expect(result.success, false);
      expect(result.status, SyncStatus.conflict);
    });

    test('should resolve conflict with custom data', () async {
      manager.setConflictResolution(ConflictResolution.merge);

      await manager.saveToCloud('conflictKey', {'source': 'local'});
      await mockProvider.upload(CloudSaveData(
        key: 'conflictKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now(),
      ));

      final result = await manager.resolveConflictWithData(
        'conflictKey',
        {'source': 'merged', 'localValue': 1, 'cloudValue': 2},
      );

      expect(result.success, true);
      final data = await manager.loadFromCloud('conflictKey');
      expect(data!['source'], 'merged');
    });

    test('should skip conflict when data is identical', () async {
      final sameData = {'value': 100};

      await manager.saveToCloud('sameKey', sameData);
      await mockProvider.upload(CloudSaveData(
        key: 'sameKey',
        data: sameData,
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      ));

      manager.setConflictResolution(ConflictResolution.merge);
      final result = await manager.syncKey('sameKey');

      expect(result.success, true);
    });
  });

  group('CloudSaveManager - Delete Operations', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should delete from local cache', () async {
      await manager.saveToCloud('deleteKey', {'value': 100});
      expect(manager.cachedKeys.contains('deleteKey'), true);

      await manager.deleteFromCloud('deleteKey');

      expect(manager.cachedKeys.contains('deleteKey'), false);
    });

    test('should delete from cloud', () async {
      await manager.saveToCloud('deleteKey', {'value': 100});
      await manager.syncKey('deleteKey');

      await manager.deleteFromCloud('deleteKey');

      final cloudData = await mockProvider.fetch('deleteKey');
      expect(cloudData, isNull);
    });

    test('should remove from pending uploads on delete', () async {
      await manager.saveToCloud('deleteKey', {'value': 100});
      expect(manager.pendingUploads.contains('deleteKey'), true);

      await manager.deleteFromCloud('deleteKey');

      expect(manager.pendingUploads.contains('deleteKey'), false);
    });

    test('should fail delete when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.deleteFromCloud('testKey');

      expect(result, false);
    });

    test('should handle delete failure gracefully', () async {
      await manager.saveToCloud('deleteKey', {'value': 100});
      mockProvider.setShouldFail(true);

      final result = await manager.deleteFromCloud('deleteKey');

      expect(result, false);
    });
  });

  group('CloudSaveManager - Auto Sync', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should enable auto sync', () {
      manager.setAutoSyncEnabled(true);

      expect(manager.autoSyncEnabled, true);
    });

    test('should disable auto sync', () {
      manager.setAutoSyncEnabled(true);
      manager.setAutoSyncEnabled(false);

      expect(manager.autoSyncEnabled, false);
    });

    test('should set auto sync interval', () {
      manager.setAutoSyncInterval(120);

      expect(manager.autoSyncIntervalSeconds, 120);
    });

    test('should enforce minimum interval of 60 seconds', () {
      manager.setAutoSyncInterval(30);

      expect(manager.autoSyncIntervalSeconds, 60);
    });

    test('should restart timer when interval changes', () {
      manager.setAutoSyncEnabled(true);
      manager.setAutoSyncInterval(120);

      expect(manager.autoSyncEnabled, true);
      expect(manager.autoSyncIntervalSeconds, 120);
    });
  });

  group('CloudSaveManager - Force Operations', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should force download from cloud', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'forceKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now(),
      ));

      await manager.saveToCloud('forceKey', {'source': 'local'});
      final result = await manager.forceDownload('forceKey');

      expect(result, true);
      final data = await manager.loadFromCloud('forceKey');
      expect(data!['source'], 'cloud');
    });

    test('should remove from pending uploads on force download', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'forceKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now(),
      ));

      await manager.saveToCloud('forceKey', {'source': 'local'});
      expect(manager.pendingUploads.contains('forceKey'), true);

      await manager.forceDownload('forceKey');

      expect(manager.pendingUploads.contains('forceKey'), false);
    });

    test('should fail force download for non-existent cloud key', () async {
      final result = await manager.forceDownload('nonexistent');

      expect(result, false);
    });

    test('should force upload to cloud', () async {
      await mockProvider.upload(CloudSaveData(
        key: 'forceKey',
        data: {'source': 'cloud'},
        lastModified: DateTime.now(),
      ));

      await manager.saveToCloud('forceKey', {'source': 'local'});
      final result = await manager.forceUpload('forceKey');

      expect(result, true);
      final cloudData = await mockProvider.fetch('forceKey');
      expect(cloudData!.data['source'], 'local');
    });

    test('should fail force upload for non-existent local key', () async {
      final result = await manager.forceUpload('nonexistent');

      expect(result, false);
    });

    test('should fail force download when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.forceDownload('testKey');

      expect(result, false);
    });

    test('should fail force upload when not initialized', () async {
      final uninitializedManager =
          CloudSaveManager(cloudProvider: mockProvider);

      final result = await uninitializedManager.forceUpload('testKey');

      expect(result, false);
    });
  });

  group('CloudSaveManager - Clear Cache', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should clear local cache', () async {
      await manager.saveToCloud('key1', {'value': 1});
      await manager.saveToCloud('key2', {'value': 2});

      await manager.clearLocalCache();

      expect(manager.cachedKeys.isEmpty, true);
    });

    test('should clear pending uploads', () async {
      await manager.saveToCloud('key1', {'value': 1});
      expect(manager.pendingUploads.isNotEmpty, true);

      await manager.clearLocalCache();

      expect(manager.pendingUploads.isEmpty, true);
    });

    test('should reset sync status', () async {
      await manager.saveToCloud('key1', {'value': 1});

      await manager.clearLocalCache();

      expect(manager.syncStatus, SyncStatus.notInitialized);
    });

    test('should clear SharedPreferences data', () async {
      await manager.saveToCloud('key1', {'value': 1});

      await manager.clearLocalCache();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cloud_save_cache'), isNull);
    });

    test('should reset lastSyncTime', () async {
      await manager.syncAll();
      expect(manager.lastSyncTime, isNotNull);

      await manager.clearLocalCache();

      expect(manager.lastSyncTime, isNull);
    });
  });

  group('CloudSaveManager - Cloud Availability', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should return true when cloud is available', () async {
      mockProvider.setAvailable(true);

      final isAvailable = await manager.isCloudAvailable();

      expect(isAvailable, true);
    });

    test('should return false when cloud is unavailable', () async {
      mockProvider.setAvailable(false);

      final isAvailable = await manager.isCloudAvailable();

      expect(isAvailable, false);
    });

    test('should return false when provider throws', () async {
      mockProvider.setShouldFail(true);

      final isAvailable = await manager.isCloudAvailable();

      expect(isAvailable, false);
    });
  });

  group('CloudSaveManager - Getters', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should return hasPendingChanges correctly', () async {
      expect(manager.hasPendingChanges, false);

      await manager.saveToCloud('key1', {'value': 1});

      expect(manager.hasPendingChanges, true);
    });

    test('should return unmodifiable pendingUploads', () async {
      await manager.saveToCloud('key1', {'value': 1});

      final uploads = manager.pendingUploads;

      expect(() => (uploads as Set).add('test'), throwsA(isA<Error>()));
    });

    test('should return conflictResolution setting', () {
      expect(manager.conflictResolution, ConflictResolution.useNewest);

      manager.setConflictResolution(ConflictResolution.useLocal);

      expect(manager.conflictResolution, ConflictResolution.useLocal);
    });
  });

  group('CloudSaveManager - Notification', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should notify listeners on save', () async {
      var notified = false;
      manager.addListener(() => notified = true);

      await manager.saveToCloud('key1', {'value': 1});

      expect(notified, true);
    });

    test('should notify listeners on sync', () async {
      var notifyCount = 0;
      manager.addListener(() => notifyCount++);

      await manager.syncAll();

      expect(notifyCount, greaterThan(0));
    });

    test('should notify listeners on conflict resolution change', () {
      var notified = false;
      manager.addListener(() => notified = true);

      manager.setConflictResolution(ConflictResolution.useCloud);

      expect(notified, true);
    });

    test('should notify listeners on auto sync toggle', () {
      var notified = false;
      manager.addListener(() => notified = true);

      manager.setAutoSyncEnabled(true);

      expect(notified, true);
    });

    test('should notify listeners on clear cache', () async {
      var notified = false;
      manager.addListener(() => notified = true);

      await manager.clearLocalCache();

      expect(notified, true);
    });
  });

  group('CloudSaveManager - Edge Cases', () {
    setUp(() async {
      await manager.initialize();
    });

    test('should handle empty data', () async {
      final result = await manager.saveToCloud('emptyKey', {});

      expect(result, true);
      final data = await manager.loadFromCloud('emptyKey');
      expect(data, isEmpty);
    });

    test('should handle complex nested data', () async {
      final complexData = {
        'level1': {
          'level2': {
            'level3': {'value': 123}
          }
        },
        'array': [1, 2, 3],
        'mixed': [
          {'a': 1},
          {'b': 2}
        ],
      };

      await manager.saveToCloud('complexKey', complexData);
      final data = await manager.loadFromCloud('complexKey');

      expect(data, complexData);
    });

    test('should handle special characters in data', () async {
      final specialData = {
        'unicode': 'Hello',
        'quotes': 'He said "hello"',
        'newlines': 'line1\nline2',
        'backslash': 'path\\to\\file',
      };

      await manager.saveToCloud('specialKey', specialData);
      final data = await manager.loadFromCloud('specialKey');

      expect(data, specialData);
    });

    test('should handle null values in data', () async {
      final nullData = {
        'nullValue': null,
        'validValue': 100,
      };

      await manager.saveToCloud('nullKey', nullData);
      final data = await manager.loadFromCloud('nullKey');

      expect(data!['nullValue'], isNull);
      expect(data['validValue'], 100);
    });

    test('should handle very large data', () async {
      final largeData = <String, dynamic>{};
      for (var i = 0; i < 1000; i++) {
        largeData['key_$i'] = 'value_$i' * 100;
      }

      final result = await manager.saveToCloud('largeKey', largeData);

      expect(result, true);
    });

    test('should handle concurrent saves', () async {
      final futures = <Future<bool>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(manager.saveToCloud('concurrentKey_$i', {'value': i}));
      }

      final results = await Future.wait(futures);

      expect(results.every((r) => r == true), true);
      // All keys should be in the local cache
      expect(manager.cachedKeys.length, greaterThanOrEqualTo(10));
    });

    test('should handle rapid save/load cycles', () async {
      for (var i = 0; i < 100; i++) {
        await manager.saveToCloud('rapidKey', {'iteration': i});
        final data = await manager.loadFromCloud('rapidKey');
        expect(data!['iteration'], i);
      }
    });
  });

  group('CloudSaveData', () {
    test('should create from json', () {
      final json = {
        'key': 'testKey',
        'data': {'value': 100},
        'lastModified': '2024-01-01T00:00:00.000',
        'version': 5,
        'checksum': 'abc123',
      };

      final saveData = CloudSaveData.fromJson(json);

      expect(saveData.key, 'testKey');
      expect(saveData.data['value'], 100);
      expect(saveData.version, 5);
      expect(saveData.checksum, 'abc123');
    });

    test('should serialize to json', () {
      final saveData = CloudSaveData(
        key: 'testKey',
        data: {'value': 100},
        lastModified: DateTime(2024, 1, 1),
        version: 5,
        checksum: 'abc123',
      );

      final json = saveData.toJson();

      expect(json['key'], 'testKey');
      expect(json['data']['value'], 100);
      expect(json['version'], 5);
    });

    test('should use default version when not in json', () {
      final json = {
        'key': 'testKey',
        'data': {'value': 100},
        'lastModified': '2024-01-01T00:00:00.000',
      };

      final saveData = CloudSaveData.fromJson(json);

      expect(saveData.version, 1);
    });

    test('should copy with new values', () {
      final original = CloudSaveData(
        key: 'testKey',
        data: {'value': 100},
        lastModified: DateTime(2024, 1, 1),
        version: 1,
      );

      final copied = original.copyWith(version: 2, checksum: 'newChecksum');

      expect(copied.key, 'testKey');
      expect(copied.version, 2);
      expect(copied.checksum, 'newChecksum');
    });
  });

  group('SyncResult', () {
    test('should create success result', () {
      final result = SyncResult.success();

      expect(result.success, true);
      expect(result.status, SyncStatus.synced);
      expect(result.lastSyncTime, isNotNull);
    });

    test('should create success result with custom time', () {
      final customTime = DateTime(2024, 6, 15);
      final result = SyncResult.success(syncTime: customTime);

      expect(result.lastSyncTime, customTime);
    });

    test('should create failure result', () {
      final result = SyncResult.failure('Test error');

      expect(result.success, false);
      expect(result.error, 'Test error');
      expect(result.status, SyncStatus.failed);
    });

    test('should create conflict result', () {
      final result = SyncResult.conflict();

      expect(result.success, false);
      expect(result.status, SyncStatus.conflict);
    });
  });

  group('MockCloudStorageProvider', () {
    late MockCloudStorageProvider testProvider;

    setUp(() {
      testProvider = MockCloudStorageProvider();
    });

    tearDown(() {
      testProvider.clear();
    });

    test('should initialize successfully', () async {
      await testProvider.initialize();
      // No exception means success
    });

    test('should check availability', () async {
      expect(await testProvider.isAvailable(), true);

      testProvider.setAvailable(false);

      expect(await testProvider.isAvailable(), false);
    });

    test('should upload and fetch data', () async {
      final data = CloudSaveData(
        key: 'testKey',
        data: {'value': 100},
        lastModified: DateTime.now(),
      );

      await testProvider.upload(data);
      final fetched = await testProvider.fetch('testKey');

      expect(fetched, isNotNull);
      expect(fetched!.data['value'], 100);
    });

    test('should delete data', () async {
      final data = CloudSaveData(
        key: 'testKey',
        data: {'value': 100},
        lastModified: DateTime.now(),
      );

      await testProvider.upload(data);
      await testProvider.delete('testKey');
      final fetched = await testProvider.fetch('testKey');

      expect(fetched, isNull);
    });

    test('should list keys', () async {
      await testProvider.upload(CloudSaveData(
        key: 'key1',
        data: {},
        lastModified: DateTime.now(),
      ));
      await testProvider.upload(CloudSaveData(
        key: 'key2',
        data: {},
        lastModified: DateTime.now(),
      ));

      final keys = await testProvider.listKeys();

      expect(keys.length, 2);
      expect(keys.contains('key1'), true);
      expect(keys.contains('key2'), true);
    });

    test('should throw when shouldFail is set', () async {
      testProvider.setShouldFail(true);

      expect(() => testProvider.fetch('anyKey'), throwsException);
      expect(() => testProvider.upload(CloudSaveData(
            key: 'anyKey',
            data: {},
            lastModified: DateTime.now(),
          )), throwsException);
      expect(() => testProvider.delete('anyKey'), throwsException);
      expect(() => testProvider.listKeys(), throwsException);
    });

    test('should simulate latency', () async {
      testProvider.setLatency(100);

      final stopwatch = Stopwatch()..start();
      await testProvider.initialize();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('should clear storage', () async {
      await testProvider.upload(CloudSaveData(
        key: 'testKey',
        data: {},
        lastModified: DateTime.now(),
      ));

      testProvider.clear();
      final keys = await testProvider.listKeys();

      expect(keys.isEmpty, true);
    });
  });
}

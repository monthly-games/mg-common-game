import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing the conflict resolution strategy
enum ConflictResolution {
  /// Use local data when conflict occurs
  useLocal,

  /// Use cloud data when conflict occurs
  useCloud,

  /// Use the most recently modified data
  useNewest,

  /// Merge both datasets (requires custom merge logic)
  merge,
}

/// Enum representing the sync status
enum SyncStatus {
  /// Sync completed successfully
  synced,

  /// Currently syncing
  syncing,

  /// Sync failed
  failed,

  /// Has local changes pending upload
  pendingUpload,

  /// Has cloud changes pending download
  pendingDownload,

  /// Conflict detected between local and cloud data
  conflict,

  /// Not yet initialized
  notInitialized,
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? error;
  final SyncStatus status;
  final DateTime? lastSyncTime;

  const SyncResult({
    required this.success,
    this.error,
    required this.status,
    this.lastSyncTime,
  });

  factory SyncResult.success({DateTime? syncTime}) => SyncResult(
        success: true,
        status: SyncStatus.synced,
        lastSyncTime: syncTime ?? DateTime.now(),
      );

  factory SyncResult.failure(String error) => SyncResult(
        success: false,
        error: error,
        status: SyncStatus.failed,
      );

  factory SyncResult.conflict() => SyncResult(
        success: false,
        status: SyncStatus.conflict,
      );
}

/// Cloud save data wrapper with metadata
class CloudSaveData {
  final String key;
  final Map<String, dynamic> data;
  final DateTime lastModified;
  final int version;
  final String? checksum;

  const CloudSaveData({
    required this.key,
    required this.data,
    required this.lastModified,
    this.version = 1,
    this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'data': data,
        'lastModified': lastModified.toIso8601String(),
        'version': version,
        'checksum': checksum,
      };

  factory CloudSaveData.fromJson(Map<String, dynamic> json) {
    return CloudSaveData(
      key: json['key'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      lastModified: DateTime.parse(json['lastModified'] as String),
      version: json['version'] as int? ?? 1,
      checksum: json['checksum'] as String?,
    );
  }

  CloudSaveData copyWith({
    String? key,
    Map<String, dynamic>? data,
    DateTime? lastModified,
    int? version,
    String? checksum,
  }) {
    return CloudSaveData(
      key: key ?? this.key,
      data: data ?? this.data,
      lastModified: lastModified ?? this.lastModified,
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
    );
  }
}

/// Abstract cloud storage provider interface
abstract class CloudStorageProvider {
  Future<void> initialize();
  Future<bool> isAvailable();
  Future<CloudSaveData?> fetch(String key);
  Future<bool> upload(CloudSaveData data);
  Future<bool> delete(String key);
  Future<List<String>> listKeys();
}

/// Mock cloud storage provider for testing
class MockCloudStorageProvider implements CloudStorageProvider {
  final Map<String, CloudSaveData> _storage = {};
  bool _isAvailable = true;
  bool _shouldFail = false;
  int _latencyMs = 0;

  void setAvailable(bool available) => _isAvailable = available;
  void setShouldFail(bool shouldFail) => _shouldFail = shouldFail;
  void setLatency(int ms) => _latencyMs = ms;
  void clear() => _storage.clear();

  @override
  Future<void> initialize() async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock initialize failed');
  }

  @override
  Future<bool> isAvailable() async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock isAvailable failed');
    return _isAvailable;
  }

  @override
  Future<CloudSaveData?> fetch(String key) async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock fetch failed');
    return _storage[key];
  }

  @override
  Future<bool> upload(CloudSaveData data) async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock upload failed');
    if (!_isAvailable) return false;
    _storage[data.key] = data;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock delete failed');
    if (!_isAvailable) return false;
    _storage.remove(key);
    return true;
  }

  @override
  Future<List<String>> listKeys() async {
    if (_latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _latencyMs));
    }
    if (_shouldFail) throw Exception('Mock listKeys failed');
    return _storage.keys.toList();
  }
}

/// Manages cloud save/load operations with sync capabilities
class CloudSaveManager extends ChangeNotifier {
  final CloudStorageProvider _cloudProvider;

  SyncStatus _syncStatus = SyncStatus.notInitialized;
  DateTime? _lastSyncTime;
  ConflictResolution _conflictResolution = ConflictResolution.useNewest;
  bool _autoSyncEnabled = false;
  Timer? _autoSyncTimer;
  int _autoSyncIntervalSeconds = 300; // Default: 5 minutes

  final Map<String, CloudSaveData> _localCache = {};
  final Set<String> _pendingUploads = {};
  final Set<String> _pendingDownloads = {};

  bool _isInitialized = false;

  // Getters
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  ConflictResolution get conflictResolution => _conflictResolution;
  bool get autoSyncEnabled => _autoSyncEnabled;
  int get autoSyncIntervalSeconds => _autoSyncIntervalSeconds;
  bool get isInitialized => _isInitialized;
  bool get hasPendingChanges =>
      _pendingUploads.isNotEmpty || _pendingDownloads.isNotEmpty;
  Set<String> get pendingUploads => Set.unmodifiable(_pendingUploads);
  Set<String> get pendingDownloads => Set.unmodifiable(_pendingDownloads);
  List<String> get cachedKeys => _localCache.keys.toList();

  CloudSaveManager({required CloudStorageProvider cloudProvider})
      : _cloudProvider = cloudProvider;

  /// Initialize the cloud save manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _cloudProvider.initialize();
      await _loadLocalCache();
      _isInitialized = true;
      _syncStatus = SyncStatus.synced;
      notifyListeners();
      debugPrint('[CloudSaveManager] Initialized');
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      debugPrint('[CloudSaveManager] Initialization failed: $e');
      rethrow;
    }
  }

  /// Load local cache from SharedPreferences
  Future<void> _loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getString('cloud_save_cache');

    if (cacheJson != null) {
      try {
        final cacheMap = jsonDecode(cacheJson) as Map<String, dynamic>;
        for (final entry in cacheMap.entries) {
          _localCache[entry.key] = CloudSaveData.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      } catch (e) {
        debugPrint('[CloudSaveManager] Failed to load cache: $e');
      }
    }

    final lastSyncStr = prefs.getString('cloud_save_last_sync');
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncStr);
    }

    final pendingStr = prefs.getStringList('cloud_save_pending_uploads');
    if (pendingStr != null) {
      _pendingUploads.addAll(pendingStr);
    }
  }

  /// Save local cache to SharedPreferences
  Future<void> _saveLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cacheMap = <String, dynamic>{};
    for (final entry in _localCache.entries) {
      cacheMap[entry.key] = entry.value.toJson();
    }

    await prefs.setString('cloud_save_cache', jsonEncode(cacheMap));

    if (_lastSyncTime != null) {
      await prefs.setString(
          'cloud_save_last_sync', _lastSyncTime!.toIso8601String());
    }

    await prefs.setStringList(
        'cloud_save_pending_uploads', _pendingUploads.toList());
  }

  /// Set conflict resolution strategy
  void setConflictResolution(ConflictResolution resolution) {
    _conflictResolution = resolution;
    notifyListeners();
  }

  /// Enable or disable auto-sync
  void setAutoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    notifyListeners();
  }

  /// Set auto-sync interval in seconds
  void setAutoSyncInterval(int seconds) {
    if (seconds < 60) {
      debugPrint(
          '[CloudSaveManager] Auto-sync interval too short, using minimum of 60 seconds');
      seconds = 60;
    }
    _autoSyncIntervalSeconds = seconds;

    if (_autoSyncEnabled) {
      _stopAutoSync();
      _startAutoSync();
    }
    notifyListeners();
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      Duration(seconds: _autoSyncIntervalSeconds),
      (_) => syncAll(),
    );
    debugPrint(
        '[CloudSaveManager] Auto-sync started (interval: ${_autoSyncIntervalSeconds}s)');
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('[CloudSaveManager] Auto-sync stopped');
  }

  /// Save data locally and queue for upload
  Future<bool> saveToCloud(String key, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      debugPrint('[CloudSaveManager] Not initialized');
      return false;
    }

    try {
      final existingVersion = _localCache[key]?.version ?? 0;
      final saveData = CloudSaveData(
        key: key,
        data: data,
        lastModified: DateTime.now(),
        version: existingVersion + 1,
        checksum: _calculateChecksum(data),
      );

      _localCache[key] = saveData;
      _pendingUploads.add(key);
      _syncStatus = SyncStatus.pendingUpload;

      await _saveLocalCache();
      notifyListeners();

      debugPrint('[CloudSaveManager] Saved locally: $key (pending upload)');
      return true;
    } catch (e) {
      debugPrint('[CloudSaveManager] Save failed: $e');
      return false;
    }
  }

  /// Load data from local cache or cloud
  Future<Map<String, dynamic>?> loadFromCloud(String key) async {
    if (!_isInitialized) {
      debugPrint('[CloudSaveManager] Not initialized');
      return null;
    }

    // Return from cache if available
    if (_localCache.containsKey(key)) {
      return _localCache[key]!.data;
    }

    // Try to fetch from cloud
    try {
      final cloudData = await _cloudProvider.fetch(key);
      if (cloudData != null) {
        _localCache[key] = cloudData;
        await _saveLocalCache();
        return cloudData.data;
      }
    } catch (e) {
      debugPrint('[CloudSaveManager] Load from cloud failed: $e');
    }

    return null;
  }

  /// Force sync a specific key
  Future<SyncResult> syncKey(String key) async {
    if (!_isInitialized) {
      return SyncResult.failure('Not initialized');
    }

    try {
      final isAvailable = await _cloudProvider.isAvailable();
      if (!isAvailable) {
        return SyncResult.failure('Cloud not available');
      }

      final localData = _localCache[key];
      final cloudData = await _cloudProvider.fetch(key);

      // No conflict - just upload or download
      if (localData == null && cloudData == null) {
        return SyncResult.success();
      }

      if (localData == null && cloudData != null) {
        _localCache[key] = cloudData;
        _pendingDownloads.remove(key);
        await _saveLocalCache();
        return SyncResult.success(syncTime: DateTime.now());
      }

      if (localData != null && cloudData == null) {
        await _cloudProvider.upload(localData);
        _pendingUploads.remove(key);
        await _saveLocalCache();
        return SyncResult.success(syncTime: DateTime.now());
      }

      // Both exist - check for conflict
      if (localData != null && cloudData != null) {
        final resolution =
            await _resolveConflict(key, localData, cloudData);
        return resolution;
      }

      return SyncResult.success();
    } catch (e) {
      debugPrint('[CloudSaveManager] Sync failed for $key: $e');
      return SyncResult.failure(e.toString());
    }
  }

  /// Sync all pending changes
  Future<SyncResult> syncAll() async {
    if (!_isInitialized) {
      return SyncResult.failure('Not initialized');
    }

    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final isAvailable = await _cloudProvider.isAvailable();
      if (!isAvailable) {
        _syncStatus = SyncStatus.failed;
        notifyListeners();
        return SyncResult.failure('Cloud not available');
      }

      // Upload pending changes
      final uploadErrors = <String>[];
      for (final key in _pendingUploads.toList()) {
        final localData = _localCache[key];
        if (localData != null) {
          try {
            final cloudData = await _cloudProvider.fetch(key);
            if (cloudData != null) {
              final result =
                  await _resolveConflict(key, localData, cloudData);
              if (!result.success) {
                uploadErrors.add(key);
                continue;
              }
            } else {
              await _cloudProvider.upload(localData);
            }
            _pendingUploads.remove(key);
          } catch (e) {
            uploadErrors.add(key);
          }
        }
      }

      // Download cloud keys not in local cache
      try {
        final cloudKeys = await _cloudProvider.listKeys();
        for (final key in cloudKeys) {
          if (!_localCache.containsKey(key)) {
            final cloudData = await _cloudProvider.fetch(key);
            if (cloudData != null) {
              _localCache[key] = cloudData;
            }
          }
        }
      } catch (e) {
        debugPrint('[CloudSaveManager] Failed to list cloud keys: $e');
      }

      _lastSyncTime = DateTime.now();
      await _saveLocalCache();

      if (uploadErrors.isNotEmpty) {
        _syncStatus = SyncStatus.failed;
        notifyListeners();
        return SyncResult.failure(
            'Failed to sync: ${uploadErrors.join(', ')}');
      }

      _syncStatus = _pendingUploads.isEmpty && _pendingDownloads.isEmpty
          ? SyncStatus.synced
          : SyncStatus.pendingUpload;

      notifyListeners();
      return SyncResult.success(syncTime: _lastSyncTime);
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      notifyListeners();
      debugPrint('[CloudSaveManager] Sync all failed: $e');
      return SyncResult.failure(e.toString());
    }
  }

  /// Resolve conflict between local and cloud data
  Future<SyncResult> _resolveConflict(
    String key,
    CloudSaveData localData,
    CloudSaveData cloudData,
  ) async {
    // Check if data is identical
    if (_calculateChecksum(localData.data) ==
        _calculateChecksum(cloudData.data)) {
      // Data is same, just update metadata
      final newerData =
          localData.lastModified.isAfter(cloudData.lastModified)
              ? localData
              : cloudData;
      _localCache[key] = newerData;
      await _cloudProvider.upload(newerData);
      _pendingUploads.remove(key);
      return SyncResult.success();
    }

    switch (_conflictResolution) {
      case ConflictResolution.useLocal:
        await _cloudProvider.upload(localData);
        _pendingUploads.remove(key);
        return SyncResult.success();

      case ConflictResolution.useCloud:
        _localCache[key] = cloudData;
        _pendingUploads.remove(key);
        await _saveLocalCache();
        return SyncResult.success();

      case ConflictResolution.useNewest:
        if (localData.lastModified.isAfter(cloudData.lastModified)) {
          await _cloudProvider.upload(localData);
          _pendingUploads.remove(key);
        } else {
          _localCache[key] = cloudData;
          _pendingUploads.remove(key);
          await _saveLocalCache();
        }
        return SyncResult.success();

      case ConflictResolution.merge:
        // For merge, we return conflict status to let the caller handle it
        _syncStatus = SyncStatus.conflict;
        notifyListeners();
        return SyncResult.conflict();
    }
  }

  /// Manually resolve a conflict with custom data
  Future<SyncResult> resolveConflictWithData(
    String key,
    Map<String, dynamic> resolvedData,
  ) async {
    if (!_isInitialized) {
      return SyncResult.failure('Not initialized');
    }

    try {
      final existingVersion = _localCache[key]?.version ?? 0;
      final saveData = CloudSaveData(
        key: key,
        data: resolvedData,
        lastModified: DateTime.now(),
        version: existingVersion + 1,
        checksum: _calculateChecksum(resolvedData),
      );

      _localCache[key] = saveData;
      await _cloudProvider.upload(saveData);
      _pendingUploads.remove(key);

      _syncStatus = _pendingUploads.isEmpty
          ? SyncStatus.synced
          : SyncStatus.pendingUpload;

      await _saveLocalCache();
      notifyListeners();

      return SyncResult.success();
    } catch (e) {
      return SyncResult.failure(e.toString());
    }
  }

  /// Delete data from both local cache and cloud
  Future<bool> deleteFromCloud(String key) async {
    if (!_isInitialized) {
      debugPrint('[CloudSaveManager] Not initialized');
      return false;
    }

    try {
      _localCache.remove(key);
      _pendingUploads.remove(key);
      await _cloudProvider.delete(key);
      await _saveLocalCache();
      notifyListeners();

      debugPrint('[CloudSaveManager] Deleted: $key');
      return true;
    } catch (e) {
      debugPrint('[CloudSaveManager] Delete failed: $e');
      return false;
    }
  }

  /// Get local cached data for a key
  CloudSaveData? getLocalData(String key) {
    return _localCache[key];
  }

  /// Check if cloud is available
  Future<bool> isCloudAvailable() async {
    try {
      return await _cloudProvider.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Clear all local cache and pending operations
  Future<void> clearLocalCache() async {
    _localCache.clear();
    _pendingUploads.clear();
    _pendingDownloads.clear();
    _lastSyncTime = null;
    _syncStatus = SyncStatus.notInitialized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cloud_save_cache');
    await prefs.remove('cloud_save_last_sync');
    await prefs.remove('cloud_save_pending_uploads');

    notifyListeners();
    debugPrint('[CloudSaveManager] Local cache cleared');
  }

  /// Force download from cloud, overwriting local data
  Future<bool> forceDownload(String key) async {
    if (!_isInitialized) {
      return false;
    }

    try {
      final cloudData = await _cloudProvider.fetch(key);
      if (cloudData != null) {
        _localCache[key] = cloudData;
        _pendingUploads.remove(key);
        await _saveLocalCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[CloudSaveManager] Force download failed: $e');
      return false;
    }
  }

  /// Force upload to cloud, overwriting cloud data
  Future<bool> forceUpload(String key) async {
    if (!_isInitialized) {
      return false;
    }

    final localData = _localCache[key];
    if (localData == null) {
      return false;
    }

    try {
      await _cloudProvider.upload(localData);
      _pendingUploads.remove(key);
      await _saveLocalCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[CloudSaveManager] Force upload failed: $e');
      return false;
    }
  }

  /// Calculate checksum for data integrity verification
  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonStr = jsonEncode(data);
    var hash = 0;
    for (var i = 0; i < jsonStr.length; i++) {
      hash = ((hash << 5) - hash + jsonStr.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}

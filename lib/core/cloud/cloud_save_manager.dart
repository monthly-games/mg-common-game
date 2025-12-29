import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Cloud save sync status
enum CloudSyncStatus {
  /// Not initialized
  notInitialized,

  /// Syncing in progress
  syncing,

  /// Synced successfully
  synced,

  /// Sync failed
  error,

  /// Offline, changes pending
  pendingUpload,

  /// Conflict detected
  conflict,
}

/// Save data conflict resolution strategy
enum ConflictResolution {
  /// Use local data
  useLocal,

  /// Use cloud data
  useCloud,

  /// Use newer data (by timestamp)
  useNewer,

  /// Merge data
  merge,

  /// Ask user
  askUser,
}

/// Cloud save data wrapper
class CloudSaveData {
  final String id;
  final String gameId;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime lastModified;
  final int version;
  final String? checksum;

  CloudSaveData({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.data,
    required this.lastModified,
    this.version = 1,
    this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'userId': userId,
        'data': data,
        'lastModified': lastModified.toIso8601String(),
        'version': version,
        'checksum': checksum,
      };

  factory CloudSaveData.fromJson(Map<String, dynamic> json) {
    return CloudSaveData(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      userId: json['userId'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      lastModified: DateTime.parse(json['lastModified'] as String),
      version: json['version'] as int? ?? 1,
      checksum: json['checksum'] as String?,
    );
  }

  CloudSaveData copyWith({
    Map<String, dynamic>? data,
    DateTime? lastModified,
    int? version,
    String? checksum,
  }) {
    return CloudSaveData(
      id: id,
      gameId: gameId,
      userId: userId,
      data: data ?? this.data,
      lastModified: lastModified ?? this.lastModified,
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
    );
  }
}

/// Conflict data for resolution
class SaveConflict {
  final CloudSaveData local;
  final CloudSaveData cloud;

  SaveConflict({required this.local, required this.cloud});
}

/// Callback types
typedef ConflictResolver = Future<CloudSaveData> Function(SaveConflict conflict);
typedef SyncCallback = void Function(CloudSyncStatus status);

/// Cloud Save Manager
///
/// Handles synchronization of game saves with cloud storage.
/// Supports Firebase, custom backend, or other cloud providers.
class CloudSaveManager extends ChangeNotifier {
  static final CloudSaveManager _instance = CloudSaveManager._();
  static CloudSaveManager get instance => _instance;

  CloudSaveManager._();

  /// 테스트용 생성자 - 싱글톤을 우회하여 독립적인 인스턴스 생성
  @visibleForTesting
  CloudSaveManager.testable();

  bool _initialized = false;
  String? _gameId;
  String? _userId;
  CloudSyncStatus _status = CloudSyncStatus.notInitialized;
  CloudSaveData? _localSave;
  CloudSaveData? _cloudSave;
  ConflictResolution _defaultResolution = ConflictResolution.useNewer;
  ConflictResolver? _conflictResolver;
  Timer? _autoSyncTimer;

  final List<SyncCallback> _syncListeners = [];

  /// Current sync status
  CloudSyncStatus get status => _status;

  /// Whether initialized
  bool get isInitialized => _initialized;

  /// Current user ID
  String? get userId => _userId;

  /// Local save data
  CloudSaveData? get localSave => _localSave;

  /// Cloud save data
  CloudSaveData? get cloudSave => _cloudSave;

  // ============================================================
  // 테스트용 접근자 (visibleForTesting)
  // ============================================================

  @visibleForTesting
  set localSaveForTest(CloudSaveData? save) => _localSave = save;

  @visibleForTesting
  set cloudSaveForTest(CloudSaveData? save) => _cloudSave = save;

  @visibleForTesting
  set initializedForTest(bool value) => _initialized = value;

  @visibleForTesting
  set gameIdForTest(String id) => _gameId = id;

  @visibleForTesting
  set userIdForTest(String id) => _userId = id;

  @visibleForTesting
  bool hasConflictForTest(CloudSaveData local, CloudSaveData cloud) =>
      _hasConflict(local, cloud);

  @visibleForTesting
  CloudSaveData resolveWithStrategyForTest(ConflictResolution strategy) =>
      _resolveWithStrategy(strategy);

  @visibleForTesting
  CloudSaveData mergeSavesForTest(CloudSaveData local, CloudSaveData cloud) =>
      _mergeSaves(local, cloud);

  @visibleForTesting
  String generateChecksumForTest(Map<String, dynamic> data) =>
      _generateChecksum(data);

  @visibleForTesting
  String generateSaveIdForTest() => _generateSaveId();

  /// Initialize cloud save manager
  Future<void> initialize({
    required String gameId,
    required String userId,
    ConflictResolution defaultResolution = ConflictResolution.useNewer,
    ConflictResolver? conflictResolver,
    Duration? autoSyncInterval,
  }) async {
    if (_initialized) return;

    _gameId = gameId;
    _userId = userId;
    _defaultResolution = defaultResolution;
    _conflictResolver = conflictResolver;

    // Load local save
    await _loadLocalSave();

    // Setup auto-sync
    if (autoSyncInterval != null) {
      _autoSyncTimer = Timer.periodic(autoSyncInterval, (_) => sync());
    }

    _initialized = true;
    _updateStatus(CloudSyncStatus.synced);

    debugPrint('CloudSaveManager initialized for game: $gameId, user: $userId');
  }

  /// Add sync status listener
  void addSyncListener(SyncCallback callback) {
    _syncListeners.add(callback);
  }

  /// Remove sync status listener
  void removeSyncListener(SyncCallback callback) {
    _syncListeners.remove(callback);
  }

  void _updateStatus(CloudSyncStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
      for (final listener in _syncListeners) {
        listener(status);
      }
    }
  }

  /// Save data locally and optionally sync
  Future<void> save(
    Map<String, dynamic> data, {
    bool syncImmediately = true,
  }) async {
    if (!_initialized) {
      throw StateError('CloudSaveManager not initialized');
    }

    final now = DateTime.now();
    final newVersion = (_localSave?.version ?? 0) + 1;

    _localSave = CloudSaveData(
      id: _localSave?.id ?? _generateSaveId(),
      gameId: _gameId!,
      userId: _userId!,
      data: data,
      lastModified: now,
      version: newVersion,
      checksum: _generateChecksum(data),
    );

    await _persistLocalSave();

    if (syncImmediately) {
      await sync();
    } else {
      _updateStatus(CloudSyncStatus.pendingUpload);
    }
  }

  /// Get save data (local or cloud)
  Map<String, dynamic>? getData() {
    return _localSave?.data;
  }

  /// Get specific value from save
  T? getValue<T>(String key) {
    return _localSave?.data[key] as T?;
  }

  /// Set specific value in save
  Future<void> setValue<T>(String key, T value, {bool syncImmediately = false}) async {
    final data = Map<String, dynamic>.from(_localSave?.data ?? {});
    data[key] = value;
    await save(data, syncImmediately: syncImmediately);
  }

  /// Sync with cloud
  Future<bool> sync() async {
    if (!_initialized) return false;

    _updateStatus(CloudSyncStatus.syncing);

    try {
      // Fetch cloud save
      _cloudSave = await _fetchCloudSave();

      if (_cloudSave == null && _localSave != null) {
        // No cloud save, upload local
        await _uploadToCloud(_localSave!);
        _updateStatus(CloudSyncStatus.synced);
        return true;
      }

      if (_cloudSave != null && _localSave == null) {
        // No local save, download cloud
        _localSave = _cloudSave;
        await _persistLocalSave();
        _updateStatus(CloudSyncStatus.synced);
        return true;
      }

      if (_cloudSave != null && _localSave != null) {
        // Both exist, check for conflict
        if (_hasConflict(_localSave!, _cloudSave!)) {
          await _resolveConflict();
        } else if (_localSave!.lastModified.isAfter(_cloudSave!.lastModified)) {
          // Local is newer, upload
          await _uploadToCloud(_localSave!);
        } else if (_cloudSave!.lastModified.isAfter(_localSave!.lastModified)) {
          // Cloud is newer, download
          _localSave = _cloudSave;
          await _persistLocalSave();
        }
        // If same time, no action needed
      }

      _updateStatus(CloudSyncStatus.synced);
      return true;
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      _updateStatus(CloudSyncStatus.error);
      return false;
    }
  }

  bool _hasConflict(CloudSaveData local, CloudSaveData cloud) {
    // Conflict if versions differ and neither is strictly newer
    if (local.version != cloud.version) {
      final localNewer = local.lastModified.isAfter(cloud.lastModified);
      final cloudNewer = cloud.lastModified.isAfter(local.lastModified);
      // True conflict: different versions, same or ambiguous timestamps
      return !localNewer && !cloudNewer;
    }
    return false;
  }

  Future<void> _resolveConflict() async {
    if (_localSave == null || _cloudSave == null) return;

    _updateStatus(CloudSyncStatus.conflict);

    CloudSaveData resolved;

    if (_conflictResolver != null) {
      resolved = await _conflictResolver!(SaveConflict(
        local: _localSave!,
        cloud: _cloudSave!,
      ));
    } else {
      resolved = _resolveWithStrategy(_defaultResolution);
    }

    _localSave = resolved;
    await _persistLocalSave();
    await _uploadToCloud(resolved);
  }

  CloudSaveData _resolveWithStrategy(ConflictResolution strategy) {
    switch (strategy) {
      case ConflictResolution.useLocal:
        return _localSave!;
      case ConflictResolution.useCloud:
        return _cloudSave!;
      case ConflictResolution.useNewer:
        return _localSave!.lastModified.isAfter(_cloudSave!.lastModified)
            ? _localSave!
            : _cloudSave!;
      case ConflictResolution.merge:
        return _mergeSaves(_localSave!, _cloudSave!);
      case ConflictResolution.askUser:
        // Default to newer if no resolver
        return _localSave!.lastModified.isAfter(_cloudSave!.lastModified)
            ? _localSave!
            : _cloudSave!;
    }
  }

  CloudSaveData _mergeSaves(CloudSaveData local, CloudSaveData cloud) {
    // Simple merge: combine data, take max of numeric values
    final merged = <String, dynamic>{};

    // Start with cloud data
    merged.addAll(cloud.data);

    // Override/merge with local data
    for (final entry in local.data.entries) {
      final cloudValue = cloud.data[entry.key];

      if (cloudValue == null) {
        // Local only
        merged[entry.key] = entry.value;
      } else if (entry.value is num && cloudValue is num) {
        // Take max for numbers (scores, levels, etc.)
        merged[entry.key] =
            (entry.value as num) > cloudValue ? entry.value : cloudValue;
      } else if (entry.value is List && cloudValue is List) {
        // Combine lists (achievements, items, etc.)
        final combined = <dynamic>{...cloudValue, ...entry.value as List};
        merged[entry.key] = combined.toList();
      } else if (local.lastModified.isAfter(cloud.lastModified)) {
        // For other types, use newer
        merged[entry.key] = entry.value;
      }
    }

    return local.copyWith(
      data: merged,
      lastModified: DateTime.now(),
      version: (local.version > cloud.version ? local.version : cloud.version) + 1,
    );
  }

  /// Delete cloud save
  Future<void> deleteCloudSave() async {
    if (!_initialized) return;

    // TODO: Implement cloud deletion
    // await _firestore.collection('saves').doc(_localSave?.id).delete();

    _cloudSave = null;
    debugPrint('Cloud save deleted');
  }

  /// Delete all saves (local and cloud)
  Future<void> deleteAllSaves() async {
    await deleteCloudSave();

    _localSave = null;
    // TODO: Delete local save from SharedPreferences
    // await SharedPreferences.getInstance()..remove('cloud_save');

    notifyListeners();
  }

  /// Force download from cloud
  Future<bool> forceDownload() async {
    if (!_initialized) return false;

    try {
      _updateStatus(CloudSyncStatus.syncing);
      _cloudSave = await _fetchCloudSave();

      if (_cloudSave != null) {
        _localSave = _cloudSave;
        await _persistLocalSave();
        _updateStatus(CloudSyncStatus.synced);
        return true;
      }

      _updateStatus(CloudSyncStatus.error);
      return false;
    } catch (e) {
      _updateStatus(CloudSyncStatus.error);
      return false;
    }
  }

  /// Force upload to cloud
  Future<bool> forceUpload() async {
    if (!_initialized || _localSave == null) return false;

    try {
      _updateStatus(CloudSyncStatus.syncing);
      await _uploadToCloud(_localSave!);
      _updateStatus(CloudSyncStatus.synced);
      return true;
    } catch (e) {
      _updateStatus(CloudSyncStatus.error);
      return false;
    }
  }

  // ============================================================
  // Private Helper Methods
  // ============================================================

  String _generateSaveId() {
    return '${_gameId}_${_userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateChecksum(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    // Simple checksum - in production use proper hashing
    var hash = 0;
    for (var i = 0; i < json.length; i++) {
      hash = (hash << 5) - hash + json.codeUnitAt(i);
      hash &= 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  Future<void> _loadLocalSave() async {
    // TODO: Load from SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // final json = prefs.getString('cloud_save');
    // if (json != null) {
    //   _localSave = CloudSaveData.fromJson(jsonDecode(json));
    // }
  }

  Future<void> _persistLocalSave() async {
    if (_localSave == null) return;

    // TODO: Save to SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('cloud_save', jsonEncode(_localSave!.toJson()));
  }

  Future<CloudSaveData?> _fetchCloudSave() async {
    // TODO: Implement cloud fetch
    // Firebase example:
    // final doc = await _firestore
    //     .collection('saves')
    //     .doc('${_gameId}_$_userId')
    //     .get();
    // if (doc.exists) {
    //   return CloudSaveData.fromJson(doc.data()!);
    // }
    return null;
  }

  Future<void> _uploadToCloud(CloudSaveData save) async {
    // TODO: Implement cloud upload
    // Firebase example:
    // await _firestore
    //     .collection('saves')
    //     .doc(save.id)
    //     .set(save.toJson());
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _syncListeners.clear();
    super.dispose();
  }
}

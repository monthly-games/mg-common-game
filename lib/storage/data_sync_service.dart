import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync conflict resolution strategy
enum ConflictResolution {
  clientWins, // Use client data
  serverWins, // Use server data
  newestWins, // Use newest timestamp
  manual, // Require manual resolution
}

/// Sync data type
enum SyncDataType {
  userProgress,
  inventory,
  currency,
  quests,
  achievements,
  friends,
  settings,
}

/// Sync record
class SyncRecord {
  final String id;
  final SyncDataType type;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final SyncStatus status;
  final String? errorMessage;

  SyncRecord({
    required this.id,
    required this.type,
    required this.userId,
    required this.data,
    required this.createdAt,
    this.syncedAt,
    required this.status,
    this.errorMessage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'userId': userId,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'syncedAt': syncedAt?.millisecondsSinceEpoch,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      id: json['id'],
      type: SyncDataType.values.firstWhere((e) => e.name == json['type']),
      userId: json['userId'],
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      syncedAt: json['syncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['syncedAt'])
          : null,
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      errorMessage: json['errorMessage'],
    );
  }
}

/// Sync result
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;
  final Duration duration;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
    required this.duration,
  });
}

/// Data synchronization service
class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  static DataSyncService get instance => _instance;

  DataSyncService._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final List<SyncRecord> _pendingSyncs = [];
  SyncStatus _currentStatus = SyncStatus.idle;
  Timer? _syncTimer;
  final StreamController<SyncStatus> _statusController = StreamController.broadcast();

  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus get currentStatus => _currentStatus;

  /// Initialize the sync service
  Future<void> initialize({Duration syncInterval = const Duration(minutes: 5)}) async {
    await _storage.initialize();
    await _loadPendingSyncs();

    // Start periodic sync
    _syncTimer = Timer.periodic(syncInterval, (_) => sync());
  }

  /// Load pending syncs from storage
  Future<void> _loadPendingSyncs() async {
    final pendingJson = _storage.getJsonList('pending_syncs');
    if (pendingJson != null) {
      _pendingSyncs.clear();
      for (final json in pendingJson) {
        if (json is Map<String, dynamic>) {
          _pendingSyncs.add(SyncRecord.fromJson(json));
        }
      }
    }
  }

  /// Save pending syncs to storage
  Future<void> _savePendingSyncs() async {
    final jsonList = _pendingSyncs.map((r) => r.toJson()).toList();
    await _storage.setJsonList('pending_syncs', jsonList);
  }

  /// Queue data for sync
  Future<void> queueSync(
    SyncDataType type,
    String userId,
    Map<String, dynamic> data,
  ) async {
    final record = SyncRecord(
      id: '${type.name}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      userId: userId,
      data: data,
      createdAt: DateTime.now(),
      status: SyncStatus.idle,
    );

    _pendingSyncs.add(record);
    await _savePendingSyncs();
  }

  /// Sync all pending data
  Future<SyncResult> sync({
    ConflictResolution conflictResolution = ConflictResolution.newestWins,
    bool forceSync = false,
  }) async {
    if (_currentStatus == SyncStatus.syncing && !forceSync) {
      return SyncResult(
        success: false,
        duration: Duration.zero,
        errors: ['Sync already in progress'],
      );
    }

    final startTime = DateTime.now();
    _updateStatus(SyncStatus.syncing);

    int syncedCount = 0;
    int failedCount = 0;
    final List<String> errors = [];

    try {
      // Process pending syncs
      for (final record in _pendingSyncs.toList()) {
        try {
          final success = await _syncRecord(record, conflictResolution);

          if (success) {
            syncedCount++;
            _pendingSyncs.remove(record);
          } else {
            failedCount++;
            record.status = SyncStatus.error;
            record.errorMessage = 'Sync failed';
          }
        } catch (e) {
          failedCount++;
          record.status = SyncStatus.error;
          record.errorMessage = e.toString();
          errors.add('Failed to sync ${record.type}: $e');
        }
      }

      // Save remaining pending syncs
      await _savePendingSyncs();

      // Sync down from server
      await _syncDown(userId: _pendingSyncs.isNotEmpty ? _pendingSyncs.first.userId : '');

      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: errors.isEmpty,
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      _updateStatus(SyncStatus.error);
      return SyncResult(
        success: false,
        errors: [e.toString()],
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  /// Sync a single record
  Future<bool> _syncRecord(
    SyncRecord record,
    ConflictResolution conflictResolution,
  ) async {
    // This would typically make an API call to sync with server
    // For now, we'll simulate successful sync
    record.status = SyncStatus.success;
    record.syncedAt = DateTime.now();
    return true;
  }

  /// Sync down data from server
  Future<void> _syncDown({required String userId}) async {
    // This would typically fetch data from server
    // For now, we'll simulate it
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Get pending syncs for a user
  List<SyncRecord> getPendingSyncs(String userId) {
    return _pendingSyncs.where((r) => r.userId == userId).toList();
  }

  /// Get pending syncs by type
  List<SyncRecord> getPendingSyncsByType(SyncDataType type) {
    return _pendingSyncs.where((r) => r.type == type).toList();
  }

  /// Clear all pending syncs
  Future<void> clearPendingSyncs() async {
    _pendingSyncs.clear();
    await _savePendingSyncs();
  }

  /// Clear pending syncs for a user
  Future<void> clearUserSyncs(String userId) async {
    _pendingSyncs.removeWhere((r) => r.userId == userId);
    await _savePendingSyncs();
  }

  /// Retry failed syncs
  Future<SyncResult> retryFailed() async {
    final failedSyncs = _pendingSyncs.where((r) => r.status == SyncStatus.error).toList();

    for (final sync in failedSyncs) {
      sync.status = SyncStatus.idle;
      sync.errorMessage = null;
    }

    return await sync();
  }

  /// Get sync statistics
  Map<String, dynamic> getStatistics() {
    final byType = <SyncDataType, int>{};
    final byStatus = <SyncStatus, int>{};

    for (final record in _pendingSyncs) {
      byType[record.type] = (byType[record.type] ?? 0) + 1;
      byStatus[record.status] = (byStatus[record.status] ?? 0) + 1;
    }

    return {
      'pendingCount': _pendingSyncs.length,
      'byType': byType.map((k, v) => MapEntry(k.name, v)),
      'byStatus': byStatus.map((k, v) => MapEntry(k.name, v)),
      'currentStatus': _currentStatus.name,
    };
  }

  /// Manually trigger sync for specific data type
  Future<void> syncDataType(
    SyncDataType type,
    String userId,
    Map<String, dynamic> data,
  ) async {
    await queueSync(type, userId, data);
    await sync();
  }

  /// Resolve sync conflict manually
  Future<void> resolveConflict(
    String recordId,
    Map<String, dynamic> resolvedData,
  ) async {
    final record = _pendingSyncs.firstWhere((r) => r.id == recordId);
    record.data = resolvedData;
    record.status = SyncStatus.idle;
    await _savePendingSyncs();
  }

  /// Dispose of resources
  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
  }

  // ==================== Conflict Resolution Helpers ====================

  /// Merge two data sets based on conflict resolution strategy
  static Map<String, dynamic> resolveConflict(
    Map<String, dynamic> clientData,
    Map<String, dynamic> serverData,
    ConflictResolution strategy,
  ) {
    switch (strategy) {
      case ConflictResolution.clientWins:
        return clientData;
      case ConflictResolution.serverWins:
        return serverData;
      case ConflictResolution.newestWins:
        final clientTime = clientData['timestamp'] as int?;
        final serverTime = serverData['timestamp'] as int?;
        if (clientTime != null && serverTime != null) {
          return clientTime > serverTime ? clientData : serverData;
        }
        return clientData;
      case ConflictResolution.manual:
        throw UnimplementedError('Manual conflict resolution required');
    }
  }

  /// Compare two data sets for conflicts
  static bool hasConflict(
    Map<String, dynamic> clientData,
    Map<String, dynamic> serverData,
  ) {
    // Simple comparison - can be enhanced with more sophisticated logic
    return jsonEncode(clientData) != jsonEncode(serverData);
  }
}

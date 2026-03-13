import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 동기화 상태
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

/// 네트워크 상태
enum NetworkStatus {
  online,
  offline,
}

/// 데이터 충돌 해결 전략
enum ConflictResolution {
  localWins,    // 로컬 우선
  remoteWins,   // 원격 우선
  lastWriteWins, // 마지막 쓰기 우선
  manual,       // 수동 해결
}

/// 동기화 항목
class SyncItem {
  final String key;
  final dynamic value;
  final DateTime lastModified;
  final int version;

  const SyncItem({
    required this.key,
    required this.value,
    required this.lastModified,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'lastModified': lastModified.toIso8601String(),
        'version': version,
      };
}

/// 데이터 충돌
class DataConflict {
  final String key;
  final SyncItem local;
  final SyncItem remote;

  const DataConflict({
    required this.key,
    required this.local,
    required this.remote,
  });
}

/// 오프라인 저장소
class OfflineStorage {
  final Map<String, SyncItem> _data = {};
  final List<String> _pendingUploads = [];
  final List<String> _pendingDownloads = [];

  /// 데이터 저장
  Future<void> set(String key, dynamic value) async {
    final item = SyncItem(
      key: key,
      value: value,
      lastModified: DateTime.now(),
      version: 1,
    );

    _data[key] = item;
    _pendingUploads.add(key);

    debugPrint('[OfflineStorage] Set: $key');
  }

  /// 데이터 조회
  Future<dynamic> get(String key) async {
    final item = _data[key];
    return item?.value;
  }

  /// 데이터 삭제
  Future<void> delete(String key) async {
    _data.remove(key);
    _pendingUploads.add(key);

    debugPrint('[OfflineStorage] Delete: $key');
  }

  /// 보류 중인 업로드 목록
  List<String> get pendingUploads => _pendingUploads.toList();

  /// 보류 중인 다운로드 목록
  List<String> get pendingDownloads => _pendingDownloads.toList();

  /// 모든 데이터
  Map<String, SyncItem> get allData => Map.from(_data);
}

/// 오프라인 지원 관리자
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._();
  static OfflineManager get instance => _instance;

  OfflineManager._();

  final OfflineStorage _storage = OfflineStorage();
  SyncStatus _syncStatus = SyncStatus.idle;
  NetworkStatus _networkStatus = NetworkStatus.offline;
  ConflictResolution _conflictResolution = ConflictResolution.lastWriteWins;

  final StreamController<SyncStatus> _syncController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<NetworkStatus> _networkController =
      StreamController<NetworkStatus>.broadcast();

  Stream<SyncStatus> get onSyncStatus => _syncController.stream;
  Stream<NetworkStatus> get onNetworkStatus => _networkController.stream;

  Timer? _syncTimer;

  /// 초기화
  Future<void> initialize() async {
    // 네트워크 상태 감지 시작
    _startNetworkMonitoring();

    // 주기적 동기화
    _startPeriodicSync();

    // 로컬 데이터 로드
    await _loadLocalData();

    debugPrint('[Offline] Initialized');
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('offline_data');

    if (data != null) {
      // JSON 파싱 (실제 구현)
      debugPrint('[Offline] Loaded ${data.length} bytes');
    }
  }

  void _startNetworkMonitoring() {
    // 네트워크 상태 감지 (실제 구현에서는 connectivity_plus)
    _updateNetworkStatus(NetworkStatus.online);
  }

  void _updateNetworkStatus(NetworkStatus status) {
    _networkStatus = status;
    _networkController.add(status);

    // 온라인이되면 자동 동기화
    if (status == NetworkStatus.online) {
      _syncPendingData();
    }

    debugPrint('[Offline] Network: ${status.name}');
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_networkStatus == NetworkStatus.online) {
        sync();
      }
    });
  }

  /// 데이터 저장
  Future<void> set(String key, dynamic value) async {
    await _storage.set(key, value);

    // 온라인이면 즉시 동기화
    if (_networkStatus == NetworkStatus.online) {
      await _uploadKey(key);
    }
  }

  /// 데이터 조회
  Future<dynamic> get(String key) async {
    return await _storage.get(key);
  }

  /// 데이터 삭제
  Future<void> delete(String key) async {
    await _storage.delete(key);

    if (_networkStatus == NetworkStatus.online) {
      await _uploadKey(key);
    }
  }

  /// 전체 동기화
  Future<void> sync() async {
    if (_syncStatus == SyncStatus.syncing) return;
    if (_networkStatus == NetworkStatus.offline) {
      debugPrint('[Offline] Cannot sync while offline');
      return;
    }

    _syncStatus = SyncStatus.syncing;
    _syncController.add(_syncStatus);

    try {
      // 1. 보류 중인 업로드 처리
      await _uploadPendingData();

      // 2. 보류 중인 다운로드 처리
      await _downloadPendingData();

      // 3. 충돌 해결
      await _resolveConflicts();

      _syncStatus = SyncStatus.success;
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      debugPrint('[Offline] Sync failed: $e');
    }

    _syncController.add(_syncStatus);
  }

  Future<void> _uploadPendingData() async {
    final pending = _storage.pendingUploads;

    for (final key in pending) {
      await _uploadKey(key);
    }
  }

  Future<void> _uploadKey(String key) async {
    final data = await _storage.get(key);
    if (data == null) return;

    // 실제 구현에서는 서버로 업로드
    debugPrint('[Offline] Uploaded: $key');

    // 성공하면 보류 목록에서 제거
    // _storage._pendingUploads.remove(key);
  }

  Future<void> _downloadPendingData() async {
    // 실제 구현에서는 서버에서 다운로드
    debugPrint('[Offline] Downloaded pending data');
  }

  Future<void> _resolveConflicts() async {
    // 충돌 감지 및 해결
    final conflicts = await _detectConflicts();

    for (final conflict in conflicts) {
      await _resolveConflict(conflict);
    }
  }

  Future<List<DataConflict>> _detectConflicts() async {
    // 실제 구현에서는 버전 비교로 충돌 감지
    return [];
  }

  Future<void> _resolveConflict(DataConflict conflict) async {
    switch (_conflictResolution) {
      case ConflictResolution.localWins:
        await _storage.set(conflict.key, conflict.local.value);
        break;
      case ConflictResolution.remoteWins:
        await _storage.set(conflict.key, conflict.remote.value);
        break;
      case ConflictResolution.lastWriteWins:
        final winner = conflict.local.lastModified.isAfter(conflict.remote.lastModified)
            ? conflict.local
            : conflict.remote;
        await _storage.set(conflict.key, winner.value);
        break;
      case ConflictResolution.manual:
        // 수동 해결 로직 (UI 표시 등)
        break;
    }
  }

  Future<void> _syncPendingData() async {
    if (_syncStatus != SyncStatus.syncing) {
      await sync();
    }
  }

  /// 오프라인 여부
  bool get isOffline => _networkStatus == NetworkStatus.offline;

  /// 동기화 상태
  SyncStatus get syncStatus => _syncStatus;

  /// 충돌 해결 전략 설정
  void setConflictResolution(ConflictResolution strategy) {
    _conflictResolution = strategy;
  }

  /// 데이터 내보내기
  String exportData() {
    final data = _storage.allData;
    return jsonEncode(data.map((k, v) => v.toJson()).toList());
  }

  /// 데이터 가져오기
  Future<void> importData(String jsonData) async {
    final List<dynamic> data = jsonDecode(jsonData);

    for (final item in data) {
      await _storage.set(item['key'], item['value']);
    }

    debugPrint('[Offline] Imported ${data.length} items');
  }

  /// 캐시 비우기
  Future<void> clearCache() async {
    // 실제 구현에서는 로컬 데이터 정리
    debugPrint('[Offline] Cache cleared');
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
    _networkController.close();
  }
}

/// 오프라인 큐
class OfflineQueue {
  final List<Map<String, dynamic>> _queue = [];

  /// 작업 추가
  void add(String operation, Map<String, dynamic> data) {
    _queue.add({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 보류 중인 작업 수
  int get pendingCount => _queue.length;

  /// 모든 작업 처리
  Future<void> processAll() async {
    while (_queue.isNotEmpty) {
      final operation = _queue.removeAt(0);
      await _processOperation(operation);
    }
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    // 실제 작업 처리
    debugPrint('[OfflineQueue] Processed: ${operation['operation']}');
  }

  /// 큐 비우기
  void clear() {
    _queue.clear();
  }
}

/// 요청 캐싱
class RequestCache {
  final Map<String, _CachedResponse> _cache = {};
  final Duration _defaultTTL = const Duration(minutes: 5);

  /// 캐시 가져오기
  _CachedResponse? get(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    if (DateTime.now().isAfter(cached.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return cached;
  }

  /// 캐시 저장
  void set(String key, dynamic data, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);

    _cache[key] = _CachedResponse(
      data: data,
      cachedAt: DateTime.now(),
      expiresAt: expiresAt,
    );
  }

  /// 캐시 비우기
  void clear() {
    _cache.clear();
  }

  /// 만료된 항목 정리
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => now.isAfter(value.expiresAt));
  }
}

class _CachedResponse {
  final dynamic data;
  final DateTime cachedAt;
  final DateTime expiresAt;

  _CachedResponse({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
  });
}

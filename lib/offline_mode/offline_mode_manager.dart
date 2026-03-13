import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오프라인 상태
enum OfflineStatus {
  online,         // 온라인
  offline,        // 오프라인
  syncing,        // 동기화 중
  conflict,       // 충돌 발생
}

/// 동기화 상태
enum SyncStatus {
  pending,        // 대기 중
  inProgress,     // 진행 중
  completed,      // 완료
  failed,         // 실패
  conflict,       // 충돌
}

/// 동기화 작업
class SyncOperation {
  final String operationId;
  final String type; // create, update, delete
  final String collection; // users, items, etc.
  final Map<String, dynamic> data;
  final Map<String, dynamic>? metadata;
  final SyncStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? errorMessage;

  const SyncOperation({
    required this.operationId,
    required this.type,
    required this.collection,
    required this.data,
    this.metadata,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.errorMessage,
  });
}

/// 오프라인 작업
class OfflineOperation {
  final String operationId;
  final String action; // login, purchase, craft, etc.
  final Map<String, dynamic> params;
  final DateTime createdAt;
  final bool isProcessed;

  const OfflineOperation({
    required this.operationId,
    required this.action,
    required this.params,
    required this.createdAt,
    required this.isProcessed,
  });
}

/// 오프라인 데이터
class OfflineData {
  final String key;
  final dynamic value;
  final DateTime updatedAt;
  final DateTime? serverTimestamp;
  final bool isModified;

  const OfflineData({
    required this.key,
    required this.value,
    required this.updatedAt,
    this.serverTimestamp,
    this.isModified = false,
  });
}

/// 충돌 해결 전략
enum ConflictResolution {
  clientWins,    // 클라이언트 우선
  serverWins,    // 서버 우선
  manual,        // 수동 해결
  merge,         // 병합
}

/// 동기화 결과
class SyncResult {
  final int totalOperations;
  final int successful;
  final int failed;
  final int conflicts;
  final Duration duration;
  final DateTime syncedAt;

  const SyncResult({
    required this.totalOperations,
    required this.successful,
    required this.failed,
    required this.conflicts,
    required this.duration,
    required this.syncedAt,
  });

  /// 성공률
  double get successRate {
    if (totalOperations == 0) return 0.0;
    return successful / totalOperations;
  }
}

/// 오프라인 모드 관리자
class OfflineModeManager {
  static final OfflineModeManager _instance = OfflineModeManager._();
  static OfflineModeManager get instance => _instance;

  OfflineModeManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  OfflineStatus _status = OfflineStatus.online;
  final List<SyncOperation> _syncQueue = [];
  final List<OfflineOperation> _offlineOperations = [];
  final Map<String, OfflineData> _offlineData = {};

  final StreamController<OfflineStatus> _statusController =
      StreamController<OfflineStatus>.broadcast();
  final StreamController<SyncResult> _syncController =
      StreamController<SyncResult>.broadcast();
  final StreamController<SyncOperation> _operationController =
      StreamController<SyncOperation>.broadcast();

  Stream<OfflineStatus> get onStatusChange => _statusController.stream;
  Stream<SyncResult> get onSync => _syncController.stream;
  Stream<SyncOperation> get onOperationUpdate => _operationController.stream;

  Timer? _syncTimer;
  Timer? _networkCheckTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 오프라인 데이터 로드
    await _loadOfflineData();

    // 동기화 큐 로드
    await _loadSyncQueue();

    // 네트워크 체크 시작
    _startNetworkCheck();

    debugPrint('[OfflineMode] Initialized');
  }

  Future<void> _loadOfflineData() async {
    final json = _prefs?.getString('offline_data_$_currentUserId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[OfflineMode] Error loading data: $e');
      }
    }

    // 기본 오프라인 데이터
    _offlineData['user_profile'] = const OfflineData(
      key: 'user_profile',
      value: {
        'username': 'Player123',
        'level': 50,
        'gold': 10000,
      },
      updatedAt: DateTime.now(),
    );

    _offlineData['inventory'] = const OfflineData(
      key: 'inventory',
      value: [
        {'itemId': 'item_1', 'quantity': 10},
        {'itemId': 'item_2', 'quantity': 5},
      ],
      updatedAt: DateTime.now(),
    );

    _offlineData['quests'] = const OfflineData(
      key: 'quests',
      value: {
        'daily': [
          {'questId': 'daily_1', 'progress': 5, 'max': 10},
        ],
      },
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _loadSyncQueue() async {
    final json = _prefs?.getString('sync_queue_$_currentUserId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[OfflineMode] Error loading queue: $e');
      }
    }
  }

  void _startNetworkCheck() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkNetworkStatus();
    });
  }

  void _checkNetworkStatus() {
    // 실제로는 네트워크 상태 확인
    final isConnected = true; // 시뮬레이션

    if (isConnected && _status == OfflineStatus.offline) {
      setOnline();
    } else if (!isConnected && _status == OfflineStatus.online) {
      setOffline();
    }
  }

  /// 온라인 상태로 전환
  Future<void> setOnline() async {
    if (_status == OfflineStatus.online) return;

    _status = OfflineStatus.syncing;
    _statusController.add(_status);

    debugPrint('[OfflineMode] Going online - syncing...');

    // 동기화 시작
    await sync();

    _status = OfflineStatus.online;
    _statusController.add(_status);

    debugPrint('[OfflineMode] Online');
  }

  /// 오프라인 상태로 전환
  void setOffline() {
    if (_status == OfflineStatus.offline) return;

    _status = OfflineStatus.offline;
    _statusController.add(_status);

    debugPrint('[OfflineMode] Offline');
  }

  /// 데이터 저장
  Future<void> saveData({
    required String key,
    required dynamic value,
    bool isModified = true,
  }) async {
    final data = OfflineData(
      key: key,
      value: value,
      updatedAt: DateTime.now(),
      isModified: isModified,
    );

    _offlineData[key] = data;

    await _persistOfflineData();

    debugPrint('[OfflineMode] Data saved: $key');
  }

  /// 데이터 조회
  T? getData<T>(String key) {
    final data = _offlineData[key];
    if (data == null) return null;
    return data.value as T;
  }

  /// 오프라인 작업 큐에 추가
  Future<void> queueOperation({
    required String action,
    required Map<String, dynamic> params,
  }) async {
    final operation = OfflineOperation(
      operationId: 'op_${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      params: params,
      createdAt: DateTime.now(),
      isProcessed: false,
    );

    _offlineOperations.add(operation);

    await _persistOfflineOperations();

    debugPrint('[OfflineMode] Operation queued: $action');
  }

  /// 동기화
  Future<SyncResult> sync() async {
    if (_status == OfflineStatus.syncing) {
      return const SyncResult(
        totalOperations: 0,
        successful: 0,
        failed: 0,
        conflicts: 0,
        duration: Duration.zero,
        syncedAt: null,
      );
    }

    _status = OfflineStatus.syncing;
    _statusController.add(_status);

    final startTime = DateTime.now();

    var successful = 0;
    var failed = 0;
    var conflicts = 0;

    // 오프라인 데이터 동기화
    for (final data in _offlineData.values) {
      if (data.isModified) {
        try {
          await _syncData(data);
          successful++;
        } catch (e) {
          debugPrint('[OfflineMode] Sync failed: ${data.key}');
          failed++;
        }
      }
    }

    // 오프라인 작업 처리
    for (final operation in _offlineOperations) {
      if (!operation.isProcessed) {
        try {
          await _processOperation(operation);
          successful++;
        } catch (e) {
          debugPrint('[OfflineMode] Operation failed: ${operation.action}');
          failed++;
        }
      }
    }

    final duration = DateTime.now().difference(startTime);

    final result = SyncResult(
      totalOperations: _offlineData.length + _offlineOperations.length,
      successful: successful,
      failed: failed,
      conflicts: conflicts,
      duration: duration,
      syncedAt: DateTime.now(),
    );

    _syncController.add(result);

    // 처리된 작업 제거
    _offlineOperations.removeWhere((op) => op.isProcessed);

    // 수정 플래그 초기화
    for (final key in _offlineData.keys) {
      final data = _offlineData[key];
      _offlineData[key] = OfflineData(
        key: data.key,
        value: data.value,
        updatedAt: data.updatedAt,
        serverTimestamp: data.serverTimestamp,
        isModified: false,
      );
    }

    await _persistOfflineData();
    await _persistOfflineOperations();

    _status = OfflineStatus.online;
    _statusController.add(_status);

    debugPrint('[OfflineMode] Sync completed: $successful success, $failed failed');

    return result;
  }

  Future<void> _syncData(OfflineData data) async {
    // 실제로는 서버에 동기화
    debugPrint('[OfflineMode] Syncing data: ${data.key}');

    // 서버 타임스탬프 업데이트
    _offlineData[data.key] = OfflineData(
      key: data.key,
      value: data.value,
      updatedAt: data.updatedAt,
      serverTimestamp: DateTime.now(),
      isModified: false,
    );
  }

  Future<void> _processOperation(OfflineOperation operation) async {
    // 실제로는 서버에 작업 전송
    debugPrint('[OfflineMode] Processing operation: ${operation.action}');

    // 처리 완료 표시
    // 실제로는 처리 후 상태 업데이트
  }

  /// 충돌 해결
  Future<bool> resolveConflict({
    required String key,
    required ConflictResolution strategy,
    Map<String, dynamic>? clientData,
    Map<String, dynamic>? serverData,
  }) async {
    switch (strategy) {
      case ConflictResolution.clientWins:
        if (clientData != null) {
          await saveData(key: key, value: clientData);
        }
        break;

      case ConflictResolution.serverWins:
        // 서버 데이터 유지 (로컬 데이터 삭제)
        _offlineData.remove(key);
        break;

      case ConflictResolution.manual:
        // 사용자에게 선택 요청
        return false;

      case ConflictResolution.merge:
        // 데이터 병합
        if (clientData != null && serverData != null) {
          final merged = {...serverData, ...clientData};
          await saveData(key: key, value: merged);
        }
        break;
    }

    return true;
  }

  /// 오프라인 가능 여부
  bool canWorkOffline({
    required String action,
    Map<String, dynamic>? params,
  }) {
    // 오프라인에서 가능한 작업인지 확인
    final offlineActions = [
      'view_profile',
      'view_inventory',
      'view_quests',
      'craft_item',
      'battle_ai',
    ];

    return offlineActions.contains(action);
  }

  /// 오프라인 모드에서 작업 실행
  Future<void> executeOffline({
    required String action,
    required Map<String, dynamic> params,
  }) async {
    if (!canWorkOffline(action: action, params: params)) {
      throw Exception('Action not available offline: $action');
    }

    // 로컬에서 작업 실행
    switch (action) {
      case 'craft_item':
        final itemId = params['itemId'] as String;
        final inventory = getData<List>('inventory') ?? [];
        // 아이템 제작 처리
        await saveData(key: 'inventory', value: inventory);
        break;

      case 'battle_ai':
        // AI 전투 처리
        break;

      default:
        break;
    }

    // 작업 큐에 추가 (나중에 동기화)
    await queueOperation(action: action, params: params);
  }

  /// 동기화 큐 조회
  List<SyncOperation> get syncQueue => _syncQueue.toList();

  /// 오프라인 작업 조회
  List<OfflineOperation> get offlineOperations => _offlineOperations.toList();

  /// 대기 중인 작업 수
  int get pendingOperations => _offlineOperations.where((op) => !op.isProcessed).length;

  /// 수정된 데이터 수
  int get modifiedDataCount => _offlineData.values.where((d) => d.isModified).length;

  /// 현재 상태
  OfflineStatus get status => _status;

  /// 오프라인 여부
  bool get isOffline => _status == OfflineStatus.offline;

  /// 온라인 여부
  bool get isOnline => _status == OfflineStatus.online;

  Future<void> _persistOfflineData() async {
    if (_currentUserId == null) return;

    final data = _offlineData.map((key, value) => MapEntry(
      key,
      {
        'value': value.value,
        'updatedAt': value.updatedAt.toIso8601String(),
        'isModified': value.isModified,
      },
    ));

    await _prefs?.setString(
      'offline_data_$_currentUserId',
      jsonEncode(data),
    );
  }

  Future<void> _persistOfflineOperations() async {
    if (_currentUserId == null) return;

    final data = _offlineOperations.map((op) => {
      'operationId': op.operationId,
      'action': op.action,
      'params': op.params,
      'createdAt': op.createdAt.toIso8601String(),
      'isProcessed': op.isProcessed,
    }).toList();

    await _prefs?.setString(
      'offline_ops_$_currentUserId',
      jsonEncode(data),
    );
  }

  /// 강제 동기화
  Future<SyncResult> forceSync() async {
    debugPrint('[OfflineMode] Force sync');
    return sync();
  }

  /// 캐시 정리
  Future<void> clearCache() async {
    _offlineData.clear();
    _syncQueue.clear();

    await _prefs?.remove('offline_data_$_currentUserId');
    await _prefs?.remove('sync_queue_$_currentUserId');

    debugPrint('[OfflineMode] Cache cleared');
  }

  void dispose() {
    _statusController.close();
    _syncController.close();
    _operationController.close();
    _syncTimer?.cancel();
    _networkCheckTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 저장 상태
enum SaveStatus {
  idle,
  saving,
  loading,
  syncing,
  conflict,
  error,
}

/// 저장 데이터
class SaveData {
  final String saveId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int version;
  final String? deviceId;

  const SaveData({
    required this.saveId,
    required this.data,
    required this.timestamp,
    required this.version,
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'saveId': saveId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'deviceId': deviceId,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        saveId: json['saveId'] as String,
        data: json['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['timestamp'] as String),
        version: json['version'] as int,
        deviceId: json['deviceId'] as String?,
      );

  SaveData copyWith({
    String? saveId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? version,
    String? deviceId,
  }) {
    return SaveData(
      saveId: saveId ?? this.saveId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

/// 충돌 해결 전략
enum ConflictResolutionStrategy {
  latestTimestamp,
  manualResolve,
  serverWins,
  clientWins,
  merge,
}

/// 클라우드 저장 매니저
class CloudSaveManager {
  static final CloudSaveManager _instance = CloudSaveManager._();
  static CloudSaveManager get instance => _instance;

  CloudSaveManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  SaveStatus _status = SaveStatus.idle;
  String? _currentDeviceId;

  SaveData? _localSave;
  SaveData? _cloudSave;
  Timer? _autoSaveTimer;
  Timer? _syncTimer;

  final StreamController<SaveStatus> _statusController =
      StreamController<SaveStatus>.broadcast();
  final StreamController<SaveData?> _saveDataController =
      StreamController<SaveData?>.broadcast();

  // ============================================
  // Getters
  // ============================================
  SaveStatus get status => _status;
  bool get isIdle => _status == SaveStatus.idle;
  bool get hasConflict => _status == SaveStatus.conflict;
  SaveData? get localSave => _localSave;
  SaveData? get cloudSave => _cloudSave;

  Stream<SaveStatus> get onStatusChanged => _statusController.stream;
  Stream<SaveData?> get onSaveDataChanged => _saveDataController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 디바이스 ID 생성
    _currentDeviceId = _prefs!.getString('device_id');
    if (_currentDeviceId == null) {
      _currentDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _prefs!.setString('device_id', _currentDeviceId!);
    }

    // 로컬 저장소 로드
    await _loadLocalSave();

    // 자동 동기화 시작
    _startAutoSync();

    debugPrint('[CloudSave] Initialized');
  }

  // ============================================
  // 저장 관리
  // ============================================

  Future<void> save(Map<String, dynamic> data, {bool immediate = false}) async {
    _setStatus(SaveStatus.saving);

    try {
      final saveData = SaveData(
        saveId: 'save_main',
        data: data,
        timestamp: DateTime.now(),
        version: (_localSave?.version ?? 0) + 1,
        deviceId: _currentDeviceId,
      );

      // 로컬에 저장
      await _saveToLocal(saveData);
      _localSave = saveData;

      _saveDataController.add(saveData);

      // 즉시 저장이거나 주기적 저장 타이밍
      if (immediate) {
        await _syncToCloud();
      }

      _setStatus(SaveStatus.idle);
      debugPrint('[CloudSave] Saved successfully');
    } catch (e) {
      _setStatus(SaveStatus.error);
      debugPrint('[CloudSave] Save error: $e');
    }
  }

  Future<void> load() async {
    _setStatus(SaveStatus.loading);

    try {
      // 먼저 로컬 데이터 로드
      await _loadLocalSave();

      // 클라우드에서 동기화
      await _syncFromCloud();

      _setStatus(SaveStatus.idle);
      debugPrint('[CloudSave] Loaded successfully');
    } catch (e) {
      _setStatus(SaveStatus.error);
      debugPrint('[CloudSave] Load error: $e');
    }
  }

  // ============================================
  // 동기화
  // ============================================

  Future<void> sync() async {
    if (!isIdle) return;

    _setStatus(SaveStatus.syncing);

    try {
      // 1. 클라우드에서 데이터 가져오기
      await _syncFromCloud();

      // 2. 충돌 확인
      if (_hasConflict()) {
        _setStatus(SaveStatus.conflict);
        return;
      }

      // 3. 로컬 변경사항을 클라우드로 전송
      if (_localSave != null && _cloudSave != null) {
        if (_localSave!.timestamp.isAfter(_cloudSave!.timestamp)) {
          await _syncToCloud();
        }
      } else if (_localSave != null) {
        await _syncToCloud();
      }

      _setStatus(SaveStatus.idle);
      debugPrint('[CloudSave] Synced successfully');
    } catch (e) {
      _setStatus(SaveStatus.error);
      debugPrint('[CloudSave] Sync error: $e');
    }
  }

  bool _hasConflict() {
    if (_localSave == null || _cloudSave == null) return false;
    if (_localSave!.version == _cloudSave!.version) return false;
    return _localSave!.timestamp != _cloudSave!.timestamp;
  }

  /// 충돌 해결
  Future<void> resolveConflict(
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? manualData,
  }) async {
    if (!hasConflict) return;

    SaveData? resolvedSave;

    switch (strategy) {
      case ConflictResolutionStrategy.latestTimestamp:
        resolvedSave = _localSave!.timestamp.isAfter(_cloudSave!.timestamp)
            ? _localSave
            : _cloudSave;
        break;

      case ConflictResolutionStrategy.serverWins:
        resolvedSave = _cloudSave;
        break;

      case ConflictResolutionStrategy.clientWins:
        resolvedSave = _localSave;
        break;

      case ConflictResolutionStrategy.manualResolve:
        if (manualData != null) {
          resolvedSave = SaveData(
            saveId: _localSave!.saveId,
            data: manualData,
            timestamp: DateTime.now(),
            version: _localSave!.version + 1,
            deviceId: _currentDeviceId,
          );
        }
        break;

      case ConflictResolutionStrategy.merge:
        // 데이터 병합 (간단 구현)
        final mergedData = Map<String, dynamic>.from(_cloudSave!.data);
        mergedData.addAll(_localSave!.data);
        resolvedSave = SaveData(
          saveId: _localSave!.saveId,
          data: mergedData,
          timestamp: DateTime.now(),
          version: _localSave!.version + 1,
          deviceId: _currentDeviceId,
        );
        break;
    }

    if (resolvedSave != null) {
      await _saveToLocal(resolvedSave);
      await _syncToCloud();
      _localSave = resolvedSave;
      _saveDataController.add(resolvedSave);
    }

    _setStatus(SaveStatus.idle);
  }

  // ============================================
  // 내부 메서드
  // ============================================

  Future<void> _saveToLocal(SaveData saveData) async {
    final json = jsonEncode(saveData.toJson());
    await _prefs!.setString('save_data', json);
  }

  Future<void> _loadLocalSave() async {
    final saveStr = _prefs!.getString('save_data');
    if (saveStr != null) {
      final json = jsonDecode(saveStr) as Map<String, dynamic>;
      _localSave = SaveData.fromJson(json);
      _saveDataController.add(_localSave);
    }
  }

  Future<void> _syncToCloud() async {
    if (_localSave == null) return;

    // 실제 클라우드 전송 (Firebase, Google Drive 등)
    // 여기서는 시뮬레이션만 수행
    await Future.delayed(const Duration(milliseconds: 500));

    final json = jsonEncode(_localSave!.toJson());
    await _prefs!.setString('cloud_save_data', json);
    _cloudSave = _localSave;

    debugPrint('[CloudSave] Synced to cloud');
  }

  Future<void> _syncFromCloud() async {
    // 실제 클라우드에서 가져오기 (Firebase, Google Drive 등)
    // 여기서는 시뮬레이션만 수행
    await Future.delayed(const Duration(milliseconds: 500));

    final cloudStr = _prefs!.getString('cloud_save_data');
    if (cloudStr != null) {
      final json = jsonDecode(cloudStr) as Map<String, dynamic>;
      _cloudSave = SaveData.fromJson(json);
    }

    debugPrint('[CloudSave] Synced from cloud');
  }

  void _startAutoSync() {
    // 30초마다 자동 동기화
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isIdle) {
        sync();
      }
    });
  }

  void _setStatus(SaveStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
    }
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 자동 저장 활성화
  void enableAutoSave({Duration interval = const Duration(minutes: 5)}) {
    _autoSaveTimer?.cancel();

    _autoSaveTimer = Timer.periodic(interval, (_) {
      if (_localSave != null && isIdle) {
        save(_localSave!.data);
      }
    });

    debugPrint('[CloudSave] Auto-save enabled');
  }

  /// 자동 저장 비활성화
  void disableAutoSave() {
    _autoSaveTimer?.cancel();
    debugPrint('[CloudSave] Auto-save disabled');
  }

  /// 데이터 내보내기
  Future<String> exportData() async {
    if (_localSave == null) return '';
    return jsonEncode(_localSave!.toJson());
  }

  /// 데이터 가져오기
  Future<void> importData(String jsonData) async {
    try {
      final json = jsonDecode(jsonData) as Map<String, dynamic>;
      final saveData = SaveData.fromJson(json);

      await save(saveData.data, immediate: true);
      debugPrint('[CloudSave] Data imported');
    } catch (e) {
      debugPrint('[CloudSave] Import error: $e');
    }
  }

  /// 저장 데이터 삭제
  Future<void> clearData() async {
    await _prefs!.remove('save_data');
    await _prefs!.remove('cloud_save_data');

    _localSave = null;
    _cloudSave = null;

    _saveDataController.add(null);

    debugPrint('[CloudSave] Data cleared');
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _autoSaveTimer?.cancel();
    _syncTimer?.cancel();
    _statusController.close();
    _saveDataController.close();
  }
}

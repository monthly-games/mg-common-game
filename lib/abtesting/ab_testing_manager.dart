import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A/B 테스트 상태
enum ExperimentState {
  notStarted,
  running,
  paused,
  completed,
}

/// A/B 테스트 결과
class ExperimentResult {
  final String experimentId;
  final Map<String, int> groupAssignments;
  final Map<String, Map<String, double>> metrics;
  final DateTime startTime;
  final DateTime? endTime;

  const ExperimentResult({
    required this.experimentId,
    required this.groupAssignments,
    required this.metrics,
    required this.startTime,
    this.endTime,
  });
}

/// 실험 메트릭
class ExperimentMetric {
  final String name;
  final double value;
  final String? groupId;
  final DateTime timestamp;

  const ExperimentMetric({
    required this.name,
    required this.value,
    this.groupId,
    required this.timestamp,
  });
}

/// A/B 테스트 실험
class Experiment {
  final String id;
  final String name;
  final String description;
  final ExperimentState state;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> variants;
  final Map<String, dynamic>? parameters;
  final int targetSampleSize;
  final int currentSampleSize;

  const Experiment({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.startTime,
    this.endTime,
    required this.variants,
    this.parameters,
    required this.targetSampleSize,
    required this.currentSampleSize,
  });

  /// 활성화 여부
  bool get isActive => state == ExperimentState.running;

  /// 완료 여부
  bool get isCompleted => state == ExperimentState.completed;
}

/// 기능 플래그
class FeatureFlag {
  final String key;
  final String name;
  final String description;
  final bool enabled;
  final Map<String, bool>? userOverrides;
  final double? rolloutPercentage;

  const FeatureFlag({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
    this.userOverrides,
    this.rolloutPercentage,
  });
}

/// A/B 테스트 관리자
class ABTestingManager {
  static final ABTestingManager _instance = ABTestingManager._();
  static ABTestingManager get instance => _instance;

  ABTestingManager._();

  final Map<String, Experiment> _experiments = {};
  final Map<String, FeatureFlag> _featureFlags = {};
  final Map<String, String> _userAssignments = {};

  final StreamController<Experiment> _experimentController =
      StreamController<Experiment>.broadcast();
  final StreamController<FeatureFlag> _featureController =
      StreamController<FeatureFlag>.broadcast();

  Stream<Experiment> get onExperimentUpdate => _experimentController.stream;
  Stream<FeatureFlag> get onFeatureUpdate => _featureController.stream;

  SharedPreferences? _prefs;
  String? _userId;
  final Random _random = Random();

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs?.getString('user_id');

    // 실험 로드
    _loadExperiments();

    // 기능 플래그 로드
    _loadFeatureFlags();

    // 사용자 배정 로드
    _loadUserAssignments();

    debugPrint('[ABTesting] Initialized');
  }

  void _loadExperiments() {
    final now = DateTime.now();

    _experiments.addAll({
      'new_ui_design': Experiment(
        id: 'new_ui_design',
        name: '새로운 UI 디자인',
        description: '새로운 UI 디자인 테스트',
        state: ExperimentState.running,
        startTime: now.subtract(const Duration(days: 7)),
        variants: ['control', 'variant_a', 'variant_b'],
        targetSampleSize: 1000,
        currentSampleSize: 750,
      ),
      'tutorial_flow': Experiment(
        id: 'tutorial_flow',
        name: '튜토리얼 흐름',
        description: '튜토리얼 완료율 개선 테스트',
        state: ExperimentState.running,
        startTime: now.subtract(const Duration(days: 3)),
        variants: ['original', 'simplified'],
        targetSampleSize: 500,
        currentSampleSize: 200,
      ),
    });
  }

  void _loadFeatureFlags() {
    _featureFlags.addAll({
      'premium_features': const FeatureFlag(
        key: 'premium_features',
        name: '프리미엄 기능',
        description: '프리미엄 기능 활성화',
        enabled: true,
        rolloutPercentage: 100.0,
      ),
      'new_battle_system': const FeatureFlag(
        key: 'new_battle_system',
        name: '새 배틀 시스템',
        description: '새로운 배틀 시스템',
        enabled: false,
        rolloutPercentage: 10.0,
      ),
      'social_sharing': const FeatureFlag(
        key: 'social_sharing',
        name: '소셜 공유',
        description: '소셜 미디어 공유 기능',
        enabled: true,
        rolloutPercentage: 50.0,
      ),
    });
  }

  void _loadUserAssignments() {
    // 사용자별 그룹 배정 로드
    final saved = _prefs?.getString('ab_assignments');
    if (saved != null) {
      // JSON 파싱 (실제 구현에서는 직접 처리)
      debugPrint('[ABTesting] Loaded user assignments');
    }
  }

  void setCurrentUser(String userId) {
    _userId = userId;
  }

  /// 실험 생성
  Future<void> createExperiment({
    required String id,
    required String name,
    required String description,
    required List<String> variants,
    required DateTime startTime,
    DateTime? endTime,
    int targetSampleSize = 1000,
    Map<String, dynamic>? parameters,
  }) async {
    final experiment = Experiment(
      id: id,
      name: name,
      description: description,
      state: ExperimentState.notStarted,
      startTime: startTime,
      endTime: endTime,
      variants: variants,
      parameters: parameters,
      targetSampleSize: targetSampleSize,
      currentSampleSize: 0,
    );

    _experiments[id] = experiment;
    _experimentController.add(experiment);

    debugPrint('[ABTesting] Experiment created: $id');
  }

  /// 실험 시작
  Future<void> startExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) return;

    final started = Experiment(
      id: experiment.id,
      name: experiment.name,
      description: experiment.description,
      state: ExperimentState.running,
      startTime: DateTime.now(),
      endTime: experiment.endTime,
      variants: experiment.variants,
      parameters: experiment.parameters,
      targetSampleSize: experiment.targetSampleSize,
      currentSampleSize: 0,
    );

    _experiments[experimentId] = started;
    _experimentController.add(started);

    debugPrint('[ABTesting] Experiment started: $experimentId');
  }

  /// 실험 종료
  Future<void> stopExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) return;

    final stopped = Experiment(
      id: experiment.id,
      name: experiment.name,
      description: experiment.description,
      state: ExperimentState.completed,
      startTime: experiment.startTime,
      endTime: DateTime.now(),
      variants: experiment.variants,
      parameters: experiment.parameters,
      targetSampleSize: experiment.targetSampleSize,
      currentSampleSize: experiment.currentSampleSize,
    );

    _experiments[experimentId] = stopped;
    _experimentController.add(stopped);

    debugPrint('[ABTesting] Experiment stopped: $experimentId');
  }

  /// 실험 일시 중지
  Future<void> pauseExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null || experiment.state != ExperimentState.running) {
      return;
    }

    final paused = Experiment(
      id: experiment.id,
      name: experiment.name,
      description: experiment.description,
      state: ExperimentState.paused,
      startTime: experiment.startTime,
      endTime: experiment.endTime,
      variants: experiment.variants,
      parameters: experiment.parameters,
      targetSampleSize: experiment.targetSampleSize,
      currentSampleSize: experiment.currentSampleSize,
    );

    _experiments[experimentId] = paused;
    _experimentController.add(paused);

    debugPrint('[ABTesting] Experiment paused: $experimentId');
  }

  /// 사용자 그룹 배정
  String getVariant(String experimentId) {
    if (_userId == null) {
      return _experiments[experimentId]?.variants.first ?? 'control';
    }

    // 기존 배정 확인
    final key = '${_userId}_$experimentId';
    if (_userAssignments.containsKey(key)) {
      return _userAssignments[key]!;
    }

    // 새로운 배정
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) {
      return 'control';
    }

    // 해시 기반 결정적 배정
    final hash = _userId!.hashCode + experimentId.hashCode;
    final index = hash.abs() % experiment.variants.length;
    final variant = experiment.variants[index];

    // 배정 저장
    _userAssignments[key] = variant;
    _saveUserAssignments();

    debugPrint('[ABTesting] Assigned $variant to $_userId for $experimentId');

    return variant;
  }

  Future<void> _saveUserAssignments() async {
    // 실제 구현에서는 JSON으로 저장
    await _prefs?.setString('ab_assignments', '{}');
  }

  /// 기능 플래그 확인
  bool isFeatureEnabled(String featureKey) {
    final flag = _featureFlags[featureKey];
    if (flag == null) return false;

    // 사용자별 오버라이드 확인
    if (flag.userOverrides != null && _userId != null) {
      final override = flag.userOverrides![_userId!];
      if (override != null) {
        return override;
      }
    }

    // 전체 활성화 확인
    if (!flag.enabled) return false;

    // 롤아웃 퍼센트 확인
    if (flag.rolloutPercentage != null) {
      final hash = (_userId?.hashCode ?? 0) % 100;
      return hash < flag.rolloutPercentage! * 100;
    }

    return true;
  }

  /// 기능 플래그 설정
  Future<void> setFeatureFlag({
    required String key,
    required bool enabled,
    double? rolloutPercentage,
    Map<String, bool>? userOverrides,
  }) async {
    final existing = _featureFlags[key];

    final flag = FeatureFlag(
      key: key,
      name: existing?.name ?? key,
      description: existing?.description ?? '',
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      userOverrides: userOverrides,
    );

    _featureFlags[key] = flag;
    _featureController.add(flag);

    debugPrint('[ABTesting] Feature flag updated: $key = $enabled');
  }

  /// 메트릭 기록
  Future<void> trackMetric({
    required String experimentId,
    required String metricName,
    required double value,
  }) async {
    final variant = getVariant(experimentId);

    final metric = ExperimentMetric(
      name: metricName,
      value: value,
      groupId: variant,
      timestamp: DateTime.now(),
    );

    // 실제 구현에서는 분석 서비스로 전송
    debugPrint('[ABTesting] Metric: $metricName = $value ($variant)');
  }

  /// 실험 결과 계산
  ExperimentResult? calculateResults(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return null;

    // 실제 구현에서는 통계적 유의성 검증
    return ExperimentResult(
      experimentId: experimentId,
      groupAssignments: {
        for (final variant in experiment.variants)
          variant: experiment.currentSampleSize ~/ experiment.variants.length,
      },
      metrics: {
        'conversion_rate': {
          for (final variant in experiment.variants)
            variant: 0.5 + (_random.nextDouble() * 0.2),
        },
        'retention': {
          for (final variant in experiment.variants)
            variant: 0.7 + (_random.nextDouble() * 0.15),
        },
      },
      startTime: experiment.startTime,
      endTime: DateTime.now(),
    );
  }

  /// 실험 목록 조회
  List<Experiment> getExperiments({ExperimentState? state}) {
    var experiments = _experiments.values.toList();

    if (state != null) {
      experiments = experiments.where((e) => e.state == state).toList();
    }

    return experiments;
  }

  /// 활성 실험 조회
  List<Experiment> getActiveExperiments() {
    return getExperiments(state: ExperimentState.running);
  }

  /// 기능 플래그 목록 조회
  List<FeatureFlag> getFeatureFlags({bool? enabled}) {
    var flags = _featureFlags.values.toList();

    if (enabled != null) {
      flags = flags.where((f) => f.enabled == enabled).toList();
    }

    return flags;
  }

  /// 통계적 유의성 검증
  bool isStatisticallySignificant({
    required String experimentId,
    required String metricName,
    required double confidenceLevel,
  }) {
    final results = calculateResults(experimentId);
    if (results == null) return false;

    // 실제 구현에서는 t-test, chi-square test 등
    return false;
  }

  void dispose() {
    _experimentController.close();
    _featureController.close();
  }
}

/// 원격 설정
class RemoteConfig {
  final String key;
  final dynamic defaultValue;
  final dynamic value;
  final DateTime? lastFetched;

  const RemoteConfig({
    required this.key,
    required this.defaultValue,
    this.value,
    this.lastFetched,
  });

  /// 값 가져오기
  T getValue<T>(T Function(dynamic) converter) {
    if (value != null) {
      return converter(value) as T;
    }
    return converter(defaultValue) as T;
  }
}

/// 원격 설정 관리자
class RemoteConfigManager {
  static final RemoteConfigManager _instance = RemoteConfigManager._();
  static RemoteConfigManager get instance => _instance;

  RemoteConfigManager._();

  final Map<String, RemoteConfig> _configs = {};
  final Duration _cacheDuration = const Duration(hours: 1);
  DateTime? _lastFetchTime;

  /// 초기화
  Future<void> initialize() async {
    // 기본 원격 설정 로드
    _loadDefaultConfigs();

    // 원격 설정 가져오기
    await fetchConfigs();

    debugPrint('[RemoteConfig] Initialized');
  }

  void _loadDefaultConfigs() {
    _configs.addAll({
      'game_difficulty': const RemoteConfig(
        key: 'game_difficulty',
        defaultValue: 'normal',
        value: 'normal',
      ),
      'max_daily_energy': const RemoteConfig(
        key: 'max_daily_energy',
        defaultValue: 100,
        value: 100,
      ),
      'event_enabled': const RemoteConfig(
        key: 'event_enabled',
        defaultValue: false,
        value: true,
      ),
      'maintenance_message': const RemoteConfig(
        key: 'maintenance_message',
        defaultValue: '',
        value: '',
      ),
    });
  }

  /// 원격 설정 가져오기
  Future<void> fetchConfigs() async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return;
    }

    // 실제 구현에서는 Remote Config API 호출
    await Future.delayed(const Duration(milliseconds: 500));

    _lastFetchTime = DateTime.now();
    debugPrint('[RemoteConfig] Fetched');
  }

  /// 설정 값 조회
  T getValue<T>(String key, T Function(dynamic) converter) {
    final config = _configs[key];
    if (config == null) {
      throw Exception('Remote config not found: $key');
    }

    return config.getValue(converter);
  }

  /// 부울 값 조회
  bool getBool(String key) {
    return getValue(key, (v) => v as bool? ?? false);
  }

  /// 정수 값 조회
  int getInt(String key) {
    return getValue(key, (v) => v as int? ?? 0);
  }

  /// 실수 값 조회
  double getDouble(String key) {
    return getValue(key, (v) => v as double? ?? 0.0);
  }

  /// 문자열 값 조회
  String getString(String key) {
    return getValue(key, (v) => v as String? ?? '');
  }
}

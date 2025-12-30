/// A/B 테스트 매니저
///
/// 실험 관리, 유저 할당, 이벤트 추적
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'ab_test_types.dart';

/// A/B 테스트 매니저
///
/// 여러 실험을 관리하고, 유저를 변형에 할당하며, 이벤트를 추적
class ABTestManager extends ChangeNotifier {
  /// 현재 유저 ID
  String? _currentUserId;

  /// 등록된 실험들
  final Map<String, ExperimentConfig> _experiments = {};

  /// 유저 할당 결과 캐시
  final Map<String, UserExperimentAssignment> _assignments = {};

  /// 추적된 이벤트들
  final List<ExperimentEvent> _trackedEvents = [];

  /// 오버라이드 (개발/테스트용)
  final Map<String, String> _overrides = {};

  /// 랜덤 생성기
  final Random _random;

  /// 콜백 - 백엔드 연동용
  Future<List<ExperimentConfig>> Function()? onFetchExperiments;
  Future<UserExperimentAssignment?> Function(String experimentId)?
      onFetchAssignment;
  Future<void> Function(ExperimentEvent event)? onTrackEvent;
  Future<void> Function(String experimentId, String variantId)?
      onSaveAssignment;

  ABTestManager({int? randomSeed}) : _random = Random(randomSeed);

  // ============================================================
  // Getters
  // ============================================================

  /// 현재 유저 ID
  String? get currentUserId => _currentUserId;

  /// 등록된 실험 ID 목록
  List<String> get experimentIds => _experiments.keys.toList();

  /// 활성 실험 목록
  List<ExperimentConfig> get activeExperiments =>
      _experiments.values.where((e) => e.isActive).toList();

  /// 추적된 이벤트 수
  int get trackedEventCount => _trackedEvents.length;

  /// 오버라이드된 실험 수
  int get overrideCount => _overrides.length;

  // ============================================================
  // 초기화
  // ============================================================

  /// 유저 설정
  void setUser(String odId) {
    if (_currentUserId != odId) {
      _currentUserId = odId;
      _assignments.clear();
      notifyListeners();
    }
  }

  /// 실험 등록
  void registerExperiment(ExperimentConfig config) {
    _experiments[config.id] = config;
    debugPrint('Experiment registered: ${config.id} (${config.name})');
  }

  /// 여러 실험 등록
  void registerExperiments(List<ExperimentConfig> configs) {
    for (final config in configs) {
      _experiments[config.id] = config;
    }
    debugPrint('${configs.length} experiments registered');
  }

  /// 서버에서 실험 목록 가져오기
  Future<void> fetchExperiments() async {
    if (onFetchExperiments != null) {
      try {
        final experiments = await onFetchExperiments!();
        for (final exp in experiments) {
          _experiments[exp.id] = exp;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to fetch experiments: $e');
      }
    }
  }

  /// 실험 가져오기
  ExperimentConfig? getExperiment(String experimentId) =>
      _experiments[experimentId];

  /// 실험 제거
  void removeExperiment(String experimentId) {
    _experiments.remove(experimentId);
    _assignments.remove(experimentId);
  }

  // ============================================================
  // 변형 할당
  // ============================================================

  /// 유저를 실험 변형에 할당하고 변형 ID 반환
  Future<String?> getVariant(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) {
      debugPrint('Experiment not found: $experimentId');
      return null;
    }

    // 오버라이드 확인
    if (_overrides.containsKey(experimentId)) {
      return _overrides[experimentId];
    }

    // 비활성 실험은 컨트롤 그룹 반환
    if (!experiment.isActive) {
      return experiment.controlVariant?.id;
    }

    // 캐시된 할당 확인
    final cached = _assignments[experimentId];
    if (cached != null) {
      return cached.isInTraffic ? cached.variantId : null;
    }

    // 서버에서 기존 할당 조회
    if (onFetchAssignment != null && _currentUserId != null) {
      try {
        final assignment = await onFetchAssignment!(experimentId);
        if (assignment != null) {
          _assignments[experimentId] = assignment;
          return assignment.isInTraffic ? assignment.variantId : null;
        }
      } catch (e) {
        debugPrint('Failed to fetch assignment: $e');
      }
    }

    // 새로 할당
    if (_currentUserId == null) return null;

    // 트래픽 비율 확인
    final inTraffic = _isInTrafficPercentage(
      _currentUserId!,
      experimentId,
      experiment.trafficPercentage,
    );

    if (!inTraffic) {
      _assignments[experimentId] = UserExperimentAssignment(
        odId: _currentUserId!,
        experimentId: experimentId,
        variantId: experiment.controlVariant?.id ?? experiment.variants.first.id,
        assignedAt: DateTime.now(),
        isInTraffic: false,
      );
      return null;
    }

    // 변형 할당
    final variantId = _assignVariant(experiment);

    final assignment = UserExperimentAssignment(
      odId: _currentUserId!,
      experimentId: experimentId,
      variantId: variantId,
      assignedAt: DateTime.now(),
      isInTraffic: true,
    );

    _assignments[experimentId] = assignment;

    // 서버에 저장
    if (onSaveAssignment != null) {
      try {
        await onSaveAssignment!(experimentId, variantId);
      } catch (e) {
        debugPrint('Failed to save assignment: $e');
      }
    }

    notifyListeners();
    return variantId;
  }

  /// 동기적으로 캐시된 변형 가져오기
  String? getVariantSync(String experimentId) {
    // 오버라이드 확인
    if (_overrides.containsKey(experimentId)) {
      return _overrides[experimentId];
    }

    final cached = _assignments[experimentId];
    if (cached != null && cached.isInTraffic) {
      return cached.variantId;
    }

    final experiment = _experiments[experimentId];
    return experiment?.controlVariant?.id;
  }

  /// 변형의 파라미터 가져오기
  T? getParameter<T>(String experimentId, String parameterKey) {
    final variantId = getVariantSync(experimentId);
    if (variantId == null) return null;

    final experiment = _experiments[experimentId];
    if (experiment == null) return null;

    final variant = experiment.variants.cast<ExperimentVariant?>().firstWhere(
          (v) => v?.id == variantId,
          orElse: () => null,
        );

    return variant?.parameters[parameterKey] as T?;
  }

  /// 특정 변형인지 확인
  bool isVariant(String experimentId, String variantId) {
    return getVariantSync(experimentId) == variantId;
  }

  /// 컨트롤 그룹인지 확인
  bool isControl(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return true;

    final variantId = getVariantSync(experimentId);
    return variantId == experiment.controlVariant?.id;
  }

  // ============================================================
  // 이벤트 추적
  // ============================================================

  /// 실험 이벤트 추적
  Future<void> trackEvent(
    String experimentId,
    String eventName, {
    Map<String, dynamic>? eventData,
  }) async {
    final assignment = _assignments[experimentId];
    if (assignment == null || !assignment.isInTraffic) return;

    final event = ExperimentEvent(
      experimentId: experimentId,
      variantId: assignment.variantId,
      eventName: eventName,
      eventData: eventData,
      timestamp: DateTime.now(),
      odId: _currentUserId,
    );

    _trackedEvents.add(event);

    if (onTrackEvent != null) {
      try {
        await onTrackEvent!(event);
      } catch (e) {
        debugPrint('Failed to track event: $e');
      }
    }
  }

  /// 전환 이벤트 추적
  Future<void> trackConversion(
    String experimentId, {
    String conversionName = 'conversion',
    Map<String, dynamic>? eventData,
  }) async {
    await trackEvent(experimentId, conversionName, eventData: eventData);
  }

  /// 모든 활성 실험에 이벤트 추적
  Future<void> trackEventForAllExperiments(
    String eventName, {
    Map<String, dynamic>? eventData,
  }) async {
    for (final experimentId in _assignments.keys) {
      await trackEvent(experimentId, eventName, eventData: eventData);
    }
  }

  // ============================================================
  // 오버라이드 (개발/테스트용)
  // ============================================================

  /// 실험 오버라이드 설정
  void setOverride(String experimentId, String variantId) {
    _overrides[experimentId] = variantId;
    notifyListeners();
  }

  /// 오버라이드 제거
  void removeOverride(String experimentId) {
    _overrides.remove(experimentId);
    notifyListeners();
  }

  /// 모든 오버라이드 제거
  void clearOverrides() {
    _overrides.clear();
    notifyListeners();
  }

  /// 현재 오버라이드 목록
  Map<String, String> get overrides => Map.unmodifiable(_overrides);

  // ============================================================
  // Private 메서드
  // ============================================================

  bool _isInTrafficPercentage(
    String odId,
    String experimentId,
    double trafficPercentage,
  ) {
    if (trafficPercentage >= 100) return true;
    if (trafficPercentage <= 0) return false;

    // 유저 ID와 실험 ID 조합으로 일관된 해시 생성
    final hash = '$odId-$experimentId-traffic'.hashCode.abs();
    final bucket = (hash % 100).toDouble();

    return bucket < trafficPercentage;
  }

  String _assignVariant(ExperimentConfig experiment) {
    switch (experiment.allocationStrategy) {
      case AllocationStrategy.random:
        return _assignRandomVariant(experiment);

      case AllocationStrategy.userIdHash:
        return _assignByUserIdHash(experiment);

      case AllocationStrategy.firstVisitTime:
        return _assignByFirstVisit(experiment);

      case AllocationStrategy.manual:
        return experiment.controlVariant?.id ?? experiment.variants.first.id;
    }
  }

  String _assignRandomVariant(ExperimentConfig experiment) {
    final totalWeight = experiment.totalWeight;
    var random = _random.nextDouble() * totalWeight;

    for (final variant in experiment.variants) {
      random -= variant.weight;
      if (random <= 0) {
        return variant.id;
      }
    }

    return experiment.variants.first.id;
  }

  String _assignByUserIdHash(ExperimentConfig experiment) {
    if (_currentUserId == null) {
      return experiment.controlVariant?.id ?? experiment.variants.first.id;
    }

    // 유저 ID와 실험 ID 조합으로 일관된 해시 생성
    final hash = '$_currentUserId-${experiment.id}'.hashCode.abs();

    // 가중치 기반 할당
    final totalWeight = experiment.totalWeight;
    var bucket = (hash % 1000) / 1000.0 * totalWeight;

    for (final variant in experiment.variants) {
      bucket -= variant.weight;
      if (bucket <= 0) {
        return variant.id;
      }
    }

    return experiment.variants.first.id;
  }

  String _assignByFirstVisit(ExperimentConfig experiment) {
    // 단순화된 구현 - 현재 시간 기반
    final now = DateTime.now();
    final bucket = now.millisecondsSinceEpoch % 1000 / 1000.0;

    final totalWeight = experiment.totalWeight;
    var remaining = bucket * totalWeight;

    for (final variant in experiment.variants) {
      remaining -= variant.weight;
      if (remaining <= 0) {
        return variant.id;
      }
    }

    return experiment.variants.first.id;
  }

  // ============================================================
  // 저장/불러오기
  // ============================================================

  Map<String, dynamic> toJson() => {
        'currentUserId': _currentUserId,
        'assignments':
            _assignments.map((k, v) => MapEntry(k, v.toJson())),
        'overrides': _overrides,
      };

  void fromJson(Map<String, dynamic> json) {
    _currentUserId = json['currentUserId'] as String?;

    _assignments.clear();
    if (json['assignments'] != null) {
      final assignmentsMap = json['assignments'] as Map<String, dynamic>;
      for (final entry in assignmentsMap.entries) {
        _assignments[entry.key] = UserExperimentAssignment.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    _overrides.clear();
    if (json['overrides'] != null) {
      _overrides.addAll(
        Map<String, String>.from(json['overrides'] as Map),
      );
    }

    notifyListeners();
  }

  /// 추적된 이벤트 가져오기
  List<ExperimentEvent> getTrackedEvents({String? experimentId}) {
    if (experimentId == null) {
      return List.unmodifiable(_trackedEvents);
    }
    return _trackedEvents
        .where((e) => e.experimentId == experimentId)
        .toList();
  }

  /// 추적된 이벤트 클리어
  void clearTrackedEvents() {
    _trackedEvents.clear();
  }

  /// 모든 데이터 클리어
  void clear() {
    _currentUserId = null;
    _experiments.clear();
    _assignments.clear();
    _trackedEvents.clear();
    _overrides.clear();
    notifyListeners();
  }
}

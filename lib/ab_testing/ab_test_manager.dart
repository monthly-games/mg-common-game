import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 실험 상태
enum ExperimentStatus {
  notStarted,
  running,
  completed,
  paused,
}

/// 변형 타입
enum VariantType {
  control, // 대조군
  a, // 실험군 A
  b, // 실험군 B
  custom,
}

/// 실험 변형
class ExperimentVariant {
  final String id;
  final String name;
  final VariantType type;
  final double weight; // 할당 확률 (0.0 - 1.0)
  final Map<String, dynamic> config;

  const ExperimentVariant({
    required this.id,
    required this.name,
    required this.type,
    required this.weight,
    this.config = const {},
  });

  /// 대조군 변형
  static const ExperimentVariant control = ExperimentVariant(
    id: 'control',
    name: 'Control Group',
    type: VariantType.control,
    weight: 0.5,
  );

  /// A 변형
  static const ExperimentVariant variantA = ExperimentVariant(
    id: 'variant_a',
    name: 'Variant A',
    type: VariantType.a,
    weight: 0.5,
    config: {},
  );
}

/// 실험 정의
class Experiment {
  final String id;
  final String name;
  final String description;
  final List<ExperimentVariant> variants;
  final ExperimentStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int targetSampleSize;
  final List<String> targetMetrics;

  const Experiment({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.status,
    this.startDate,
    this.endDate,
    this.targetSampleSize = 1000,
    this.targetMetrics = const [],
  });

  /// 현재 활성화된 실험인지 확인
  bool get isActive => status == ExperimentStatus.running &&
      (startDate == null || DateTime.now().isAfter(startDate!)) &&
      (endDate == null || DateTime.now().isBefore(endDate!));

  /// 변형의 총 가중치 확인
  double get totalWeight => variants.fold(0, (sum, v) => sum + v.weight);
}

/// 실험 참여 정보
class ExperimentParticipation {
  final String experimentId;
  final String variantId;
  final DateTime enrolledAt;
  final Map<String, dynamic> metadata;

  const ExperimentParticipation({
    required this.experimentId,
    required this.variantId,
    required this.enrolledAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'variantId': variantId,
        'enrolledAt': enrolledAt.toIso8601String(),
        'metadata': metadata,
      };

  factory ExperimentParticipation.fromJson(Map<String, dynamic> json) =>
      ExperimentParticipation(
        experimentId: json['experimentId'] as String,
        variantId: json['variantId'] as String,
        enrolledAt: DateTime.parse(json['enrolledAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );
}

/// 메트릭 데이터
class MetricData {
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const MetricData({
    required this.name,
    required this.value,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

/// A/B 테스트 매니저
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._();
  static ABTestManager get instance => _instance;

  ABTestManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, Experiment> _experiments = {};
  final Map<String, ExperimentParticipation> _participations = {};
  final Map<String, List<MetricData>> _metrics = {};

  final StreamController<ExperimentParticipation> _enrollmentController =
      StreamController<ExperimentParticipation>.broadcast();
  final StreamController<MetricData> _metricController =
      StreamController<MetricData>.broadcast();

  final Random _random = Random.secure();

  // Getters
  List<Experiment> get experiments => _experiments.values.toList();
  List<ExperimentParticipation> get participations => _participations.values.toList();
  Stream<ExperimentParticipation> get onEnrolled => _enrollmentController.stream;
  Stream<MetricData> get onMetric => _metricController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 참여 정보 로드
    await _loadParticipations();

    // 실험 로드 (실제로는 서버에서)
    _loadDefaultExperiments();

    debugPrint('[ABTest] Initialized');
  }

  Future<void> _loadParticipations() async {
    final participationsJson = _prefs!.getStringList('ab_participations');
    if (participationsJson != null) {
      for (final json in participationsJson) {
        final participation = ExperimentParticipation.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        _participations[participation.experimentId] = participation;
      }
    }
  }

  void _loadDefaultExperiments() {
    // 기본 실험 정의 (실제로는 서버에서 가져옴)
    _experiments['onboarding_flow'] = const Experiment(
      id: 'onboarding_flow',
      name: '온보딩 플로우 테스트',
      description: '간단한 온보딩 vs 상세한 온보딩',
      variants: [
        ExperimentVariant(
          id: 'simple',
          name: '간단한 온보딩',
          type: VariantType.control,
          weight: 0.5,
          config: {'steps': 3},
        ),
        ExperimentVariant(
          id: 'detailed',
          name: '상세한 온보딩',
          type: VariantType.a,
          weight: 0.5,
          config: {'steps': 7},
        ),
      ],
      status: ExperimentStatus.running,
      targetSampleSize: 1000,
      targetMetrics: ['completion_rate', 'time_to_complete'],
    );

    _experiments['reward_display'] = const Experiment(
      id: 'reward_display',
      name: '보상 표시 방식',
      description: '숫자로 표시 vs 아이콘으로 표시',
      variants: [
        ExperimentVariant(
          id: 'numeric',
          name: '숫자 표시',
          type: VariantType.control,
          weight: 0.5,
        ),
        ExperimentVariant(
          id: 'icon',
          name: '아이콘 표시',
          type: VariantType.a,
          weight: 0.5,
        ),
      ],
      status: ExperimentStatus.running,
      targetMetrics: ['engagement', 'click_rate'],
    );
  }

  // ============================================
  // 실험 관리
  // ============================================

  /// 실험 등록
  void registerExperiment(Experiment experiment) {
    _experiments[experiment.id] = experiment;
    debugPrint('[ABTest] Experiment registered: ${experiment.name}');
  }

  /// 실험 참여
  Future<ExperimentVariant?> enrollExperiment(String experimentId) async {
    if (!_isInitialized) {
      await initialize();
    }

    final experiment = _experiments[experimentId];
    if (experiment == null) {
      debugPrint('[ABTest] Experiment not found: $experimentId');
      return null;
    }

    if (!experiment.isActive) {
      debugPrint('[ABTest] Experiment not active: $experimentId');
      return null;
    }

    // 이미 참여중인지 확인
    final existing = _participations[experimentId];
    if (existing != null) {
      final variant = experiment.variants.firstWhere(
        (v) => v.id == existing.variantId,
        orElse: () => ExperimentVariant.control,
      );
      return variant;
    }

    // 변형 할당
    final variant = _assignVariant(experiment);

    final participation = ExperimentParticipation(
      experimentId: experimentId,
      variantId: variant.id,
      enrolledAt: DateTime.now(),
    );

    _participations[experimentId] = participation;
    await _saveParticipations();

    _enrollmentController.add(participation);

     // 애널리틱스에 전송
     AnalyticsManager.instance.trackEvent(
       name: 'ab_test_enrolled',
       category: EventCategory.engagement,
       properties: {
         'experiment_id': experimentId,
         'variant_id': variant.id,
       },
     );

    debugPrint('[ABTest] Enrolled in $experimentId: ${variant.name}');
    return variant;
  }

  /// 변형 할당 (가중 기반 랜덤)
  ExperimentVariant _assignVariant(Experiment experiment) {
    final totalWeight = experiment.totalWeight;
    final randomValue = _random.nextDouble() * totalWeight;

    double accumulatedWeight = 0;

    for (final variant in experiment.variants) {
      accumulatedWeight += variant.weight;
      if (randomValue <= accumulatedWeight) {
        return variant;
      }
    }

    return experiment.variants.first;
  }

  /// 현재 변형 확인
  ExperimentVariant? getVariant(String experimentId) {
    final experiment = _experiments[experimentId];
    final participation = _participations[experimentId];

    if (experiment == null || participation == null) {
      return null;
    }

    return experiment.variants.firstWhere(
      (v) => v.id == participation.variantId,
      orElse: () => ExperimentVariant.control,
    );
  }

  /// 변형 설정값 가져오기
  T? getVariantConfig<T>(String experimentId, String key) {
    final variant = getVariant(experimentId);
    if (variant == null) return null;

    return variant.config[key] as T?;
  }

  /// 실험 탈퇴
  Future<void> leaveExperiment(String experimentId) async {
    _participations.remove(experimentId);
    await _saveParticipations();

    debugPrint('[ABTest] Left experiment: $experimentId');
  }

  // ============================================
  // 메트릭 추적
  // ============================================

  /// 메트릭 기록
  Future<void> trackMetric({
    required String experimentId,
    required String metricName,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_participations.containsKey(experimentId)) {
      debugPrint('[ABTest] Not enrolled in experiment: $experimentId');
      return;
    }

    final metric = MetricData(
      name: metricName,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _metrics.putIfAbsent(experimentId, () => []).add(metric);

    _metricController.add(metric);

     // 애널리틱스에 전송
     AnalyticsManager.instance.trackEvent(
       name: 'ab_test_metric',
       category: EventCategory.engagement,
       properties: {
         'experiment_id': experimentId,
         'metric_name': metricName,
         'metric_value': value,
         'variant_id': _participations[experimentId]!.variantId,
       },
     );

    debugPrint('[ABTest] Metric tracked: $metricName = $value');
  }

  /// 실험별 메트릭 가져오기
  List<MetricData> getMetrics(String experimentId) {
    return _metrics[experimentId] ?? [];
  }

  /// 변형별 메트릭 통계
  Map<String, double> getVariantStatistics(String experimentId, String metricName) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return {};

    final stats = <String, double>{};

    for (final variant in experiment.variants) {
      final participations = _participations.values
          .where((p) => p.experimentId == experimentId && p.variantId == variant.id);

      if (participations.isEmpty) {
        stats[variant.id] = 0.0;
        continue;
      }

      final variantMetrics = _metrics[experimentId]
              ?.where((m) => participations.any((p) =>
                  p.enrolledAt.isBefore(m.timestamp) &&
                  m.name == metricName))
              .toList() ??
          [];

      if (variantMetrics.isEmpty) {
        stats[variant.id] = 0.0;
        continue;
      }

      final average = variantMetrics
          .map((m) => m.value)
          .reduce((a, b) => a + b) / variantMetrics.length;

      stats[variant.id] = average;
    }

    return stats;
  }

  /// 실험 결과 리포트
  Map<String, dynamic> getExperimentReport(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return {};

    final report = <String, dynamic>{
      'experiment_id': experimentId,
      'experiment_name': experiment.name,
      'status': experiment.status.name,
      'total_participants': _participations.values
          .where((p) => p.experimentId == experimentId)
          .length,
      'variants': <String, dynamic>{},
    };

    for (final variant in experiment.variants) {
      final variantParticipations = _participations.values
          .where((p) => p.experimentId == experimentId && p.variantId == variant.id)
          .length;

      report['variants'][variant.id] = {
        'name': variant.name,
        'participants': variantParticipations,
        'metrics': <String, dynamic>{},
      };

      for (final metricName in experiment.targetMetrics) {
        final stats = getVariantStatistics(experimentId, metricName);
        report['variants'][variant.id]['metrics'][metricName] =
            stats[variant.id] ?? 0.0;
      }
    }

    return report;
  }

  // ============================================
  // 피쳐 플래그
  // ============================================

  /// 피쳐 활성화 확인
  bool isFeatureEnabled(String featureName) {
    // 피쳐 플래그 형태의 실험 확인
    final featureExperiment = _experiments['feature_$featureName'];
    if (featureExperiment == null) return false;

    final variant = getVariant('feature_$featureName');
    return variant != null;
  }

  /// 피쳐 설정값 확인
  T? getFeatureConfig<T>(String featureName, String key) {
    return getVariantConfig<T>('feature_$featureName', key);
  }

  // ============================================
  // 리소스 정리
  // ============================================

  Future<void> _saveParticipations() async {
    final participationsJson = _participations.values
        .map((p) => jsonEncode(p.toJson()))
        .toList();

    await _prefs!.setStringList('ab_participations', participationsJson);
  }

  void dispose() {
    _enrollmentController.close();
    _metricController.close();
  }

  bool get _isInitialized => _prefs != null;
}

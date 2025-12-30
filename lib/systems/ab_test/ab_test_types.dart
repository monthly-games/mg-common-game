/// A/B 테스트 시스템 타입 정의
///
/// 실험 그룹, 변형, 설정 모델 정의
library;

import 'dart:math';

/// 실험 상태
enum ExperimentStatus {
  /// 준비 중
  draft,

  /// 실행 중
  running,

  /// 일시 정지
  paused,

  /// 완료
  completed,

  /// 보관됨
  archived,
}

/// 유저 할당 방식
enum AllocationStrategy {
  /// 랜덤 할당
  random,

  /// 유저 ID 기반 해시 (일관된 할당)
  userIdHash,

  /// 첫 접속 시간 기반
  firstVisitTime,

  /// 수동 할당
  manual,
}

/// 실험 변형 (Variant)
class ExperimentVariant {
  final String id;
  final String name;
  final Map<String, dynamic> parameters;
  final double weight;
  final bool isControl;

  const ExperimentVariant({
    required this.id,
    required this.name,
    this.parameters = const {},
    this.weight = 1.0,
    this.isControl = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parameters': parameters,
        'weight': weight,
        'isControl': isControl,
      };

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) {
    return ExperimentVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      isControl: json['isControl'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'ExperimentVariant($id: $name, weight: $weight)';
}

/// 실험 설정
class ExperimentConfig {
  final String id;
  final String name;
  final String? description;
  final List<ExperimentVariant> variants;
  final ExperimentStatus status;
  final AllocationStrategy allocationStrategy;
  final DateTime? startDate;
  final DateTime? endDate;
  final double trafficPercentage;
  final List<String>? targetAudience;
  final Map<String, dynamic>? metadata;

  const ExperimentConfig({
    required this.id,
    required this.name,
    this.description,
    required this.variants,
    this.status = ExperimentStatus.draft,
    this.allocationStrategy = AllocationStrategy.userIdHash,
    this.startDate,
    this.endDate,
    this.trafficPercentage = 100.0,
    this.targetAudience,
    this.metadata,
  });

  /// 컨트롤 그룹 가져오기
  ExperimentVariant? get controlVariant =>
      variants.cast<ExperimentVariant?>().firstWhere(
            (v) => v?.isControl == true,
            orElse: () => null,
          );

  /// 실험이 활성 상태인지 확인
  bool get isActive {
    if (status != ExperimentStatus.running) return false;

    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;

    return true;
  }

  /// 총 가중치
  double get totalWeight => variants.fold(0.0, (sum, v) => sum + v.weight);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'variants': variants.map((v) => v.toJson()).toList(),
        'status': status.index,
        'allocationStrategy': allocationStrategy.index,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'trafficPercentage': trafficPercentage,
        'targetAudience': targetAudience,
        'metadata': metadata,
      };

  factory ExperimentConfig.fromJson(Map<String, dynamic> json) {
    return ExperimentConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      variants: (json['variants'] as List<dynamic>)
          .map((v) => ExperimentVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
      status: ExperimentStatus.values[json['status'] as int? ?? 0],
      allocationStrategy:
          AllocationStrategy.values[json['allocationStrategy'] as int? ?? 1],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      trafficPercentage: (json['trafficPercentage'] as num?)?.toDouble() ?? 100.0,
      targetAudience: (json['targetAudience'] as List<dynamic>?)?.cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  ExperimentConfig copyWith({
    ExperimentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ExperimentConfig(
      id: id,
      name: name,
      description: description,
      variants: variants,
      status: status ?? this.status,
      allocationStrategy: allocationStrategy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trafficPercentage: trafficPercentage,
      targetAudience: targetAudience,
      metadata: metadata,
    );
  }
}

/// 유저 실험 할당 결과
class UserExperimentAssignment {
  final String odId;
  final String experimentId;
  final String variantId;
  final DateTime assignedAt;
  final bool isInTraffic;

  const UserExperimentAssignment({
    required this.odId,
    required this.experimentId,
    required this.variantId,
    required this.assignedAt,
    this.isInTraffic = true,
  });

  Map<String, dynamic> toJson() => {
        'userId': odId,
        'experimentId': experimentId,
        'variantId': variantId,
        'assignedAt': assignedAt.toIso8601String(),
        'isInTraffic': isInTraffic,
      };

  factory UserExperimentAssignment.fromJson(Map<String, dynamic> json) {
    return UserExperimentAssignment(
      odId: json['userId'] as String,
      experimentId: json['experimentId'] as String,
      variantId: json['variantId'] as String,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      isInTraffic: json['isInTraffic'] as bool? ?? true,
    );
  }
}

/// 실험 이벤트 (분석용)
class ExperimentEvent {
  final String experimentId;
  final String variantId;
  final String eventName;
  final Map<String, dynamic>? eventData;
  final DateTime timestamp;
  final String? odId;

  const ExperimentEvent({
    required this.experimentId,
    required this.variantId,
    required this.eventName,
    this.eventData,
    required this.timestamp,
    this.odId,
  });

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'variantId': variantId,
        'eventName': eventName,
        'eventData': eventData,
        'timestamp': timestamp.toIso8601String(),
        'userId': odId,
      };

  factory ExperimentEvent.fromJson(Map<String, dynamic> json) {
    return ExperimentEvent(
      experimentId: json['experimentId'] as String,
      variantId: json['variantId'] as String,
      eventName: json['eventName'] as String,
      eventData: json['eventData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      odId: json['userId'] as String?,
    );
  }
}

/// 실험 결과 요약
class ExperimentResults {
  final String experimentId;
  final Map<String, VariantMetrics> variantMetrics;
  final DateTime calculatedAt;

  const ExperimentResults({
    required this.experimentId,
    required this.variantMetrics,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'variantMetrics': variantMetrics.map((k, v) => MapEntry(k, v.toJson())),
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

/// 변형별 지표
class VariantMetrics {
  final String variantId;
  final int participants;
  final int conversions;
  final double conversionRate;
  final Map<String, double> customMetrics;

  const VariantMetrics({
    required this.variantId,
    required this.participants,
    required this.conversions,
    required this.conversionRate,
    this.customMetrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'participants': participants,
        'conversions': conversions,
        'conversionRate': conversionRate,
        'customMetrics': customMetrics,
      };

  factory VariantMetrics.fromJson(Map<String, dynamic> json) {
    return VariantMetrics(
      variantId: json['variantId'] as String,
      participants: json['participants'] as int,
      conversions: json['conversions'] as int,
      conversionRate: (json['conversionRate'] as num).toDouble(),
      customMetrics: Map<String, double>.from(
        (json['customMetrics'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
    );
  }
}

/// 간단한 A/B 테스트 헬퍼
class SimpleABTest {
  final String testId;
  final List<String> variants;
  final Random _random;

  SimpleABTest({
    required this.testId,
    required this.variants,
    int? seed,
  }) : _random = Random(seed);

  /// 랜덤 변형 선택
  String getRandomVariant() {
    return variants[_random.nextInt(variants.length)];
  }

  /// 유저 ID 기반 일관된 변형 선택
  String getVariantForUser(String odId) {
    final hash = odId.hashCode.abs();
    return variants[hash % variants.length];
  }

  /// 가중치 기반 변형 선택
  String getWeightedVariant(Map<String, double> weights) {
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);
    var random = _random.nextDouble() * totalWeight;

    for (final entry in weights.entries) {
      random -= entry.value;
      if (random <= 0) {
        return entry.key;
      }
    }

    return weights.keys.first;
  }
}

enum ResourceType {
  gold,
  exp,
  currency,
  material,
  energy,
  token,
  custom,
}

enum IdleModifierType {
  additive,
  multiplicative,
}

class OfflineCaps {
  final Duration maxOfflineTime;
  final double maxOfflineReward;
  final double offlineEfficiency;

  OfflineCaps({
    required this.maxOfflineTime,
    required this.maxOfflineReward,
    this.offlineEfficiency = 1.0,
  })  : assert(maxOfflineTime.inMilliseconds >= 0),
        assert(maxOfflineReward >= 0),
        assert(offlineEfficiency >= 0 && offlineEfficiency <= 1.0);

  OfflineCaps.standard()
      : maxOfflineTime = const Duration(hours: 8),
        maxOfflineReward = double.infinity,
        offlineEfficiency = 1.0;

  Map<String, dynamic> toJson() {
    return {
      'maxOfflineTimeMs': maxOfflineTime.inMilliseconds,
      'maxOfflineReward': maxOfflineReward,
      'offlineEfficiency': offlineEfficiency,
    };
  }

  factory OfflineCaps.fromJson(Map<String, dynamic> json) {
    return OfflineCaps(
      maxOfflineTime: Duration(milliseconds: (json['maxOfflineTimeMs'] as int?) ?? 0),
      maxOfflineReward: (json['maxOfflineReward'] as num?)?.toDouble() ?? double.infinity,
      offlineEfficiency: (json['offlineEfficiency'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class IdleResource {
  final String id;
  final String name;
  final double baseRate;
  final ResourceType type;

  IdleResource({
    required this.id,
    required this.name,
    required this.baseRate,
    required this.type,
  })  : assert(id != ''),
        assert(name != ''),
        assert(baseRate >= 0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseRate': baseRate,
      'type': type.name,
    };
  }

  factory IdleResource.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? ResourceType.custom.name;
    final resolvedType = ResourceType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => ResourceType.custom,
    );

    return IdleResource(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown',
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? 0,
      type: resolvedType,
    );
  }
}

class IdleConfig {
  final Duration tickInterval;
  final double baseProductionRate;
  final OfflineCaps offlineCaps;
  final List<IdleResource> resources;
  final bool enableBoosts;
  final bool enableModifiers;

  IdleConfig({
    required this.tickInterval,
    required this.baseProductionRate,
    required this.offlineCaps,
    this.resources = const [],
    this.enableBoosts = true,
    this.enableModifiers = true,
  })  : assert(tickInterval.inMilliseconds >= 0),
        assert(baseProductionRate >= 0);

  IdleConfig.standard()
      : tickInterval = const Duration(seconds: 1),
        baseProductionRate = 1.0,
        offlineCaps = OfflineCaps.standard(),
        resources = const [],
        enableBoosts = true,
        enableModifiers = true;

  IdleConfig copyWith({
    Duration? tickInterval,
    double? baseProductionRate,
    OfflineCaps? offlineCaps,
    List<IdleResource>? resources,
    bool? enableBoosts,
    bool? enableModifiers,
  }) {
    return IdleConfig(
      tickInterval: tickInterval ?? this.tickInterval,
      baseProductionRate: baseProductionRate ?? this.baseProductionRate,
      offlineCaps: offlineCaps ?? this.offlineCaps,
      resources: resources ?? this.resources,
      enableBoosts: enableBoosts ?? this.enableBoosts,
      enableModifiers: enableModifiers ?? this.enableModifiers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tickIntervalMs': tickInterval.inMilliseconds,
      'baseProductionRate': baseProductionRate,
      'offlineCaps': offlineCaps.toJson(),
      'resources': resources.map((resource) => resource.toJson()).toList(growable: false),
      'enableBoosts': enableBoosts,
      'enableModifiers': enableModifiers,
    };
  }

  factory IdleConfig.fromJson(Map<String, dynamic> json) {
    final rawResources = json['resources'] as List<dynamic>? ?? const [];

    return IdleConfig(
      tickInterval: Duration(milliseconds: (json['tickIntervalMs'] as int?) ?? 1000),
      baseProductionRate: (json['baseProductionRate'] as num?)?.toDouble() ?? 1.0,
      offlineCaps: json['offlineCaps'] is Map<String, dynamic>
          ? OfflineCaps.fromJson(json['offlineCaps'] as Map<String, dynamic>)
          : OfflineCaps.standard(),
      resources: rawResources
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(IdleResource.fromJson)
          .toList(growable: false),
      enableBoosts: json['enableBoosts'] as bool? ?? true,
      enableModifiers: json['enableModifiers'] as bool? ?? true,
    );
  }
}

class IdleBoost {
  final String id;
  final double multiplier;
  final Duration duration;
  final DateTime appliedAt;

  IdleBoost({
    required this.id,
    required this.multiplier,
    required this.duration,
    DateTime? appliedAt,
  })  : assert(id != ''),
        assert(multiplier >= 0),
        assert(duration.inMilliseconds >= 0),
        appliedAt = appliedAt ?? DateTime.now();

  bool isActiveAt(DateTime reference) {
    return !reference.isBefore(appliedAt) && reference.isBefore(appliedAt.add(duration));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'multiplier': multiplier,
      'durationMs': duration.inMilliseconds,
      'appliedAtMs': appliedAt.millisecondsSinceEpoch,
    };
  }

  factory IdleBoost.fromJson(Map<String, dynamic> json) {
    return IdleBoost(
      id: json['id'] as String? ?? 'unknown',
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
      duration: Duration(milliseconds: (json['durationMs'] as int?) ?? 0),
      appliedAt: DateTime.fromMillisecondsSinceEpoch((json['appliedAtMs'] as int?) ?? 0),
    );
  }
}

class IdleModifier {
  final String id;
  final double value;
  final IdleModifierType type;

  IdleModifier({
    required this.id,
    required this.value,
    this.type = IdleModifierType.multiplicative,
  })  : assert(id != ''),
        assert(value >= 0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'type': type.name,
    };
  }

  factory IdleModifier.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? IdleModifierType.multiplicative.name;
    final type = IdleModifierType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => IdleModifierType.multiplicative,
    );

    return IdleModifier(
      id: json['id'] as String? ?? 'unknown',
      value: (json['value'] as num?)?.toDouble() ?? 1.0,
      type: type,
    );
  }
}

class IdleReward {
  final Duration offlineDuration;
  final double amount;
  final bool wasCapped;

  IdleReward({
    required this.offlineDuration,
    required this.amount,
    required this.wasCapped,
  });

  Map<String, dynamic> toJson() {
    return {
      'offlineDurationMs': offlineDuration.inMilliseconds,
      'amount': amount,
      'wasCapped': wasCapped,
    };
  }

  factory IdleReward.fromJson(Map<String, dynamic> json) {
    return IdleReward(
      offlineDuration: Duration(milliseconds: (json['offlineDurationMs'] as int?) ?? 0),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      wasCapped: json['wasCapped'] as bool? ?? false,
    );
  }
}

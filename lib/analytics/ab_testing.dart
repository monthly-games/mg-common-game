import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:mg_common_game/storage/local_storage_service.dart';

/// Experiment status
enum ExperimentStatus {
  drafting,
  running,
  paused,
  completed,
  archived,
}

/// Traffic allocation strategy
enum AllocationStrategy {
  random,      // Random assignment
  consistent,  // Consistent hash based assignment
  weighted,    // Weighted random assignment
}

/// Variant configuration
class ExperimentVariant {
  final String variantId;
  final String name;
  final String description;
  final double weight; // 0.0 to 1.0
  final Map<String, dynamic> config;

  ExperimentVariant({
    required this.variantId,
    required this.name,
    required this.description,
    required this.weight,
    required this.config,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'name': name,
      'description': description,
      'weight': weight,
      'config': config,
    };
  }

  /// Create from JSON
  factory ExperimentVariant.fromJson(Map<String, dynamic> json) {
    return ExperimentVariant(
      variantId: json['variantId'],
      name: json['name'],
      description: json['description'],
      weight: json['weight'].toDouble(),
      config: json['config'] as Map<String, dynamic>,
    );
  }
}

/// A/B Test experiment
class Experiment {
  final String experimentId;
  final String name;
  final String description;
  final ExperimentStatus status;
  final List<ExperimentVariant> variants;
  final AllocationStrategy allocationStrategy;
  final DateTime? startTime;
  final DateTime? endTime;
  final int targetSampleSize;
  final Map<String, String> userAssignments; // userId -> variantId
  final Map<String, int> variantCounts; // variantId -> count

  Experiment({
    required this.experimentId,
    required this.name,
    required this.description,
    required this.status,
    required this.variants,
    required this.allocationStrategy,
    this.startTime,
    this.endTime,
    this.targetSampleSize = 1000,
    Map<String, String>? userAssignments,
    Map<String, int>? variantCounts,
  })  : userAssignments = userAssignments ?? {},
        variantCounts = variantCounts ?? {};

  /// Get control variant
  ExperimentVariant? get controlVariant {
    try {
      return variants.firstWhere((v) => v.variantId == 'control');
    } catch (e) {
      return variants.isNotEmpty ? variants.first : null;
    }
  }

  /// Check if experiment is active
  bool get isActive {
    if (status != ExperimentStatus.running) return false;

    final now = DateTime.now();
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;

    return true;
  }

  /// Get total participants
  int get totalParticipants => userAssignments.length;

  /// Check if target sample size reached
  bool get targetReached => totalParticipants >= targetSampleSize;

  /// Get variant distribution
  Map<String, double> get distribution {
    if (totalParticipants == 0) return {};

    final distribution = <String, double>{};
    for (final entry in variantCounts.entries) {
      distribution[entry.key] = entry.value / totalParticipants;
    }
    return distribution;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'experimentId': experimentId,
      'name': name,
      'description': description,
      'status': status.name,
      'variants': variants.map((v) => v.toJson()).toList(),
      'allocationStrategy': allocationStrategy.name,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'targetSampleSize': targetSampleSize,
      'userAssignments': userAssignments,
      'variantCounts': variantCounts,
    };
  }

  /// Create from JSON
  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      experimentId: json['experimentId'],
      name: json['name'],
      description: json['description'],
      status: ExperimentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExperimentStatus.drafting,
      ),
      variants: (json['variants'] as List)
          .map((v) => ExperimentVariant.fromJson(v))
          .toList(),
      allocationStrategy: AllocationStrategy.values.firstWhere(
        (e) => e.name == json['allocationStrategy'],
        orElse: () => AllocationStrategy.random,
      ),
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      targetSampleSize: json['targetSampleSize'] ?? 1000,
      userAssignments: (json['userAssignments'] as Map?)?.cast<String, String>() ?? {},
      variantCounts: (json['variantCounts'] as Map?)?.cast<String, int>() ?? {},
    );
  }
}

/// Experiment result
class ExperimentResult {
  final String experimentId;
  final String variantId;
  final int participantCount;
  final double conversionRate;
  final Map<String, double> metrics;
  final double? confidenceInterval;
  final double? pValue;

  ExperimentResult({
    required this.experimentId,
    required this.variantId,
    required this.participantCount,
    required this.conversionRate,
    required this.metrics,
    this.confidenceInterval,
    this.pValue,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'experimentId': experimentId,
      'variantId': variantId,
      'participantCount': participantCount,
      'conversionRate': conversionRate,
      'metrics': metrics,
      'confidenceInterval': confidenceInterval,
      'pValue': pValue,
    };
  }
}

/// A/B Testing manager
class ABTestManager {
  static final ABTestManager _instance = ABTestManager._internal();
  static ABTestManager get instance => _instance;

  ABTestManager._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final Map<String, Experiment> _experiments = {};
  final Map<String, Map<String, String>> _userAssignments = {}; // experimentId -> userId -> variantId
  final Random _random = Random();

  final StreamController<Experiment> _experimentController = StreamController.broadcast();

  /// Stream of experiment updates
  Stream<Experiment> get experimentStream => _experimentController.stream;

  bool _isInitialized = false;

  /// Initialize A/B test manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _storage.initialize();
    await _loadExperiments();
    await _loadUserAssignments();

    _isInitialized = true;
  }

  /// Load experiments from storage
  Future<void> _loadExperiments() async {
    final experimentsJson = _storage.getJsonList('ab_experiments');
    if (experimentsJson != null) {
      for (final json in experimentsJson) {
        if (json is Map<String, dynamic>) {
          final experiment = Experiment.fromJson(json);
          _experiments[experiment.experimentId] = experiment;
        }
      }
    }
  }

  /// Save experiments to storage
  Future<void> _saveExperiments() async {
    final jsonList = _experiments.values.map((e) => e.toJson()).toList();
    await _storage.setJsonList('ab_experiments', jsonList);
  }

  /// Load user assignments from storage
  Future<void> _loadUserAssignments() async {
    final assignmentsJson = _storage.getJson('ab_user_assignments');
    if (assignmentsJson != null) {
      for (final entry in assignmentsJson.entries) {
        _userAssignments[entry.key] = Map<String, String>.from(entry.value);
      }
    }
  }

  /// Save user assignments to storage
  Future<void> _saveUserAssignments() async {
    final json = _userAssignments.map((k, v) => MapEntry(k, v));
    await _storage.setJson('ab_user_assignments', json);
  }

  /// Create new experiment
  Future<bool> createExperiment({
    required String experimentId,
    required String name,
    required String description,
    required List<ExperimentVariant> variants,
    AllocationStrategy allocationStrategy = AllocationStrategy.random,
    DateTime? startTime,
    DateTime? endTime,
    int targetSampleSize = 1000,
  }) async {
    if (_experiments.containsKey(experimentId)) {
      return false;
    }

    // Validate variant weights sum to 1.0
    final totalWeight = variants.fold<double>(0.0, (sum, v) => sum + v.weight);
    if ((totalWeight - 1.0).abs() > 0.01) {
      throw Exception('Variant weights must sum to 1.0');
    }

    final experiment = Experiment(
      experimentId: experimentId,
      name: name,
      description: description,
      status: ExperimentStatus.drafting,
      variants: variants,
      allocationStrategy: allocationStrategy,
      startTime: startTime,
      endTime: endTime,
      targetSampleSize: targetSampleSize,
    );

    _experiments[experimentId] = experiment;
    await _saveExperiments();

    _experimentController.add(experiment);

    return true;
  }

  /// Get experiment by ID
  Experiment? getExperiment(String experimentId) {
    return _experiments[experimentId];
  }

  /// Get all experiments
  List<Experiment> getAllExperiments() {
    return _experiments.values.toList()
      ..sort((a, b) => b.startTime?.compareTo(a.startTime ?? DateTime.now()) ?? 0);
  }

  /// Get active experiments
  List<Experiment> getActiveExperiments() {
    return _experiments.values.where((e) => e.isActive).toList();
  }

  /// Start experiment
  Future<bool> startExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) return false;

    final updated = Experiment(
      experimentId: experiment.experimentId,
      name: experiment.name,
      description: experiment.description,
      status: ExperimentStatus.running,
      variants: experiment.variants,
      allocationStrategy: experiment.allocationStrategy,
      startTime: experiment.startTime ?? DateTime.now(),
      endTime: experiment.endTime,
      targetSampleSize: experiment.targetSampleSize,
      userAssignments: experiment.userAssignments,
      variantCounts: experiment.variantCounts,
    );

    _experiments[experimentId] = updated;
    await _saveExperiments();

    _experimentController.add(updated);

    return true;
  }

  /// Pause experiment
  Future<bool> pauseExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) return false;

    final updated = Experiment(
      experimentId: experiment.experimentId,
      name: experiment.name,
      description: experiment.description,
      status: ExperimentStatus.paused,
      variants: experiment.variants,
      allocationStrategy: experiment.allocationStrategy,
      startTime: experiment.startTime,
      endTime: experiment.endTime,
      targetSampleSize: experiment.targetSampleSize,
      userAssignments: experiment.userAssignments,
      variantCounts: experiment.variantCounts,
    );

    _experiments[experimentId] = updated;
    await _saveExperiments();

    _experimentController.add(updated);

    return true;
  }

  /// Complete experiment
  Future<bool> completeExperiment(String experimentId) async {
    final experiment = _experiments[experimentId];
    if (experiment == null) return false;

    final updated = Experiment(
      experimentId: experiment.experimentId,
      name: experiment.name,
      description: experiment.description,
      status: ExperimentStatus.completed,
      variants: experiment.variants,
      allocationStrategy: experiment.allocationStrategy,
      startTime: experiment.startTime,
      endTime: experiment.endTime ?? DateTime.now(),
      targetSampleSize: experiment.targetSampleSize,
      userAssignments: experiment.userAssignments,
      variantCounts: experiment.variantCounts,
    );

    _experiments[experimentId] = updated;
    await _saveExperiments();

    _experimentController.add(updated);

    return true;
  }

  /// Assign user to variant
  String assignVariant(String experimentId, String userId) {
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) {
      return 'control';
    }

    // Check if user already assigned
    _userAssignments.putIfAbsent(experimentId, () => {});
    if (_userAssignments[experimentId]!.containsKey(userId)) {
      return _userAssignments[experimentId]![userId]!;
    }

    // Assign to variant based on strategy
    final variantId = _allocateVariant(experiment, userId);

    // Store assignment
    _userAssignments[experimentId]![userId] = variantId;
    experiment.userAssignments[userId] = variantId;
    experiment.variantCounts[variantId] = (experiment.variantCounts[variantId] ?? 0) + 1;

    _saveUserAssignments();
    _saveExperiments();

    return variantId;
  }

  /// Allocate variant based on strategy
  String _allocateVariant(Experiment experiment, String userId) {
    switch (experiment.allocationStrategy) {
      case AllocationStrategy.random:
        return _randomWeightedAllocation(experiment.variants);

      case AllocationStrategy.consistent:
        return _consistentHashAllocation(experiment.variants, userId);

      case AllocationStrategy.weighted:
        return _randomWeightedAllocation(experiment.variants);
    }
  }

  /// Random weighted allocation
  String _randomWeightedAllocation(List<ExperimentVariant> variants) {
    final rand = _random.nextDouble();
    var cumulativeWeight = 0.0;

    for (final variant in variants) {
      cumulativeWeight += variant.weight;
      if (rand <= cumulativeWeight) {
        return variant.variantId;
      }
    }

    return variants.last.variantId;
  }

  /// Consistent hash allocation
  String _consistentHashAllocation(List<ExperimentVariant> variants, String userId) {
    final hash = userId.hashCode.abs() % variants.length;
    return variants[hash].variantId;
  }

  /// Get user's assigned variant
  String? getUserVariant(String experimentId, String userId) {
    return _userAssignments[experimentId]?[userId];
  }

  /// Get variant config for user
  Map<String, dynamic>? getVariantConfig(String experimentId, String userId) {
    final variantId = getUserVariant(experimentId, userId);
    if (variantId == null) return null;

    final experiment = _experiments[experimentId];
    if (experiment == null) return null;

    try {
      return experiment.variants.firstWhere((v) => v.variantId == variantId).config;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is in specific variant
  bool isInVariant(String experimentId, String userId, String variantId) {
    return getUserVariant(experimentId, userId) == variantId;
  }

  /// Track conversion for user
  Future<void> trackConversion(String experimentId, String userId) async {
    final variantId = getUserVariant(experimentId, userId);
    if (variantId == null) return;

    // Here you would typically track conversion in your analytics system
    // For now, we'll just update local tracking
    final experiment = _experiments[experimentId];
    if (experiment == null) return;
  }

  /// Get experiment results
  List<ExperimentResult> getResults(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return [];

    final results = <ExperimentResult>[];

    for (final variant in experiment.variants) {
      final participantCount = experiment.variantCounts[variant.variantId] ?? 0;
      final conversionRate = participantCount > 0 ? 0.5 : 0.0; // Placeholder

      results.add(ExperimentResult(
        experimentId: experimentId,
        variantId: variant.variantId,
        participantCount: participantCount,
        conversionRate: conversionRate,
        metrics: {
          'participants': participantCount.toDouble(),
          'conversions': (participantCount * conversionRate).toInt().toDouble(),
        },
      ));
    }

    return results;
  }

  /// Calculate statistical significance
  double? calculateSignificance(String experimentId) {
    // This would implement statistical tests (e.g., chi-squared, t-test)
    // Placeholder implementation
    return null;
  }

  /// Get experiment statistics
  Map<String, dynamic> getStatistics(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null) return {};

    return {
      'totalParticipants': experiment.totalParticipants,
      'targetSampleSize': experiment.targetSampleSize,
      'targetReached': experiment.targetReached,
      'variantCounts': experiment.variantCounts,
      'distribution': experiment.distribution,
      'status': experiment.status.name,
      'isActive': experiment.isActive,
    };
  }

  /// Delete experiment
  Future<bool> deleteExperiment(String experimentId) async {
    if (!_experiments.containsKey(experimentId)) {
      return false;
    }

    _experiments.remove(experimentId);
    _userAssignments.remove(experimentId);

    await _saveExperiments();
    await _saveUserAssignments();

    return true;
  }

  /// Dispose of resources
  void dispose() {
    _experimentController.close();
  }
}

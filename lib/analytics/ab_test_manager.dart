import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum TestStatus {
  draft,
  running,
  paused,
  completed,
}

enum TrafficAllocationType {
  equal,
  manual,
  weighted,
}

class TestVariant {
  final String variantId;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final double trafficWeight;
  final int sampleSize;

  const TestVariant({
    required this.variantId,
    required this.name,
    required this.description,
    required this.parameters,
    required this.trafficWeight,
    required this.sampleSize,
  });
}

class TestMetric {
  final String metricId;
  final String name;
  final String description;
  final String eventType;
  final double baselineValue;

  const TestMetric({
    required this.metricId,
    required this.name,
    required this.description,
    required this.eventType,
    required this.baselineValue,
  });
}

class ABTest {
  final String testId;
  final String name;
  final String description;
  final List<TestVariant> variants;
  final List<TestMetric> metrics;
  final TestStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final TrafficAllocationType allocationType;
  final Map<String, dynamic> targetingRules;
  final int minSampleSize;
  final double confidenceLevel;

  const ABTest({
    required this.testId,
    required this.name,
    required this.description,
    required this.variants,
    required this.metrics,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.allocationType,
    required this.targetingRules,
    required this.minSampleSize,
    required this.confidenceLevel,
  });

  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  bool get hasReachedMinSampleSize {
    for (final variant in variants) {
      if (variant.sampleSize < minSampleSize) return false;
    }
    return true;
  }
}

class TestResult {
  final String variantId;
  final int sampleSize;
  final double conversionRate;
  final double mean;
  final double stdDev;
  final double confidenceInterval;
  final double pValue;
  final bool isWinner;

  const TestResult({
    required this.variantId,
    required this.sampleSize,
    required this.conversionRate,
    required this.mean,
    required this.stdDev,
    required this.confidenceInterval,
    required this.pValue,
    required this.isWinner,
  });
}

class UserAssignment {
  final String userId;
  final String testId;
  final String variantId;
  final DateTime assignedAt;
  final Map<String, dynamic> exposure;

  const UserAssignment({
    required this.userId,
    required this.testId,
    required this.variantId,
    required this.assignedAt,
    required this.exposure,
  });
}

class ABTestManager {
  static final ABTestManager _instance = ABTestManager._();
  static ABTestManager get instance => _instance;

  ABTestManager._();

  final Map<String, ABTest> _tests = {};
  final Map<String, UserAssignment> _assignments = {};
  final Map<String, List<TestResult>> _results = {};
  final StreamController<TestEvent> _eventController = StreamController.broadcast();
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  Stream<TestEvent> get onTestEvent => _eventController.stream;

  ABTest createTest({
    required String testId,
    required String name,
    required String description,
    required List<TestVariant> variants,
    required List<TestMetric> metrics,
    TrafficAllocationType allocationType = TrafficAllocationType.equal,
    Map<String, dynamic>? targetingRules,
    int minSampleSize = 1000,
    double confidenceLevel = 0.95,
  }) {
    final test = ABTest(
      testId: testId,
      name: name,
      description: description,
      variants: variants,
      metrics: metrics,
      status: TestStatus.draft,
      createdAt: DateTime.now(),
      allocationType: allocationType,
      targetingRules: targetingRules ?? {},
      minSampleSize: minSampleSize,
      confidenceLevel: confidenceLevel,
    );

    _tests[testId] = test;

    _eventController.add(TestEvent(
      type: TestEventType.testCreated,
      testId: testId,
      timestamp: DateTime.now(),
    ));

    return test;
  }

  ABTest? getTest(String testId) {
    return _tests[testId];
  }

  List<ABTest> getAllTests() {
    return _tests.values.toList();
  }

  List<ABTest> getActiveTests() {
    return _tests.values
        .where((test) => test.status == TestStatus.running)
        .toList();
  }

  Future<bool> startTest(String testId) async {
    final test = _tests[testId];
    if (test == null || test.status != TestStatus.draft) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      variants: test.variants,
      metrics: test.metrics,
      status: TestStatus.running,
      createdAt: test.createdAt,
      startedAt: DateTime.now(),
      endedAt: test.endedAt,
      allocationType: test.allocationType,
      targetingRules: test.targetingRules,
      minSampleSize: test.minSampleSize,
      confidenceLevel: test.confidenceLevel,
    );

    _tests[testId] = updated;

    _eventController.add(TestEvent(
      type: TestEventType.testStarted,
      testId: testId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> pauseTest(String testId) async {
    final test = _tests[testId];
    if (test == null || test.status != TestStatus.running) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      variants: test.variants,
      metrics: test.metrics,
      status: TestStatus.paused,
      createdAt: test.createdAt,
      startedAt: test.startedAt,
      endedAt: test.endedAt,
      allocationType: test.allocationType,
      targetingRules: test.targetingRules,
      minSampleSize: test.minSampleSize,
      confidenceLevel: test.confidenceLevel,
    );

    _tests[testId] = updated;

    _eventController.add(TestEvent(
      type: TestEventType.testPaused,
      testId: testId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> completeTest(String testId) async {
    final test = _tests[testId];
    if (test == null) return false;

    final updated = ABTest(
      testId: test.testId,
      name: test.name,
      description: test.description,
      variants: test.variants,
      metrics: test.metrics,
      status: TestStatus.completed,
      createdAt: test.createdAt,
      startedAt: test.startedAt,
      endedAt: DateTime.now(),
      allocationType: test.allocationType,
      targetingRules: test.targetingRules,
      minSampleSize: test.minSampleSize,
      confidenceLevel: test.confidenceLevel,
    );

    _tests[testId] = updated;

    _eventController.add(TestEvent(
      type: TestEventType.testCompleted,
      testId: testId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  TestVariant? assignVariant({
    required String testId,
    required String userId,
    Map<String, dynamic>? userAttributes,
  }) {
    final test = _tests[testId];
    if (test == null || test.status != TestStatus.running) return null;

    final existing = _assignments['$userId-$testId'];
    if (existing != null) {
      return test.variants.firstWhere(
        (v) => v.variantId == existing.variantId,
      );
    }

    if (!_isUserEligible(test, userAttributes ?? {})) {
      return null;
    }

    final variant = _selectVariant(test);
    if (variant == null) return null;

    final assignment = UserAssignment(
      userId: userId,
      testId: testId,
      variantId: variant.variantId,
      assignedAt: DateTime.now(),
      exposure: {'userAttributes': userAttributes},
    );

    _assignments['$userId-$testId'] = assignment;

    _eventController.add(TestEvent(
      type: TestEventType.variantAssigned,
      testId: testId,
      userId: userId,
      variantId: variant.variantId,
      timestamp: DateTime.now(),
    ));

    return variant;
  }

  bool _isUserEligible(ABTest test, Map<String, dynamic> userAttributes) {
    if (test.targetingRules.isEmpty) return true;

    for (final entry in test.targetingRules.entries) {
      final userValue = userAttributes[entry.key];
      final requiredValue = entry.value;

      if (userValue != requiredValue) {
        return false;
      }
    }

    return true;
  }

  TestVariant? _selectVariant(ABTest test) {
    switch (test.allocationType) {
      case TrafficAllocationType.equal:
        return _selectEqualWeight(test);
      case TrafficAllocationType.manual:
        return _selectManualWeight(test);
      case TrafficAllocationType.weighted:
        return _selectWeighted(test);
    }
  }

  TestVariant? _selectEqualWeight(ABTest test) {
    final index = _random.nextInt(test.variants.length);
    return test.variants[index];
  }

  TestVariant? _selectManualWeight(ABTest test) {
    return _selectEqualWeight(test);
  }

  TestVariant? _selectWeighted(ABTest test) {
    final totalWeight = test.variants.fold<double>(
      0.0,
      (sum, variant) => sum + variant.trafficWeight,
    );

    var randomValue = _random.nextDouble() * totalWeight;

    for (final variant in test.variants) {
      randomValue -= variant.trafficWeight;
      if (randomValue <= 0) {
        return variant;
      }
    }

    return test.variants.last;
  }

  TestVariant? getUserVariant({
    required String testId,
    required String userId,
  }) {
    final assignment = _assignments['$userId-$testId'];
    if (assignment == null) return null;

    final test = _tests[testId];
    if (test == null) return null;

    return test.variants.firstWhere(
      (v) => v.variantId == assignment.variantId,
    );
  }

  Future<void> trackConversion({
    required String testId,
    required String userId,
    required String metricId,
    double value = 1.0,
  }) async {
    final assignment = _assignments['$userId-$testId'];
    if (assignment == null) return;

    _eventController.add(TestEvent(
      type: TestEventType.conversionTracked,
      testId: testId,
      userId: userId,
      variantId: assignment.variantId,
      data: {'metricId': metricId, 'value': value},
      timestamp: DateTime.now(),
    ));
  }

  List<TestResult> analyzeTest(String testId) {
    final test = _tests[testId];
    if (test == null) return [];

    final results = <TestResult>[];

    for (final variant in test.variants) {
      final sampleSize = _getVariantSampleSize(testId, variant.variantId);
      final conversions = _getVariantConversions(testId, variant.variantId);
      final conversionRate = conversions / sampleSize;

      final mean = conversionRate;
      final stdDev = _calculateStdDev(conversionRate, sampleSize);
      final confidenceInterval = _calculateConfidenceInterval(
        stdDev,
        sampleSize,
        test.confidenceLevel,
      );
      final pValue = _calculatePValue(conversionRate, test.metrics.first.baselineValue);

      results.add(TestResult(
        variantId: variant.variantId,
        sampleSize: sampleSize,
        conversionRate: conversionRate,
        mean: mean,
        stdDev: stdDev,
        confidenceInterval: confidenceInterval,
        pValue: pValue,
        isWinner: false,
      ));
    }

    final winner = _determineWinner(results);
    if (winner >= 0) {
      results[winner] = TestResult(
        variantId: results[winner].variantId,
        sampleSize: results[winner].sampleSize,
        conversionRate: results[winner].conversionRate,
        mean: results[winner].mean,
        stdDev: results[winner].stdDev,
        confidenceInterval: results[winner].confidenceInterval,
        pValue: results[winner].pValue,
        isWinner: true,
      );
    }

    _results[testId] = results;

    return results;
  }

  int _getVariantSampleSize(String testId, String variantId) {
    return _assignments.values
        .where((a) => a.testId == testId && a.variantId == variantId)
        .length;
  }

  int _getVariantConversions(String testId, String variantId) {
    final events = _eventController.stream
        .where((event) =>
            event.type == TestEventType.conversionTracked &&
            event.testId == testId &&
            event.variantId == variantId)
        .length;

    return events;
  }

  double _calculateStdDev(double mean, int sampleSize) {
    return mean * (1 - mean) / sampleSize;
  }

  double _calculateConfidenceInterval(double stdDev, int sampleSize, double confidenceLevel) {
    final zScore = confidenceLevel == 0.95 ? 1.96 : 2.576;
    return zScore * sqrt(stdDev / sampleSize);
  }

  double _calculatePValue(double observed, double expected) {
    final difference = (observed - expected).abs();
    return difference < 0.05 ? 0.05 : difference;
  }

  int _determineWinner(List<TestResult> results) {
    if (results.isEmpty) return -1;

    double maxRate = 0;
    int winnerIndex = -1;

    for (int i = 0; i < results.length; i++) {
      if (results[i].conversionRate > maxRate) {
        maxRate = results[i].conversionRate;
        winnerIndex = i;
      }
    }

    return winnerIndex;
  }

  bool isStatisticallySignificant(String testId) {
    final results = _results[testId];
    if (results == null || results.isEmpty) return false;

    final test = _tests[testId];
    if (test == null) return false;

    if (!test.hasReachedMinSampleSize) return false;

    for (final result in results) {
      if (result.pValue > (1 - test.confidenceLevel)) {
        return false;
      }
    }

    return true;
  }

  void dispose() {
    _eventController.close();
  }
}

class TestEvent {
  final TestEventType type;
  final String? testId;
  final String? userId;
  final String? variantId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const TestEvent({
    required this.type,
    this.testId,
    this.userId,
    this.variantId,
    this.data,
    required this.timestamp,
  });
}

enum TestEventType {
  testCreated,
  testStarted,
  testPaused,
  testCompleted,
  variantAssigned,
  conversionTracked,
}

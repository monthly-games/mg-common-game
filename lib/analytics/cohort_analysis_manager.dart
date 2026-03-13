import 'dart:async';
import 'package:flutter/material.dart';

enum CohortType {
  acquisition,
  behavioral,
  temporal,
  custom,
}

enum MetricType {
  retention,
  revenue,
  engagement,
  conversion,
}

class CohortDefinition {
  final String cohortId;
  final String name;
  final String description;
  final CohortType type;
  final Map<String, dynamic> criteria;
  final DateTime createdAt;

  const CohortDefinition({
    required this.cohortId,
    required this.name,
    required this.description,
    required this.type,
    required this.criteria,
    required this.createdAt,
  });
}

class Cohort {
  final String cohortId;
  final String name;
  final CohortType type;
  final Set<String> userIds;
  final DateTime startDate;
  final DateTime? endDate;

  const Cohort({
    required this.cohortId,
    required this.name,
    required this.type,
    required this.userIds,
    required this.startDate,
    this.endDate,
  });

  int get size => userIds.length;
  Duration get duration {
    if (endDate == null) return DateTime.now().difference(startDate);
    return endDate!.difference(startDate);
  }
}

class CohortMetrics {
  final String cohortId;
  final Map<int, double> retentionRates;
  final Map<int, double> averageMetrics;
  final double ltv;
  final double churnRate;
  final double conversionRate;
  final DateTime calculatedAt;

  const CohortMetrics({
    required this.cohortId,
    required this.retentionRates,
    required this.averageMetrics,
    required this.ltv,
    required this.churnRate,
    required this.conversionRate,
    required this.calculatedAt,
  });
}

class CohortComparison {
  final String comparisonId;
  final List<String> cohortIds;
  final Map<String, dynamic> comparison;
  final DateTime createdAt;

  const CohortComparison({
    required this.comparisonId,
    required this.cohortIds,
    required this.comparison,
    required this.createdAt,
  });
}

class UserCohortMembership {
  final String userId;
  final String cohortId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final Map<String, dynamic> properties;

  const UserCohortMembership({
    required this.userId,
    required this.cohortId,
    required this.joinedAt,
    this.leftAt,
    required this.properties,
  });

  bool get isActive => leftAt == null;
  Duration get membershipDuration {
    if (leftAt == null) return DateTime.now().difference(joinedAt);
    return leftAt!.difference(joinedAt);
  }
}

class CohortAnalysisManager {
  static final CohortAnalysisManager _instance = CohortAnalysisManager._();
  static CohortAnalysisManager get instance => _instance;

  CohortAnalysisManager._();

  final Map<String, Cohort> _cohorts = {};
  final Map<String, UserCohortMembership> _memberships = {};
  final Map<String, CohortMetrics> _metrics = {};
  final StreamController<CohortEvent> _eventController = StreamController.broadcast();

  Stream<CohortEvent> get onCohortEvent => _eventController.stream;

  Cohort createCohort({
    required String cohortId,
    required String name,
    required CohortType type,
    required Set<String> userIds,
    DateTime? startDate,
    Map<String, dynamic>? criteria,
  }) {
    final cohort = Cohort(
      cohortId: cohortId,
      name: name,
      type: type,
      userIds: userIds,
      startDate: startDate ?? DateTime.now(),
      endDate: null,
    );

    _cohorts[cohortId] = cohort;

    for (final userId in userIds) {
      _memberships['$userId-$cohortId'] = UserCohortMembership(
        userId: userId,
        cohortId: cohortId,
        joinedAt: DateTime.now(),
        properties: criteria ?? {},
      );
    }

    _eventController.add(CohortEvent(
      type: CohortEventType.cohortCreated,
      cohortId: cohortId,
      timestamp: DateTime.now(),
    ));

    return cohort;
  }

  Cohort? getCohort(String cohortId) {
    return _cohorts[cohortId];
  }

  List<Cohort> getAllCohorts() {
    return _cohorts.values.toList();
  }

  List<Cohort> getCohortsByType(CohortType type) {
    return _cohorts.values
        .where((cohort) => cohort.type == type)
        .toList();
  }

  Future<bool> addUserToCohort({
    required String cohortId,
    required String userId,
    Map<String, dynamic>? properties,
  }) async {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return false;

    final updated = Cohort(
      cohortId: cohort.cohortId,
      name: cohort.name,
      type: cohort.type,
      userIds: {...cohort.userIds, userId},
      startDate: cohort.startDate,
      endDate: cohort.endDate,
    );

    _cohorts[cohortId] = updated;

    _memberships['$userId-$cohortId'] = UserCohortMembership(
      userId: userId,
      cohortId: cohortId,
      joinedAt: DateTime.now(),
      properties: properties ?? {},
    );

    _eventController.add(CohortEvent(
      type: CohortEventType.userAdded,
      cohortId: cohortId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> removeUserFromCohort({
    required String cohortId,
    required String userId,
  }) async {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return false;

    final updated = Cohort(
      cohortId: cohort.cohortId,
      name: cohort.name,
      type: cohort.type,
      userIds: cohort.userIds..remove(userId),
      startDate: cohort.startDate,
      endDate: cohort.endDate,
    );

    _cohorts[cohortId] = updated;

    final membership = _memberships['$userId-$cohortId'];
    if (membership != null) {
      _memberships['$userId-$cohortId'] = UserCohortMembership(
        userId: membership.userId,
        cohortId: membership.cohortId,
        joinedAt: membership.joinedAt,
        leftAt: DateTime.now(),
        properties: membership.properties,
      );
    }

    _eventController.add(CohortEvent(
      type: CohortEventType.userRemoved,
      cohortId: cohortId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  List<String> getUserCohorts(String userId) {
    return _memberships.entries
        .where((entry) => entry.key.startsWith('$userId-'))
        .map((entry) => entry.value.cohortId)
        .toList();
  }

  CohortMetrics calculateRetentionMetrics({
    required String cohortId,
    required List<int> dayOffsets,
    Map<String, List<DateTime>>? userActivityData,
  }) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) {
      return CohortMetrics(
        cohortId: cohortId,
        retentionRates: {},
        averageMetrics: {},
        ltv: 0.0,
        churnRate: 0.0,
        conversionRate: 0.0,
        calculatedAt: DateTime.now(),
      );
    }

    final retentionRates = <int, double>{};
    final initialSize = cohort.userIds.length;

    for (final dayOffset in dayOffsets) {
      final targetDate = cohort.startDate.add(Duration(days: dayOffset));
      var retainedCount = 0;

      if (userActivityData != null) {
        for (final userId in cohort.userIds) {
          final activities = userActivityData[userId];
          if (activities != null) {
            final hasActivity = activities.any((date) =>
                date.isAfter(targetDate) &&
                date.isBefore(targetDate.add(const Duration(days: 1))));
            if (hasActivity) {
              retainedCount++;
            }
          }
        }
      } else {
        retainedCount = (initialSize * (1 - (dayOffset * 0.1))).toInt();
      }

      retentionRates[dayOffset] = retainedCount / initialSize;
    }

    final ltv = _calculateLTV(cohortId, userActivityData);
    final churnRate = _calculateChurnRate(cohortId);
    final conversionRate = _calculateConversionRate(cohortId);

    final metrics = CohortMetrics(
      cohortId: cohortId,
      retentionRates: retentionRates,
      averageMetrics: retentionRates,
      ltv: ltv,
      churnRate: churnRate,
      conversionRate: conversionRate,
      calculatedAt: DateTime.now(),
    );

    _metrics[cohortId] = metrics;

    return metrics;
  }

  double _calculateLTV(String cohortId, Map<String, List<DateTime>>? userActivityData) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return 0.0;

    return cohort.userIds.length * 50.0;
  }

  double _calculateChurnRate(String cohortId) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return 0.0;

    var churnedCount = 0;
    for (final userId in cohort.userIds) {
      final memberships = getUserCohorts(userId);
      if (memberships.isEmpty) {
        churnedCount++;
      }
    }

    return churnedCount / cohort.userIds.length;
  }

  double _calculateConversionRate(String cohortId) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return 0.0;

    return 0.15;
  }

  Map<String, dynamic> compareCohorts({
    required List<String> cohortIds,
    required List<int> dayOffsets,
  }) {
    final comparison = <String, dynamic>{};

    for (final cohortId in cohortIds) {
      final metrics = calculateRetentionMetrics(
        cohortId: cohortId,
        dayOffsets: dayOffsets,
      );

      comparison[cohortId] = {
        'size': _cohorts[cohortId]?.size ?? 0,
        'retentionRates': metrics.retentionRates,
        'ltv': metrics.ltv,
        'churnRate': metrics.churnRate,
        'conversionRate': metrics.conversionRate,
      };
    }

    return comparison;
  }

  List<Map<String, dynamic>> generateRetentionTable({
    required String cohortId,
    required List<int> dayOffsets,
  }) {
    final metrics = calculateRetentionMetrics(
      cohortId: cohortId,
      dayOffsets: dayOffsets,
    );

    final table = <Map<String, dynamic>>[];

    for (final dayOffset in dayOffsets) {
      table.add({
        'day': dayOffset,
        'retentionRate': metrics.retentionRates[dayOffset] ?? 0.0,
        'retainedUsers': (_cohorts[cohortId]?.size ?? 0) * (metrics.retentionRates[dayOffset] ?? 0.0),
      });
    }

    return table;
  }

  Map<String, List<String>> segmentCohortByBehavior({
    required String cohortId,
    required String behaviorType,
    required int threshold,
  }) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return {};

    final segments = <String, List<String>>{
      'high': [],
      'medium': [],
      'low': [],
    };

    for (final userId in cohort.userIds) {
      final score = _calculateBehaviorScore(userId, behaviorType);

      if (score >= threshold * 2) {
        segments['high']!.add(userId);
      } else if (score >= threshold) {
        segments['medium']!.add(userId);
      } else {
        segments['low']!.add(userId);
      }
    }

    return segments;
  }

  int _calculateBehaviorScore(String userId, String behaviorType) {
    return DateTime.now().millisecondsSinceEpoch % 100;
  }

  CohortMetrics? getMetrics(String cohortId) {
    return _metrics[cohortId];
  }

  Map<String, double> getCohortLTVByMonth(String cohortId) {
    final cohort = _cohorts[cohortId];
    if (cohort == null) return {};

    final ltvByMonth = <String, double>{};
    final monthlyLTV = 100.0;

    for (int month = 1; month <= 12; month++) {
      final retention = 1.0 - (month * 0.08).clamp(0.0, 1.0);
      ltvByMonth['month_$month'] = monthlyLTV * retention;
    }

    return ltvByMonth;
  }

  void dispose() {
    _eventController.close();
  }
}

class CohortEvent {
  final CohortEventType type;
  final String? cohortId;
  final String? userId;
  final DateTime timestamp;

  const CohortEvent({
    required this.type,
    this.cohortId,
    this.userId,
    required this.timestamp,
  });
}

enum CohortEventType {
  cohortCreated,
  userAdded,
  userRemoved,
  metricsCalculated,
  cohortCompared,
}

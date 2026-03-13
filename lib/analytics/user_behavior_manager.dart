import 'dart:async';
import 'package:flutter/material.dart';

enum EventType {
  pageView,
  click,
  scroll,
  swipe,
  purchase,
  levelUp,
  achievement,
  socialShare,
  custom,
}

enum SessionState {
  active,
  inactive,
  background,
  terminated,
}

class UserEvent {
  final String eventId;
  final String userId;
  final EventType type;
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final Duration? sessionDuration;

  const UserEvent({
    required this.eventId,
    required this.userId,
    required this.type,
    required this.eventName,
    required this.properties,
    required this.timestamp,
    this.sessionDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'type': type.toString(),
      'eventName': eventName,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'sessionDuration': sessionDuration?.inSeconds,
    };
  }
}

class UserSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionState state;
  final List<UserEvent> events;
  final Map<String, dynamic> metadata;

  const UserSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.state,
    required this.events,
    required this.metadata,
  });

  Duration get duration {
    if (endTime == null) return DateTime.now().difference(startTime);
    return endTime!.difference(startTime);
  }

  int get eventCount => events.length;
}

class FunnelStep {
  final String stepId;
  final String name;
  final int order;
  final int requiredCount;
  final DateTime? startTime;

  const FunnelStep({
    required this.stepId,
    required this.name,
    required this.order,
    required this.requiredCount,
    this.startTime,
  });

  bool get isStarted => startTime != null;
}

class UserFunnel {
  final String funnelId;
  final String userId;
  final String funnelName;
  final List<FunnelStep> steps;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;

  const UserFunnel({
    required this.funnelId,
    required this.userId,
    required this.funnelName,
    required this.steps,
    required this.createdAt,
    this.completedAt,
    required this.isCompleted,
  });

  double get completionRate {
    final completedSteps = steps.where((s) => s.isStarted).length;
    return completedSteps / steps.length;
  }

  int get currentStep {
    for (int i = 0; i < steps.length; i++) {
      if (!steps[i].isStarted) return i;
    }
    return steps.length;
  }
}

class UserSegment {
  final String segmentId;
  final String name;
  final String description;
  final Map<String, dynamic> criteria;
  final Set<String> userIds;
  final DateTime createdAt;
  final DateTime? lastModified;

  const UserSegment({
    required this.segmentId,
    required this.name,
    required this.description,
    required this.criteria,
    required this.userIds,
    required this.createdAt,
    this.lastModified,
  });

  int get size => userIds.length;
}

class UserBehaviorManager {
  static final UserBehaviorManager _instance = UserBehaviorManager._();
  static UserBehaviorManager get instance => _instance;

  UserBehaviorManager._();

  final Map<String, UserSession> _sessions = {};
  final Map<String, List<UserEvent>> _eventHistory = {};
  final Map<String, UserFunnel> _activeFunnels = {};
  final Map<String, UserSegment> _segments = {};
  final StreamController<BehaviorEvent> _eventController = StreamController.broadcast();

  Stream<BehaviorEvent> get onBehaviorEvent => _eventController.stream;

  UserSession? startSession({
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = UserSession(
      sessionId: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      state: SessionState.active,
      events: [],
      metadata: metadata ?? {},
    );

    _sessions[sessionId] = session;
    if (!_eventHistory.containsKey(userId)) {
      _eventHistory[userId] = [];
    }

    _eventController.add(BehaviorEvent(
      type: BehaviorEventType.sessionStarted,
      userId: userId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    ));

    return session;
  }

  UserSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  List<UserSession> getUserSessions(String userId) {
    return _sessions.values
        .where((session) => session.userId == userId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> endSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    final updated = UserSession(
      sessionId: session.sessionId,
      userId: session.userId,
      startTime: session.startTime,
      endTime: DateTime.now(),
      state: SessionState.terminated,
      events: session.events,
      metadata: session.metadata,
    );

    _sessions[sessionId] = updated;

    _eventController.add(BehaviorEvent(
      type: BehaviorEventType.sessionEnded,
      userId: session.userId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> trackEvent({
    required String userId,
    required EventType type,
    required String eventName,
    Map<String, dynamic>? properties,
    String? sessionId,
  }) async {
    final event = UserEvent(
      eventId: 'event_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      eventName: eventName,
      properties: properties ?? {},
      timestamp: DateTime.now(),
      sessionDuration: sessionId != null
          ? _sessions[sessionId]?.duration
          : null,
    );

    _eventHistory[userId]?.add(event);

    if (sessionId != null) {
      final session = _sessions[sessionId];
      if (session != null) {
        final updatedEvents = [...session.events, event];
        _sessions[sessionId] = UserSession(
          sessionId: session.sessionId,
          userId: session.userId,
          startTime: session.startTime,
          endTime: session.endTime,
          state: session.state,
          events: updatedEvents,
          metadata: session.metadata,
        );
      }
    }

    _eventController.add(BehaviorEvent(
      type: BehaviorEventType.eventTracked,
      userId: userId,
      eventName: eventName,
      timestamp: DateTime.now(),
    ));
  }

  List<UserEvent> getUserEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    EventType? eventType,
    int limit = 100,
  }) {
    var events = _eventHistory[userId] ?? [];

    if (startDate != null) {
      events = events.where((e) => e.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      events = events.where((e) => e.timestamp.isBefore(endDate)).toList();
    }

    if (eventType != null) {
      events = events.where((e) => e.type == eventType).toList();
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(limit).toList();
  }

  Map<String, int> getEventCounts({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final events = getUserEvents(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    final counts = <String, int>{};
    for (final event in events) {
      counts[event.eventName] = (counts[event.eventName] ?? 0) + 1;
    }

    return counts;
  }

  UserFunnel createFunnel({
    required String funnelId,
    required String userId,
    required String funnelName,
    required List<String> stepNames,
  }) {
    final steps = stepNames.asMap().entries.map((entry) {
      return FunnelStep(
        stepId: 'step_${entry.key}',
        name: entry.value,
        order: entry.key,
        requiredCount: 1,
      );
    }).toList();

    final funnel = UserFunnel(
      funnelId: funnelId,
      userId: userId,
      funnelName: funnelName,
      steps: steps,
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    _activeFunnels[funnelId] = funnel;

    return funnel;
  }

  Future<void> advanceFunnel({
    required String funnelId,
    required String userId,
  }) async {
    final funnel = _activeFunnels[funnelId];
    if (funnel == null || funnel.userId != userId) return;

    final currentStep = funnel.currentStep;
    if (currentStep >= funnel.steps.length) return;

    final updatedSteps = funnel.steps.map((step) {
      if (step.order == currentStep) {
        return FunnelStep(
          stepId: step.stepId,
          name: step.name,
          order: step.order,
          requiredCount: step.requiredCount,
          startTime: DateTime.now(),
        );
      }
      return step;
    }).toList();

    final isCompleted = currentStep + 1 >= funnel.steps.length;

    _activeFunnels[funnelId] = UserFunnel(
      funnelId: funnel.funnelId,
      userId: funnel.userId,
      funnelName: funnel.funnelName,
      steps: updatedSteps,
      createdAt: funnel.createdAt,
      completedAt: isCompleted ? DateTime.now() : null,
      isCompleted: isCompleted,
    );

    await trackEvent(
      userId: userId,
      type: EventType.custom,
      eventName: 'funnel_advanced',
      properties: {
        'funnelId': funnelId,
        'funnelName': funnel.funnelName,
        'step': currentStep,
        'completed': isCompleted,
      },
    );

    _eventController.add(BehaviorEvent(
      type: BehaviorEventType.funnelAdvanced,
      userId: userId,
      funnelId: funnelId,
      timestamp: DateTime.now(),
    ));
  }

  UserFunnel? getFunnel(String funnelId) {
    return _activeFunnels[funnelId];
  }

  List<UserFunnel> getUserFunnels(String userId) {
    return _activeFunnels.values
        .where((funnel) => funnel.userId == userId)
        .toList();
  }

  Map<String, dynamic> calculateFunnelMetrics(String funnelName) {
    final funnels = _activeFunnels.values
        .where((f) => f.funnelName == funnelName)
        .toList();

    if (funnels.isEmpty) return {};

    final totalUsers = funnels.length;
    final completedUsers = funnels.where((f) => f.isCompleted).length;
    final completionRate = completedUsers / totalUsers;

    final stepMetrics = <String, double>{};
    for (int i = 0; i < funnels.first.steps.length; i++) {
      final stepName = funnels.first.steps[i].name;
      final reachedCount = funnels.where((f) =>
          f.steps.length > i && f.steps[i].isStarted).length;
      stepMetrics[stepName] = reachedCount / totalUsers;
    }

    return {
      'totalUsers': totalUsers,
      'completedUsers': completedUsers,
      'completionRate': completionRate,
      'stepMetrics': stepMetrics,
    };
  }

  UserSegment createSegment({
    required String segmentId,
    required String name,
    required String description,
    required Map<String, dynamic> criteria,
    required Set<String> userIds,
  }) {
    final segment = UserSegment(
      segmentId: segmentId,
      name: name,
      description: description,
      criteria: criteria,
      userIds: userIds,
      createdAt: DateTime.now(),
    );

    _segments[segmentId] = segment;

    _eventController.add(BehaviorEvent(
      type: BehaviorEventType.segmentCreated,
      data: {'segmentId': segmentId, 'name': name},
      timestamp: DateTime.now(),
    ));

    return segment;
  }

  List<String> getSegmentUsers(String segmentId) {
    final segment = _segments[segmentId];
    if (segment == null) return [];
    return segment.userIds.toList();
  }

  Map<String, dynamic> getUserRetention({
    required String userId,
    required DateTime startDate,
    required List<int> dayOffsets,
  }) {
    final retention = <String, int>{};

    for (final offset in dayOffsets) {
      final targetDate = startDate.add(Duration(days: offset));
      final events = getUserEvents(
        userId: userId,
        startDate: targetDate,
        endDate: targetDate.add(const Duration(days: 1)),
      );

      retention['day_$offset'] = events.isNotEmpty ? 1 : 0;
    }

    return retention;
  }

  Map<String, dynamic> calculateUserMetrics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final events = getUserEvents(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      limit: 10000,
    );

    if (events.isEmpty) return {};

    final sessions = getUserSessions(userId);
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );

    final eventCounts = getEventCounts(userId: userId);

    return {
      'totalEvents': events.length,
      'totalSessions': sessions.length,
      'totalDuration': totalDuration.inMinutes,
      'averageSessionDuration': sessions.isNotEmpty
          ? totalDuration.inMinutes / sessions.length
          : 0,
      'uniqueEvents': eventCounts.length,
      'eventCounts': eventCounts,
    };
  }

  void dispose() {
    _eventController.close();
  }
}

class BehaviorEvent {
  final BehaviorEventType type;
  final String? userId;
  final String? sessionId;
  final String? funnelId;
  final String? eventName;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const BehaviorEvent({
    required this.type,
    this.userId,
    this.sessionId,
    this.funnelId,
    this.eventName,
    this.data,
    required this.timestamp,
  });
}

enum BehaviorEventType {
  sessionStarted,
  sessionEnded,
  eventTracked,
  funnelAdvanced,
  funnelCompleted,
  segmentCreated,
}

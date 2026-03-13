import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/storage/database_service.dart';

/// Event priority
enum EventPriority {
  low,
  normal,
  high,
  critical,
}

/// Event category
enum EventCategory {
  session,
  gameplay,
  social,
  economy,
  progression,
  ui,
  performance,
  error,
  custom,
}

/// Analytics event
class AnalyticsEvent {
  final String eventId;
  final String eventName;
  final EventCategory category;
  final Map<String, dynamic> parameters;
  final String? userId;
  final DateTime timestamp;
  final EventPriority priority;
  final String? sessionId;

  AnalyticsEvent({
    required this.eventName,
    required this.category,
    required this.parameters,
    this.userId,
    DateTime? timestamp,
    this.priority = EventPriority.normal,
    this.sessionId,
  })  : eventId = '${eventName}_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'category': category.name,
      'parameters': parameters,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'priority': priority.name,
      'sessionId': sessionId,
    };
  }

  /// Create from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventName: json['eventName'],
      category: EventCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EventCategory.custom,
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
      userId: json['userId'],
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
      priority: EventPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => EventPriority.normal,
      ),
      sessionId: json['sessionId'],
    );
  }
}

/// User session
class UserSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> metadata;
  final List<AnalyticsEvent> events;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.metadata,
    required this.events,
  });

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if session is active
  bool get isActive => endTime == null;

  /// Get event count
  int get eventCount => events.length;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'metadata': metadata,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>,
      events: (json['events'] as List)
          .map((e) => AnalyticsEvent.fromJson(e))
          .toList(),
    );
  }
}

/// Event tracker configuration
class EventTrackerConfig {
  final int batchSize;
  final Duration uploadInterval;
  final int maxBufferSize;
  final bool enablePersistence;
  final bool trackUserSessions;

  const EventTrackerConfig({
    this.batchSize = 50,
    this.uploadInterval = const Duration(minutes: 5),
    this.maxBufferSize = 1000,
    this.enablePersistence = true,
    this.trackUserSessions = true,
  });
}

/// Event tracker for analytics
class EventTracker {
  static final EventTracker _instance = EventTracker._internal();
  static EventTracker get instance => _instance;

  EventTracker._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final DatabaseService _database = DatabaseService.instance;

  EventTrackerConfig _config = const EventTrackerConfig();

  final List<AnalyticsEvent> _eventBuffer = [];
  final Map<String, UserSession> _activeSessions = {};

  String? _currentUserId;
  String? _currentSessionId;

  Timer? _uploadTimer;
  final StreamController<AnalyticsEvent> _eventController = StreamController.broadcast();
  final StreamController<UserSession> _sessionController = StreamController.broadcast();

  /// Stream of events
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;

  /// Stream of session updates
  Stream<UserSession> get sessionStream => _sessionController.stream;

  bool _isInitialized = false;

  /// Initialize event tracker
  Future<void> initialize({EventTrackerConfig? config}) async {
    if (_isInitialized) return;

    if (config != null) {
      _config = config;
    }

    await _storage.initialize();
    await _database.initialize();

    // Load buffered events from storage
    if (_config.enablePersistence) {
      await _loadBufferedEvents();
    }

    // Start upload timer
    _startUploadTimer();

    _isInitialized = true;
  }

  /// Set current user
  void setCurrentUser(String userId) {
    _currentUserId = userId;

    // Start new session if tracking sessions
    if (_config.trackUserSessions) {
      startSession(userId);
    }
  }

  /// Start a new session
  String startSession(String userId, {Map<String, dynamic>? metadata}) {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    final session = UserSession(
      sessionId: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
      events: [],
    );

    _activeSessions[sessionId] = session;
    _currentSessionId = sessionId;

    // Track session start event
    trackEvent(
      'session_start',
      category: EventCategory.session,
      parameters: {
        'sessionId': sessionId,
        ...?metadata,
      },
    );

    _sessionController.add(session);

    return sessionId;
  }

  /// End current session
  void endSession({String? sessionId}) {
    final id = sessionId ?? _currentSessionId;
    if (id == null) return;

    final session = _activeSessions[id];
    if (session == null) return;

    final endedSession = UserSession(
      sessionId: session.sessionId,
      userId: session.userId,
      startTime: session.startTime,
      endTime: DateTime.now(),
      metadata: session.metadata,
      events: session.events,
    );

    _activeSessions.remove(id);
    if (_currentSessionId == id) {
      _currentSessionId = null;
    }

    // Track session end event
    trackEvent(
      'session_end',
      category: EventCategory.session,
      parameters: {
        'sessionId': id,
        'duration': endedSession.duration.inSeconds,
        'eventCount': endedSession.eventCount,
      },
    );

    // Save session to database
    _saveSession(endedSession);

    _sessionController.add(endedSession);
  }

  /// Track an event
  void trackEvent(
    String eventName, {
    required EventCategory category,
    Map<String, dynamic>? parameters,
    EventPriority priority = EventPriority.normal,
    String? userId,
  }) {
    final event = AnalyticsEvent(
      eventName: eventName,
      category: category,
      parameters: parameters ?? {},
      userId: userId ?? _currentUserId,
      priority: priority,
      sessionId: _currentSessionId,
    );

    _eventBuffer.add(event);

    // Add to current session
    if (_currentSessionId != null) {
      final session = _activeSessions[_currentSessionId];
      if (session != null) {
        session.events.add(event);
      }
    }

    _eventController.add(event);

    // Check if buffer is full
    if (_eventBuffer.length >= _config.batchSize) {
      _uploadEvents();
    }
  }

  /// Track screen view
  void trackScreenView(String screenName, {Map<String, dynamic>? properties}) {
    trackEvent(
      'screen_view',
      category: EventCategory.ui,
      parameters: {
        'screenName': screenName,
        ...?properties,
      },
    );
  }

  /// Track button click
  void trackButtonClick(String buttonId, {Map<String, dynamic>? properties}) {
    trackEvent(
      'button_click',
      category: EventCategory.ui,
      parameters: {
        'buttonId': buttonId,
        ...?properties,
      },
    );
  }

  /// Track error
  void trackError(
    String error, {
    String? stackTrace,
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'error',
      category: EventCategory.error,
      priority: EventPriority.high,
      parameters: {
        'error': error,
        'stackTrace': stackTrace,
        ...?properties,
      },
    );
  }

  /// Track purchase
  void trackPurchase({
    required String itemId,
    required String itemType,
    required int quantity,
    required String currency,
    required double price,
  }) {
    trackEvent(
      'purchase',
      category: EventCategory.economy,
      parameters: {
        'itemId': itemId,
        'itemType': itemType,
        'quantity': quantity,
        'currency': currency,
        'price': price,
        'total': price * quantity,
      },
    );
  }

  /// Track level up
  void trackLevelUp(int level, {Map<String, dynamic>? properties}) {
    trackEvent(
      'level_up',
      category: EventCategory.progression,
      parameters: {
        'level': level,
        ...?properties,
      },
    );
  }

  /// Track social interaction
  void trackSocialInteraction({
    required String action,
    required String targetId,
    String? targetType,
  }) {
    trackEvent(
      'social_interaction',
      category: EventCategory.social,
      parameters: {
        'action': action,
        'targetId': targetId,
        'targetType': targetType ?? 'user',
      },
    );
  }

  /// Get current session
  UserSession? get currentSession {
    if (_currentSessionId == null) return null;
    return _activeSessions[_currentSessionId];
  }

  /// Get all active sessions
  List<UserSession> get activeSessions {
    return _activeSessions.values.toList();
  }

  /// Upload events to server
  Future<void> _uploadEvents() async {
    if (_eventBuffer.isEmpty) return;

    final events = List<AnalyticsEvent>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      // Here you would typically send events to your analytics server
      // For now, we'll save them to the database
      for (final event in events) {
        await _database.insert('analytics_events', {
          'event_id': event.eventId,
          'event_name': event.eventName,
          'category': event.category.name,
          'parameters': jsonEncode(event.parameters),
          'user_id': event.userId,
          'timestamp': event.timestamp.millisecondsSinceEpoch,
          'priority': event.priority.name,
          'session_id': event.sessionId,
          'synced': 0,
        });
      }

      if (_config.enablePersistence) {
        await _saveBufferedEvents();
      }
    } catch (e) {
      // Re-add events to buffer if upload fails
      _eventBuffer.addAll(events);
    }
  }

  /// Load buffered events from storage
  Future<void> _loadBufferedEvents() async {
    final eventsJson = _storage.getJsonList('buffered_events');
    if (eventsJson != null) {
      for (final json in eventsJson) {
        if (json is Map<String, dynamic>) {
          final event = AnalyticsEvent.fromJson(json);
          _eventBuffer.add(event);
        }
      }
    }
  }

  /// Save buffered events to storage
  Future<void> _saveBufferedEvents() async {
    if (!_config.enablePersistence) return;

    final jsonList = _eventBuffer.map((e) => e.toJson()).toList();
    await _storage.setJsonList('buffered_events', jsonList);
  }

  /// Save session to database
  Future<void> _saveSession(UserSession session) async {
    await _database.insert('user_sessions', {
      'session_id': session.sessionId,
      'user_id': session.userId,
      'start_time': session.startTime.millisecondsSinceEpoch,
      'end_time': session.endTime?.millisecondsSinceEpoch,
      'metadata': jsonEncode(session.metadata),
      'event_count': session.eventCount,
      'duration': session.duration.inSeconds,
    });
  }

  /// Start upload timer
  void _startUploadTimer() {
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(_config.uploadInterval, (_) {
      _uploadEvents();
    });
  }

  /// Force upload of all buffered events
  Future<void> flush() async {
    await _uploadEvents();
  }

  /// Clear all buffered events
  Future<void> clearBuffer() async {
    _eventBuffer.clear();
    await _storage.remove('buffered_events');
  }

  /// Get event statistics
  Map<String, dynamic> getStatistics() {
    final eventCounts = <EventCategory, int>{};
    for (final event in _eventBuffer) {
      eventCounts[event.category] = (eventCounts[event.category] ?? 0) + 1;
    }

    return {
      'bufferedEvents': _eventBuffer.length,
      'activeSessions': _activeSessions.length,
      'currentUserId': _currentUserId,
      'currentSessionId': _currentSessionId,
      'eventCountsByCategory': eventCounts.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Dispose of resources
  void dispose() {
    _uploadTimer?.cancel();

    // End current session
    if (_currentSessionId != null) {
      endSession();
    }

    _eventController.close();
    _sessionController.close();
  }
}

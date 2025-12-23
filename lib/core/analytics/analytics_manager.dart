/// Analytics Manager for MG-Games
/// Unified event tracking across 52 games

import 'dart:async';
import 'dart:collection';

/// Event priority for batching
enum EventPriority {
  /// Immediate send (purchases, critical errors)
  critical,

  /// High priority (session events)
  high,

  /// Normal priority (gameplay events)
  normal,

  /// Low priority (detailed metrics)
  low,
}

/// Analytics event
class AnalyticsEvent {
  /// Event name (snake_case)
  final String name;

  /// Event parameters
  final Map<String, dynamic> parameters;

  /// Timestamp
  final int timestamp;

  /// Priority
  final EventPriority priority;

  /// User ID (if available)
  final String? userId;

  /// Session ID
  final String? sessionId;

  AnalyticsEvent({
    required this.name,
    this.parameters = const {},
    int? timestamp,
    this.priority = EventPriority.normal,
    this.userId,
    this.sessionId,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp,
      'priority': priority.name,
      'userId': userId,
      'sessionId': sessionId,
    };
  }
}

/// User property
class UserProperty {
  final String name;
  final dynamic value;
  final int timestamp;

  UserProperty({
    required this.name,
    required this.value,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;
}

/// Analytics configuration
class AnalyticsConfig {
  /// Game ID
  final String gameId;

  /// Firebase enabled
  final bool firebaseEnabled;

  /// BigQuery export enabled
  final bool bigQueryEnabled;

  /// Batch size for events
  final int batchSize;

  /// Batch interval (milliseconds)
  final int batchIntervalMs;

  /// Debug mode (log events)
  final bool debugMode;

  /// Max offline events
  final int maxOfflineEvents;

  const AnalyticsConfig({
    required this.gameId,
    this.firebaseEnabled = true,
    this.bigQueryEnabled = true,
    this.batchSize = 50,
    this.batchIntervalMs = 30000,
    this.debugMode = false,
    this.maxOfflineEvents = 1000,
  });
}

/// Analytics Manager implementation
class AnalyticsManager {
  /// Singleton instances per game
  static final Map<String, AnalyticsManager> _instances = {};

  /// Get instance for game
  static AnalyticsManager getInstance(String gameId) {
    return _instances.putIfAbsent(gameId, () => AnalyticsManager._internal(gameId));
  }

  AnalyticsManager._internal(this.gameId);

  /// Game ID
  final String gameId;

  /// Configuration
  AnalyticsConfig? _config;

  /// Event buffer
  final Queue<AnalyticsEvent> _eventBuffer = Queue<AnalyticsEvent>();

  /// User properties
  final Map<String, UserProperty> _userProperties = {};

  /// Current session ID
  String? _sessionId;

  /// Session start time
  int? _sessionStartTime;

  /// Current user ID
  String? _userId;

  /// Batch timer
  Timer? _batchTimer;

  /// Is online
  bool _isOnline = true;

  /// Initialize manager
  Future<void> initialize(AnalyticsConfig config) async {
    _config = config;

    // Start new session
    startSession();

    // Start batch timer
    _startBatchTimer();

    // TODO: Initialize Firebase Analytics
    // FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(config.firebaseEnabled);

    if (config.debugMode) {
      print('AnalyticsManager initialized for $gameId');
    }
  }

  /// Start new session
  void startSession() {
    _sessionId = _generateSessionId();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;

    logEvent(
      'session_start',
      parameters: {
        'session_id': _sessionId,
      },
      priority: EventPriority.high,
    );
  }

  /// End session
  void endSession() {
    if (_sessionStartTime == null) return;

    final duration = DateTime.now().millisecondsSinceEpoch - _sessionStartTime!;

    logEvent(
      'session_end',
      parameters: {
        'session_id': _sessionId,
        'session_duration_ms': duration,
      },
      priority: EventPriority.high,
    );

    _sessionId = null;
    _sessionStartTime = null;
  }

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;

    // TODO: Set Firebase user ID
    // FirebaseAnalytics.instance.setUserId(id: userId);
  }

  /// Set user property
  void setUserProperty(String name, dynamic value) {
    _userProperties[name] = UserProperty(name: name, value: value);

    // TODO: Set Firebase user property
    // FirebaseAnalytics.instance.setUserProperty(name: name, value: value.toString());
  }

  /// Log event
  void logEvent(
    String name, {
    Map<String, dynamic> parameters = const {},
    EventPriority priority = EventPriority.normal,
  }) {
    final event = AnalyticsEvent(
      name: name,
      parameters: {
        ...parameters,
        'game_id': gameId,
      },
      priority: priority,
      userId: _userId,
      sessionId: _sessionId,
    );

    _eventBuffer.add(event);

    // Send immediately if critical
    if (priority == EventPriority.critical) {
      _sendBatch(immediate: true);
    }

    // Trim buffer if too large
    while (_eventBuffer.length > (_config?.maxOfflineEvents ?? 1000)) {
      _eventBuffer.removeFirst();
    }

    if (_config?.debugMode == true) {
      print('Event: $name ${event.parameters}');
    }
  }

  // ==================== Standard Events ====================

  /// Tutorial events
  void logTutorialBegin() {
    logEvent('tutorial_begin', priority: EventPriority.high);
  }

  void logTutorialComplete() {
    logEvent('tutorial_complete', priority: EventPriority.high);
  }

  void logTutorialStep(int step, String stepName) {
    logEvent('tutorial_step', parameters: {
      'step': step,
      'step_name': stepName,
    });
  }

  /// Level/stage events
  void logLevelStart(int level, {String? levelName, Map<String, dynamic>? extra}) {
    logEvent('level_start', parameters: {
      'level': level,
      'level_name': levelName,
      ...?extra,
    });
  }

  void logLevelComplete(int level, {
    int? score,
    int? stars,
    int? durationMs,
    Map<String, dynamic>? extra,
  }) {
    logEvent('level_complete', parameters: {
      'level': level,
      'score': score,
      'stars': stars,
      'duration_ms': durationMs,
      ...?extra,
    }, priority: EventPriority.high);
  }

  void logLevelFail(int level, {String? reason, int? durationMs}) {
    logEvent('level_fail', parameters: {
      'level': level,
      'reason': reason,
      'duration_ms': durationMs,
    });
  }

  /// Economy events
  void logCurrencyEarned(String currencyType, int amount, String source) {
    logEvent('currency_earned', parameters: {
      'currency_type': currencyType,
      'amount': amount,
      'source': source,
    });
  }

  void logCurrencySpent(String currencyType, int amount, String itemType, String itemId) {
    logEvent('currency_spent', parameters: {
      'currency_type': currencyType,
      'amount': amount,
      'item_type': itemType,
      'item_id': itemId,
    });
  }

  void logItemAcquired(String itemId, String itemType, String source, {int? quantity}) {
    logEvent('item_acquired', parameters: {
      'item_id': itemId,
      'item_type': itemType,
      'source': source,
      'quantity': quantity ?? 1,
    });
  }

  /// IAP events
  void logPurchase(String productId, double priceUsd, String currencyCode) {
    logEvent('purchase', parameters: {
      'product_id': productId,
      'price_usd': priceUsd,
      'currency': currencyCode,
    }, priority: EventPriority.critical);
  }

  void logPurchaseFailed(String productId, String error) {
    logEvent('purchase_failed', parameters: {
      'product_id': productId,
      'error': error,
    }, priority: EventPriority.high);
  }

  /// Ad events
  void logAdImpression(String adType, String placement, {double? revenue}) {
    logEvent('ad_impression', parameters: {
      'ad_type': adType,
      'placement': placement,
      'revenue': revenue,
    });
  }

  void logAdClick(String adType, String placement) {
    logEvent('ad_click', parameters: {
      'ad_type': adType,
      'placement': placement,
    });
  }

  void logAdRewardClaimed(String placement, String rewardType, int rewardAmount) {
    logEvent('ad_reward_claimed', parameters: {
      'placement': placement,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    }, priority: EventPriority.high);
  }

  /// Social events
  void logSocialShare(String contentType, String method) {
    logEvent('social_share', parameters: {
      'content_type': contentType,
      'method': method,
    });
  }

  void logSocialInvite(String method) {
    logEvent('social_invite', parameters: {
      'method': method,
    });
  }

  /// Feature usage
  void logFeatureUsed(String featureName, {Map<String, dynamic>? extra}) {
    logEvent('feature_used', parameters: {
      'feature_name': featureName,
      ...?extra,
    });
  }

  /// Error tracking
  void logError(String errorType, String message, {String? stackTrace}) {
    logEvent('error', parameters: {
      'error_type': errorType,
      'message': message,
      'stack_trace': stackTrace,
    }, priority: EventPriority.high);
  }

  // ==================== Internal Methods ====================

  /// Start batch timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(
      Duration(milliseconds: _config?.batchIntervalMs ?? 30000),
      (_) => _sendBatch(),
    );
  }

  /// Send event batch
  Future<void> _sendBatch({bool immediate = false}) async {
    if (_eventBuffer.isEmpty) return;
    if (!_isOnline && !immediate) return;

    final batchSize = immediate ? _eventBuffer.length : (_config?.batchSize ?? 50);
    final batch = <AnalyticsEvent>[];

    for (var i = 0; i < batchSize && _eventBuffer.isNotEmpty; i++) {
      batch.add(_eventBuffer.removeFirst());
    }

    try {
      // TODO: Send to Firebase Analytics
      // for (final event in batch) {
      //   await FirebaseAnalytics.instance.logEvent(
      //     name: event.name,
      //     parameters: event.parameters,
      //   );
      // }

      if (_config?.debugMode == true) {
        print('Sent ${batch.length} events');
      }
    } catch (e) {
      // Put events back in buffer on failure
      for (final event in batch.reversed) {
        _eventBuffer.addFirst(event);
      }

      if (_config?.debugMode == true) {
        print('Failed to send events: $e');
      }
    }
  }

  /// Generate session ID
  String _generateSessionId() {
    return '${gameId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Update online status
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline) {
      _sendBatch();
    }
  }

  /// Flush all events
  Future<void> flush() async {
    while (_eventBuffer.isNotEmpty) {
      await _sendBatch(immediate: true);
    }
  }

  /// Dispose
  void dispose() {
    endSession();
    _batchTimer?.cancel();
    flush();
    _instances.remove(gameId);
  }
}

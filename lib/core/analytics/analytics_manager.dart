/// Analytics Manager for MG-Games
/// Unified event tracking across 52 games with Firebase Analytics integration

import 'dart:async';
import 'dart:collection';

import 'package:firebase_analytics/firebase_analytics.dart';

import '../firebase/firebase_service.dart';

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

  /// Firebase Analytics instance
  FirebaseAnalytics? _firebaseAnalytics;

  /// Event buffer for offline/batching
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

    // Get Firebase Analytics instance if available
    if (config.firebaseEnabled && FirebaseService.instance.isInitialized) {
      _firebaseAnalytics = FirebaseService.instance.analytics;
    }

    // Start new session
    startSession();

    // Start batch timer for offline events
    _startBatchTimer();

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
  Future<void> setUserId(String userId) async {
    _userId = userId;

    // Set Firebase user ID
    await _firebaseAnalytics?.setUserId(id: userId);
    await FirebaseService.instance.setUserId(userId);
  }

  /// Set user property
  Future<void> setUserProperty(String name, dynamic value) async {
    _userProperties[name] = UserProperty(name: name, value: value);

    // Set Firebase user property
    await _firebaseAnalytics?.setUserProperty(
      name: name,
      value: value?.toString(),
    );
  }

  /// Log event
  Future<void> logEvent(
    String name, {
    Map<String, dynamic> parameters = const {},
    EventPriority priority = EventPriority.normal,
  }) async {
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

    // Send to Firebase immediately if available
    if (_firebaseAnalytics != null && _isOnline) {
      try {
        // Convert parameters to Firebase format (String, int, double, bool only)
        final firebaseParams = _convertToFirebaseParams(event.parameters);
        await _firebaseAnalytics!.logEvent(
          name: name,
          parameters: firebaseParams,
        );
      } catch (e) {
        // Buffer on failure
        _eventBuffer.add(event);
      }
    } else {
      // Buffer for later
      _eventBuffer.add(event);
    }

    // Trim buffer if too large
    while (_eventBuffer.length > (_config?.maxOfflineEvents ?? 1000)) {
      _eventBuffer.removeFirst();
    }

    if (_config?.debugMode == true) {
      print('Event: $name ${event.parameters}');
    }
  }

  /// Convert parameters to Firebase-compatible format
  Map<String, Object>? _convertToFirebaseParams(Map<String, dynamic> params) {
    if (params.isEmpty) return null;

    final result = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;

      // Firebase only accepts String, int, double, bool
      if (value is String || value is int || value is double || value is bool) {
        result[key] = value;
      } else {
        result[key] = value.toString();
      }
    });

    return result.isEmpty ? null : result;
  }

  // ==================== Standard Events ====================

  /// Tutorial events
  Future<void> logTutorialBegin() async {
    await _firebaseAnalytics?.logTutorialBegin();
    await logEvent('tutorial_begin', priority: EventPriority.high);
  }

  Future<void> logTutorialComplete() async {
    await _firebaseAnalytics?.logTutorialComplete();
    await logEvent('tutorial_complete', priority: EventPriority.high);
  }

  Future<void> logTutorialStep(int step, String stepName) async {
    await logEvent('tutorial_step', parameters: {
      'step': step,
      'step_name': stepName,
    });
  }

  /// Level/stage events
  Future<void> logLevelStart(int level, {String? levelName, Map<String, dynamic>? extra}) async {
    await _firebaseAnalytics?.logLevelStart(levelName: levelName ?? 'Level $level');
    await logEvent('level_start', parameters: {
      'level': level,
      'level_name': levelName,
      ...?extra,
    });
  }

  Future<void> logLevelComplete(int level, {
    int? score,
    int? stars,
    int? durationMs,
    Map<String, dynamic>? extra,
  }) async {
    await _firebaseAnalytics?.logLevelEnd(
      levelName: 'Level $level',
      success: 1,
    );
    await logEvent('level_complete', parameters: {
      'level': level,
      'score': score,
      'stars': stars,
      'duration_ms': durationMs,
      ...?extra,
    }, priority: EventPriority.high);
  }

  Future<void> logLevelFail(int level, {String? reason, int? durationMs}) async {
    await _firebaseAnalytics?.logLevelEnd(
      levelName: 'Level $level',
      success: 0,
    );
    await logEvent('level_fail', parameters: {
      'level': level,
      'reason': reason,
      'duration_ms': durationMs,
    });
  }

  /// Economy events
  Future<void> logCurrencyEarned(String currencyType, int amount, String source) async {
    await _firebaseAnalytics?.logEarnVirtualCurrency(
      virtualCurrencyName: currencyType,
      value: amount,
    );
    await logEvent('currency_earned', parameters: {
      'currency_type': currencyType,
      'amount': amount,
      'source': source,
    });
  }

  Future<void> logCurrencySpent(String currencyType, int amount, String itemType, String itemId) async {
    await _firebaseAnalytics?.logSpendVirtualCurrency(
      virtualCurrencyName: currencyType,
      value: amount,
      itemName: itemId,
    );
    await logEvent('currency_spent', parameters: {
      'currency_type': currencyType,
      'amount': amount,
      'item_type': itemType,
      'item_id': itemId,
    });
  }

  Future<void> logItemAcquired(String itemId, String itemType, String source, {int? quantity}) async {
    await logEvent('item_acquired', parameters: {
      'item_id': itemId,
      'item_type': itemType,
      'source': source,
      'quantity': quantity ?? 1,
    });
  }

  /// IAP events
  Future<void> logPurchase(String productId, double priceUsd, String currencyCode) async {
    await _firebaseAnalytics?.logPurchase(
      value: priceUsd,
      currency: currencyCode,
      transactionId: '${DateTime.now().millisecondsSinceEpoch}',
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productId,
          price: priceUsd,
        ),
      ],
    );
    await logEvent('purchase', parameters: {
      'product_id': productId,
      'price_usd': priceUsd,
      'currency': currencyCode,
    }, priority: EventPriority.critical);
  }

  Future<void> logPurchaseFailed(String productId, String error) async {
    await logEvent('purchase_failed', parameters: {
      'product_id': productId,
      'error': error,
    }, priority: EventPriority.high);
  }

  /// Ad events
  Future<void> logAdImpression(String adType, String placement, {double? revenue}) async {
    await _firebaseAnalytics?.logAdImpression(
      adPlatform: 'admob',
      adFormat: adType,
      adSource: 'google',
      adUnitName: placement,
      value: revenue,
      currency: 'USD',
    );
    await logEvent('ad_impression', parameters: {
      'ad_type': adType,
      'placement': placement,
      'revenue': revenue,
    });
  }

  Future<void> logAdClick(String adType, String placement) async {
    await logEvent('ad_click', parameters: {
      'ad_type': adType,
      'placement': placement,
    });
  }

  Future<void> logAdRewardClaimed(String placement, String rewardType, int rewardAmount) async {
    await logEvent('ad_reward_claimed', parameters: {
      'placement': placement,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    }, priority: EventPriority.high);
  }

  /// Social events
  Future<void> logSocialShare(String contentType, String method) async {
    await _firebaseAnalytics?.logShare(
      contentType: contentType,
      itemId: 'share',
      method: method,
    );
    await logEvent('social_share', parameters: {
      'content_type': contentType,
      'method': method,
    });
  }

  Future<void> logSocialInvite(String method) async {
    await logEvent('social_invite', parameters: {
      'method': method,
    });
  }

  /// Feature usage
  Future<void> logFeatureUsed(String featureName, {Map<String, dynamic>? extra}) async {
    await logEvent('feature_used', parameters: {
      'feature_name': featureName,
      ...?extra,
    });
  }

  /// Screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _firebaseAnalytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Error tracking
  Future<void> logError(String errorType, String message, {String? stackTrace}) async {
    await FirebaseService.instance.recordError(
      Exception('$errorType: $message'),
      stackTrace != null ? StackTrace.fromString(stackTrace) : null,
      reason: errorType,
    );
    await logEvent('error', parameters: {
      'error_type': errorType,
      'message': message,
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
    if (_firebaseAnalytics == null) return;

    final batchSize = immediate ? _eventBuffer.length : (_config?.batchSize ?? 50);
    final batch = <AnalyticsEvent>[];

    for (var i = 0; i < batchSize && _eventBuffer.isNotEmpty; i++) {
      batch.add(_eventBuffer.removeFirst());
    }

    try {
      for (final event in batch) {
        final params = _convertToFirebaseParams(event.parameters);
        await _firebaseAnalytics!.logEvent(
          name: event.name,
          parameters: params,
        );
      }

      if (_config?.debugMode == true) {
        print('Sent ${batch.length} buffered events');
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

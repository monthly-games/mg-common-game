/// Firebase Service for MG-Games
/// Unified Firebase initialization and management

import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase initialization result
class FirebaseInitResult {
  final bool success;
  final String? error;
  final Map<String, bool> services;

  const FirebaseInitResult({
    required this.success,
    this.error,
    this.services = const {},
  });
}

/// Firebase service configuration
class FirebaseConfig {
  /// Game ID (e.g., "game_0001")
  final String gameId;

  /// Enable Analytics
  final bool analyticsEnabled;

  /// Enable Crashlytics
  final bool crashlyticsEnabled;

  /// Enable Remote Config
  final bool remoteConfigEnabled;

  /// Debug mode
  final bool debugMode;

  /// Firebase options (from firebase_options.dart)
  final FirebaseOptions? options;

  const FirebaseConfig({
    required this.gameId,
    this.analyticsEnabled = true,
    this.crashlyticsEnabled = true,
    this.remoteConfigEnabled = true,
    this.debugMode = false,
    this.options,
  });
}

/// Firebase Service singleton
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  FirebaseConfig? _config;
  bool _isInitialized = false;

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _analyticsObserver;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get Analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Get Analytics observer for navigation
  FirebaseAnalyticsObserver? get analyticsObserver => _analyticsObserver;

  /// Initialize Firebase
  Future<FirebaseInitResult> initialize(FirebaseConfig config) async {
    if (_isInitialized) {
      return FirebaseInitResult(
        success: true,
        services: _getServiceStatus(),
      );
    }

    _config = config;
    final services = <String, bool>{};

    try {
      // Initialize Firebase Core
      if (config.options != null) {
        await Firebase.initializeApp(options: config.options);
      } else {
        await Firebase.initializeApp();
      }

      // Initialize Analytics
      if (config.analyticsEnabled) {
        try {
          _analytics = FirebaseAnalytics.instance;
          _analyticsObserver = FirebaseAnalyticsObserver(analytics: _analytics!);

          await _analytics!.setAnalyticsCollectionEnabled(!config.debugMode || kDebugMode);
          await _analytics!.setDefaultEventParameters({
            'game_id': config.gameId,
          });

          services['analytics'] = true;
        } catch (e) {
          services['analytics'] = false;
          if (config.debugMode) {
            debugPrint('Failed to initialize Analytics: $e');
          }
        }
      }

      // Initialize Crashlytics
      if (config.crashlyticsEnabled) {
        try {
          final crashlytics = FirebaseCrashlytics.instance;

          // Set collection enabled
          await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

          // Set custom keys
          await crashlytics.setCustomKey('game_id', config.gameId);

          // Pass all uncaught errors to Crashlytics
          FlutterError.onError = (errorDetails) {
            crashlytics.recordFlutterFatalError(errorDetails);
          };

          // Pass all uncaught asynchronous errors
          PlatformDispatcher.instance.onError = (error, stack) {
            crashlytics.recordError(error, stack, fatal: true);
            return true;
          };

          services['crashlytics'] = true;
        } catch (e) {
          services['crashlytics'] = false;
          if (config.debugMode) {
            debugPrint('Failed to initialize Crashlytics: $e');
          }
        }
      }

      _isInitialized = true;

      return FirebaseInitResult(
        success: true,
        services: services,
      );
    } catch (e) {
      return FirebaseInitResult(
        success: false,
        error: e.toString(),
        services: services,
      );
    }
  }

  /// Get current service status
  Map<String, bool> _getServiceStatus() {
    return {
      'analytics': _analytics != null,
      'crashlytics': _config?.crashlyticsEnabled ?? false,
      'remoteConfig': _config?.remoteConfigEnabled ?? false,
    };
  }

  // ==================== Analytics Methods ====================

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    await _analytics?.setUserId(id: userId);
    if (userId != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics?.setUserProperty(name: name, value: value);
    if (value != null) {
      await FirebaseCrashlytics.instance.setCustomKey(name, value);
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Log level start
  Future<void> logLevelStart({required String levelName}) async {
    await _analytics?.logLevelStart(levelName: levelName);
  }

  /// Log level end
  Future<void> logLevelEnd({
    required String levelName,
    int? success,
  }) async {
    await _analytics?.logLevelEnd(levelName: levelName, success: success);
  }

  /// Log purchase
  Future<void> logPurchase({
    required double value,
    required String currency,
    String? transactionId,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics?.logPurchase(
      value: value,
      currency: currency,
      transactionId: transactionId,
      items: items,
    );
  }

  /// Log ad impression
  Future<void> logAdImpression({
    required String adPlatform,
    required String adFormat,
    required String adSource,
    String? adUnitName,
    double? value,
    String? currency,
  }) async {
    await _analytics?.logAdImpression(
      adPlatform: adPlatform,
      adFormat: adFormat,
      adSource: adSource,
      adUnitName: adUnitName,
      value: value,
      currency: currency,
    );
  }

  /// Log tutorial begin
  Future<void> logTutorialBegin() async {
    await _analytics?.logTutorialBegin();
  }

  /// Log tutorial complete
  Future<void> logTutorialComplete() async {
    await _analytics?.logTutorialComplete();
  }

  /// Log earn virtual currency
  Future<void> logEarnVirtualCurrency({
    required String virtualCurrencyName,
    required num value,
  }) async {
    await _analytics?.logEarnVirtualCurrency(
      virtualCurrencyName: virtualCurrencyName,
      value: value,
    );
  }

  /// Log spend virtual currency
  Future<void> logSpendVirtualCurrency({
    required String virtualCurrencyName,
    required num value,
    required String itemName,
  }) async {
    await _analytics?.logSpendVirtualCurrency(
      virtualCurrencyName: virtualCurrencyName,
      value: value,
      itemName: itemName,
    );
  }

  /// Log unlock achievement
  Future<void> logUnlockAchievement({required String achievementId}) async {
    await _analytics?.logUnlockAchievement(achievementId: achievementId);
  }

  /// Log post score
  Future<void> logPostScore({
    required int score,
    int? level,
    String? character,
  }) async {
    await _analytics?.logPostScore(
      score: score,
      level: level,
      character: character,
    );
  }

  // ==================== Crashlytics Methods ====================

  /// Record error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log message to Crashlytics
  Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }

  /// Set custom key
  Future<void> setCustomKey(String key, Object value) async {
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Force a crash (for testing)
  void forceCrash() {
    FirebaseCrashlytics.instance.crash();
  }

  /// Check if crash collection enabled
  Future<bool> isCrashlyticsCollectionEnabled() async {
    return FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled;
  }
}

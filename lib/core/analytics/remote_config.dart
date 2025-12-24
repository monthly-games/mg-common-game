/// Remote Config Manager for MG-Games
/// Centralized remote configuration across 52 games

import 'dart:async';
import 'dart:convert';

/// Remote config value wrapper
class ConfigValue<T> {
  final String key;
  final T value;
  final T defaultValue;
  final String source; // 'default', 'remote', 'static'
  final int? fetchedAt;

  ConfigValue({
    required this.key,
    required this.value,
    required this.defaultValue,
    required this.source,
    this.fetchedAt,
  });

  bool get isRemote => source == 'remote';
}

/// A/B test variant
class AbTestVariant {
  final String testId;
  final String variantId;
  final String variantName;
  final Map<String, dynamic> parameters;

  AbTestVariant({
    required this.testId,
    required this.variantId,
    required this.variantName,
    this.parameters = const {},
  });
}

/// Remote config listener
typedef ConfigChangeListener = void Function(String key, dynamic oldValue, dynamic newValue);

/// Remote Config Manager
class RemoteConfigManager {
  /// Singleton instances per game
  static final Map<String, RemoteConfigManager> _instances = {};

  /// Get instance for game
  static RemoteConfigManager getInstance(String gameId) {
    return _instances.putIfAbsent(gameId, () => RemoteConfigManager._internal(gameId));
  }

  RemoteConfigManager._internal(this.gameId);

  /// Game ID
  final String gameId;

  /// Default values
  final Map<String, dynamic> _defaults = {};

  /// Remote values
  final Map<String, dynamic> _remoteValues = {};

  /// A/B test assignments
  final Map<String, AbTestVariant> _abTests = {};

  /// Change listeners
  final List<ConfigChangeListener> _listeners = [];

  /// Last fetch time
  int? _lastFetchTime;

  /// Fetch interval (minimum 1 hour)
  final int _minFetchIntervalMs = 3600000;

  /// Is initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize with defaults
  Future<void> initialize(Map<String, dynamic> defaults) async {
    _defaults.addAll(defaults);

    // TODO: Initialize Firebase Remote Config
    // await FirebaseRemoteConfig.instance.setDefaults(defaults);

    await fetchAndActivate();
    _isInitialized = true;
  }

  /// Fetch and activate remote config
  Future<bool> fetchAndActivate() async {
    // Check if enough time has passed since last fetch
    if (_lastFetchTime != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _lastFetchTime!;
      if (elapsed < _minFetchIntervalMs) {
        return false;
      }
    }

    try {
      // TODO: Fetch from Firebase Remote Config
      // await FirebaseRemoteConfig.instance.fetchAndActivate();

      // Simulated remote values for development
      _remoteValues.addAll(_getSimulatedRemoteValues());

      _lastFetchTime = DateTime.now().millisecondsSinceEpoch;
      return true;
    } catch (e) {
      print('Failed to fetch remote config: $e');
      return false;
    }
  }

  /// Get string value
  String getString(String key, {String defaultValue = ''}) {
    return _getValue<String>(key, defaultValue);
  }

  /// Get int value
  int getInt(String key, {int defaultValue = 0}) {
    return _getValue<int>(key, defaultValue);
  }

  /// Get double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _getValue<double>(key, defaultValue);
  }

  /// Get bool value
  bool getBool(String key, {bool defaultValue = false}) {
    return _getValue<bool>(key, defaultValue);
  }

  /// Get JSON value
  Map<String, dynamic> getJson(String key, {Map<String, dynamic> defaultValue = const {}}) {
    final stringValue = getString(key);
    if (stringValue.isEmpty) return defaultValue;

    try {
      return jsonDecode(stringValue) as Map<String, dynamic>;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Get typed value
  T _getValue<T>(String key, T defaultValue) {
    // Check remote values first
    if (_remoteValues.containsKey(key)) {
      final value = _remoteValues[key];
      if (value is T) return value;
    }

    // Fall back to defaults
    if (_defaults.containsKey(key)) {
      final value = _defaults[key];
      if (value is T) return value;
    }

    return defaultValue;
  }

  /// Get config value with metadata
  ConfigValue<T> getConfigValue<T>(String key, T defaultValue) {
    final isRemote = _remoteValues.containsKey(key);
    final value = _getValue<T>(key, defaultValue);

    return ConfigValue<T>(
      key: key,
      value: value,
      defaultValue: defaultValue,
      source: isRemote ? 'remote' : 'default',
      fetchedAt: _lastFetchTime,
    );
  }

  // ==================== A/B Testing ====================

  /// Get A/B test variant
  AbTestVariant? getAbTestVariant(String testId) {
    return _abTests[testId];
  }

  /// Set A/B test variant (for testing)
  void setAbTestVariant(AbTestVariant variant) {
    _abTests[variant.testId] = variant;
  }

  /// Check if user is in variant
  bool isInVariant(String testId, String variantId) {
    final variant = _abTests[testId];
    return variant?.variantId == variantId;
  }

  // ==================== Game-Specific Configs ====================

  /// Economy config
  Map<String, dynamic> getEconomyConfig() {
    return getJson('economy_config', defaultValue: {
      'daily_reward_coins': 100,
      'energy_regen_minutes': 20,
      'max_energy': 30,
    });
  }

  /// Ads config
  Map<String, dynamic> getAdsConfig() {
    return getJson('ads_config', defaultValue: {
      'interstitial_cooldown': 180,
      'max_rewarded_per_day': 10,
      'banner_enabled': false,
    });
  }

  /// Event config
  Map<String, dynamic> getEventConfig() {
    return getJson('event_config', defaultValue: {
      'current_event_id': null,
      'event_end_timestamp': null,
    });
  }

  /// Feature flags
  Map<String, bool> getFeatureFlags() {
    final json = getJson('feature_flags', defaultValue: {});
    return json.map((key, value) => MapEntry(key, value == true));
  }

  /// Check feature flag
  bool isFeatureEnabled(String feature) {
    final flags = getFeatureFlags();
    return flags[feature] ?? false;
  }

  // ==================== Listeners ====================

  /// Add change listener
  void addListener(ConfigChangeListener listener) {
    _listeners.add(listener);
  }

  /// Remove change listener
  void removeListener(ConfigChangeListener listener) {
    _listeners.remove(listener);
  }

  /// Notify listeners
  void _notifyListeners(String key, dynamic oldValue, dynamic newValue) {
    for (final listener in _listeners) {
      listener(key, oldValue, newValue);
    }
  }

  // ==================== Simulated Values ====================

  /// Simulated remote values for development
  Map<String, dynamic> _getSimulatedRemoteValues() {
    return {
      'economy_config': jsonEncode({
        'daily_reward_coins': 100,
        'energy_regen_minutes': 20,
        'max_energy': 30,
      }),
      'ads_config': jsonEncode({
        'interstitial_cooldown': 180,
        'max_rewarded_per_day': 10,
        'banner_enabled': false,
      }),
      'feature_flags': jsonEncode({
        'new_ui_enabled': false,
        'social_features': true,
      }),
    };
  }

  /// Dispose
  void dispose() {
    _listeners.clear();
    _instances.remove(gameId);
  }
}

/// Standard remote config defaults for casual games
class CasualGameDefaults {
  static Map<String, dynamic> get all => {
        // Economy
        'daily_reward_coins': 100,
        'energy_regen_minutes': 20,
        'max_energy': 30,
        'starting_coins': 500,

        // Ads
        'interstitial_cooldown': 180,
        'max_interstitials_per_day': 15,
        'max_rewarded_per_day': 10,
        'banner_enabled': false,

        // Gameplay
        'tutorial_enabled': true,
        'difficulty_adjustment': true,
        'offline_rewards_max_hours': 8,

        // Features
        'social_features_enabled': true,
        'leaderboard_enabled': true,
        'notifications_enabled': true,
      };
}

/// Standard remote config defaults for Level A games
class LevelAGameDefaults {
  static Map<String, dynamic> get all => {
        // Economy
        'daily_gems': 50,
        'stamina_regen_minutes': 5,
        'max_stamina': 120,
        'starting_gems': 1000,

        // Gacha
        'pity_counter_ssr': 90,
        'pity_counter_sr': 10,
        'rate_up_percentage': 50,

        // Ads
        'interstitial_cooldown': 300,
        'max_interstitials_per_day': 10,
        'max_rewarded_per_day': 5,

        // Features
        'guild_enabled': true,
        'pvp_enabled': true,
        'live_ops_enabled': true,
      };
}

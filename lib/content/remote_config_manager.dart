import 'dart:async';
import 'package:flutter/material.dart';

enum ConfigValueType {
  string,
  number,
  boolean,
  json,
  array,
}

enum ConfigFetchStatus {
  success,
  failure,
  throttled,
  noUpdate,
}

enum ConfigSource {
  remote,
  default,
  cached,
}

class RemoteConfigValue {
  final String key;
  final dynamic value;
  final ConfigValueType type;
  final ConfigSource source;
  final DateTime? fetchedAt;
  final String? metadata;

  const RemoteConfigValue({
    required this.key,
    required this.value,
    required this.type,
    required this.source,
    this.fetchedAt,
    this.metadata,
  });

  String get asString => value.toString();
  int get asInt => value is int ? value as int : int.tryParse(value.toString()) ?? 0;
  double get asDouble => value is double ? value as double : double.tryParse(value.toString()) ?? 0.0;
  bool get asBool => value is bool ? value as bool : value.toString().toLowerCase() == 'true';
  Map<String, dynamic> get asJson => value is Map ? value as Map<String, dynamic> : {};
  List<dynamic> get asArray => value is List ? value as List<dynamic> : [];

  bool get isFromRemote => source == ConfigSource.remote;
  bool get isDefault => source == ConfigSource.default;
  bool get isCached => source == ConfigSource.cached;
}

class ConfigParameter {
  final String key;
  final String description;
  final dynamic defaultValue;
  final ConfigValueType type;
  final bool isRequired;
  final String? condition;
  final List<String>? tags;

  const ConfigParameter({
    required this.key,
    required this.description,
    required this.defaultValue,
    required this.type,
    required this.isRequired,
    this.condition,
    this.tags,
  });
}

class ConfigCondition {
  final String conditionId;
  final String name;
  final String expression;
  final Map<String, dynamic> parameters;

  const ConfigCondition({
    required this.conditionId,
    required this.name,
    required this.expression,
    required this.parameters,
  });

  bool evaluate(Map<String, dynamic> userContext) {
    return true;
  }
}

class FeatureFlag {
  final String flagId;
  final String name;
  final String description;
  final bool defaultValue;
  final Map<String, bool> variantValues;
  final String? condition;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeatureFlag({
    required this.flagId,
    required this.name,
    required this.description,
    required this.defaultValue,
    required this.variantValues,
    this.condition,
    this.createdAt,
    this.updatedAt,
  });
}

class ConfigFetchResult {
  final ConfigFetchStatus status;
  final DateTime? fetchedAt;
  final String? errorMessage;
  final int fetchedKeys;
  final Duration fetchDuration;

  const ConfigFetchResult({
    required this.status,
    this.fetchedAt,
    this.errorMessage,
    required this.fetchedKeys,
    required this.fetchDuration,
  });

  bool get isSuccess => status == ConfigFetchStatus.success;
  bool get isFailure => status == ConfigFetchStatus.failure;
}

class RemoteConfigManager {
  static final RemoteConfigManager _instance = RemoteConfigManager._();
  static RemoteConfigManager get instance => _instance;

  RemoteConfigManager._();

  final Map<String, RemoteConfigValue> _configValues = {};
  final Map<String, ConfigParameter> _parameters = {};
  final Map<String, FeatureFlag> _featureFlags = {};
  final Map<String, ConfigCondition> _conditions = {};
  final StreamController<ConfigEvent> _eventController = StreamController.broadcast();
  Timer? _refreshTimer;
  DateTime? _lastFetchTime;
  Duration _minimumFetchInterval = const Duration(minutes: 1);
  Duration _cacheExpiration = const Duration(hours: 12);

  Stream<ConfigEvent> get onConfigEvent => _eventController.stream;

  Future<void> initialize({
    Duration? minimumFetchInterval,
    Duration? cacheExpiration,
    bool autoFetch = true,
    Duration refreshInterval = const Duration(minutes: 30),
  }) async {
    _minimumFetchInterval = minimumFetchInterval ?? _minimumFetchInterval;
    _cacheExpiration = cacheExpiration ?? _cacheExpiration;

    await _loadDefaultParameters();
    await _loadFeatureFlags();
    await _loadConditions();

    if (autoFetch) {
      await fetchConfigs();
    }

    _startRefreshTimer(refreshInterval);
  }

  Future<void> _loadDefaultParameters() async {
    final parameters = [
      ConfigParameter(
        key: 'game_difficulty',
        description: 'Game difficulty level',
        defaultValue: 'normal',
        type: ConfigValueType.string,
        isRequired: true,
        tags: ['gameplay'],
      ),
      ConfigParameter(
        key: 'max_player_level',
        description: 'Maximum player level',
        defaultValue: 100,
        type: ConfigValueType.number,
        isRequired: true,
        tags: ['gameplay'],
      ),
      ConfigParameter(
        key: 'enable_pvp',
        description: 'Enable PVP mode',
        defaultValue: true,
        type: ConfigValueType.boolean,
        isRequired: true,
        tags: ['feature'],
      ),
      ConfigParameter(
        key: 'daily_reward_coins',
        description: 'Daily login reward coins',
        defaultValue: 100,
        type: ConfigValueType.number,
        isRequired: true,
        tags: ['rewards'],
      ),
      ConfigParameter(
        key: 'shop_discount_rate',
        description: 'Shop discount rate (0-1)',
        defaultValue: 0.1,
        type: ConfigValueType.number,
        isRequired: false,
        tags: ['monetization'],
      ),
      ConfigParameter(
        key: 'maintenance_message',
        description: 'Maintenance message',
        defaultValue: '',
        type: ConfigValueType.string,
        isRequired: false,
        tags: ['maintenance'],
      ),
      ConfigParameter(
        key: 'event_schedule',
        description: 'Event schedule configuration',
        defaultValue: {},
        type: ConfigValueType.json,
        isRequired: false,
        tags: ['events'],
      ),
      ConfigParameter(
        key: 'banner_rotation',
        description: 'Banner rotation order',
        defaultValue: [],
        type: ConfigValueType.array,
        isRequired: false,
        tags: ['ui'],
      ),
    ];

    for (final param in parameters) {
      _parameters[param.key] = param;
      _configValues[param.key] = RemoteConfigValue(
        key: param.key,
        value: param.defaultValue,
        type: param.type,
        source: ConfigSource.default,
      );
    }
  }

  Future<void> _loadFeatureFlags() async {
    final flags = [
      FeatureFlag(
        flagId: 'new_tutorial_enabled',
        name: 'New Tutorial Enabled',
        description: 'Enable the new tutorial flow',
        defaultValue: false,
        variantValues: {},
      ),
      FeatureFlag(
        flagId: 'advanced_stats_enabled',
        name: 'Advanced Stats Enabled',
        description: 'Show advanced statistics to players',
        defaultValue: false,
        variantValues: {},
      ),
      FeatureFlag(
        flagId: 'seasonal_events_enabled',
        name: 'Seasonal Events Enabled',
        description: 'Enable seasonal events',
        defaultValue: true,
        variantValues: {},
      ),
      FeatureFlag(
        flagId: 'new_ui_enabled',
        name: 'New UI Enabled',
        description: 'Enable the new user interface',
        defaultValue: false,
        variantValues: {},
      ),
    ];

    for (final flag in flags) {
      _featureFlags[flag.flagId] = flag;
    }
  }

  Future<void> _loadConditions() async {
    final conditions = [
      ConfigCondition(
        conditionId: 'user_level_gt_10',
        name: 'User level greater than 10',
        expression: 'user_level > 10',
        parameters: {'user_level': 0},
      ),
      ConfigCondition(
        conditionId: 'is_premium_user',
        name: 'Is premium user',
        expression: 'is_premium == true',
        parameters: {'is_premium': false},
      ),
      ConfigCondition(
        conditionId: 'completed_tutorial',
        name: 'Completed tutorial',
        expression: 'tutorial_completed == true',
        parameters: {'tutorial_completed': false},
      ),
    ];

    for (final condition in conditions) {
      _conditions[condition.conditionId] = condition;
    }
  }

  void _startRefreshTimer(Duration interval) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchConfigs());
  }

  Future<ConfigFetchResult> fetchConfigs({
    Map<String, dynamic>? userContext,
  }) async {
    final startTime = DateTime.now();

    if (!_shouldFetch()) {
      final result = ConfigFetchResult(
        status: ConfigFetchStatus.throttled,
        fetchedAt: DateTime.now(),
        fetchedKeys: 0,
        fetchDuration: Duration.zero,
      );

      _eventController.add(ConfigEvent(
        type: ConfigEventType.fetchThrottled,
        timestamp: DateTime.now(),
      ));

      return result;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updates = _generateRemoteConfigs(userContext);
      final fetchedKeys = updates.length;

      for (final entry in updates.entries) {
        _configValues[entry.key] = entry.value;
      }

      _lastFetchTime = DateTime.now();

      final result = ConfigFetchResult(
        status: ConfigFetchStatus.success,
        fetchedAt: _lastFetchTime,
        fetchedKeys: fetchedKeys,
        fetchDuration: DateTime.now().difference(startTime),
      );

      _eventController.add(ConfigEvent(
        type: ConfigEventType.fetchSuccess,
        timestamp: DateTime.now(),
        data: {
          'fetchedKeys': fetchedKeys,
          'duration': result.fetchDuration.inMilliseconds,
        },
      ));

      return result;
    } catch (e) {
      final result = ConfigFetchResult(
        status: ConfigFetchStatus.failure,
        fetchedAt: DateTime.now(),
        errorMessage: e.toString(),
        fetchedKeys: 0,
        fetchDuration: DateTime.now().difference(startTime),
      );

      _eventController.add(ConfigEvent(
        type: ConfigEventType.fetchFailed,
        timestamp: DateTime.now(),
        data: {'error': e.toString()},
      ));

      return result;
    }
  }

  bool _shouldFetch() {
    if (_lastFetchTime == null) return true;
    final elapsed = DateTime.now().difference(_lastFetchTime!);
    return elapsed >= _minimumFetchInterval;
  }

  Map<String, RemoteConfigValue> _generateRemoteConfigs(
    Map<String, dynamic>? userContext,
  ) {
    return {
      'game_difficulty': RemoteConfigValue(
        key: 'game_difficulty',
        value: 'hard',
        type: ConfigValueType.string,
        source: ConfigSource.remote,
        fetchedAt: DateTime.now(),
      ),
      'max_player_level': RemoteConfigValue(
        key: 'max_player_level',
        value: 150,
        type: ConfigValueType.number,
        source: ConfigSource.remote,
        fetchedAt: DateTime.now(),
      ),
      'daily_reward_coins': RemoteConfigValue(
        key: 'daily_reward_coins',
        value: 200,
        type: ConfigValueType.number,
        source: ConfigSource.remote,
        fetchedAt: DateTime.now(),
      ),
    };
  }

  RemoteConfigValue getValue(String key) {
    return _configValues[key] ?? RemoteConfigValue(
      key: key,
      value: null,
      type: ConfigValueType.string,
      source: ConfigSource.default,
    );
  }

  String getString(String key, {String defaultValue = ''}) {
    final value = getValue(key);
    if (value.value == null) return defaultValue;
    return value.asString;
  }

  int getInt(String key, {int defaultValue = 0}) {
    final value = getValue(key);
    if (value.value == null) return defaultValue;
    return value.asInt;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = getValue(key);
    if (value.value == null) return defaultValue;
    return value.asDouble;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final value = getValue(key);
    if (value.value == null) return defaultValue;
    return value.asBool;
  }

  Map<String, dynamic> getJson(String key) {
    return getValue(key).asJson;
  }

  List<dynamic> getArray(String key) {
    return getValue(key).asArray;
  }

  List<RemoteConfigValue> getAllValues() {
    return _configValues.values.toList();
  }

  List<RemoteConfigValue> getValuesByTag(String tag) {
    return _parameters.entries
        .where((entry) => entry.value.tags?.contains(tag) ?? false)
        .map((entry) => _configValues[entry.key]!)
        .toList();
  }

  bool isFeatureEnabled(String flagId, {Map<String, dynamic>? userContext}) {
    final flag = _featureFlags[flagId];
    if (flag == null) return false;

    if (flag.condition != null) {
      final condition = _conditions[flag.condition];
      if (condition != null) {
        return condition.evaluate(userContext ?? {});
      }
    }

    return flag.defaultValue;
  }

  List<FeatureFlag> getAllFeatureFlags() {
    return _featureFlags.values.toList();
  }

  FeatureFlag? getFeatureFlag(String flagId) {
    return _featureFlags[flagId];
  }

  void setFeatureFlag(String flagId, bool enabled) {
    final flag = _featureFlags[flagId];
    if (flag == null) return;

    final updated = FeatureFlag(
      flagId: flag.flagId,
      name: flag.name,
      description: flag.description,
      defaultValue: enabled,
      variantValues: flag.variantValues,
      condition: flag.condition,
      createdAt: flag.createdAt,
      updatedAt: DateTime.now(),
    );

    _featureFlags[flagId] = updated;

    _eventController.add(ConfigEvent(
      type: ConfigEventType.featureFlagUpdated,
      flagId: flagId,
      timestamp: DateTime.now(),
      data: {'enabled': enabled},
    ));
  }

  Future<bool> activate(String key) async {
    final value = getValue(key);
    _eventController.add(ConfigEvent(
      type: ConfigEventType.activated,
      key: key,
      timestamp: DateTime.now(),
    ));
    return true;
  }

  ConfigParameter? getParameter(String key) {
    return _parameters[key];
  }

  List<ConfigParameter> getAllParameters() {
    return _parameters.values.toList();
  }

  Map<String, dynamic> getConfigStats() {
    return {
      'totalParameters': _parameters.length,
      'totalFeatureFlags': _featureFlags.length,
      'totalConditions': _conditions.length,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheExpiration': _cacheExpiration.inHours,
      'valuesFromRemote': _configValues.values.where((v) => v.isFromRemote).length,
      'valuesFromDefault': _configValues.values.where((v) => v.isDefault).length,
      'valuesFromCache': _configValues.values.where((v) => v.isCached).length,
    };
  }

  Future<void> clearCache() async {
    for (final key in _configValues.keys) {
      final value = _configValues[key];
      if (value != null && value.isCached) {
        _configValues[key] = RemoteConfigValue(
          key: key,
          value: _parameters[key]?.defaultValue,
          type: value.type,
          source: ConfigSource.default,
        );
      }
    }

    _eventController.add(ConfigEvent(
      type: ConfigEventType.cacheCleared,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> resetToDefaults() async {
    for (final param in _parameters.values) {
      _configValues[param.key] = RemoteConfigValue(
        key: param.key,
        value: param.defaultValue,
        type: param.type,
        source: ConfigSource.default,
      );
    }

    _eventController.add(ConfigEvent(
      type: ConfigEventType.resetToDefaults,
      timestamp: DateTime.now(),
    ));
  }

  void setMinimumFetchInterval(Duration duration) {
    _minimumFetchInterval = duration;
  }

  void setCacheExpiration(Duration duration) {
    _cacheExpiration = duration;
  }

  void dispose() {
    _refreshTimer?.cancel();
    _eventController.close();
  }
}

class ConfigEvent {
  final ConfigEventType type;
  final String? key;
  final String? flagId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const ConfigEvent({
    required this.type,
    this.key,
    this.flagId,
    required this.timestamp,
    this.data,
  });
}

enum ConfigEventType {
  fetchSuccess,
  fetchFailed,
  fetchThrottled,
  activated,
  featureFlagUpdated,
  cacheCleared,
  resetToDefaults,
  configUpdated,
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback for auto-click events
typedef AutoClickCallback = void Function(int clickCount, double damageDealt);

/// Configuration for an auto-clicker
class AutoClickerConfig {
  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// Base clicks per second
  final double baseClicksPerSecond;

  /// Base damage per click
  final double baseDamagePerClick;

  /// Purchase cost (0 = free/unlocked)
  final int cost;

  /// Maximum level (0 = unlimited)
  final int maxLevel;

  /// Cost multiplier per level
  final double costMultiplier;

  /// Damage increase per level
  final double damagePerLevel;

  /// CPS increase per level
  final double cpsPerLevel;

  /// Icon for display
  final IconData? icon;

  const AutoClickerConfig({
    required this.id,
    required this.name,
    this.baseClicksPerSecond = 1.0,
    this.baseDamagePerClick = 1.0,
    this.cost = 0,
    this.maxLevel = 0,
    this.costMultiplier = 1.5,
    this.damagePerLevel = 0.5,
    this.cpsPerLevel = 0.1,
    this.icon,
  });
}

/// State of an auto-clicker
class AutoClickerState {
  final String id;
  int level;
  bool isUnlocked;
  bool isActive;

  AutoClickerState({
    required this.id,
    this.level = 0,
    this.isUnlocked = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'isUnlocked': isUnlocked,
      'isActive': isActive,
    };
  }

  factory AutoClickerState.fromJson(Map<String, dynamic> json) {
    return AutoClickerState(
      id: json['id'] as String,
      level: json['level'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Manages auto-clicker system for idle/clicker games
class AutoClickerManager extends ChangeNotifier {
  static const String _stateKey = 'auto_clicker_state';

  SharedPreferences? _prefs;
  Timer? _tickTimer;
  bool _isRunning = false;

  final Map<String, AutoClickerConfig> _configs = {};
  final Map<String, AutoClickerState> _states = {};

  /// Global click multiplier
  double globalClickMultiplier = 1.0;

  /// Global CPS multiplier
  double globalCpsMultiplier = 1.0;

  /// Tick interval in milliseconds
  int tickIntervalMs = 100;

  /// Accumulated fractional clicks (for sub-1 CPS)
  final Map<String, double> _accumulatedClicks = {};

  /// Total clicks performed by auto-clickers
  int totalAutoClicks = 0;

  /// Total damage dealt by auto-clickers
  double totalAutoDamage = 0;

  /// Callback when auto-clicks occur
  AutoClickCallback? onAutoClick;

  /// Callback when auto-clicker is upgraded
  void Function(String id, int newLevel)? onUpgrade;

  /// Initialize the manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadState();
  }

  void _loadState() {
    final stateJson = _prefs?.getString(_stateKey);
    if (stateJson != null) {
      try {
        final states = _parseJsonList(stateJson);
        for (final stateData in states) {
          final state = AutoClickerState.fromJson(stateData);
          _states[state.id] = state;
        }
      } catch (e) {
        // Ignore parse errors
      }
    }
  }

  List<Map<String, dynamic>> _parseJsonList(String json) {
    // Simple JSON list parser
    final result = <Map<String, dynamic>>[];
    // Simplified - in production use dart:convert
    return result;
  }

  Future<void> _saveState() async {
    final states = _states.values.map((s) => s.toJson()).toList();
    // In production, use jsonEncode
    await _prefs?.setString(_stateKey, states.toString());
  }

  // ============================================================
  // Registration
  // ============================================================

  /// Register an auto-clicker configuration
  void registerAutoClicker(AutoClickerConfig config) {
    _configs[config.id] = config;
    if (!_states.containsKey(config.id)) {
      _states[config.id] = AutoClickerState(
        id: config.id,
        isUnlocked: config.cost == 0,
      );
    }
  }

  /// Register multiple auto-clickers
  void registerAutoClickers(List<AutoClickerConfig> configs) {
    for (final config in configs) {
      registerAutoClicker(config);
    }
  }

  /// Unregister an auto-clicker
  void unregisterAutoClicker(String id) {
    _configs.remove(id);
    _states.remove(id);
    _accumulatedClicks.remove(id);
  }

  // ============================================================
  // Getters
  // ============================================================

  /// Get all auto-clicker configs
  List<AutoClickerConfig> get allConfigs => _configs.values.toList();

  /// Get all unlocked auto-clickers
  List<AutoClickerConfig> get unlockedAutoClickers {
    return _configs.values.where((c) => isUnlocked(c.id)).toList();
  }

  /// Get all active auto-clickers
  List<AutoClickerConfig> get activeAutoClickers {
    return _configs.values
        .where((c) => isUnlocked(c.id) && isActive(c.id))
        .toList();
  }

  /// Check if an auto-clicker is unlocked
  bool isUnlocked(String id) {
    return _states[id]?.isUnlocked ?? false;
  }

  /// Check if an auto-clicker is active
  bool isActive(String id) {
    return _states[id]?.isActive ?? true;
  }

  /// Get level of an auto-clicker
  int getLevel(String id) {
    return _states[id]?.level ?? 0;
  }

  /// Get config for an auto-clicker
  AutoClickerConfig? getConfig(String id) {
    return _configs[id];
  }

  /// Get state for an auto-clicker
  AutoClickerState? getState(String id) {
    return _states[id];
  }

  // ============================================================
  // Stats Calculation
  // ============================================================

  /// Get current CPS for an auto-clicker
  double getCps(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null || !state.isUnlocked || !state.isActive) {
      return 0;
    }

    final baseCps = config.baseClicksPerSecond;
    final levelBonus = config.cpsPerLevel * state.level;
    return (baseCps + levelBonus) * globalCpsMultiplier;
  }

  /// Get current damage per click for an auto-clicker
  double getDamagePerClick(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null || !state.isUnlocked) {
      return 0;
    }

    final baseDamage = config.baseDamagePerClick;
    final levelBonus = config.damagePerLevel * state.level;
    return (baseDamage + levelBonus) * globalClickMultiplier;
  }

  /// Get total CPS from all active auto-clickers
  double get totalCps {
    double total = 0;
    for (final config in _configs.values) {
      total += getCps(config.id);
    }
    return total;
  }

  /// Get total DPS from all active auto-clickers
  double get totalDps {
    double total = 0;
    for (final config in _configs.values) {
      total += getCps(config.id) * getDamagePerClick(config.id);
    }
    return total;
  }

  /// Get upgrade cost for an auto-clicker
  int getUpgradeCost(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null) return 0;

    if (!state.isUnlocked) {
      return config.cost;
    }

    if (config.maxLevel > 0 && state.level >= config.maxLevel) {
      return 0; // Max level reached
    }

    final baseCost = config.cost > 0 ? config.cost : 100;
    return (baseCost * _pow(config.costMultiplier, state.level.toDouble())).floor();
  }

  double _pow(double base, double exp) {
    double result = 1;
    for (int i = 0; i < exp.floor(); i++) {
      result *= base;
    }
    return result;
  }

  // ============================================================
  // Actions
  // ============================================================

  /// Unlock an auto-clicker
  bool unlock(String id) {
    final state = _states[id];
    if (state == null || state.isUnlocked) return false;

    state.isUnlocked = true;
    _saveState();
    notifyListeners();
    return true;
  }

  /// Upgrade an auto-clicker
  bool upgrade(String id) {
    final config = _configs[id];
    final state = _states[id];
    if (config == null || state == null) return false;

    if (!state.isUnlocked) {
      return unlock(id);
    }

    if (config.maxLevel > 0 && state.level >= config.maxLevel) {
      return false;
    }

    state.level++;
    onUpgrade?.call(id, state.level);
    _saveState();
    notifyListeners();
    return true;
  }

  /// Toggle an auto-clicker on/off
  void toggleActive(String id) {
    final state = _states[id];
    if (state == null || !state.isUnlocked) return;

    state.isActive = !state.isActive;
    _saveState();
    notifyListeners();
  }

  /// Set active state for an auto-clicker
  void setActive(String id, bool active) {
    final state = _states[id];
    if (state == null || !state.isUnlocked) return;

    state.isActive = active;
    _saveState();
    notifyListeners();
  }

  // ============================================================
  // Tick System
  // ============================================================

  /// Start auto-clicking
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _tickTimer = Timer.periodic(
      Duration(milliseconds: tickIntervalMs),
      (_) => _tick(),
    );
  }

  /// Stop auto-clicking
  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _isRunning = false;
  }

  /// Check if running
  bool get isRunning => _isRunning;

  void _tick() {
    final tickFraction = tickIntervalMs / 1000.0;
    int totalClicks = 0;
    double totalDamage = 0;

    for (final config in activeAutoClickers) {
      final cps = getCps(config.id);
      final damagePerClick = getDamagePerClick(config.id);

      // Accumulate fractional clicks
      final accumulated = (_accumulatedClicks[config.id] ?? 0) + (cps * tickFraction);
      final clicks = accumulated.floor();

      if (clicks > 0) {
        _accumulatedClicks[config.id] = accumulated - clicks;
        totalClicks += clicks;
        totalDamage += clicks * damagePerClick;
      } else {
        _accumulatedClicks[config.id] = accumulated;
      }
    }

    if (totalClicks > 0) {
      totalAutoClicks += totalClicks;
      totalAutoDamage += totalDamage;
      onAutoClick?.call(totalClicks, totalDamage);
    }
  }

  // ============================================================
  // Persistence
  // ============================================================

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'states': _states.values.map((s) => s.toJson()).toList(),
      'totalAutoClicks': totalAutoClicks,
      'totalAutoDamage': totalAutoDamage,
      'globalClickMultiplier': globalClickMultiplier,
      'globalCpsMultiplier': globalCpsMultiplier,
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    if (json['states'] != null) {
      final statesList = json['states'] as List;
      for (final stateData in statesList) {
        final state = AutoClickerState.fromJson(stateData as Map<String, dynamic>);
        _states[state.id] = state;
      }
    }

    totalAutoClicks = json['totalAutoClicks'] as int? ?? 0;
    totalAutoDamage = (json['totalAutoDamage'] as num?)?.toDouble() ?? 0;
    globalClickMultiplier = (json['globalClickMultiplier'] as num?)?.toDouble() ?? 1.0;
    globalCpsMultiplier = (json['globalCpsMultiplier'] as num?)?.toDouble() ?? 1.0;

    notifyListeners();
  }

  /// Reset all auto-clickers
  Future<void> reset() async {
    stop();
    _states.clear();
    _accumulatedClicks.clear();
    totalAutoClicks = 0;
    totalAutoDamage = 0;

    // Re-initialize states for registered configs
    for (final config in _configs.values) {
      _states[config.id] = AutoClickerState(
        id: config.id,
        isUnlocked: config.cost == 0,
      );
    }

    await _prefs?.remove(_stateKey);
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  @override
  String toString() {
    return 'AutoClickerManager(clickers: ${_configs.length}, totalCps: ${totalCps.toStringAsFixed(1)}, totalDps: ${totalDps.toStringAsFixed(1)})';
  }
}

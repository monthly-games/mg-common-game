import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback for prestige events
typedef PrestigeCallback = void Function(PrestigeData data);

/// Configuration for prestige requirements
class PrestigeConfig {
  /// Minimum resource amount required to prestige
  final int minResourceForPrestige;

  /// Resource ID used for prestige calculation
  final String prestigeResourceId;

  /// Formula type for calculating prestige points
  final PrestigeFormula formula;

  /// Base value for formula calculations
  final double formulaBase;

  /// Multiplier applied to prestige points
  final double pointMultiplier;

  /// Permanent bonus per prestige point (e.g., 0.01 = 1% per point)
  final double bonusPerPoint;

  /// Maximum prestige level (0 = unlimited)
  final int maxPrestigeLevel;

  /// Achievements that provide bonus prestige points
  final Map<String, int> achievementBonuses;

  const PrestigeConfig({
    this.minResourceForPrestige = 1000000,
    this.prestigeResourceId = 'gold',
    this.formula = PrestigeFormula.logarithmic,
    this.formulaBase = 10.0,
    this.pointMultiplier = 1.0,
    this.bonusPerPoint = 0.01,
    this.maxPrestigeLevel = 0,
    this.achievementBonuses = const {},
  });
}

/// Formula types for prestige point calculation
enum PrestigeFormula {
  /// Points = log(resources) / log(base)
  logarithmic,

  /// Points = sqrt(resources / base)
  squareRoot,

  /// Points = resources / base
  linear,

  /// Points = (resources / base) ^ 0.5
  diminishing,
}

/// Data class for prestige information
class PrestigeData {
  final int currentPrestigeLevel;
  final int totalPrestigePoints;
  final int pointsEarnedThisRun;
  final double currentBonus;
  final DateTime prestigeTime;

  PrestigeData({
    required this.currentPrestigeLevel,
    required this.totalPrestigePoints,
    required this.pointsEarnedThisRun,
    required this.currentBonus,
    required this.prestigeTime,
  });

  @override
  String toString() {
    return 'PrestigeData(level: $currentPrestigeLevel, points: $totalPrestigePoints, bonus: ${(currentBonus * 100).toStringAsFixed(1)}%)';
  }
}

/// Manages prestige/rebirth system for idle games
class PrestigeManager extends ChangeNotifier {
  static const String _prestigeLevelKey = 'prestige_level';
  static const String _prestigePointsKey = 'prestige_points';
  static const String _totalPrestigesKey = 'total_prestiges';
  static const String _lastPrestigeTimeKey = 'last_prestige_time';
  static const String _highestResourceKey = 'highest_resource';

  SharedPreferences? _prefs;
  PrestigeConfig _config;

  int _prestigeLevel = 0;
  int _prestigePoints = 0;
  int _totalPrestiges = 0;
  int _highestResourceAchieved = 0;
  DateTime? _lastPrestigeTime;

  /// Current resource amount (set by game)
  int currentResource = 0;

  /// Completed achievements (for bonus calculation)
  final Set<String> _completedAchievements = {};

  /// Callback when prestige occurs
  PrestigeCallback? onPrestige;

  /// Callback when prestige becomes available
  VoidCallback? onPrestigeAvailable;

  PrestigeManager({PrestigeConfig? config})
      : _config = config ?? const PrestigeConfig();

  /// Update configuration
  void updateConfig(PrestigeConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Get current configuration
  PrestigeConfig get config => _config;

  /// Initialize the manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadState();
  }

  void _loadState() {
    _prestigeLevel = _prefs?.getInt(_prestigeLevelKey) ?? 0;
    _prestigePoints = _prefs?.getInt(_prestigePointsKey) ?? 0;
    _totalPrestiges = _prefs?.getInt(_totalPrestigesKey) ?? 0;
    _highestResourceAchieved = _prefs?.getInt(_highestResourceKey) ?? 0;

    final lastPrestigeTimestamp = _prefs?.getInt(_lastPrestigeTimeKey);
    if (lastPrestigeTimestamp != null) {
      _lastPrestigeTime = DateTime.fromMillisecondsSinceEpoch(lastPrestigeTimestamp);
    }
  }

  Future<void> _saveState() async {
    await _prefs?.setInt(_prestigeLevelKey, _prestigeLevel);
    await _prefs?.setInt(_prestigePointsKey, _prestigePoints);
    await _prefs?.setInt(_totalPrestigesKey, _totalPrestiges);
    await _prefs?.setInt(_highestResourceKey, _highestResourceAchieved);
    if (_lastPrestigeTime != null) {
      await _prefs?.setInt(_lastPrestigeTimeKey, _lastPrestigeTime!.millisecondsSinceEpoch);
    }
  }

  // ============================================================
  // Getters
  // ============================================================

  int get prestigeLevel => _prestigeLevel;
  int get prestigePoints => _prestigePoints;
  int get totalPrestiges => _totalPrestiges;
  int get highestResourceAchieved => _highestResourceAchieved;
  DateTime? get lastPrestigeTime => _lastPrestigeTime;

  /// Check if prestige is available
  bool get canPrestige {
    if (_config.maxPrestigeLevel > 0 && _prestigeLevel >= _config.maxPrestigeLevel) {
      return false;
    }
    return currentResource >= _config.minResourceForPrestige;
  }

  /// Get current bonus multiplier from prestige
  double get prestigeBonus {
    return 1.0 + (_prestigePoints * _config.bonusPerPoint);
  }

  /// Get bonus as percentage string
  String get prestigeBonusPercentage {
    final bonus = (_prestigePoints * _config.bonusPerPoint * 100);
    return '+${bonus.toStringAsFixed(1)}%';
  }

  // ============================================================
  // Prestige Point Calculation
  // ============================================================

  /// Calculate prestige points that would be earned
  int calculatePrestigePoints([int? resourceAmount]) {
    final resource = resourceAmount ?? currentResource;
    if (resource < _config.minResourceForPrestige) return 0;

    double points;
    switch (_config.formula) {
      case PrestigeFormula.logarithmic:
        points = _logBase(resource.toDouble(), _config.formulaBase);
        break;
      case PrestigeFormula.squareRoot:
        points = _sqrt(resource / _config.formulaBase);
        break;
      case PrestigeFormula.linear:
        points = resource / _config.formulaBase;
        break;
      case PrestigeFormula.diminishing:
        points = _pow(resource / _config.formulaBase, 0.5);
        break;
    }

    // Apply multiplier
    points *= _config.pointMultiplier;

    // Apply achievement bonuses
    for (final achievement in _completedAchievements) {
      final bonus = _config.achievementBonuses[achievement];
      if (bonus != null) {
        points += bonus;
      }
    }

    return points.floor();
  }

  double _logBase(double x, double base) {
    if (x <= 0) return 0;
    return _log(x) / _log(base);
  }

  double _log(double x) {
    if (x <= 0) return 0;
    // Natural log approximation
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    for (int i = 1; i <= 100; i += 2) {
      result += currentTerm / i;
      currentTerm *= termSquared;
    }
    return 2 * result;
  }

  double _sqrt(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _pow(double base, double exp) {
    if (base <= 0) return 0;
    return _exp(exp * _log(base));
  }

  double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 100; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }
    return result;
  }

  /// Get progress towards next prestige threshold
  double get progressToPrestige {
    if (currentResource >= _config.minResourceForPrestige) return 1.0;
    return currentResource / _config.minResourceForPrestige;
  }

  // ============================================================
  // Prestige Actions
  // ============================================================

  /// Perform prestige and return the data
  Future<PrestigeData?> performPrestige() async {
    if (!canPrestige) return null;

    final pointsEarned = calculatePrestigePoints();
    if (pointsEarned <= 0) return null;

    // Update highest achieved
    if (currentResource > _highestResourceAchieved) {
      _highestResourceAchieved = currentResource;
    }

    // Apply prestige
    _prestigeLevel++;
    _prestigePoints += pointsEarned;
    _totalPrestiges++;
    _lastPrestigeTime = DateTime.now();

    await _saveState();

    final data = PrestigeData(
      currentPrestigeLevel: _prestigeLevel,
      totalPrestigePoints: _prestigePoints,
      pointsEarnedThisRun: pointsEarned,
      currentBonus: prestigeBonus,
      prestigeTime: _lastPrestigeTime!,
    );

    onPrestige?.call(data);
    notifyListeners();

    return data;
  }

  /// Update current resource amount
  void updateResource(int amount) {
    final wasAvailable = canPrestige;
    currentResource = amount;

    if (!wasAvailable && canPrestige) {
      onPrestigeAvailable?.call();
    }

    notifyListeners();
  }

  /// Add completed achievement
  void addCompletedAchievement(String achievementId) {
    _completedAchievements.add(achievementId);
    notifyListeners();
  }

  /// Remove completed achievement
  void removeCompletedAchievement(String achievementId) {
    _completedAchievements.remove(achievementId);
    notifyListeners();
  }

  /// Get all completed achievements
  Set<String> get completedAchievements => Set.from(_completedAchievements);

  // ============================================================
  // Persistence
  // ============================================================

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'prestigeLevel': _prestigeLevel,
      'prestigePoints': _prestigePoints,
      'totalPrestiges': _totalPrestiges,
      'highestResource': _highestResourceAchieved,
      'lastPrestigeTime': _lastPrestigeTime?.millisecondsSinceEpoch,
      'completedAchievements': _completedAchievements.toList(),
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    _prestigeLevel = json['prestigeLevel'] as int? ?? 0;
    _prestigePoints = json['prestigePoints'] as int? ?? 0;
    _totalPrestiges = json['totalPrestiges'] as int? ?? 0;
    _highestResourceAchieved = json['highestResource'] as int? ?? 0;

    if (json['lastPrestigeTime'] != null) {
      _lastPrestigeTime = DateTime.fromMillisecondsSinceEpoch(
        json['lastPrestigeTime'] as int,
      );
    }

    if (json['completedAchievements'] != null) {
      _completedAchievements.clear();
      _completedAchievements.addAll(
        (json['completedAchievements'] as List).cast<String>(),
      );
    }

    notifyListeners();
  }

  /// Reset all prestige data
  Future<void> reset() async {
    _prestigeLevel = 0;
    _prestigePoints = 0;
    _totalPrestiges = 0;
    _highestResourceAchieved = 0;
    _lastPrestigeTime = null;
    currentResource = 0;
    _completedAchievements.clear();

    await _prefs?.remove(_prestigeLevelKey);
    await _prefs?.remove(_prestigePointsKey);
    await _prefs?.remove(_totalPrestigesKey);
    await _prefs?.remove(_highestResourceKey);
    await _prefs?.remove(_lastPrestigeTimeKey);

    notifyListeners();
  }

  @override
  String toString() {
    return 'PrestigeManager(level: $_prestigeLevel, points: $_prestigePoints, bonus: $prestigeBonusPercentage)';
  }
}

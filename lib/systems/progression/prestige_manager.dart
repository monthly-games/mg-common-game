import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/systems/save_manager.dart';

/// Represents a prestige upgrade that can be purchased with prestige points
class PrestigeUpgrade {
  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final int costPerLevel; // Fixed cost per level (simpler than exponential)
  final double bonusPerLevel; // Bonus multiplier per level (e.g., 0.1 = 10% per level)

  int _currentLevel = 0;

  PrestigeUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.costPerLevel,
    required this.bonusPerLevel,
  });

  int get currentLevel => _currentLevel;

  int get costForNextLevel {
    if (_currentLevel >= maxLevel) return -1;
    return costPerLevel;
  }

  /// Returns the total bonus multiplier (1.0 + level * bonusPerLevel)
  /// Example: level 3 with 0.1 bonus = 1.3x multiplier
  double get totalMultiplier => 1.0 + (_currentLevel * bonusPerLevel);

  void levelUp() {
    if (_currentLevel < maxLevel) {
      _currentLevel++;
    }
  }

  void setLevel(int level) {
    _currentLevel = level.clamp(0, maxLevel);
  }

  void reset() {
    _currentLevel = 0;
  }
}

/// Manages prestige system: levels, points, and prestige upgrades
class PrestigeManager extends ChangeNotifier implements Saveable {
  @override
  String get saveKey => 'prestige';
  int _prestigeLevel = 0;
  int _prestigePoints = 0;
  final Map<String, PrestigeUpgrade> _prestigeUpgrades = {};

  int get prestigeLevel => _prestigeLevel;
  int get prestigePoints => _prestigePoints;

  List<PrestigeUpgrade> get allPrestigeUpgrades =>
      _prestigeUpgrades.values.toList();

  void registerPrestigeUpgrade(PrestigeUpgrade upgrade) {
    _prestigeUpgrades[upgrade.id] = upgrade;
  }

  PrestigeUpgrade? getPrestigeUpgrade(String id) => _prestigeUpgrades[id];

  /// Calculate prestige points earned based on player level
  /// Formula: floor(level / 10) to encourage higher level play
  /// Example: Level 50 = 5 points, Level 100 = 10 points
  int calculatePrestigePoints(int playerLevel) {
    return (playerLevel / 10).floor();
  }

  /// Perform prestige: gain points, increment prestige level
  /// Returns the number of points earned
  int performPrestige(int playerLevel) {
    final pointsEarned = calculatePrestigePoints(playerLevel);
    if (pointsEarned <= 0) return 0;

    _prestigeLevel++;
    _prestigePoints += pointsEarned;
    notifyListeners();

    // Auto-save after prestige
    savePrestigeData();

    return pointsEarned;
  }

  /// Add prestige points directly (e.g., from weekly challenges)
  void addPrestigePoints(int points) {
    if (points <= 0) return;
    _prestigePoints += points;
    notifyListeners();
    savePrestigeData();
  }

  /// Check if player can afford a prestige upgrade
  bool canAffordPrestigeUpgrade(String id) {
    final upgrade = _prestigeUpgrades[id];
    if (upgrade == null) return false;
    final cost = upgrade.costForNextLevel;
    return cost != -1 && _prestigePoints >= cost;
  }

  /// Purchase a prestige upgrade with prestige points
  /// Returns true if successful
  bool purchasePrestigeUpgrade(String id) {
    final upgrade = _prestigeUpgrades[id];
    if (upgrade == null) return false;

    final cost = upgrade.costForNextLevel;
    if (cost == -1) return false; // Max level

    if (_prestigePoints >= cost) {
      _prestigePoints -= cost;
      upgrade.levelUp();
      notifyListeners();

      // Auto-save after purchase
      savePrestigeData();

      return true;
    }
    return false;
  }

  /// Get the combined multiplier from a specific prestige upgrade
  double getPrestigeMultiplier(String id) {
    return _prestigeUpgrades[id]?.totalMultiplier ?? 1.0;
  }

  /// Calculate total XP multiplier from all relevant prestige upgrades
  /// Prestige upgrades stack additively, then multiply
  double getTotalXpMultiplier() {
    double totalBonus = 0.0;
    for (final upgrade in _prestigeUpgrades.values) {
      if (upgrade.id.contains('xp')) {
        totalBonus += upgrade.currentLevel * upgrade.bonusPerLevel;
      }
    }
    return 1.0 + totalBonus;
  }

  /// Calculate total gold/income multiplier
  double getTotalGoldMultiplier() {
    double totalBonus = 0.0;
    for (final upgrade in _prestigeUpgrades.values) {
      if (upgrade.id.contains('gold') || upgrade.id.contains('income')) {
        totalBonus += upgrade.currentLevel * upgrade.bonusPerLevel;
      }
    }
    return 1.0 + totalBonus;
  }

  /// For save/load
  void setPrestigeLevel(int level) {
    _prestigeLevel = level;
    notifyListeners();
  }

  void setPrestigePoints(int points) {
    _prestigePoints = points;
    notifyListeners();
  }

  void setPrestigeUpgradeLevel(String id, int level) {
    _prestigeUpgrades[id]?.setLevel(level);
    notifyListeners();
  }

  /// Full reset (for testing or special cases)
  void reset() {
    _prestigeLevel = 0;
    _prestigePoints = 0;
    for (final upgrade in _prestigeUpgrades.values) {
      upgrade.reset();
    }
    notifyListeners();
  }

  // ========== SAVE/LOAD SYSTEM ==========

  /// Save prestige data to SharedPreferences
  Future<void> savePrestigeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save prestige level and points
    await prefs.setInt('prestige_level', _prestigeLevel);
    await prefs.setInt('prestige_points', _prestigePoints);

    // Save each prestige upgrade level
    for (final upgrade in _prestigeUpgrades.values) {
      await prefs.setInt('prestige_upgrade_${upgrade.id}', upgrade.currentLevel);
    }
  }

  /// Load prestige data from SharedPreferences
  Future<void> loadPrestigeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load prestige level and points
    _prestigeLevel = prefs.getInt('prestige_level') ?? 0;
    _prestigePoints = prefs.getInt('prestige_points') ?? 0;

    // Load each prestige upgrade level
    for (final upgrade in _prestigeUpgrades.values) {
      final level = prefs.getInt('prestige_upgrade_${upgrade.id}') ?? 0;
      upgrade.setLevel(level);
    }

    notifyListeners();
  }

  /// Clear all prestige data from SharedPreferences (for reset)
  Future<void> clearPrestigeData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('prestige_level');
    await prefs.remove('prestige_points');

    for (final upgrade in _prestigeUpgrades.values) {
      await prefs.remove('prestige_upgrade_${upgrade.id}');
    }
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    final upgradesData = <String, dynamic>{};
    for (final upgrade in _prestigeUpgrades.values) {
      upgradesData[upgrade.id] = upgrade.currentLevel;
    }

    return {
      'level': _prestigeLevel,
      'points': _prestigePoints,
      'upgrades': upgradesData,
    };
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    _prestigeLevel = data['level'] as int? ?? 0;
    _prestigePoints = data['points'] as int? ?? 0;

    final upgradesData = data['upgrades'] as Map<String, dynamic>?;
    if (upgradesData != null) {
      for (final entry in upgradesData.entries) {
        final upgrade = _prestigeUpgrades[entry.key];
        if (upgrade != null) {
          upgrade.setLevel(entry.value as int? ?? 0);
        }
      }
    }

    notifyListeners();
  }
}

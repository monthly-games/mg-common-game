import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/systems/save_manager.dart';

class Upgrade {
  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final int baseCost;
  final double costMultiplier;
  final double valuePerLevel; // e.g., 0.1 for 10% increase per level

  int _currentLevel = 0;

  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
    this.costMultiplier = 1.5,
    required this.valuePerLevel,
  });

  int get currentLevel => _currentLevel;

  int get costForNextLevel {
    if (_currentLevel >= maxLevel) return -1;
    return (baseCost * matchPower(costMultiplier, _currentLevel)).round();
  }

  double get currentValue => _currentLevel * valuePerLevel;

  void levelUp() {
    if (_currentLevel < maxLevel) {
      _currentLevel++;
    }
  }

  void setLevel(int level) {
    _currentLevel = level.clamp(0, maxLevel);
  }

  // Helper for power calculation without dart:math import issues in some contexts
  // or just use dart:math if available. Importing it here.
  static double matchPower(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

class UpgradeManager extends ChangeNotifier implements Saveable {
  @override
  String get saveKey => 'upgrades';
  final Map<String, Upgrade> _upgrades = {};

  List<Upgrade> get allUpgrades => _upgrades.values.toList();

  void registerUpgrade(Upgrade upgrade) {
    _upgrades[upgrade.id] = upgrade;
  }

  Upgrade? getUpgrade(String id) => _upgrades[id];

  bool canAfford(String id, int currency) {
    final upgrade = _upgrades[id];
    if (upgrade == null) return false;
    final cost = upgrade.costForNextLevel;
    return cost != -1 && currency >= cost;
  }

  /// Returns true if purchase successful
  bool purchaseUpgrade(
      String id, int Function() getCurrency, Function(int) spendCurrency) {
    final upgrade = _upgrades[id];
    if (upgrade == null) return false;

    final cost = upgrade.costForNextLevel;
    if (cost == -1) return false; // Max level

    if (getCurrency() >= cost) {
      spendCurrency(cost);
      upgrade.levelUp();
      notifyListeners();
      return true;
    }
    return false;
  }

  // For loading saves
  void setUpgradeLevel(String id, int level) {
    _upgrades[id]?.setLevel(level);
    notifyListeners();
  }

  // ========== LEGACY SAVE/LOAD SYSTEM ==========

  Future<void> saveUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    for (final upgrade in _upgrades.values) {
      await prefs.setInt('upgrade_${upgrade.id}', upgrade.currentLevel);
    }
  }

  Future<void> loadUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    for (final upgrade in _upgrades.values) {
      final level = prefs.getInt('upgrade_${upgrade.id}') ?? 0;
      upgrade.setLevel(level);
    }
    notifyListeners();
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    final levelsData = <String, dynamic>{};
    for (final upgrade in _upgrades.values) {
      levelsData[upgrade.id] = upgrade.currentLevel;
    }
    return levelsData;
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final upgrade = _upgrades[entry.key];
      if (upgrade != null) {
        upgrade.setLevel(entry.value as int? ?? 0);
      }
    }
    notifyListeners();
  }
}

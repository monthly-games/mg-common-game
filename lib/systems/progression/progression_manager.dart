import 'package:flutter/foundation.dart';
import 'prestige_manager.dart';
import '../../core/systems/save_manager.dart';

class ProgressionManager extends ChangeNotifier implements Saveable {
  @override
  String get saveKey => 'progression';
  int _currentLevel = 1;
  int _currentXp = 0;

  // Base XP needed for level 1 -> 2
  final int _baseXp = 100;
  // Growth factor for XP requirements
  final double _growthFactor = 1.5;

  // Optional prestige manager for XP multiplier
  PrestigeManager? _prestigeManager;

  // Callback for level up events (useful for haptic feedback, etc.)
  void Function(int newLevel)? onLevelUp;

  int get currentLevel => _currentLevel;
  int get currentXp => _currentXp;

  int get xpToNextLevel {
    return (_baseXp * (_currentLevel * _growthFactor)).round();
  }

  /// Set prestige manager to enable XP multiplier bonuses
  void setPrestigeManager(PrestigeManager prestigeManager) {
    _prestigeManager = prestigeManager;
  }

  void addXp(int amount) {
    if (amount <= 0) return;

    // Apply prestige XP multiplier if available
    final multiplier = _prestigeManager?.getTotalXpMultiplier() ?? 1.0;
    final adjustedAmount = (amount * multiplier).round();

    _currentXp += adjustedAmount;

    // Check for level up(s)
    while (_currentXp >= xpToNextLevel) {
      _currentXp -= xpToNextLevel;
      _currentLevel++;
      // Trigger level up callback
      onLevelUp?.call(_currentLevel);
      notifyListeners();
    }
    notifyListeners();
  }

  void setLevel(int level, int xp) {
    _currentLevel = level;
    _currentXp = xp;
    notifyListeners();
  }

  void reset() {
    _currentLevel = 1;
    _currentXp = 0;
    notifyListeners();
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    return {
      'level': _currentLevel,
      'xp': _currentXp,
    };
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    _currentLevel = data['level'] as int? ?? 1;
    _currentXp = data['xp'] as int? ?? 0;
    notifyListeners();
  }
}

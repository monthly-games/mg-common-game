import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../systems/save_manager.dart';

@singleton
class GoldManager implements Saveable {
  @override
  String get saveKey => 'gold';
  int _currentGold = 0;
  final _goldController = StreamController<int>.broadcast();

  // Optional prestige manager for gold multiplier
  PrestigeManager? _prestigeManager;

  int get currentGold => _currentGold;
  Stream<int> get onGoldChanged => _goldController.stream;

  /// Set prestige manager to enable gold multiplier bonuses
  void setPrestigeManager(PrestigeManager prestigeManager) {
    _prestigeManager = prestigeManager;
  }

  void addGold(int amount) {
    if (amount <= 0) return;

    // Apply prestige gold multiplier if available
    final multiplier = _prestigeManager?.getTotalGoldMultiplier() ?? 1.0;
    final adjustedAmount = (amount * multiplier).round();

    _currentGold += adjustedAmount;
    _goldController.add(_currentGold);
  }

  bool trySpendGold(int amount) {
    if (amount <= 0) return false;
    if (_currentGold >= amount) {
      _currentGold -= amount;
      _goldController.add(_currentGold);
      return true;
    }
    return false;
  }

  void dispose() {
    _goldController.close();
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    return {
      'amount': _currentGold,
    };
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    _currentGold = data['amount'] as int? ?? 0;
    _goldController.add(_currentGold);
  }
}

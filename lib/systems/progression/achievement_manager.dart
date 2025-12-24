import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/systems/save_manager.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final bool hidden;

  bool _unlocked = false;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    this.hidden = false,
  });

  bool get unlocked => _unlocked;

  void unlock() {
    _unlocked = true;
  }

  void lock() {
    _unlocked = false;
  }
}

class AchievementManager extends ChangeNotifier implements Saveable {
  @override
  String get saveKey => 'achievements';
  final Map<String, Achievement> _achievements = {};

  // Callback for achievement unlock events (useful for haptic feedback, etc.)
  void Function(Achievement achievement)? onAchievementUnlocked;

  List<Achievement> get allAchievements => _achievements.values.toList();
  List<Achievement> get unlockedAchievements =>
      _achievements.values.where((a) => a.unlocked).toList();

  /// Total number of achievements
  int get totalCount => _achievements.length;

  /// Number of unlocked achievements
  int get unlockedCount => _achievements.values.where((a) => a.unlocked).length;

  void registerAchievement(Achievement achievement) {
    _achievements[achievement.id] = achievement;
  }

  bool isUnlocked(String id) {
    return _achievements[id]?.unlocked ?? false;
  }

  /// Returns true if newly unlocked
  bool unlock(String id) {
    final achievement = _achievements[id];
    if (achievement != null && !achievement.unlocked) {
      achievement.unlock();
      // Trigger achievement unlock callback
      onAchievementUnlocked?.call(achievement);
      notifyListeners();
      return true;
    }
    return false;
  }

  // For loading saves
  void setUnlocked(String id, bool unlocked) {
    if (unlocked) {
      _achievements[id]?.unlock();
    } else {
      _achievements[id]?.lock();
    }
    notifyListeners();
  }

  // ========== LEGACY SAVE/LOAD SYSTEM ==========

  Future<void> saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (final achievement in _achievements.values) {
      await prefs.setBool('achievement_${achievement.id}', achievement.unlocked);
    }
  }

  Future<void> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (final achievement in _achievements.values) {
      final unlocked = prefs.getBool('achievement_${achievement.id}') ?? false;
      if (unlocked) {
        achievement.unlock();
      }
    }
    notifyListeners();
  }

  // ========== SAVEABLE IMPLEMENTATION ==========

  @override
  Map<String, dynamic> toSaveData() {
    final unlockedList = <String>[];
    for (final achievement in _achievements.values) {
      if (achievement.unlocked) {
        unlockedList.add(achievement.id);
      }
    }
    return {
      'unlocked': unlockedList.join(','),
    };
  }

  @override
  void fromSaveData(Map<String, dynamic> data) {
    final unlockedString = data['unlocked'] as String? ?? '';
    final unlockedIds = unlockedString.isEmpty ? <String>[] : unlockedString.split(',');

    for (final achievement in _achievements.values) {
      if (unlockedIds.contains(achievement.id)) {
        achievement.unlock();
      } else {
        achievement.lock();
      }
    }

    notifyListeners();
  }
}

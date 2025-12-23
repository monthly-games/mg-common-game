import 'package:get_it/get_it.dart';
import 'save_manager.dart';
import '../../systems/progression/progression_manager.dart';
import '../../systems/progression/prestige_manager.dart';
import '../../systems/progression/achievement_manager.dart';
import '../../systems/progression/upgrade_manager.dart';
import '../../systems/quests/daily_quest.dart';
import '../../systems/stats/statistics_manager.dart';
import '../../systems/settings/settings_manager.dart';
import '../../core/economy/gold_manager.dart';

/// Helper class for setting up SaveManager with common game systems
class SaveManagerHelper {
  /// Register and initialize SaveManager with all registered game systems
  ///
  /// This automatically detects which systems are registered in GetIt
  /// and adds them to SaveManager if they implement Saveable.
  static Future<void> setupSaveManager({
    bool autoSaveEnabled = true,
    int autoSaveIntervalSeconds = 30,
  }) async {
    if (!GetIt.I.isRegistered<SaveManager>()) {
      final saveManager = SaveManager();
      GetIt.I.registerSingleton(saveManager);

      // Configure auto-save
      saveManager.setAutoSaveEnabled(autoSaveEnabled);
      saveManager.setAutoSaveInterval(autoSaveIntervalSeconds);
    }

    final saveManager = GetIt.I<SaveManager>();

    // Register all Saveable systems that are already in GetIt
    if (GetIt.I.isRegistered<ProgressionManager>()) {
      saveManager.registerSaveable(GetIt.I<ProgressionManager>());
    }

    if (GetIt.I.isRegistered<PrestigeManager>()) {
      saveManager.registerSaveable(GetIt.I<PrestigeManager>());
    }

    if (GetIt.I.isRegistered<AchievementManager>()) {
      saveManager.registerSaveable(GetIt.I<AchievementManager>());
    }

    if (GetIt.I.isRegistered<UpgradeManager>()) {
      saveManager.registerSaveable(GetIt.I<UpgradeManager>());
    }

    if (GetIt.I.isRegistered<GoldManager>()) {
      saveManager.registerSaveable(GetIt.I<GoldManager>());
    }

    // Load all data
    await saveManager.loadAll();

    // Start auto-save
    if (autoSaveEnabled) {
      saveManager.setAutoSaveEnabled(true);
    }
  }

  /// Quick save all systems
  static Future<void> quickSave() async {
    if (GetIt.I.isRegistered<SaveManager>()) {
      await GetIt.I<SaveManager>().saveAll();
    }
  }

  /// Quick load all systems
  static Future<void> quickLoad() async {
    if (GetIt.I.isRegistered<SaveManager>()) {
      await GetIt.I<SaveManager>().loadAll();
    }
  }

  /// Legacy save all - calls individual system save methods
  /// Use this for backwards compatibility with systems that haven't migrated to SaveManager yet
  static Future<void> legacySaveAll() async {
    // Statistics Manager
    if (GetIt.I.isRegistered<StatisticsManager>()) {
      await GetIt.I<StatisticsManager>().saveStats();
    }

    // Settings Manager
    if (GetIt.I.isRegistered<SettingsManager>()) {
      await GetIt.I<SettingsManager>().saveSettings();
    }

    // Quest Manager
    if (GetIt.I.isRegistered<DailyQuestManager>()) {
      await GetIt.I<DailyQuestManager>().saveQuestData();
    }

    // Prestige Manager
    if (GetIt.I.isRegistered<PrestigeManager>()) {
      await GetIt.I<PrestigeManager>().savePrestigeData();
    }

    // Achievement Manager
    if (GetIt.I.isRegistered<AchievementManager>()) {
      await GetIt.I<AchievementManager>().saveAchievements();
    }

    // Upgrade Manager
    if (GetIt.I.isRegistered<UpgradeManager>()) {
      await GetIt.I<UpgradeManager>().saveUpgrades();
    }
  }

  /// Legacy load all - calls individual system load methods
  /// Use this for backwards compatibility with systems that haven't migrated to SaveManager yet
  static Future<void> legacyLoadAll() async {
    // Statistics Manager
    if (GetIt.I.isRegistered<StatisticsManager>()) {
      await GetIt.I<StatisticsManager>().loadStats();
    }

    // Settings Manager
    if (GetIt.I.isRegistered<SettingsManager>()) {
      await GetIt.I<SettingsManager>().loadSettings();
    }

    // Quest Manager
    if (GetIt.I.isRegistered<DailyQuestManager>()) {
      await GetIt.I<DailyQuestManager>().loadQuestData();
    }

    // Prestige Manager
    if (GetIt.I.isRegistered<PrestigeManager>()) {
      await GetIt.I<PrestigeManager>().loadPrestigeData();
    }

    // Achievement Manager
    if (GetIt.I.isRegistered<AchievementManager>()) {
      await GetIt.I<AchievementManager>().loadAchievements();
    }

    // Upgrade Manager
    if (GetIt.I.isRegistered<UpgradeManager>()) {
      await GetIt.I<UpgradeManager>().loadUpgrades();
    }
  }

  /// Save all using both new SaveManager and legacy methods
  /// Use this during transition period
  static Future<void> saveAllHybrid() async {
    await Future.wait([
      quickSave(),
      legacySaveAll(),
    ]);
  }

  /// Load all using both new SaveManager and legacy methods
  /// Use this during transition period
  static Future<void> loadAllHybrid() async {
    await Future.wait([
      quickLoad(),
      legacyLoadAll(),
    ]);
  }
}

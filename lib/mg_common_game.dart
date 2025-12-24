/// MG Common Game Library
///
/// Shared systems and utilities for MG games
library mg_common_game;

// Export all systems
export 'systems/systems.dart';
export 'core/systems/save_manager.dart';
export 'core/systems/save_manager_helper.dart';
export 'systems/crafting/crafting_manager.dart';
export 'systems/idle/idle_manager.dart';
export 'systems/inventory/inventory_manager.dart';
export 'systems/progression/progression_manager.dart';
export 'systems/progression/upgrade_manager.dart';
export 'systems/progression/achievement_manager.dart';
export 'systems/progression/prestige_manager.dart';
export 'systems/quests/daily_quest.dart';
export 'systems/quests/weekly_challenge.dart';
export 'systems/stats/statistics_manager.dart';
export 'systems/settings/settings_manager.dart';

// Gacha & BattlePass systems
export 'systems/gacha/gacha_pool.dart';
export 'systems/gacha/gacha_manager.dart';
export 'systems/battlepass/battlepass_config.dart';
export 'systems/battlepass/battlepass_manager.dart';

// UI Widgets
export 'core/ui/widgets/gacha/gacha.dart';
export 'core/ui/widgets/battlepass/battlepass.dart';

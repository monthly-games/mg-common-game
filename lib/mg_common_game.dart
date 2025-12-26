/// MG Common Game Library
///
/// Shared systems and utilities for MG games
library mg_common_game;

// Audio System
export 'core/audio/audio_manager.dart';
export 'core/audio/audio_settings.dart';

// Export all systems
export 'systems/systems.dart';
export 'core/systems/save_manager.dart';
export 'core/systems/save_manager_helper.dart';
export 'systems/crafting/crafting_manager.dart';
export 'systems/idle/idle.dart';
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

// Battle System
export 'systems/battle/battle.dart';

// Social System (Friends, Guilds, Raids, Leaderboards)
export 'systems/social/social.dart';

// Event System (Limited-time events, Campaigns)
export 'systems/events/events.dart';

// Shop System (In-game purchases, Bundles)
export 'systems/shop/shop.dart';

// UI Widgets
export 'core/ui/widgets/gacha/gacha.dart';
export 'core/ui/widgets/battlepass/battlepass.dart';

// UI System (mg_ui)
export 'core/ui/mg_ui.dart';

// Engine (Flame 기반)
export 'core/engine/mg_engine.dart';

// Optimization (Performance, Quality, Memory)
export 'core/optimization/mg_optimization.dart';

// Utilities
export 'core/utils/image_utils.dart';

// Localization System
export 'core/localization/localization.dart';

// Analytics System
export 'core/analytics/analytics.dart';

// Performance System
export 'core/performance/performance.dart';

// UI Animations
export 'ui/animations/animations.dart';

// Testing Utilities
export 'testing/testing.dart';

// Notification System
export 'core/notifications/notifications.dart';

// Cloud Save System
export 'core/cloud/cloud.dart';

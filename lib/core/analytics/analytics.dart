/// Analytics Module for MG-Games
/// Unified analytics and remote config across 52 games
///
/// Features:
/// - Firebase Analytics integration
/// - BigQuery export support
/// - Event batching and offline support
/// - Remote Config management
/// - A/B testing
///
/// Usage:
/// ```dart
/// final analytics = AnalyticsManager.getInstance('game_0037');
/// await analytics.initialize(AnalyticsConfig(
///   gameId: 'game_0037',
///   firebaseEnabled: true,
///   debugMode: true,
/// ));
///
/// // Log events
/// analytics.logLevelComplete(5, score: 1000, stars: 3);
/// analytics.logPurchase('coins_500', 0.99, 'USD');
///
/// // Remote config
/// final config = RemoteConfigManager.getInstance('game_0037');
/// await config.initialize(CasualGameDefaults.all);
/// final dailyCoins = config.getInt('daily_reward_coins');
/// ```

library analytics;

export 'analytics_manager.dart';
export 'remote_config.dart';
export 'analytics_events.dart';

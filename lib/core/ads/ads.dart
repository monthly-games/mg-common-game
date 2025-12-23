/// Ads Module for MG-Games
/// Unified advertising across 52 games with mediation support
///
/// Features:
/// - AdMob + MAX mediation
/// - Frequency control (cooldowns, daily limits)
/// - Auto-hide for paying users
/// - Revenue tracking
/// - A/B testing support
///
/// Usage:
/// ```dart
/// final ads = AdManager.getInstance('game_0037');
/// await ads.initialize(AdConfig.casualDefault('game_0037'));
///
/// // Show interstitial
/// if (await ads.showInterstitial()) {
///   print('Interstitial shown');
/// }
///
/// // Show rewarded
/// await ads.showRewarded(
///   unitId: 'rewarded_double',
///   onReward: (type, amount) {
///     player.addCoins(amount);
///   },
/// );
/// ```

library ads;

export 'models/ad_unit.dart';
export 'models/ad_config.dart';
export 'ad_manager.dart';
export 'frequency_controller.dart';

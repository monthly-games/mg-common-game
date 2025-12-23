/// Ad Configuration Model for MG-Games
/// Remote-configurable ad settings

import 'ad_unit.dart';

/// Ad configuration for a game
class AdConfig {
  /// Game ID
  final String gameId;

  /// Whether ads are enabled globally
  final bool adsEnabled;

  /// Whether interstitials are enabled
  final bool interstitialEnabled;

  /// Whether rewarded ads are enabled
  final bool rewardedEnabled;

  /// Whether banners are enabled
  final bool bannerEnabled;

  /// Interstitial cooldown (seconds)
  final int interstitialCooldown;

  /// Max interstitials per session
  final int maxInterstitialsPerSession;

  /// Max interstitials per day
  final int maxInterstitialsPerDay;

  /// Max rewarded per day
  final int maxRewardedPerDay;

  /// eCPM floor (USD) - below this, don't show
  final double ecpmFloor;

  /// Countries to disable ads (ISO 3166-1 alpha-2)
  final List<String> disabledCountries;

  /// Remove ads for paying users
  final bool hideAdsForPayers;

  /// Paying user threshold (USD)
  final double payerThreshold;

  /// A/B test group
  final String? abTestGroup;

  /// Mediation waterfall priority
  final List<AdNetwork> mediationPriority;

  AdConfig({
    required this.gameId,
    this.adsEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
    this.bannerEnabled = false,
    this.interstitialCooldown = 180,
    this.maxInterstitialsPerSession = 5,
    this.maxInterstitialsPerDay = 15,
    this.maxRewardedPerDay = 10,
    this.ecpmFloor = 0.5,
    this.disabledCountries = const [],
    this.hideAdsForPayers = true,
    this.payerThreshold = 0.99,
    this.abTestGroup,
    this.mediationPriority = const [
      AdNetwork.admob,
      AdNetwork.max,
      AdNetwork.unity,
      AdNetwork.meta,
    ],
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      gameId: json['gameId'] as String,
      adsEnabled: json['adsEnabled'] as bool? ?? true,
      interstitialEnabled: json['interstitialEnabled'] as bool? ?? true,
      rewardedEnabled: json['rewardedEnabled'] as bool? ?? true,
      bannerEnabled: json['bannerEnabled'] as bool? ?? false,
      interstitialCooldown: json['interstitialCooldown'] as int? ?? 180,
      maxInterstitialsPerSession: json['maxInterstitialsPerSession'] as int? ?? 5,
      maxInterstitialsPerDay: json['maxInterstitialsPerDay'] as int? ?? 15,
      maxRewardedPerDay: json['maxRewardedPerDay'] as int? ?? 10,
      ecpmFloor: (json['ecpmFloor'] as num?)?.toDouble() ?? 0.5,
      disabledCountries:
          (json['disabledCountries'] as List?)?.cast<String>() ?? [],
      hideAdsForPayers: json['hideAdsForPayers'] as bool? ?? true,
      payerThreshold: (json['payerThreshold'] as num?)?.toDouble() ?? 0.99,
      abTestGroup: json['abTestGroup'] as String?,
      mediationPriority: (json['mediationPriority'] as List?)
              ?.map((e) => AdNetwork.values.byName(e as String))
              .toList() ??
          [AdNetwork.admob],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'adsEnabled': adsEnabled,
      'interstitialEnabled': interstitialEnabled,
      'rewardedEnabled': rewardedEnabled,
      'bannerEnabled': bannerEnabled,
      'interstitialCooldown': interstitialCooldown,
      'maxInterstitialsPerSession': maxInterstitialsPerSession,
      'maxInterstitialsPerDay': maxInterstitialsPerDay,
      'maxRewardedPerDay': maxRewardedPerDay,
      'ecpmFloor': ecpmFloor,
      'disabledCountries': disabledCountries,
      'hideAdsForPayers': hideAdsForPayers,
      'payerThreshold': payerThreshold,
      'abTestGroup': abTestGroup,
      'mediationPriority': mediationPriority.map((e) => e.name).toList(),
    };
  }

  /// Default config for casual games
  static AdConfig casualDefault(String gameId) {
    return AdConfig(
      gameId: gameId,
      interstitialCooldown: 180,
      maxInterstitialsPerSession: 5,
      maxRewardedPerDay: 10,
      bannerEnabled: false,
    );
  }

  /// Default config for Level A games (less aggressive)
  static AdConfig levelADefault(String gameId) {
    return AdConfig(
      gameId: gameId,
      interstitialCooldown: 300, // 5 minutes
      maxInterstitialsPerSession: 3,
      maxRewardedPerDay: 5,
      bannerEnabled: false,
      ecpmFloor: 1.0, // Higher floor for premium audience
    );
  }

  /// Get default config for game number
  static AdConfig getDefault(int gameNumber) {
    final gameId = 'game_${gameNumber.toString().padLeft(4, '0')}';
    if (gameNumber >= 25 && gameNumber <= 36) {
      return levelADefault(gameId);
    }
    return casualDefault(gameId);
  }
}

/// Reward configuration for rewarded ads
class RewardConfig {
  /// Reward type identifier
  final String rewardType;

  /// Reward amount
  final int amount;

  /// Multiplier for premium users
  final double premiumMultiplier;

  /// Whether reward can be doubled by watching another ad
  final bool canDouble;

  RewardConfig({
    required this.rewardType,
    required this.amount,
    this.premiumMultiplier = 1.0,
    this.canDouble = false,
  });

  /// Standard reward configs
  static final coins100 = RewardConfig(
    rewardType: 'coins',
    amount: 100,
    canDouble: true,
  );

  static final energy5 = RewardConfig(
    rewardType: 'energy',
    amount: 5,
    canDouble: false,
  );

  static final extraLife = RewardConfig(
    rewardType: 'extra_life',
    amount: 1,
    canDouble: false,
  );

  static final doubleReward = RewardConfig(
    rewardType: 'multiplier',
    amount: 2, // 2x multiplier
    canDouble: false,
  );
}

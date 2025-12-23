/// Ad Unit Model for MG-Games
/// Defines ad unit configuration across 52 games

/// Ad type enumeration
enum AdType {
  /// Interstitial (full screen between sessions)
  interstitial,

  /// Rewarded video (opt-in for rewards)
  rewarded,

  /// Banner (persistent at bottom)
  banner,

  /// App open (on app launch)
  appOpen,

  /// Native (blended with UI)
  native,
}

/// Ad network/mediator
enum AdNetwork {
  /// Google AdMob
  admob,

  /// AppLovin MAX
  max,

  /// Unity Ads
  unity,

  /// Meta Audience Network
  meta,

  /// ironSource
  ironSource,

  /// Direct (house ads)
  direct,
}

/// Ad unit configuration
class AdUnit {
  /// Unique unit identifier
  final String unitId;

  /// Ad type
  final AdType type;

  /// Primary network
  final AdNetwork network;

  /// Platform-specific unit IDs
  final Map<String, String> platformIds;

  /// Game ID this unit belongs to
  final String gameId;

  /// Display name
  final String displayName;

  /// Placement identifier (for analytics)
  final String placement;

  /// Whether unit is enabled
  bool isEnabled;

  /// Floor price eCPM (USD)
  final double? floorEcpm;

  /// Custom targeting
  final Map<String, dynamic>? targeting;

  AdUnit({
    required this.unitId,
    required this.type,
    required this.network,
    required this.platformIds,
    required this.gameId,
    required this.displayName,
    required this.placement,
    this.isEnabled = true,
    this.floorEcpm,
    this.targeting,
  });

  /// Get platform ID for current platform
  String? getPlatformId(String platform) => platformIds[platform];

  /// Android unit ID
  String? get androidId => platformIds['android'];

  /// iOS unit ID
  String? get iosId => platformIds['ios'];

  factory AdUnit.fromJson(Map<String, dynamic> json) {
    return AdUnit(
      unitId: json['unitId'] as String,
      type: AdType.values.byName(json['type'] as String),
      network: AdNetwork.values.byName(json['network'] as String),
      platformIds: Map<String, String>.from(json['platformIds'] as Map),
      gameId: json['gameId'] as String,
      displayName: json['displayName'] as String,
      placement: json['placement'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      floorEcpm: (json['floorEcpm'] as num?)?.toDouble(),
      targeting: json['targeting'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'type': type.name,
      'network': network.name,
      'platformIds': platformIds,
      'gameId': gameId,
      'displayName': displayName,
      'placement': placement,
      'isEnabled': isEnabled,
      'floorEcpm': floorEcpm,
      'targeting': targeting,
    };
  }
}

/// Ad placement for different game contexts
class AdPlacement {
  /// Placement ID
  final String id;

  /// Display name
  final String name;

  /// Ad type for this placement
  final AdType type;

  /// Priority (higher = more important)
  final int priority;

  /// Trigger conditions
  final PlacementTrigger trigger;

  /// Cooldown in seconds (0 = no cooldown)
  final int cooldownSeconds;

  /// Max impressions per session (0 = unlimited)
  final int maxPerSession;

  /// Max impressions per day (0 = unlimited)
  final int maxPerDay;

  /// Required for reward
  final bool rewardRequired;

  AdPlacement({
    required this.id,
    required this.name,
    required this.type,
    this.priority = 5,
    required this.trigger,
    this.cooldownSeconds = 0,
    this.maxPerSession = 0,
    this.maxPerDay = 0,
    this.rewardRequired = false,
  });
}

/// Placement trigger type
enum PlacementTrigger {
  /// Manual trigger (user-initiated)
  manual,

  /// Session end
  sessionEnd,

  /// Level complete
  levelComplete,

  /// Game over
  gameOver,

  /// Menu navigation
  menuTransition,

  /// Feature unlock
  featureUnlock,

  /// Energy refill
  energyRefill,

  /// Reward doubling
  rewardDouble,

  /// Extra life/continue
  extraLife,

  /// Shop entry
  shopEntry,
}

/// Standard placements for casual games
class StandardPlacements {
  static final interstitialSessionEnd = AdPlacement(
    id: 'interstitial_session_end',
    name: 'Session End Interstitial',
    type: AdType.interstitial,
    trigger: PlacementTrigger.sessionEnd,
    cooldownSeconds: 180, // 3 minutes
    maxPerSession: 3,
    maxPerDay: 10,
  );

  static final rewardedDouble = AdPlacement(
    id: 'rewarded_double',
    name: 'Double Rewards',
    type: AdType.rewarded,
    trigger: PlacementTrigger.rewardDouble,
    rewardRequired: true,
    maxPerDay: 10,
  );

  static final rewardedEnergy = AdPlacement(
    id: 'rewarded_energy',
    name: 'Energy Refill',
    type: AdType.rewarded,
    trigger: PlacementTrigger.energyRefill,
    rewardRequired: true,
    cooldownSeconds: 1800, // 30 minutes
    maxPerDay: 5,
  );

  static final rewardedExtraLife = AdPlacement(
    id: 'rewarded_extra_life',
    name: 'Extra Life/Continue',
    type: AdType.rewarded,
    trigger: PlacementTrigger.extraLife,
    rewardRequired: true,
    maxPerDay: 10,
  );

  static final bannerBottom = AdPlacement(
    id: 'banner_bottom',
    name: 'Bottom Banner',
    type: AdType.banner,
    trigger: PlacementTrigger.manual,
    priority: 1,
  );

  /// Get all standard placements
  static List<AdPlacement> getAll() {
    return [
      interstitialSessionEnd,
      rewardedDouble,
      rewardedEnergy,
      rewardedExtraLife,
      bannerBottom,
    ];
  }
}

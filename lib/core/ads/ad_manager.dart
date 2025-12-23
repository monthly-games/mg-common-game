/// Ad Manager for MG-Games
/// Unified ad handling across 52 games with mediation support

import 'dart:async';

import 'models/ad_unit.dart';
import 'models/ad_config.dart';
import 'frequency_controller.dart';

/// Ad load state
enum AdLoadState {
  /// Not loaded
  notLoaded,

  /// Loading
  loading,

  /// Loaded and ready
  ready,

  /// Failed to load
  failed,
}

/// Ad event types
enum AdEventType {
  /// Ad loaded successfully
  loaded,

  /// Ad failed to load
  loadFailed,

  /// Ad shown
  shown,

  /// Ad failed to show
  showFailed,

  /// Ad clicked
  clicked,

  /// Ad closed
  closed,

  /// Reward earned (for rewarded)
  rewarded,

  /// Ad revenue reported
  revenueReported,
}

/// Ad event callback
typedef AdEventCallback = void Function(AdEventType event, Map<String, dynamic>? data);

/// Reward callback
typedef RewardCallback = void Function(String rewardType, int amount);

/// Ad Manager implementation
class AdManager {
  /// Singleton instances per game
  static final Map<String, AdManager> _instances = {};

  /// Get instance for game
  static AdManager getInstance(String gameId) {
    return _instances.putIfAbsent(gameId, () => AdManager._internal(gameId));
  }

  AdManager._internal(this.gameId);

  /// Game ID
  final String gameId;

  /// Configuration
  AdConfig? _config;

  /// Frequency controller
  final FrequencyController _frequencyController = FrequencyController();

  /// Ad units
  final Map<String, AdUnit> _adUnits = {};

  /// Load states
  final Map<String, AdLoadState> _loadStates = {};

  /// Event stream controller
  final StreamController<(AdEventType, Map<String, dynamic>?)> _eventController =
      StreamController<(AdEventType, Map<String, dynamic>?)>.broadcast();

  /// Event stream
  Stream<(AdEventType, Map<String, dynamic>?)> get eventStream =>
      _eventController.stream;

  /// Global event callback
  AdEventCallback? onAdEvent;

  /// Initialize Ad Manager
  Future<bool> initialize(AdConfig config) async {
    _config = config;
    _frequencyController.initialize(config);

    try {
      // Initialize ad networks
      await _initializeNetworks();

      // Register standard ad units
      _registerStandardUnits();

      // Preload ads
      await _preloadAds();

      return true;
    } catch (e) {
      _emitEvent(AdEventType.loadFailed, {'error': e.toString()});
      return false;
    }
  }

  /// Initialize ad networks (AdMob, MAX, etc.)
  Future<void> _initializeNetworks() async {
    // TODO: Initialize actual SDK
    // - AdMob: MobileAds.instance.initialize()
    // - MAX: AppLovinMAX.initialize()
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Register standard ad units for this game
  void _registerStandardUnits() {
    final gameNum = int.tryParse(gameId.replaceAll('game_', '')) ?? 0;
    final prefix = 'ca-app-pub-xxxxx/';

    // Interstitial
    registerAdUnit(AdUnit(
      unitId: 'interstitial_main',
      type: AdType.interstitial,
      network: AdNetwork.admob,
      platformIds: {
        'android': '$prefix${gameNum}0001',
        'ios': '$prefix${gameNum}0002',
      },
      gameId: gameId,
      displayName: 'Main Interstitial',
      placement: 'interstitial_session_end',
    ));

    // Rewarded - Double Reward
    registerAdUnit(AdUnit(
      unitId: 'rewarded_double',
      type: AdType.rewarded,
      network: AdNetwork.admob,
      platformIds: {
        'android': '$prefix${gameNum}0003',
        'ios': '$prefix${gameNum}0004',
      },
      gameId: gameId,
      displayName: 'Double Reward',
      placement: 'rewarded_double',
    ));

    // Rewarded - Energy
    registerAdUnit(AdUnit(
      unitId: 'rewarded_energy',
      type: AdType.rewarded,
      network: AdNetwork.admob,
      platformIds: {
        'android': '$prefix${gameNum}0005',
        'ios': '$prefix${gameNum}0006',
      },
      gameId: gameId,
      displayName: 'Energy Refill',
      placement: 'rewarded_energy',
    ));

    // Rewarded - Extra Life
    registerAdUnit(AdUnit(
      unitId: 'rewarded_extra_life',
      type: AdType.rewarded,
      network: AdNetwork.admob,
      platformIds: {
        'android': '$prefix${gameNum}0007',
        'ios': '$prefix${gameNum}0008',
      },
      gameId: gameId,
      displayName: 'Extra Life',
      placement: 'rewarded_extra_life',
    ));

    // Banner
    registerAdUnit(AdUnit(
      unitId: 'banner_bottom',
      type: AdType.banner,
      network: AdNetwork.admob,
      platformIds: {
        'android': '$prefix${gameNum}0009',
        'ios': '$prefix${gameNum}0010',
      },
      gameId: gameId,
      displayName: 'Bottom Banner',
      placement: 'banner_bottom',
    ));
  }

  /// Preload ads
  Future<void> _preloadAds() async {
    // Preload interstitial and first rewarded
    await loadAd('interstitial_main');
    await loadAd('rewarded_double');
  }

  /// Register an ad unit
  void registerAdUnit(AdUnit unit) {
    _adUnits[unit.unitId] = unit;
    _loadStates[unit.unitId] = AdLoadState.notLoaded;
  }

  /// Load an ad
  Future<bool> loadAd(String unitId) async {
    final unit = _adUnits[unitId];
    if (unit == null || !unit.isEnabled) {
      return false;
    }

    _loadStates[unitId] = AdLoadState.loading;

    try {
      // TODO: Load actual ad based on type and network
      // - Interstitial: InterstitialAd.load()
      // - Rewarded: RewardedAd.load()
      // - Banner: BannerAd.load()

      await Future.delayed(const Duration(milliseconds: 200));

      _loadStates[unitId] = AdLoadState.ready;
      _emitEvent(AdEventType.loaded, {'unitId': unitId, 'type': unit.type.name});
      return true;
    } catch (e) {
      _loadStates[unitId] = AdLoadState.failed;
      _emitEvent(AdEventType.loadFailed, {'unitId': unitId, 'error': e.toString()});
      return false;
    }
  }

  /// Check if ad is ready
  bool isAdReady(String unitId) {
    return _loadStates[unitId] == AdLoadState.ready;
  }

  /// Show interstitial ad
  Future<bool> showInterstitial({
    String unitId = 'interstitial_main',
    String? placement,
  }) async {
    final unit = _adUnits[unitId];
    if (unit == null || unit.type != AdType.interstitial) {
      return false;
    }

    // Check frequency
    final check = _frequencyController.canShowAd(
      placementId: placement ?? unit.placement,
      type: AdType.interstitial,
    );

    if (!check.canShow) {
      _emitEvent(AdEventType.showFailed, {
        'unitId': unitId,
        'reason': check.blockReason,
      });
      return false;
    }

    // Check if loaded
    if (!isAdReady(unitId)) {
      final loaded = await loadAd(unitId);
      if (!loaded) return false;
    }

    try {
      // TODO: Show actual ad
      await Future.delayed(const Duration(milliseconds: 100));

      // Record impression
      _frequencyController.recordImpression(
        placementId: placement ?? unit.placement,
        type: AdType.interstitial,
        revenue: 0.005, // Simulated eCPM $5
      );

      _loadStates[unitId] = AdLoadState.notLoaded;
      _emitEvent(AdEventType.shown, {'unitId': unitId, 'type': 'interstitial'});

      // Preload next
      loadAd(unitId);

      return true;
    } catch (e) {
      _emitEvent(AdEventType.showFailed, {'unitId': unitId, 'error': e.toString()});
      return false;
    }
  }

  /// Show rewarded ad
  Future<bool> showRewarded({
    required String unitId,
    required RewardCallback onReward,
    String? placement,
    RewardConfig? reward,
  }) async {
    final unit = _adUnits[unitId];
    if (unit == null || unit.type != AdType.rewarded) {
      return false;
    }

    // Check frequency
    final check = _frequencyController.canShowAd(
      placementId: placement ?? unit.placement,
      type: AdType.rewarded,
    );

    if (!check.canShow) {
      _emitEvent(AdEventType.showFailed, {
        'unitId': unitId,
        'reason': check.blockReason,
      });
      return false;
    }

    // Check if loaded
    if (!isAdReady(unitId)) {
      final loaded = await loadAd(unitId);
      if (!loaded) return false;
    }

    try {
      // TODO: Show actual rewarded ad
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate user watching full ad
      final rewardType = reward?.rewardType ?? 'coins';
      final rewardAmount = reward?.amount ?? 100;

      // Record impression with reward
      _frequencyController.recordImpression(
        placementId: placement ?? unit.placement,
        type: AdType.rewarded,
        rewardClaimed: true,
        revenue: 0.015, // Simulated eCPM $15
      );

      _loadStates[unitId] = AdLoadState.notLoaded;
      _emitEvent(AdEventType.rewarded, {
        'unitId': unitId,
        'rewardType': rewardType,
        'rewardAmount': rewardAmount,
      });

      // Deliver reward
      onReward(rewardType, rewardAmount);

      // Preload next
      loadAd(unitId);

      return true;
    } catch (e) {
      _emitEvent(AdEventType.showFailed, {'unitId': unitId, 'error': e.toString()});
      return false;
    }
  }

  /// Show/hide banner
  void showBanner({String unitId = 'banner_bottom'}) {
    final unit = _adUnits[unitId];
    if (unit == null || unit.type != AdType.banner) {
      return;
    }

    if (_config?.bannerEnabled != true) {
      return;
    }

    // TODO: Show actual banner
    _emitEvent(AdEventType.shown, {'unitId': unitId, 'type': 'banner'});
  }

  void hideBanner({String unitId = 'banner_bottom'}) {
    // TODO: Hide actual banner
    _emitEvent(AdEventType.closed, {'unitId': unitId, 'type': 'banner'});
  }

  /// Update user payment status
  void updatePaymentStatus(bool isPaying, double totalSpend) {
    _frequencyController.updatePaymentStatus(isPaying, totalSpend);

    // If user is now a payer, hide ads
    if (isPaying && _config?.hideAdsForPayers == true) {
      hideBanner();
    }
  }

  /// Get ad statistics
  Map<String, dynamic> getStatistics() {
    return _frequencyController.getStatistics();
  }

  /// Start new session
  void startSession() {
    _frequencyController.startSession();
    _preloadAds();
  }

  /// Emit event
  void _emitEvent(AdEventType type, Map<String, dynamic>? data) {
    _eventController.add((type, data));
    onAdEvent?.call(type, data);
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _instances.remove(gameId);
  }
}

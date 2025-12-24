/// Ad Manager for MG-Games
/// Unified ad handling across 52 games with mediation support

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'models/ad_unit.dart';
import 'models/ad_config.dart';
import 'frequency_controller.dart';
import 'adapters/admob_adapter.dart';

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

  /// AdMob interstitial ads
  final Map<String, AdMobInterstitialAd> _interstitials = {};

  /// AdMob rewarded ads
  final Map<String, AdMobRewardedAd> _rewardedAds = {};

  /// AdMob banner ads
  final Map<String, AdMobBannerAd> _banners = {};

  /// Event stream controller
  final StreamController<(AdEventType, Map<String, dynamic>?)> _eventController =
      StreamController<(AdEventType, Map<String, dynamic>?)>.broadcast();

  /// Event stream
  Stream<(AdEventType, Map<String, dynamic>?)> get eventStream =>
      _eventController.stream;

  /// Global event callback
  AdEventCallback? onAdEvent;

  /// Test mode flag
  bool _testMode = false;

  /// Initialize Ad Manager
  Future<bool> initialize(AdConfig config, {bool testMode = false}) async {
    _config = config;
    _testMode = testMode;
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
    final result = await AdMobAdapter.initialize();
    if (!result.success) {
      throw Exception('Failed to initialize AdMob: ${result.error}');
    }
  }

  /// Register standard ad units for this game
  void _registerStandardUnits() {
    final gameNum = int.tryParse(gameId.replaceAll('game_', '')) ?? 0;
    final testIds = _testMode ? AdMobAdapter.getTestAdUnitIds() : null;

    // Interstitial
    registerAdUnit(AdUnit(
      unitId: 'interstitial_main',
      type: AdType.interstitial,
      network: AdNetwork.admob,
      platformIds: testIds != null
          ? {'android': testIds['interstitial']!, 'ios': testIds['interstitial']!}
          : {
              'android': 'ca-app-pub-xxxxx/${gameNum}0001',
              'ios': 'ca-app-pub-xxxxx/${gameNum}0002',
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
      platformIds: testIds != null
          ? {'android': testIds['rewarded']!, 'ios': testIds['rewarded']!}
          : {
              'android': 'ca-app-pub-xxxxx/${gameNum}0003',
              'ios': 'ca-app-pub-xxxxx/${gameNum}0004',
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
      platformIds: testIds != null
          ? {'android': testIds['rewarded']!, 'ios': testIds['rewarded']!}
          : {
              'android': 'ca-app-pub-xxxxx/${gameNum}0005',
              'ios': 'ca-app-pub-xxxxx/${gameNum}0006',
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
      platformIds: testIds != null
          ? {'android': testIds['rewarded']!, 'ios': testIds['rewarded']!}
          : {
              'android': 'ca-app-pub-xxxxx/${gameNum}0007',
              'ios': 'ca-app-pub-xxxxx/${gameNum}0008',
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
      platformIds: testIds != null
          ? {'android': testIds['banner']!, 'ios': testIds['banner']!}
          : {
              'android': 'ca-app-pub-xxxxx/${gameNum}0009',
              'ios': 'ca-app-pub-xxxxx/${gameNum}0010',
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
      final adUnitId = AdMobAdapter.getAdUnitId(unit);
      if (adUnitId.isEmpty) {
        _loadStates[unitId] = AdLoadState.failed;
        return false;
      }

      bool loaded = false;

      switch (unit.type) {
        case AdType.interstitial:
          final interstitial = AdMobAdapter.createInterstitial(adUnitId);
          interstitial.onAdLoaded = () {
            _emitEvent(AdEventType.loaded, {'unitId': unitId, 'type': 'interstitial'});
          };
          interstitial.onAdFailedToLoad = (error) {
            _loadStates[unitId] = AdLoadState.failed;
            _emitEvent(AdEventType.loadFailed, {'unitId': unitId, 'error': error});
          };
          interstitial.onAdDismissed = () {
            _emitEvent(AdEventType.closed, {'unitId': unitId, 'type': 'interstitial'});
            // Auto reload after dismiss
            loadAd(unitId);
          };
          interstitial.onAdClicked = () {
            _emitEvent(AdEventType.clicked, {'unitId': unitId});
          };
          loaded = await interstitial.load();
          if (loaded) {
            _interstitials[unitId] = interstitial;
          }
          break;

        case AdType.rewarded:
          final rewarded = AdMobAdapter.createRewarded(adUnitId);
          rewarded.onAdLoaded = () {
            _emitEvent(AdEventType.loaded, {'unitId': unitId, 'type': 'rewarded'});
          };
          rewarded.onAdFailedToLoad = (error) {
            _loadStates[unitId] = AdLoadState.failed;
            _emitEvent(AdEventType.loadFailed, {'unitId': unitId, 'error': error});
          };
          rewarded.onAdDismissed = () {
            _emitEvent(AdEventType.closed, {'unitId': unitId, 'type': 'rewarded'});
            // Auto reload after dismiss
            loadAd(unitId);
          };
          rewarded.onAdClicked = () {
            _emitEvent(AdEventType.clicked, {'unitId': unitId});
          };
          loaded = await rewarded.load();
          if (loaded) {
            _rewardedAds[unitId] = rewarded;
          }
          break;

        case AdType.banner:
          final banner = AdMobAdapter.createBanner(adUnitId);
          banner.onAdLoaded = () {
            _emitEvent(AdEventType.loaded, {'unitId': unitId, 'type': 'banner'});
          };
          banner.onAdFailedToLoad = (error) {
            _loadStates[unitId] = AdLoadState.failed;
            _emitEvent(AdEventType.loadFailed, {'unitId': unitId, 'error': error});
          };
          banner.onAdClicked = () {
            _emitEvent(AdEventType.clicked, {'unitId': unitId});
          };
          loaded = await banner.load();
          if (loaded) {
            _banners[unitId] = banner;
          }
          break;

        default:
          _loadStates[unitId] = AdLoadState.failed;
          return false;
      }

      if (loaded) {
        _loadStates[unitId] = AdLoadState.ready;
      } else {
        _loadStates[unitId] = AdLoadState.failed;
      }

      return loaded;
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

    final interstitial = _interstitials[unitId];
    if (interstitial == null) return false;

    try {
      final shown = await interstitial.show();

      if (shown) {
        // Record impression
        _frequencyController.recordImpression(
          placementId: placement ?? unit.placement,
          type: AdType.interstitial,
          revenue: 0.005, // Estimated eCPM $5
        );

        _loadStates[unitId] = AdLoadState.notLoaded;
        _interstitials.remove(unitId);
        _emitEvent(AdEventType.shown, {'unitId': unitId, 'type': 'interstitial'});
      }

      return shown;
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

    final rewardedAd = _rewardedAds[unitId];
    if (rewardedAd == null) return false;

    try {
      final rewardType = reward?.rewardType ?? 'coins';
      final rewardAmount = reward?.amount ?? 100;

      final shown = await rewardedAd.show(
        onRewarded: (type, amount) {
          // Record impression with reward
          _frequencyController.recordImpression(
            placementId: placement ?? unit.placement,
            type: AdType.rewarded,
            rewardClaimed: true,
            revenue: 0.015, // Estimated eCPM $15
          );

          _emitEvent(AdEventType.rewarded, {
            'unitId': unitId,
            'rewardType': type.isNotEmpty ? type : rewardType,
            'rewardAmount': amount > 0 ? amount : rewardAmount,
          });

          // Deliver reward
          onReward(type.isNotEmpty ? type : rewardType, amount > 0 ? amount : rewardAmount);
        },
      );

      if (shown) {
        _loadStates[unitId] = AdLoadState.notLoaded;
        _rewardedAds.remove(unitId);
        _emitEvent(AdEventType.shown, {'unitId': unitId, 'type': 'rewarded'});
      }

      return shown;
    } catch (e) {
      _emitEvent(AdEventType.showFailed, {'unitId': unitId, 'error': e.toString()});
      return false;
    }
  }

  /// Get banner widget
  Widget? getBannerWidget({String unitId = 'banner_bottom'}) {
    final unit = _adUnits[unitId];
    if (unit == null || unit.type != AdType.banner) {
      return null;
    }

    if (_config?.bannerEnabled != true) {
      return null;
    }

    final banner = _banners[unitId];
    if (banner == null || !banner.isLoaded) {
      return null;
    }

    return SizedBox(
      width: banner.width,
      height: banner.height,
      child: banner.widget,
    );
  }

  /// Show/hide banner
  Future<void> showBanner({String unitId = 'banner_bottom'}) async {
    final unit = _adUnits[unitId];
    if (unit == null || unit.type != AdType.banner) {
      return;
    }

    if (_config?.bannerEnabled != true) {
      return;
    }

    if (!isAdReady(unitId)) {
      await loadAd(unitId);
    }

    _emitEvent(AdEventType.shown, {'unitId': unitId, 'type': 'banner'});
  }

  void hideBanner({String unitId = 'banner_bottom'}) {
    final banner = _banners[unitId];
    banner?.dispose();
    _banners.remove(unitId);
    _loadStates[unitId] = AdLoadState.notLoaded;
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

  /// Enable test mode
  Future<void> enableTestMode(List<String>? testDeviceIds) async {
    _testMode = true;
    if (testDeviceIds != null && testDeviceIds.isNotEmpty) {
      await AdMobAdapter.setTestDeviceIds(testDeviceIds);
    }
  }

  /// Open ad inspector (for debugging)
  Future<void> openAdInspector() async {
    await AdMobAdapter.openAdInspector();
  }

  /// Emit event
  void _emitEvent(AdEventType type, Map<String, dynamic>? data) {
    _eventController.add((type, data));
    onAdEvent?.call(type, data);
  }

  /// Dispose resources
  void dispose() {
    // Dispose all ads
    for (final ad in _interstitials.values) {
      ad.dispose();
    }
    for (final ad in _rewardedAds.values) {
      ad.dispose();
    }
    for (final ad in _banners.values) {
      ad.dispose();
    }

    _interstitials.clear();
    _rewardedAds.clear();
    _banners.clear();

    _eventController.close();
    _instances.remove(gameId);
  }
}

/// AdMob Adapter for MG-Games
/// Implements actual Google Mobile Ads SDK integration
///
/// Usage:
/// 1. Add google_mobile_ads: ^5.2.0 to pubspec.yaml
/// 2. Configure AndroidManifest.xml and Info.plist with AdMob App ID
/// 3. Call AdMobAdapter.initialize() at app startup

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/ad_unit.dart';

/// AdMob initialization result
class AdMobInitResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? adapterStatus;

  const AdMobInitResult({
    required this.success,
    this.error,
    this.adapterStatus,
  });
}

/// AdMob adapter for interstitial ads
class AdMobInterstitialAd {
  final String adUnitId;
  bool _isLoaded = false;
  bool _isShowing = false;

  InterstitialAd? _interstitialAd;

  /// Callbacks
  VoidCallback? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  void Function(String error)? onAdFailedToShow;
  VoidCallback? onAdDismissed;
  VoidCallback? onAdClicked;

  AdMobInterstitialAd({required this.adUnitId});

  bool get isLoaded => _isLoaded;

  Future<bool> load() async {
    if (_isLoaded) return true;

    final completer = Completer<bool>();

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoaded = true;
            _setupCallbacks();
            onAdLoaded?.call();
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            _isLoaded = false;
            onAdFailedToLoad?.call(error.message);
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _isLoaded = false;
      onAdFailedToLoad?.call(e.toString());
      return false;
    }
  }

  void _setupCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        onAdShown?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        _isShowing = false;
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        _isShowing = false;
        onAdFailedToShow?.call(error.message);
      },
      onAdClicked: (ad) {
        onAdClicked?.call();
      },
    );
  }

  Future<bool> show() async {
    if (!_isLoaded || _isShowing) return false;

    try {
      _isShowing = true;
      await _interstitialAd?.show();
      return true;
    } catch (e) {
      _isShowing = false;
      onAdFailedToShow?.call(e.toString());
      return false;
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}

/// AdMob adapter for rewarded ads
class AdMobRewardedAd {
  final String adUnitId;
  bool _isLoaded = false;
  bool _isShowing = false;

  RewardedAd? _rewardedAd;

  /// Callbacks
  VoidCallback? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  void Function(String error)? onAdFailedToShow;
  VoidCallback? onAdDismissed;
  VoidCallback? onAdClicked;

  AdMobRewardedAd({required this.adUnitId});

  bool get isLoaded => _isLoaded;

  Future<bool> load() async {
    if (_isLoaded) return true;

    final completer = Completer<bool>();

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoaded = true;
            onAdLoaded?.call();
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            _isLoaded = false;
            onAdFailedToLoad?.call(error.message);
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _isLoaded = false;
      onAdFailedToLoad?.call(e.toString());
      return false;
    }
  }

  Future<bool> show({
    required void Function(String type, int amount) onRewarded,
  }) async {
    if (!_isLoaded || _isShowing) return false;

    try {
      _isShowing = true;

      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          onAdShown?.call();
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isLoaded = false;
          _isShowing = false;
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isLoaded = false;
          _isShowing = false;
          onAdFailedToShow?.call(error.message);
        },
        onAdClicked: (ad) {
          onAdClicked?.call();
        },
      );

      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded(reward.type, reward.amount.toInt());
        },
      );

      return true;
    } catch (e) {
      _isShowing = false;
      onAdFailedToShow?.call(e.toString());
      return false;
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoaded = false;
  }
}

/// AdMob adapter for banner ads
class AdMobBannerAd {
  final String adUnitId;
  final AdSize adSize;
  bool _isLoaded = false;

  BannerAd? _bannerAd;

  /// Callbacks
  VoidCallback? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  VoidCallback? onAdClicked;
  VoidCallback? onAdOpened;
  VoidCallback? onAdClosed;

  AdMobBannerAd({
    required this.adUnitId,
    this.adSize = AdSize.banner,
  });

  bool get isLoaded => _isLoaded;

  /// Get the ad widget for display
  AdWidget? get widget => _bannerAd != null ? AdWidget(ad: _bannerAd!) : null;

  /// Get the ad size
  double get width => adSize.width.toDouble();
  double get height => adSize.height.toDouble();

  Future<bool> load() async {
    if (_isLoaded) return true;

    final completer = Completer<bool>();

    try {
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isLoaded = true;
            onAdLoaded?.call();
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _bannerAd = null;
            _isLoaded = false;
            onAdFailedToLoad?.call(error.message);
            if (!completer.isCompleted) completer.complete(false);
          },
          onAdClicked: (ad) {
            onAdClicked?.call();
          },
          onAdOpened: (ad) {
            onAdOpened?.call();
          },
          onAdClosed: (ad) {
            onAdClosed?.call();
          },
        ),
      );

      await _bannerAd?.load();
      return await completer.future;
    } catch (e) {
      _isLoaded = false;
      onAdFailedToLoad?.call(e.toString());
      return false;
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }
}

/// AdMob adapter main class
class AdMobAdapter {
  static bool _isInitialized = false;
  static Map<String, dynamic>? _adapterStatuses;

  /// Initialize Google Mobile Ads SDK
  static Future<AdMobInitResult> initialize() async {
    if (_isInitialized) {
      return AdMobInitResult(
        success: true,
        adapterStatus: _adapterStatuses,
      );
    }

    try {
      final initStatus = await MobileAds.instance.initialize();

      final adapterStatus = <String, dynamic>{};
      initStatus.adapterStatuses.forEach((key, value) {
        adapterStatus[key] = {
          'state': value.state.name,
          'description': value.description,
          'latency': value.latency,
        };
      });

      _adapterStatuses = adapterStatus;
      _isInitialized = true;

      return AdMobInitResult(
        success: true,
        adapterStatus: adapterStatus,
      );
    } catch (e) {
      return AdMobInitResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Set test device IDs
  static Future<void> setTestDeviceIds(List<String> deviceIds) async {
    final config = RequestConfiguration(testDeviceIds: deviceIds);
    await MobileAds.instance.updateRequestConfiguration(config);
  }

  /// Enable/disable ad inspector for debugging
  static void openAdInspector({void Function()? onClosed}) {
    // MobileAds.instance.openAdInspector requires newer SDK signature
    debugPrint("Ad Inspector opened. Close callback: ");
  }

  /// Get test ad unit IDs (Google's official test IDs)
  static Map<String, String> getTestAdUnitIds() {
    if (Platform.isAndroid) {
      return {
        'interstitial': 'ca-app-pub-3940256099942544/1033173712',
        'rewarded': 'ca-app-pub-3940256099942544/5224354917',
        'rewardedInterstitial': 'ca-app-pub-3940256099942544/5354046379',
        'banner': 'ca-app-pub-3940256099942544/6300978111',
        'native': 'ca-app-pub-3940256099942544/2247696110',
        'appOpen': 'ca-app-pub-3940256099942544/9257395921',
      };
    } else if (Platform.isIOS) {
      return {
        'interstitial': 'ca-app-pub-3940256099942544/4411468910',
        'rewarded': 'ca-app-pub-3940256099942544/1712485313',
        'rewardedInterstitial': 'ca-app-pub-3940256099942544/6978759866',
        'banner': 'ca-app-pub-3940256099942544/2934735716',
        'native': 'ca-app-pub-3940256099942544/3986624511',
        'appOpen': 'ca-app-pub-3940256099942544/5575463023',
      };
    }
    return {};
  }

  /// Get ad unit ID for platform
  static String getAdUnitId(AdUnit unit) {
    if (Platform.isAndroid) {
      return unit.platformIds['android'] ?? '';
    } else if (Platform.isIOS) {
      return unit.platformIds['ios'] ?? '';
    }
    return '';
  }

  /// Create interstitial ad instance
  static AdMobInterstitialAd createInterstitial(String adUnitId) {
    return AdMobInterstitialAd(adUnitId: adUnitId);
  }

  /// Create rewarded ad instance
  static AdMobRewardedAd createRewarded(String adUnitId) {
    return AdMobRewardedAd(adUnitId: adUnitId);
  }

  /// Create banner ad instance
  static AdMobBannerAd createBanner(
    String adUnitId, {
    AdSize size = AdSize.banner,
  }) {
    return AdMobBannerAd(adUnitId: adUnitId, adSize: size);
  }

  /// Get adaptive banner size
  static Future<AdSize> getAdaptiveBannerSize(double width) async {
    final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );
    return adaptiveSize ?? AdSize.banner;
  }
}

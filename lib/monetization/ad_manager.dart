import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 타입
enum AdType {
  banner,
  interstitial,
  rewarded,
  rewardedInterstitial,
  native,
}

/// 광고 상태
enum AdStatus {
  loading,
  loaded,
  failed,
  shown,
  dismissed,
  clicked,
}

/// 광고 이벤트
class AdEvent {
  final AdType type;
  final AdStatus status;
  final String? errorMessage;
  final DateTime timestamp;

  const AdEvent({
    required this.type,
    required this.status,
    this.errorMessage,
    required this.timestamp,
  });
}

/// 배너 광고 크기
enum BannerSize {
  adaptive,
  mediumRectangle,
  fullBanner,
  leaderboard,
}

class AdManager {
  static final AdManager _instance = AdManager._();
  static AdManager get instance => _instance;

  AdManager._();

  // ============================================
  // 상태
  // ============================================
  bool _isInitialized = false;
  final StreamController<AdEvent> _eventController =
      StreamController<AdEvent>.broadcast();

  // 배너 광고
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // 전면 광고
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  // 보상형 광고
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  Stream<AdEvent> get onAdEvent => _eventController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();

      _isInitialized = true;

      _eventController.add(AdEvent(
        type: AdType.banner,
        status: AdStatus.loaded,
        timestamp: DateTime.now(),
      ));

      debugPrint('[AdManager] Initialized');
    } catch (e) {
      debugPrint('[AdManager] Initialization error: $e');
      _eventController.add(AdEvent(
        type: AdType.banner,
        status: AdStatus.failed,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  // ============================================
  // 배너 광고
  // ============================================

  /// 배너 광고 로드
  Future<void> loadBannerAd({
    required String adUnitId,
    BannerSize size = BannerSize.adaptive,
    required void Function(Widget adWidget) onAdLoaded,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final adSize = _getAdSize(size);

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;

          _eventController.add(AdEvent(
            type: AdType.banner,
            status: AdStatus.loaded,
            timestamp: DateTime.now(),
          ));

          onAdLoaded(AdWidget(ad: ad as BannerAd));
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerAdLoaded = false;

          _eventController.add(AdEvent(
            type: AdType.banner,
            status: AdStatus.failed,
            errorMessage: error.message,
            timestamp: DateTime.now(),
          ));
        },
        onAdOpened: (ad) {
          _eventController.add(AdEvent(
            type: AdType.banner,
            status: AdStatus.shown,
            timestamp: DateTime.now(),
          ));
        },
        onAdClosed: (ad) {
          _eventController.add(AdEvent(
            type: AdType.banner,
            status: AdStatus.dismissed,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );

    _bannerAd!.load();
  }

  /// 배너 광고 해제
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  AdSize _getAdSize(BannerSize size) {
    switch (size) {
      case BannerSize.adaptive:
        return AdSize.adaptiveBanner;
      case BannerSize.mediumRectangle:
        return AdSize.mediumRectangle;
      case BannerSize.fullBanner:
        return AdSize.fullBanner;
      case BannerSize.leaderboard:
        return AdSize.leaderboard;
    }
  }

  // ============================================
  // 전면 광고
  // ============================================

  /// 전면 광고 로드
  Future<void> loadInterstitialAd({required String adUnitId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _eventController.add(AdEvent(
                type: AdType.interstitial,
                status: AdStatus.shown,
                timestamp: DateTime.now(),
              ));
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;

              _eventController.add(AdEvent(
                type: AdType.interstitial,
                status: AdStatus.dismissed,
                timestamp: DateTime.now(),
              ));
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;

              _eventController.add(AdEvent(
                type: AdType.interstitial,
                status: AdStatus.failed,
                errorMessage: error.message,
                timestamp: DateTime.now(),
              ));
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;

          _eventController.add(AdEvent(
            type: AdType.interstitial,
            status: AdStatus.failed,
            errorMessage: error.message,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );
  }

  /// 전면 광고 표시
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('[AdManager] Interstitial ad not loaded');
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('[AdManager] Error showing interstitial ad: $e');
      return false;
    }
  }

  // ============================================
  // 보상형 광고
  // ============================================

  /// 보상형 광고 로드
  Future<void> loadRewardedAd({required String adUnitId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _eventController.add(AdEvent(
                type: AdType.rewarded,
                status: AdStatus.shown,
                timestamp: DateTime.now(),
              ));
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;

              _eventController.add(AdEvent(
                type: AdType.rewarded,
                status: AdStatus.dismissed,
                timestamp: DateTime.now(),
              ));
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;

              _eventController.add(AdEvent(
                type: AdType.rewarded,
                status: AdStatus.failed,
                errorMessage: error.message,
                timestamp: DateTime.now(),
              ));
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoaded = false;

          _eventController.add(AdEvent(
            type: AdType.rewarded,
            status: AdStatus.failed,
            errorMessage: error.message,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );
  }

  /// 보상형 광고 표시
  Future<bool> showRewardedAd({
    void Function(RewardItem)? onEarnedReward,
  }) async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('[AdManager] Rewarded ad not loaded');
      return false;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onEarnedReward?.call(reward);

          debugPrint('[AdManager] Reward earned: ${reward.amount} ${reward.type}');
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AdManager] Error showing rewarded ad: $e');
      return false;
    }
  }

  // ============================================
  // 네이티브 광고
  // ============================================

  /// 네이티브 광고 로드
  Future<void> loadNativeAd({
    required String adUnitId,
    required void Function(NativeAd ad) onAdLoaded,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'adFactoryExample', // 네이티브 광고 팩토리 ID
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _eventController.add(AdEvent(
            type: AdType.native,
            status: AdStatus.loaded,
            timestamp: DateTime.now(),
          ));

          onAdLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          _eventController.add(AdEvent(
            type: AdType.native,
            status: AdStatus.failed,
            errorMessage: error.message,
            timestamp: DateTime.now(),
          ));
        },
      ),
    );

    await nativeAd.load();
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _eventController.close();
  }
}

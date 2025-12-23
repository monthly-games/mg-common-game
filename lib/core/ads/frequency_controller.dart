/// Frequency Controller for MG-Games Ads
/// Controls ad frequency to optimize user experience and revenue

import 'dart:math';

import 'models/ad_unit.dart';
import 'models/ad_config.dart';

/// Ad impression record
class AdImpression {
  /// Placement ID
  final String placementId;

  /// Ad type
  final AdType type;

  /// Timestamp (milliseconds since epoch)
  final int timestamp;

  /// Whether reward was claimed (for rewarded)
  final bool rewardClaimed;

  /// Revenue (eCPM / 1000)
  final double? revenue;

  AdImpression({
    required this.placementId,
    required this.type,
    required this.timestamp,
    this.rewardClaimed = false,
    this.revenue,
  });
}

/// Frequency check result
class FrequencyCheckResult {
  /// Whether ad can be shown
  final bool canShow;

  /// Reason if blocked
  final String? blockReason;

  /// Seconds until can show again
  final int? waitSeconds;

  /// Remaining today
  final int remainingToday;

  /// Remaining this session
  final int remainingSession;

  FrequencyCheckResult({
    required this.canShow,
    this.blockReason,
    this.waitSeconds,
    required this.remainingToday,
    required this.remainingSession,
  });
}

/// Frequency Controller implementation
class FrequencyController {
  /// Singleton instance
  static final FrequencyController _instance = FrequencyController._internal();
  factory FrequencyController() => _instance;
  FrequencyController._internal();

  /// Configuration
  AdConfig? _config;

  /// Session start time
  int _sessionStartTime = 0;

  /// Impression history
  final List<AdImpression> _impressions = [];

  /// Last impression time by placement
  final Map<String, int> _lastImpressionByPlacement = {};

  /// User is paying (has made purchase)
  bool _userIsPaying = false;

  /// Total user spend
  double _userTotalSpend = 0;

  /// Initialize controller
  void initialize(AdConfig config) {
    _config = config;
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// Start new session
  void startSession() {
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    // Keep daily history, clear session-specific data
  }

  /// Update user payment status
  void updatePaymentStatus(bool isPaying, double totalSpend) {
    _userIsPaying = isPaying;
    _userTotalSpend = totalSpend;
  }

  /// Check if ad can be shown
  FrequencyCheckResult canShowAd({
    required String placementId,
    required AdType type,
    AdPlacement? placement,
  }) {
    final config = _config;
    if (config == null) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Frequency controller not initialized',
        remainingToday: 0,
        remainingSession: 0,
      );
    }

    // Check if ads are enabled
    if (!config.adsEnabled) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Ads disabled',
        remainingToday: 0,
        remainingSession: 0,
      );
    }

    // Check type-specific enable
    if (type == AdType.interstitial && !config.interstitialEnabled) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Interstitials disabled',
        remainingToday: 0,
        remainingSession: 0,
      );
    }
    if (type == AdType.rewarded && !config.rewardedEnabled) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Rewarded disabled',
        remainingToday: 0,
        remainingSession: 0,
      );
    }
    if (type == AdType.banner && !config.bannerEnabled) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Banners disabled',
        remainingToday: 0,
        remainingSession: 0,
      );
    }

    // Check paying user
    if (config.hideAdsForPayers &&
        _userIsPaying &&
        _userTotalSpend >= config.payerThreshold) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'User is paying customer',
        remainingToday: 0,
        remainingSession: 0,
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final todayStart = _getTodayStart();

    // Get impressions for this type today
    final todayImpressions = _impressions.where((i) =>
        i.type == type &&
        i.timestamp >= todayStart);

    // Get impressions for this session
    final sessionImpressions = _impressions.where((i) =>
        i.type == type &&
        i.timestamp >= _sessionStartTime);

    // Check daily limit
    final maxToday = type == AdType.interstitial
        ? config.maxInterstitialsPerDay
        : type == AdType.rewarded
            ? config.maxRewardedPerDay
            : 999;

    final todayCount = todayImpressions.length;
    final remainingToday = max(0, maxToday - todayCount);

    if (remainingToday <= 0) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Daily limit reached',
        remainingToday: 0,
        remainingSession: 0,
      );
    }

    // Check session limit
    final maxSession = type == AdType.interstitial
        ? config.maxInterstitialsPerSession
        : placement?.maxPerSession ?? 999;

    final sessionCount = sessionImpressions.length;
    final remainingSession = max(0, maxSession - sessionCount);

    if (remainingSession <= 0) {
      return FrequencyCheckResult(
        canShow: false,
        blockReason: 'Session limit reached',
        remainingToday: remainingToday,
        remainingSession: 0,
      );
    }

    // Check cooldown
    final lastTime = _lastImpressionByPlacement[placementId];
    final cooldown = type == AdType.interstitial
        ? config.interstitialCooldown
        : placement?.cooldownSeconds ?? 0;

    if (lastTime != null && cooldown > 0) {
      final elapsed = (now - lastTime) ~/ 1000;
      if (elapsed < cooldown) {
        return FrequencyCheckResult(
          canShow: false,
          blockReason: 'Cooldown active',
          waitSeconds: cooldown - elapsed,
          remainingToday: remainingToday,
          remainingSession: remainingSession,
        );
      }
    }

    // All checks passed
    return FrequencyCheckResult(
      canShow: true,
      remainingToday: remainingToday,
      remainingSession: remainingSession,
    );
  }

  /// Record an impression
  void recordImpression({
    required String placementId,
    required AdType type,
    bool rewardClaimed = false,
    double? revenue,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    _impressions.add(AdImpression(
      placementId: placementId,
      type: type,
      timestamp: now,
      rewardClaimed: rewardClaimed,
      revenue: revenue,
    ));

    _lastImpressionByPlacement[placementId] = now;

    // Cleanup old impressions (keep last 7 days)
    final weekAgo = now - (7 * 24 * 60 * 60 * 1000);
    _impressions.removeWhere((i) => i.timestamp < weekAgo);
  }

  /// Get ad statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final todayStart = _getTodayStart();

    final todayImpressions = _impressions.where((i) => i.timestamp >= todayStart);
    final sessionImpressions =
        _impressions.where((i) => i.timestamp >= _sessionStartTime);

    // Calculate revenue
    final todayRevenue = todayImpressions
        .where((i) => i.revenue != null)
        .fold<double>(0, (sum, i) => sum + i.revenue!);

    // Calculate fill rate (estimated)
    final rewardedClaimed = todayImpressions
        .where((i) => i.type == AdType.rewarded && i.rewardClaimed)
        .length;
    final rewardedTotal =
        todayImpressions.where((i) => i.type == AdType.rewarded).length;

    return {
      'todayImpressions': todayImpressions.length,
      'sessionImpressions': sessionImpressions.length,
      'todayRevenue': todayRevenue,
      'todayInterstitials':
          todayImpressions.where((i) => i.type == AdType.interstitial).length,
      'todayRewarded':
          todayImpressions.where((i) => i.type == AdType.rewarded).length,
      'rewardClaimRate':
          rewardedTotal > 0 ? rewardedClaimed / rewardedTotal : 0.0,
      'sessionDurationMs': now - _sessionStartTime,
    };
  }

  /// Get today start timestamp
  int _getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }

  /// Clear all data
  void clear() {
    _impressions.clear();
    _lastImpressionByPlacement.clear();
    _userIsPaying = false;
    _userTotalSpend = 0;
  }
}

/// 광고 시스템 타입 정의
///
/// 광고 타입, 설정, 이벤트 모델 정의
library;

/// 광고 타입
enum AdType {
  /// 배너 광고
  banner,

  /// 전면 광고 (Interstitial)
  interstitial,

  /// 보상형 광고 (Rewarded)
  rewarded,

  /// 보상형 전면 광고
  rewardedInterstitial,

  /// 네이티브 광고
  native,

  /// 앱 오픈 광고
  appOpen,
}

/// 광고 상태
enum AdState {
  /// 초기화되지 않음
  notInitialized,

  /// 로딩 중
  loading,

  /// 준비됨
  ready,

  /// 표시 중
  showing,

  /// 완료됨
  completed,

  /// 에러
  error,
}

/// 광고 제공자
enum AdProvider {
  /// Google AdMob
  admob,

  /// Unity Ads
  unity,

  /// AppLovin MAX
  applovin,

  /// ironSource
  ironSource,

  /// Meta Audience Network
  meta,

  /// 테스트/더미 광고
  test,
}

/// 배너 크기
enum BannerSize {
  /// 320x50
  standard,

  /// 320x100
  largeBanner,

  /// 300x250
  mediumRectangle,

  /// 전체 너비 적응형
  adaptiveBanner,

  /// 스마트 배너
  smartBanner,
}

/// 광고 단위 설정
class AdUnitConfig {
  final String id;
  final AdType type;
  final String androidId;
  final String iosId;
  final BannerSize? bannerSize;
  final Duration? cooldown;
  final int? maxDailyImpressions;
  final Map<String, dynamic>? metadata;

  const AdUnitConfig({
    required this.id,
    required this.type,
    required this.androidId,
    required this.iosId,
    this.bannerSize,
    this.cooldown,
    this.maxDailyImpressions,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'androidId': androidId,
        'iosId': iosId,
        'bannerSize': bannerSize?.index,
        'cooldown': cooldown?.inMilliseconds,
        'maxDailyImpressions': maxDailyImpressions,
        'metadata': metadata,
      };

  factory AdUnitConfig.fromJson(Map<String, dynamic> json) {
    return AdUnitConfig(
      id: json['id'] as String,
      type: AdType.values[json['type'] as int],
      androidId: json['androidId'] as String,
      iosId: json['iosId'] as String,
      bannerSize:
          json['bannerSize'] != null ? BannerSize.values[json['bannerSize'] as int] : null,
      cooldown: json['cooldown'] != null
          ? Duration(milliseconds: json['cooldown'] as int)
          : null,
      maxDailyImpressions: json['maxDailyImpressions'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// 광고 보상
class AdReward {
  final String type;
  final int amount;
  final Map<String, dynamic>? metadata;

  const AdReward({
    required this.type,
    required this.amount,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'metadata': metadata,
      };

  factory AdReward.fromJson(Map<String, dynamic> json) {
    return AdReward(
      type: json['type'] as String,
      amount: json['amount'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'AdReward($type x$amount)';
}

/// 광고 이벤트
class AdEvent {
  final String adUnitId;
  final AdType adType;
  final AdEventType eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const AdEvent({
    required this.adUnitId,
    required this.adType,
    required this.eventType,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'adUnitId': adUnitId,
        'adType': adType.index,
        'eventType': eventType.index,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  factory AdEvent.fromJson(Map<String, dynamic> json) {
    return AdEvent(
      adUnitId: json['adUnitId'] as String,
      adType: AdType.values[json['adType'] as int],
      eventType: AdEventType.values[json['eventType'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// 광고 이벤트 타입
enum AdEventType {
  /// 로드 요청됨
  loadRequested,

  /// 로드 성공
  loaded,

  /// 로드 실패
  loadFailed,

  /// 표시됨
  shown,

  /// 표시 실패
  showFailed,

  /// 클릭됨
  clicked,

  /// 닫힘
  closed,

  /// 보상 획득
  rewarded,

  /// 노출 (impression)
  impression,
}

/// 광고 통계
class AdStats {
  final String adUnitId;
  final int impressions;
  final int clicks;
  final int rewards;
  final int errors;
  final double ctr; // Click-through rate
  final Duration totalWatchTime;

  const AdStats({
    required this.adUnitId,
    this.impressions = 0,
    this.clicks = 0,
    this.rewards = 0,
    this.errors = 0,
    this.ctr = 0.0,
    this.totalWatchTime = Duration.zero,
  });

  AdStats copyWith({
    int? impressions,
    int? clicks,
    int? rewards,
    int? errors,
    double? ctr,
    Duration? totalWatchTime,
  }) {
    return AdStats(
      adUnitId: adUnitId,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      rewards: rewards ?? this.rewards,
      errors: errors ?? this.errors,
      ctr: ctr ?? this.ctr,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
    );
  }

  /// 클릭율 재계산
  AdStats recalculateCtr() {
    return copyWith(
      ctr: impressions > 0 ? clicks / impressions : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'adUnitId': adUnitId,
        'impressions': impressions,
        'clicks': clicks,
        'rewards': rewards,
        'errors': errors,
        'ctr': ctr,
        'totalWatchTime': totalWatchTime.inMilliseconds,
      };

  factory AdStats.fromJson(Map<String, dynamic> json) {
    return AdStats(
      adUnitId: json['adUnitId'] as String,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      rewards: json['rewards'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      ctr: (json['ctr'] as num?)?.toDouble() ?? 0.0,
      totalWatchTime: Duration(milliseconds: json['totalWatchTime'] as int? ?? 0),
    );
  }
}

/// 광고 빈도 제어
class AdFrequencyControl {
  final String adUnitId;
  final int impressionsToday;
  final DateTime? lastImpressionTime;
  final DateTime lastResetDate;

  const AdFrequencyControl({
    required this.adUnitId,
    this.impressionsToday = 0,
    this.lastImpressionTime,
    required this.lastResetDate,
  });

  /// 일일 제한에 도달했는지 확인
  bool hasReachedDailyLimit(int? maxDaily) {
    if (maxDaily == null) return false;
    return impressionsToday >= maxDaily;
  }

  /// 쿨다운 중인지 확인
  bool isInCooldown(Duration? cooldown) {
    if (cooldown == null || lastImpressionTime == null) return false;
    return DateTime.now().difference(lastImpressionTime!) < cooldown;
  }

  /// 새 노출 기록
  AdFrequencyControl recordImpression() {
    return AdFrequencyControl(
      adUnitId: adUnitId,
      impressionsToday: impressionsToday + 1,
      lastImpressionTime: DateTime.now(),
      lastResetDate: lastResetDate,
    );
  }

  /// 일일 리셋 필요 여부
  bool needsDailyReset() {
    final now = DateTime.now();
    return now.day != lastResetDate.day ||
        now.month != lastResetDate.month ||
        now.year != lastResetDate.year;
  }

  /// 일일 리셋
  AdFrequencyControl resetDaily() {
    return AdFrequencyControl(
      adUnitId: adUnitId,
      impressionsToday: 0,
      lastImpressionTime: null,
      lastResetDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'adUnitId': adUnitId,
        'impressionsToday': impressionsToday,
        'lastImpressionTime': lastImpressionTime?.toIso8601String(),
        'lastResetDate': lastResetDate.toIso8601String(),
      };

  factory AdFrequencyControl.fromJson(Map<String, dynamic> json) {
    return AdFrequencyControl(
      adUnitId: json['adUnitId'] as String,
      impressionsToday: json['impressionsToday'] as int? ?? 0,
      lastImpressionTime: json['lastImpressionTime'] != null
          ? DateTime.parse(json['lastImpressionTime'] as String)
          : null,
      lastResetDate: DateTime.parse(json['lastResetDate'] as String),
    );
  }
}

/// 보상형 광고 결과
class RewardedAdResult {
  final bool success;
  final bool userEarnedReward;
  final AdReward? reward;
  final String? errorMessage;

  const RewardedAdResult({
    required this.success,
    required this.userEarnedReward,
    this.reward,
    this.errorMessage,
  });

  factory RewardedAdResult.success(AdReward reward) {
    return RewardedAdResult(
      success: true,
      userEarnedReward: true,
      reward: reward,
    );
  }

  factory RewardedAdResult.noReward() {
    return const RewardedAdResult(
      success: true,
      userEarnedReward: false,
    );
  }

  factory RewardedAdResult.failure(String error) {
    return RewardedAdResult(
      success: false,
      userEarnedReward: false,
      errorMessage: error,
    );
  }
}

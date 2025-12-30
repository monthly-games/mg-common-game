/// 광고 매니저
///
/// 광고 로드, 표시, 보상 관리
library;

import 'package:flutter/foundation.dart';

import 'ad_types.dart';

/// 광고 매니저
///
/// 다양한 광고 타입을 관리하고, 빈도 제어 및 통계를 처리
class AdManager extends ChangeNotifier {
  /// 초기화 상태
  bool _initialized = false;

  /// 광고 비활성화 여부 (광고 제거 구매 등)
  bool _adsDisabled = false;

  /// 현재 사용 중인 광고 제공자
  AdProvider _provider = AdProvider.test;

  /// 등록된 광고 단위
  final Map<String, AdUnitConfig> _adUnits = {};

  /// 광고 상태
  final Map<String, AdState> _adStates = {};

  /// 빈도 제어 데이터
  final Map<String, AdFrequencyControl> _frequencyControl = {};

  /// 광고 통계
  final Map<String, AdStats> _stats = {};

  /// 이벤트 로그
  final List<AdEvent> _eventLog = [];

  /// 콜백 - 광고 SDK 연동용
  Future<void> Function(AdUnitConfig config)? onLoadAd;
  Future<bool> Function(AdUnitConfig config)? onShowAd;
  Future<RewardedAdResult> Function(AdUnitConfig config, AdReward defaultReward)?
      onShowRewardedAd;
  void Function(AdEvent event)? onAdEvent;

  // ============================================================
  // Getters
  // ============================================================

  /// 초기화 상태
  bool get isInitialized => _initialized;

  /// 광고 비활성화 여부
  bool get adsDisabled => _adsDisabled;

  /// 현재 광고 제공자
  AdProvider get provider => _provider;

  /// 등록된 광고 단위 ID 목록
  List<String> get adUnitIds => _adUnits.keys.toList();

  /// 이벤트 로그 수
  int get eventLogCount => _eventLog.length;

  // ============================================================
  // 초기화
  // ============================================================

  /// 광고 시스템 초기화
  Future<void> initialize({
    AdProvider provider = AdProvider.test,
    List<AdUnitConfig>? adUnits,
  }) async {
    if (_initialized) return;

    _provider = provider;

    if (adUnits != null) {
      for (final unit in adUnits) {
        _adUnits[unit.id] = unit;
        _adStates[unit.id] = AdState.notInitialized;
        _stats[unit.id] = AdStats(adUnitId: unit.id);
        _frequencyControl[unit.id] = AdFrequencyControl(
          adUnitId: unit.id,
          lastResetDate: DateTime.now(),
        );
      }
    }

    _initialized = true;
    debugPrint('AdManager initialized with ${_adUnits.length} ad units');
    notifyListeners();
  }

  /// 광고 단위 등록
  void registerAdUnit(AdUnitConfig config) {
    _adUnits[config.id] = config;
    _adStates[config.id] = AdState.notInitialized;
    _stats[config.id] = AdStats(adUnitId: config.id);
    _frequencyControl[config.id] = AdFrequencyControl(
      adUnitId: config.id,
      lastResetDate: DateTime.now(),
    );
  }

  /// 광고 단위 설정 가져오기
  AdUnitConfig? getAdUnit(String adUnitId) => _adUnits[adUnitId];

  /// 광고 상태 가져오기
  AdState getAdState(String adUnitId) =>
      _adStates[adUnitId] ?? AdState.notInitialized;

  /// 광고 통계 가져오기
  AdStats? getStats(String adUnitId) => _stats[adUnitId];

  // ============================================================
  // 광고 비활성화
  // ============================================================

  /// 광고 비활성화 (광고 제거 구매 시)
  void disableAds() {
    _adsDisabled = true;
    notifyListeners();
  }

  /// 광고 다시 활성화
  void enableAds() {
    _adsDisabled = false;
    notifyListeners();
  }

  // ============================================================
  // 광고 로드
  // ============================================================

  /// 광고 로드
  Future<bool> loadAd(String adUnitId) async {
    if (!_initialized) {
      debugPrint('AdManager not initialized');
      return false;
    }

    final config = _adUnits[adUnitId];
    if (config == null) {
      debugPrint('Ad unit not found: $adUnitId');
      return false;
    }

    // 이미 로딩 중이거나 준비됨
    final currentState = _adStates[adUnitId];
    if (currentState == AdState.loading || currentState == AdState.ready) {
      return currentState == AdState.ready;
    }

    _updateState(adUnitId, AdState.loading);
    _logEvent(adUnitId, config.type, AdEventType.loadRequested);

    if (onLoadAd != null) {
      try {
        await onLoadAd!(config);
        _updateState(adUnitId, AdState.ready);
        _logEvent(adUnitId, config.type, AdEventType.loaded);
        return true;
      } catch (e) {
        _updateState(adUnitId, AdState.error);
        _logEvent(adUnitId, config.type, AdEventType.loadFailed, {'error': e.toString()});
        _incrementErrors(adUnitId);
        return false;
      }
    }

    // 테스트 모드 - 즉시 준비됨
    _updateState(adUnitId, AdState.ready);
    _logEvent(adUnitId, config.type, AdEventType.loaded);
    return true;
  }

  /// 모든 광고 미리 로드
  Future<void> preloadAllAds() async {
    for (final adUnitId in _adUnits.keys) {
      await loadAd(adUnitId);
    }
  }

  /// 특정 타입 광고 미리 로드
  Future<void> preloadAdsByType(AdType type) async {
    for (final config in _adUnits.values) {
      if (config.type == type) {
        await loadAd(config.id);
      }
    }
  }

  // ============================================================
  // 광고 표시
  // ============================================================

  /// 광고 표시 가능 여부 확인
  bool canShowAd(String adUnitId) {
    if (_adsDisabled) return false;

    final config = _adUnits[adUnitId];
    if (config == null) return false;

    final state = _adStates[adUnitId];
    if (state != AdState.ready) return false;

    // 빈도 제어 확인
    final frequency = _frequencyControl[adUnitId];
    if (frequency != null) {
      // 일일 리셋 확인
      if (frequency.needsDailyReset()) {
        _frequencyControl[adUnitId] = frequency.resetDaily();
      } else {
        // 일일 제한 확인
        if (frequency.hasReachedDailyLimit(config.maxDailyImpressions)) {
          return false;
        }
        // 쿨다운 확인
        if (frequency.isInCooldown(config.cooldown)) {
          return false;
        }
      }
    }

    return true;
  }

  /// 전면 광고 표시
  Future<bool> showInterstitial(String adUnitId) async {
    if (!canShowAd(adUnitId)) return false;

    final config = _adUnits[adUnitId];
    if (config == null || config.type != AdType.interstitial) return false;

    _updateState(adUnitId, AdState.showing);

    bool success = false;

    if (onShowAd != null) {
      try {
        success = await onShowAd!(config);
      } catch (e) {
        _logEvent(adUnitId, config.type, AdEventType.showFailed, {'error': e.toString()});
        _incrementErrors(adUnitId);
      }
    } else {
      // 테스트 모드
      success = true;
    }

    if (success) {
      _recordImpression(adUnitId);
      _logEvent(adUnitId, config.type, AdEventType.shown);
      _logEvent(adUnitId, config.type, AdEventType.impression);
    }

    _updateState(adUnitId, success ? AdState.completed : AdState.error);

    // 자동 리로드
    loadAd(adUnitId);

    return success;
  }

  /// 보상형 광고 표시
  Future<RewardedAdResult> showRewarded(
    String adUnitId, {
    String rewardType = 'coins',
    int rewardAmount = 100,
  }) async {
    if (!canShowAd(adUnitId)) {
      return RewardedAdResult.failure('Cannot show ad');
    }

    final config = _adUnits[adUnitId];
    if (config == null ||
        (config.type != AdType.rewarded && config.type != AdType.rewardedInterstitial)) {
      return RewardedAdResult.failure('Invalid ad type');
    }

    _updateState(adUnitId, AdState.showing);

    final defaultReward = AdReward(type: rewardType, amount: rewardAmount);

    RewardedAdResult result;

    if (onShowRewardedAd != null) {
      try {
        result = await onShowRewardedAd!(config, defaultReward);
      } catch (e) {
        result = RewardedAdResult.failure(e.toString());
        _logEvent(adUnitId, config.type, AdEventType.showFailed, {'error': e.toString()});
        _incrementErrors(adUnitId);
      }
    } else {
      // 테스트 모드 - 항상 보상 지급
      result = RewardedAdResult.success(defaultReward);
    }

    if (result.success) {
      _recordImpression(adUnitId);
      _logEvent(adUnitId, config.type, AdEventType.shown);
      _logEvent(adUnitId, config.type, AdEventType.impression);

      if (result.userEarnedReward && result.reward != null) {
        _logEvent(adUnitId, config.type, AdEventType.rewarded, {
          'type': result.reward!.type,
          'amount': result.reward!.amount,
        });
        _incrementRewards(adUnitId);
      }
    }

    _updateState(adUnitId, result.success ? AdState.completed : AdState.error);

    // 자동 리로드
    loadAd(adUnitId);

    return result;
  }

  // ============================================================
  // 이벤트 처리
  // ============================================================

  /// 광고 클릭 이벤트 기록
  void recordClick(String adUnitId) {
    final config = _adUnits[adUnitId];
    if (config == null) return;

    _logEvent(adUnitId, config.type, AdEventType.clicked);
    _incrementClicks(adUnitId);
  }

  /// 광고 닫힘 이벤트 기록
  void recordClosed(String adUnitId) {
    final config = _adUnits[adUnitId];
    if (config == null) return;

    _logEvent(adUnitId, config.type, AdEventType.closed);
  }

  // ============================================================
  // Private 메서드
  // ============================================================

  void _updateState(String adUnitId, AdState state) {
    _adStates[adUnitId] = state;
    notifyListeners();
  }

  void _logEvent(
    String adUnitId,
    AdType adType,
    AdEventType eventType, [
    Map<String, dynamic>? data,
  ]) {
    final event = AdEvent(
      adUnitId: adUnitId,
      adType: adType,
      eventType: eventType,
      timestamp: DateTime.now(),
      data: data,
    );

    _eventLog.add(event);
    onAdEvent?.call(event);
  }

  void _recordImpression(String adUnitId) {
    final control = _frequencyControl[adUnitId];
    if (control != null) {
      _frequencyControl[adUnitId] = control.recordImpression();
    }

    final stats = _stats[adUnitId];
    if (stats != null) {
      _stats[adUnitId] = stats.copyWith(
        impressions: stats.impressions + 1,
      ).recalculateCtr();
    }
  }

  void _incrementClicks(String adUnitId) {
    final stats = _stats[adUnitId];
    if (stats != null) {
      _stats[adUnitId] = stats.copyWith(
        clicks: stats.clicks + 1,
      ).recalculateCtr();
    }
  }

  void _incrementRewards(String adUnitId) {
    final stats = _stats[adUnitId];
    if (stats != null) {
      _stats[adUnitId] = stats.copyWith(
        rewards: stats.rewards + 1,
      );
    }
  }

  void _incrementErrors(String adUnitId) {
    final stats = _stats[adUnitId];
    if (stats != null) {
      _stats[adUnitId] = stats.copyWith(
        errors: stats.errors + 1,
      );
    }
  }

  // ============================================================
  // 유틸리티
  // ============================================================

  /// 남은 쿨다운 시간
  Duration? getRemainingCooldown(String adUnitId) {
    final config = _adUnits[adUnitId];
    final control = _frequencyControl[adUnitId];

    if (config?.cooldown == null ||
        control?.lastImpressionTime == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(control!.lastImpressionTime!);
    final remaining = config!.cooldown! - elapsed;

    return remaining.isNegative ? null : remaining;
  }

  /// 오늘 남은 노출 수
  int? getRemainingDailyImpressions(String adUnitId) {
    final config = _adUnits[adUnitId];
    final control = _frequencyControl[adUnitId];

    if (config?.maxDailyImpressions == null || control == null) return null;

    // 일일 리셋 확인
    if (control.needsDailyReset()) {
      return config!.maxDailyImpressions;
    }

    return config!.maxDailyImpressions! - control.impressionsToday;
  }

  /// 이벤트 로그 가져오기
  List<AdEvent> getEventLog({
    String? adUnitId,
    AdEventType? eventType,
    int? limit,
  }) {
    var events = _eventLog.toList();

    if (adUnitId != null) {
      events = events.where((e) => e.adUnitId == adUnitId).toList();
    }

    if (eventType != null) {
      events = events.where((e) => e.eventType == eventType).toList();
    }

    if (limit != null && events.length > limit) {
      events = events.sublist(events.length - limit);
    }

    return events;
  }

  // ============================================================
  // 저장/불러오기
  // ============================================================

  Map<String, dynamic> toJson() => {
        'adsDisabled': _adsDisabled,
        'frequencyControl':
            _frequencyControl.map((k, v) => MapEntry(k, v.toJson())),
        'stats': _stats.map((k, v) => MapEntry(k, v.toJson())),
      };

  void fromJson(Map<String, dynamic> json) {
    _adsDisabled = json['adsDisabled'] as bool? ?? false;

    if (json['frequencyControl'] != null) {
      final controlMap = json['frequencyControl'] as Map<String, dynamic>;
      for (final entry in controlMap.entries) {
        _frequencyControl[entry.key] = AdFrequencyControl.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    if (json['stats'] != null) {
      final statsMap = json['stats'] as Map<String, dynamic>;
      for (final entry in statsMap.entries) {
        _stats[entry.key] = AdStats.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    notifyListeners();
  }

  /// 이벤트 로그 클리어
  void clearEventLog() {
    _eventLog.clear();
  }

  /// 통계 리셋
  void resetStats(String adUnitId) {
    _stats[adUnitId] = AdStats(adUnitId: adUnitId);
    notifyListeners();
  }

  /// 모든 통계 리셋
  void resetAllStats() {
    for (final adUnitId in _stats.keys.toList()) {
      _stats[adUnitId] = AdStats(adUnitId: adUnitId);
    }
    notifyListeners();
  }

  /// 모든 데이터 클리어
  void clear() {
    _initialized = false;
    _adsDisabled = false;
    _adUnits.clear();
    _adStates.clear();
    _frequencyControl.clear();
    _stats.clear();
    _eventLog.clear();
    notifyListeners();
  }
}

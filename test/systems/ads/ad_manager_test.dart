import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/ads/ads.dart';

void main() {
  group('AdUnitConfig', () {
    test('기본 생성', () {
      const config = AdUnitConfig(
        id: 'interstitial_1',
        type: AdType.interstitial,
        androidId: 'ca-app-pub-xxx/android',
        iosId: 'ca-app-pub-xxx/ios',
      );

      expect(config.id, 'interstitial_1');
      expect(config.type, AdType.interstitial);
      expect(config.androidId, 'ca-app-pub-xxx/android');
      expect(config.iosId, 'ca-app-pub-xxx/ios');
    });

    test('옵션 설정', () {
      const config = AdUnitConfig(
        id: 'rewarded_1',
        type: AdType.rewarded,
        androidId: 'android_id',
        iosId: 'ios_id',
        cooldown: Duration(minutes: 5),
        maxDailyImpressions: 10,
      );

      expect(config.cooldown, const Duration(minutes: 5));
      expect(config.maxDailyImpressions, 10);
    });

    test('JSON 직렬화', () {
      const config = AdUnitConfig(
        id: 'banner_1',
        type: AdType.banner,
        androidId: 'android_id',
        iosId: 'ios_id',
        bannerSize: BannerSize.standard,
      );

      final json = config.toJson();
      final restored = AdUnitConfig.fromJson(json);

      expect(restored.id, config.id);
      expect(restored.type, config.type);
      expect(restored.bannerSize, config.bannerSize);
    });
  });

  group('AdReward', () {
    test('기본 생성', () {
      const reward = AdReward(type: 'coins', amount: 100);

      expect(reward.type, 'coins');
      expect(reward.amount, 100);
    });

    test('toString', () {
      const reward = AdReward(type: 'gems', amount: 50);
      expect(reward.toString(), 'AdReward(gems x50)');
    });

    test('JSON 직렬화', () {
      const reward = AdReward(
        type: 'coins',
        amount: 100,
        metadata: {'bonus': true},
      );

      final json = reward.toJson();
      final restored = AdReward.fromJson(json);

      expect(restored.type, reward.type);
      expect(restored.amount, reward.amount);
      expect(restored.metadata?['bonus'], true);
    });
  });

  group('AdEvent', () {
    test('JSON 직렬화', () {
      final event = AdEvent(
        adUnitId: 'unit1',
        adType: AdType.interstitial,
        eventType: AdEventType.shown,
        timestamp: DateTime(2024, 1, 1),
        data: {'key': 'value'},
      );

      final json = event.toJson();
      final restored = AdEvent.fromJson(json);

      expect(restored.adUnitId, event.adUnitId);
      expect(restored.adType, event.adType);
      expect(restored.eventType, event.eventType);
    });
  });

  group('AdStats', () {
    test('기본 생성', () {
      const stats = AdStats(adUnitId: 'unit1');

      expect(stats.impressions, 0);
      expect(stats.clicks, 0);
      expect(stats.ctr, 0.0);
    });

    test('copyWith', () {
      const stats = AdStats(adUnitId: 'unit1');
      final updated = stats.copyWith(impressions: 100, clicks: 10);

      expect(updated.impressions, 100);
      expect(updated.clicks, 10);
    });

    test('recalculateCtr', () {
      const stats = AdStats(
        adUnitId: 'unit1',
        impressions: 100,
        clicks: 5,
      );

      final recalculated = stats.recalculateCtr();

      expect(recalculated.ctr, 0.05);
    });

    test('recalculateCtr - 0 impressions', () {
      const stats = AdStats(
        adUnitId: 'unit1',
        impressions: 0,
        clicks: 0,
      );

      final recalculated = stats.recalculateCtr();

      expect(recalculated.ctr, 0.0);
    });

    test('JSON 직렬화', () {
      const stats = AdStats(
        adUnitId: 'unit1',
        impressions: 50,
        clicks: 5,
        rewards: 3,
        errors: 1,
        ctr: 0.1,
      );

      final json = stats.toJson();
      final restored = AdStats.fromJson(json);

      expect(restored.impressions, stats.impressions);
      expect(restored.clicks, stats.clicks);
      expect(restored.rewards, stats.rewards);
      expect(restored.ctr, stats.ctr);
    });
  });

  group('AdFrequencyControl', () {
    test('hasReachedDailyLimit', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        impressionsToday: 10,
        lastResetDate: DateTime.now(),
      );

      expect(control.hasReachedDailyLimit(10), true);
      expect(control.hasReachedDailyLimit(15), false);
      expect(control.hasReachedDailyLimit(null), false);
    });

    test('isInCooldown', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        lastImpressionTime: DateTime.now(),
        lastResetDate: DateTime.now(),
      );

      expect(control.isInCooldown(const Duration(minutes: 5)), true);
      expect(control.isInCooldown(null), false);
    });

    test('isInCooldown - 쿨다운 지남', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        lastImpressionTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastResetDate: DateTime.now(),
      );

      expect(control.isInCooldown(const Duration(minutes: 5)), false);
    });

    test('recordImpression', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        impressionsToday: 5,
        lastResetDate: DateTime.now(),
      );

      final updated = control.recordImpression();

      expect(updated.impressionsToday, 6);
      expect(updated.lastImpressionTime, isNotNull);
    });

    test('needsDailyReset', () {
      final yesterday = AdFrequencyControl(
        adUnitId: 'unit1',
        lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final today = AdFrequencyControl(
        adUnitId: 'unit1',
        lastResetDate: DateTime.now(),
      );

      expect(yesterday.needsDailyReset(), true);
      expect(today.needsDailyReset(), false);
    });

    test('resetDaily', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        impressionsToday: 10,
        lastImpressionTime: DateTime.now(),
        lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final reset = control.resetDaily();

      expect(reset.impressionsToday, 0);
      expect(reset.lastImpressionTime, isNull);
    });

    test('JSON 직렬화', () {
      final control = AdFrequencyControl(
        adUnitId: 'unit1',
        impressionsToday: 5,
        lastImpressionTime: DateTime(2024, 1, 1, 12, 0),
        lastResetDate: DateTime(2024, 1, 1),
      );

      final json = control.toJson();
      final restored = AdFrequencyControl.fromJson(json);

      expect(restored.adUnitId, control.adUnitId);
      expect(restored.impressionsToday, control.impressionsToday);
    });
  });

  group('RewardedAdResult', () {
    test('success factory', () {
      const reward = AdReward(type: 'coins', amount: 100);
      final result = RewardedAdResult.success(reward);

      expect(result.success, true);
      expect(result.userEarnedReward, true);
      expect(result.reward?.amount, 100);
    });

    test('noReward factory', () {
      final result = RewardedAdResult.noReward();

      expect(result.success, true);
      expect(result.userEarnedReward, false);
    });

    test('failure factory', () {
      final result = RewardedAdResult.failure('Network error');

      expect(result.success, false);
      expect(result.errorMessage, 'Network error');
    });
  });

  group('AdManager', () {
    late AdManager manager;

    setUp(() async {
      manager = AdManager();
      await manager.initialize(
        provider: AdProvider.test,
        adUnits: const [
          AdUnitConfig(
            id: 'interstitial_1',
            type: AdType.interstitial,
            androidId: 'android_1',
            iosId: 'ios_1',
          ),
          AdUnitConfig(
            id: 'rewarded_1',
            type: AdType.rewarded,
            androidId: 'android_2',
            iosId: 'ios_2',
          ),
        ],
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('초기화', () {
      expect(manager.isInitialized, true);
      expect(manager.provider, AdProvider.test);
      expect(manager.adUnitIds.length, 2);
    });

    test('중복 초기화 방지', () async {
      await manager.initialize(provider: AdProvider.admob);

      // 처음 초기화가 유지됨
      expect(manager.provider, AdProvider.test);
    });

    test('광고 단위 등록', () {
      manager.registerAdUnit(const AdUnitConfig(
        id: 'new_unit',
        type: AdType.banner,
        androidId: 'android',
        iosId: 'ios',
      ));

      expect(manager.adUnitIds, contains('new_unit'));
      expect(manager.getAdUnit('new_unit')?.type, AdType.banner);
    });

    test('광고 상태', () {
      expect(manager.getAdState('interstitial_1'), AdState.notInitialized);
    });

    test('광고 비활성화', () {
      manager.disableAds();

      expect(manager.adsDisabled, true);
      expect(manager.canShowAd('interstitial_1'), false);
    });

    test('광고 활성화', () {
      manager.disableAds();
      manager.enableAds();

      expect(manager.adsDisabled, false);
    });

    test('광고 로드 - 테스트 모드', () async {
      final success = await manager.loadAd('interstitial_1');

      expect(success, true);
      expect(manager.getAdState('interstitial_1'), AdState.ready);
    });

    test('광고 로드 - 미등록 광고', () async {
      final success = await manager.loadAd('nonexistent');

      expect(success, false);
    });

    test('광고 로드 - 미초기화', () async {
      final newManager = AdManager();

      final success = await newManager.loadAd('any');

      expect(success, false);
      newManager.dispose();
    });

    test('전면 광고 표시 - 테스트 모드', () async {
      await manager.loadAd('interstitial_1');
      final success = await manager.showInterstitial('interstitial_1');

      expect(success, true);
      expect(manager.getStats('interstitial_1')?.impressions, 1);
    });

    test('전면 광고 표시 - 로드 안됨', () async {
      final success = await manager.showInterstitial('interstitial_1');

      expect(success, false);
    });

    test('전면 광고 표시 - 잘못된 타입', () async {
      await manager.loadAd('rewarded_1');
      final success = await manager.showInterstitial('rewarded_1');

      expect(success, false);
    });

    test('보상형 광고 표시 - 테스트 모드', () async {
      await manager.loadAd('rewarded_1');
      final result = await manager.showRewarded('rewarded_1');

      expect(result.success, true);
      expect(result.userEarnedReward, true);
      expect(result.reward?.type, 'coins');
      expect(result.reward?.amount, 100);
    });

    test('보상형 광고 - 커스텀 보상', () async {
      await manager.loadAd('rewarded_1');
      final result = await manager.showRewarded(
        'rewarded_1',
        rewardType: 'gems',
        rewardAmount: 50,
      );

      expect(result.reward?.type, 'gems');
      expect(result.reward?.amount, 50);
    });

    test('보상형 광고 - 잘못된 타입', () async {
      await manager.loadAd('interstitial_1');
      final result = await manager.showRewarded('interstitial_1');

      expect(result.success, false);
    });

    test('클릭 기록', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');
      manager.recordClick('interstitial_1');

      final stats = manager.getStats('interstitial_1')!;
      expect(stats.clicks, 1);
      expect(stats.ctr, 1.0); // 1 click / 1 impression
    });

    test('이벤트 로그', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');

      final events = manager.getEventLog(adUnitId: 'interstitial_1');

      expect(events.length, greaterThan(0));
      expect(events.any((e) => e.eventType == AdEventType.shown), true);
    });

    test('이벤트 로그 필터링', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');
      await manager.loadAd('rewarded_1');

      final interstitialEvents = manager.getEventLog(adUnitId: 'interstitial_1');
      final loadEvents = manager.getEventLog(eventType: AdEventType.loaded);

      expect(interstitialEvents.every((e) => e.adUnitId == 'interstitial_1'), true);
      expect(loadEvents.every((e) => e.eventType == AdEventType.loaded), true);
    });

    test('이벤트 로그 제한', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');

      final events = manager.getEventLog(limit: 3);
      expect(events.length, 3);
    });

    test('이벤트 로그 클리어', () async {
      await manager.loadAd('interstitial_1');
      manager.clearEventLog();

      expect(manager.eventLogCount, 0);
    });

    test('통계 리셋', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');

      manager.resetStats('interstitial_1');

      expect(manager.getStats('interstitial_1')?.impressions, 0);
    });

    test('전체 클리어', () {
      manager.clear();

      expect(manager.isInitialized, false);
      expect(manager.adUnitIds, isEmpty);
    });

    test('JSON 저장/복원', () async {
      await manager.loadAd('interstitial_1');
      await manager.showInterstitial('interstitial_1');
      manager.disableAds();

      final json = manager.toJson();

      final newManager = AdManager();
      await newManager.initialize(adUnits: const [
        AdUnitConfig(
          id: 'interstitial_1',
          type: AdType.interstitial,
          androidId: 'android',
          iosId: 'ios',
        ),
      ]);
      newManager.fromJson(json);

      expect(newManager.adsDisabled, true);
      expect(newManager.getStats('interstitial_1')?.impressions, 1);

      newManager.dispose();
    });

    test('ChangeNotifier 동작', () async {
      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      await manager.loadAd('interstitial_1');

      expect(notifyCount, greaterThan(0));
    });
  });

  group('AdManager - 빈도 제어', () {
    late AdManager manager;

    setUp(() async {
      manager = AdManager();
      await manager.initialize(
        adUnits: const [
          AdUnitConfig(
            id: 'limited',
            type: AdType.interstitial,
            androidId: 'android',
            iosId: 'ios',
            maxDailyImpressions: 3,
            cooldown: Duration(seconds: 1),
          ),
        ],
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('일일 노출 제한', () async {
      await manager.loadAd('limited');

      // 3회 표시
      await manager.showInterstitial('limited');
      await manager.loadAd('limited');
      await manager.showInterstitial('limited');
      await manager.loadAd('limited');
      await manager.showInterstitial('limited');

      // 4회째 - 불가
      await manager.loadAd('limited');
      expect(manager.canShowAd('limited'), false);
    });

    test('남은 일일 노출 수', () async {
      await manager.loadAd('limited');
      await manager.showInterstitial('limited');

      expect(manager.getRemainingDailyImpressions('limited'), 2);
    });

    test('쿨다운', () async {
      await manager.loadAd('limited');
      await manager.showInterstitial('limited');

      // 즉시 표시 시도 - 쿨다운 중
      await manager.loadAd('limited');
      expect(manager.canShowAd('limited'), false);

      // 쿨다운 시간 확인
      final remaining = manager.getRemainingCooldown('limited');
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, lessThanOrEqualTo(1));
    });
  });

  group('AdManager - 콜백', () {
    late AdManager manager;

    setUp(() async {
      manager = AdManager();
      await manager.initialize(
        adUnits: const [
          AdUnitConfig(
            id: 'interstitial',
            type: AdType.interstitial,
            androidId: 'android',
            iosId: 'ios',
          ),
          AdUnitConfig(
            id: 'rewarded',
            type: AdType.rewarded,
            androidId: 'android',
            iosId: 'ios',
          ),
        ],
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('로드 콜백 성공', () async {
      int loadCount = 0;

      manager.onLoadAd = (config) async {
        loadCount++;
      };

      await manager.loadAd('interstitial');

      expect(loadCount, 1);
      expect(manager.getAdState('interstitial'), AdState.ready);
    });

    test('로드 콜백 실패', () async {
      manager.onLoadAd = (config) async {
        throw Exception('Load failed');
      };

      await manager.loadAd('interstitial');

      expect(manager.getAdState('interstitial'), AdState.error);
      expect(manager.getStats('interstitial')?.errors, 1);
    });

    test('표시 콜백', () async {
      bool shown = false;

      manager.onShowAd = (config) async {
        shown = true;
        return true;
      };

      await manager.loadAd('interstitial');
      await manager.showInterstitial('interstitial');

      expect(shown, true);
    });

    test('보상형 광고 콜백', () async {
      manager.onShowRewardedAd = (config, defaultReward) async {
        return RewardedAdResult.success(
          const AdReward(type: 'premium', amount: 500),
        );
      };

      await manager.loadAd('rewarded');
      final result = await manager.showRewarded('rewarded');

      expect(result.reward?.type, 'premium');
      expect(result.reward?.amount, 500);
    });

    test('이벤트 콜백', () async {
      final events = <AdEvent>[];

      manager.onAdEvent = (event) {
        events.add(event);
      };

      await manager.loadAd('interstitial');

      expect(events.any((e) => e.eventType == AdEventType.loaded), true);
    });
  });

  group('AdManager - 미리 로드', () {
    late AdManager manager;

    setUp(() async {
      manager = AdManager();
      await manager.initialize(
        adUnits: const [
          AdUnitConfig(
            id: 'inter1',
            type: AdType.interstitial,
            androidId: 'a',
            iosId: 'i',
          ),
          AdUnitConfig(
            id: 'inter2',
            type: AdType.interstitial,
            androidId: 'a',
            iosId: 'i',
          ),
          AdUnitConfig(
            id: 'rewarded1',
            type: AdType.rewarded,
            androidId: 'a',
            iosId: 'i',
          ),
        ],
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('모든 광고 미리 로드', () async {
      await manager.preloadAllAds();

      expect(manager.getAdState('inter1'), AdState.ready);
      expect(manager.getAdState('inter2'), AdState.ready);
      expect(manager.getAdState('rewarded1'), AdState.ready);
    });

    test('타입별 광고 미리 로드', () async {
      await manager.preloadAdsByType(AdType.interstitial);

      expect(manager.getAdState('inter1'), AdState.ready);
      expect(manager.getAdState('inter2'), AdState.ready);
      expect(manager.getAdState('rewarded1'), AdState.notInitialized);
    });
  });
}

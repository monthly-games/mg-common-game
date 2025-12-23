# mg-common-game 수익화 공통 모듈 설계

> 목적: 24개 게임에서 재사용 가능한 공통 수익화 시스템 모듈 설계

---

## 1. 모듈 구조

```
lib/
├── core/
│   └── monetization/
│       ├── ads/
│       │   ├── ad_manager.dart           # 광고 통합 관리자
│       │   ├── rewarded_ad_service.dart  # 보상형 광고
│       │   ├── interstitial_service.dart # 전면 광고
│       │   └── ad_frequency_controller.dart # 빈도 제어
│       │
│       ├── iap/
│       │   ├── iap_manager.dart          # IAP 통합 관리자
│       │   ├── product_catalog.dart      # 상품 카탈로그
│       │   ├── purchase_validator.dart   # 구매 검증
│       │   └── receipt_handler.dart      # 영수증 처리
│       │
│       ├── offers/
│       │   ├── offer_engine.dart         # 오퍼 엔진
│       │   ├── personalization.dart      # 개인화 로직
│       │   ├── offer_templates.dart      # 오퍼 템플릿
│       │   └── trigger_system.dart       # 트리거 시스템
│       │
│       ├── economy/
│       │   ├── currency_manager.dart     # 재화 관리
│       │   ├── wallet_service.dart       # 지갑 서비스
│       │   └── exchange_rate.dart        # 환율 관리
│       │
│       └── analytics/
│           ├── monetization_events.dart  # 수익화 이벤트
│           └── ltv_tracker.dart          # LTV 추적
```

---

## 2. 광고 모듈 (Ads)

### 2.1 AdManager

```dart
abstract class AdManager {
  // 광고 초기화
  Future<void> initialize(AdConfig config);

  // 보상형 광고
  Future<AdResult> showRewardedAd({
    required String placement,
    required RewardType rewardType,
  });

  // 전면 광고
  Future<AdResult> showInterstitial({
    required String placement,
  });

  // 광고 가용성 확인
  bool isRewardedAdReady();
  bool isInterstitialReady();

  // 개인화된 광고 빈도 조회
  AdFrequency getPersonalizedFrequency(String userId);
}
```

### 2.2 광고 배치 표준 (Placements)

| Placement ID | 타입 | 설명 | 기본 빈도 |
|-------------|------|------|----------|
| `stage_clear` | Rewarded | 스테이지 클리어 후 2배 보상 | 무제한 |
| `revive` | Rewarded | 부활/재도전 | 3회/일 |
| `daily_bonus` | Rewarded | 일일 보너스 2배 | 1회/일 |
| `gacha_extra` | Rewarded | 가챠 추가 뽑기 | 5회/일 |
| `offline_bonus` | Rewarded | 오프라인 보상 증가 | 2회/일 |
| `stage_fail` | Interstitial | 스테이지 실패 후 | 3분 간격 |
| `session_end` | Interstitial | 세션 종료 시 | 5분 간격 |

### 2.3 개인화 빈도 제어

```dart
class AdFrequencyController {
  // 유저 세그먼트별 광고 빈도 조정
  AdFrequency calculateFrequency(UserProfile profile) {
    if (profile.isPayer) {
      // 과금 유저: 전면 광고 최소화, 보상형만
      return AdFrequency.payer;
    }
    if (profile.adResistance > 0.7) {
      // 광고 거부 성향: 보상 강화로 유도
      return AdFrequency.lowWithBonus;
    }
    if (profile.engagementScore > 0.8) {
      // 고관여 유저: 보상형 위주
      return AdFrequency.engaged;
    }
    return AdFrequency.standard;
  }
}
```

---

## 3. IAP 모듈 (In-App Purchase)

### 3.1 상품 카탈로그 템플릿

```dart
enum ProductType {
  starterPack,      // 초보자 팩
  valuePack,        // 가치 팩
  comebackPack,     // 복귀자 팩
  subscription,     // 구독
  consumable,       // 소모품
  nonConsumable,    // 비소모품
}

class ProductTemplate {
  static const Map<String, ProductConfig> templates = {
    'starter_pack_099': ProductConfig(
      type: ProductType.starterPack,
      price: 0.99,
      contents: ['premium_currency_500', 'stamina_full', 'rare_ticket_1'],
      oneTimePurchase: true,
      showUntilLevel: 10,
    ),
    'value_pack_499': ProductConfig(
      type: ProductType.valuePack,
      price: 4.99,
      contents: ['premium_currency_3000', 'epic_ticket_3', 'gold_boost_24h'],
      valueMultiplier: 3.0,  // 가성비 지표
    ),
    'monthly_pass': ProductConfig(
      type: ProductType.subscription,
      price: 4.99,
      duration: Duration(days: 30),
      dailyRewards: ['premium_currency_100', 'stamina_30'],
    ),
  };
}
```

### 3.2 가격 티어

| 티어 | USD | 용도 |
|-----|-----|------|
| Tier 1 | $0.99 | 스타터 팩, 소액 소모품 |
| Tier 2 | $2.99 | 소형 번들 |
| Tier 3 | $4.99 | 중형 번들, 월정액 |
| Tier 4 | $9.99 | 대형 번들 |
| Tier 5 | $19.99 | 프리미엄 번들 |
| Tier 6 | $49.99 | 최고급 팩 |

### 3.3 Pay-to-Win 방지 규칙

```dart
class PurchaseValidator {
  // 공정성 검증
  bool validateFairness(Product product) {
    // 금지: 직접 전투력 증가
    if (product.directPowerIncrease > 0) return false;

    // 금지: PVP 우위 아이템
    if (product.pvpAdvantage) return false;

    // 허용: 시간 단축 (Pay-for-Speed)
    // 허용: 외형/꾸미기
    // 허용: 편의 기능
    return true;
  }
}
```

---

## 4. 오퍼 엔진 (Personalized Offers)

### 4.1 오퍼 트리거 시스템

```dart
enum OfferTrigger {
  firstSession,           // 첫 세션
  levelUp,                // 레벨업
  stageClear,             // 스테이지 클리어
  stageFail,              // 스테이지 실패
  lowCurrency,            // 재화 부족
  returnAfterAbsence,     // 복귀 유저
  churnRisk,              // 이탈 위험
  highValuePotential,     // 고가치 잠재력
  seasonStart,            // 시즌 시작
  eventStart,             // 이벤트 시작
}

class TriggerSystem {
  List<Offer> getTriggeredOffers(UserContext context) {
    final offers = <Offer>[];

    if (context.isChurnRisk) {
      offers.add(OfferTemplates.comebackBonus);
    }

    if (context.justFailedStage && context.failCount >= 3) {
      offers.add(OfferTemplates.powerBoost);
    }

    if (context.isHighValuePotential) {
      offers.add(OfferTemplates.premiumBundle);
    }

    return offers;
  }
}
```

### 4.2 개인화 로직

```dart
class PersonalizationEngine {
  Offer selectBestOffer(UserProfile profile, List<Offer> candidates) {
    // 유저 세그먼트 판단
    final segment = _classifyUser(profile);

    // 세그먼트별 오퍼 가중치 적용
    final scored = candidates.map((offer) {
      double score = offer.baseScore;

      switch (segment) {
        case UserSegment.whale:
          score *= offer.whaleMultiplier;
          break;
        case UserSegment.minnow:
          score *= offer.minnowMultiplier;
          break;
        case UserSegment.nonPayer:
          score *= offer.nonPayerMultiplier;
          break;
      }

      return ScoredOffer(offer, score);
    }).toList();

    // 최고 점수 오퍼 반환
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.first.offer;
  }

  UserSegment _classifyUser(UserProfile profile) {
    if (profile.totalSpent > 100) return UserSegment.whale;
    if (profile.totalSpent > 10) return UserSegment.dolphin;
    if (profile.totalSpent > 0) return UserSegment.minnow;
    return UserSegment.nonPayer;
  }
}
```

### 4.3 오퍼 템플릿

```dart
class OfferTemplates {
  // 스타터 패키지 (신규 유저)
  static final starterPack = Offer(
    id: 'starter_pack',
    trigger: OfferTrigger.firstSession,
    price: 0.99,
    discount: 0.8,  // 80% 할인 표시
    contents: {...},
    expiresIn: Duration(hours: 24),
  );

  // 복귀 패키지
  static final comebackPack = Offer(
    id: 'comeback_pack',
    trigger: OfferTrigger.returnAfterAbsence,
    price: 4.99,
    contents: {...},
    requiredAbsenceDays: 7,
  );

  // 파워업 패키지 (실패 후)
  static final powerBoost = Offer(
    id: 'power_boost',
    trigger: OfferTrigger.stageFail,
    price: 2.99,
    contents: {...},
    showAfterFailCount: 3,
  );

  // VIP 번들 (고가치 유저)
  static final vipBundle = Offer(
    id: 'vip_bundle',
    trigger: OfferTrigger.highValuePotential,
    price: 19.99,
    contents: {...},
    exclusiveFlag: true,
  );
}
```

---

## 5. 재화 시스템 (Economy)

### 5.1 공통 재화 타입

```dart
enum CurrencyType {
  // 하드 커런시 (유료)
  gem,              // 보석/다이아

  // 소프트 커런시 (무료)
  gold,             // 골드/코인

  // 에너지
  stamina,          // 스태미나/행동력

  // 특수 재화
  eventCurrency,    // 이벤트 전용
  guildCurrency,    // 길드 전용
  pvpCurrency,      // PVP 전용
}

class CurrencyManager {
  // 재화 추가 (출처 추적)
  Future<void> add(CurrencyType type, int amount, String source);

  // 재화 소비 (용도 추적)
  Future<bool> spend(CurrencyType type, int amount, String purpose);

  // 잔액 조회
  int getBalance(CurrencyType type);

  // 충분한지 확인
  bool canAfford(CurrencyType type, int amount);
}
```

### 5.2 하드/소프트 커런시 밸런스

| 항목 | 하드 커런시 | 소프트 커런시 |
|-----|-----------|-------------|
| 획득 경로 | IAP, 광고 보상, 업적 | 스테이지, 방치, 퀘스트 |
| 주요 용도 | 가챠, 즉시 완료, 프리미엄 | 강화, 업그레이드, 일반 구매 |
| 일일 무료 획득량 | 50~100 | 10,000~50,000 |
| 환율 기준 | 100 = $0.99 | 변동 (인플레 관리) |

---

## 6. 분석 이벤트 (Analytics)

### 6.1 수익화 이벤트 스키마

```dart
class MonetizationEvents {
  // 광고 시청
  static void logAdWatched({
    required String adType,      // rewarded, interstitial
    required String placement,
    required bool completed,
    String? rewardType,
    int? rewardAmount,
  });

  // IAP 구매
  static void logPurchase({
    required String productId,
    required double price,
    required String currency,
    required bool success,
    String? failReason,
  });

  // 오퍼 노출/클릭
  static void logOfferImpression({
    required String offerId,
    required String trigger,
  });

  static void logOfferClick({
    required String offerId,
    required String action,  // purchase, dismiss, later
  });

  // 재화 변동
  static void logCurrencyChange({
    required String currencyType,
    required int amount,
    required String source,    // stage_clear, iap, ad_reward
    required int balanceAfter,
  });
}
```

### 6.2 KPI 추적

```dart
class LtvTracker {
  // ARPDAU 계산
  double calculateArpdau(DateTime date);

  // 광고 ARPDAU
  double calculateAdsArpdau(DateTime date);

  // IAP ARPDAU
  double calculateIapArpdau(DateTime date);

  // 전환율 (비과금→과금)
  double calculateConversionRate(DateRange range);

  // 예상 LTV
  double predictLtv(UserProfile profile);
}
```

---

## 7. Remote Config 연동

### 7.1 설정 키

```dart
class MonetizationConfig {
  // 광고 설정
  static const adInterstitialCooldown = 'monetization_ad_interstitial_cooldown';
  static const adRewardedDailyLimit = 'monetization_ad_rewarded_daily_limit';
  static const adRewardMultiplier = 'monetization_ad_reward_multiplier';

  // IAP 설정
  static const iapStarterPackEnabled = 'monetization_iap_starter_enabled';
  static const iapPriceOverrides = 'monetization_iap_price_overrides';

  // 오퍼 설정
  static const offerChurnThreshold = 'monetization_offer_churn_threshold';
  static const offerWhaleThreshold = 'monetization_offer_whale_threshold';

  // A/B 테스트
  static const abTestGroup = 'monetization_ab_group';
}
```

---

## 8. 사용 예시

### 8.1 게임에서 초기화

```dart
class GameApp extends StatelessWidget {
  @override
  void initState() {
    // 수익화 모듈 초기화
    MonetizationModule.initialize(
      gameId: 'game_0001',
      adConfig: AdConfig(
        rewardedAdUnitId: 'ca-app-pub-xxx',
        interstitialAdUnitId: 'ca-app-pub-xxx',
      ),
      iapConfig: IapConfig(
        products: ProductCatalog.game0001,
      ),
    );
  }
}
```

### 8.2 보상형 광고 표시

```dart
void onStageClear() async {
  final result = await AdManager.instance.showRewardedAd(
    placement: 'stage_clear',
    rewardType: RewardType.doubleReward,
  );

  if (result.completed) {
    // 2배 보상 지급
    CurrencyManager.add(CurrencyType.gold, reward * 2, 'ad_reward');
  }
}
```

### 8.3 개인화 오퍼 표시

```dart
void checkOffers(UserContext context) {
  final offers = TriggerSystem.getTriggeredOffers(context);

  if (offers.isNotEmpty) {
    final bestOffer = PersonalizationEngine.selectBestOffer(
      userProfile,
      offers,
    );

    showOfferPopup(bestOffer);
  }
}
```

---

## 9. 게임별 커스터마이징

각 게임은 이 공통 모듈을 상속/확장하여 게임 특성에 맞게 커스터마이징:

```dart
// game_0001 전용 수익화 설정
class Game0001Monetization extends MonetizationModule {
  @override
  List<String> get adPlacements => [
    'puzzle_hint',      // 퍼즐 힌트 광고
    'dungeon_skip',     // 던전 스킵 광고
    ...super.adPlacements,
  ];

  @override
  ProductCatalog get products => ProductCatalog.game0001;
}
```

---

이 공통 모듈을 기반으로 각 게임은 `monetization_design.md` 문서에서 게임별 수익화 전략을 정의합니다.

# MG Common Game

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.16+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.2+-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Flame-1.14+-orange?logo=flame" alt="Flame">
  <img src="https://img.shields.io/badge/Games-52-green" alt="52 Games">
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License">
</p>

**Flutter/Flame 기반 공통 게임 엔진** - 52개 모바일 게임 포트폴리오를 위한 공유 라이브러리

## 목차

- [개요](#개요)
- [빠른 시작](#빠른-시작)
- [시스템 아키텍처](#시스템-아키텍처)
- [핵심 시스템](#핵심-시스템)
- [게임 시스템](#게임-시스템)
- [수익화 시스템](#수익화-시스템)
- [소셜 시스템](#소셜-시스템)
- [UI 컴포넌트](#ui-컴포넌트)
- [개발 도구](#개발-도구)
- [문서](#문서)
- [52개 게임 목록](#52개-게임-목록)

---

## 개요

MG Common Game은 52개 모바일 게임 포트폴리오 프로젝트를 위한 공유 라이브러리입니다.

### 특징

| 카테고리 | 기능 |
|----------|------|
| **게임 엔진** | Flame 기반 게임 루프, 씬 관리, 에셋 관리, 오브젝트 풀링 |
| **수익화** | 가챠 (천장/픽업), 배틀패스, 상점, 번들 |
| **분석** | Firebase Analytics, Crashlytics, 성능 모니터링 |
| **다국어** | 현지화 시스템, RTL 지원, 동적 폰트 |
| **클라우드** | 클라우드 저장, 충돌 해결, 오프라인 동기화 |
| **알림** | 로컬/푸시 알림, 예약 알림, 리텐션 알림 |
| **테스팅** | Mock 서비스, 테스트 헬퍼, 통합 테스트 템플릿 |
| **CI/CD** | GitHub Actions 워크플로우, 자동 빌드/배포 |

### 지원 장르

| 장르 | 주요 시스템 |
|------|-------------|
| **방치형/클리커** | OfflineProgressManager, AutoClickerManager, PrestigeManager |
| **매치-3/머지** | Match3Board, GemTypes, PowerUps, CascadeEffect |
| **러너/리듬** | RunnerLane, RhythmNote, JudgmentSystem, ComboManager |
| **카드/TCG** | CardTypes, DeckManager, CardBattleState, DrawPile |
| **RPG/전투** | BattleEntity, BattleManager, SkillSystem, TurnManager |

---

## 빠른 시작

### 1. Submodule 추가

```bash
git submodule add https://github.com/monthly-games/mg-common-game.git libs/mg_common_game
```

### 2. pubspec.yaml 설정

```yaml
dependencies:
  mg_common_game:
    path: libs/mg_common_game
```

### 3. 기본 사용법

```dart
import 'package:mg_common_game/mg_common_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 코어 시스템 초기화
  await AudioManager.instance.init();
  await SaveManager.instance.init();
  await AnalyticsManager.instance.init();

  // 알림 시스템 (선택)
  await NotificationManager.instance.initialize();

  // 클라우드 저장 (선택)
  await CloudSaveManager.instance.initialize(
    gameId: 'my_game',
    userId: 'user_123',
  );

  runApp(MyGameApp());
}
```

---

## 시스템 아키텍처

```
mg_common_game/
├── lib/
│   ├── core/                    # 핵심 시스템
│   │   ├── engine/              # 게임 엔진 (Flame)
│   │   ├── audio/               # 오디오 매니저
│   │   ├── ui/                  # UI 컴포넌트
│   │   ├── analytics/           # 분석 시스템
│   │   ├── localization/        # 현지화
│   │   ├── performance/         # 성능 모니터링
│   │   ├── optimization/        # 최적화 도구
│   │   ├── notifications/       # 푸시 알림
│   │   ├── cloud/               # 클라우드 저장
│   │   └── systems/             # 저장/설정
│   │
│   ├── systems/                 # 게임 시스템
│   │   ├── progression/         # 진행 (레벨, 업적, 프레스티지)
│   │   ├── inventory/           # 인벤토리
│   │   ├── crafting/            # 제작
│   │   ├── quests/              # 퀘스트 (일일/주간)
│   │   ├── stats/               # 통계
│   │   ├── idle/                # 방치형 시스템
│   │   ├── battle/              # 전투 시스템
│   │   ├── gacha/               # 가챠 시스템
│   │   ├── battlepass/          # 배틀패스
│   │   ├── shop/                # 상점 시스템
│   │   ├── social/              # 소셜 시스템
│   │   ├── events/              # 이벤트 시스템
│   │   └── settings/            # 설정
│   │
│   ├── ui/animations/           # UI 애니메이션
│   ├── testing/                 # 테스팅 도구
│   └── mg_common_game.dart      # 메인 export
│
├── templates/                   # 출시 템플릿
│   ├── store/                   # 스토어 메타데이터
│   └── legal/                   # 법적 문서
│
├── tools/                       # 개발 도구
├── doc/                         # 문서
├── example/                     # 예제 코드
└── .github/workflows/           # CI/CD
```

---

## 핵심 시스템

### 오디오 시스템

```dart
// 초기화
await AudioManager.instance.init();

// BGM/SFX 재생
AudioManager.instance.playBgm('assets/audio/bgm_main.mp3');
AudioManager.instance.playSfx('assets/audio/sfx_click.mp3');

// 볼륨 조절
AudioManager.instance.setBgmVolume(0.8);
AudioManager.instance.setSfxVolume(1.0);
```

### 저장 시스템

```dart
// 초기화
await SaveManager.instance.init();

// 저장/로드
await SaveManager.instance.save('player_level', 10);
final level = SaveManager.instance.load<int>('player_level') ?? 1;
```

### 클라우드 저장

```dart
// 초기화
await CloudSaveManager.instance.initialize(
  gameId: 'my_game',
  userId: 'user_123',
  defaultResolution: ConflictResolution.useNewer,
);

// 저장 및 동기화
await CloudSaveManager.instance.save({'level': 10, 'gold': 5000});
await CloudSaveManager.instance.sync();
```

### 알림 시스템

```dart
// 초기화
await NotificationManager.instance.initialize();
await NotificationManager.instance.requestPermission();

// 예약 알림
await NotificationManager.instance.scheduleDailyRewardNotification(
  time: NotificationScheduler.nextOccurrence(9, 0),
);

// 에너지 충전 알림
await NotificationManager.instance.scheduleEnergyFullNotification(
  time: NotificationScheduler.energyRefillTime(5, 10, Duration(minutes: 5)),
);
```

### 분석 시스템

```dart
// 이벤트 추적
AnalyticsManager.instance.logEvent('level_complete', {
  'level': 5, 'score': 1000, 'time_seconds': 120,
});

// 화면 추적
AnalyticsManager.instance.logScreenView('main_menu');
```

### 현지화 시스템

```dart
// 초기화
await LocalizationManager.instance.init(
  supportedLocales: ['ko', 'en', 'ja'],
  defaultLocale: 'ko',
);

// 번역 사용
final text = LocalizationManager.instance.translate('welcome_message');
```

---

## 게임 시스템

### 진행 시스템

```dart
// 레벨 시스템
final levelManager = ProgressionManager();
levelManager.addExp(100);

// 업그레이드 시스템
final upgradeManager = UpgradeManager();
upgradeManager.registerUpgrade(Upgrade(
  id: 'damage', baseCost: 100, costMultiplier: 1.5,
));
upgradeManager.purchase('damage');

// 업적 시스템
final achievementManager = AchievementManager();
achievementManager.unlock('first_kill');

// 프레스티지 시스템
final prestigeManager = PrestigeManager(
  formula: PrestigeFormula.logarithmic,
);
await prestigeManager.prestige();
```

### 방치형 시스템

```dart
// 오프라인 진행
final offlineManager = OfflineProgressManager(
  maxOfflineHours: 24,
  offlineEfficiency: 0.5,
);
final rewards = offlineManager.calculateOfflineRewards(
  currentGoldPerSecond: 100,
);

// 오토클리커
final autoClicker = AutoClickerManager();
autoClicker.purchase('basic');
print('Total CPS: ${autoClicker.totalCps}');
```

### 전투 시스템

```dart
// 전투 엔티티
final player = BattleEntity(
  id: 'player',
  stats: BattleStats(hp: 100, attack: 20, defense: 10),
);

// 전투 실행
final battleManager = BattleManager();
battleManager.startBattle([player], [enemy]);
final result = battleManager.executeAttack(player, enemy);
```

---

## 수익화 시스템

### 가챠 시스템

```dart
// 가챠 풀 정의
final pool = GachaPool(
  id: 'banner_001',
  items: [
    GachaItem(id: 'ssr_001', rarity: GachaRarity.legendary, weight: 1),
    GachaItem(id: 'sr_001', rarity: GachaRarity.epic, weight: 5),
  ],
  pickupItemIds: ['ssr_001'],
  pityConfig: PityConfig(softPityStart: 70, hardPity: 90),
);

// 뽑기
final gachaManager = GachaManager();
gachaManager.addPool(pool);
final result = gachaManager.pull('banner_001');
final results = gachaManager.pull10('banner_001');
```

### 배틀패스 시스템

```dart
// 시즌 생성
final season = BattlePassSeason(
  id: 'season_001',
  maxLevel: 50,
  tiers: [...],
);

// 배틀패스 매니저
final battlePassManager = BattlePassManager();
await battlePassManager.startSeason(season);
battlePassManager.addExp(500);
battlePassManager.claimReward(5, isPremium: true);
```

### 상점 시스템

```dart
// 상품 등록
shopManager.addProduct(ShopProduct(
  id: 'gem_pack_small',
  price: Price(amount: 0.99, currency: 'USD'),
  rewards: {'gems': 50},
));

// 구매
await shopManager.purchase('gem_pack_small');
```

---

## 소셜 시스템

```dart
// 친구
await friendManager.sendFriendRequest('user_456');
await friendManager.sendGift('user_456', {'energy': 5});

// 길드
await guildManager.createGuild('Awesome Guild');
await guildManager.sendMessage('Hello!');

// 리더보드
await leaderboardManager.submitScore('weekly_score', 10000);
final rankings = await leaderboardManager.getRankings('weekly_score');
```

---

## UI 컴포넌트

### 디자인 시스템

```dart
import 'package:mg_common_game/core/ui/mg_ui.dart';

// 색상
MGColors.primary, MGColors.gold, MGColors.error, MGColors.success

// 타이포그래피
MGTextStyles.h1, MGTextStyles.body, MGTextStyles.hud

// 간격
MGSpacing.xs (4px), MGSpacing.sm (8px), MGSpacing.md (16px), MGSpacing.lg (24px)
```

### 주요 컴포넌트

```dart
// 버튼
MGButton.primary(label: 'START', onPressed: () {});
MGIconButton(icon: Icons.settings, onPressed: () {});

// 리소스 표시
MGResourceBar(icon: Icons.monetization_on, value: '1,234');
MGLinearProgress(value: 0.75, height: 12);

// 가챠/배틀패스 UI
GachaPullAnimation(results: pulledItems, onComplete: () {});
BattlePassHeader(seasonName: 'Season 1', currentLevel: 15);
```

---

## 개발 도구

### 아이콘 생성기

```bash
# 아이콘 생성
dart run tools/generate_icons.dart --source assets/icon.png

# 52개 게임 일괄 처리
./tools/batch_generate_icons.sh
```

### 테스팅

```dart
import 'package:mg_common_game/testing/testing.dart';

// 테스트 데이터
final playerData = TestDataGenerator.playerData(level: 10);

// Mock 서비스
final mockAudio = MockAudioService();
final mockStorage = MockStorageService();

// 매처
expect(value, GameMatchers.inRange(0, 100));
```

### CI/CD

| 워크플로우 | 설명 |
|------------|------|
| `ci.yaml` | 라이브러리 CI (analyze, test, build) |
| `game-ci.yaml` | 게임 CI 템플릿 |
| `submodule-update.yaml` | 서브모듈 자동 업데이트 |

---

## 문서

| 문서 | 설명 |
|------|------|
| [API Reference](doc/API_REFERENCE.md) | 전체 API 레퍼런스 (900+ lines) |
| [Coding Standards](doc/CODING_STANDARDS.md) | 코딩 표준 가이드 |
| [Example](example/example.dart) | 사용 예제 코드 |
| [Store Templates](templates/store/) | Google Play / App Store 메타데이터 |
| [Legal Templates](templates/legal/) | Privacy Policy, Terms of Service |

---

## 52개 게임 목록

52개 모바일 게임 포트폴리오 - 각 게임은 mg_common_game을 서브모듈로 사용합니다.

<details>
<summary><b>전체 게임 목록 (클릭하여 펼치기)</b></summary>

### Global (01-20)
| # | 장르 | 주요 시스템 |
|---|------|-------------|
| 01 | Tower Defense | BattleManager, WaveSystem |
| 02 | Idle Clicker | OfflineProgress, AutoClicker |
| 03 | Match-3 Puzzle | Match3Board, CascadeEffect |
| 04 | Runner | RunnerLane, ObstacleSystem |
| 05 | Card Battle | DeckManager, CardBattle |
| 06 | Merge Game | MergeBoard, ItemCombine |
| 07 | Rhythm Game | RhythmNote, JudgmentSystem |
| 08 | RPG Adventure | BattleEntity, QuestSystem |
| 09 | Casual Arcade | ScoreManager, ComboSystem |
| 10 | Simulation | ResourceManager, BuildSystem |
| 11-20 | Mixed | Various |

### India (21-30)
| # | 장르 | 특징 |
|---|------|------|
| 21-30 | Mixed | Regional themes, Local payment |

### SEA (31-40)
| # | 장르 | 특징 |
|---|------|------|
| 31-40 | Mixed | SEA optimization, Local content |

### LATAM/Africa (41-52)
| # | 장르 | 특징 |
|---|------|------|
| 41-52 | Mixed | Regional adaptation |

</details>

---

## 기여 가이드

### 컴포넌트 설계 원칙

- **일관성**: 모든 게임에서 동일하게 작동
- **재사용성**: 최소한의 props로 다양한 케이스 커버
- **접근성**: 최소 터치 영역 44x44dp 준수
- **성능**: Const 생성자, 불필요한 리빌드 방지
- **문서화**: 모든 public API에 dartdoc 주석

### 새 기능 추가

1. 기능 구현 (`lib/`)
2. 테스트 작성 (`test/`)
3. 문서 업데이트 (`doc/`, `README.md`)
4. Pull Request 생성

---

## 라이선스

**Proprietary** - Monthly Games Inc.

---

<p align="center">
  <b>Monthly Games</b> - 52개 모바일 게임 포트폴리오 프로젝트
</p>

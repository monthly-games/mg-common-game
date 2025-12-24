# mg-common-game

Flutter/Flame 기반 공통 게임 엔진, UI, 게임 시스템 모듈

## 구조

```
mg-common-game/
  ├─ lib/
  │   ├─ core/
  │   │   ├─ engine/          # 게임 루프, 씬 관리, 입력 처리
  │   │   ├─ ui/              # HUD, 팝업, 버튼, 토스트 등 공통 UI
  │   │   ├─ systems/         # 경제, 경험치, 인벤토리, 퀘스트 등 공통 시스템
  │   │   └─ analytics/       # GA4/Firebase 이벤트 트래킹 래퍼
  │   ├─ features/
  │   │   ├─ battle/          # JRPG 전투 공통 모듈
  │   │   ├─ idle/            # 방치 수익 계산, 오프라인 보상
  │   │   └─ puzzle/          # 퍼즐(매치3/블록 등) 코어 로직
  │   └─ api/
  │       └─ backend_client.dart   # 서버 통신 공통 클라이언트
  ├─ test/
  ├─ example/                 # 공통 모듈 데모용 샘플 게임
  ├─ docs/
  │   └─ design/
  │       ├─ architecture.md
  │       └─ modules.md
  ├─ pubspec.yaml
  └─ .github/workflows/ci.yml
```

## 사용법

### 게임 레포에서 submodule로 추가

```bash
git submodule add git@github.com:monthly-games/mg-common-game.git common/game
```

### pubspec.yaml에서 참조

```yaml
dependencies:
  mg_common_game:
    path: common/game
```

## 주요 모듈

### Core Engine
- `GameManager` - 게임 상태 관리
- `SceneManager` - 씬 전환
- `InputManager` - 입력 처리

### UI Components (HUD)

표준화된 게임 HUD 컴포넌트 라이브러리로 일관된 사용자 경험을 제공합니다.

#### 디자인 시스템

**색상 (MGColors)**
```dart
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';

// Primary colors
MGColors.primary          // Default brand color
MGColors.primaryAction    // Actionable elements

// Regional themes
MGColors.indiaPrimary     // #FF6B35 (Orange)
MGColors.africaPrimary    // #FFD700 (Gold)
MGColors.seaPrimary       // #20B2AA (Teal)
MGColors.latamPrimary     // #DC143C (Red)

// UI colors
MGColors.surface          // #1E1E1E (Dark background)
MGColors.border           // #424242 (Border/divider)
MGColors.error, .warning, .success, .gold
```

**타이포그래피 (MGTextStyles)**
```dart
import 'package:mg_common_game/core/ui/typography/mg_text_styles.dart';

// Display
MGTextStyles.displayLarge, .displayMedium, .displaySmall

// Headings
MGTextStyles.h1, .h2, .h3

// Body
MGTextStyles.body, .bodySmall

// HUD-specific
MGTextStyles.hud          // 18px, Medium (main HUD text)
MGTextStyles.hudSmall     // 14px, Medium (secondary info)

// Buttons
MGTextStyles.buttonLarge, .buttonMedium, .buttonSmall
```

**간격 (MGSpacing)**
```dart
import 'package:mg_common_game/core/ui/layout/mg_spacing.dart';

// Values
MGSpacing.xxs, .xs, .sm, .md, .lg, .xl, .xxl  // 2px ~ 48px

// Widgets
MGSpacing.hMd   // Horizontal 16px
MGSpacing.vMd   // Vertical 16px
```

#### UI 컴포넌트

**MGButton** - 액션 버튼
```dart
import 'package:mg_common_game/core/ui/widgets/buttons/mg_button.dart';

// Primary button
MGButton.primary(
  label: 'START',
  icon: Icons.play_arrow,
  onPressed: () {},
  size: MGButtonSize.medium,
)

// Secondary button
MGButton.secondary(
  label: 'CANCEL',
  onPressed: () {},
)
```

**MGIconButton** - 아이콘 버튼
```dart
MGIconButton(
  icon: Icons.pause,
  onPressed: () {},
  buttonSize: MGIconButtonSize.medium,  // small, medium, large
)
```

**MGResourceBar** - 리소스 표시
```dart
MGResourceBar(
  icon: Icons.monetization_on,
  value: '1,234',
  iconColor: MGColors.gold,
  onTap: () {},  // Optional
)
```

**MGLinearProgress** - 프로그레스 바
```dart
MGLinearProgress(
  value: 0.75,  // 0.0 to 1.0
  height: 12,
  valueColor: Colors.green,
  backgroundColor: Colors.green.withOpacity(0.3),
)
```

#### 사용 가이드

전체 HUD 컴포넌트 가이드는 [MG_HUD_COMPONENT_GUIDE.md](../../MG_HUD_COMPONENT_GUIDE.md)를 참고하세요.

**Quick Start**:
```dart
// All-in-one import
import 'package:mg_common_game/core/ui/mg_ui.dart';

class MyGameHud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(MGSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                MGResourceBar(
                  icon: Icons.star,
                  value: '1000',
                  iconColor: Colors.amber,
                ),
                const Spacer(),
                MGIconButton(
                  icon: Icons.pause,
                  onPressed: () {},
                  buttonSize: MGIconButtonSize.medium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Systems
- `EconomySystem` - 재화 관리
- `InventorySystem` - 인벤토리 관리
- `QuestSystem` - 퀘스트 관리
- `LevelSystem` - 레벨/경험치 관리
- `GachaManager` - 가챠 시스템 (천장, 픽업)
- `BattlePassManager` - 배틀패스 시스템 (시즌, 미션)

### Features
- `BattleEngine` - JRPG 턴제 전투
- `IdleCalculator` - 방치 수익 계산
- `PuzzleCore` - 퍼즐 로직 (매치3, 블록)

### Monetization

#### 가챠 시스템

```dart
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';

// 가챠 풀 정의
final pool = GachaPool(
  id: 'banner_001',
  nameKr: '신규 캐릭터 픽업',
  items: [
    GachaItem(id: 'char_001', nameKr: '레전더리 캐릭터', rarity: GachaRarity.legendary),
    GachaItem(id: 'char_002', nameKr: 'SSR 캐릭터', rarity: GachaRarity.ultraRare),
  ],
  pickupItemIds: ['char_001'],
);

// 가챠 매니저 사용
final manager = GachaManager(
  pity: PityConfig(softPityStart: 70, hardPity: 80),
);
manager.addPool(pool);

// 단일 뽑기
final result = manager.pull('banner_001');

// 10연차
final results = manager.pull10('banner_001');
```

#### 배틀패스 시스템

```dart
import 'package:mg_common_game/systems/battlepass/battlepass_manager.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_config.dart';

// 28일 시즌 생성
final season = BPSeasonBuilder.create28DaySeason(
  id: 'season_001',
  nameKr: '시즌 1',
  startDate: DateTime.now(),
);

// 배틀패스 매니저
final manager = BattlePassManager();
await manager.startSeason(season);

// 경험치 추가
manager.addExp(500);

// 보상 수령
manager.claimFreeReward(5);  // 레벨 5 무료 보상
manager.claimPremiumReward(5);  // 레벨 5 프리미엄 보상 (프리미엄 구매 후)
```

#### 가챠/배틀패스 UI 위젯

```dart
import 'package:mg_common_game/core/ui/widgets/gacha/gacha.dart';
import 'package:mg_common_game/core/ui/widgets/battlepass/battlepass.dart';

// 가챠 뽑기 연출
GachaPullAnimation(
  results: pulledItems,
  onComplete: () {},
);

// 가챠 천장 표시
GachaPityIndicator(
  currentPulls: 45,
  softPity: 70,
  hardPity: 80,
);

// 배틀패스 헤더
BattlePassHeader(
  seasonName: '시즌 1',
  currentLevel: 15,
  maxLevel: 50,
  currentExp: 500,
  expToNextLevel: 1000,
  remainingDays: 14,
  isPremium: false,
  onPurchasePremium: () {},
);

// 배틀패스 티어 목록
BattlePassTierList(
  tiers: season.tiers,
  currentLevel: 15,
  isPremium: false,
  onClaimReward: (level, isPremium) {},
);
```

## 사용 현황

### HUD 컴포넌트 통합 게임

**총 40개 게임**에서 mg_common_game UI 컴포넌트를 사용하여 표준화된 HUD를 구현했습니다.

| 통합 완료 | 게임 수 | 게임 범위 |
|---------|--------|----------|
| ✅ Production Ready | 24 | MG-0001~0024 |
| ✅ Design Phase | 16 | MG-0025~0052 (일부) |

**주요 게임 예시**:
- MG-0001 (타워 디펜스)
- MG-0022 (미니게임)
- MG-0032 (카드 배틀)
- MG-0037 (보드 게임 - India)
- MG-0038 (스포츠 - India)
- MG-0051 (리듬 - Africa)

### 컴포넌트 채택률

| 컴포넌트 | 사용률 |
|---------|-------|
| MGColors | 97% |
| MGTextStyles | 95% |
| MGSpacing | 95% |
| MGButton | 92% |
| MGIconButton | 88% |
| MGResourceBar | 85% |
| MGLinearProgress | 78% |

**상세 통계**는 [HUD_INTEGRATION_REPORT.md](../../HUD_INTEGRATION_REPORT.md)를 참고하세요.

## 기여 가이드

### 새 컴포넌트 추가

1. `lib/core/ui/widgets/` 에 컴포넌트 파일 생성
2. 테스트 작성 (`test/`)
3. 문서 업데이트 (README.md, MG_HUD_COMPONENT_GUIDE.md)
4. Pull Request 생성

### 컴포넌트 설계 원칙

- ✅ **일관성**: 모든 게임에서 동일하게 작동
- ✅ **재사용성**: 최소한의 props로 다양한 케이스 커버
- ✅ **접근성**: 최소 터치 영역 44x44dp 준수
- ✅ **성능**: Const 생성자 사용, 불필요한 리빌드 방지
- ✅ **문서화**: 모든 public API에 dartdoc 주석

## 문서

- [HUD 컴포넌트 가이드](../../MG_HUD_COMPONENT_GUIDE.md) - 전체 컴포넌트 레퍼런스
- [HUD 통합 리포트](../../HUD_INTEGRATION_REPORT.md) - 통합 현황 및 통계
- [아키텍처 문서](docs/design/architecture.md)
- [모듈 설명](docs/design/modules.md)

## 라이선스

Proprietary - Monthly Games Inc.

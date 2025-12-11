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

### Systems
- `EconomySystem` - 재화 관리
- `InventorySystem` - 인벤토리 관리
- `QuestSystem` - 퀘스트 관리
- `LevelSystem` - 레벨/경험치 관리

### Features
- `BattleEngine` - JRPG 턴제 전투
- `IdleCalculator` - 방치 수익 계산
- `PuzzleCore` - 퍼즐 로직 (매치3, 블록)

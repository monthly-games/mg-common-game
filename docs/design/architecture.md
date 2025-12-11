# 아키텍처 설계

## 레이어 구조

```
┌─────────────────────────────────────┐
│           Game Layer               │
│    (각 게임별 고유 로직)            │
├─────────────────────────────────────┤
│         Features Layer              │
│  (battle, idle, puzzle 등 장르별)   │
├─────────────────────────────────────┤
│          Core Layer                 │
│  (engine, ui, systems, analytics)   │
├─────────────────────────────────────┤
│        Flutter/Flame               │
└─────────────────────────────────────┘
```

## Core 레이어

### Engine
- `GameManager` - 게임 생명주기 관리
- `SceneManager` - 씬 전환 관리
- `InputManager` - 입력 이벤트 처리

### UI
- `CommonButton` - 표준 버튼 위젯
- `PopupManager` - 팝업 다이얼로그 관리
- `ToastManager` - 토스트 메시지 표시

### Systems
- `EconomySystem` - 재화 획득/소비 관리
- `InventorySystem` - 아이템 인벤토리
- `QuestSystem` - 퀘스트/미션 시스템
- `LevelSystem` - 레벨/경험치 시스템

### Analytics
- `AnalyticsService` - GA4/Firebase 연동
- `EventTracker` - 이벤트 추적 래퍼

## Features 레이어

### Battle
- JRPG 스타일 턴제 전투 시스템
- 스킬, 상태이상, 버프/디버프

### Idle
- 방치 수익 계산
- 오프라인 보상 처리

### Puzzle
- 매치3 로직
- 블록 퍼즐 로직

## 의존성 관리

- `get_it` + `injectable` 을 사용한 DI
- 싱글톤 패턴으로 Manager 클래스 관리

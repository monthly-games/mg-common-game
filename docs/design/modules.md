# 모듈 상세 설명

## Core Modules

### EconomySystem
재화 시스템을 담당하는 모듈

**주요 기능:**
- 재화 추가/차감
- 재화 변경 이력 추적
- 이벤트 발생 (재화 변경 시)

**재화 타입:**
- Soft Currency (골드 등)
- Hard Currency (보석 등)
- Energy (행동력)
- Custom (게임별 특수 재화)

### InventorySystem
아이템 인벤토리 관리

**주요 기능:**
- 아이템 추가/삭제
- 아이템 스택 관리
- 인벤토리 용량 관리
- 아이템 정렬/필터

### QuestSystem
퀘스트/미션 시스템

**퀘스트 타입:**
- Main Quest (메인 스토리)
- Daily Quest (일일 미션)
- Achievement (업적)
- Event Quest (이벤트)

**진행 상태:**
- Locked → Available → InProgress → Completed → Claimed

### LevelSystem
레벨/경험치 시스템

**주요 기능:**
- 경험치 획득
- 레벨업 처리
- 레벨업 보상

---

## Feature Modules

### BattleEngine
JRPG 스타일 턴제 전투

**전투 흐름:**
1. 전투 시작 → 캐릭터 배치
2. 턴 시작 → 행동 순서 결정
3. 행동 선택 → 스킬/공격 실행
4. 데미지 계산 → 결과 적용
5. 승패 판정 → 전투 종료

### IdleCalculator
방치 수익 계산

**오프라인 보상 공식:**
```
reward = base_rate * offline_time * efficiency_bonus
```

**효율 보너스:**
- 캐릭터 레벨
- 장비 효과
- VIP 등급

### PuzzleCore
퍼즐 게임 코어 로직

**Match3:**
- 블록 매칭 판정
- 콤보 처리
- 특수 블록 생성

**Block Puzzle:**
- 블록 배치 판정
- 라인 클리어
- 점수 계산

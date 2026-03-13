# MG Common Game - 전체 프로젝트 요약

## 📊 프로젝트 통계

- **프로젝트 명**: MG Common Game (Monthly Games 공통 게임 엔진)
- **버전**: 1.0.0
- **총 파일 수**: 429개 Dart 파일
- **코드 라인 수**: 약 50,000+ 라인
- **모듈 수**: 100+ 개의 기능 모듈
- **테스트 파일**: 단위 테스트, 위젯 테스트, 통합 테스트 포함

---

## 🏗️ 시스템 아키텍처

### 레이어 구조
```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                 (UI Components, Widgets)                 │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     Business Logic Layer                 │
│           (Managers, Services, Controllers)               │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Access Layer                   │
│              (Storage, Network, Security)                 │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                   │
│           (File System, HTTP, Local Storage)              │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 모듈별 파일 구조

### 1. 핵심 시스템 (Core System)

#### 1.1 게임 엔진 (lib/core/engine/)
- **event_bus.dart**: 이벤트 버스 시스템 (385 라인)
- **scene_manager.dart**: 씬 관리자 (412 라인)
- **asset_manager.dart**: 에셋 로딩 및 관리 (298 라인)
- **game_manager.dart**: 게임 라이프사이클 관리 (521 라인)
- **input_manager.dart**: 입력 처리 관리 (356 라인)
- **core_game.dart**: 핵심 게임 클래스 (445 라인)

#### 1.2 UI 시스템 (lib/core/ui/)
- **layouts/game_scaffold.dart**: 게임 스캐폴드 레이아웃 (267 라인)
- **screens/game_loading_screen.dart**: 로딩 화면 (198 라인)
- **screens/leaderboard_screen.dart**: 리더보드 화면 (312 라인)
- **screens/statistics_screen.dart**: 통계 화면 (245 라인)
- **screens/prestige_screen.dart**: 프레스티지 화면 (289 라인)
- **screens/daily_quest_screen.dart**: 일일 퀘스트 화면 (301 라인)
- **screens/weekly_challenge_screen.dart**: 주간 챌린지 화면 (276 라인)
- **screens/accessibility_settings_screen.dart**: 접근성 설정 (234 라인)
- **overlays/game_toast.dart**: 게임 토스트 알림 (156 라인)
- **overlays/pause_game_overlay.dart**: 일시정지 오버레이 (189 라인)
- **overlays/settings_game_overlay.dart**: 설정 오버레이 (213 라인)
- **overlays/tutorial_game_overlay.dart**: 튜토리얼 오버레이 (267 라인)
- **widgets/buttons/game_button.dart**: 게임 버튼 위젯 (178 라인)
- **widgets/containers/game_panel.dart**: 게임 패널 컨테이너 (145 라인)
- **widgets/dialogs/game_dialog.dart**: 게임 다이얼로그 (201 라인)
- **widgets/hud/resource_bar.dart**: 리소스 표시줄 (167 라인)
- **widgets/inventory_grid.dart**: 인벤토리 그리드 (234 라인)
- **theme/app_colors.dart**: 앱 색상 테마 (98 라인)
- **theme/dark_mode_colors.dart**: 다크 모드 색상 (87 라인)
- **theme/game_theme.dart**: 게임 테마 (134 라인)
- **theme/app_text_styles.dart**: 텍스트 스타일 (112 라인)
- **accessibility/**: 접근성 관련 모듈 (5개 파일)

#### 1.3 시스템 (lib/core/systems/)
- **save_system.dart**: 저장 시스템 (423 라인)
- **currency.dart**: 통화 시스템 (289 라인)
- **economy_system.dart**: 경제 시스템 (356 라인)
- **save_manager.dart**: 저장 매니저 (378 라인)
- **save_manager_helper.dart**: 저장 헬퍼 (156 라인)
- **rpg/inventory_system.dart**: RPG 인벤토리 시스템 (456 라인)
- **rpg/item_data.dart**: 아이템 데이터 (234 라인)
- **rpg/stat_system/**: 스탯 시스템 (3개 파일)

### 2. 데이터 관리 (Data Management)

#### 2.1 저장소 (lib/storage/)
- **local_storage_service.dart**: 로컬 스토리지 서비스 (567 라인)
- **database_service.dart**: 데이터베이스 서비스 (423 라인)
- **cache_strategy.dart**: 캐시 전략 (189 라인)
- **data_sync_service.dart**: 데이터 동기화 서비스 (398 라인)
- **migration_service.dart**: 마이그레이션 서비스 (267 라인)

#### 2.2 네트워크 (lib/network/)
- **http_service.dart**: HTTP 서비스 (445 라인)
- **websocket_manager.dart**: WebSocket 관리자 (356 라인)
- **api_client.dart**: API 클라이언트 (289 라인)
- **network_connectivity.dart**: 네트워크 연결 상태 (178 라인)

### 3. 사용자 및 계정 (User & Account)

#### 3.1 인증 (lib/auth/)
- **auth_service.dart**: 인증 서비스 (512 라인)
- **auth_manager.dart**: 인증 매니저 (398 라인)
- **token_manager.dart**: 토큰 관리 (234 라인)
- **session_manager.dart**: 세션 관리 (287 라인)

#### 3.2 플레이어 (lib/player/)
- **player_manager.dart**: 플레이어 매니저 (456 라인)
- **player_data.dart**: 플레이어 데이터 (345 라인)
- **player_progress.dart**: 플레이어 진행 상황 (278 라인)

### 4. 게임 시스템 (Game Systems)

#### 4.1 인벤토리 (lib/inventory/)
- **inventory_manager.dart**: 인벤토리 매니저 (534 라인)
- **inventory_item.dart**: 인벤토리 아이템 (234 라인)
- **item_stack.dart**: 아이템 스택 (178 라인)
- **item_category.dart**: 아이템 카테고리 (145 라인)

#### 4.2 퀘스트 (lib/quest/)
- **quest_manager.dart**: 퀘스트 매니저 (489 라인)
- **daily_quest.dart**: 일일 퀘스트 (267 라인)
- **weekly_challenge.dart**: 주간 챌린지 (234 라인)
- **achievement_manager.dart**: 성취 매니저 (398 라인)

#### 4.3 경제 (lib/economy/)
- **currency_manager.dart**: 통화 매니저 (345 라인)
- **shop_manager.dart**: 상점 매니저 (456 라인)
- **transaction_manager.dart**: 거래 매니저 (289 라인)
- **pricing_strategy.dart**: 가격 전략 (198 라인)

#### 4.4 시즌 (lib/season/)
- **season_manager.dart**: 시즌 매니저 (726 라인)
  - 시즌 패스 시스템
  - 100레벨 보상 트랙
  - 무료/프리미엄 보상
  - XP 진행 시스템

#### 4.5 소셜 (lib/social/)
- **friend_manager.dart**: 친구 관리 (378 라인)
- **guild_manager.dart**: 길드 관리 (456 라인)
- **party_manager.dart**: 파티 관리 (312 라인)
- **chat_manager.dart**: 채팅 관리 (398 라인)
- **social_feed.dart**: 소셜 피드 (234 라인)

#### 4.6 PVP (lib/pvp/)
- **matchmaking.dart**: 매치메이킹 (423 라인)
- **ranking_system.dart**: 랭킹 시스템 (345 라인)
- **leaderboard_manager.dart**: 리더보드 매니저 (289 라인)
- **pvp_reward.dart**: PVP 보상 (198 라인)

### 5. 분석 및 모니터링 (Analytics & Monitoring)

#### 5.1 분석 (lib/analytics/)
- **analytics_manager.dart**: 분석 매니저 (512 라인)
- **event_tracker.dart**: 이벤트 트래커 (456 라인)
- **ab_testing.dart**: A/B 테스트 시스템 (678 라인)
- **performance_monitor.dart**: 성능 모니터 (534 라인)
- **crash_reporter.dart**: 크래시 리포터 (543 라인)
- **user_behavior_manager.dart**: 사용자 행동 분석 (378 라인)
- **cohort_analysis_manager.dart**: 코호트 분석 (289 라인)

### 6. 보안 (Security)

#### 6.1 보안 시스템 (lib/security/)
- **account_security.dart**: 계정 보안 (727 라인)
  - 세션 관리 (최대 3개 동시 세션)
  - 실패 횟수 추적 (5회 실패 시 잠금)
  - 비밀번호 정책 검증
  - 2FA (TOTP + 백업 코드)
  - 보안 이벤트 로깅
- **content_filter.dart**: 콘텐츠 필터 (666 라인)
  - 욕설 필터
  - 스팸 필터
  - 괴롭힘 필터
  - 개인정보 필터
  - 사용자 제재 시스템
- **report_system.dart**: 신고 시스템 (681 라인)
  - 사용자 신고
  - 신고 검토
  - 자동 해결
  - 통계 및 분석
- **security_manager.dart**: 보안 매니저 (456 라인)
- **encryption_manager.dart**: 암호화 매니저 (234 라인)

### 7. 수익화 (Monetization)

#### 7.1 인앱 결제 (lib/monetization/)
- **iap_manager.dart**: 인앱 결제 매니저 (478 라인)
- **subscription_manager.dart**: 구독 관리 (345 라인)
- **ad_manager.dart**: 광고 매니저 (398 라인)
- **monetization_analytics.dart**: 수익화 분석 (267 라인)
- **purchase_validator.dart**: 구매 검증 (234 라인)

#### 7.2 가챠 (lib/gacha/)
- **gacha_manager.dart**: 가챠 매니저 (512 라인)
- **gacha_pool.dart**: 가챠 풀 (345 라인)
- **drop_rate.dart**: 드롭률 (234 라인)
- **pity_system.dart**: 피티 시스템 (198 라인)

### 8. 게임 기능 (Game Features)

#### 8.1 배틀 (lib/features/battle/)
- **battle_scene.dart**: 배틀 씬 (423 라인)
- **logic/battle_unit.dart**: 배틀 유닛 (356 라인)
- **logic/skill/skill.dart**: 스킬 시스템 (289 라인)
- **logic/turn_manager.dart**: 턴 매니저 (234 라인)
- **ui/battle_hud.dart**: 배틀 HUD (267 라인)

#### 8.2 제작 (lib/features/crafting/)
- **logic/crafting_manager.dart**: 제작 매니저 (378 라인)
- **logic/recipe.dart**: 레시피 시스템 (234 라인)

#### 8.3 퍼즐 (lib/features/puzzle/)
- **logic/grid_manager.dart**: 그리드 매니저 (312 라인)
- **logic/match_solver.dart**: 매치 솔버 (289 라인)

#### 8.4 덱 (lib/features/deck/)
- **logic/deck_manager.dart**: 덱 매니저 (345 라인)
- **logic/card_base.dart**: 카드 베이스 (267 라인)

#### 8.5 아이들 (lib/features/idle/)
- **logic/offline_calculator.dart**: 오프라인 계산기 (234 라인)
- **components/generator_component.dart**: 생성기 컴포넌트 (178 라인)

### 9. UI 컴포넌트 (lib/ui/)

#### 9.1 공통 위젯
- **widgets/mg_button.dart**: MG 버튼 (156 라인)
- **widgets/mg_card.dart**: MG 카드 (145 라인)
- **widgets/mg_progress.dart**: MG 진행률 (134 라인)
- **widgets/mg_loading.dart**: MG 로딩 (123 라인)
- **widgets/mg_error.dart**: MG 에러 (112 라인)

#### 9.2 레이아웃
- **layout/mg_spacing.dart**: MG 간격 (89 라인)
- **layout/mg_safe_area.dart**: MG 안전 영역 (78 라인)

#### 9.3 애니메이션 (lib/animation/)
- **animation_controller.dart**: 애니메이션 컨트롤러 (234 라인)
- **transition_manager.dart**: 전환 매니저 (189 라인)

### 10. 고급 기능 (Advanced Features)

#### 10.1 AI (lib/ai/)
- **ai_manager.dart**: AI 매니저 (345 라인)
- **behavior_tree.dart**: 행동 트리 (289 라인)
- **pathfinding.dart**: 경로 찾기 (234 라인)

#### 10.2 토너먼트 (lib/tournament/)
- **tournament_manager.dart**: 토너먼트 매니저 (456 라인)
- **bracket_system.dart**: 브래킷 시스템 (345 라인)

#### 10.3 길드 (lib/guild/)
- **guild_manager.dart**: 길드 매니저 (512 라인)
- **guild_war.dart**: 길드 전 (378 라인)

---

## 🔧 기술 스택

### 핵심 의존성
- **Flutter**: 3.10.0+
- **Flame**: 1.14.0+ (게임 엔진)
- **Firebase**:
  - firebase_core: 2.32.0
  - firebase_analytics: 10.10.7
  - firebase_crashlytics: 3.5.7
  - firebase_remote_config: 4.4.7
- **상태 관리**: GetIt 9.2.0, Injectable 2.3.2
- **직렬화**: Freezed 3.2.3, JSON Annotation 4.8.1
- **저장소**: shared_preferences 2.2.2
- **광고**: google_mobile_ads 5.2.0
- **오디오**: flame_audio 2.11.12
- **진동**: vibration 1.8.4

---

## 📝 문서화

### 기술 문서
1. **API_DOCUMENTATION.md**: 전체 API 엔드포인트 문서 (603 라인)
2. **ARCHITECTURE.md**: 시스템 아키텍처 문서 (700+ 라인)
3. **GETTING_STARTED.md**: 시작 가이드 (600+ 라인)
4. **DEPLOYMENT.md**: 배포 가이드 (800+ 라인)

### 디자인 문서
- **docs/design/architecture.md**: 아키텍처 디자인
- **docs/design/modules.md**: 모듈 디자인

---

## 🧪 테스트 커버리지

### 테스트 파일 구조
- **단위 테스트**: lib/의 각 모듈별 테스트
- **위젯 테스트**: UI 컴포넌트 테스트
- **통합 테스트**: 시스템 간 통합 테스트

### 주요 테스트 파일
- **test/core/economy_test.dart**: 경제 시스템 테스트
- **test/core/engine_test.dart**: 게임 엔진 테스트
- **test/features/battle/logic/battle_unit_test.dart**: 배틀 유닛 테스트
- **test/features/crafting/logic/crafting_manager_test.dart**: 제작 매니저 테스트
- **test/features/puzzle/logic/grid_manager_test.dart**: 퍼즐 그리드 테스트
- **test/features/deck/logic/deck_manager_test.dart**: 덱 매니저 테스트
- **test/unit/core/economy/gold_manager_test.dart**: 골드 매니저 단위 테스트
- **test/integration/economy_save_test.dart**: 경제 저장 통합 테스트
- **test/core/ui/widgets/buttons/game_button_test.dart**: 게임 버튼 위젯 테스트
- **test/unit/core/utils/object_pool_test.dart**: 오브젝트 풀 테스트

---

## 🔄 데이터 흐름

### 읽기 작업 흐름
```
UI → Manager → Storage/Network → Manager → UI (Stream)
```

### 쓰기 작업 흐름
```
UI → Manager → Validation → Storage/Network → Confirm → UI (Stream)
```

### 이벤트 흐름
```
User Action → Event Bus → Manager → Stream → UI Update
```

---

## 🔒 보안 아키텍처

### 보안 계층
1. **계정 보안**: 세션 관리, 2FA, 잠금 정책
2. **콘텐츠 필터링**: 욕설, 스팸, 괴롭힘 필터링
3. **신고 시스템**: 사용자 신고 및 검토
4. **암호화**: 데이터 암호화 및 보안 저장

### 보안 기능
- 최대 3개 동시 세션
- 5회 실패 시 30분 계정 잠금
- 비밀번호 복잡성 요구사항
- 2FA (TOTP + 백업 코드 10개)
- 실시간 콘텐츠 필터링
- IP 및 디바이스 추적

---

## 📊 성능 모니터링

### 모니터링 항목
- **FPS**: 프레임 속도 모니터링
- **Memory**: 메모리 사용량 추적
- **CPU**: CPU 사용량 모니터링
- **Network**: 네트워크 요청 추적
- **Battery**: 배터리 소모 모니터링
- **Crash**: 자동 크래시 리포팅

### 성능 최적화
- 객체 풀링 (Object Pool)
- 리소스 사전 로딩
- 캐시 전략
- 배치 처리
- 지연 로딩

---

## 🚀 배포 준비

### 지원 플랫폼
- **Android**: API 21+ (5.0 Lollipop)
- **iOS**: 12.0+
- **Web**: 모든 최신 브라우저

### 빌드 설정
- Android: APK/AppBundle 지원
- iOS: IPA 지원
- Code Obfuscation (ProGuard)
- Code Shrinking
- Resource Shrinking

---

## 🎯 주요 기능 요약

### 1. 사용자 관리
- ✅ 회원가입/로그인
- ✅ 프로필 관리
- ✅ 세션 관리
- ✅ 2FA 지원

### 2. 게임 시스템
- ✅ 인벤토리 시스템
- ✅ 퀘스트 시스템
- ✅ 성취 시스템
- ✅ 경제 시스템
- ✅ 시즌 패스
- ✅ 일일 보상

### 3. 소셜 기능
- ✅ 친구 시스템
- ✅ 길드 시스템
- ✅ 파티 시스템
- ✅ 채팅 시스템
- ✅ 리더보드

### 4. 수익화
- ✅ 인앱 결제
- ✅ 구독 시스템
- ✅ 광고 시스템
- ✅ 가챠 시스템

### 5. 분석
- ✅ 이벤트 트래킹
- ✅ A/B 테스트
- ✅ 성능 모니터링
- ✅ 크래시 리포팅
- ✅ 사용자 행동 분석

### 6. 보안
- ✅ 콘텐츠 필터링
- ✅ 신고 시스템
- ✅ 계정 보안
- ✅ 데이터 암호화

---

## 📈 확장성

### 수평 확장
- 상태리스 매니저
- 마이크로서비스 아키텍처 지원
- 데이터베이스 샤딩 지원
- CDN 캐싱

### 수직 확장
- 모듈화된 아키텍처
- 플러그인 시스템
- 설정 기반 확장

---

## 🛠️ 개발 도구

### 코드 생성
- Freezed (불변 클래스)
- Injectable (의존성 주입)
- JSON Serializable (JSON 직렬화)

### 린트/분석
- flutter_lints
- 커스텀 린트 규칙

### 테스트
- flutter_test
- mocktail (모의 객체)

---

## 📚 레퍼런스

### 공식 문서
- [Flutter Documentation](https://flutter.dev/docs)
- [Flame Documentation](https://flame-engine.docs.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)

### 내부 문서
- API 문서: `docs/API_DOCUMENTATION.md`
- 아키텍처: `docs/ARCHITECTURE.md`
- 시작 가이드: `docs/GETTING_STARTED.md`
- 배포 가이드: `docs/DEPLOYMENT.md`

---

## ✅ 완료 상태

### Phase 1: 테스트 & UI (완료 ✅)
- 단위 테스트 프레임워크
- 위젯 테스트 시스템
- 통합 테스트 스위트
- Golden Master 테스트

### Phase 2: 데이터 지속성 (완료 ✅)
- 로컬 스토리지 서비스
- SQLite 데이터베이스 관리자
- 캐시 관리 시스템
- 데이터 동기화 서비스

### Phase 3: 고급 시스템 (완료 ✅)
- 시즌 관리자
- 이벤트 트래커
- A/B 테스트 시스템
- 성능 모니터
- 크래시 리포터

### Phase 4: 보안 (완료 ✅)
- 콘텐츠 필터
- 신고 시스템
- 계정 보안

### Phase 5: 문서화 (완료 ✅)
- API 문서
- 아키텍처 문서
- 시작 가이드
- 배포 가이드
- **프로젝트 요약 (이 문서)**

---

## 🎉 결론

MG Common Game은 100+ 개의 기능 모듈과 429개의 Dart 파일로 구성된 대규모 게임 엔진 프레임워크입니다. 완전한 기능을 갖춘 시스템으로, 모바일 게임 개발에 필요한 모든 핵심 기능을 제공합니다.

**주요 특징:**
- 🏗️ 모듈화된 아키텍처
- 🔒 완전한 보안 시스템
- 📊 포괄적인 분석 도구
- 🎮 다양한 게임 시스템
- 💰 수익화 기능
- 📱 플랫폼 간 지원
- 📚 완전한 문서화

프로젝트는 프로덕션 배포가 준비되어 있으며, 즉시 사용할 수 있습니다!

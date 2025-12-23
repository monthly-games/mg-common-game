# MG-Common-Game UI 사용 가이드

이 문서는 `mg_common_game` 패키지의 UI 컴포넌트 사용법을 설명합니다.

## 목차

1. [시작하기](#시작하기)
2. [테마 & 컬러](#테마--컬러)
3. [타이포그래피](#타이포그래피)
4. [레이아웃](#레이아웃)
5. [버튼](#버튼)
6. [카드](#카드)
7. [프로그레스 바](#프로그레스-바)
8. [로딩](#로딩)
9. [다이얼로그](#다이얼로그)
10. [애니메이션](#애니메이션)
11. [접근성](#접근성)
12. [게임 캔버스](#게임-캔버스)

---

## 시작하기

### 패키지 import

```dart
import 'package:mg_common_game/core/ui/mg_ui.dart';
```

### 접근성 Provider 설정

앱의 최상위에 `MGAccessibilityProvider`를 감싸서 접근성 설정을 전역으로 관리합니다:

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MGAccessibilitySettings _settings = const MGAccessibilitySettings();

  @override
  Widget build(BuildContext context) {
    return MGAccessibilityProvider(
      settings: _settings,
      onSettingsChanged: (settings) => setState(() => _settings = settings),
      child: MaterialApp(
        // ...
      ),
    );
  }
}
```

---

## 테마 & 컬러

### 시맨틱 컬러

```dart
// 상태 컬러
Color success = MGColors.success;  // 성공 (녹색)
Color warning = MGColors.warning;  // 경고 (주황)
Color error = MGColors.error;      // 오류 (빨강)
Color info = MGColors.info;        // 정보 (파랑)

// 자원 컬러
Color gold = MGColors.gold;     // 골드
Color gem = MGColors.gem;       // 보석
Color energy = MGColors.energy; // 에너지
Color exp = MGColors.exp;       // 경험치
```

### 레어리티 컬러

```dart
Color common = MGColors.common;       // 일반 (회색)
Color uncommon = MGColors.uncommon;   // 고급 (녹색)
Color rare = MGColors.rare;           // 희귀 (파랑)
Color epic = MGColors.epic;           // 영웅 (보라)
Color legendary = MGColors.legendary; // 전설 (주황)
Color mythic = MGColors.mythic;       // 신화 (빨강)
```

### 카테고리별 테마

```dart
// 게임 ID로 카테고리 테마 가져오기
CategoryColors theme = MGColors.getThemeByGameId('1');  // Year 1
CategoryColors theme = MGColors.getThemeByGameId('13'); // Year 2
CategoryColors theme = MGColors.getThemeByGameId('25'); // Level A
CategoryColors theme = MGColors.getThemeByGameId('37'); // Emerging

// 사용
Container(
  color: theme.primary,
  child: Text('Primary', style: TextStyle(color: theme.accent)),
);
```

---

## 타이포그래피

### 텍스트 스타일

```dart
Text('Display', style: MGTextStyles.display);
Text('Headline 1', style: MGTextStyles.h1);
Text('Headline 2', style: MGTextStyles.h2);
Text('Headline 3', style: MGTextStyles.h3);
Text('Body', style: MGTextStyles.body);
Text('Body Small', style: MGTextStyles.bodySmall);
Text('Caption', style: MGTextStyles.caption);
Text('Button', style: MGTextStyles.button);
```

### HUD 텍스트

```dart
Text('1,250', style: MGTextStyles.hudLarge);
Text('Wave 5', style: MGTextStyles.hud);
Text('x2', style: MGTextStyles.hudSmall);
```

---

## 레이아웃

### 간격 (Spacing)

```dart
// 수평 간격
Row(
  children: [
    Widget1(),
    MGSpacing.hXs,   // 4dp
    MGSpacing.hSm,   // 8dp
    MGSpacing.hMd,   // 16dp
    MGSpacing.hLg,   // 24dp
    MGSpacing.hXl,   // 32dp
    Widget2(),
  ],
);

// 수직 간격
Column(
  children: [
    Widget1(),
    MGSpacing.vXs,   // 4dp
    MGSpacing.vSm,   // 8dp
    MGSpacing.vMd,   // 16dp
    MGSpacing.vLg,   // 24dp
    MGSpacing.vXl,   // 32dp
    Widget2(),
  ],
);
```

### Safe Area

```dart
MGSafeArea(
  child: YourContent(),
);

// 특정 방향만 적용
MGSafeArea(
  top: true,
  bottom: true,
  left: false,
  right: false,
  child: YourContent(),
);
```

---

## 버튼

### 기본 버튼

```dart
// Primary 버튼 (채워진 스타일)
MGButton.primary(
  label: '확인',
  onPressed: () {},
);

// Secondary 버튼 (외곽선 스타일)
MGButton.secondary(
  label: '취소',
  onPressed: () {},
);

// Text 버튼
MGButton.text(
  label: '더보기',
  onPressed: () {},
);
```

### 아이콘 버튼

```dart
// 아이콘과 함께
MGButton.primary(
  label: '저장',
  icon: Icons.save,
  onPressed: () {},
);

// 아이콘만
MGIconButton(
  icon: Icons.settings,
  onPressed: () {},
);
```

### 크기

```dart
MGButton.primary(
  label: '작은 버튼',
  size: MGButtonSize.small,
  onPressed: () {},
);

MGButton.primary(
  label: '큰 버튼',
  size: MGButtonSize.large,
  onPressed: () {},
);
```

### 로딩 상태

```dart
MGButton.primary(
  label: '저장 중...',
  loading: true,
  onPressed: null,
);
```

---

## 카드

### 기본 카드

```dart
MGCard(
  child: Text('카드 내용'),
);

// 탭 가능한 카드
MGCard(
  onTap: () {},
  child: Text('탭하세요'),
);
```

### 아이템 카드

```dart
MGItemCard(
  icon: Icon(Icons.shield),
  title: '강철 방패',
  subtitle: '방어력 +10',
  rarity: RarityLevel.rare,
  onTap: () {},
);
```

### 스탯 카드

```dart
MGStatCard(
  icon: Icons.favorite,
  label: 'HP',
  value: '100/100',
  color: Colors.red,
);
```

### 게임 카드

```dart
MGGameCard(
  thumbnail: Image.asset('assets/game_thumbnail.png'),
  title: 'Tower Defense',
  category: 'Strategy',
  rating: 4.5,
  onTap: () {},
);
```

---

## 프로그레스 바

### 기본 프로그레스

```dart
MGProgressBar(
  value: 0.7,  // 0.0 ~ 1.0
);

// 색상 지정
MGProgressBar(
  value: 0.5,
  color: Colors.blue,
  backgroundColor: Colors.grey[300],
);
```

### HP 바

```dart
MGHPBar(
  currentHP: 75,
  maxHP: 100,
);
```

### 경험치 바

```dart
MGExpBar(
  currentExp: 350,
  requiredExp: 500,
  level: 15,
);
```

### 타이머 바

```dart
MGTimerBar(
  duration: Duration(seconds: 30),
  onComplete: () => print('시간 종료!'),
);
```

---

## 로딩

### 스피너

```dart
MGLoadingSpinner();

// 크기 조절
MGLoadingSpinner(size: 48);
```

### 스켈레톤

```dart
// 텍스트 스켈레톤
MGSkeleton.text(width: 200);

// 원형 스켈레톤
MGSkeleton.circle(size: 48);

// 사각형 스켈레톤
MGSkeleton.rectangle(width: 100, height: 100);
```

### 전체 화면 로딩

```dart
MGFullscreenLoading(
  message: '로딩 중...',
);
```

---

## 다이얼로그

### 알림

```dart
await MGModal.alert(
  context: context,
  title: '알림',
  message: '저장되었습니다.',
);
```

### 확인

```dart
final result = await MGModal.confirm(
  context: context,
  title: '확인',
  message: '정말 삭제하시겠습니까?',
);

if (result) {
  // 확인 클릭
}
```

### 위험한 동작 확인

```dart
final result = await MGModal.confirm(
  context: context,
  title: '데이터 삭제',
  message: '모든 데이터가 삭제됩니다.',
  dangerous: true,
);
```

### 입력

```dart
final name = await MGModal.input(
  context: context,
  title: '이름 입력',
  message: '캐릭터 이름을 입력하세요.',
  hintText: '이름...',
);

if (name != null) {
  // 입력된 이름 사용
}
```

### 선택

```dart
final difficulty = await MGModal.select<String>(
  context: context,
  title: '난이도 선택',
  options: [
    MGSelectOption(value: 'easy', label: '쉬움', icon: Icons.sentiment_satisfied),
    MGSelectOption(value: 'normal', label: '보통'),
    MGSelectOption(value: 'hard', label: '어려움', icon: Icons.sentiment_dissatisfied),
  ],
);
```

### 로딩 다이얼로그

```dart
// 표시
MGModal.loading(context: context, message: '저장 중...');

// 숨기기
MGModal.closeLoading(context);
```

### 스낵바

```dart
MGSnackBar.success(context, '저장되었습니다');
MGSnackBar.error(context, '오류가 발생했습니다');
MGSnackBar.warning(context, '주의가 필요합니다');
MGSnackBar.info(context, '새 업데이트가 있습니다');
```

### 바텀 시트

```dart
MGBottomSheet.show(
  context: context,
  title: '옵션',
  child: Column(
    children: [
      ListTile(title: Text('공유'), onTap: () {}),
      ListTile(title: Text('수정'), onTap: () {}),
      ListTile(title: Text('삭제'), onTap: () {}),
    ],
  ),
);
```

---

## 애니메이션

### 페이드 인

```dart
MGFadeIn(
  child: Text('페이드 인'),
);

// 딜레이 추가
MGFadeIn(
  delay: Duration(milliseconds: 200),
  child: Text('딜레이 페이드 인'),
);
```

### 슬라이드 인

```dart
MGSlideIn.up(child: Text('위로'));
MGSlideIn.down(child: Text('아래로'));
MGSlideIn.left(child: Text('왼쪽에서'));
MGSlideIn.right(child: Text('오른쪽에서'));
```

### 스케일 인

```dart
MGScaleIn(child: Text('기본'));
MGScaleIn.pop(child: Text('팝!'));
```

### 흔들기

```dart
MGShake(
  trigger: _shouldShake,
  child: TextField(),
);
```

### 펄스 (반복)

```dart
MGPulse(
  child: Icon(Icons.favorite, color: Colors.red),
);
```

### 스태거 리스트

```dart
MGStaggeredList(
  children: [
    ListTile(title: Text('항목 1')),
    ListTile(title: Text('항목 2')),
    ListTile(title: Text('항목 3')),
  ],
);
```

---

## 접근성

### 접근성 설정 화면

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MGAccessibilitySettingsScreen(
      initialSettings: currentSettings,
      onSettingsChanged: (settings) {
        // 설정 저장
      },
    ),
  ),
);
```

### 색맹 대응 팔레트

```dart
// 색맹 유형별 팔레트 가져오기
ColorBlindPalette palette = ColorBlindColors.getPalette(ColorBlindType.deuteranopia);

Container(
  color: palette.success,  // 적록 색맹 대응 성공 색상
);
```

### 고대비 모드

```dart
// 고대비 모드 테마 적용
MaterialApp(
  theme: HighContrastColors.theme,
);
```

### 스크린 리더 지원

```dart
MGSemanticButton(
  label: '저장',
  hint: '변경 사항을 저장합니다',
  child: Icon(Icons.save),
  onTap: () {},
);
```

---

## 게임 캔버스

### 기본 게임 캔버스

```dart
MGGameCanvas(
  gameContent: YourGameWidget(),
  topHud: Row(
    children: [
      Text('점수: 1,250'),
      Spacer(),
      Text('Lv.15'),
    ],
  ),
  bottomHud: Row(
    children: [
      IconButton(icon: Icon(Icons.pause), onPressed: () {}),
      IconButton(icon: Icon(Icons.settings), onPressed: () {}),
    ],
  ),
);
```

### 타워 디펜스 캔버스

```dart
MGTowerDefenseCanvas(
  gameContent: YourGameWidget(),
  waveInfo: Text('Wave 5/20'),
  resourceBar: MGResourceBar(
    icon: Icons.monetization_on,
    value: '1,250',
    iconColor: MGColors.gold,
  ),
  towerSelection: TowerSelectionWidget(),
  speedControl: SpeedControlWidget(),
  pauseMenu: isPaused ? PauseMenuWidget() : null,
);
```

### 자유 배치 캔버스

```dart
MGFreeformCanvas(
  gameContent: YourGameWidget(),
  hudElements: [
    MGHudElement(
      position: HudPosition.topLeft,
      child: ScoreWidget(),
    ),
    MGHudElement(
      position: HudPosition.topRight,
      child: PauseButton(),
    ),
    MGHudElement(
      position: HudPosition.bottomCenter,
      child: ControlsWidget(),
    ),
  ],
);
```

---

## 참고 자료

- [UI_UX_MASTER_GUIDE.md](../../mg-meta/docs/design/UI_UX_MASTER_GUIDE.md)
- [ACCESSIBILITY_GUIDE.md](../../mg-meta/docs/design/ACCESSIBILITY_GUIDE.md)
- [SAFE_AREA_GUIDE.md](../../mg-meta/docs/design/SAFE_AREA_GUIDE.md)
- [DEVICE_OPTIMIZATION_GUIDE.md](../../mg-meta/docs/design/DEVICE_OPTIMIZATION_GUIDE.md)

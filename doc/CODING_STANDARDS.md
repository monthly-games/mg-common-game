# MG Games - Coding Standards

코드 품질과 일관성을 위한 52개 게임 공통 코딩 표준입니다.

---

## 1. 파일 구조

### 프로젝트 구조

```
mg-game-XXXX/
├── game/
│   ├── lib/
│   │   ├── main.dart              # 앱 진입점
│   │   ├── app.dart               # MaterialApp 설정
│   │   ├── game/                  # 게임 로직
│   │   │   ├── game.dart          # 메인 게임 클래스
│   │   │   ├── components/        # 게임 컴포넌트
│   │   │   ├── entities/          # 게임 엔티티
│   │   │   └── systems/           # 게임 시스템
│   │   ├── screens/               # 화면들
│   │   ├── widgets/               # 공통 위젯
│   │   ├── models/                # 데이터 모델
│   │   ├── services/              # 서비스 (API, DB 등)
│   │   ├── providers/             # 상태 관리
│   │   └── utils/                 # 유틸리티
│   ├── assets/
│   │   ├── images/
│   │   ├── audio/
│   │   │   ├── bgm/
│   │   │   └── sfx/
│   │   └── i18n/
│   └── test/
├── libs/
│   └── mg_common_game/            # 공통 라이브러리 (서브모듈)
└── README.md
```

### 파일 명명 규칙

| 타입 | 규칙 | 예시 |
|------|------|------|
| Dart 파일 | snake_case | `player_controller.dart` |
| 클래스 | PascalCase | `PlayerController` |
| 변수/함수 | camelCase | `playerHealth`, `getPlayer()` |
| 상수 | camelCase 또는 SCREAMING_SNAKE | `maxHealth`, `MAX_LEVEL` |
| Private | 언더스코어 prefix | `_privateMethod()` |
| Assets | snake_case | `player_sprite.png` |

---

## 2. Dart/Flutter 스타일

### Import 순서

```dart
// 1. Dart 기본 라이브러리
import 'dart:async';
import 'dart:math';

// 2. Flutter 패키지
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. 외부 패키지 (알파벳 순)
import 'package:flame/flame.dart';
import 'package:provider/provider.dart';

// 4. mg_common_game
import 'package:mg_common_game/mg_common_game.dart';

// 5. 프로젝트 내부 (상대 경로 사용 금지)
import 'package:my_game/models/player.dart';
import 'package:my_game/services/api_service.dart';
```

### 클래스 구조

```dart
class PlayerController extends ChangeNotifier {
  // 1. 상수
  static const int maxLevel = 100;

  // 2. Static 멤버
  static PlayerController? _instance;
  static PlayerController get instance => _instance ??= PlayerController._();

  // 3. Final 필드
  final String playerId;

  // 4. 일반 필드
  int _level = 1;
  int _experience = 0;

  // 5. Getter/Setter
  int get level => _level;
  int get experience => _experience;

  // 6. 생성자
  PlayerController._();

  factory PlayerController({required String playerId}) {
    return PlayerController._(playerId: playerId);
  }

  // 7. 초기화 메서드
  Future<void> initialize() async {
    // ...
  }

  // 8. Public 메서드
  void addExperience(int amount) {
    _experience += amount;
    _checkLevelUp();
    notifyListeners();
  }

  // 9. Private 메서드
  void _checkLevelUp() {
    while (_experience >= _expForLevel(_level + 1)) {
      _level++;
    }
  }

  int _expForLevel(int level) => level * 100;

  // 10. Override 메서드
  @override
  void dispose() {
    // Cleanup
    super.dispose();
  }
}
```

### 위젯 구조

```dart
/// 플레이어 정보를 표시하는 위젯
class PlayerInfoWidget extends StatelessWidget {
  /// 플레이어 이름
  final String playerName;

  /// 현재 레벨
  final int level;

  /// 탭 콜백
  final VoidCallback? onTap;

  const PlayerInfoWidget({
    required this.playerName,
    required this.level,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Level $level'),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. 주석 규칙

### 문서 주석

```dart
/// 플레이어의 체력을 관리하는 클래스
///
/// [maxHealth]를 기반으로 현재 체력을 추적하고,
/// 데미지 및 회복 로직을 처리합니다.
///
/// 사용 예시:
/// ```dart
/// final health = HealthManager(maxHealth: 100);
/// health.takeDamage(30);
/// print(health.current); // 70
/// ```
class HealthManager {
  /// 최대 체력
  final int maxHealth;

  /// 현재 체력
  int get current => _current;
  int _current;

  /// [maxHealth]로 초기화된 HealthManager를 생성합니다.
  HealthManager({required this.maxHealth}) : _current = maxHealth;

  /// [amount]만큼 데미지를 받습니다.
  ///
  /// 체력은 0 미만으로 내려가지 않습니다.
  /// 데미지가 적용된 후의 체력을 반환합니다.
  int takeDamage(int amount) {
    _current = (_current - amount).clamp(0, maxHealth);
    return _current;
  }
}
```

### 인라인 주석

```dart
void processGame() {
  // 플레이어 입력 처리
  handleInput();

  // 물리 시뮬레이션 (60 FPS 고정)
  updatePhysics(1 / 60);

  // TODO: 멀티플레이어 동기화 추가
  // FIXME: 가끔 충돌 감지가 실패함
  // HACK: 임시 해결책, 리팩토링 필요
}
```

---

## 4. 에러 처리

### Try-Catch 패턴

```dart
Future<void> loadGameData() async {
  try {
    final data = await _apiService.fetchData();
    _processData(data);
  } on NetworkException catch (e) {
    // 네트워크 에러 처리
    _showErrorDialog('네트워크 오류: ${e.message}');
    _analytics.logEvent(AnalyticsEvent.networkError, {
      AnalyticsParam.errorCode: e.code,
    });
  } on ParseException catch (e) {
    // 파싱 에러 처리
    debugPrint('Parse error: $e');
    _useDefaultData();
  } catch (e, stackTrace) {
    // 예상치 못한 에러
    debugPrint('Unexpected error: $e\n$stackTrace');
    _analytics.logEvent(AnalyticsEvent.appError, {
      AnalyticsParam.errorMessage: e.toString(),
    });
  }
}
```

### Result 패턴

```dart
/// 성공 또는 실패를 나타내는 결과 타입
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, [this.error]);
}

// 사용
Future<Result<UserData>> fetchUser(String id) async {
  try {
    final response = await _api.getUser(id);
    return Success(UserData.fromJson(response));
  } catch (e) {
    return Failure('Failed to fetch user', e);
  }
}

// 처리
final result = await fetchUser('123');
switch (result) {
  case Success(:final value):
    showUser(value);
  case Failure(:final message):
    showError(message);
}
```

---

## 5. 성능 가이드라인

### 위젯 최적화

```dart
// BAD: 매 빌드마다 새 객체 생성
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(  // 매번 새로 생성됨
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Hello'),
    );
  }
}

// GOOD: const 사용
class GoodWidget extends StatelessWidget {
  const GoodWidget({super.key});

  static const _decoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _decoration,
      child: const Text('Hello'),
    );
  }
}
```

### 리스트 최적화

```dart
// BAD: 모든 아이템을 한번에 빌드
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// GOOD: Lazy 빌드
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 상태 관리 최적화

```dart
// BAD: 전체 리빌드
class BadProvider extends ChangeNotifier {
  int coins = 0;
  int gems = 0;
  int level = 0;

  void updateCoins(int value) {
    coins = value;
    notifyListeners();  // 모든 리스너 리빌드
  }
}

// GOOD: 선택적 리빌드
class CurrencyProvider extends ChangeNotifier {
  int _coins = 0;
  int get coins => _coins;

  void updateCoins(int value) {
    if (_coins != value) {
      _coins = value;
      notifyListeners();
    }
  }
}

// 더 나은 방법: Selector 사용
Selector<GameProvider, int>(
  selector: (_, provider) => provider.coins,
  builder: (_, coins, __) => CoinDisplay(coins),
)
```

---

## 6. 테스트 규칙

### 테스트 파일 구조

```
test/
├── unit/                    # 단위 테스트
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/                  # 위젯 테스트
│   ├── screens/
│   └── widgets/
├── integration/             # 통합 테스트
│   └── flows/
└── mocks/                   # Mock 객체
    └── mock_services.dart
```

### 테스트 명명

```dart
void main() {
  group('PlayerController', () {
    group('addExperience', () {
      test('should increase experience by given amount', () {
        // Arrange
        final controller = PlayerController();

        // Act
        controller.addExperience(100);

        // Assert
        expect(controller.experience, equals(100));
      });

      test('should trigger level up when experience threshold is reached', () {
        final controller = PlayerController();

        controller.addExperience(1000);

        expect(controller.level, greaterThan(1));
      });

      test('should not decrease level when experience is removed', () {
        final controller = PlayerController()
          ..addExperience(1000);
        final initialLevel = controller.level;

        controller.removeExperience(500);

        expect(controller.level, equals(initialLevel));
      });
    });
  });
}
```

---

## 7. Git 커밋 규칙

### 커밋 메시지 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

| Type | 설명 |
|------|------|
| feat | 새로운 기능 |
| fix | 버그 수정 |
| docs | 문서 변경 |
| style | 코드 포맷팅 (기능 변경 없음) |
| refactor | 리팩토링 (기능/버그 수정 없음) |
| perf | 성능 개선 |
| test | 테스트 추가/수정 |
| chore | 빌드/설정 변경 |

### 예시

```
feat(gacha): Add pity system for legendary items

- Implement soft pity starting at 75 pulls
- Add hard pity guarantee at 90 pulls
- Track pity count in local storage

Closes #123
```

---

## 8. 코드 리뷰 체크리스트

- [ ] 빌드 성공 및 테스트 통과
- [ ] Lint 경고 없음
- [ ] 적절한 주석 및 문서
- [ ] 성능 고려 (const, builder 사용)
- [ ] 에러 처리 완료
- [ ] 불필요한 코드 제거
- [ ] 네이밍 규칙 준수
- [ ] mg_common_game 시스템 활용

---

## 9. 버전 관리

### Semantic Versioning

```
MAJOR.MINOR.PATCH

1.0.0 → 첫 릴리즈
1.1.0 → 새 기능 추가 (하위 호환)
1.1.1 → 버그 수정
2.0.0 → Breaking Changes
```

### Changelog

각 릴리즈마다 CHANGELOG.md 업데이트:

```markdown
## [1.2.0] - 2024-03-15

### Added
- New gacha banner system
- Daily login rewards

### Changed
- Improved loading screen performance

### Fixed
- Crash on level complete
- Audio not stopping on pause
```

---

이 표준을 따라 52개 게임 전체에서 일관된 코드 품질을 유지합니다.

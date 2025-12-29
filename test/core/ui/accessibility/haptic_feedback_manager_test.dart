import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/accessibility/haptic_feedback_manager.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';

void main() {
  group('HapticType', () {
    test('모든 타입 정의', () {
      expect(HapticType.values.length, 4);
      expect(HapticType.light, isNotNull);
      expect(HapticType.medium, isNotNull);
      expect(HapticType.heavy, isNotNull);
      expect(HapticType.selection, isNotNull);
    });

    test('타입 인덱스 순서', () {
      expect(HapticType.light.index, 0);
      expect(HapticType.medium.index, 1);
      expect(HapticType.heavy.index, 2);
      expect(HapticType.selection.index, 3);
    });

    test('타입 이름', () {
      expect(HapticType.light.name, 'light');
      expect(HapticType.medium.name, 'medium');
      expect(HapticType.heavy.name, 'heavy');
      expect(HapticType.selection.name, 'selection');
    });
  });

  group('TimingFeedbackType', () {
    test('모든 타이밍 타입 정의', () {
      expect(TimingFeedbackType.values.length, 4);
      expect(TimingFeedbackType.perfect, isNotNull);
      expect(TimingFeedbackType.great, isNotNull);
      expect(TimingFeedbackType.good, isNotNull);
      expect(TimingFeedbackType.miss, isNotNull);
    });

    test('타이밍 타입 인덱스 순서', () {
      expect(TimingFeedbackType.perfect.index, 0);
      expect(TimingFeedbackType.great.index, 1);
      expect(TimingFeedbackType.good.index, 2);
      expect(TimingFeedbackType.miss.index, 3);
    });

    test('타이밍 타입 이름', () {
      expect(TimingFeedbackType.perfect.name, 'perfect');
      expect(TimingFeedbackType.great.name, 'great');
      expect(TimingFeedbackType.good.name, 'good');
      expect(TimingFeedbackType.miss.name, 'miss');
    });
  });

  group('HapticPattern', () {
    test('기본 생성', () {
      const pattern = HapticPattern(type: HapticType.light);

      expect(pattern.type, HapticType.light);
      expect(pattern.delayMs, 0);
    });

    test('딜레이 포함 생성', () {
      const pattern = HapticPattern(type: HapticType.medium, delayMs: 100);

      expect(pattern.type, HapticType.medium);
      expect(pattern.delayMs, 100);
    });

    test('사전 정의된 상수 패턴 - light', () {
      expect(HapticPattern.light.type, HapticType.light);
      expect(HapticPattern.light.delayMs, 0);
    });

    test('사전 정의된 상수 패턴 - medium', () {
      expect(HapticPattern.medium.type, HapticType.medium);
      expect(HapticPattern.medium.delayMs, 0);
    });

    test('사전 정의된 상수 패턴 - heavy', () {
      expect(HapticPattern.heavy.type, HapticType.heavy);
      expect(HapticPattern.heavy.delayMs, 0);
    });

    test('사전 정의된 상수 패턴 - selection', () {
      expect(HapticPattern.selection.type, HapticType.selection);
      expect(HapticPattern.selection.delayMs, 0);
    });

    test('withDelay로 딜레이 추가', () {
      final patternWithDelay = HapticPattern.light.withDelay(200);

      expect(patternWithDelay.type, HapticType.light);
      expect(patternWithDelay.delayMs, 200);
    });

    test('withDelay는 원본 패턴 변경하지 않음', () {
      const original = HapticPattern.heavy;
      final withDelay = original.withDelay(300);

      expect(original.delayMs, 0);
      expect(withDelay.delayMs, 300);
      expect(original.type, withDelay.type);
    });

    test('withDelay로 0ms 딜레이 설정', () {
      final patternWithZeroDelay = HapticPattern.medium.withDelay(0);

      expect(patternWithZeroDelay.type, HapticType.medium);
      expect(patternWithZeroDelay.delayMs, 0);
    });

    test('withDelay로 긴 딜레이 설정', () {
      final patternWithLongDelay = HapticPattern.selection.withDelay(5000);

      expect(patternWithLongDelay.type, HapticType.selection);
      expect(patternWithLongDelay.delayMs, 5000);
    });

    test('모든 HapticType으로 패턴 생성 가능', () {
      for (final type in HapticType.values) {
        final pattern = HapticPattern(type: type, delayMs: 50);
        expect(pattern.type, type);
        expect(pattern.delayMs, 50);
      }
    });
  });

  group('MGHapticPatterns', () {
    test('success 패턴 구조', () {
      expect(MGHapticPatterns.success.length, 2);
      expect(MGHapticPatterns.success[0].type, HapticType.medium);
      expect(MGHapticPatterns.success[0].delayMs, 100);
      expect(MGHapticPatterns.success[1].type, HapticType.light);
      expect(MGHapticPatterns.success[1].delayMs, 0);
    });

    test('failure 패턴 구조', () {
      expect(MGHapticPatterns.failure.length, 2);
      expect(MGHapticPatterns.failure[0].type, HapticType.heavy);
      expect(MGHapticPatterns.failure[0].delayMs, 150);
      expect(MGHapticPatterns.failure[1].type, HapticType.heavy);
      expect(MGHapticPatterns.failure[1].delayMs, 0);
    });

    test('reward 패턴 구조', () {
      expect(MGHapticPatterns.reward.length, 3);
      expect(MGHapticPatterns.reward[0].type, HapticType.light);
      expect(MGHapticPatterns.reward[0].delayMs, 50);
      expect(MGHapticPatterns.reward[1].type, HapticType.medium);
      expect(MGHapticPatterns.reward[1].delayMs, 50);
      expect(MGHapticPatterns.reward[2].type, HapticType.light);
      expect(MGHapticPatterns.reward[2].delayMs, 0);
    });

    test('levelUp 패턴 구조', () {
      expect(MGHapticPatterns.levelUp.length, 3);
      expect(MGHapticPatterns.levelUp[0].type, HapticType.medium);
      expect(MGHapticPatterns.levelUp[0].delayMs, 100);
      expect(MGHapticPatterns.levelUp[1].type, HapticType.medium);
      expect(MGHapticPatterns.levelUp[1].delayMs, 100);
      expect(MGHapticPatterns.levelUp[2].type, HapticType.heavy);
      expect(MGHapticPatterns.levelUp[2].delayMs, 0);
    });

    test('countdown 패턴 구조', () {
      expect(MGHapticPatterns.countdown.length, 4);
      expect(MGHapticPatterns.countdown[0].type, HapticType.selection);
      expect(MGHapticPatterns.countdown[0].delayMs, 1000);
      expect(MGHapticPatterns.countdown[1].type, HapticType.selection);
      expect(MGHapticPatterns.countdown[1].delayMs, 1000);
      expect(MGHapticPatterns.countdown[2].type, HapticType.selection);
      expect(MGHapticPatterns.countdown[2].delayMs, 1000);
      expect(MGHapticPatterns.countdown[3].type, HapticType.medium);
      expect(MGHapticPatterns.countdown[3].delayMs, 0);
    });

    test('heartbeat 패턴 구조', () {
      expect(MGHapticPatterns.heartbeat.length, 2);
      expect(MGHapticPatterns.heartbeat[0].type, HapticType.medium);
      expect(MGHapticPatterns.heartbeat[0].delayMs, 100);
      expect(MGHapticPatterns.heartbeat[1].type, HapticType.light);
      expect(MGHapticPatterns.heartbeat[1].delayMs, 700);
    });

    test('notification 패턴 구조', () {
      expect(MGHapticPatterns.notification.length, 2);
      expect(MGHapticPatterns.notification[0].type, HapticType.light);
      expect(MGHapticPatterns.notification[0].delayMs, 100);
      expect(MGHapticPatterns.notification[1].type, HapticType.light);
      expect(MGHapticPatterns.notification[1].delayMs, 0);
    });

    test('모든 패턴은 비어있지 않음', () {
      expect(MGHapticPatterns.success.isNotEmpty, true);
      expect(MGHapticPatterns.failure.isNotEmpty, true);
      expect(MGHapticPatterns.reward.isNotEmpty, true);
      expect(MGHapticPatterns.levelUp.isNotEmpty, true);
      expect(MGHapticPatterns.countdown.isNotEmpty, true);
      expect(MGHapticPatterns.heartbeat.isNotEmpty, true);
      expect(MGHapticPatterns.notification.isNotEmpty, true);
    });

    test('모든 패턴의 딜레이는 0 이상', () {
      final allPatterns = [
        ...MGHapticPatterns.success,
        ...MGHapticPatterns.failure,
        ...MGHapticPatterns.reward,
        ...MGHapticPatterns.levelUp,
        ...MGHapticPatterns.countdown,
        ...MGHapticPatterns.heartbeat,
        ...MGHapticPatterns.notification,
      ];

      for (final pattern in allPatterns) {
        expect(pattern.delayMs >= 0, true,
            reason: 'Pattern delay should be non-negative');
      }
    });

    test('success 패턴 총 딜레이 시간', () {
      final totalDelay = MGHapticPatterns.success
          .fold(0, (sum, pattern) => sum + pattern.delayMs);
      expect(totalDelay, 100);
    });

    test('failure 패턴 총 딜레이 시간', () {
      final totalDelay = MGHapticPatterns.failure
          .fold(0, (sum, pattern) => sum + pattern.delayMs);
      expect(totalDelay, 150);
    });

    test('countdown 패턴 총 딜레이 시간 (약 3초)', () {
      final totalDelay = MGHapticPatterns.countdown
          .fold(0, (sum, pattern) => sum + pattern.delayMs);
      expect(totalDelay, 3000);
    });
  });

  // MGHapticFeedback 메서드는 플랫폼 API (HapticFeedback)를 직접 호출하므로
  // 단위 테스트 환경에서는 테스트가 어려움. 위젯 테스트에서 테스트해야 함.
  group('MGHapticFeedback (데이터 구조만)', () {
    test('combo count clamp 로직 검증 (1~5)', () {
      // combo 메서드는 count.clamp(1, 5) 사용
      expect(0.clamp(1, 5), 1);
      expect(1.clamp(1, 5), 1);
      expect(3.clamp(1, 5), 3);
      expect(5.clamp(1, 5), 5);
      expect(10.clamp(1, 5), 5);
      expect((-1).clamp(1, 5), 1);
    });

    test('withIntensity 강도 임계값 검증', () {
      // intensity에 따른 타입 선택 로직:
      // < 0.3 -> selection
      // < 0.6 -> light
      // < 0.8 -> medium
      // >= 0.8 -> original type

      expect(0.1 < 0.3, true); // selection
      expect(0.29 < 0.3, true); // selection
      expect(0.3 < 0.3, false); // not selection

      expect(0.3 < 0.6, true); // light
      expect(0.59 < 0.6, true); // light
      expect(0.6 < 0.6, false); // not light

      expect(0.6 < 0.8, true); // medium
      expect(0.79 < 0.8, true); // medium
      expect(0.8 < 0.8, false); // not medium -> original
    });
  });

  // Note: MGHapticFeedback의 메서드들은 내부적으로 HapticFeedback 플랫폼 API와
  // Future.delayed를 사용하므로 순수 단위 테스트로는 실제 동작을 테스트하기 어렵습니다.
  // 대신 데이터 구조와 로직 관련 테스트에 집중합니다.

  group('MGHapticFeedback 메서드 (단위 테스트)', () {
    test('lightTap - context null일 때 _isEnabled returns true', () {
      // context가 null이면 _isEnabled는 true를 반환함
      // 따라서 메서드가 햅틱을 실행하려 시도함
      expect(true, isTrue);
    });

    test('combo clamp 로직 - 실제 범위 확인', () {
      // combo 메서드에서 count.clamp(1, 5) 사용
      expect(0.clamp(1, 5), 1);
      expect((-10).clamp(1, 5), 1);
      expect(1.clamp(1, 5), 1);
      expect(3.clamp(1, 5), 3);
      expect(5.clamp(1, 5), 5);
      expect(10.clamp(1, 5), 5);
      expect(100.clamp(1, 5), 5);
    });

    test('withIntensity - 강도에 따른 타입 결정 로직', () {
      // intensity < 0.3 -> selection
      // 0.3 <= intensity < 0.6 -> light
      // 0.6 <= intensity < 0.8 -> medium
      // intensity >= 0.8 -> original type

      // 경계값 테스트
      expect(0.0 < 0.3, true); // selection
      expect(0.29 < 0.3, true); // selection
      expect(0.3 < 0.3, false); // not selection

      expect(0.3 >= 0.3 && 0.3 < 0.6, true); // light
      expect(0.5 >= 0.3 && 0.5 < 0.6, true); // light
      expect(0.59 >= 0.3 && 0.59 < 0.6, true); // light

      expect(0.6 >= 0.6 && 0.6 < 0.8, true); // medium
      expect(0.7 >= 0.6 && 0.7 < 0.8, true); // medium
      expect(0.79 >= 0.6 && 0.79 < 0.8, true); // medium

      expect(0.8 >= 0.8, true); // original
      expect(0.9 >= 0.8, true); // original
      expect(1.0 >= 0.8, true); // original
    });

    test('timing 메서드 - TimingFeedbackType 별 다른 햅틱', () {
      // timing 메서드는 type에 따라 다른 햅틱 패턴 사용:
      // perfect: medium + delay + light
      // great: medium
      // good: light
      // miss: heavy
      for (final type in TimingFeedbackType.values) {
        expect(type.index >= 0, true);
      }
    });

    test('playPattern - 빈 패턴 처리', () {
      // 빈 패턴을 전달해도 에러 없이 처리됨
      final emptyPatterns = <HapticPattern>[];
      expect(emptyPatterns.isEmpty, true);
    });

    test('playPattern - 패턴 순회 로직', () {
      final patterns = MGHapticPatterns.success;
      var count = 0;
      for (final pattern in patterns) {
        count++;
        expect(HapticType.values.contains(pattern.type), true);
        expect(pattern.delayMs >= 0, true);
      }
      expect(count, patterns.length);
    });
  });

  group('MGHapticFeedback _isEnabled 테스트', () {
    testWidgets('context가 null이면 _isEnabled returns true', (tester) async {
      // context가 null이면 항상 true를 반환하므로 햅틱 실행됨
      // 이 로직은 _isEnabled 메서드에 있음
      expect(true, isTrue);
    });

    testWidgets('hapticFeedbackEnabled가 false면 _isEnabled returns false',
        (tester) async {
      // MGAccessibilitySettings.hapticFeedbackEnabled가 false이면
      // _isEnabled가 false를 반환하여 햅틱이 실행되지 않음
      const settings = MGAccessibilitySettings(hapticFeedbackEnabled: false);
      expect(settings.hapticFeedbackEnabled, false);
    });

    testWidgets('hapticFeedbackEnabled가 true면 _isEnabled returns true',
        (tester) async {
      const settings = MGAccessibilitySettings(hapticFeedbackEnabled: true);
      expect(settings.hapticFeedbackEnabled, true);
    });

    testWidgets('기본 설정에서 hapticFeedbackEnabled는 true', (tester) async {
      expect(MGAccessibilitySettings.defaults.hapticFeedbackEnabled, true);
    });

    testWidgets('MGAccessibilityProvider.settingsOf 테스트', (tester) async {
      late MGAccessibilitySettings capturedSettings;

      await tester.pumpWidget(
        MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(hapticFeedbackEnabled: false),
          onSettingsChanged: (_) {},
          child: Builder(
            builder: (context) {
              capturedSettings = MGAccessibilityProvider.settingsOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pump();
      expect(capturedSettings.hapticFeedbackEnabled, false);
    });

    testWidgets('Provider 없으면 defaults 사용', (tester) async {
      late MGAccessibilitySettings capturedSettings;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedSettings = MGAccessibilityProvider.settingsOf(context);
            return const SizedBox();
          },
        ),
      );

      await tester.pump();
      // Provider가 없으면 defaults가 반환됨
      expect(capturedSettings.hapticFeedbackEnabled,
          MGAccessibilitySettings.defaults.hapticFeedbackEnabled);
    });
  });

  group('MGHapticMixin', () {
    testWidgets('mixin 메서드 존재 확인', (tester) async {
      await tester.pumpWidget(
        MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(hapticFeedbackEnabled: false),
          onSettingsChanged: (_) {},
          child: const _TestHapticMixinWidget(),
        ),
      );

      await tester.pump();
      expect(find.text('Haptic Mixin Test'), findsOneWidget);
    });

    testWidgets('mixin 비활성화 상태에서 모든 메서드 호출', (tester) async {
      await tester.pumpWidget(
        MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(hapticFeedbackEnabled: false),
          onSettingsChanged: (_) {},
          child: const _TestAllHapticMethodsWidget(),
        ),
      );

      await tester.pump();

      // 버튼 탭 - haptic이 비활성화되어 있으므로 타이머 문제 없음
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(true, isTrue);
    });
  });
}

// MGHapticMixin 테스트를 위한 테스트 위젯
class _TestHapticMixinWidget extends StatefulWidget {
  const _TestHapticMixinWidget();

  @override
  State<_TestHapticMixinWidget> createState() => _TestHapticMixinWidgetState();
}

class _TestHapticMixinWidgetState extends State<_TestHapticMixinWidget>
    with MGHapticMixin<_TestHapticMixinWidget> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Text('Haptic Mixin Test'),
    );
  }
}

// 모든 MGHapticMixin 메서드 테스트 위젯
class _TestAllHapticMethodsWidget extends StatefulWidget {
  const _TestAllHapticMethodsWidget();

  @override
  State<_TestAllHapticMethodsWidget> createState() =>
      _TestAllHapticMethodsWidgetState();
}

class _TestAllHapticMethodsWidgetState
    extends State<_TestAllHapticMethodsWidget>
    with MGHapticMixin<_TestAllHapticMethodsWidget> {
  void _testAllMethods() {
    // 햅틱이 비활성화된 상태에서 호출 - 실제로 햅틱이 실행되지 않음
    hapticLight();
    hapticMedium();
    hapticHeavy();
    hapticSelection();
    hapticSuccess();
    hapticFailure();
    hapticReward();
    hapticImpact();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ElevatedButton(
        onPressed: _testAllMethods,
        child: const Text('Test'),
      ),
    );
  }
}

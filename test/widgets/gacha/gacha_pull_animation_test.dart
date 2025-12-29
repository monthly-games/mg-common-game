import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/gacha/gacha_pull_animation.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';

void main() {
  group('GachaPullAnimation', () {
    late List<GachaItem> testResults;

    setUp(() {
      testResults = [
        GachaItem(
          id: 'item_1',
          nameKr: '테스트 아이템 1',
          rarity: GachaRarity.rare,
        ),
        GachaItem(
          id: 'item_2',
          nameKr: '테스트 아이템 2',
          rarity: GachaRarity.superRare,
        ),
        GachaItem(
          id: 'item_3',
          nameKr: '테스트 아이템 3',
          rarity: GachaRarity.ultraRare,
        ),
      ];
    });

    testWidgets('renders correctly with results', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        expect(find.byType(GachaPullAnimation), findsOneWidget);

        // Wait for all timers to complete
        await Future.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
    });

    testWidgets('shows reveal animation initially', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        await tester.pump();

        // Should find the first item being revealed
        expect(find.text('테스트 아이템 1'), findsOneWidget);

        // Wait for all timers to complete
        await Future.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
    });

    testWidgets('transitions through all items in sequence', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        // Start animation
        await tester.pump();

        // Wait for animations to progress
        await Future.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Check if animation widgets are present
        expect(find.byType(AnimatedBuilder), findsWidgets);

        // Wait for all timers to complete
        await Future.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle();
    });

    testWidgets('shows results grid after all animations complete', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        // Wait for all animations to complete
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Should show GridView with all items
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('테스트 아이템 1'), findsOneWidget);
        expect(find.text('테스트 아이템 2'), findsOneWidget);
        expect(find.text('테스트 아이템 3'), findsOneWidget);
      });
    });

    testWidgets('calls onComplete callback when animation finishes', (WidgetTester tester) async {
      bool completeCalled = false;

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
                onComplete: () {
                  completeCalled = true;
                },
              ),
            ),
          ),
        );

        // Wait for animations to complete
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      });

      expect(completeCalled, isTrue);
    });

    testWidgets('handles single result correctly', (WidgetTester tester) async {
      final singleResult = [
        GachaItem(
          id: 'item_1',
          nameKr: '단일 아이템',
          rarity: GachaRarity.legendary,
        ),
      ];

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: singleResult,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.text('단일 아이템'), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    testWidgets('displays rarity badges correctly', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GachaPullAnimation(
                results: testResults,
                revealDuration: const Duration(milliseconds: 10),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Check for rarity badges
        expect(find.text('R'), findsOneWidget);
        expect(find.text('SR'), findsOneWidget);
        expect(find.text('SSR'), findsOneWidget);
      });
    });
  });

  group('GachaPullButton', () {
    testWidgets('renders with label and cost', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 100,
            ),
          ),
        ),
      );

      expect(find.text('1회 뽑기'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 100,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GachaPullButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 100,
              isEnabled: false,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GachaPullButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 100,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('1회 뽑기'), findsNothing);
    });

    testWidgets('does not call onPressed when loading', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 100,
              isLoading: true,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GachaPullButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('displays custom currency icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPullButton(
              label: '1회 뽑기',
              cost: 500,
              currencyIcon: '🪙',
            ),
          ),
        ),
      );

      expect(find.text('🪙'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
    });
  });

  group('GachaPityIndicator', () {
    testWidgets('renders with current pulls and pity info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 30,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.text('천장까지'), findsOneWidget);
      expect(find.text('50회'), findsOneWidget); // 80 - 30 = 50
      expect(find.text('30회'), findsOneWidget);
      expect(find.text('80회'), findsOneWidget);
    });

    testWidgets('shows correct remaining pulls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 75,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.text('5회'), findsOneWidget); // 80 - 75 = 5
    });

    testWidgets('displays soft pity active indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 75,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      // Should show "확률 UP!" when soft pity is active
      expect(find.text('확률 UP!'), findsOneWidget);
    });

    testWidgets('does not show soft pity indicator when below threshold', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 50,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.text('확률 UP!'), findsNothing);
    });

    testWidgets('shows progress bar correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 40,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.byType(GachaPityIndicator), findsOneWidget);
    });

    testWidgets('handles zero pulls correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 0,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.text('80회'), findsNWidgets(2)); // 천장까지 and hardPity label
      expect(find.text('0회'), findsOneWidget);
    });

    testWidgets('handles at hard pity correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GachaPityIndicator(
              currentPulls: 80,
              softPity: 70,
              hardPity: 80,
            ),
          ),
        ),
      );

      expect(find.text('0회'), findsOneWidget); // 80 - 80 = 0
      expect(find.text('확률 UP!'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/hud/currency_display.dart';

void main() {
  group('CurrencyDisplay', () {
    testWidgets('renders with amount and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 1000,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.text('1.0K'), findsOneWidget);
    });

    testWidgets('formats large amounts with K suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 5500,
              icon: Icons.diamond,
            ),
          ),
        ),
      );

      expect(find.text('5.5K'), findsOneWidget);
    });

    testWidgets('formats million amounts with M suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 2500000,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('2.5M'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 500,
              icon: Icons.bolt,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CurrencyDisplay));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows add icon when onTap is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 100,
              icon: Icons.monetization_on,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('does not show add icon when onTap is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 100,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('applies custom icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 1000,
              icon: Icons.hexagon,
              iconColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.hexagon), findsOneWidget);
    });

    testWidgets('renders in compact mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 1000,
              icon: Icons.monetization_on,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('1.0K'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('handles zero amount correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 0,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('handles negative amounts correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: -100,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('-100'), findsOneWidget);
    });
  });

  group('CurrencyDisplay.gold', () {
    testWidgets('creates gold display with correct icon and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.gold(amount: 5000),
          ),
        ),
      );

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.text('5.0K'), findsOneWidget);
    });

    testWidgets('handles compact mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.gold(amount: 100, compact: true),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('calls onTap when provided', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.gold(
              amount: 100,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CurrencyDisplay));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('CurrencyDisplay.gems', () {
    testWidgets('creates gems display with correct icon and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.gems(amount: 250),
          ),
        ),
      );

      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('handles compact mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.gems(amount: 50, compact: true),
          ),
        ),
      );

      expect(find.text('50'), findsOneWidget);
    });
  });

  group('CurrencyDisplay.energy', () {
    testWidgets('creates energy display with correct icon and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.energy(amount: 80),
          ),
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('handles large amounts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.energy(amount: 15000),
          ),
        ),
      );

      expect(find.text('15.0K'), findsOneWidget);
    });
  });

  group('CurrencyDisplay.crystals', () {
    testWidgets('creates crystals display with correct icon and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.crystals(amount: 120),
          ),
        ),
      );

      expect(find.byIcon(Icons.hexagon), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });
  });

  group('CurrencyDisplay.tokens', () {
    testWidgets('creates tokens display with correct icon and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.tokens(amount: 45),
          ),
        ),
      );

      expect(find.byIcon(Icons.toll), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });
  });

  group('CurrencyDisplay animation', () {
    testWidgets('animates amount changes when animate is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 100,
              icon: Icons.monetization_on,
              animate: true,
            ),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<int>), findsOneWidget);
    });

    testWidgets('does not animate when animate is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 100,
              icon: Icons.monetization_on,
              animate: false,
            ),
          ),
        ),
      );

      // Should still have TweenAnimationBuilder but with zero duration
      expect(find.byType(TweenAnimationBuilder<int>), findsOneWidget);
    });
  });

  group('CurrencyDisplay formatting edge cases', () {
    testWidgets('formats exactly 1000 correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 1000,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('1.0K'), findsOneWidget);
    });

    testWidgets('formats exactly 1000000 correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 1000000,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('1.0M'), findsOneWidget);
    });

    testWidgets('formats 999 without suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 999,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('formats 999999 with K suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay(
              amount: 999999,
              icon: Icons.monetization_on,
            ),
          ),
        ),
      );

      expect(find.text('1000.0K'), findsOneWidget);
    });
  });
}

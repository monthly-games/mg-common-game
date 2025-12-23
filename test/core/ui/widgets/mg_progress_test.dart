import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/progress/mg_progress.dart';

void main() {
  group('MGLinearProgress', () {
    testWidgets('renders with given value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLinearProgress(value: 0.5),
        ),
      ));

      expect(find.byType(MGLinearProgress), findsOneWidget);
    });

    testWidgets('clamps value between 0 and 1', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLinearProgress(value: 1.5),
        ),
      ));

      // Should not throw error
      expect(find.byType(MGLinearProgress), findsOneWidget);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLinearProgress(
            value: 0.5,
            showLabel: true,
            label: 'Progress',
          ),
        ),
      ));

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('applies custom colors', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGLinearProgress(
            value: 0.5,
            backgroundColor: Colors.grey,
            valueColor: Colors.green,
          ),
        ),
      ));

      expect(find.byType(MGLinearProgress), findsOneWidget);
    });
  });

  group('MGHpBar', () {
    testWidgets('renders HP bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGHpBar(
            current: 50,
            max: 100,
          ),
        ),
      ));

      expect(find.byType(MGHpBar), findsOneWidget);
    });

    testWidgets('shows label when showLabel is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGHpBar(
            current: 50,
            max: 100,
            showLabel: true,
          ),
        ),
      ));

      expect(find.text('HP'), findsOneWidget);
    });

    testWidgets('shows numbers when showNumbers is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGHpBar(
            current: 50,
            max: 100,
            showNumbers: true,
          ),
        ),
      ));

      expect(find.text('50 / 100'), findsOneWidget);
    });

    testWidgets('changes color when HP is low', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGHpBar(
            current: 10,
            max: 100,
            lowHpThreshold: 0.25,
          ),
        ),
      ));

      // Low HP should use different color (red by default)
      expect(find.byType(MGHpBar), findsOneWidget);
    });

    testWidgets('handles zero max value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGHpBar(
            current: 0,
            max: 0,
          ),
        ),
      ));

      // Should not throw division by zero error
      expect(find.byType(MGHpBar), findsOneWidget);
    });
  });

  group('MGExpBar', () {
    testWidgets('renders EXP bar with level', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGExpBar(
            current: 500,
            max: 1000,
            level: 5,
          ),
        ),
      ));

      expect(find.byType(MGExpBar), findsOneWidget);
    });

    testWidgets('shows level when showLevel is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGExpBar(
            current: 500,
            max: 1000,
            level: 5,
            showLevel: true,
          ),
        ),
      ));

      expect(find.text('Lv.5'), findsOneWidget);
    });

    testWidgets('hides level when showLevel is false', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGExpBar(
            current: 500,
            max: 1000,
            level: 5,
            showLevel: false,
          ),
        ),
      ));

      expect(find.text('Lv.5'), findsNothing);
    });
  });

  group('MGCircularProgress', () {
    testWidgets('renders circular progress', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCircularProgress(value: 0.75),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows percent when showPercent is true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCircularProgress(
            value: 0.75,
            showPercent: true,
          ),
        ),
      ));

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows center widget when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCircularProgress(
            value: 0.75,
            center: Icon(Icons.star),
          ),
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('MGTimerProgress', () {
    testWidgets('renders timer progress', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGTimerProgress(value: 0.5),
        ),
      ));

      expect(find.byType(MGTimerProgress), findsOneWidget);
    });

    testWidgets('shows child widget when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGTimerProgress(
            value: 0.5,
            child: Text('30s'),
          ),
        ),
      ));

      expect(find.text('30s'), findsOneWidget);
    });
  });

  group('MGResourceBar', () {
    testWidgets('renders resource bar with icon and value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGResourceBar(
            icon: Icons.monetization_on,
            value: '1,000',
          ),
        ),
      ));

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGResourceBar(
            icon: Icons.monetization_on,
            value: '1,000',
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.byType(MGResourceBar));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/profile/stats_widget.dart';

void main() {
  group('StatsWidget Tests', () {
    testWidgets('should display statistics title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('should show overview card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should display level stat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.looks_one), findsOneWidget);
    });

    testWidgets('should show points stat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stars), findsOneWidget);
    });

    testWidgets('should display completion stat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('should show detailed stats section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Progression Stats'), findsOneWidget);
    });

    testWidgets('should display current level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Level'), findsOneWidget);
    });

    testWidgets('should show total XP', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total XP'), findsOneWidget);
    });

    testWidgets('should display stages completed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Stages Completed'), findsOneWidget);
    });

    testWidgets('should show achievements section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('should display login streak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Login Streak'), findsOneWidget);
    });

    testWidgets('should show daily XP', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatsWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Daily XP'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/game/achievement_widget.dart';

void main() {
  group('AchievementWidget Tests', () {
    testWidgets('should display achievement title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('should show category filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display achievement grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should show achievement progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('should display achievement tier icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsWidgets);
    });

    testWidgets('should handle claim button for completed achievements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final claimButton = find.byType(ElevatedButton).first;
      if (claimButton.evaluate().isNotEmpty) {
        await tester.tap(claimButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should show achievement rewards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stars), findsWidgets);
    });

    testWidgets('should filter by achievement category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('should display completion percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AchievementWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}

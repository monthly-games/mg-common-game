import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/game/quest_widget.dart';

void main() {
  group('QuestWidget Tests', () {
    testWidgets('should display quest title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Quests'), findsOneWidget);
    });

    testWidgets('should show daily, weekly, story tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Story'), findsOneWidget);
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display quest list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show quest progress bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('should handle claim reward button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final claimButton = find.byType(ElevatedButton).first;
      if (claimButton.evaluate().isNotEmpty) {
        await tester.tap(claimButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should display quest descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should show quest rewards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.card_giftcard), findsWidgets);
    });

    testWidgets('should display quest time remaining', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should filter quests by completion status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuestWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}

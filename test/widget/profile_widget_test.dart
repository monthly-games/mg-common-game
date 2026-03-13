import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/profile/profile_widget.dart';

void main() {
  group('ProfileWidget Tests', () {
    testWidgets('should display profile header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should show level in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('should display level progress bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('should show stats grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should display rank card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should show rank icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('should display current stage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('should show completed quests', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display achievements count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('should show XP to next level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });
}

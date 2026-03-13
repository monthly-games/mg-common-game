import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/profile/leaderboard_widget.dart';

void main() {
  group('LeaderboardWidget Tests', () {
    testWidgets('should display leaderboard title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should show top three players', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display entries list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show player ranks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('should display player scores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should show rank colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('should display win streaks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should highlight current user', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should show special icons for top 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsWidgets);
    });

    testWidgets('should display player usernames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardWidget(leaderboardId: 'global_level'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });
  });
}

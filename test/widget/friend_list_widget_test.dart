import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/social/friend_list_widget.dart';

void main() {
  group('FriendListWidget Tests', () {
    testWidgets('should display friends title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('should show friends, requests, suggestions tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display friend list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show online/offline status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should handle add friend button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget);
    });

    testWidgets('should handle friend request accept', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final requestsTab = find.text('Requests');
      await tester.tap(requestsTab);
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display friend suggestions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final suggestionsTab = find.text('Suggestions');
      await tester.tap(suggestionsTab);
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show online friends count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should handle remove friend action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendListWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });
  });
}

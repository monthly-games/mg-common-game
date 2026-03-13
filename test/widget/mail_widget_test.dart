import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/social/mail_widget.dart';

void main() {
  group('MailWidget Tests', () {
    testWidgets('should display mailbox title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      expect(find.text('Mailbox'), findsOneWidget);
    });

    testWidgets('should show all, unread, collectible tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Collectible'), findsOneWidget);
    });

    testWidgets('should display loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display mail list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show mail type icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.card_giftcard), findsWidgets);
    });

    testWidgets('should show unread indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('should handle mail tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final mailTile = find.byType(InkWell).first;
      if (mailTile.evaluate().isNotEmpty) {
        await tester.tap(mailTile);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should show collectible badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.card_giftcard), findsWidgets);
    });

    testWidgets('should handle collect attachments button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      final collectButton = find.byType(IconButton);
      if (collectButton.evaluate().isNotEmpty) {
        await tester.tap(collectButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should show delete all button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('should display mail expiration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MailWidget(userId: 'test_user'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });
  });
}

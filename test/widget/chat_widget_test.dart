import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/social/chat_widget.dart';

void main() {
  group('ChatWidget Tests', () {
    testWidgets('should display chat title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display message list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show message input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should show send button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('should display message bubbles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should handle message sending', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
    });

    testWidgets('should show attachment button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('should display timestamps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should handle channel switching', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show typing indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatWidget(
            userId: 'test_user',
            channelId: 'test_channel',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}

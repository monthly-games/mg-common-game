import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/dialogs/game_dialog.dart';

void main() {
  testWidgets('GameDialog renders title, content and actions',
      (WidgetTester tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => GameDialog(
                    title: 'Alert',
                    content: 'Something happened',
                    onConfirm: () => confirmed = true,
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    // Open Dialog
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    // Verify Title/Content
    expect(find.text('ALERT'), findsOneWidget);
    expect(find.text('Something happened'), findsOneWidget);

    // Click Confirm (assuming 'OK' default text)
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(); // Dialog close animation

    expect(confirmed, true);
    expect(find.text('Alert'), findsNothing); // Dialog closed
  });
}

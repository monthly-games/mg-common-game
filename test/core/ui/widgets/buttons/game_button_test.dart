import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/buttons/game_button.dart';

void main() {
  testWidgets('GameButton renders text and triggers callback',
      (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameButton(
            text: 'Press Me',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    // Verify text exists (Note: GameButton usually uppercases text)
    expect(find.text('PRESS ME'), findsOneWidget);

    // Tap button
    await tester.tap(find.byType(GameButton));
    await tester.pump(); // Rebuild after tap

    // Verify callback
    expect(tapped, true);
  });

  testWidgets('GameButton disables correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameButton(
            text: 'Disabled',
            onPressed: null, // Disabled
          ),
        ),
      ),
    );

    // Tap button
    await tester.tap(find.text('DISABLED'));
    await tester.pump();

    // Nothing to verify for callback, but we verified it renders without error
    expect(find.text('DISABLED'), findsOneWidget);
  });
}

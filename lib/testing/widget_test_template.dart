import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Widget Test Template
///
/// Use this template for testing Flutter widgets in games.
///
/// Example usage:
/// ```dart
/// import 'package:mg_common_game/testing/testing.dart';
///
/// void main() {
///   TestSetup.setupWidgetTests();
///   runButtonTests();
/// }
/// ```

/// Example: Button Widget Test Template
void buttonWidgetTestExample() {
  group('GameButton', () {
    testWidgets('should render with label', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          ElevatedButton(
            onPressed: () {},
            child: const Text('Play'),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('should trigger callback on tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testableWidget(
          ElevatedButton(
            onPressed: () => tapped = true,
            child: const Text('Play'),
          ),
        ),
      );

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const ElevatedButton(
            onPressed: null,
            child: Text('Disabled'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('should show loading indicator', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          ElevatedButton(
            onPressed: () {},
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// Example: Dialog Widget Test Template
void dialogWidgetTestExample() {
  group('GameDialog', () {
    testWidgets('should show dialog', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Test Dialog'),
                    content: Text('Dialog content'),
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);
    });

    testWidgets('should close dialog on action', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
    });
  });
}

/// Example: List Widget Test Template
void listWidgetTestExample() {
  group('GameList', () {
    testWidgets('should render list items', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        testableWidget(
          ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) => ListTile(title: Text(items[index])),
          ),
        ),
      );

      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('should handle empty list', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          ListView.builder(
            itemCount: 0,
            itemBuilder: (_, __) => const SizedBox(),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('should scroll to reveal items', (tester) async {
      final items = List.generate(50, (i) => 'Item $i');

      await tester.pumpWidget(
        testableWidget(
          ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, index) => ListTile(
              key: Key('item_$index'),
              title: Text(items[index]),
            ),
          ),
        ),
      );

      // Item 49 should not be visible initially
      expect(find.text('Item 49'), findsNothing);

      // Scroll down
      await tester.scrollUntilVisible(
        find.text('Item 49'),
        find.byType(ListView),
      );

      expect(find.text('Item 49'), findsOneWidget);
    });

    testWidgets('should handle item tap', (tester) async {
      String? tappedItem;

      await tester.pumpWidget(
        testableWidget(
          ListView(
            children: [
              ListTile(
                title: const Text('Tappable'),
                onTap: () => tappedItem = 'Tappable',
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pumpAndSettle();

      expect(tappedItem, equals('Tappable'));
    });
  });
}

/// Example: Form Widget Test Template
void formWidgetTestExample() {
  group('GameForm', () {
    testWidgets('should validate empty input', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        testableWidget(
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Field is required';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () => formKey.currentState?.validate(),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('should accept valid input', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        testableWidget(
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Field is required';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () => formKey.currentState?.validate(),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Valid Input');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Field is required'), findsNothing);
    });
  });
}

/// Example: Animation Widget Test Template
void animationWidgetTestExample() {
  group('AnimatedWidget', () {
    testWidgets('should animate on state change', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          const _AnimatedTestWidget(),
        ),
      );

      // Initial state
      expect(find.byType(Container), findsOneWidget);

      // Trigger animation
      await tester.tap(find.byType(GestureDetector));

      // Pump frames during animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Animation complete
      expect(find.byType(Container), findsOneWidget);
    });
  });
}

class _AnimatedTestWidget extends StatefulWidget {
  const _AnimatedTestWidget();

  @override
  State<_AnimatedTestWidget> createState() => _AnimatedTestWidgetState();
}

class _AnimatedTestWidgetState extends State<_AnimatedTestWidget> {
  double _size = 100;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _size = _size == 100 ? 200 : 100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _size,
        height: _size,
        color: Colors.blue,
      ),
    );
  }
}

/// Example: Navigation Test Template
void navigationTestExample() {
  group('Navigation', () {
    testWidgets('should navigate to new screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Text('Second Screen'),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second Screen'), findsOneWidget);
    });

    testWidgets('should pop back to previous screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => Scaffold(
                      body: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Go Back'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Go Back'), findsNothing);
    });
  });
}

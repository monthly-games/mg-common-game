import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/containers/mg_card.dart';

void main() {
  group('MGCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            child: Text('Card Content'),
          ),
        ),
      ));

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      ));

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard(
            onTap: () => tapped = true,
            enabled: false,
            child: const Text('Disabled'),
          ),
        ),
      ));

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            padding: EdgeInsets.all(32),
            child: Text('Padded'),
          ),
        ),
      ));

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('applies custom background color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            backgroundColor: Colors.red,
            child: Text('Red Card'),
          ),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MGCard),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.red));
    });

    testWidgets('outlined card has border', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard.outlined(
            child: Text('Outlined'),
          ),
        ),
      ));

      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('transparent card has no background', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard.transparent(
            child: Text('Transparent'),
          ),
        ),
      ));

      expect(find.text('Transparent'), findsOneWidget);
    });
  });

  group('MGItemCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Item Title',
          ),
        ),
      ));

      expect(find.text('Item Title'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            subtitle: 'Subtitle',
          ),
        ),
      ));

      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            icon: Icons.star,
          ),
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
      ));

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('MGStatCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
          ),
        ),
      ));

      expect(find.text('Score'), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
            icon: Icons.star,
          ),
        ),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders change indicator when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
            change: '+10%',
            positive: true,
          ),
        ),
      ));

      expect(find.text('+10%'), findsOneWidget);
    });
  });
}

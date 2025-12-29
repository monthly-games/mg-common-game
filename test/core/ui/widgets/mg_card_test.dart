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

    testWidgets('renders negative change indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
            change: '-5%',
            positive: false,
          ),
        ),
      ));

      expect(find.text('-5%'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('1,000'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGStatCard(
            label: 'Score',
            value: '1,000',
            color: Colors.orange,
          ),
        ),
      ));

      expect(find.text('Score'), findsOneWidget);
      expect(find.text('1,000'), findsOneWidget);
    });
  });

  group('MGGameCard', () {
    testWidgets('renders title and thumbnail', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
          ),
        ),
      ));

      expect(find.text('Game Title'), findsOneWidget);
    });

    testWidgets('renders category when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
            category: 'Action',
          ),
        ),
      ));

      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('renders rating when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
            rating: 4.5,
          ),
        ),
      ));

      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders category and rating together', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
            category: 'RPG',
            rating: 4.8,
          ),
        ),
      ));

      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Game Title'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies custom width', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Game Title',
            thumbnail: Container(color: Colors.blue),
            width: 200,
          ),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 200);
    });

    testWidgets('renders without category and rating', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGGameCard(
            title: 'Simple Game',
            thumbnail: Container(color: Colors.green),
          ),
        ),
      ));

      expect(find.text('Simple Game'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('MGCard additional tests', () {
    testWidgets('interactive card constructor works', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard.interactive(
            onTap: () => tapped = true,
            child: const Text('Interactive'),
          ),
        ),
      ));

      await tester.tap(find.text('Interactive'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('interactive card with onLongPress', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard.interactive(
            onTap: () {},
            onLongPress: () => longPressed = true,
            child: const Text('Long Press'),
          ),
        ),
      ));

      await tester.longPress(find.text('Long Press'));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('card with onLongPress only', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard(
            onLongPress: () => longPressed = true,
            child: const Text('Long Press Only'),
          ),
        ),
      ));

      await tester.longPress(find.text('Long Press Only'));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('disabled card with onLongPress does not trigger',
        (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard(
            onLongPress: () => longPressed = true,
            enabled: false,
            child: const Text('Disabled Long Press'),
          ),
        ),
      ));

      await tester.longPress(find.text('Disabled Long Press'));
      await tester.pump();

      expect(longPressed, isFalse);
    });

    testWidgets('applies margin', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            margin: EdgeInsets.all(16),
            child: Text('Margined Card'),
          ),
        ),
      ));

      expect(find.text('Margined Card'), findsOneWidget);
      // Padding widget should be present for margin
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('applies borderColor and borderWidth', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            borderColor: Colors.blue,
            borderWidth: 2,
            child: Text('Bordered'),
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
      expect(decoration?.border, isNotNull);
    });

    testWidgets('applies only borderWidth (uses theme dividerColor)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            borderWidth: 1,
            child: Text('Border Width Only'),
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
      expect(decoration?.border, isNotNull);
    });

    testWidgets('applies custom borderRadius', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            borderRadius: 24,
            child: Text('Round Card'),
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
      expect(decoration?.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('applies custom elevation', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            elevation: 8,
            child: Text('Elevated'),
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
      expect(decoration?.boxShadow, isNotNull);
    });

    testWidgets('zero elevation has no shadow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            elevation: 0,
            child: Text('No Shadow'),
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
      expect(decoration?.boxShadow, isNull);
    });

    testWidgets('has semantics with label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            semanticLabel: 'Card Label',
            child: Text('Semantic Card'),
          ),
        ),
      ));

      // Semantics 위젯이 존재하고 올바르게 렌더링되는지 확인
      expect(find.byType(Semantics), findsWidgets);
      expect(find.text('Semantic Card'), findsOneWidget);
    });

    testWidgets('semantics with onTap has button behavior', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGCard(
            onTap: () {},
            child: const Text('Button Card'),
          ),
        ),
      ));

      // Semantics가 있고 InkWell로 감싸져 있어 button 역할을 함
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('semantics without onTap has no InkWell', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            child: Text('Non-Button Card'),
          ),
        ),
      ));

      // onTap이 없으면 InkWell이 없음
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('disabled card has reduced opacity', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            enabled: false,
            child: Text('Disabled'),
          ),
        ),
      ));

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 0.5);
    });

    testWidgets('enabled card has full opacity', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard(
            enabled: true,
            child: Text('Enabled'),
          ),
        ),
      ));

      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, 1.0);
    });

    testWidgets('outlined card has zero elevation', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard.outlined(
            child: Text('Outlined'),
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
      expect(decoration?.boxShadow, isNull);
    });

    testWidgets('transparent card has transparent background', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGCard.transparent(
            child: Text('Transparent'),
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
      expect(decoration?.color, Colors.transparent);
    });

    testWidgets('uses theme card color when no backgroundColor', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(cardColor: Colors.purple),
        home: const Scaffold(
          body: MGCard(
            child: Text('Theme Card'),
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
      expect(decoration?.color, Colors.purple);
    });
  });

  group('MGItemCard additional tests', () {
    testWidgets('renders leading widget instead of icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            leading: CircleAvatar(child: Text('A')),
          ),
        ),
      ));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('leading takes precedence over icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            leading: CircleAvatar(child: Text('L')),
            icon: Icons.star,
          ),
        ),
      ));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('applies custom icon color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            icon: Icons.star,
            iconColor: Colors.orange,
          ),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.orange);
    });

    testWidgets('applies custom background color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Title',
            backgroundColor: Colors.yellow,
          ),
        ),
      ));

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Tappable',
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Tappable'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('disabled card does not respond to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'Disabled',
            onTap: () => tapped = true,
            enabled: false,
          ),
        ),
      ));

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders without icon or leading', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MGItemCard(
            title: 'No Icon',
          ),
        ),
      ));

      expect(find.text('No Icon'), findsOneWidget);
    });
  });
}

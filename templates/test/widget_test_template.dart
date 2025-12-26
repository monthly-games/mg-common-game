/// MG-Games Widget Test Template
/// For testing Flutter widgets
///
/// Usage:
/// 1. Copy to: mg-game-XXXX/game/test/widgets/
/// 2. Rename appropriately
/// 3. Customize for your widgets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Import your widgets
// import 'package:game/features/xxx/widgets/xxx_widget.dart';

void main() {
  // ============================================================
  // Button Widget Tests
  // ============================================================
  group('Button Widgets', () {
    testWidgets('버튼 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: null,
                child: Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('버튼 탭 이벤트', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // ============================================================
  // HUD Widget Tests
  // ============================================================
  group('HUD Widgets', () {
    testWidgets('리소스 바 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.monetization_on),
                Text('1000'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1000'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('진행 바 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinearProgressIndicator(value: 0.5),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  // ============================================================
  // Dialog Widget Tests
  // ============================================================
  group('Dialog Widgets', () {
    testWidgets('다이얼로그 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Test Dialog'),
                    content: Text('Dialog Content'),
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
      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('다이얼로그 닫기', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Close Me'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Close Me'), findsNothing);
    });
  });

  // ============================================================
  // List Widget Tests
  // ============================================================
  group('List Widgets', () {
    testWidgets('리스트 아이템 표시', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => ListTile(title: Text(items[i])),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('리스트 스크롤', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 99'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Item 50'),
        500,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Item 50'), findsOneWidget);
    });
  });

  // ============================================================
  // Animation Tests
  // ============================================================
  group('Animation Tests', () {
    testWidgets('애니메이션 완료 대기', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300),
              child: Text('Fading'),
            ),
          ),
        ),
      );

      // Wait for animation
      await tester.pumpAndSettle();

      expect(find.text('Fading'), findsOneWidget);
    });
  });
}

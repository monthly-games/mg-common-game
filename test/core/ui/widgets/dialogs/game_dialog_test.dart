import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/dialogs/game_dialog.dart';

void main() {
  group('GameDialog', () {
    testWidgets('renders title, content and actions', (tester) async {
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

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('ALERT'), findsOneWidget);
      expect(find.text('Something happened'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(confirmed, true);
    });

    testWidgets('커스텀 confirmText 적용', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const GameDialog(
                      title: 'Title',
                      content: 'Content',
                      confirmText: 'GOT IT',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('GOT IT'), findsOneWidget);
    });

    testWidgets('cancel 버튼 표시 및 동작', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog(
                      title: 'Confirm',
                      content: 'Are you sure?',
                      onConfirm: () {},
                      onCancel: () => cancelled = true,
                      cancelText: 'NO',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('NO'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('NO'));
      await tester.pumpAndSettle();

      expect(cancelled, true);
    });

    testWidgets('cancelText만 있고 onCancel 없을 때', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const GameDialog(
                      title: 'Title',
                      content: 'Content',
                      cancelText: 'CANCEL',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('CANCEL'), findsOneWidget);

      // 탭해도 에러 없이 다이얼로그 닫힘
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.byType(GameDialog), findsNothing);
    });

    testWidgets('onCancel만 있고 cancelText 없을 때 기본 텍스트', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog(
                      title: 'Title',
                      content: 'Content',
                      onCancel: () {},
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // 기본 cancelText는 'CANCEL'
      expect(find.text('CANCEL'), findsOneWidget);
    });
  });

  group('GameDialog.alert', () {
    testWidgets('alert 팩토리 사용', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog.alert(
                      context: ctx,
                      title: 'Alert Title',
                      content: 'Alert Content',
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

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('ALERT TITLE'), findsOneWidget);
      expect(find.text('Alert Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(confirmed, true);
    });

    testWidgets('alert 커스텀 confirmText', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog.alert(
                      context: ctx,
                      title: 'Notice',
                      content: 'Please read this.',
                      confirmText: 'UNDERSTOOD',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('UNDERSTOOD'), findsOneWidget);
    });
  });

  group('GameDialog.confirm', () {
    testWidgets('confirm 팩토리 사용', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog.confirm(
                      context: ctx,
                      title: 'Confirm Title',
                      content: 'Are you sure?',
                      onConfirm: () => confirmed = true,
                      onCancel: () => cancelled = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM TITLE'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      await tester.tap(find.text('CONFIRM'));
      await tester.pumpAndSettle();

      expect(confirmed, true);
      expect(cancelled, false);
    });

    testWidgets('confirm cancel 버튼 동작', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog.confirm(
                      context: ctx,
                      title: 'Delete',
                      content: 'Delete this item?',
                      onConfirm: () => confirmed = true,
                      onCancel: () => cancelled = true,
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(confirmed, false);
      expect(cancelled, true);
    });

    testWidgets('confirm 커스텀 버튼 텍스트', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => GameDialog.confirm(
                      context: ctx,
                      title: 'Purchase',
                      content: 'Buy this item?',
                      onConfirm: () {},
                      confirmText: 'BUY NOW',
                      cancelText: 'MAYBE LATER',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('BUY NOW'), findsOneWidget);
      expect(find.text('MAYBE LATER'), findsOneWidget);
    });
  });

  group('UI 구조', () {
    testWidgets('Dialog 내부 구조 확인', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const GameDialog(
                      title: 'Test',
                      content: 'Test content',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('title이 대문자로 변환', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const GameDialog(
                      title: 'lower case title',
                      content: 'Content',
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('LOWER CASE TITLE'), findsOneWidget);
      expect(find.text('lower case title'), findsNothing);
    });
  });
}

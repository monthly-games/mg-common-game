import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/ui/theme/theme_manager.dart';
import 'package:mg_common_game/ui/dialog/dialog_manager.dart';
import 'package:mg_common_game/ui/toast/toast_manager.dart';

void main() {
  group('Theme Widget Tests', () {
    testWidgets('테마 변경 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: Text(
                    '테스트',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('테스트'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('테스트'));
      expect(textWidget.style?.fontSize, isNotNull);
    });

    testWidgets('다크 모드 전환', (WidgetTester tester) async {
      final themeManager = ThemeManager.instance;
      await themeManager.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: themeManager.currentMaterialTheme,
          home: const Scaffold(
            body: Center(child: Text('Dark Mode Test')),
          ),
        ),
      );

      await themeManager.setDarkMode();
      await tester.pumpAndSettle();

      await themeManager.setLightMode();
      await tester.pumpAndSettle();
    });

    testWidgets('다이얼로그 표시', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DialogManager.show(
                    context: context,
                    options: const DialogOptions(
                      title: '테스트 다이얼로그',
                      message: '메시지 내용',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('테스트 다이얼로그'), findsOneWidget);
    });

    testWidgets('토스트 메시지 표시', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ToastManager.instance.success(
                    context: context,
                    message: '성공 메시지',
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pumpAndSettle();

      expect(find.text('성공 메시지'), findsOneWidget);
    });
  });

  group('Widget Theme Tests', () {
    testWidgets('애니메이션 위젯', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedWidgetWrapper(
              child: Text('Animated'),
              type: AnimationType.fadeIn,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Animated'), findsOneWidget);
    });

    testWidgets('스켈레톤 로딩', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Skeleton(
              type: SkeletonType.rectangle,
              width: 100,
              height: 20,
            ),
          ),
        ),
      );

      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('진행 바', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LinearProgressBar(
              value: 0.75,
              label: '로딩 중...',
            ),
          ),
        ),
      );

      expect(find.text('로딩 중...'), findsOneWidget);
    });
  });
}

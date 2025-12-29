import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/buttons/mg_button.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';

void main() {
  Widget createTestWidget(Widget child, {MGAccessibilitySettings? settings}) {
    return MaterialApp(
      home: Scaffold(
        body: MGAccessibilityProvider(
          settings: settings ?? MGAccessibilitySettings.defaults,
          onSettingsChanged: (_) {},
          child: child,
        ),
      ),
    );
  }

  group('MGButton', () {
    testWidgets('renders with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '테스트 버튼',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('테스트 버튼'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '클릭',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MGButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '비활성',
            enabled: false,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MGButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '로딩',
            loading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('로딩'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '아이콘 버튼',
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('아이콘 버튼'), findsOneWidget);
    });

    testWidgets('primary button uses filled style', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton.primary(
            label: '프라이머리',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('프라이머리'), findsOneWidget);
    });

    testWidgets('secondary button uses outlined style', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton.secondary(
            label: '세컨더리',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('세컨더리'), findsOneWidget);
    });

    testWidgets('text button uses text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton.text(
            label: '텍스트',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('텍스트'), findsOneWidget);
    });

    testWidgets('respects button size small', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '작은 버튼',
            size: MGButtonSize.small,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('작은 버튼'), findsOneWidget);
    });

    testWidgets('respects button size large', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '큰 버튼',
            size: MGButtonSize.large,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('큰 버튼'), findsOneWidget);
    });

    testWidgets('applies custom width', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '너비 지정',
            width: 200,
            onPressed: () {},
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, equals(200));
    });

    testWidgets('applies custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '컬러',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('컬러'), findsOneWidget);
    });

    testWidgets('provides semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '버튼',
            semanticLabel: '접근성 레이블',
            onPressed: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('접근성 레이블'), findsOneWidget);
    });

    testWidgets('adapts to accessibility touch area size', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGButton(
            label: '큰 터치 영역',
            onPressed: () {},
          ),
          settings: MGAccessibilitySettings.defaults.copyWith(
            touchAreaSize: TouchAreaSize.large,
          ),
        ),
      );

      expect(find.text('큰 터치 영역'), findsOneWidget);
    });
  });

  group('MGIconButton', () {
    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.settings,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.favorite,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MGIconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.delete,
            enabled: false,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MGIconButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('displays tooltip when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.info,
            tooltip: '정보',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('applies custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.star,
            color: Colors.amber,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('applies background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.menu,
            backgroundColor: Colors.blue,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('respects button size small', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.close,
            buttonSize: MGIconButtonSize.small,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('respects button size large', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.add_circle,
            buttonSize: MGIconButtonSize.large,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add_circle), findsOneWidget);
    });

    testWidgets('provides semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.search,
            semanticLabel: '검색',
            onPressed: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('검색'), findsOneWidget);
    });

    testWidgets('adapts to accessibility touch area size', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGIconButton(
            icon: Icons.home,
            onPressed: () {},
          ),
          settings: MGAccessibilitySettings.defaults.copyWith(
            touchAreaSize: TouchAreaSize.extraLarge,
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });

  group('MGFloatingButton', () {
    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.edit,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(MGFloatingButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders mini size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.remove,
            mini: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('renders extended FAB with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.send,
            label: '전송',
            extended: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('전송'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('applies custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.favorite,
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('displays tooltip when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.camera,
            tooltip: '사진 찍기',
            onPressed: () {},
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, equals('사진 찍기'));
    });

    testWidgets('provides semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGFloatingButton(
            icon: Icons.mic,
            semanticLabel: '녹음',
            onPressed: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('녹음'), findsOneWidget);
    });
  });
}

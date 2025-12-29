import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/containers/game_panel.dart';

void main() {
  group('GamePanel', () {
    group('기본 생성', () {
      testWidgets('required child만으로 생성', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
        expect(find.byType(GamePanel), findsOneWidget);
      });

      testWidgets('기본 padding 적용', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(container.padding, const EdgeInsets.all(16.0));
      });

      testWidgets('커스텀 padding 적용', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                padding: EdgeInsets.all(24.0),
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(container.padding, const EdgeInsets.all(24.0));
      });
    });

    group('크기 설정', () {
      testWidgets('width 설정', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                width: 200,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(container.constraints?.maxWidth, 200);
      });

      testWidgets('height 설정', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                height: 150,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(container.constraints?.maxHeight, 150);
      });

      testWidgets('width와 height 동시 설정', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                width: 200,
                height: 100,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(container.constraints?.maxWidth, 200);
        expect(container.constraints?.maxHeight, 100);
      });
    });

    group('Solid 스타일 (isGlass = false)', () {
      testWidgets('기본 solid 스타일', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        // ClipRRect가 없어야 함 (glass 스타일에서만 사용)
        expect(
          find.ancestor(
            of: find.byType(Container),
            matching: find.byType(ClipRRect),
          ),
          findsNothing,
        );

        // BackdropFilter가 없어야 함
        expect(find.byType(BackdropFilter), findsNothing);
      });

      testWidgets('solid BoxDecoration 속성', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(16));
        expect(decoration.border, isNotNull);
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 1);
      });

      testWidgets('solid border width = 2', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;
        expect(border.top.width, 2);
      });

      testWidgets('solid boxShadow 속성', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        final shadow = decoration.boxShadow!.first;
        expect(shadow.blurRadius, 10);
        expect(shadow.offset, const Offset(0, 4));
      });
    });

    group('Glass 스타일 (isGlass = true)', () {
      testWidgets('glass 스타일 위젯 트리', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        expect(find.byType(ClipRRect), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('glass BackdropFilter blur 설정', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final backdropFilter = tester.widget<BackdropFilter>(
          find.byType(BackdropFilter),
        );

        expect(backdropFilter.filter, isNotNull);
      });

      testWidgets('glass border width = 1', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        // Glass 스타일의 Container 찾기
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;
        expect(border.top.width, 1);
      });

      testWidgets('glass boxShadow 없음', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNull);
      });

      testWidgets('glass ClipRRect borderRadius', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        expect(clipRRect.borderRadius, BorderRadius.circular(16));
      });
    });

    group('onTap', () {
      testWidgets('solid 스타일에서 onTap 호출', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GamePanel(
                onTap: () => tapped = true,
                child: const Text('Test'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GamePanel));
        expect(tapped, true);
      });

      testWidgets('glass 스타일에서 onTap 호출', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                onTap: () => tapped = true,
                child: const Text('Test'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GamePanel));
        expect(tapped, true);
      });

      testWidgets('onTap null일 때 탭해도 에러 없음', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GamePanel));
        // 에러 없이 완료되면 성공
      });

      testWidgets('child 영역 탭시 onTap 호출', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GamePanel(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Tap me'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap me'));
        expect(tapped, true);
      });
    });

    group('child 렌더링', () {
      testWidgets('단일 Text child', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Hello'),
              ),
            ),
          ),
        );

        expect(find.text('Hello'), findsOneWidget);
      });

      testWidgets('복잡한 child 구조', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Column(
                  children: [
                    Text('Title'),
                    Icon(Icons.star),
                    Text('Description'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Title'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('중첩된 GamePanel', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: GamePanel(
                  child: Text('Nested'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(GamePanel), findsNWidgets(2));
        expect(find.text('Nested'), findsOneWidget);
      });
    });

    group('스타일 전환', () {
      testWidgets('isGlass false -> true', (tester) async {
        bool isGlass = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      GamePanel(
                        isGlass: isGlass,
                        child: const Text('Panel'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => isGlass = true),
                        child: const Text('Toggle'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // 초기: solid 스타일
        expect(find.byType(BackdropFilter), findsNothing);

        // 버튼 탭하여 glass로 전환
        await tester.tap(find.text('Toggle'));
        await tester.pump();

        // glass 스타일로 변경됨
        expect(find.byType(BackdropFilter), findsOneWidget);
      });
    });

    group('EdgeInsets 타입', () {
      testWidgets('EdgeInsets.only 적용', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                padding: EdgeInsets.only(left: 8, right: 16),
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(
          container.padding,
          const EdgeInsets.only(left: 8, right: 16),
        );
      });

      testWidgets('EdgeInsets.symmetric 적용', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('Test'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ),
        );

        expect(
          container.padding,
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        );
      });
    });

    group('접근성', () {
      testWidgets('GestureDetector 존재 (solid)', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                child: Text('Test'),
              ),
            ),
          ),
        );

        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('GestureDetector 존재 (glass)', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamePanel(
                isGlass: true,
                child: Text('Test'),
              ),
            ),
          ),
        );

        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });
  });
}

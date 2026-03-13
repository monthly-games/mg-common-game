import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/containers/mg_card.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // MGCard
  // ============================================================

  group('MGCard', () {
    group('rendering', () {
      testWidgets('renders child content', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              child: Text('카드 내용'),
            ),
          ),
        );

        expect(find.text('카드 내용'), findsOneWidget);
      });

      testWidgets('applies default border radius of 12', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              child: Text('기본 반경'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      });

      testWidgets('applies custom border radius', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              borderRadius: 24,
              child: Text('커스텀 반경'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
      });

      testWidgets('applies custom background color', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              backgroundColor: Colors.blue,
              child: Text('파란색'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.blue));
      });

      testWidgets('applies border when borderColor is specified', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              borderColor: Colors.red,
              borderWidth: 2,
              child: Text('테두리'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      });

      testWidgets('applies box shadow when elevation > 0', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              elevation: 4,
              child: Text('그림자'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
      });

      testWidgets('no box shadow when elevation is 0', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              elevation: 0,
              child: Text('평면'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNull);
      });

      testWidgets('applies custom padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              padding: const EdgeInsets.all(32),
              child: Text('패딩'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.padding, equals(const EdgeInsets.all(32)));
      });

      testWidgets('applies margin via Padding widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              margin: const EdgeInsets.all(16),
              child: Text('마진'),
            ),
          ),
        );

        expect(find.text('마진'), findsOneWidget);
        // Margin wraps the card in a Padding widget
        final paddingWidgets = tester.widgetList<Padding>(
          find.ancestor(
            of: find.byType(Container),
            matching: find.byType(Padding),
          ),
        );
        expect(paddingWidgets, isNotEmpty);
      });
    });

    group('interaction', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              onTap: () {
                tapped = true;
              },
              child: Text('탭 가능'),
            ),
          ),
        );

        await tester.tap(find.text('탭 가능'));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onLongPress when long-pressed', (WidgetTester tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              onLongPress: () {
                longPressed = true;
              },
              child: Text('길게 누르기'),
            ),
          ),
        );

        await tester.longPress(find.text('길게 누르기'));
        await tester.pump();

        expect(longPressed, isTrue);
      });

      testWidgets('does not call onTap when disabled', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              enabled: false,
              onTap: () {
                tapped = true;
              },
              child: Text('비활성'),
            ),
          ),
        );

        await tester.tap(find.text('비활성'));
        await tester.pump();

        expect(tapped, isFalse);
      });

      testWidgets('does not call onLongPress when disabled', (WidgetTester tester) async {
        bool longPressed = false;

        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              enabled: false,
              onLongPress: () {
                longPressed = true;
              },
              child: Text('비활성'),
            ),
          ),
        );

        await tester.longPress(find.text('비활성'));
        await tester.pump();

        expect(longPressed, isFalse);
      });

      testWidgets('no InkWell when no tap/longPress callbacks', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              child: Text('정적 카드'),
            ),
          ),
        );

        expect(find.byType(InkWell), findsNothing);
      });

      testWidgets('wraps with InkWell when onTap is provided', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              onTap: () {},
              child: Text('인터랙티브'),
            ),
          ),
        );

        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('disabled state', () {
      testWidgets('shows reduced opacity when disabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              enabled: false,
              child: Text('반투명'),
            ),
          ),
        );

        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Opacity),
          ),
        );

        expect(opacity.opacity, equals(0.5));
      });

      testWidgets('shows full opacity when enabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              enabled: true,
              child: Text('불투명'),
            ),
          ),
        );

        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Opacity),
          ),
        );

        expect(opacity.opacity, equals(1.0));
      });
    });

    group('accessibility', () {
      testWidgets('applies semanticLabel', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              semanticLabel: '아이템 카드',
              child: Text('내용'),
            ),
          ),
        );

        // Verify the Semantics widget has the correct label
        final semanticsWidget = tester.widget<Semantics>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Semantics),
          ).first,
        );
        expect(semanticsWidget.properties.label, equals('아이템 카드'));
      });

      testWidgets('marks as button in semantics when onTap is provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              onTap: () {},
              semanticLabel: '버튼 카드',
              child: Text('탭'),
            ),
          ),
        );

        // Verify semantics has button: true
        final semanticsWidget = tester.widget<Semantics>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Semantics),
          ).first,
        );
        expect(semanticsWidget.properties.button, isTrue);
        expect(semanticsWidget.properties.label, equals('버튼 카드'));
      });

      testWidgets('semantics does not mark as button when no onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard(
              child: Text('정적'),
            ),
          ),
        );

        final semanticsWidget = tester.widget<Semantics>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Semantics),
          ).first,
        );
        expect(semanticsWidget.properties.button, isFalse);
      });
    });

    group('named constructors', () {
      testWidgets('MGCard.interactive requires onTap', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          createTestWidget(
            MGCard.interactive(
              onTap: () {
                tapped = true;
              },
              child: Text('인터랙티브'),
            ),
          ),
        );

        await tester.tap(find.text('인터랙티브'));
        await tester.pump();

        expect(tapped, isTrue);
        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('MGCard.outlined has no elevation and default border',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard.outlined(
              child: Text('아웃라인'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        // No shadow (elevation = 0)
        expect(decoration.boxShadow, isNull);
        // Has border
        expect(decoration.border, isNotNull);
      });

      testWidgets('MGCard.transparent has transparent background and no elevation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MGCard.transparent(
              child: Text('투명'),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MGCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.transparent));
        expect(decoration.boxShadow, isNull);
      });
    });
  });

  // ============================================================
  // MGItemCard
  // ============================================================

  group('MGItemCard', () {
    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '아이템 제목',
          ),
        ),
      );

      expect(find.text('아이템 제목'), findsOneWidget);
    });

    testWidgets('renders icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            icon: Icons.star,
            title: '별 아이템',
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('별 아이템'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '제목',
            subtitle: '부제목',
          ),
        ),
      );

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('부제목'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '트레일링',
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders leading widget instead of icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            leading: CircleAvatar(child: Text('A')),
            title: '리딩 위젯',
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('리딩 위젯'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '탭 아이템',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('탭 아이템'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '비활성 아이템',
            enabled: false,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('비활성 아이템'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('applies custom icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            icon: Icons.favorite,
            iconColor: Colors.pink,
            title: '핑크 아이콘',
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, equals(Colors.pink));
    });

    testWidgets('applies custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGItemCard(
            title: '배경색',
            backgroundColor: Colors.amber,
          ),
        ),
      );

      expect(find.text('배경색'), findsOneWidget);
    });
  });

  // ============================================================
  // MGStatCard
  // ============================================================

  group('MGStatCard', () {
    testWidgets('renders label and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '점수',
            value: '1,234',
          ),
        ),
      );

      expect(find.text('점수'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '코인',
            value: '500',
            icon: Icons.monetization_on,
          ),
        ),
      );

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('renders positive change text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '수익',
            value: '10,000',
            change: '+12%',
            positive: true,
          ),
        ),
      );

      expect(find.text('+12%'), findsOneWidget);
    });

    testWidgets('renders negative change text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '손실',
            value: '5,000',
            change: '-8%',
            positive: false,
          ),
        ),
      );

      expect(find.text('-8%'), findsOneWidget);
    });

    testWidgets('does not show change when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '단순',
            value: '100',
          ),
        ),
      );

      expect(find.text('단순'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      // Only 2 text widgets in the stat card (label + value)
    });

    testWidgets('applies custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '커스텀',
            value: '42',
            color: Colors.deepPurple,
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          MGStatCard(
            label: '탭',
            value: '99',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('99'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // ============================================================
  // MGGameCard
  // ============================================================

  group('MGGameCard', () {
    testWidgets('renders thumbnail and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.blue),
            title: '게임 이름',
          ),
        ),
      );

      expect(find.text('게임 이름'), findsOneWidget);
    });

    testWidgets('renders category when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.green),
            title: '퍼즐 게임',
            category: '퍼즐',
          ),
        ),
      );

      expect(find.text('퍼즐 게임'), findsOneWidget);
      expect(find.text('퍼즐'), findsOneWidget);
    });

    testWidgets('renders rating with star icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.orange),
            title: '인기 게임',
            rating: 4.5,
          ),
        ),
      );

      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('applies custom width', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.red),
            title: '넓은 카드',
            width: 200,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(MGCard),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, equals(200));
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.purple),
            title: '탭 게임',
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('탭 게임'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders both category and rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.teal),
            title: '완전 게임',
            category: 'RPG',
            rating: 3.8,
          ),
        ),
      );

      expect(find.text('완전 게임'), findsOneWidget);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('3.8'), findsOneWidget);
    });

    testWidgets('uses default width of 160', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MGGameCard(
            thumbnail: Container(color: Colors.grey),
            title: '기본 너비',
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(MGCard),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, equals(160));
    });
  });
}

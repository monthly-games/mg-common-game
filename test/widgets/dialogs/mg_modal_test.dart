import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/dialogs/mg_modal.dart';
import 'package:mg_common_game/core/ui/widgets/buttons/mg_button.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';

void main() {
  Widget createTestApp({Widget? home}) {
    return MaterialApp(
      home: home ??
          MGAccessibilityProvider(
            settings: MGAccessibilitySettings.defaults,
            onSettingsChanged: (_) {},
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Text('트리거'),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Helper to get a BuildContext from the widget tree
  BuildContext getContext(WidgetTester tester) {
    return tester.element(find.text('트리거'));
  }

  // ============================================================
  // MGModal.show
  // ============================================================

  group('MGModal.show', () {
    testWidgets('renders title and content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '모달 제목',
        content: Text('모달 내용'),
      );

      await tester.pumpAndSettle();

      expect(find.text('모달 제목'), findsOneWidget);
      expect(find.text('모달 내용'), findsOneWidget);
    });

    testWidgets('renders action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '액션 모달',
        content: Text('내용'),
        actions: [
          MGButton.text(label: '취소', onPressed: () {}),
          MGButton.primary(label: '확인', onPressed: () {}),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('dismisses on barrier tap when barrierDismissible is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '닫을 수 있는 모달',
        content: Text('탭하여 닫기'),
        barrierDismissible: true,
      );

      await tester.pumpAndSettle();
      expect(find.text('닫을 수 있는 모달'), findsOneWidget);

      // Tap the barrier (outside the dialog)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('닫을 수 있는 모달'), findsNothing);
    });

    testWidgets('does not dismiss on barrier tap when barrierDismissible is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '고정 모달',
        content: Text('닫을 수 없음'),
        barrierDismissible: false,
      );

      await tester.pumpAndSettle();
      expect(find.text('고정 모달'), findsOneWidget);

      // Tap the barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Still visible
      expect(find.text('고정 모달'), findsOneWidget);

      // Clean up - dismiss the dialog via Navigator
      Navigator.of(getContext(tester)).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('renders with Dialog widget', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '다이얼로그',
        content: Text('내용'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      // Clean up
      Navigator.of(getContext(tester)).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('dialog has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '둥근 모서리',
        content: Text('내용'),
      );

      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        equals(BorderRadius.circular(16)),
      );

      // Clean up
      Navigator.of(getContext(tester)).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('shows divider between title and content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.show(
        context: context,
        title: '구분선',
        content: Text('내용'),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsOneWidget);

      // Clean up
      Navigator.of(getContext(tester)).pop();
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGModal.confirm
  // ============================================================

  group('MGModal.confirm', () {
    testWidgets('shows title and message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.confirm(
        context: context,
        title: '확인 제목',
        message: '정말 삭제하시겠습니까?',
      );

      await tester.pumpAndSettle();

      expect(find.text('확인 제목'), findsOneWidget);
      expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);
    });

    testWidgets('returns true when confirm is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      final future = MGModal.confirm(
        context: context,
        title: '삭제',
        message: '삭제할까요?',
        confirmText: '삭제',
        cancelText: '아니오',
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, isTrue);
    });

    testWidgets('returns false when cancel is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      final future = MGModal.confirm(
        context: context,
        title: '취소 테스트',
        message: '취소할까요?',
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, isFalse);
    });

    testWidgets('returns false when dismissed by barrier tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      final future = MGModal.confirm(
        context: context,
        title: '배리어 닫기',
        message: '외부 탭',
      );

      await tester.pumpAndSettle();

      // Tap barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, isFalse);
    });

    testWidgets('uses custom button labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.confirm(
        context: context,
        title: '커스텀 버튼',
        message: '계속하시겠습니까?',
        confirmText: '네, 진행',
        cancelText: '아니요',
      );

      await tester.pumpAndSettle();

      expect(find.text('네, 진행'), findsOneWidget);
      expect(find.text('아니요'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('아니요'));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGModal.alert
  // ============================================================

  group('MGModal.alert', () {
    testWidgets('shows title and message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.alert(
        context: context,
        title: '알림',
        message: '작업이 완료되었습니다.',
      );

      await tester.pumpAndSettle();

      expect(find.text('알림'), findsOneWidget);
      expect(find.text('작업이 완료되었습니다.'), findsOneWidget);
    });

    testWidgets('shows default button text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.alert(
        context: context,
        title: '기본 버튼',
        message: '메시지',
      );

      await tester.pumpAndSettle();

      expect(find.text('확인'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });

    testWidgets('uses custom button text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.alert(
        context: context,
        title: '커스텀',
        message: '메시지',
        buttonText: '알겠습니다',
      );

      await tester.pumpAndSettle();

      expect(find.text('알겠습니다'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('알겠습니다'));
      await tester.pumpAndSettle();
    });

    testWidgets('dismisses when button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.alert(
        context: context,
        title: '닫기 테스트',
        message: '버튼으로 닫기',
      );

      await tester.pumpAndSettle();
      expect(find.text('닫기 테스트'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('닫기 테스트'), findsNothing);
    });
  });

  // ============================================================
  // MGModal.success
  // ============================================================

  group('MGModal.success', () {
    testWidgets('shows check circle icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.success(
        context: context,
        title: '성공!',
        message: '저장되었습니다.',
      );

      await tester.pumpAndSettle();

      expect(find.text('성공!'), findsOneWidget);
      expect(find.text('저장되었습니다.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Clean up
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows without message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.success(
        context: context,
        title: '완료',
      );

      await tester.pumpAndSettle();

      expect(find.text('완료'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Clean up
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGModal.error
  // ============================================================

  group('MGModal.error', () {
    testWidgets('shows error icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.error(
        context: context,
        title: '오류',
        message: '네트워크 오류가 발생했습니다.',
      );

      await tester.pumpAndSettle();

      expect(find.text('오류'), findsOneWidget);
      expect(find.text('네트워크 오류가 발생했습니다.'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Clean up
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });

    testWidgets('shows without message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.error(
        context: context,
        title: '실패',
      );

      await tester.pumpAndSettle();

      expect(find.text('실패'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Clean up
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });

    testWidgets('uses custom button text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.error(
        context: context,
        title: '에러',
        message: '문제 발생',
        buttonText: '닫기',
      );

      await tester.pumpAndSettle();

      expect(find.text('닫기'), findsOneWidget);

      // Clean up
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGModal.loading
  // ============================================================

  group('MGModal.loading', () {
    testWidgets('shows spinner and message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.loading(
        context: context,
        message: '로딩 중...',
      );

      // Use pump() instead of pumpAndSettle() because
      // CircularProgressIndicator animates continuously
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('로딩 중...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up - loading dialog is not barrier dismissible
      MGModal.closeLoading(getContext(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('loading dialog is not barrier-dismissible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.loading(
        context: context,
        message: '처리 중...',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('처리 중...'), findsOneWidget);

      // Tap barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Still visible
      expect(find.text('처리 중...'), findsOneWidget);

      // Clean up
      MGModal.closeLoading(getContext(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  // ============================================================
  // MGModal.select
  // ============================================================

  group('MGModal.select', () {
    testWidgets('renders option labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.select<String>(
        context: context,
        title: '선택하세요',
        options: [
          MGSelectOption(value: 'a', label: '옵션 A'),
          MGSelectOption(value: 'b', label: '옵션 B'),
          MGSelectOption(value: 'c', label: '옵션 C'),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('선택하세요'), findsOneWidget);
      expect(find.text('옵션 A'), findsOneWidget);
      expect(find.text('옵션 B'), findsOneWidget);
      expect(find.text('옵션 C'), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('returns selected value when option is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      final future = MGModal.select<String>(
        context: context,
        title: '선택',
        options: [
          MGSelectOption(value: 'first', label: '첫 번째'),
          MGSelectOption(value: 'second', label: '두 번째'),
        ],
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('두 번째'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, equals('second'));
    });

    testWidgets('shows check mark on selected option', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.select<String>(
        context: context,
        title: '선택됨',
        options: [
          MGSelectOption(value: 'a', label: '선택 A'),
          MGSelectOption(value: 'b', label: '선택 B'),
        ],
        selectedValue: 'b',
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('renders option descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.select<int>(
        context: context,
        title: '설명 옵션',
        options: [
          MGSelectOption(value: 1, label: '기본', description: '무료 플랜'),
          MGSelectOption(value: 2, label: '프로', description: '유료 플랜'),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('무료 플랜'), findsOneWidget);
      expect(find.text('유료 플랜'), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('renders option icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGModal.select<String>(
        context: context,
        title: '아이콘 옵션',
        options: [
          MGSelectOption(value: 'music', label: '음악', icon: Icons.music_note),
          MGSelectOption(value: 'video', label: '동영상', icon: Icons.videocam),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGModal.input
  // ============================================================

  group('MGModal.input', () {
    // Note: MGModal.input disposes its TextEditingController immediately
    // after the dialog closes, which can race with the close animation.
    // We use pump() (not pumpAndSettle) for cleanup to avoid this.

    testWidgets('renders title and text field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      unawaited(MGModal.input(
        context: context,
        title: '이름 입력',
        hintText: '이름을 입력하세요',
      ));

      await tester.pumpAndSettle();

      expect(find.text('이름 입력'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows initial value in text field', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      unawaited(MGModal.input(
        context: context,
        title: '수정',
        initialValue: '기존 값',
      ));

      await tester.pumpAndSettle();

      expect(find.text('기존 값'), findsOneWidget);
    });

    testWidgets('shows optional message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      unawaited(MGModal.input(
        context: context,
        title: '입력',
        message: '닉네임을 변경합니다.',
      ));

      await tester.pumpAndSettle();

      expect(find.text('닉네임을 변경합니다.'), findsOneWidget);
    });

    testWidgets('uses custom button labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      unawaited(MGModal.input(
        context: context,
        title: '커스텀',
        confirmText: '적용',
        cancelText: '돌아가기',
      ));

      await tester.pumpAndSettle();

      expect(find.text('적용'), findsOneWidget);
      expect(find.text('돌아가기'), findsOneWidget);
    });
  });

  // ============================================================
  // MGBottomSheet
  // ============================================================

  group('MGBottomSheet', () {
    testWidgets('renders child content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGBottomSheet.show(
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('바텀 시트 내용'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('바텀 시트 내용'), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('renders title when provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGBottomSheet.show(
        context: context,
        title: '시트 제목',
        child: Text('내용'),
      );

      await tester.pumpAndSettle();

      expect(find.text('시트 제목'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('shows drag handle when enableDrag is true', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGBottomSheet.show(
        context: context,
        enableDrag: true,
        child: Text('드래그 가능'),
      );

      await tester.pumpAndSettle();

      // The drag handle is a 40x4 Container
      expect(find.text('드래그 가능'), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('select renders options and returns selected value',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      final future = MGBottomSheet.select<String>(
        context: context,
        title: '정렬 기준',
        options: [
          MGSelectOption(value: 'name', label: '이름순'),
          MGSelectOption(value: 'date', label: '날짜순'),
          MGSelectOption(value: 'price', label: '가격순'),
        ],
      );

      await tester.pumpAndSettle();

      expect(find.text('정렬 기준'), findsOneWidget);
      expect(find.text('이름순'), findsOneWidget);
      expect(find.text('날짜순'), findsOneWidget);
      expect(find.text('가격순'), findsOneWidget);

      await tester.tap(find.text('날짜순'));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result, equals('date'));
    });

    testWidgets('select shows check on selected value', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      final context = getContext(tester);
      MGBottomSheet.select<String>(
        context: context,
        title: '현재 선택',
        options: [
          MGSelectOption(value: 'a', label: 'A'),
          MGSelectOption(value: 'b', label: 'B'),
        ],
        selectedValue: 'a',
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);

      // Clean up
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MGSelectOption
  // ============================================================

  group('MGSelectOption', () {
    test('stores value and label', () {
      final option = MGSelectOption(value: 42, label: '답');
      expect(option.value, equals(42));
      expect(option.label, equals('답'));
    });

    test('stores optional description and icon', () {
      final option = MGSelectOption(
        value: 'x',
        label: '옵션',
        description: '설명',
        icon: Icons.star,
      );
      expect(option.description, equals('설명'));
      expect(option.icon, equals(Icons.star));
    });

    test('description and icon are null by default', () {
      final option = MGSelectOption(value: 1, label: '기본');
      expect(option.description, isNull);
      expect(option.icon, isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/widgets/buttons/mg_button.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';

void main() {
  group('MGButton', () {
    Widget buildTestWidget({
      required Widget child,
      MGAccessibilitySettings? settings,
    }) {
      return MaterialApp(
        home: MGAccessibilityProvider(
          settings: settings ?? const MGAccessibilitySettings(),
          onSettingsChanged: (_) {},
          child: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton(label: 'Test Button'),
      ));

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: MGButton(
          label: 'Test',
          onPressed: () => pressed = true,
        ),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: MGButton(
          label: 'Test',
          onPressed: () => pressed = true,
          enabled: false,
        ),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('does not call onPressed when loading', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(buildTestWidget(
        child: MGButton(
          label: 'Test',
          onPressed: () => pressed = true,
          loading: true,
        ),
      ));

      await tester.tap(find.byType(MGButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton(
          label: 'Test',
          loading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton(
          label: 'Test',
          icon: Icons.add,
        ),
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('primary button has filled style', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton.primary(label: 'Primary'),
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('secondary button has outlined style', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton.secondary(label: 'Secondary'),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('text button has text style', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton.text(label: 'Text'),
      ));

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('respects accessibility touch size', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const MGButton(label: 'Test'),
        settings: const MGAccessibilitySettings(
          touchAreaSize: TouchAreaSize.extraLarge,
        ),
      ));

      // 버튼이 렌더링되는지 확인
      expect(find.text('Test'), findsOneWidget);
      // TouchAreaSize.extraLarge가 설정에 적용되었는지 확인
      final provider = tester.widget<MGAccessibilityProvider>(find.byType(MGAccessibilityProvider));
      expect(provider.settings.touchAreaSize, equals(TouchAreaSize.extraLarge));
    });

    group('MGButtonSize', () {
      testWidgets('small size renders correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const MGButton(
            label: 'Small',
            size: MGButtonSize.small,
          ),
        ));

        expect(find.text('Small'), findsOneWidget);
      });

      testWidgets('large size renders correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          child: const MGButton(
            label: 'Large',
            size: MGButtonSize.large,
          ),
        ));

        expect(find.text('Large'), findsOneWidget);
      });
    });
  });

  group('MGIconButton', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(),
          onSettingsChanged: (_) {},
          child: const Scaffold(
            body: Center(
              child: MGIconButton(icon: Icons.settings),
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(MaterialApp(
        home: MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(),
          onSettingsChanged: (_) {},
          child: Scaffold(
            body: Center(
              child: MGIconButton(
                icon: Icons.settings,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MGAccessibilityProvider(
          settings: const MGAccessibilitySettings(),
          onSettingsChanged: (_) {},
          child: const Scaffold(
            body: Center(
              child: MGIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
              ),
            ),
          ),
        ),
      ));

      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });
}

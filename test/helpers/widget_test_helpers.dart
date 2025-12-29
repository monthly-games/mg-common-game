import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';

/// Helper functions for widget testing in mg_common_game
///
/// This file provides common test utilities to reduce boilerplate
/// and ensure consistent test setup across the test suite.

/// Creates a Material app wrapper for widget testing
///
/// Most widgets require MaterialApp context to render properly.
/// This helper provides a standard wrapper with optional customization.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   createMaterialApp(
///     child: MyWidget(),
///   ),
/// );
/// ```
Widget createMaterialApp({
  required Widget child,
  ThemeData? theme,
  Locale? locale,
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    home: Scaffold(
      body: child,
    ),
  );
}

/// Creates a widget wrapped with MGAccessibilityProvider
///
/// Used for testing widgets that depend on accessibility settings,
/// particularly buttons and interactive elements.
///
/// Example:
/// ```dart
/// await tester.pumpWidget(
///   createAccessibilityTestWidget(
///     child: MGButton(label: 'Test'),
///     settings: MGAccessibilitySettings.defaults.copyWith(
///       touchAreaSize: TouchAreaSize.large,
///     ),
///   ),
/// );
/// ```
Widget createAccessibilityTestWidget({
  required Widget child,
  MGAccessibilitySettings? settings,
}) {
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

/// Pumps a widget and waits for all animations to complete
///
/// This is a convenience method that combines pumpWidget and pumpAndSettle.
/// Useful for widgets with animations or async operations.
///
/// Example:
/// ```dart
/// await pumpAndSettle(
///   tester,
///   createMaterialApp(child: AnimatedWidget()),
/// );
/// ```
Future<void> pumpAndSettle(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle(duration);
}

/// Verifies that a callback was called exactly once
///
/// Example:
/// ```dart
/// int callCount = 0;
/// onPressed: () => callCount++
///
/// await tester.tap(find.byType(MyButton));
/// await tester.pump();
///
/// expectCallbackCalledOnce(callCount);
/// ```
void expectCallbackCalledOnce(int callCount) {
  expect(callCount, equals(1), reason: 'Callback should be called exactly once');
}

/// Verifies that a callback was never called
///
/// Example:
/// ```dart
/// int callCount = 0;
///
/// // Disabled button shouldn't trigger callback
/// await tester.tap(find.byType(MyButton));
/// await tester.pump();
///
/// expectCallbackNotCalled(callCount);
/// ```
void expectCallbackNotCalled(int callCount) {
  expect(callCount, equals(0), reason: 'Callback should not be called');
}

/// Finds a widget by its semantic label
///
/// Useful for accessibility testing to ensure screen readers
/// can properly identify UI elements.
///
/// Example:
/// ```dart
/// expect(findBySemanticsLabel('Submit'), findsOneWidget);
/// ```
Finder findBySemanticsLabel(String label) {
  return find.bySemanticsLabel(label);
}

/// Waits for a specific duration during tests
///
/// Use sparingly - prefer pumpAndSettle when possible.
/// Only use for testing specific timing-dependent behavior.
///
/// Example:
/// ```dart
/// await waitFor(tester, Duration(milliseconds: 200));
/// ```
Future<void> waitFor(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
}

/// Verifies text is present in the widget tree
///
/// Example:
/// ```dart
/// expectTextPresent('Hello World');
/// ```
void expectTextPresent(String text) {
  expect(find.text(text), findsOneWidget,
      reason: 'Text "$text" should be present');
}

/// Verifies text is not present in the widget tree
///
/// Example:
/// ```dart
/// expectTextAbsent('Error message');
/// ```
void expectTextAbsent(String text) {
  expect(find.text(text), findsNothing,
      reason: 'Text "$text" should not be present');
}

/// Verifies an icon is present in the widget tree
///
/// Example:
/// ```dart
/// expectIconPresent(Icons.check);
/// ```
void expectIconPresent(IconData icon) {
  expect(find.byIcon(icon), findsWidgets,
      reason: 'Icon ${icon.codePoint} should be present');
}

/// Verifies a widget type is present in the widget tree
///
/// Example:
/// ```dart
/// expectWidgetPresent<CircularProgressIndicator>();
/// ```
void expectWidgetPresent<T extends Widget>() {
  expect(find.byType(T), findsWidgets,
      reason: 'Widget of type $T should be present');
}

/// Verifies a widget type is not present in the widget tree
///
/// Example:
/// ```dart
/// expectWidgetAbsent<CircularProgressIndicator>();
/// ```
void expectWidgetAbsent<T extends Widget>() {
  expect(find.byType(T), findsNothing,
      reason: 'Widget of type $T should not be present');
}

/// Test data generators for common scenarios

/// Generates test gacha items for testing
///
/// Example:
/// ```dart
/// final items = generateTestGachaItems(count: 5);
/// ```
// Note: Commented out to avoid import issues
// Can be uncommented when needed
/*
List<GachaItem> generateTestGachaItems({
  int count = 3,
  GachaRarity rarity = GachaRarity.rare,
}) {
  return List.generate(
    count,
    (index) => GachaItem(
      id: 'test_item_$index',
      nameKr: '테스트 아이템 ${index + 1}',
      rarity: rarity,
    ),
  );
}
*/

/// Generates test battle pass tiers for testing
///
/// Example:
/// ```dart
/// final tiers = generateTestBattlePassTiers(count: 10);
/// ```
// Note: Commented out to avoid import issues
// Can be uncommented when needed
/*
List<BPTier> generateTestBattlePassTiers({
  int count = 5,
  int baseExp = 1000,
}) {
  return List.generate(
    count,
    (index) => BPTier(
      level: index + 1,
      requiredExp: baseExp * (index + 1),
      freeRewards: [
        BPReward(
          id: 'free_${index + 1}',
          nameKr: '무료 보상 ${index + 1}',
          type: BPRewardType.currency,
          amount: 100 * (index + 1),
        ),
      ],
      premiumRewards: [
        BPReward(
          id: 'premium_${index + 1}',
          nameKr: '프리미엄 보상 ${index + 1}',
          type: BPRewardType.item,
          amount: 1,
          isPremiumOnly: true,
        ),
      ],
    ),
  );
}
*/

/// Extension methods for WidgetTester convenience

extension WidgetTesterExtensions on WidgetTester {
  /// Taps a widget and waits for the tap to complete
  ///
  /// Example:
  /// ```dart
  /// await tester.tapAndSettle(find.byType(MyButton));
  /// ```
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text and waits for the UI to update
  ///
  /// Example:
  /// ```dart
  /// await tester.enterTextAndSettle(find.byType(TextField), 'Hello');
  /// ```
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Scrolls until a widget is visible
  ///
  /// Example:
  /// ```dart
  /// await tester.scrollUntilVisible(
  ///   find.text('Item 50'),
  ///   500,
  ///   scrollable: find.byType(ListView),
  /// );
  /// ```
  Future<void> scrollUntilVisible(
    Finder finder,
    double delta, {
    Finder? scrollable,
    Duration? duration,
    int maxScrolls = 50,
  }) async {
    await dragUntilVisible(
      finder,
      scrollable ?? find.byType(Scrollable).first,
      Offset(0, delta),
      duration: duration,
      maxIteration: maxScrolls,
    );
  }
}

/// Common test constants

class TestConstants {
  TestConstants._();

  /// Default animation duration for tests
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Short animation duration for faster tests
  static const Duration shortAnimationDuration = Duration(milliseconds: 100);

  /// Timeout for async operations
  static const Duration asyncTimeout = Duration(seconds: 5);

  /// Default accessibility settings for testing
  static const MGAccessibilitySettings defaultAccessibilitySettings =
      MGAccessibilitySettings.defaults;

  /// Large touch area accessibility settings
  static final MGAccessibilitySettings largeTouchAreaSettings =
      MGAccessibilitySettings.defaults.copyWith(
    touchAreaSize: TouchAreaSize.large,
  );

  /// Extra large touch area accessibility settings
  static final MGAccessibilitySettings extraLargeTouchAreaSettings =
      MGAccessibilitySettings.defaults.copyWith(
    touchAreaSize: TouchAreaSize.extraLarge,
  );

  /// High contrast accessibility settings
  static final MGAccessibilitySettings highContrastSettings =
      MGAccessibilitySettings.defaults.copyWith(
    highContrastEnabled: true,
  );

  /// Reduced motion accessibility settings
  static final MGAccessibilitySettings reducedMotionSettings =
      MGAccessibilitySettings.defaults.copyWith(
    reduceMotion: true,
  );
}

/// Callback tracker for testing
///
/// Useful for tracking multiple callback invocations
///
/// Example:
/// ```dart
/// final tracker = CallbackTracker();
/// onPressed: tracker.call
///
/// expect(tracker.callCount, equals(0));
/// await tester.tap(find.byType(MyButton));
/// expect(tracker.callCount, equals(1));
/// ```
class CallbackTracker {
  int callCount = 0;
  List<dynamic> arguments = [];

  void call([dynamic arg]) {
    callCount++;
    if (arg != null) {
      arguments.add(arg);
    }
  }

  void reset() {
    callCount = 0;
    arguments.clear();
  }

  bool get wasCalled => callCount > 0;
  bool get wasNotCalled => callCount == 0;
  bool get wasCalledOnce => callCount == 1;
}

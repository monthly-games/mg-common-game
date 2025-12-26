import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper utilities for MG Games
///
/// Provides common test setup, mocking, and assertion utilities.

// ============================================================
// Widget Test Helpers
// ============================================================

/// Wraps a widget with MaterialApp for testing
Widget testableWidget(
  Widget child, {
  ThemeData? theme,
  Locale? locale,
  List<NavigatorObserver>? navigatorObservers,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    locale: locale,
    navigatorObservers: navigatorObservers ?? [],
    home: child,
  );
}

/// Wraps a widget with Scaffold for testing
Widget scaffoldWidget(
  Widget child, {
  ThemeData? theme,
}) {
  return testableWidget(
    Scaffold(body: child),
    theme: theme,
  );
}

/// Pumps widget and settles all animations
extension WidgetTesterExtensions on WidgetTester {
  /// Pump widget and wait for all animations to complete
  Future<void> pumpAndSettle2({
    Duration duration = const Duration(milliseconds: 100),
    int maxRetries = 100,
  }) async {
    int retries = 0;
    while (retries < maxRetries) {
      await pump(duration);
      if (!hasRunningAnimations) break;
      retries++;
    }
  }

  /// Tap and wait for animations
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and wait
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Drag and wait
  Future<void> dragAndSettle(Finder finder, Offset offset) async {
    await drag(finder, offset);
    await pumpAndSettle();
  }

  /// Find widget by text and tap
  Future<void> tapText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Find widget by key and tap
  Future<void> tapKey(Key key) async {
    await tap(find.byKey(key));
    await pumpAndSettle();
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder,
    Finder scrollable, {
    double delta = 100,
    int maxScrolls = 50,
  }) async {
    int scrolls = 0;
    while (scrolls < maxScrolls) {
      if (finder.evaluate().isNotEmpty) break;
      await drag(scrollable, Offset(0, -delta));
      await pump();
      scrolls++;
    }
    await pumpAndSettle();
  }
}

// ============================================================
// Finder Extensions
// ============================================================

extension FinderExtensions on CommonFinders {
  /// Find by semantic label
  Finder bySemanticsLabel(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Find by tooltip
  Finder byTooltipText(String tooltip) {
    return find.byTooltip(tooltip);
  }

  /// Find ancestor of type with descendant
  Finder ancestorOf<T extends Widget>(Finder descendant) {
    return find.ancestor(
      of: descendant,
      matching: find.byType(T),
    );
  }

  /// Find descendant of widget
  Finder descendantOf(Finder ancestor, Finder descendant) {
    return find.descendant(
      of: ancestor,
      matching: descendant,
    );
  }
}

// ============================================================
// Async Test Helpers
// ============================================================

/// Wait for a condition to be true
Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(endTime)) {
      throw TimeoutException('Condition not met within timeout');
    }
    await Future.delayed(interval);
  }
}

/// Wait for future with timeout
Future<T> waitForFuture<T>(
  Future<T> future, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  return future.timeout(timeout);
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

// ============================================================
// Mock Data Generators
// ============================================================

/// Generate random test data
class TestDataGenerator {
  static int _counter = 0;

  /// Generate unique ID
  static String uniqueId([String prefix = 'test']) {
    _counter++;
    return '${prefix}_$_counter';
  }

  /// Generate random string
  static String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (i) => chars[(DateTime.now().microsecond + i) % chars.length],
    ).join();
  }

  /// Generate random int in range
  static int randomInt(int min, int max) {
    return min + (DateTime.now().microsecond % (max - min + 1));
  }

  /// Generate random double in range
  static double randomDouble(double min, double max) {
    final fraction = (DateTime.now().microsecond % 1000) / 1000;
    return min + (max - min) * fraction;
  }

  /// Generate test player data
  static Map<String, dynamic> playerData({
    String? id,
    String? name,
    int? level,
    int? coins,
  }) {
    return {
      'id': id ?? uniqueId('player'),
      'name': name ?? 'TestPlayer',
      'level': level ?? randomInt(1, 100),
      'coins': coins ?? randomInt(0, 10000),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate test item data
  static Map<String, dynamic> itemData({
    String? id,
    String? name,
    String? type,
    int? rarity,
  }) {
    return {
      'id': id ?? uniqueId('item'),
      'name': name ?? 'TestItem',
      'type': type ?? 'equipment',
      'rarity': rarity ?? randomInt(1, 5),
    };
  }

  /// Generate list of test items
  static List<Map<String, dynamic>> itemList(int count) {
    return List.generate(count, (i) => itemData(id: 'item_$i'));
  }

  /// Reset counter
  static void reset() {
    _counter = 0;
  }
}

// ============================================================
// Expectation Helpers
// ============================================================

/// Custom matchers for game testing
class GameMatchers {
  /// Matches value within range
  static Matcher inRange(num min, num max) {
    return predicate<num>(
      (value) => value >= min && value <= max,
      'is in range [$min, $max]',
    );
  }

  /// Matches non-empty string
  static Matcher get nonEmptyString {
    return predicate<String>(
      (value) => value.isNotEmpty,
      'is non-empty string',
    );
  }

  /// Matches valid ID format
  static Matcher get validId {
    return predicate<String>(
      (value) => value.isNotEmpty && !value.contains(' '),
      'is valid ID',
    );
  }

  /// Matches positive number
  static Matcher get positive {
    return predicate<num>(
      (value) => value > 0,
      'is positive',
    );
  }

  /// Matches non-negative number
  static Matcher get nonNegative {
    return predicate<num>(
      (value) => value >= 0,
      'is non-negative',
    );
  }

  /// Matches percentage (0-100)
  static Matcher get percentage {
    return inRange(0, 100);
  }

  /// Matches normalized value (0-1)
  static Matcher get normalized {
    return inRange(0, 1);
  }
}

// ============================================================
// Test Group Helpers
// ============================================================

/// Setup and teardown helpers
class TestSetup {
  static final List<VoidCallback> _teardowns = [];

  /// Register teardown callback
  static void onTeardown(VoidCallback callback) {
    _teardowns.add(callback);
  }

  /// Run all teardowns
  static void runTeardowns() {
    for (final teardown in _teardowns.reversed) {
      teardown();
    }
    _teardowns.clear();
  }

  /// Setup for widget tests
  static void setupWidgetTests() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Setup for unit tests
  static void setupUnitTests() {
    TestDataGenerator.reset();
  }
}

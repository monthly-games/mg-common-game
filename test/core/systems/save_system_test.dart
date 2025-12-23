import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/systems/save_system.dart';

// Wrap SharedPreferences interaction if possible, or mock the platform channel.
// SharedPreferences.setMockInitialValues({}) is the standard way for integrated testing,
// but for unit testing the logic, we want to mock the instance if possible.
// However, SharedPreferences.getInstance() is static.
// Better to inject a wrapper or usage mechanism.
// Or we use `SharedPreferences.setMockInitialValues` for simplicity in Dart.

void main() {
  late LocalSaveSystem saveSystem;

  setUp(() async {
    // Mocking standard Platform Channel values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    saveSystem = LocalSaveSystem();
    await saveSystem.init(); // Assuming it needs init to get the instance
  });

  group('LocalSaveSystem', () {
    test('save writes data to prefs', () async {
      await saveSystem.save('test_key', {'gold': 100});

      final data = await saveSystem.load('test_key');
      expect(data, isNotNull);
      expect(data!['gold'], 100);
    });

    test('load returns null for missing key', () async {
      final data = await saveSystem.load('missing_key');
      expect(data, isNull);
    });
  });
}

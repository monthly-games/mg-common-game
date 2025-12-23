import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GoldManager goldManager;
  late LocalSaveSystem saveSystem;

  setUp(() async {
    SharedPreferences.setMockInitialValues({}); // Start fresh
    goldManager = GoldManager();
    saveSystem = LocalSaveSystem();
    await saveSystem.init();
  });

  test('Integration: Gold changes should be savable', () async {
    // 1. Add Gold
    goldManager.addGold(500);

    // 2. Manual Save Trigger
    await saveSystem.save('gold', {'amount': goldManager.currentGold});

    // 3. Verify Persistence (Reload to check)
    final loadedData = await saveSystem.load('gold');
    expect(loadedData?['amount'], 500);
  });

  test('Integration: Gold should be loaded from save', () async {
    // 1. Pre-exist data
    await saveSystem.save('gold', {'amount': 999});

    // 2. Load
    final loadedData = await saveSystem.load('gold');
    final savedGold = loadedData?['amount'] as int? ?? 0;

    goldManager.addGold(savedGold);

    // 3. Verify
    expect(goldManager.currentGold, 999);
  });
}

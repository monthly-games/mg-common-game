import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';

void main() {
  group('ProgressionManager', () {
    late ProgressionManager manager;

    setUp(() {
      manager = ProgressionManager();
    });

    test('초기 레벨 1', () {
      expect(manager.currentLevel, 1);
      expect(manager.currentXp, 0);
    });

    test('경험치 추가', () {
      manager.addXp(50);
      expect(manager.currentXp, 50);
    });

    test('음수 경험치 무시', () {
      manager.addXp(-10);
      expect(manager.currentXp, 0);
    });

    test('0 경험치 무시', () {
      manager.addXp(0);
      expect(manager.currentXp, 0);
    });

    test('레벨업', () {
      // xpToNextLevel = baseXp(100) * (level(1) * growthFactor(1.5)) = 150
      manager.addXp(150);
      expect(manager.currentLevel, 2);
    });

    test('레벨업 콜백', () {
      int? leveledUp;
      manager.onLevelUp = (level) => leveledUp = level;

      // Level 1 -> 2
      manager.addXp(150);
      expect(leveledUp, 2);
    });

    test('레벨업 시 경험치 이월', () {
      final xpToNext = manager.xpToNextLevel;
      manager.addXp(xpToNext + 50);

      expect(manager.currentLevel, 2);
      expect(manager.currentXp, 50);
    });

    test('다중 레벨업', () {
      // 큰 경험치로 여러 레벨업
      manager.addXp(10000);
      expect(manager.currentLevel, greaterThan(1));
    });

    test('setLevel', () {
      manager.setLevel(5, 100);
      expect(manager.currentLevel, 5);
      expect(manager.currentXp, 100);
    });

    test('리셋', () {
      manager.addXp(500);
      manager.reset();

      expect(manager.currentLevel, 1);
      expect(manager.currentXp, 0);
    });

    test('xpToNextLevel 계산', () {
      // Level 1: 100 * (1 * 1.5) = 150
      expect(manager.xpToNextLevel, 150);

      manager.setLevel(2, 0);
      // Level 2: 100 * (2 * 1.5) = 300
      expect(manager.xpToNextLevel, 300);
    });

    test('레벨별 경험치 증가', () {
      final level1Xp = manager.xpToNextLevel;
      manager.addXp(level1Xp);

      final level2Xp = manager.xpToNextLevel;
      expect(level2Xp, greaterThan(level1Xp));
    });

    test('toSaveData/fromSaveData', () {
      manager.addXp(200);

      final json = manager.toSaveData();
      expect(json['level'], manager.currentLevel);
      expect(json['xp'], manager.currentXp);

      final restored = ProgressionManager();
      restored.fromSaveData(json);

      expect(restored.currentLevel, manager.currentLevel);
      expect(restored.currentXp, manager.currentXp);
    });

    test('saveKey', () {
      expect(manager.saveKey, 'progression');
    });
  });
}

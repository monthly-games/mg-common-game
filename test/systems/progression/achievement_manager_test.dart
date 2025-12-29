import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

void main() {
  group('Achievement', () {
    test('기본 생성', () {
      final achievement = Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Defeat your first enemy',
        iconAsset: 'assets/icons/first_blood.png',
      );

      expect(achievement.id, 'first_blood');
      expect(achievement.title, 'First Blood');
      expect(achievement.unlocked, false);
    });

    test('숨김 업적', () {
      final hidden = Achievement(
        id: 'secret',
        title: 'Secret Achievement',
        description: 'Do something secret',
        iconAsset: 'assets/icons/secret.png',
        hidden: true,
      );

      expect(hidden.hidden, true);
    });

    test('해금/잠금', () {
      final achievement = Achievement(
        id: 'test',
        title: 'Test',
        description: 'Test achievement',
        iconAsset: 'assets/icons/test.png',
      );

      expect(achievement.unlocked, false);

      achievement.unlock();
      expect(achievement.unlocked, true);

      achievement.lock();
      expect(achievement.unlocked, false);
    });
  });

  group('AchievementManager', () {
    late AchievementManager manager;

    setUp(() {
      manager = AchievementManager();
    });

    test('업적 등록', () {
      manager.registerAchievement(Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Defeat your first enemy',
        iconAsset: 'assets/icons/first_blood.png',
      ));

      expect(manager.allAchievements.length, 1);
    });

    test('업적 해금', () {
      manager.registerAchievement(Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Defeat your first enemy',
        iconAsset: 'assets/icons/first_blood.png',
      ));

      expect(manager.isUnlocked('first_blood'), false);

      final unlocked = manager.unlock('first_blood');

      expect(unlocked, true);
      expect(manager.isUnlocked('first_blood'), true);
    });

    test('이미 해금된 업적 재해금 불가', () {
      manager.registerAchievement(Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Defeat your first enemy',
        iconAsset: 'assets/icons/first_blood.png',
      ));

      manager.unlock('first_blood');
      final secondUnlock = manager.unlock('first_blood');

      expect(secondUnlock, false); // 이미 해금됨
    });

    test('해금 콜백', () {
      Achievement? unlockedAchievement;
      manager.onAchievementUnlocked = (a) => unlockedAchievement = a;

      manager.registerAchievement(Achievement(
        id: 'first_blood',
        title: 'First Blood',
        description: 'Defeat your first enemy',
        iconAsset: 'assets/icons/first_blood.png',
      ));

      manager.unlock('first_blood');

      expect(unlockedAchievement, isNotNull);
      expect(unlockedAchievement!.id, 'first_blood');
    });

    test('해금된 업적 목록', () {
      manager.registerAchievement(Achievement(
        id: 'ach_1',
        title: 'Achievement 1',
        description: 'Description 1',
        iconAsset: 'assets/icons/ach1.png',
      ));

      manager.registerAchievement(Achievement(
        id: 'ach_2',
        title: 'Achievement 2',
        description: 'Description 2',
        iconAsset: 'assets/icons/ach2.png',
      ));

      manager.registerAchievement(Achievement(
        id: 'ach_3',
        title: 'Achievement 3',
        description: 'Description 3',
        iconAsset: 'assets/icons/ach3.png',
      ));

      manager.unlock('ach_1');
      manager.unlock('ach_3');

      expect(manager.unlockedAchievements.length, 2);
      expect(manager.unlockedCount, 2);
      expect(manager.totalCount, 3);
    });

    test('setUnlocked', () {
      manager.registerAchievement(Achievement(
        id: 'ach_1',
        title: 'Achievement 1',
        description: 'Description 1',
        iconAsset: 'assets/icons/ach1.png',
      ));

      manager.setUnlocked('ach_1', true);
      expect(manager.isUnlocked('ach_1'), true);

      manager.setUnlocked('ach_1', false);
      expect(manager.isUnlocked('ach_1'), false);
    });

    test('toSaveData/fromSaveData', () {
      manager.registerAchievement(Achievement(
        id: 'ach_1',
        title: 'Achievement 1',
        description: 'Description 1',
        iconAsset: 'assets/icons/ach1.png',
      ));

      manager.registerAchievement(Achievement(
        id: 'ach_2',
        title: 'Achievement 2',
        description: 'Description 2',
        iconAsset: 'assets/icons/ach2.png',
      ));

      manager.unlock('ach_1');

      final json = manager.toSaveData();

      final newManager = AchievementManager();
      newManager.registerAchievement(Achievement(
        id: 'ach_1',
        title: 'Achievement 1',
        description: 'Description 1',
        iconAsset: 'assets/icons/ach1.png',
      ));
      newManager.registerAchievement(Achievement(
        id: 'ach_2',
        title: 'Achievement 2',
        description: 'Description 2',
        iconAsset: 'assets/icons/ach2.png',
      ));
      newManager.fromSaveData(json);

      expect(newManager.isUnlocked('ach_1'), true);
      expect(newManager.isUnlocked('ach_2'), false);
    });

    test('saveKey', () {
      expect(manager.saveKey, 'achievements');
    });
  });
}

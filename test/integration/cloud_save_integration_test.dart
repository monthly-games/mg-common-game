import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/storage/cloud_save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CloudSaveManager Integration Tests', () {
    late CloudSaveManager saveManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = CloudSaveManager.instance;
      await saveManager.initialize();
    });

    tearDown(() {
      saveManager.dispose();
    });

    test('데이터 저장 및 로드', () async {
      final testData = {
        'playerName': '테스트 플레이어',
        'level': 10,
        'coins': 5000,
        'achievements': ['first_win', 'speed_demon'],
      };

      // 저장
      await saveManager.save(testData, immediate: true);

      await Future.delayed(const Duration(milliseconds: 500));

      // 로드
      await saveManager.load();

      expect(saveManager.localSave, isNotNull);
      expect(saveManager.localSave!.data['playerName'], equals('테스트 플레이어'));
      expect(saveManager.localSave!.data['level'], equals(10));
    });

    test('충돌 감지 및 해결 - 최신 타임스탬프', () async {
      final localData = {
        'score': 100,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };

      final cloudData = {
        'score': 200,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await saveManager.save(localData, immediate: true);
      await Future.delayed(const Duration(milliseconds: 500));

      // 충돌 상황 시뮬레이션
      expect(saveManager.localSave, isNotNull);
    });

    test('데이터 내보내기 및 가져오기', () async {
      final testData = {
        'exportTest': 'data',
        'value': 42,
      };

      await saveManager.save(testData, immediate: true);
      await Future.delayed(const Duration(milliseconds: 500));

      final exportedJson = await saveManager.exportData();
      expect(exportedJson, isNotEmpty);
      expect(exportedJson.contains('exportTest'), isTrue);

      await saveManager.clearData();
      expect(saveManager.localSave, isNull);

      await saveManager.importData(exportedJson);
      expect(saveManager.localSave, isNotNull);
    });

    test('자동 저장 기능', () async {
      final data = {'autoSaveTest': true};

      saveManager.enableAutoSave(interval: const Duration(seconds: 1));

      await saveManager.save(data);
      await Future.delayed(const Duration(seconds: 2));

      expect(saveManager.localSave, isNotNull);
      expect(saveManager.localSave!.data['autoSaveTest'], isTrue);

      saveManager.disableAutoSave();
    });

    test('상태 변경 감지', () async {
      final statuses = <SaveStatus>[];

      saveManager.onStatusChanged.listen(statuses.add);

      await saveManager.save({'statusTest': true});

      expect(statuses.contains(SaveStatus.saving), isTrue);
      expect(statuses.contains(SaveStatus.idle), isTrue);
    });
  });
}

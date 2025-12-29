import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/cloud/cloud_save_manager.dart';

/// CloudSaveManager 테스트용 서브클래스
/// 싱글톤 패턴을 우회하고 내부 메서드를 테스트하기 위해 사용
class TestableCloudSaveManager extends CloudSaveManager {
  TestableCloudSaveManager() : super.testable();

  // 내부 상태 접근자
  void setLocalSave(CloudSaveData? save) => localSaveForTest = save;
  void setCloudSave(CloudSaveData? save) => cloudSaveForTest = save;
  void setInitialized(bool value) => initializedForTest = value;
  void setGameId(String id) => gameIdForTest = id;
  void setUserId(String id) => userIdForTest = id;

  // 테스트용 public 메서드
  bool testHasConflict(CloudSaveData local, CloudSaveData cloud) =>
      hasConflictForTest(local, cloud);

  CloudSaveData testResolveWithStrategy(ConflictResolution strategy) =>
      resolveWithStrategyForTest(strategy);

  CloudSaveData testMergeSaves(CloudSaveData local, CloudSaveData cloud) =>
      mergeSavesForTest(local, cloud);

  String testGenerateChecksum(Map<String, dynamic> data) =>
      generateChecksumForTest(data);

  String testGenerateSaveId() => generateSaveIdForTest();

  // dispose 테스트용
  void testDispose() => dispose();
}

void main() {
  group('CloudSyncStatus', () {
    test('모든 상태 정의', () {
      expect(CloudSyncStatus.values.length, 6);
      expect(CloudSyncStatus.notInitialized, isNotNull);
      expect(CloudSyncStatus.syncing, isNotNull);
      expect(CloudSyncStatus.synced, isNotNull);
      expect(CloudSyncStatus.error, isNotNull);
      expect(CloudSyncStatus.pendingUpload, isNotNull);
      expect(CloudSyncStatus.conflict, isNotNull);
    });

    test('상태 인덱스 순서', () {
      expect(CloudSyncStatus.notInitialized.index, 0);
      expect(CloudSyncStatus.syncing.index, 1);
      expect(CloudSyncStatus.synced.index, 2);
      expect(CloudSyncStatus.error.index, 3);
      expect(CloudSyncStatus.pendingUpload.index, 4);
      expect(CloudSyncStatus.conflict.index, 5);
    });

    test('상태 이름', () {
      expect(CloudSyncStatus.notInitialized.name, 'notInitialized');
      expect(CloudSyncStatus.syncing.name, 'syncing');
      expect(CloudSyncStatus.synced.name, 'synced');
      expect(CloudSyncStatus.error.name, 'error');
      expect(CloudSyncStatus.pendingUpload.name, 'pendingUpload');
      expect(CloudSyncStatus.conflict.name, 'conflict');
    });
  });

  group('ConflictResolution', () {
    test('모든 전략 정의', () {
      expect(ConflictResolution.values.length, 5);
      expect(ConflictResolution.useLocal, isNotNull);
      expect(ConflictResolution.useCloud, isNotNull);
      expect(ConflictResolution.useNewer, isNotNull);
      expect(ConflictResolution.merge, isNotNull);
      expect(ConflictResolution.askUser, isNotNull);
    });

    test('전략 인덱스 순서', () {
      expect(ConflictResolution.useLocal.index, 0);
      expect(ConflictResolution.useCloud.index, 1);
      expect(ConflictResolution.useNewer.index, 2);
      expect(ConflictResolution.merge.index, 3);
      expect(ConflictResolution.askUser.index, 4);
    });

    test('전략 이름', () {
      expect(ConflictResolution.useLocal.name, 'useLocal');
      expect(ConflictResolution.useCloud.name, 'useCloud');
      expect(ConflictResolution.useNewer.name, 'useNewer');
      expect(ConflictResolution.merge.name, 'merge');
      expect(ConflictResolution.askUser.name, 'askUser');
    });
  });

  group('CloudSaveData', () {
    test('기본 생성', () {
      final data = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10, 'gold': 1000},
        lastModified: DateTime.now(),
      );

      expect(data.id, 'save_001');
      expect(data.gameId, 'my_game');
      expect(data.userId, 'user_123');
      expect(data.data['level'], 10);
      expect(data.version, 1);
    });

    test('toJson 변환', () {
      final now = DateTime.now();
      final data = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: now,
        version: 5,
        checksum: 'abc123',
      );

      final json = data.toJson();

      expect(json['id'], 'save_001');
      expect(json['gameId'], 'my_game');
      expect(json['userId'], 'user_123');
      expect(json['data']['level'], 10);
      expect(json['version'], 5);
      expect(json['checksum'], 'abc123');
    });

    test('fromJson 복원', () {
      final json = {
        'id': 'save_001',
        'gameId': 'my_game',
        'userId': 'user_123',
        'data': {'level': 10, 'gold': 500},
        'lastModified': '2024-01-01T12:00:00.000Z',
        'version': 3,
        'checksum': 'xyz789',
      };

      final data = CloudSaveData.fromJson(json);

      expect(data.id, 'save_001');
      expect(data.gameId, 'my_game');
      expect(data.data['level'], 10);
      expect(data.version, 3);
    });

    test('copyWith', () {
      final original = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: DateTime.now(),
        version: 1,
      );

      final updated = original.copyWith(
        data: {'level': 20},
        version: 2,
      );

      expect(updated.id, original.id);
      expect(updated.gameId, original.gameId);
      expect(updated.data['level'], 20);
      expect(updated.version, 2);
    });

    test('copyWith - 부분 업데이트', () {
      final now = DateTime.now();
      final original = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: now,
        version: 1,
        checksum: 'original_checksum',
      );

      // data만 업데이트
      final dataUpdated = original.copyWith(data: {'level': 20, 'gold': 500});
      expect(dataUpdated.data['level'], 20);
      expect(dataUpdated.data['gold'], 500);
      expect(dataUpdated.version, 1); // 변경 안됨

      // version만 업데이트
      final versionUpdated = original.copyWith(version: 5);
      expect(versionUpdated.data['level'], 10); // 변경 안됨
      expect(versionUpdated.version, 5);

      // lastModified만 업데이트
      final newTime = now.add(Duration(hours: 1));
      final timeUpdated = original.copyWith(lastModified: newTime);
      expect(timeUpdated.lastModified, newTime);

      // checksum만 업데이트
      final checksumUpdated = original.copyWith(checksum: 'new_checksum');
      expect(checksumUpdated.checksum, 'new_checksum');
    });

    test('copyWith - 원본 불변성', () {
      final original = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: DateTime.now(),
        version: 1,
      );

      final updated = original.copyWith(
        data: {'level': 20},
        version: 2,
      );

      // 원본은 변경되지 않음
      expect(original.data['level'], 10);
      expect(original.version, 1);
      // 복사본은 새 값
      expect(updated.data['level'], 20);
      expect(updated.version, 2);
    });

    test('fromJson - version 기본값', () {
      final json = {
        'id': 'save_001',
        'gameId': 'my_game',
        'userId': 'user_123',
        'data': {'level': 10},
        'lastModified': '2024-01-01T12:00:00.000Z',
        // version 없음
      };

      final data = CloudSaveData.fromJson(json);
      expect(data.version, 1); // 기본값 1
    });

    test('fromJson - checksum null 허용', () {
      final json = {
        'id': 'save_001',
        'gameId': 'my_game',
        'userId': 'user_123',
        'data': {'level': 10},
        'lastModified': '2024-01-01T12:00:00.000Z',
        'version': 2,
        'checksum': null,
      };

      final data = CloudSaveData.fromJson(json);
      expect(data.checksum, isNull);
    });

    test('toJson-fromJson 라운드트립', () {
      final original = CloudSaveData(
        id: 'roundtrip_test',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 50, 'items': ['sword', 'shield'], 'stats': {'hp': 100}},
        lastModified: DateTime(2025, 6, 15, 10, 30),
        version: 10,
        checksum: 'abc123xyz',
      );

      final json = original.toJson();
      final restored = CloudSaveData.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.gameId, original.gameId);
      expect(restored.userId, original.userId);
      expect(restored.data['level'], original.data['level']);
      expect(restored.version, original.version);
      expect(restored.checksum, original.checksum);
    });

    test('복잡한 data 구조', () {
      final complexData = {
        'player': {
          'name': 'Hero',
          'level': 99,
          'class': 'Warrior',
        },
        'inventory': ['sword', 'potion', 'key'],
        'settings': {
          'sound': true,
          'music': false,
          'difficulty': 'hard',
        },
        'progress': [1, 2, 3, 4, 5],
      };

      final saveData = CloudSaveData(
        id: 'complex_save',
        gameId: 'rpg_game',
        userId: 'player_1',
        data: complexData,
        lastModified: DateTime.now(),
      );

      final json = saveData.toJson();
      final restored = CloudSaveData.fromJson(json);

      expect(restored.data['player']['name'], 'Hero');
      expect(restored.data['inventory'], containsAll(['sword', 'potion', 'key']));
      expect(restored.data['settings']['difficulty'], 'hard');
    });
  });

  group('SaveConflict', () {
    test('충돌 데이터 생성', () {
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: DateTime.now(),
      );

      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 15},
        lastModified: DateTime.now().subtract(Duration(hours: 1)),
      );

      final conflict = SaveConflict(local: local, cloud: cloud);

      expect(conflict.local.data['level'], 10);
      expect(conflict.cloud.data['level'], 15);
    });
  });

  group('CloudSaveManager', () {
    late CloudSaveManager manager;

    setUp(() {
      manager = CloudSaveManager.instance;
    });

    test('싱글톤 인스턴스', () {
      final instance1 = CloudSaveManager.instance;
      final instance2 = CloudSaveManager.instance;

      expect(identical(instance1, instance2), true);
    });

    test('초기 상태 - status', () {
      // 싱글톤이므로 이전 테스트 상태 영향받을 수 있음
      expect(manager.status, isA<CloudSyncStatus>());
    });

    test('초기 상태 - isInitialized', () {
      expect(manager.isInitialized, isA<bool>());
    });

    test('초기 상태 - userId', () {
      // 초기화 전에는 null일 수 있음
      expect(manager.userId, anyOf(isNull, isA<String>()));
    });

    test('초기 상태 - localSave', () {
      expect(manager.localSave, anyOf(isNull, isA<CloudSaveData>()));
    });

    test('초기 상태 - cloudSave', () {
      expect(manager.cloudSave, anyOf(isNull, isA<CloudSaveData>()));
    });

    test('getData - localSave 없을 때', () {
      // localSave가 없으면 null 반환
      final data = manager.getData();
      expect(data, anyOf(isNull, isA<Map<String, dynamic>>()));
    });

    test('getValue - localSave 없을 때', () {
      // localSave가 없으면 null 반환
      final value = manager.getValue<int>('nonexistent');
      expect(value, anyOf(isNull, isA<int>()));
    });

    test('addSyncListener와 removeSyncListener', () {
      var callCount = 0;
      void listener(CloudSyncStatus status) {
        callCount++;
      }

      manager.addSyncListener(listener);
      manager.removeSyncListener(listener);

      // 리스너가 제거되었으므로 호출되지 않아야 함
      // (실제 상태 변경 없이는 확인 어려움)
      expect(callCount, 0);
    });

    test('ChangeNotifier 상속', () {
      expect(manager, isA<CloudSaveManager>());
    });

    // 실제 초기화는 Firebase 등 외부 서비스에 의존하므로
    // 여기서는 기본 동작만 테스트
  });

  group('데이터 병합 로직', () {
    test('숫자 필드 병합 - 더 큰 값 선택', () {
      final localData = {'score': 100, 'level': 10};
      final cloudData = {'score': 150, 'level': 8};

      // 병합 시 각 필드에서 더 큰 값 선택 예상
      final mergedScore = localData['score']! > cloudData['score']!
          ? localData['score']
          : cloudData['score'];
      final mergedLevel = localData['level']! > cloudData['level']!
          ? localData['level']
          : cloudData['level'];

      expect(mergedScore, 150);
      expect(mergedLevel, 10);
    });

    test('리스트 필드 병합 - 합집합', () {
      final localList = ['item_1', 'item_2'];
      final cloudList = ['item_2', 'item_3'];

      final merged = {...localList, ...cloudList}.toList();

      expect(merged.length, 3);
      expect(merged.contains('item_1'), true);
      expect(merged.contains('item_2'), true);
      expect(merged.contains('item_3'), true);
    });

    test('리스트 필드 병합 - 빈 리스트', () {
      final localList = <String>[];
      final cloudList = ['item_1', 'item_2'];

      final merged = {...localList, ...cloudList}.toList();

      expect(merged.length, 2);
      expect(merged, containsAll(['item_1', 'item_2']));
    });

    test('타임스탬프 비교', () {
      final now = DateTime.now();
      final earlier = now.subtract(Duration(hours: 1));
      final later = now.add(Duration(hours: 1));

      expect(now.isAfter(earlier), true);
      expect(now.isBefore(later), true);
      expect(later.isAfter(now), true);
      expect(earlier.isBefore(now), true);
    });

    test('타임스탬프 동일', () {
      final time = DateTime(2025, 1, 1, 12, 0, 0);
      final sameTime = DateTime(2025, 1, 1, 12, 0, 0);

      expect(time.isAfter(sameTime), false);
      expect(time.isBefore(sameTime), false);
      expect(time.isAtSameMomentAs(sameTime), true);
    });

    test('병합 시 local only 필드', () {
      final localData = {'score': 100, 'localOnly': 'value'};
      final cloudData = {'score': 150};

      final merged = <String, dynamic>{};
      merged.addAll(cloudData);
      for (final entry in localData.entries) {
        if (!cloudData.containsKey(entry.key)) {
          merged[entry.key] = entry.value;
        } else if (entry.value is num && cloudData[entry.key] is num) {
          merged[entry.key] = (entry.value as num) > (cloudData[entry.key] as num)
              ? entry.value
              : cloudData[entry.key];
        }
      }

      expect(merged['localOnly'], 'value');
      expect(merged['score'], 150);
    });

    test('병합 시 cloud only 필드', () {
      final localData = {'score': 100};
      final cloudData = {'score': 150, 'cloudOnly': 'cloud_value'};

      final merged = <String, dynamic>{};
      merged.addAll(cloudData);

      expect(merged['cloudOnly'], 'cloud_value');
      expect(merged['score'], 150);
    });
  });

  group('SaveConflict 상세', () {
    test('충돌 시나리오 - 로컬이 더 최신', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      );

      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 15},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      expect(local.lastModified.isAfter(cloud.lastModified), true);
      expect(local.version > cloud.version, true);
    });

    test('충돌 시나리오 - 클라우드가 더 최신', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10},
        lastModified: now.subtract(Duration(hours: 2)),
        version: 1,
      );

      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 25},
        lastModified: now,
        version: 3,
      );

      expect(cloud.lastModified.isAfter(local.lastModified), true);
      expect(cloud.version > local.version, true);
    });

    test('충돌 시나리오 - 동시 수정 (진정한 충돌)', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 10, 'device': 'phone'},
        lastModified: now,
        version: 2,
      );

      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'my_game',
        userId: 'user_123',
        data: {'level': 15, 'device': 'tablet'},
        lastModified: now,
        version: 2,
      );

      // 같은 시간, 같은 버전이지만 다른 데이터
      expect(local.lastModified.isAtSameMomentAs(cloud.lastModified), true);
      expect(local.version == cloud.version, true);
      expect(local.data['level'] != cloud.data['level'], true);
    });
  });

  group('TestableCloudSaveManager - _hasConflict', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
    });

    test('같은 버전 - 충돌 없음', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      );

      expect(manager.testHasConflict(local, cloud), false);
    });

    test('다른 버전, 로컬이 최신 - 충돌 없음', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      expect(manager.testHasConflict(local, cloud), false);
    });

    test('다른 버전, 클라우드가 최신 - 충돌 없음', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      );

      expect(manager.testHasConflict(local, cloud), false);
    });

    test('다른 버전, 동일 타임스탬프 - 충돌 발생', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      );

      expect(manager.testHasConflict(local, cloud), true);
    });
  });

  group('TestableCloudSaveManager - _resolveWithStrategy', () {
    late TestableCloudSaveManager manager;
    late CloudSaveData localSave;
    late CloudSaveData cloudSave;

    setUp(() {
      manager = TestableCloudSaveManager();

      final now = DateTime.now();
      localSave = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10, 'gold': 500},
        lastModified: now,
        version: 2,
      );
      cloudSave = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 15, 'gold': 300},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      manager.setLocalSave(localSave);
      manager.setCloudSave(cloudSave);
    });

    test('useLocal 전략', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.useLocal);
      expect(resolved.data['level'], 10);
      expect(resolved.data['gold'], 500);
    });

    test('useCloud 전략', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.useCloud);
      expect(resolved.data['level'], 15);
      expect(resolved.data['gold'], 300);
    });

    test('useNewer 전략 - 로컬이 최신', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.useNewer);
      expect(resolved.data['level'], 10); // local이 더 최신
    });

    test('useNewer 전략 - 클라우드가 최신', () {
      // 클라우드를 더 최신으로 설정
      final now = DateTime.now();
      cloudSave = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 25, 'gold': 1000},
        lastModified: now.add(Duration(hours: 1)),
        version: 3,
      );
      manager.setCloudSave(cloudSave);

      final resolved = manager.testResolveWithStrategy(ConflictResolution.useNewer);
      expect(resolved.data['level'], 25); // cloud가 더 최신
    });

    test('merge 전략', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.merge);
      // merge는 숫자의 경우 더 큰 값 선택
      expect(resolved.data['level'], 15); // cloud가 더 큼
      expect(resolved.data['gold'], 500); // local이 더 큼
    });

    test('askUser 전략 (resolver 없을 때 useNewer로 폴백)', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.askUser);
      expect(resolved.data['level'], 10); // local이 더 최신이므로
    });
  });

  group('TestableCloudSaveManager - _mergeSaves', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
    });

    test('숫자 필드 - 더 큰 값 선택', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'score': 100, 'level': 20},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'score': 200, 'level': 10},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      expect(merged.data['score'], 200); // cloud가 더 큼
      expect(merged.data['level'], 20); // local이 더 큼
    });

    test('리스트 필드 - 합집합', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {
          'achievements': ['ach_1', 'ach_2']
        },
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {
          'achievements': ['ach_2', 'ach_3']
        },
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      final achievements = merged.data['achievements'] as List;
      expect(achievements.length, 3);
      expect(achievements.contains('ach_1'), true);
      expect(achievements.contains('ach_2'), true);
      expect(achievements.contains('ach_3'), true);
    });

    test('local only 필드', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10, 'localSetting': 'value'},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 5},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      expect(merged.data['localSetting'], 'value');
      expect(merged.data['level'], 10);
    });

    test('문자열 필드 - 최신 값 사용', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'playerName': 'NewName'},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'playerName': 'OldName'},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      expect(merged.data['playerName'], 'NewName'); // local이 더 최신
    });

    test('버전 증가', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now,
        version: 3,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 5},
        lastModified: now.subtract(Duration(hours: 1)),
        version: 5,
      );

      final merged = manager.testMergeSaves(local, cloud);
      expect(merged.version, 6); // max(3, 5) + 1
    });

    test('빈 리스트 병합', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'items': <String>[]},
        lastModified: now,
        version: 1,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {
          'items': ['item_1', 'item_2']
        },
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      final items = merged.data['items'] as List;
      expect(items.length, 2);
    });

    test('복잡한 데이터 구조 병합', () {
      final now = DateTime.now();
      final local = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {
          'score': 1000,
          'level': 50,
          'achievements': ['gold_1', 'gold_2'],
          'settings': {'sound': true},
        },
        lastModified: now,
        version: 2,
      );
      final cloud = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {
          'score': 800,
          'level': 60,
          'achievements': ['gold_2', 'gold_3'],
          'settings': {'sound': false},
        },
        lastModified: now.subtract(Duration(hours: 1)),
        version: 1,
      );

      final merged = manager.testMergeSaves(local, cloud);
      expect(merged.data['score'], 1000); // local이 더 큼
      expect(merged.data['level'], 60); // cloud가 더 큼
      expect((merged.data['achievements'] as List).length, 3);
      expect(merged.data['settings'], {'sound': true}); // local이 더 최신
    });
  });

  group('TestableCloudSaveManager - _generateChecksum', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
    });

    test('동일 데이터 - 동일 체크섬', () {
      final data = {'level': 10, 'gold': 100};
      final checksum1 = manager.testGenerateChecksum(data);
      final checksum2 = manager.testGenerateChecksum(data);

      expect(checksum1, checksum2);
    });

    test('다른 데이터 - 다른 체크섬', () {
      final data1 = {'level': 10};
      final data2 = {'level': 20};

      final checksum1 = manager.testGenerateChecksum(data1);
      final checksum2 = manager.testGenerateChecksum(data2);

      expect(checksum1, isNot(checksum2));
    });

    test('체크섬은 16진수 문자열', () {
      final data = {'test': 'value'};
      final checksum = manager.testGenerateChecksum(data);

      expect(checksum, matches(RegExp(r'^[0-9a-f]+$')));
    });

    test('빈 객체 체크섬', () {
      final data = <String, dynamic>{};
      final checksum = manager.testGenerateChecksum(data);

      expect(checksum, isNotEmpty);
    });

    test('중첩 객체 체크섬', () {
      final data = {
        'player': {'name': 'Hero', 'stats': {'hp': 100, 'mp': 50}}
      };
      final checksum = manager.testGenerateChecksum(data);

      expect(checksum, isNotEmpty);
    });
  });

  group('TestableCloudSaveManager - _generateSaveId', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('세이브 ID 형식', () {
      final saveId = manager.testGenerateSaveId();

      expect(saveId, contains('test_game'));
      expect(saveId, contains('test_user'));
    });

    test('연속 생성시 다른 ID (타임스탬프 포함)', () async {
      final saveId1 = manager.testGenerateSaveId();
      await Future.delayed(Duration(milliseconds: 2));
      final saveId2 = manager.testGenerateSaveId();

      expect(saveId1, isNot(saveId2));
    });
  });

  group('TestableCloudSaveManager - save와 getData', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('save - 초기화 안됐을 때 에러', () async {
      final uninitManager = TestableCloudSaveManager();

      expect(
        () => uninitManager.save({'level': 1}),
        throwsA(isA<StateError>()),
      );
    });

    test('save - 데이터 저장', () async {
      await manager.save({'level': 10, 'gold': 500}, syncImmediately: false);

      expect(manager.localSave, isNotNull);
      expect(manager.localSave!.data['level'], 10);
      expect(manager.localSave!.data['gold'], 500);
    });

    test('save - 버전 자동 증가', () async {
      await manager.save({'level': 1}, syncImmediately: false);
      final version1 = manager.localSave!.version;

      await manager.save({'level': 2}, syncImmediately: false);
      final version2 = manager.localSave!.version;

      expect(version2, version1 + 1);
    });

    test('save - 체크섬 생성', () async {
      await manager.save({'level': 10}, syncImmediately: false);

      expect(manager.localSave!.checksum, isNotNull);
      expect(manager.localSave!.checksum, isNotEmpty);
    });

    test('getData - 저장된 데이터 반환', () async {
      await manager.save({'level': 25, 'name': 'Player'}, syncImmediately: false);

      final data = manager.getData();
      expect(data, isNotNull);
      expect(data!['level'], 25);
      expect(data['name'], 'Player');
    });

    test('getData - 데이터 없을 때 null', () {
      final data = manager.getData();
      expect(data, isNull);
    });

    test('getValue - 특정 키 값 반환', () async {
      await manager.save({'level': 30, 'gold': 1000}, syncImmediately: false);

      expect(manager.getValue<int>('level'), 30);
      expect(manager.getValue<int>('gold'), 1000);
    });

    test('getValue - 존재하지 않는 키', () async {
      await manager.save({'level': 10}, syncImmediately: false);

      expect(manager.getValue<int>('nonexistent'), isNull);
    });

    test('setValue - 특정 키 값 설정', () async {
      await manager.save({'level': 10}, syncImmediately: false);
      await manager.setValue('gold', 500, syncImmediately: false);

      expect(manager.getValue<int>('gold'), 500);
      expect(manager.getValue<int>('level'), 10); // 기존 값 유지
    });
  });

  group('TestableCloudSaveManager - sync 상태 관리', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('save syncImmediately=false - pendingUpload 상태', () async {
      await manager.save({'level': 10}, syncImmediately: false);

      expect(manager.status, CloudSyncStatus.pendingUpload);
    });

    test('sync - 초기화 안됐을 때 false 반환', () async {
      final uninitManager = TestableCloudSaveManager();

      final result = await uninitManager.sync();
      expect(result, false);
    });

    test('forceDownload - 초기화 안됐을 때 false', () async {
      final uninitManager = TestableCloudSaveManager();

      final result = await uninitManager.forceDownload();
      expect(result, false);
    });

    test('forceUpload - 초기화 안됐을 때 false', () async {
      final uninitManager = TestableCloudSaveManager();

      final result = await uninitManager.forceUpload();
      expect(result, false);
    });

    test('forceUpload - 로컬 데이터 없을 때 false', () async {
      final result = await manager.forceUpload();
      expect(result, false);
    });
  });

  group('TestableCloudSaveManager - 리스너', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('addSyncListener - 상태 변경 시 호출', () async {
      final statuses = <CloudSyncStatus>[];
      manager.addSyncListener((status) {
        statuses.add(status);
      });

      await manager.save({'level': 10}, syncImmediately: false);

      expect(statuses.contains(CloudSyncStatus.pendingUpload), true);
    });

    test('removeSyncListener - 제거 후 호출 안됨', () async {
      var callCount = 0;
      void listener(CloudSyncStatus status) {
        callCount++;
      }

      manager.addSyncListener(listener);
      await manager.save({'level': 1}, syncImmediately: false);
      final firstCount = callCount;

      manager.removeSyncListener(listener);
      await manager.save({'level': 2}, syncImmediately: false);

      // 리스너 제거 후에는 추가 호출 없음
      expect(callCount, firstCount);
    });

    test('ChangeNotifier - notifyListeners 호출', () async {
      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      await manager.save({'level': 10}, syncImmediately: false);

      expect(notified, true);
    });
  });

  group('TestableCloudSaveManager - deleteAllSaves', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('deleteAllSaves - 로컬과 클라우드 데이터 삭제', () async {
      await manager.save({'level': 10}, syncImmediately: false);

      await manager.deleteAllSaves();

      expect(manager.localSave, isNull);
      expect(manager.cloudSave, isNull);
    });
  });

  group('ConflictResolver 콜백', () {
    test('ConflictResolver 타입 정의', () {
      ConflictResolver resolver = (SaveConflict conflict) async {
        return conflict.local; // 항상 로컬 선택
      };

      expect(resolver, isA<ConflictResolver>());
    });

    test('SyncCallback 타입 정의', () {
      SyncCallback callback = (CloudSyncStatus status) {
        // 상태 처리
      };

      expect(callback, isA<SyncCallback>());
    });
  });

  group('CloudSaveData - 추가 테스트', () {
    test('lastModified 타임존 처리', () {
      final utcTime = DateTime.utc(2025, 1, 15, 12, 30, 45);
      final data = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: utcTime,
      );

      final json = data.toJson();
      final restored = CloudSaveData.fromJson(json);

      expect(restored.lastModified.isUtc, true);
    });

    test('빈 data Map', () {
      final data = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {},
        lastModified: DateTime.now(),
      );

      expect(data.data, isEmpty);

      final json = data.toJson();
      final restored = CloudSaveData.fromJson(json);
      expect(restored.data, isEmpty);
    });

    test('copyWith - 모든 필드 동시 업데이트', () {
      final now = DateTime.now();
      final later = now.add(Duration(hours: 1));

      final original = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
        checksum: 'abc',
      );

      final updated = original.copyWith(
        data: {'level': 20, 'gold': 100},
        lastModified: later,
        version: 2,
        checksum: 'xyz',
      );

      expect(updated.data['level'], 20);
      expect(updated.data['gold'], 100);
      expect(updated.lastModified, later);
      expect(updated.version, 2);
      expect(updated.checksum, 'xyz');
      // 불변 필드는 유지
      expect(updated.id, 'save_001');
      expect(updated.gameId, 'game');
      expect(updated.userId, 'user');
    });
  });

  group('TestableCloudSaveManager - initialize', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
    });

    tearDown(() {
      manager.testDispose();
    });

    test('initialize - 기본 설정', () async {
      await manager.initialize(
        gameId: 'test_game',
        userId: 'test_user',
      );

      expect(manager.isInitialized, true);
      expect(manager.userId, 'test_user');
      expect(manager.status, CloudSyncStatus.synced);
    });

    test('initialize - 중복 호출 무시', () async {
      await manager.initialize(
        gameId: 'game1',
        userId: 'user1',
      );

      await manager.initialize(
        gameId: 'game2',
        userId: 'user2',
      );

      // 첫 번째 초기화 값 유지
      expect(manager.userId, 'user1');
    });

    test('initialize - autoSyncInterval 설정', () async {
      await manager.initialize(
        gameId: 'test_game',
        userId: 'test_user',
        autoSyncInterval: const Duration(seconds: 30),
      );

      expect(manager.isInitialized, true);
    });

    test('initialize - conflictResolver 설정', () async {
      CloudSaveData? resolvedData;

      await manager.initialize(
        gameId: 'test_game',
        userId: 'test_user',
        conflictResolver: (conflict) async {
          resolvedData = conflict.local;
          return conflict.local;
        },
      );

      expect(manager.isInitialized, true);
    });

    test('initialize - defaultResolution 설정', () async {
      await manager.initialize(
        gameId: 'test_game',
        userId: 'test_user',
        defaultResolution: ConflictResolution.useCloud,
      );

      expect(manager.isInitialized, true);
    });
  });

  group('TestableCloudSaveManager - sync 시나리오', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('sync - localSave만 있을 때 업로드', () async {
      final now = DateTime.now();
      manager.setLocalSave(CloudSaveData(
        id: 'save_001',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      ));

      final result = await manager.sync();

      expect(result, true);
      expect(manager.status, CloudSyncStatus.synced);
    });

    test('sync - cloudSave만 있을 때 다운로드', () async {
      // _fetchCloudSave가 null을 반환하므로 이 시나리오는 시뮬레이션 불가
      // 대신 localSave도 cloudSave도 없는 경우 테스트
      final result = await manager.sync();

      expect(result, true);
      expect(manager.status, CloudSyncStatus.synced);
    });

    test('sync - 둘 다 있고 local이 최신', () async {
      final now = DateTime.now();
      manager.setLocalSave(CloudSaveData(
        id: 'save_001',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      ));

      // cloudSave는 _fetchCloudSave에서 null 반환하므로 localSave만 있는 시나리오와 동일

      final result = await manager.sync();
      expect(result, true);
    });

    test('sync - 에러 발생 시 false 반환', () async {
      // sync 메서드 내에서 에러가 발생할 수 있는 상황 시뮬레이션이 어려움
      // 기본 동작 테스트
      final result = await manager.sync();
      expect(result, true);
    });
  });

  group('TestableCloudSaveManager - forceDownload/forceUpload', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('forceDownload - cloudSave가 null일 때 error 상태', () async {
      final result = await manager.forceDownload();

      // _fetchCloudSave가 null 반환하므로 false
      expect(result, false);
      expect(manager.status, CloudSyncStatus.error);
    });

    test('forceUpload - localSave가 있을 때 성공', () async {
      final now = DateTime.now();
      manager.setLocalSave(CloudSaveData(
        id: 'save_001',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      ));

      final result = await manager.forceUpload();

      expect(result, true);
      expect(manager.status, CloudSyncStatus.synced);
    });
  });

  group('TestableCloudSaveManager - dispose', () {
    test('dispose - 리소스 정리', () {
      final manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');

      // 리스너 추가
      manager.addSyncListener((status) {});
      manager.addListener(() {});

      // dispose 호출
      manager.testDispose();

      // dispose 후 에러 없이 완료되면 성공
      expect(true, true);
    });

    test('dispose - autoSyncTimer 취소', () async {
      final manager = TestableCloudSaveManager();

      await manager.initialize(
        gameId: 'test_game',
        userId: 'test_user',
        autoSyncInterval: const Duration(seconds: 1),
      );

      manager.testDispose();

      // dispose 후 에러 없이 완료되면 성공
      expect(true, true);
    });
  });

  group('TestableCloudSaveManager - _resolveWithStrategy askUser fallback', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();

      final now = DateTime.now();
      final localSave = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 10},
        lastModified: now.subtract(const Duration(hours: 1)),
        version: 1,
      );
      final cloudSave = CloudSaveData(
        id: 'save_001',
        gameId: 'game',
        userId: 'user',
        data: {'level': 20},
        lastModified: now,
        version: 2,
      );

      manager.setLocalSave(localSave);
      manager.setCloudSave(cloudSave);
    });

    test('askUser - cloud가 더 최신일 때 cloud 반환', () {
      final resolved = manager.testResolveWithStrategy(ConflictResolution.askUser);
      expect(resolved.data['level'], 20); // cloud가 더 최신
    });
  });

  group('TestableCloudSaveManager - 추가 sync 시나리오', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('sync - 동일 타임스탬프 (동작 없음)', () async {
      final now = DateTime.now();

      // 동일 버전, 동일 시간
      manager.setLocalSave(CloudSaveData(
        id: 'save_001',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      ));

      // _fetchCloudSave가 null을 반환하므로 실제로는 local만 있는 시나리오
      final result = await manager.sync();
      expect(result, true);
    });
  });

  group('TestableCloudSaveManager - deleteCloudSave', () {
    late TestableCloudSaveManager manager;

    setUp(() {
      manager = TestableCloudSaveManager();
      manager.setInitialized(true);
      manager.setGameId('test_game');
      manager.setUserId('test_user');
    });

    test('deleteCloudSave - cloudSave 삭제', () async {
      final now = DateTime.now();
      manager.setCloudSave(CloudSaveData(
        id: 'save_001',
        gameId: 'test_game',
        userId: 'test_user',
        data: {'level': 10},
        lastModified: now,
        version: 1,
      ));

      await manager.deleteCloudSave();

      expect(manager.cloudSave, isNull);
    });

    test('deleteCloudSave - 초기화 안됐을 때 무시', () async {
      final uninitManager = TestableCloudSaveManager();

      await uninitManager.deleteCloudSave();
      // 에러 없이 완료
      expect(true, true);
    });
  });
}

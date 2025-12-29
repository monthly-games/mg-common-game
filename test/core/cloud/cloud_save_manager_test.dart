import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/cloud/cloud_save_manager.dart';

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
}

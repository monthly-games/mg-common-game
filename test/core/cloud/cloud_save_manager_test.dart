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

    test('초기 상태', () {
      // 초기화 전 상태 확인
      expect(manager.status, CloudSyncStatus.notInitialized);
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

      expect(mergedScore, 150);
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

    test('타임스탬프 비교', () {
      final now = DateTime.now();
      final earlier = now.subtract(Duration(hours: 1));
      final later = now.add(Duration(hours: 1));

      expect(now.isAfter(earlier), true);
      expect(now.isBefore(later), true);
    });
  });
}

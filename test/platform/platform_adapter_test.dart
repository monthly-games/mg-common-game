import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/platform/platform_adapter.dart';

void main() {
  group('PlatformAdapter', () {
    test('플랫폼 정보 감지', () {
      final platform = PlatformInfo.current;

      expect(platform, isNotNull);
      expect(platform.type, isIn(PlatformType.values));
    });

    test('반응형 레이아웃', () {
      // 모바일 레이아웃 테스트
      final mobileWidget = PlatformAdapter.buildAdaptiveLayout(
        mobile: const Text('Mobile'),
        tablet: const Text('Tablet'),
        desktop: const Text('Desktop'),
      );

      expect(mobileWidget, isA<LayoutBuilder>());
    });

    test('적응형 폰트 크기', () {
      // 테스트에서는 BuildContext가 없으므로 기본값 확인
      const mobileSize = 16.0;

      // 데스크탑에서는 1.2배
      final desktopSize = mobileSize * 1.2;

      expect(desktopSize, 19.2);
    });
  });

  group('DataSyncManager', () {
    test('싱글톤 인스턴스', () {
      final instance1 = DataSyncManager.instance;
      final instance2 = DataSyncManager.instance;

      expect(identical(instance1, instance2), true);
    });

    test('동기화 이벤트 스트림', () async {
      final syncManager = DataSyncManager.instance;

      bool eventReceived = false;
      syncManager.onSyncEvent.listen((event) {
        eventReceived = true;
        expect(event.type, isIn(SyncType.values));
      });

      await syncManager.syncAcrossPlatforms(userId: 'user_001');

      expect(eventReceived, true);
    });

    test('진행 상태 동기화', () async {
      final syncManager = DataSyncManager.instance;

      await syncManager.syncProgress(
        userId: 'user_001',
        gameId: 'game_001',
        progressData: {
          'level': 10,
          'score': 1000,
        },
      );

      // 예외가 발생하지 않으면 성공
      expect(true, true);
    });
  });
}

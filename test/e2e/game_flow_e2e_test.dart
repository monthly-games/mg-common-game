import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('게임 플레이 E2E 테스트', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('게임 시작 및 플레이 흐름', () async {
      // 게임 시작 버튼 찾기
      final startButton = find.byValueKey('start_game_button');
      await driver.waitFor(startButton);
      await driver.tap(startButton);

      // 게임 화면 로딩 대기
      final gameScreen = find.byValueKey('game_screen');
      await driver.waitFor(gameScreen);

      // 스코어 확인
      final scoreText = find.byValueKey('score_text');
      expect(await driver.getText(scoreText), '0');

      // 게임 플레이 시뮬레이션 (터치 이벤트)
      final gameArea = find.byValueKey('game_area');
      await driver.tap(gameArea);

      await Future.delayed(const Duration(seconds: 1));

      // 스코어 증가 확인
      final newScore = await driver.getText(scoreText);
      expect(int.parse(newScore), greaterThan(0));

      // 게임 종료
      final pauseButton = find.byValueKey('pause_button');
      await driver.tap(pauseButton);

      final endGameButton = find.byValueKey('end_game_button');
      await driver.tap(endGameButton);

      // 결과 화면 확인
      final resultScreen = find.byValueKey('result_screen');
      await driver.waitFor(resultScreen);
    });

    test('퀘스트 완료 흐름', () async {
      // 퀘스트 화면 이동
      final questTab = find.text('퀘스트');
      await driver.tap(questTab);

      // 일일 퀘스트 확인
      final dailyQuest = find.byValueKey('daily_quest_card');
      await driver.waitFor(dailyQuest);

      // 퀘스트 상세보기
      await driver.tap(dailyQuest);

      final questDetail = find.byValueKey('quest_detail');
      await driver.waitFor(questDetail);

      // 퀘스트 수락
      final acceptButton = find.text('퀘스트 수락');
      await driver.tap(acceptButton);

      // 수락 확인 메시지
      final successMessage = find.text('퀘스트를 수락했습니다');
      await driver.waitFor(successMessage);
    });

    test('상점 구매 흐름', () async {
      // 상점 탭
      final shopTab = find.text('상점');
      await driver.tap(shopTab);

      // 아이템 선택
      final firstItem = find.byValueKey('shop_item_0');
      await driver.waitFor(firstItem);
      await driver.tap(firstItem);

      // 구매 확인 다이얼로그
      final confirmDialog = find.byValueKey('purchase_confirm_dialog');
      await driver.waitFor(confirmDialog);

      // 구매 버튼
      final purchaseButton = find.text('구매');
      await driver.tap(purchaseButton);

      // 구매 성공 메시지
      final successToast = find.text('구매 완료');
      await driver.waitFor(successToast);
    });

    test('설정 변경 흐름', () async {
      // 설정 화면 이동
      final settingsButton = find.byValueKey('settings_button');
      await driver.tap(settingsButton);

      // 볼륨 조절
      final volumeSlider = find.byValueKey('volume_slider');
      await driver.tap(volumeSlider);

      // 다크 모드 토글
      final darkModeToggle = find.byValueKey('dark_mode_toggle');
      await driver.tap(darkModeToggle);

      // 변경사항 저장
      final saveButton = find.text('저장');
      await driver.tap(saveButton);

      // 설정 화면 닫기
      final backButton = find.byValueKey('back_button');
      await driver.tap(backButton);
    });
  });

  group('성능 E2E 테스트', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('프레임 레이트 모니터링', () async {
      final timeline = await driver.traceAction(() async {
        // 게임 플레이 시뮬레이션
        final gameArea = find.byValueKey('game_area');

        for (int i = 0; i < 10; i++) {
          await driver.tap(gameArea);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      });

      // 평균 FPS 계산
      final frameCount = timeline.frames.length;
      final duration = timeline.duration.inMilliseconds;
      final fps = (frameCount / duration * 1000);

      expect(fps, greaterThan(55)); // 55 FPS 이상 유지
    });

    test('메모리 사용량 모니터링', () async {
      // 초기 메모리
      final initialMemory = await driver.getVmMetrics();

      // 게임 플레이
      for (int i = 0; i < 20; i++) {
        await driver.tap(find.byValueKey('game_area'));
      }

      await Future.delayed(const Duration(seconds: 2));

      // 가비지 컬렉션 유도
      await driver.requestData('gc');

      // 최종 메모리
      final finalMemory = await driver.getVmMetrics();

      // 메모리 누수 확인 (20% 이상 증가하지 않아야 함)
      final memoryIncrease = (finalMemory.heapUsage - initialMemory.heapUsage) /
                            initialMemory.heapUsage;

      expect(memoryIncrease, lessThan(0.2));
    });
  });

  group('네트워크 E2E 테스트', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('오프라인 상태 처리', () async {
      // 비행 모드 활성화 (시뮬레이터 설정 필요)
      await driver.requestData('set_airplane_mode:true');

      // 오프라인 메시지 확인
      final offlineMessage = find.text('네트워크 연결 없음');
      await driver.waitFor(offlineMessage);

      // 온라인 복구
      await driver.requestData('set_airplane_mode:false');

      // 재연결 메시지
      final reconnectMessage = find.text('재연결됨');
      await driver.waitFor(reconnectMessage);
    });
  });
}

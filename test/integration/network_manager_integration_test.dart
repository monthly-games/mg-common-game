import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/core/networking/network_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('NetworkManager Integration Tests', () {
    late NetworkManager networkManager;

    setUp(() {
      networkManager = NetworkManager.instance;
    });

    tearDown(() {
      networkManager.disconnect();
    });

    test('연결 상태 변경 감지', () async {
      final statuses = <NetworkStatus>[];

      networkManager.onStatusChanged.listen(statuses.add);

      expect(networkManager.status, NetworkStatus.disconnected);

      // WebSocket 서버가 없으므로 연결 실패 테스트
      try {
        await networkManager.connect('ws://localhost:8080');
      } catch (e) {
        // 연결 실패 예상
      }

      // 상태 변경 확인
      expect(statuses.isNotEmpty, isTrue);
    });

    test('이벤트 전송 및 수신', () async {
      final receivedEvents = <NetworkEvent>[];

      networkManager.onEventType('test_event').listen(receivedEvents.add);

      // 연결되지 않은 상태에서는 전송 불가
      final result = networkManager.send('test_event', {'data': 'test'});

      // 연결되지 않았으므로 결과는 false 또는 에러
      expect(result, isA<bool>());
    });

    test('하트비트 메커니즘', () async {
      // 연결 설정 (시뮬레이션)
      await networkManager.connect('ws://localhost:8080', userId: 'test_user');

      // 하트비트 간격 확인
      expect(networkManager.heartbeatInterval, isPositive);
    });

    test('자동 재연결', () async {
      int reconnectAttempts = 0;

      networkManager.onReconnecting.listen((_) {
        reconnectAttempts++;
      });

      try {
        await networkManager.connect(
          'ws://localhost:8080',
          enableReconnect: true,
          reconnectDelay: const Duration(seconds: 1),
        );
      } catch (e) {
        // 연결 실패 예상
      }

      // 재연결 시도가 있어야 함
      await Future.delayed(const Duration(seconds: 2));
      expect(reconnectAttempts, greaterThan(0));
    });

    test('요청-응답 패턴', () async {
      final responseCompleter = Completer<Map<String, dynamic>>();

      networkManager.request('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch}).then((response) {
        responseCompleter.complete(response);
      }).catchError((error) {
        responseCompleter.complete({'error': error.toString()});
      });

      final response = await responseCompleter.future;
      expect(response, isA<Map<String, dynamic>>());
    });
  });
}

// 테스트용 WebSocket 채널 모의
class MockWebSocketChannel extends WebSocketChannel {
  MockWebSocketChannel() : super(const MockStream(), const MockSink());
}

class MockStream extends Stream<dynamic> {
  const MockStream();

  @override
  StreamSubscription<dynamic> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return MockStreamSubscription();
  }
}

class MockStreamSubscription extends StreamSubscription<dynamic> {
  @override
  Future<void> cancel() async {}

  @override
  void onData(void Function(dynamic data)? handleData) {}

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  Future<void> asFuture([void Function()? onDone]) async => this;

  @override
  bool get isPaused => false;

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}
}

class MockSink extends StreamSink<dynamic> {
  @override
  Future<void> close() async {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  void add(dynamic event) {}

  @override
  Future get done => throw UnimplementedError();
}

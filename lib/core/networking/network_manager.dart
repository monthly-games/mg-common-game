import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 네트워크 연결 상태
enum NetworkStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// 네트워크 이벤트
class NetworkEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NetworkEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NetworkEvent.fromJson(Map<String, dynamic> json) => NetworkEvent(
        type: json['type'] as String,
        data: json['data'] as Map<String, dynamic>,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 네트워크 매니저 (WebSocket 기반)
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._();
  static NetworkManager get instance => _instance;

  NetworkManager._();

  // ============================================
  // 상태
  // ============================================
  WebSocketChannel? _channel;
  NetworkStatus _status = NetworkStatus.disconnected;
  String? _serverUrl;
  String? _userId;

  final StreamController<NetworkEvent> _eventController =
      StreamController<NetworkEvent>.broadcast();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // ============================================
  // Getters
  // ============================================
  NetworkStatus get status => _status;
  bool get isConnected => _status == NetworkStatus.connected;
  Stream<NetworkEvent> get onEvent => _eventController.stream;
  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;

  // ============================================
  // 연결 관리
  // ============================================

  Future<void> connect(String serverUrl, {String? userId}) async {
    if (_status == NetworkStatus.connecting ||
        _status == NetworkStatus.connected) {
      return;
    }

    _serverUrl = serverUrl;
    _userId = userId;

    _setStatus(NetworkStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(serverUrl),
      );

      // 메시지 수신 리스너
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _setStatus(NetworkStatus.connected);
      _reconnectAttempts = 0;

      // 하트비트 시작
      _startHeartbeat();

      debugPrint('[Network] Connected to $serverUrl');
    } catch (e) {
      _handleError(e);
      _setStatus(NetworkStatus.error);
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    await _channel?.sink.close();
    _channel = null;

    _setStatus(NetworkStatus.disconnected);

    debugPrint('[Network] Disconnected');
  }

  Future<void> reconnect() async {
    if (_serverUrl == null) return;

    await disconnect();

    _setStatus(NetworkStatus.reconnecting);

    // 지수 백오프로 재연결 시도
    final delay = Duration(seconds: 2 << _reconnectAttempts);
    await Future.delayed(delay);

    _reconnectAttempts++;
    if (_reconnectAttempts <= _maxReconnectAttempts) {
      await connect(_serverUrl!, userId: _userId);
    } else {
      _setStatus(NetworkStatus.error);
      debugPrint('[Network] Max reconnect attempts reached');
    }
  }

  // ============================================
  // 메시지 전송
  // ============================================

  void send(String type, Map<String, dynamic> data) {
    if (!isConnected) {
      debugPrint('[Network] Not connected, cannot send message');
      return;
    }

    final event = NetworkEvent(type: type, data: data);

    try {
      _channel!.sink.add(jsonEncode(event.toJson()));
      debugPrint('[Network] Sent: $type');
    } catch (e) {
      debugPrint('[Network] Send error: $e');
    }
  }

  // ============================================
  // 이벤트 구독
  // ============================================

  Stream<NetworkEvent> onEventType(String type) {
    return onEvent.where((event) => event.type == type);
  }

  // ============================================
  // 내부 핸들러
  // ============================================

  void _handleMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = NetworkEvent.fromJson(json);

      _eventController.add(event);

      debugPrint('[Network] Received: ${event.type}');
    } catch (e) {
      debugPrint('[Network] Message parse error: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('[Network] Error: $error');

    if (_status == NetworkStatus.connected) {
      _reconnect();
    }
  }

  void _handleDone() {
    debugPrint('[Network] Connection closed');

    if (_status == NetworkStatus.connected) {
      _reconnect();
    }
  }

  void _setStatus(NetworkStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      debugPrint('[Network] Status: $status');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        send('heartbeat', {'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}

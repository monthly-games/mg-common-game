import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket message types
enum WebSocketMessageType {
  chat,
  presence,
  notification,
  system,
  error,
  pong,
}

/// WebSocket message
class WebSocketMessage {
  final WebSocketMessageType type;
  final String? channelId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    this.channelId,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'channelId': channelId,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketMessageType.system,
      ),
      channelId: json['channelId'],
      data: json['data'] as Map<String, dynamic>,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : null,
    );
  }

  /// Create chat message
  factory WebSocketMessage.chat({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.chat,
      channelId: channelId,
      data: {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
      },
    );
  }

  /// Create presence message
  factory WebSocketMessage.presence({
    required String userId,
    required String status,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.presence,
      data: {
        'userId': userId,
        'status': status,
      },
    );
  }

  /// Create notification message
  factory WebSocketMessage.notification({
    required String title,
    required String body,
    String? imageUrl,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.notification,
      data: {
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  /// Create error message
  factory WebSocketMessage.error({
    required String message,
    int? code,
  }) {
    return WebSocketMessage(
      type: WebSocketMessageType.error,
      data: {
        'message': message,
        if (code != null) 'code': code,
      },
    );
  }
}

/// WebSocket connection state
enum WebSocketConnectionState {
  connecting,
  connected,
  disconnecting,
  disconnected,
  error,
}

/// WebSocket configuration
class WebSocketConfig {
  final String url;
  final Duration reconnectDelay;
  final Duration pingInterval;
  final int maxReconnectAttempts;

  const WebSocketConfig({
    required this.url,
    this.reconnectDelay = const Duration(seconds: 3),
    this.pingInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 10,
  });
}

/// WebSocket service for real-time communication
class WebSocketService {
  static WebSocketService? _instance;
  WebSocketConfig? _config;

  WebSocketChannel? _channel;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  final StreamController<WebSocketMessage> _messageController = StreamController.broadcast();
  final StreamController<WebSocketConnectionState> _stateController = StreamController.broadcast();

  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Get singleton instance
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// Stream of connection state changes
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// Current connection state
  WebSocketConnectionState get state => _state;

  /// Check if connected
  bool get isConnected => _state == WebSocketConnectionState.connected;

  /// Initialize WebSocket service
  void initialize(WebSocketConfig config) {
    _config = config;
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_config == null) {
      throw StateError('WebSocketService not initialized. Call initialize() first.');
    }

    if (_state == WebSocketConnectionState.connecting ||
        _state == WebSocketConnectionState.connected) {
      return;
    }

    _updateState(WebSocketConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_config!.url));

      // Listen for incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _updateState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      _onError(e);
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    if (_state == WebSocketConnectionState.disconnected) {
      return;
    }

    _updateState(WebSocketConnectionState.disconnecting);

    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    await _channel?.sink.close();
    _channel = null;

    _updateState(WebSocketConnectionState.disconnected);
  }

  /// Send message
  void send(WebSocketMessage message) {
    if (!isConnected) {
      throw StateError('WebSocket is not connected');
    }

    _channel?.sink.add(jsonEncode(message.toJson()));
  }

  /// Send chat message
  void sendChatMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    send(WebSocketMessage.chat(
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      content: content,
    ));
  }

  /// Update presence
  void updatePresence({
    required String userId,
    required String status,
  }) {
    send(WebSocketMessage.presence(
      userId: userId,
      status: status,
    ));
  }

  /// Join channel
  void joinChannel(String channelId, String userId) {
    send(WebSocketMessage(
      type: WebSocketMessageType.system,
      channelId: channelId,
      data: {
        'action': 'join',
        'userId': userId,
      },
    ));
  }

  /// Leave channel
  void leaveChannel(String channelId, String userId) {
    send(WebSocketMessage(
      type: WebSocketMessageType.system,
      channelId: channelId,
      data: {
        'action': 'leave',
        'userId': userId,
      },
    ));
  }

  /// Handle incoming message
  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(json);

      // Handle pong
      if (wsMessage.type == WebSocketMessageType.pong) {
        return;
      }

      _messageController.add(wsMessage);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle error
  void _onError(dynamic error) {
    _updateState(WebSocketConnectionState.error);
    print('WebSocket error: $error');

    // Attempt to reconnect
    _scheduleReconnect();
  }

  /// Handle connection closed
  void _onDone() {
    _updateState(WebSocketConnectionState.disconnected);
    _pingTimer?.cancel();

    // Attempt to reconnect
    _scheduleReconnect();
  }

  /// Update connection state
  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_config!.pingInterval, (_) {
      if (isConnected) {
        _channel?.sink.add(jsonEncode({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
      }
    });
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _config!.maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    _reconnectTimer = Timer(_config!.reconnectDelay, () {
      print('Reconnecting... (attempt $_reconnectAttempts)');
      connect();
    });
  }

  /// Subscribe to specific channel
  Stream<WebSocketMessage> subscribeToChannel(String channelId) {
    return messageStream.where((message) => message.channelId == channelId);
  }

  /// Subscribe to specific message type
  Stream<WebSocketMessage> subscribeToType(WebSocketMessageType type) {
    return messageStream.where((message) => message.type == type);
  }

  /// Subscribe to chat messages in a channel
  Stream<WebSocketMessage> subscribeToChat(String channelId) {
    return messageStream.where((message) =>
      message.type == WebSocketMessageType.chat &&
      message.channelId == channelId
    );
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}

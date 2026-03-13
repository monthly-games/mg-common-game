import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 플레이어 상태
enum PlayerState {
  idle,
  searching,
  matched,
  playing,
  disconnected,
}

/// 멀티플레이어 모드
enum MultiplayerMode {
  pvp,
  pve,
  co-op,
  battleRoyale,
}

/// 게임 메시지 타입
enum GameMessageType {
  playerMove,
  playerAction,
  gameState,
  chat,
  system,
}

/// 게임 메시지
class GameMessage {
  final String type;
  final Map<String, dynamic> data;
  final String? senderId;
  final DateTime timestamp;

  GameMessage({
    required this.type,
    required this.data,
    this.senderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GameMessage.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return GameMessage(
      type: map['type'] as String,
      data: map['data'] as Map<String, dynamic>,
      senderId: map['senderId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String toJson() => jsonEncode({
        'type': type,
        'data': data,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
      });
}

/// 플레이어
class Player {
  final String id;
  final String username;
  final String? avatarUrl;
  final PlayerState state;
  final int? score;
  final Map<String, dynamic>? stats;

  const Player({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.state,
    this.score,
    this.stats,
  });
}

/// 매치 룸
class MatchLobby {
  final String id;
  final String name;
  final MultiplayerMode mode;
  final int maxPlayers;
  final List<Player> players;
  final bool isPrivate;
  final String? password;
  final DateTime createdAt;

  const MatchLobby({
    required this.id,
    required this.name,
    required this.mode,
    required this.maxPlayers,
    required this.players,
    this.isPrivate = false,
    this.password,
    required this.createdAt,
  });

  /// 참가 가능 여부
  bool get canJoin => players.length < maxPlayers;

  /// 참가자 수
  int get playerCount => players.length;
}

/// 게임 상태
class GameState {
  final String id;
  final int tick;
  final Map<String, dynamic> data;
  final List<PlayerStateUpdate> playerUpdates;

  const GameState({
    required this.id,
    required this.tick,
    required this.data,
    required this.playerUpdates,
  });
}

/// 플레이어 상태 업데이트
class PlayerStateUpdate {
  final String playerId;
  final Map<String, dynamic> position;
  final Map<String, dynamic>? action;
  final int tick;

  const PlayerStateUpdate({
    required this.playerId,
    required this.position,
    this.action,
    required this.tick,
  });
}

/// 실시간 멀티플레이어 관리자
class RealtimeMultiplayerManager {
  static final RealtimeMultiplayerManager _instance = RealtimeMultiplayerManager._();
  static RealtimeMultiplayerManager get instance => _instance;

  RealtimeMultiplayerManager._();

  WebSocketChannel? _channel;
  String? _roomId;
  String? _playerId;
  Player? _currentPlayer;
  MatchLobby? _currentLobby;

  final StreamController<GameMessage> _messageController =
      StreamController<GameMessage>.broadcast();
  final StreamController<List<Player>> _playersController =
      StreamController<List<Player>>.broadcast();
  final StreamController<GameState> _gameStateController =
      StreamController<GameState>.broadcast();
  final StreamController<String> _chatController =
      StreamController<String>.broadcast();

  Stream<GameMessage> get onMessage => _messageController.stream;
  Stream<List<Player>> get onPlayersUpdate => _playersController.stream;
  Stream<GameState> get onGameStateUpdate => _gameStateController.stream;
  Stream<String> get onChatMessage => _chatController.stream;

  bool _isConnected = false;
  Timer? _pingTimer;
  int _lastPingTime = 0;
  int _latency = 0;

  /// 연결
  Future<void> connect(String serverUrl) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('[Multiplayer] Error: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('[Multiplayer] Connection closed');
          _isConnected = false;
        },
      );

      // 핑 타이머 시작
      _startPingTimer();

      _isConnected = true;
      debugPrint('[Multiplayer] Connected to $serverUrl');
    } catch (e) {
      debugPrint('[Multiplayer] Connection failed: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic message) {
    final json = message as String;
    final gameMessage = GameMessage.fromJson(json);

    switch (gameMessage.type) {
      case 'game_state':
        final gameState = GameState.fromJson(gameMessage.data);
        _gameStateController.add(gameState);
        break;
      case 'players_update':
        final players = (gameMessage.data['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList();
        _playersController.add(players);
        break;
      case 'chat':
        _chatController.add(gameMessage.data['message'] as String);
        break;
      default:
        _messageController.add(gameMessage);
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendPing();
    });
  }

  void _sendPing() {
    _lastPingTime = DateTime.now().millisecondsSinceEpoch;

    send(const GameMessage(
      type: 'ping',
      data: {'timestamp': _lastPingTime},
    ));
  }

  void _handlePong(Map<String, dynamic> data) {
    final pingTime = data['timestamp'] as int;
    _latency = DateTime.now().millisecondsSinceEpoch - pingTime;

    debugPrint('[Multiplayer] Latency: ${_latency}ms');
  }

  /// 연결 해제
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _pingTimer?.cancel();
    _isConnected = false;
    _roomId = null;

    debugPrint('[Multiplayer] Disconnected');
  }

  /// 방 생성
  Future<String> createRoom({
    required String name,
    required MultiplayerMode mode,
    required int maxPlayers,
    bool isPrivate = false,
    String? password,
  }) async {
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

    final message = GameMessage(
      type: 'create_room',
      data: {
        'roomId': roomId,
        'name': name,
        'mode': mode.name,
        'maxPlayers': maxPlayers,
        'isPrivate': isPrivate,
        'password': password,
      },
    );

    send(message);

    _roomId = roomId;

    debugPrint('[Multiplayer] Room created: $roomId');

    return roomId;
  }

  /// 방 참가
  Future<void> joinRoom({
    required String roomId,
    String? password,
  }) async {
    final message = GameMessage(
      type: 'join_room',
      data: {
        'roomId': roomId,
        'password': password,
      },
    );

    send(message);

    _roomId = roomId;

    debugPrint('[Multiplayer] Joined room: $roomId');
  }

  /// 방 나가기
  Future<void> leaveRoom() async {
    if (_roomId == null) return;

    final message = GameMessage(
      type: 'leave_room',
      data: {
        'roomId': _roomId,
      },
    );

    send(message);

    _roomId = null;

    debugPrint('[Multiplayer] Left room');
  }

  /// 메시지 전송
  void send(GameMessage message) {
    if (!_isConnected || _channel == null) {
      debugPrint('[Multiplayer] Not connected');
      return;
    }

    final json = message.toJson();
    _channel!.sink.add(json);
  }

  /// 플레이어 이동 전송
  void sendPlayerMove({
    required double x,
    required double y,
    required double z,
    Map<String, dynamic>? additionalData,
  }) {
    final message = GameMessage(
      type: 'player_move',
      data: {
        'position': {'x': x, 'y': y, 'z': z},
        if (additionalData != null) ...additionalData,
      },
      senderId: _playerId,
    );

    send(message);
  }

  /// 플레이어 액션 전송
  void sendPlayerAction({
    required String action,
    required Map<String, dynamic> data,
  }) {
    final message = GameMessage(
      type: 'player_action',
      data: {
        'action': action,
        ...data,
      },
      senderId: _playerId,
    );

    send(message);
  }

  /// 채팅 메시지 전송
  void sendChatMessage(String message) {
    final gameMessage = GameMessage(
      type: 'chat',
      data: {
        'message': message,
        'roomId': _roomId,
      },
      senderId: _playerId,
    );

    send(gameMessage);
  }

  /// 현재 방 정보
  MatchLobby? get currentLobby => _currentLobby;

  /// 연결 상태
  bool get isConnected => _isConnected;

  /// 레이턴시
  int get latency => _latency;

  /// 플레이어 ID 설정
  void setPlayerId(String playerId) {
    _playerId = playerId;
  }

  /// 현재 플레이어
  Player? get currentPlayer => _currentPlayer;

  void dispose() {
    disconnect();
    _messageController.close();
    _playersController.close();
    _gameStateController.close();
    _chatController.close();
  }
}

/// 랙 보상 (Lag Compensation)
class LagCompensation {
  final Map<String, List<PlayerStateUpdate>> _stateHistory = {};
  final int _maxHistorySize = 100;

  /// 상태 기록
  void recordState(PlayerStateUpdate update) {
    _stateHistory.putIfAbsent(update.playerId, () => []);

    final history = _stateHistory[update.playerId]!;
    history.add(update);

    // 히스토리 크기 제한
    if (history.length > _maxHistorySize) {
      history.removeAt(0);
    }
  }

  /// 재동기화 (Rewind & Replay)
  PlayerStateUpdate? rewindAndReplay({
    required String playerId,
    required int currentTick,
    required int lagTicks,
  }) {
    final history = _stateHistory[playerId];
    if (history == null || history.isEmpty) return null;

    // 랙 만큼 과거 상태 찾기
    final targetTick = currentTick - lagTicks;
    final pastState = history.cast<PlayerStateUpdate?>().firstWhere(
      (state) => state != null && state.tick == targetTick,
      orElse: () => null,
    );

    return pastState;
  }
}

/// 리플레이 시스템
class ReplaySystem {
  final List<GameMessage> _recordedMessages = [];
  bool _isRecording = false;

  /// 녹화 시작
  void startRecording() {
    _isRecording = true;
    _recordedMessages.clear();
    debugPrint('[Replay] Recording started');
  }

  /// 녹화 중지
  void stopRecording() {
    _isRecording = false;
    debugPrint('[Replay] Recording stopped (${_recordedMessages.length} messages)');
  }

  /// 메시지 기록
  void recordMessage(GameMessage message) {
    if (_isRecording) {
      _recordedMessages.add(message);
    }
  }

  /// 리플레이 재생
  Future<void> replay({Duration? delay}) async {
    delay ??= const Duration(milliseconds: 100);

    for (final message in _recordedMessages) {
      // 실제 재생 로직
      await Future.delayed(delay);
      debugPrint('[Replay] ${message.type}');
    }
  }

  /// 리플레이 저장
  String saveReplay() {
    final replayData = jsonEncode({
      'messages': _recordedMessages.map((m) => m.toJson()).toList(),
      'recordedAt': DateTime.now().toIso8601String(),
    });

    return replayData;
  }

  /// 리플레이 로드
  Future<void> loadReplay(String replayData) async {
    final data = jsonDecode(replayData) as Map<String, dynamic>;

    _recordedMessages.clear();
    for (final msg in data['messages'] as List) {
      _recordedMessages.add(GameMessage.fromJson(msg as String));
    }

    debugPrint('[Replay] Loaded ${_recordedMessages.length} messages');
  }
}

/// 로비 매치메이킹
class LobbyMatchmaking {
  final List<MatchLobby> _lobbies = [];

  /// 로비 목록 조회
  List<MatchLobby> getLobbies({MultiplayerMode? mode}) {
    var lobbies = _lobbies.toList();

    if (mode != null) {
      lobbies = lobbies.where((l) => l.mode == mode).toList();
    }

    return lobbies;
  }

  /// 로비 추가
  void addLobby(MatchLobby lobby) {
    _lobbies.add(lobby);
  }

  /// 빠른 참가
  MatchLobby? findQuickJoin(MultiplayerMode mode) {
    return _lobbies
        .where((l) => l.mode == mode && l.canJoin && !l.isPrivate)
        .firstWhere(
          (l) => l.players.length < l.maxPlayers,
          orElse: () => _lobbies
              .where((l) => l.mode == mode && l.canJoin)
              .first,
        );
  }
}

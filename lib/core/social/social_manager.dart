import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/networking/network_manager.dart';

/// 친구 상태
enum FriendStatus {
  offline,
  online,
  inGame,
  away,
}

/// 친구 정보
class Friend {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final FriendStatus status;
  final int level;
  final String? currentGame;
  final DateTime lastSeen;

  Friend({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.status,
    required this.level,
    this.currentGame,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime(2000);

  Friend copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    FriendStatus? status,
    int? level,
    String? currentGame,
    DateTime? lastSeen,
  }) {
    return Friend(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      level: level ?? this.level,
      currentGame: currentGame ?? this.currentGame,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'status': status.name,
        'level': level,
        'currentGame': currentGame,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        status: FriendStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => FriendStatus.offline,
        ),
        level: json['level'] as int,
        currentGame: json['currentGame'] as String?,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );
}

/// 리더보드 항목
class LeaderboardEntry {
  final String userId;
  final String nickname;
  final int score;
  final int rank;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.rank,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'score': score,
        'rank': rank,
        'avatarUrl': avatarUrl,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        score: json['score'] as int,
        rank: json['rank'] as int,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// 채팅 메시지
class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderNickname;
  final String content;
  final DateTime timestamp;
  final String? avatarUrl;
  final bool isSystemMessage;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderNickname,
    required this.content,
    required this.timestamp,
    this.avatarUrl,
    this.isSystemMessage = false,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'senderId': senderId,
        'senderNickname': senderNickname,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'avatarUrl': avatarUrl,
        'isSystemMessage': isSystemMessage,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        messageId: json['messageId'] as String,
        senderId: json['senderId'] as String,
        senderNickname: json['senderNickname'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        avatarUrl: json['avatarUrl'] as String?,
        isSystemMessage: json['isSystemMessage'] as bool? ?? false,
      );
}

/// 소셜 매니저
class SocialManager {
  static final SocialManager _instance = SocialManager._();
  static SocialManager get instance => _instance;

  SocialManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, Friend> _friends = {};
  final List<ChatMessage> _chatMessages = [];

  final StreamController<List<Friend>> _friendsController =
      StreamController<List<Friend>>.broadcast();
  final StreamController<List<ChatMessage>> _chatController =
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<List<LeaderboardEntry>> _leaderboardController =
      StreamController<List<LeaderboardEntry>>.broadcast();

  bool _isInitialized = false;

  // ============================================
  // Getters
  // ============================================
  bool get isInitialized => _isInitialized;
  List<Friend> get friends => _friends.values.toList();
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  Stream<List<Friend>> get onFriendsChanged => _friendsController.stream;
  Stream<List<ChatMessage>> get onChatMessages => _chatController.stream;
  Stream<List<LeaderboardEntry>> get onLeaderboardUpdated =>
      _leaderboardController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadFriends();

    _isInitialized = true;

    // 네트워크 이벤트 구독
    NetworkManager.instance.onEventType('friend_status_update').listen(_handleFriendStatusUpdate);
    NetworkManager.instance.onEventType('chat_message').listen(_handleChatMessage);
    NetworkManager.instance.onEventType('leaderboard_update').listen(_handleLeaderboardUpdate);

    debugPrint('[Social] Initialized');
  }

  // ============================================
  // 친구 관리
  // ============================================

  Future<void> addFriend(String userId, String nickname) async {
    if (_friends.containsKey(userId)) {
      debugPrint('[Social] Friend already exists: $userId');
      return;
    }

    final friend = Friend(
      userId: userId,
      nickname: nickname,
      status: FriendStatus.offline,
      level: 1,
    );

    _friends[userId] = friend;
    await _saveFriends();

    _friendsController.add(friends);

    // 서버에 전송
    NetworkManager.instance.send('add_friend', {
      'userId': userId,
      'nickname': nickname,
    });

    debugPrint('[Social] Friend added: $nickname');
  }

  Future<void> removeFriend(String userId) async {
    if (!_friends.containsKey(userId)) return;

    _friends.remove(userId);
    await _saveFriends();

    _friendsController.add(friends);

    NetworkManager.instance.send('remove_friend', {'userId': userId});

    debugPrint('[Social] Friend removed: $userId');
  }

  void updateFriendStatus(String userId, FriendStatus status, {String? currentGame}) {
    final friend = _friends[userId];
    if (friend != null) {
      _friends[userId] = friend.copyWith(
        status: status,
        currentGame: currentGame,
      );
      _friendsController.add(friends);
    }
  }

  List<Friend> getOnlineFriends() {
    return friends.where((f) => f.status != FriendStatus.offline).toList();
  }

  // ============================================
  // 리더보드
  // ============================================

  Future<List<LeaderboardEntry>> getLeaderboard({
    String? gameId,
    int limit = 100,
  }) async {
    // 서버에서 리더보드 가져오기
    NetworkManager.instance.send('get_leaderboard', {
      'gameId': gameId,
      'limit': limit,
    });

    // 로컬 캐시 반환
    final key = 'leaderboard_${gameId ?? "global"}';
    final cached = _prefs!.getStringList(key);
    if (cached != null) {
      return cached.map((e) => LeaderboardEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    }

    return [];
  }

  // ============================================
  // 채팅
  // ============================================

  Future<void> sendChatMessage(String content, {String? recipientId}) async {
    final message = ChatMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me', // 실제 사용자 ID로 대체
      senderNickname: 'Me',
      content: content,
      timestamp: DateTime.now(),
    );

    _chatMessages.add(message);
    if (_chatMessages.length > 100) {
      _chatMessages.removeAt(0);
    }

    _chatController.add(List.unmodifiable(_chatMessages));

    NetworkManager.instance.send('send_chat', {
      'content': content,
      'recipientId': recipientId,
    });
  }

  void clearChat() {
    _chatMessages.clear();
    _chatController.add([]);
  }

  // ============================================
  // 내부 핸들러
  // ============================================

  void _handleFriendStatusUpdate(NetworkEvent event) {
    final data = event.data;
    final userId = data['userId'] as String?;
    final statusStr = data['status'] as String?;

    if (userId != null && statusStr != null) {
      final status = FriendStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => FriendStatus.offline,
      );
      updateFriendStatus(userId, status, currentGame: data['currentGame'] as String?);
    }
  }

  void _handleChatMessage(NetworkEvent event) {
    final data = event.data;
    final message = ChatMessage(
      messageId: data['messageId'] as String,
      senderId: data['senderId'] as String,
      senderNickname: data['senderNickname'] as String,
      content: data['content'] as String,
      timestamp: DateTime.parse(data['timestamp'] as String),
      avatarUrl: data['avatarUrl'] as String?,
    );

    _chatMessages.add(message);
    if (_chatMessages.length > 100) {
      _chatMessages.removeAt(0);
    }

    _chatController.add(List.unmodifiable(_chatMessages));
  }

  void _handleLeaderboardUpdate(NetworkEvent event) {
    final data = event.data;
    final entries = (data['entries'] as List?)
        ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    if (entries != null) {
      _leaderboardController.add(entries);
    }
  }

  // ============================================
  // 데이터 저장/로드
  // ============================================

  Future<void> _saveFriends() async {
    final friendsJson = _friends.values.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs!.setStringList('friends', friendsJson);
  }

  Future<void> _loadFriends() async {
    final friendsJson = _prefs!.getStringList('friends');
    if (friendsJson != null) {
      for (final json in friendsJson) {
        final friend = Friend.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _friends[friend.userId] = friend;
      }
    }
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _friendsController.close();
    _chatController.close();
    _leaderboardController.close();
  }
}

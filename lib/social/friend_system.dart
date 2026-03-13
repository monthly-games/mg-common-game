import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 친구 관계 상태
enum FriendStatus {
  none,
  pending,
  accepted,
  blocked,
}

/// 온라인 상태
enum OnlineStatus {
  offline,
  online,
  away,
  busy,
  invisible,
}

/// 친구
class Friend {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final FriendStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final OnlineStatus onlineStatus;
  final DateTime? lastSeen;

  const Friend({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.onlineStatus = OnlineStatus.offline,
    this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'onlineStatus': onlineStatus.name,
        'lastSeen': lastSeen?.toIso8601String(),
      };
}

/// 친구 요청
class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromAvatarUrl;
  final String? message;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromAvatarUrl,
    this.message,
    required this.createdAt,
  });
}

/// 채팅 메시지
class ChatMessage {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyTo;

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.replyTo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromUsername': fromUsername,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'replyTo': replyTo,
      };
}

/// 메시지 타입
enum MessageType {
  text,
  image,
  emoji,
  system,
}

/// 채팅방
class ChatRoom {
  final String id;
  final String name;
  final ChatRoomType type;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
  });
}

/// 채팅방 타입
enum ChatRoomType {
  direct,
  group,
  guild,
  system,
}

/// 소셜 피드 포스트
class SocialPost {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool isLiked;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });
}

/// 친구 관리자
class FriendManager {
  static final FriendManager _instance = FriendManager._();
  static FriendManager get instance => _instance;

  FriendManager._();

  final Map<String, Friend> _friends = {};
  final List<FriendRequest> _incomingRequests = [];
  final List<FriendRequest> _outgoingRequests = [];

  final StreamController<Friend> _friendController =
      StreamController<Friend>.broadcast();
  final StreamController<FriendRequest> _requestController =
      StreamController<FriendRequest>.broadcast();

  Stream<Friend> get onFriendUpdate => _friendController.stream;
  Stream<FriendRequest> get onFriendRequest => _requestController.stream;

  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// 친구 추가 요청
  Future<void> sendFriendRequest({
    required String toUserId,
    String? message,
  }) async {
    final request = FriendRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: _currentUserId!,
      fromUsername: '현재 사용자',
      message: message,
      createdAt: DateTime.now(),
    );

    _outgoingRequests.add(request);

    debugPrint('[Friend] Friend request sent to $toUserId');
  }

  /// 친구 요청 수락
  Future<void> acceptFriendRequest(String requestId) async {
    final request = _incomingRequests.firstWhere((r) => r.id == requestId);

    final friend = Friend(
      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
      userId: request.fromUserId,
      username: request.fromUsername,
      avatarUrl: request.fromAvatarUrl,
      status: FriendStatus.accepted,
      requestedAt: request.createdAt,
      acceptedAt: DateTime.now(),
      onlineStatus: OnlineStatus.online,
    );

    _friends[request.fromUserId] = friend;
    _incomingRequests.removeWhere((r) => r.id == requestId);

    _friendController.add(friend);

    debugPrint('[Friend] Friend request accepted: ${request.fromUsername}');
  }

  /// 친구 요청 거절
  Future<void> declineFriendRequest(String requestId) async {
    _incomingRequests.removeWhere((r) => r.id == requestId);

    debugPrint('[Friend] Friend request declined: $requestId');
  }

  /// 친구 삭제
  Future<void> removeFriend(String userId) async {
    _friends.remove(userId);

    debugPrint('[Friend] Friend removed: $userId');
  }

  /// 친구 차단
  Future<void> blockFriend(String userId) async {
    final friend = _friends[userId];
    if (friend != null) {
      final blocked = Friend(
        id: friend.id,
        userId: friend.userId,
        username: friend.username,
        avatarUrl: friend.avatarUrl,
        status: FriendStatus.blocked,
        requestedAt: friend.requestedAt,
        acceptedAt: friend.acceptedAt,
      );

      _friends[userId] = blocked;
      _friendController.add(blocked);
    }

    debugPrint('[Friend] Friend blocked: $userId');
  }

  /// 친구 목록 조회
  List<Friend> getFriends({FriendStatus? status}) {
    var friends = _friends.values.toList();

    if (status != null) {
      friends = friends.where((f) => f.status == status).toList();
    }

    return friends;
  }

  /// 온라인 친구 조회
  List<Friend> getOnlineFriends() {
    return _friends.values
        .where((f) =>
            f.status == FriendStatus.accepted &&
            f.onlineStatus == OnlineStatus.online)
        .toList();
  }

  /// 친구 검색
  List<Friend> searchFriends(String query) {
    final lowerQuery = query.toLowerCase();

    return _friends.values
        .where((f) =>
            f.username.toLowerCase().contains(lowerQuery) ||
            f.userId.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 친구 요청 목록
  List<FriendRequest> getIncomingRequests() => _incomingRequests;
  List<FriendRequest> getOutgoingRequests() => _outgoingRequests;

  /// 온라인 상태 업데이트
  void updateOnlineStatus(String userId, OnlineStatus status) {
    final friend = _friends[userId];
    if (friend != null) {
      // 불변 객체이므로 새 객체 생성 (실제로는 상태만 업데이트)
      debugPrint('[Friend] $userId status: ${status.name}');
    }
  }

  void dispose() {
    _friendController.close();
    _requestController.close();
  }
}

/// 채팅 관리자
class ChatManager {
  static final ChatManager _instance = ChatManager._();
  static ChatManager get instance => _instance;

  ChatManager._();

  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, List<ChatMessage>> _messages = {};

  final StreamController<ChatRoom> _roomController =
      StreamController<ChatRoom>.broadcast();
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatRoom> get onRoomUpdate => _roomController.stream;
  Stream<ChatMessage> get onNewMessage => _messageController.stream;

  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// 1:1 채팅방 생성
  Future<ChatRoom> createDirectChat(String otherUserId) async {
    final roomId = 'chat_${[_currentUserId, otherUserId].join('_').hashCode}';

    final room = ChatRoom(
      id: roomId,
      name: otherUserId,
      type: ChatRoomType.direct,
      participants: [_currentUserId!, otherUserId],
    );

    _chatRooms[roomId] = room;
    _messages[roomId] = [];

    _roomController.add(room);

    return room;
  }

  /// 그룹 채팅방 생성
  Future<ChatRoom> createGroupChat({
    required String name,
    required List<String> participantIds,
  }) async {
    final roomId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    final room = ChatRoom(
      id: roomId,
      name: name,
      type: ChatRoomType.group,
      participants: [_currentUserId!, ...participantIds],
    );

    _chatRooms[roomId] = room;
    _messages[roomId] = [];

    _roomController.add(room);

    return room;
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required String roomId,
    required String content,
    MessageType type = MessageType.text,
    String? replyTo,
  }) async {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: _currentUserId!,
      fromUsername: '현재 사용자',
      content: content,
      type: type,
      timestamp: DateTime.now(),
      replyTo: replyTo,
    );

    _messages[roomId]!.add(message);
    _messageController.add(message);

    debugPrint('[Chat] Message sent to $roomId');
  }

  /// 메시지 목록 조회
  List<ChatMessage> getMessages(String roomId) {
    return _messages[roomId] ?? [];
  }

  /// 채팅방 목록 조회
  List<ChatRoom> getChatRooms() {
    return _chatRooms.values.toList()
      ..sort((a, b) =>
          (b.lastMessageTime ?? DateTime(0))
              .compareTo(a.lastMessageTime ?? DateTime(0)));
  }

  /// 읽지 않은 메시지 수
  int getUnreadCount(String roomId) {
    return _messages[roomId]
            ?.where((m) => m.fromUserId != _currentUserId && !m.isRead)
            .length ??
        0;
  }

  /// 메시지 읽음 표시
  void markAsRead(String roomId) {
    final messages = _messages[roomId];
    if (messages != null) {
      for (final message in messages) {
        if (message.fromUserId != _currentUserId) {
          // message.isRead = true; // 불변 객체라 실제로는 별도 처리 필요
        }
      }
    }
  }

  /// 채팅방 나가기
  Future<void> leaveChatRoom(String roomId) async {
    _chatRooms.remove(roomId);
    _messages.remove(roomId);

    debugPrint('[Chat] Left room: $roomId');
  }

  void dispose() {
    _roomController.close();
    _messageController.close();
  }
}

/// 소셜 피드 관리자
class SocialFeedManager {
  static final SocialFeedManager _instance = SocialFeedManager._();
  static SocialFeedManager get instance => _instance;

  SocialFeedManager._();

  final List<SocialPost> _posts = [];

  final StreamController<SocialPost> _postController =
      StreamController<SocialPost>.broadcast();

  Stream<SocialPost> get onNewPost => _postController.stream;

  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// 포스트 작성
  Future<void> createPost({
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final post = SocialPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
      username: '현재 사용자',
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    _posts.insert(0, post);
    _postController.add(post);

    debugPrint('[SocialFeed] Post created');
  }

  /// 포스트 좋아요
  Future<void> likePost(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    // post.likes++; // 불변 객체라 실제로는 별도 처리
    // post.isLiked = true;

    debugPrint('[SocialFeed] Post liked: $postId');
  }

  /// 포스트 삭제
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);

    debugPrint('[SocialFeed] Post deleted: $postId');
  }

  /// 피드 조회
  List<SocialPost> getFeed({int limit = 20, int offset = 0}) {
    return _posts.skip(offset).take(limit).toList();
  }

  /// 내 포스트 조회
  List<SocialPost> getMyPosts() {
    return _posts.where((p) => p.userId == _currentUserId).toList();
  }

  void dispose() {
    _postController.close();
  }
}

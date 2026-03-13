import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 친구 상태
enum FriendStatus {
  pending,        // 대기 중
  accepted,       // 수락됨
  blocked,        // 차단됨
  favorite,       // 즐겨찾기
}

/// 온라인 상태
enum OnlineStatus {
  offline,        // 오프라인
  online,         // 온라인
  away,           // 자리 비움
  busy,           // 다른 용무 중
  gaming,         // 게임 중
}

/// 피드 타입
enum FeedType {
  text,           // 텍스트
  image,          // 이미지
  achievement,    // 업적
  levelUp,        // 레벨업
  item,           // 아이템
  guild,          // 길드
  shared,         // 공유
}

/// 친구
class Friend {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatar;
  final int level;
  final OnlineStatus onlineStatus;
  final FriendStatus status;
  final DateTime? addedAt;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final String? currentActivity; // 현재 활동

  const Friend({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatar,
    required this.level,
    required this.onlineStatus,
    required this.status,
    this.addedAt,
    this.lastSeenAt,
    this.isOnline = false,
    this.currentActivity,
  });

  /// 표시 이름
  String get display => displayName ?? username;
}

/// 친구 요청
class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUsername;
  final String? avatar;
  final String? message;
  final DateTime sentAt;
  final DateTime? expiresAt;

  const FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUsername,
    this.avatar,
    this.message,
    required this.sentAt,
    this.expiresAt,
  });
}

/// 소셜 피드 포스트
class SocialPost {
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final FeedType type;
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<String> likedBy;
  final bool isLiked;
  final bool isPinned;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const SocialPost({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.type,
    required this.content,
    this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.likedBy,
    required this.isLiked,
    this.isPinned = false,
    this.tags = const [],
    this.metadata,
  });

  /// 시간 형식
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.month}/${createdAt.day}';
  }
}

/// 댓글
class Comment {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final String? parentCommentId; // 대댓글

  const Comment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.isLiked,
    this.parentCommentId,
  });
}

/// 활동 기록
class Activity {
  final String activityId;
  final String userId;
  final String username;
  final String? avatar;
  final ActivityType type;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const Activity({
    required this.activityId,
    required this.userId,
    required this.username,
    this.avatar,
    required this.type,
    this.description,
    required this.timestamp,
    this.data,
  });
}

enum ActivityType {
  friendAdd,          // 친구 추가
  levelUp,            // 레벨업
  achievement,        // 업적 달성
  itemGet,            // 아이템 획득
  guildJoin,          // 길드 가입
  post,               // 게시글 작성
  like,               // 좋아요
  comment,            // 댓글
}

/// 소셜 관리자
class SocialFriendsManager {
  static final SocialFriendsManager _instance = SocialFriendsManager._();
  static SocialFriendsManager get instance => _instance;

  SocialFriendsManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<Friend> _friends = [];
  final List<FriendRequest> _friendRequests = [];
  final List<SocialPost> _feed = [];
  final List<Activity> _activities = [];

  final StreamController<Friend> _friendController =
      StreamController<Friend>.broadcast();
  final StreamController<FriendRequest> _requestController =
      StreamController<FriendRequest>.broadcast();
  final StreamController<SocialPost> _feedController =
      StreamController<SocialPost>.broadcast();
  final StreamController<Activity> _activityController =
      StreamController<Activity>.broadcast();

  Stream<Friend> get onFriendUpdate => _friendController.stream;
  Stream<FriendRequest> get onFriendRequest => _requestController.stream;
  Stream<SocialPost> get onFeedUpdate => _feedController.stream;
  Stream<Activity> get onActivity => _activityController.stream;

  Timer? _presenceTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 데이터 로드
    await _loadData();

    // 프레즌스 업데이트 시작
    _startPresenceUpdate();

    debugPrint('[SocialFriends] Initialized');
  }

  Future<void> _loadData() async {
    // 샘플 친구
    _friends.addAll([
      Friend(
        userId: 'user_1',
        username: 'DragonSlayer',
        displayName: '용사랑',
        avatar: 'assets/avatars/user1.png',
        level: 45,
        onlineStatus: OnlineStatus.online,
        status: FriendStatus.accepted,
        addedAt: DateTime.now().subtract(const Duration(days: 30)),
        isOnline: true,
        currentActivity: '던전 플레이 중',
      ),
      Friend(
        userId: 'user_2',
        username: 'StarPlayer',
        displayName: '별바라기',
        avatar: 'assets/avatars/user2.png',
        level: 52,
        onlineStatus: OnlineStatus.gaming,
        status: FriendStatus.favorite,
        addedAt: DateTime.now().subtract(const Duration(days: 15)),
        isOnline: true,
        currentActivity: 'PVP 중',
      ),
      Friend(
        userId: 'user_3',
        username: 'NightHawk',
        displayName: '밤의매',
        level: 38,
        onlineStatus: OnlineStatus.offline,
        status: FriendStatus.accepted,
        addedAt: DateTime.now().subtract(const Duration(days: 7)),
        isOnline: false,
        lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);

    // 샘플 친구 요청
    _friendRequests.addAll([
      FriendRequest(
        requestId: 'req_1',
        fromUserId: 'user_4',
        fromUsername: 'FireMaster',
        avatar: 'assets/avatars/user4.png',
        message: '친구 추가해요!',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);

    // 샘플 피드
    _feed.addAll([
      SocialPost(
        postId: 'post_1',
        authorId: 'user_1',
        authorName: 'DragonSlayer',
        authorAvatar: 'assets/avatars/user1.png',
        type: FeedType.achievement,
        content: '드디어 레벨 50 달성! 🎉',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 24,
        commentCount: 5,
        shareCount: 2,
        likedBy: ['user_2', 'user_3'],
        isLiked: false,
        tags: ['레벨업', '성장'],
      ),
      SocialPost(
        postId: 'post_2',
        authorId: 'user_2',
        authorName: 'StarPlayer',
        authorAvatar: 'assets/avatars/user2.png',
        type: FeedType.item,
        content: '레어 아이템 획득! ⚔️',
        imageUrls: ['assets/items/rare_sword.png'],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likeCount: 15,
        commentCount: 3,
        shareCount: 0,
        likedBy: ['user_1'],
        isLiked: true,
        tags: ['아이템', '획득'],
      ),
    ]);

    // 샘플 활동
    _activities.addAll([
      Activity(
        activityId: 'act_1',
        userId: 'user_1',
        username: 'DragonSlayer',
        avatar: 'assets/avatars/user1.png',
        type: ActivityType.levelUp,
        description: '레벨 45 달성',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Activity(
        activityId: 'act_2',
        userId: 'user_2',
        username: 'StarPlayer',
        avatar: 'assets/avatars/user2.png',
        type: ActivityType.itemGet,
        description: '희귀 아이템 획득',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);
  }

  void _startPresenceUpdate() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updatePresence();
    });
  }

  void _updatePresence() {
    // 친구 온라인 상태 업데이트
    // 실제로는 서버에서 가져옴
  }

  /// 친구 요청 전송
  Future<bool> sendFriendRequest({
    required String userId,
    String? message,
  }) async {
    if (_currentUserId == null) return false;

    // 이미 친구인지 확인
    if (_friends.any((f) => f.userId == userId)) {
      return false;
    }

    // 요청 생성
    final request = FriendRequest(
      requestId: 'req_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: _currentUserId!,
      fromUsername: '나', // 실제 유저명
      message: message,
      sentAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    // 실제로는 상대방에게 전송

    debugPrint('[SocialFriends] Friend request sent: $userId');

    return true;
  }

  /// 친구 요청 수락
  Future<bool> acceptFriendRequest(String requestId) async {
    final request = _friendRequests.cast<FriendRequest?>.firstWhere(
      (r) => r?.requestId == requestId,
      orElse: () => null,
    );

    if (request == null) return false;

    // 친구 추가
    final friend = Friend(
      userId: request.fromUserId,
      username: request.fromUsername,
      avatar: request.avatar,
      level: 1, // 실제로는 조회
      onlineStatus: OnlineStatus.offline,
      status: FriendStatus.accepted,
      addedAt: DateTime.now(),
    );

    _friends.add(friend);
    _friendRequests.removeWhere((r) => r.requestId == requestId);

    _friendController.add(friend);

    // 활동 기록
    final activity = Activity(
      activityId: 'act_${DateTime.now().millisecondsSinceEpoch}',
      userId: request.fromUserId,
      username: request.fromUsername,
      avatar: request.avatar,
      type: ActivityType.friendAdd,
      description: '새로운 친구',
      timestamp: DateTime.now(),
    );

    _activities.insert(0, activity);
    _activityController.add(activity);

    await _saveData();

    debugPrint('[SocialFriends] Friend request accepted: ${request.fromUsername}");

    return true;
  }

  /// 친구 요청 거절
  Future<bool> declineFriendRequest(String requestId) async {
    final removed = _friendRequests.removeWhere((r) => r.requestId == requestId);
    return removed > 0;
  }

  /// 친구 삭제
  Future<bool> removeFriend(String userId) async {
    final removed = _friends.removeWhere((f) => f.userId == userId);
    if (removed > 0) {
      await _saveData();
      debugPrint('[SocialFriends] Friend removed: $userId');
    }
    return removed > 0;
  }

  /// 친구 차단
  Future<bool> blockFriend(String userId) async {
    final index = _friends.indexWhere((f) => f.userId == userId);
    if (index == -1) return false;

    final friend = _friends[index];
    final updated = Friend(
      userId: friend.userId,
      username: friend.username,
      displayName: friend.displayName,
      avatar: friend.avatar,
      level: friend.level,
      onlineStatus: friend.onlineStatus,
      status: FriendStatus.blocked,
      addedAt: friend.addedAt,
      lastSeenAt: friend.lastSeenAt,
    );

    _friends[index] = updated;
    _friendController.add(updated);

    await _saveData();

    debugPrint('[SocialFriends] Friend blocked: $userId');

    return true;
  }

  /// 즐겨찾기 설정
  Future<bool> setFavorite(String userId, bool isFavorite) async {
    final index = _friends.indexWhere((f) => f.userId == userId);
    if (index == -1) return false;

    final friend = _friends[index];
    final updated = Friend(
      userId: friend.userId,
      username: friend.username,
      displayName: friend.displayName,
      avatar: friend.avatar,
      level: friend.level,
      onlineStatus: friend.onlineStatus,
      status: isFavorite ? FriendStatus.favorite : FriendStatus.accepted,
      addedAt: friend.addedAt,
      lastSeenAt: friend.lastSeenAt,
    );

    _friends[index] = updated;
    _friendController.add(updated);

    await _saveData();

    return true;
  }

  /// 피드 게시글 작성
  Future<SocialPost?> createPost({
    required FeedType type,
    required String content,
    List<String>? imageUrls,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null) return null;

    final post = SocialPost(
      postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: _currentUserId!,
      authorName: '나', // 실제 유저명
      type: type,
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      likedBy: [],
      isLiked: false,
      tags: tags ?? [],
      metadata: metadata,
    );

    _feed.insert(0, post);
    _feedController.add(post);

    // 활동 기록
    final activity = Activity(
      activityId: 'act_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
      username: '나',
      type: ActivityType.post,
      description: content,
      timestamp: DateTime.now(),
    );

    _activities.insert(0, activity);
    _activityController.add(activity);

    await _saveData();

    debugPrint('[SocialFriends] Post created');

    return post;
  }

  /// 좋아요
  Future<bool> toggleLike(String postId) async {
    final index = _feed.indexWhere((p) => p.postId == postId);
    if (index == -1) return false;

    final post = _feed[index];
    final isLiked = !post.isLiked;

    final updated = SocialPost(
      postId: post.postId,
      authorId: post.authorId,
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      type: post.type,
      content: post.content,
      imageUrls: post.imageUrls,
      createdAt: post.createdAt,
      updatedAt: DateTime.now(),
      likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      commentCount: post.commentCount,
      shareCount: post.shareCount,
      likedBy: post.likedBy,
      isLiked: isLiked,
      isPinned: post.isPinned,
      tags: post.tags,
      metadata: post.metadata,
    );

    _feed[index] = updated;
    _feedController.add(updated);

    await _saveData();

    return isLiked;
  }

  /// 댓글 작성
  Future<Comment?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    if (_currentUserId == null) return null;

    final comment = Comment(
      commentId: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: _currentUserId!,
      authorName: '나',
      content: content,
      createdAt: DateTime.now(),
      likeCount: 0,
      isLiked: false,
      parentCommentId: parentCommentId,
    );

    // 피드 업데이트
    final index = _feed.indexWhere((p) => p.postId == postId);
    if (index != -1) {
      final post = _feed[index];
      final updated = SocialPost(
        postId: post.postId,
        authorId: post.authorId,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        type: post.type,
        content: post.content,
        imageUrls: post.imageUrls,
        createdAt: post.createdAt,
        updatedAt: DateTime.now(),
        likeCount: post.likeCount,
        commentCount: post.commentCount + 1,
        shareCount: post.shareCount,
        likedBy: post.likedBy,
        isLiked: post.isLiked,
        isPinned: post.isPinned,
        tags: post.tags,
        metadata: post.metadata,
      );

      _feed[index] = updated;
      _feedController.add(updated);
    }

    await _saveData();

    debugPrint('[SocialFriends] Comment added');

    return comment;
  }

  /// 공유
  Future<int> sharePost(String postId) async {
    final index = _feed.indexWhere((p) => p.postId == postId);
    if (index == -1) return 0;

    final post = _feed[index];
    final updated = SocialPost(
      postId: post.postId,
      authorId: post.authorId,
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      type: post.type,
      content: post.content,
      imageUrls: post.imageUrls,
      createdAt: post.createdAt,
      updatedAt: DateTime.now(),
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      shareCount: post.shareCount + 1,
      likedBy: post.likedBy,
      isLiked: post.isLiked,
      isPinned: post.isPinned,
      tags: post.tags,
      metadata: post.metadata,
    );

    _feed[index] = updated;
    _feedController.add(updated);

    await _saveData();

    return updated.shareCount;
  }

  /// 친구 목록
  List<Friend> getFriends({FriendStatus? status, bool? isOnline}) {
    var friends = _friends.toList();

    if (status != null) {
      friends = friends.where((f) => f.status == status).toList();
    }

    if (isOnline != null) {
      friends = friends.where((f) => f.isOnline == isOnline).toList();
    }

    return friends..sort((a, b) {
      // 즐겨찾기 먼저
      if (a.status == FriendStatus.favorite && b.status != FriendStatus.favorite) {
        return -1;
      }
      if (b.status == FriendStatus.favorite && a.status != FriendStatus.favorite) {
        return 1;
      }
      // 온라인 순
      return b.isOnline ? 1 : -1;
    });
  }

  /// 친구 요청 목록
  List<FriendRequest> getFriendRequests() {
    return _friendRequests.toList();
  }

  /// 친구 검색
  List<Friend> searchFriends(String query) {
    final lowerQuery = query.toLowerCase();
    return _friends.where((f) =>
        f.username.toLowerCase().contains(lowerQuery) ||
        (f.displayName?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// 피드 조회
  List<SocialPost> getFeed({int limit = 20}) {
    return _feed.take(limit).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 내 게시글
  List<SocialPost> getMyPosts() {
    if (_currentUserId == null) return [];
    return _feed.where((p) => p.authorId == _currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 활동 기록
  List<Activity> getActivities({int limit = 20}) {
    return _activities.take(limit).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 온라인 친구 수
  int get onlineFriendCount {
    return _friends.where((f) => f.isOnline).length;
  }

  Future<void> _saveData() async {
    if (_currentUserId == null) return;

    final data = {
      'friends': _friends.map((f) => {
        'userId': f.userId,
        'status': f.status.name,
      }).toList(),
      'lastUpdate': DateTime.now().toIso8601String(),
    };

    await _prefs?.setString(
      'social_friends_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _friendController.close();
    _requestController.close();
    _feedController.close();
    _activityController.close();
    _presenceTimer?.cancel();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

enum FriendStatus {
  none,
  pending,
  accepted,
  declined,
  blocked,
}

enum OnlineStatus {
  offline,
  online,
  away,
  busy,
  invisible,
}

class Friend {
  final String userId;
  final String friendId;
  final FriendStatus status;
  final DateTime? addedAt;
  final DateTime? acceptedAt;
  final String? requestedBy;
  final int friendshipLevel;
  final int totalInteractions;
  final DateTime? lastInteraction;

  const Friend({
    required this.userId,
    required this.friendId,
    required this.status,
    this.addedAt,
    this.acceptedAt,
    this.requestedBy,
    required this.friendshipLevel,
    required this.totalInteractions,
    this.lastInteraction,
  });

  bool get isPending => status == FriendStatus.pending;
  bool get isAccepted => status == FriendStatus.accepted;
  bool get isBlocked => status == FriendStatus.blocked;
  bool get isFriend => status == FriendStatus.accepted;
}

class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserAvatar;
  final String toUserId;
  final String message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final FriendStatus status;

  const FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserAvatar,
    required this.toUserId,
    required this.message,
    required this.createdAt,
    this.expiresAt,
    required this.status,
  });

  bool get isPending => status == FriendStatus.pending;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  Duration get timeUntilExpiry {
    if (expiresAt == null) return Duration.zero;
    return expiresAt!.difference(DateTime.now());
  }
}

class UserProfile {
  final String userId;
  final String username;
  final String? avatar;
  final int level;
  final OnlineStatus onlineStatus;
  final DateTime? lastSeen;
  final String? statusMessage;
  final Map<String, dynamic> statistics;
  final List<String> achievements;

  const UserProfile({
    required this.userId,
    required this.username,
    this.avatar,
    required this.level,
    required this.onlineStatus,
    this.lastSeen,
    this.statusMessage,
    required this.statistics,
    required this.achievements,
  });

  bool get isOnline => onlineStatus == OnlineStatus.online;
  bool get isAway => onlineStatus == OnlineStatus.away;
  bool get isBusy => onlineStatus == OnlineStatus.busy;
  bool get isInvisible => onlineStatus == OnlineStatus.invisible;
}

class FriendSuggestion {
  final String userId;
  final String username;
  final String? avatar;
  final double matchScore;
  final List<String> reasons;
  final int mutualFriends;

  const FriendSuggestion({
    required this.userId,
    required this.username,
    this.avatar,
    required this.matchScore,
    required this.reasons,
    required this.mutualFriends,
  });
}

class SocialIntegration {
  final String platformId;
  final String platformUserId;
  final String platformUserName;
  final String? platformAvatar;
  final DateTime connectedAt;

  const SocialIntegration({
    required this.platformId,
    required this.platformUserId,
    required this.platformUserName,
    this.platformAvatar,
    required this.connectedAt,
  });
}

class FriendManager {
  static final FriendManager _instance = FriendManager._();
  static FriendManager get instance => _instance;

  FriendManager._();

  final Map<String, List<Friend>> _friends = {};
  final Map<String, FriendRequest> _friendRequests = {};
  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, Set<String>> _blockedUsers = {};
  final Map<String, List<SocialIntegration>> _socialIntegrations = {};
  final StreamController<FriendEvent> _eventController = StreamController.broadcast();
  Timer? _cleanupTimer;

  Stream<FriendEvent> get onFriendEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadSampleProfiles();
    _startCleanupTimer();
  }

  Future<void> _loadSampleProfiles() async {
    final profiles = [
      UserProfile(
        userId: 'user1',
        username: 'Player1',
        level: 50,
        onlineStatus: OnlineStatus.online,
        lastSeen: DateTime.now(),
        statistics: {'wins': 100, 'losses': 50},
        achievements: ['first_win', 'veteran'],
      ),
      UserProfile(
        userId: 'user2',
        username: 'Player2',
        level: 75,
        onlineStatus: OnlineStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
        statistics: {'wins': 200, 'losses': 100},
        achievements: ['champion', 'strategist'],
      ),
    ];

    for (final profile in profiles) {
      _userProfiles[profile.userId] = profile;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupExpiredRequests(),
    );
  }

  Future<String> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    String message = '',
  }) async {
    if (_areBlocked(fromUserId, toUserId)) {
      throw Exception('Cannot send friend request: blocked');
    }

    if (_areFriends(fromUserId, toUserId)) {
      throw Exception('Already friends');
    }

    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

    final request = FriendRequest(
      requestId: requestId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      message: message,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      status: FriendStatus.pending,
    );

    _friendRequests[requestId] = request;

    _eventController.add(FriendEvent(
      type: FriendEventType.requestSent,
      fromUserId: fromUserId,
      toUserId: toUserId,
      requestId: requestId,
      timestamp: DateTime.now(),
    ));

    return requestId;
  }

  Future<bool> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = _friendRequests[requestId];
    if (request == null) return false;
    if (request.toUserId != userId) return false;
    if (!request.isPending) return false;

    final now = DateTime.now();

    final friend1 = Friend(
      userId: request.fromUserId,
      friendId: request.toUserId,
      status: FriendStatus.accepted,
      addedAt: request.createdAt,
      acceptedAt: now,
      requestedBy: request.fromUserId,
      friendshipLevel: 1,
      totalInteractions: 0,
      lastInteraction: now,
    );

    final friend2 = Friend(
      userId: request.toUserId,
      friendId: request.fromUserId,
      status: FriendStatus.accepted,
      addedAt: request.createdAt,
      acceptedAt: now,
      requestedBy: request.fromUserId,
      friendshipLevel: 1,
      totalInteractions: 0,
      lastInteraction: now,
    );

    _friends.putIfAbsent(request.fromUserId, () => []).add(friend1);
    _friends.putIfAbsent(request.toUserId, () => []).add(friend2);

    _friendRequests.remove(requestId);

    _eventController.add(FriendEvent(
      type: FriendEventType.requestAccepted,
      fromUserId: request.fromUserId,
      toUserId: request.toUserId,
      requestId: requestId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> declineFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = _friendRequests[requestId];
    if (request == null) return false;
    if (request.toUserId != userId) return false;

    _friendRequests.remove(requestId);

    _eventController.add(FriendEvent(
      type: FriendEventType.requestDeclined,
      fromUserId: request.fromUserId,
      toUserId: request.toUserId,
      requestId: requestId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> cancelFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    final request = _friendRequests[requestId];
    if (request == null) return false;
    if (request.fromUserId != userId) return false;

    _friendRequests.remove(requestId);

    _eventController.add(FriendEvent(
      type: FriendEventType.requestCancelled,
      fromUserId: userId,
      toUserId: request.toUserId,
      requestId: requestId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    final friends = _friends[userId];
    if (friends == null) return false;

    final removed = friends.removeWhere((f) => f.friendId == friendId);
    if (removed <= 0) return false;

    final otherFriends = _friends[friendId];
    otherFriends?.removeWhere((f) => f.friendId == userId);

    _eventController.add(FriendEvent(
      type: FriendEventType.friendRemoved,
      fromUserId: userId,
      toUserId: friendId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  void blockUser({
    required String userId,
    required String blockedUserId,
  }) {
    _blockedUsers.putIfAbsent(userId, () => {}).add(blockedUserId);

    removeFriend(userId: userId, friendId: blockedUserId);

    _eventController.add(FriendEvent(
      type: FriendEventType.userBlocked,
      fromUserId: userId,
      toUserId: blockedUserId,
      timestamp: DateTime.now(),
    ));
  }

  void unblockUser({
    required String userId,
    required String blockedUserId,
  }) {
    _blockedUsers[userId]?.remove(blockedUserId);

    _eventController.add(FriendEvent(
      type: FriendEventType.userUnblocked,
      fromUserId: userId,
      toUserId: blockedUserId,
      timestamp: DateTime.now(),
    ));
  }

  bool isBlocked({
    required String userId,
    required String targetUserId,
  }) {
    return _blockedUsers[userId]?.contains(targetUserId) ?? false;
  }

  List<String> getBlockedUsers(String userId) {
    return _blockedUsers[userId]?.toList() ?? [];
  }

  List<Friend> getFriends(String userId) {
    return _friends[userId] ?? [];
  }

  List<Friend> getOnlineFriends(String userId) {
    final friends = getFriends(userId);
    final onlineIds = friends.where((f) => f.isAccepted).map((f) => f.friendId).toSet();

    return _userProfiles.values
        .where((profile) =>
            onlineIds.contains(profile.userId) &&
            profile.isOnline)
        .map((profile) => friends.firstWhere((f) => f.friendId == profile.userId))
        .toList();
  }

  List<FriendRequest> getPendingRequests(String userId) {
    return _friendRequests.values
        .where((req) => req.toUserId == userId && req.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<FriendRequest> getSentRequests(String userId) {
    return _friendRequests.values
        .where((req) => req.fromUserId == userId && req.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<FriendSuggestion> getFriendSuggestions({
    required String userId,
    int limit = 10,
  }) {
    final suggestions = <FriendSuggestion>[];

    final existingFriends = getFriends(userId).map((f) => f.friendId).toSet();
    final blocked = getBlockedUsers(userId);

    for (final profile in _userProfiles.values) {
      if (profile.userId == userId) continue;
      if (existingFriends.contains(profile.userId)) continue;
      if (blocked.contains(profile.userId)) continue;

      final score = _calculateMatchScore(userId, profile.userId);
      final reasons = _getSuggestionReasons(userId, profile.userId);
      final mutualCount = _getMutualFriendsCount(userId, profile.userId);

      suggestions.add(FriendSuggestion(
        userId: profile.userId,
        username: profile.username,
        avatar: profile.avatar,
        matchScore: score,
        reasons: reasons,
        mutualFriends: mutualCount,
      ));
    }

    suggestions.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return suggestions.take(limit).toList();
  }

  double _calculateMatchScore(String userId1, String userId2) {
    double score = 0.0;

    final profile1 = _userProfiles[userId1];
    final profile2 = _userProfiles[userId2];

    if (profile1 != null && profile2 != null) {
      final levelDiff = (profile1.level - profile2.level).abs();
      score += (1.0 - (levelDiff / 100.0)) * 0.3;

      final sharedAchievements = profile1.achievements
          .toSet()
          .intersection(profile2.achievements.toSet())
          .length;
      score += (sharedAchievements / 10.0) * 0.4;
    }

    final mutualCount = _getMutualFriendsCount(userId1, userId2);
    score += (mutualCount / 5.0) * 0.3;

    return score.clamp(0.0, 1.0);
  }

  List<String> _getSuggestionReasons(String userId1, String userId2) {
    final reasons = <String>[];

    final mutualCount = _getMutualFriendsCount(userId1, userId2);
    if (mutualCount > 0) {
      reasons.add('$mutualCount mutual friends');
    }

    final profile1 = _userProfiles[userId1];
    final profile2 = _userProfiles[userId2];

    if (profile1 != null && profile2 != null) {
      final sharedAchievements = profile1.achievements
          .toSet()
          .intersection(profile2.achievements.toSet());
      if (sharedAchievements.isNotEmpty) {
        reasons.add('Similar achievements');
      }

      if ((profile1.level - profile2.level).abs() <= 10) {
        reasons.add('Similar level');
      }
    }

    if (reasons.isEmpty) {
      reasons.add('Popular player');
    }

    return reasons;
  }

  int _getMutualFriendsCount(String userId1, String userId2) {
    final friends1 = getFriends(userId1).where((f) => f.isAccepted).map((f) => f.friendId).toSet();
    final friends2 = getFriends(userId2).where((f) => f.isAccepted).map((f) => f.friendId).toSet();
    return friends1.intersection(friends2).length;
  }

  void updateUserProfile(UserProfile profile) {
    _userProfiles[profile.userId] = profile;

    _eventController.add(FriendEvent(
      type: FriendEventType.profileUpdated,
      fromUserId: profile.userId,
      timestamp: DateTime.now(),
    ));
  }

  UserProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }

  List<UserProfile> getUserProfiles(List<String> userIds) {
    return userIds.map((id) => _userProfiles[id]).whereType<UserProfile>().toList();
  }

  void setOnlineStatus({
    required String userId,
    required OnlineStatus status,
  }) {
    final profile = _userProfiles[userId];
    if (profile != null) {
      final updated = UserProfile(
        userId: profile.userId,
        username: profile.username,
        avatar: profile.avatar,
        level: profile.level,
        onlineStatus: status,
        lastSeen: status == OnlineStatus.offline ? DateTime.now() : profile.lastSeen,
        statusMessage: profile.statusMessage,
        statistics: profile.statistics,
        achievements: profile.achievements,
      );

      _userProfiles[userId] = updated;

      _eventController.add(FriendEvent(
        type: FriendEventType.statusChanged,
        fromUserId: userId,
        timestamp: DateTime.now(),
        data: {'status': status.toString()},
      ));
    }
  }

  void connectSocialAccount({
    required String userId,
    required String platformId,
    required String platformUserId,
    required String platformUserName,
  }) {
    _socialIntegrations.putIfAbsent(userId, () => []);

    _socialIntegrations[userId]!.add(SocialIntegration(
      platformId: platformId,
      platformUserId: platformUserId,
      platformUserName: platformUserName,
      connectedAt: DateTime.now(),
    ));

    _eventController.add(FriendEvent(
      type: FriendEventType.socialConnected,
      fromUserId: userId,
      timestamp: DateTime.now(),
      data: {'platform': platformId},
    ));
  }

  List<SocialIntegration> getSocialIntegrations(String userId) {
    return _socialIntegrations[userId] ?? [];
  }

  Future<List<UserProfile>> findFriendsFromSocial({
    required String userId,
    required String platformId,
  }) async {
    final integrations = _socialIntegrations[userId];
    if (integrations == null) return [];

    final platformIntegration = integrations
        .where((i) => i.platformId == platformId)
        .toList();

    if (platformIntegration.isEmpty) return [];

    await Future.delayed(const Duration(milliseconds: 500));

    return _userProfiles.values.toList();
  }

  bool _areBlocked(String userId1, String userId2) {
    return isBlocked(userId: userId1, targetUserId: userId2) ||
           isBlocked(userId: userId2, targetUserId: userId1);
  }

  bool _areFriends(String userId1, String userId2) {
    final friends1 = getFriends(userId1);
    return friends1.any((f) => f.friendId == userId2 && f.isAccepted);
  }

  void _cleanupExpiredRequests() {
    final expired = _friendRequests.values
        .where((req) => req.isExpired)
        .toList();

    for (final req in expired) {
      _friendRequests.remove(req.requestId);

      _eventController.add(FriendEvent(
        type: FriendEventType.requestExpired,
        fromUserId: req.fromUserId,
        toUserId: req.toUserId,
        requestId: req.requestId,
        timestamp: DateTime.now(),
      ));
    }
  }

  Map<String, dynamic> getFriendStats(String userId) {
    final friends = getFriends(userId);
    final acceptedFriends = friends.where((f) => f.isAccepted).length;
    final pendingRequests = getPendingRequests(userId).length;
    final sentRequests = getSentRequests(userId).length;
    final blockedCount = getBlockedUsers(userId).length;

    return {
      'totalFriends': friends.length,
      'acceptedFriends': acceptedFriends,
      'pendingRequests': pendingRequests,
      'sentRequests': sentRequests,
      'blockedUsers': blockedCount,
      'onlineFriends': getOnlineFriends(userId).length,
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();
  }
}

class FriendEvent {
  final FriendEventType type;
  final String? fromUserId;
  final String? toUserId;
  final String? requestId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const FriendEvent({
    required this.type,
    this.fromUserId,
    this.toUserId,
    this.requestId,
    required this.timestamp,
    this.data,
  });
}

enum FriendEventType {
  requestSent,
  requestAccepted,
  requestDeclined,
  requestCancelled,
  requestExpired,
  friendRemoved,
  userBlocked,
  userUnblocked,
  profileUpdated,
  statusChanged,
  socialConnected,
  socialDisconnected,
}

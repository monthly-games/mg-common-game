import 'package:flutter/foundation.dart';
import 'social_types.dart';

/// Social System Manager
/// Manages friends, guilds, raids, and leaderboards
class SocialManager extends ChangeNotifier {
  // Friends
  final Map<String, Friend> _friends = {};
  final List<String> _pendingRequests = [];

  // Guild
  Guild? _currentGuild;

  // Raids
  final Map<String, RaidBoss> _activeRaids = {};
  final Map<String, int> _playerRaidDamage = {};

  // Leaderboards cache
  final Map<String, List<LeaderboardEntry>> _leaderboardCache = {};

  // Callbacks for backend integration
  Future<bool> Function(String odId)? onSendFriendRequest;
  Future<bool> Function(String odId)? onAcceptFriendRequest;
  Future<bool> Function(String odId)? onRemoveFriend;
  Future<Guild?> Function(String name)? onCreateGuild;
  Future<bool> Function(String guildId)? onJoinGuild;
  Future<bool> Function()? onLeaveGuild;
  Future<List<LeaderboardEntry>> Function(LeaderboardType type, {int limit})? onFetchLeaderboard;
  Future<bool> Function(String odId, int damage)? onSubmitRaidDamage;

  // === Friends ===

  List<Friend> get friends => _friends.values.toList();
  List<Friend> get onlineFriends => friends.where((f) => f.isOnline).toList();
  List<String> get pendingRequests => List.unmodifiable(_pendingRequests);
  int get friendCount => _friends.length;

  /// Send friend request
  Future<bool> sendFriendRequest(String odId) async {
    if (onSendFriendRequest != null) {
      final success = await onSendFriendRequest!(odId);
      if (success) {
        _friends[odId] = Friend(
          id: odId,
          name: 'User $odId',
          status: FriendStatus.pending,
        );
        notifyListeners();
      }
      return success;
    }
    return false;
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String odId) async {
    if (onAcceptFriendRequest != null) {
      final success = await onAcceptFriendRequest!(odId);
      if (success) {
        _pendingRequests.remove(odId);
        if (_friends.containsKey(odId)) {
          _friends[odId] = _friends[odId]!.copyWith(status: FriendStatus.accepted);
        }
        notifyListeners();
      }
      return success;
    }
    return false;
  }

  /// Remove friend
  Future<bool> removeFriend(String odId) async {
    if (onRemoveFriend != null) {
      final success = await onRemoveFriend!(odId);
      if (success) {
        _friends.remove(odId);
        notifyListeners();
      }
      return success;
    }
    _friends.remove(odId);
    notifyListeners();
    return true;
  }

  /// Check if user is friend
  bool isFriend(String odId) => _friends.containsKey(odId) &&
      _friends[odId]!.status == FriendStatus.accepted;

  /// Update friend from server data
  void updateFriend(Friend friend) {
    _friends[friend.id] = friend;
    notifyListeners();
  }

  /// Add pending request
  void addPendingRequest(String odId) {
    if (!_pendingRequests.contains(odId)) {
      _pendingRequests.add(odId);
      notifyListeners();
    }
  }

  // === Guild ===

  Guild? get currentGuild => _currentGuild;
  bool get hasGuild => _currentGuild != null;
  bool get isGuildLeader => _currentGuild?.leader?.id == _playerId;
  String? _playerId;

  /// Set current player ID
  void setPlayerId(String id) {
    _playerId = id;
  }

  /// Create a new guild
  Future<bool> createGuild(String name, {String? description}) async {
    if (onCreateGuild != null) {
      final guild = await onCreateGuild!(name);
      if (guild != null) {
        _currentGuild = guild;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// Join a guild
  Future<bool> joinGuild(String guildId) async {
    if (onJoinGuild != null) {
      final success = await onJoinGuild!(guildId);
      if (success) {
        notifyListeners();
      }
      return success;
    }
    return false;
  }

  /// Leave current guild
  Future<bool> leaveGuild() async {
    if (onLeaveGuild != null) {
      final success = await onLeaveGuild!();
      if (success) {
        _currentGuild = null;
        notifyListeners();
      }
      return success;
    }
    _currentGuild = null;
    notifyListeners();
    return true;
  }

  /// Update guild from server data
  void updateGuild(Guild guild) {
    _currentGuild = guild;
    notifyListeners();
  }

  /// Get member by role
  List<GuildMember> getMembersByRole(GuildRole role) {
    return _currentGuild?.members.where((m) => m.role == role).toList() ?? [];
  }

  // === Raids ===

  List<RaidBoss> get activeRaids => _activeRaids.values.where((r) => r.isActive).toList();

  /// Register an active raid
  void registerRaid(RaidBoss raid) {
    _activeRaids[raid.id] = raid;
    notifyListeners();
  }

  /// Get player's damage contribution to a raid
  int getPlayerRaidDamage(String odId) => _playerRaidDamage[odId] ?? 0;

  /// Submit damage to raid boss
  Future<bool> submitRaidDamage(String odId, int damage) async {
    if (onSubmitRaidDamage != null) {
      final success = await onSubmitRaidDamage!(odId, damage);
      if (success) {
        _playerRaidDamage[odId] = (getPlayerRaidDamage(odId)) + damage;
        if (_activeRaids.containsKey(odId)) {
          _activeRaids[odId] = _activeRaids[odId]!.takeDamage(damage);
        }
        notifyListeners();
      }
      return success;
    }

    // Local only mode
    _playerRaidDamage[odId] = (getPlayerRaidDamage(odId)) + damage;
    if (_activeRaids.containsKey(odId)) {
      _activeRaids[odId] = _activeRaids[odId]!.takeDamage(damage);
    }
    notifyListeners();
    return true;
  }

  /// Update raid from server data
  void updateRaid(RaidBoss raid) {
    _activeRaids[raid.id] = raid;
    notifyListeners();
  }

  /// Remove expired raids
  void cleanupRaids() {
    _activeRaids.removeWhere((_, raid) => !raid.isActive && raid.isDefeated);
    notifyListeners();
  }

  // === Leaderboards ===

  /// Fetch leaderboard
  Future<List<LeaderboardEntry>> fetchLeaderboard(
    LeaderboardType type, {
    int limit = 100,
  }) async {
    if (onFetchLeaderboard != null) {
      final entries = await onFetchLeaderboard!(type, limit: limit);
      _leaderboardCache[type.name] = entries;
      return entries;
    }
    return _leaderboardCache[type.name] ?? [];
  }

  /// Get cached leaderboard
  List<LeaderboardEntry> getCachedLeaderboard(LeaderboardType type) {
    return _leaderboardCache[type.name] ?? [];
  }

  /// Update leaderboard cache
  void updateLeaderboard(LeaderboardType type, List<LeaderboardEntry> entries) {
    _leaderboardCache[type.name] = entries;
    notifyListeners();
  }

  /// Find player rank in leaderboard
  int? getPlayerRank(LeaderboardType type, String odId) {
    final entries = _leaderboardCache[type.name];
    if (entries == null) return null;

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].odId == odId) return entries[i].rank;
    }
    return null;
  }

  // === Persistence ===

  Map<String, dynamic> toJson() {
    return {
      'friends': _friends.map((k, v) => MapEntry(k, v.toJson())),
      'pendingRequests': _pendingRequests,
      'guild': _currentGuild?.toJson(),
      'raidDamage': _playerRaidDamage,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _friends.clear();
    if (json['friends'] != null) {
      final friendsMap = json['friends'] as Map<String, dynamic>;
      for (final entry in friendsMap.entries) {
        _friends[entry.key] = Friend.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    _pendingRequests.clear();
    if (json['pendingRequests'] != null) {
      _pendingRequests.addAll(List<String>.from(json['pendingRequests'] as List));
    }

    if (json['guild'] != null) {
      _currentGuild = Guild.fromJson(json['guild'] as Map<String, dynamic>);
    }

    _playerRaidDamage.clear();
    if (json['raidDamage'] != null) {
      _playerRaidDamage.addAll(Map<String, int>.from(json['raidDamage'] as Map));
    }

    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _friends.clear();
    _pendingRequests.clear();
    _currentGuild = null;
    _activeRaids.clear();
    _playerRaidDamage.clear();
    _leaderboardCache.clear();
    notifyListeners();
  }
}

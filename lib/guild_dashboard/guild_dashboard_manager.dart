import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 길드 역할
enum GuildRole {
  leader,       // 길드장
  coLeader,     // 부길드장
  officer,      // 간부
  veteran,      // 베테랑
  member,       // 일반 회원
  apprentice,   // 수습생
}

/// 길드 가입 상태
enum GuildJoinStatus {
  pending,      // 대기 중
  approved,     // 승인됨
  rejected,     // 거절됨
  kicked,       // 추방됨
}

/// 길드 활동 로그 타입
enum GuildActivityType {
  memberJoined,     // 회원 가입
  memberLeft,       // 회원 탈퇴
  memberPromoted,   // 회원 승진
  memberDemoted,    // 회원 강등
  donation,         // 기부
  warStarted,       // 길드전 시작
  warEnded,         // 길드전 종료
  raidStarted,      // 레이드 시작
  raidEnded,        // 레이드 종료
  announcement,     // 공지사항
  levelUp,          // 레벨 업
}

/// 길드 통계
class GuildStats {
  final int totalMembers;
  final int activeMembers;
  final int totalPoints;
  final int weeklyPoints;
  final int guildLevel;
  final int warWins;
  final int warLosses;
  final int raidClears;
  final DateTime lastUpdated;

  const GuildStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.guildLevel,
    required this.warWins,
    required this.warLosses,
    required this.raidClears,
    required this.lastUpdated,
  });

  double get winRate => warWins + warLosses > 0
      ? warWins / (warWins + warLosses)
      : 0.0;
}

/// 길드 자산
class GuildAssets {
  final int gold;
  final int gems;
  final Map<String, int> items;
  final DateTime lastUpdated;

  const GuildAssets({
    required this.gold,
    required this.gems,
    this.items = const {},
    required this.lastUpdated,
  });

  int getItemCount(String itemId) {
    return items[itemId] ?? 0;
  }
}

/// 길드원 정보
class GuildMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final GuildRole role;
  final int level;
  final int power;
  final int contribution;
  final int weeklyContribution;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final bool isOnline;

  const GuildMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.level,
    required this.power,
    required this.contribution,
    required this.weeklyContribution,
    required this.joinedAt,
    this.lastActiveAt,
    this.isOnline = false,
  });

  /// 기여도 계산
  double get contributionRate => contribution > 0 ? weeklyContribution / contribution : 0.0;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'level': level,
        'power': power,
        'contribution': contribution,
        'weeklyContribution': weeklyContribution,
        'joinedAt': joinedAt.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'isOnline': isOnline,
      };
}

/// 길드 활동 로그
class GuildActivity {
  final String id;
  final GuildActivityType type;
  final String title;
  final String? description;
  final String? actorId;
  final String? actorName;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const GuildActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.actorId,
    this.actorName,
    this.metadata,
    required this.timestamp,
  });
}

/// 길드 공지사항
class GuildAnnouncement {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;
  final List<String> attachments;

  const GuildAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.attachments = const [],
  });
}

/// 길드 투표
class GuildVote {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final List<VoteOption> options;
  final DateTime createdAt;
  final DateTime endsAt;
  final bool isActive;
  final int maxVoters;

  const GuildVote({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.options,
    required this.createdAt,
    required this.endsAt,
    this.isActive = true,
    this.maxVoters = 0,
  });

  /// 투표 참여율
  double get participationRate {
    if (maxVoters == 0) return 0.0;
    final totalVotes = options.fold<int>(0, (sum, option) => sum + option.voteCount);
    return totalVotes / maxVoters;
  }
}

/// 투표 옵션
class VoteOption {
  final String id;
  final String text;
  final int voteCount;
  final List<String> voterIds;

  const VoteOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.voterIds = const [],
  });
}

/// 길드 관리 대시보드
class GuildDashboardManager {
  static final GuildDashboardManager _instance = GuildDashboardManager._();
  static GuildDashboardManager get instance => _instance;

  GuildDashboardManager._();

  SharedPreferences? _prefs;
  String? _currentGuildId;
  String? _currentUserId;

  final Map<String, List<GuildMember>> _guildMembers = {};
  final Map<String, GuildStats> _guildStats = {};
  final Map<String, GuildAssets> _guildAssets = {};
  final Map<String, List<GuildActivity>> _activityLogs = {};
  final Map<String, List<GuildAnnouncement>> _announcements = {};
  final Map<String, List<GuildVote>> _votes = {};
  final Map<String, List<String>> _joinRequests = {};

  final StreamController<GuildMember> _memberController =
      StreamController<GuildMember>.broadcast();
  final StreamController<GuildStats> _statsController =
      StreamController<GuildStats>.broadcast();
  final StreamController<GuildActivity> _activityController =
      StreamController<GuildActivity>.broadcast();
  final StreamController<GuildAnnouncement> _announcementController =
      StreamController<GuildAnnouncement>.broadcast();

  Stream<GuildMember> get onMemberUpdate => _memberController.stream;
  Stream<GuildStats> get onStatsUpdate => _statsController.stream;
  Stream<GuildActivity> get onActivity => _activityController.stream;
  Stream<GuildAnnouncement> get onAnnouncement => _announcementController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentGuildId = _prefs?.getString('guild_id');
    _currentUserId = _prefs?.getString('user_id');

    // 길드 데이터 로드
    if (_currentGuildId != null) {
      await _loadGuildData(_currentGuildId!);
    }

    debugPrint('[GuildDashboard] Initialized');
  }

  Future<void> _loadGuildData(String guildId) async {
    // 회원 목록 로드
    _guildMembers[guildId] = await _loadMembers(guildId);

    // 통계 로드
    _guildStats[guildId] = await _loadStats(guildId);

    // 자산 로드
    _guildAssets[guildId] = await _loadAssets(guildId);

    // 활동 로그 로드
    _activityLogs[guildId] = await _loadActivityLogs(guildId);

    // 공지사항 로드
    _announcements[guildId] = await _loadAnnouncements(guildId);

    // 투표 로드
    _votes[guildId] = await _loadVotes(guildId);
  }

  Future<List<GuildMember>> _loadMembers(String guildId) async {
    // 시뮬레이션
    return [
      GuildMember(
        userId: 'user1',
        username: '길드장1',
        role: GuildRole.leader,
        level: 50,
        power: 100000,
        contribution: 50000,
        weeklyContribution: 5000,
        joinedAt: DateTime.now().subtract(const Duration(days: 100)),
        lastActiveAt: DateTime.now(),
        isOnline: true,
      ),
      GuildMember(
        userId: 'user2',
        username: '부길드장1',
        role: GuildRole.coLeader,
        level: 45,
        power: 90000,
        contribution: 40000,
        weeklyContribution: 4000,
        joinedAt: DateTime.now().subtract(const Duration(days: 90)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 1)),
        isOnline: false,
      ),
    ];
  }

  Future<GuildStats> _loadStats(String guildId) async {
    return const GuildStats(
      totalMembers: 50,
      activeMembers: 35,
      totalPoints: 1000000,
      weeklyPoints: 50000,
      guildLevel: 25,
      warWins: 15,
      warLosses: 5,
      raidClears: 30,
      lastUpdated: null,
    );
  }

  Future<GuildAssets> _loadAssets(String guildId) async {
    return const GuildAssets(
      gold: 1000000,
      gems: 50000,
      items: {
        'item_1': 100,
        'item_2': 50,
      },
      lastUpdated: null,
    );
  }

  Future<List<GuildActivity>> _loadActivityLogs(String guildId) async {
    return [
      GuildActivity(
        id: 'act_1',
        type: GuildActivityType.memberJoined,
        title: '새로운 회원 가입',
        description: '유저1님이 길드에 가입했습니다.',
        actorId: 'user1',
        actorName: '유저1',
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<List<GuildAnnouncement>> _loadAnnouncements(String guildId) async {
    return [
      GuildAnnouncement(
        id: 'anno_1',
        title: '길드전 일정 안내',
        content: '이번 주 길드전은 토요일 오후 3시입니다.',
        authorId: 'user1',
        authorName: '길드장1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: true,
      ),
    ];
  }

  Future<List<GuildVote>> _loadVotes(String guildId) async {
    return [
      GuildVote(
        id: 'vote_1',
        title: '길드전 참여 시간',
        description: '이번 주 길드전 참여 시간을 투표해주세요.',
        creatorId: 'user1',
        options: [
          const VoteOption(id: 'opt_1', text: '토요일 오후 1시', voteCount: 10),
          const VoteOption(id: 'opt_2', text: '토요일 오후 3시', voteCount: 15),
          const VoteOption(id: 'opt_3', text: '일요일 오후 2시', voteCount: 5),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        endsAt: DateTime.now().add(const Duration(days: 1)),
        isActive: true,
        maxVoters: 30,
      ),
    ];
  }

  /// 회원 관리
  Future<void> addMember({
    required String guildId,
    required String userId,
    required String username,
    GuildRole role = GuildRole.apprentice,
  }) async {
    final member = GuildMember(
      userId: userId,
      username: username,
      role: role,
      level: 1,
      power: 0,
      contribution: 0,
      weeklyContribution: 0,
      joinedAt: DateTime.now(),
      isOnline: true,
    );

    _guildMembers[guildId]!.add(member);
    _memberController.add(member);

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.memberJoined,
      title: '새로운 회원 가입',
      description: '$username님이 길드에 가입했습니다.',
      actorId: userId,
      actorName: username,
    );

    debugPrint('[GuildDashboard] Member added: $username');
  }

  Future<void> removeMember({
    required String guildId,
    required String userId,
    String? reason,
  }) async {
    final members = _guildMembers[guildId];
    if (members == null) return;

    final memberIndex = members.indexWhere((m) => m.userId == userId);
    if (memberIndex == -1) return;

    final member = members[memberIndex];

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.memberLeft,
      title: '회원 탈퇴',
      description: '${member.username}님이 길드에서 탈퇴했습니다.',
      actorId: userId,
      actorName: member.username,
      metadata: {'reason': reason},
    );

    members.removeAt(memberIndex);
    _memberController.add(member);

    debugPrint('[GuildDashboard] Member removed: ${member.username}');
  }

  Future<void> promoteMember({
    required String guildId,
    required String userId,
    required GuildRole newRole,
  }) async {
    final members = _guildMembers[guildId];
    if (members == null) return;

    final memberIndex = members.indexWhere((m) => m.userId == userId);
    if (memberIndex == -1) return;

    final member = members[memberIndex];
    final oldRole = member.role;

    final updatedMember = GuildMember(
      userId: member.userId,
      username: member.username,
      avatarUrl: member.avatarUrl,
      role: newRole,
      level: member.level,
      power: member.power,
      contribution: member.contribution,
      weeklyContribution: member.weeklyContribution,
      joinedAt: member.joinedAt,
      lastActiveAt: member.lastActiveAt,
      isOnline: member.isOnline,
    );

    members[memberIndex] = updatedMember;
    _memberController.add(updatedMember);

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.memberPromoted,
      title: '회원 승진',
      description: '${member.username}님이 ${oldRole.name}에서 ${newRole.name}으로 승진했습니다.',
      actorId: userId,
      actorName: member.username,
    );

    debugPrint('[GuildDashboard] Member promoted: ${member.username} -> ${newRole.name}');
  }

  Future<void> kickMember({
    required String guildId,
    required String userId,
    required String reason,
  }) async {
    final members = _guildMembers[guildId];
    if (members == null) return;

    final memberIndex = members.indexWhere((m) => m.userId == userId);
    if (memberIndex == -1) return;

    final member = members[memberIndex];
    members.removeAt(memberIndex);

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.memberLeft,
      title: '회원 추방',
      description: '${member.username}님이 추방되었습니다. 사유: $reason',
      actorId: _currentUserId,
      actorName: '운영진',
    );

    debugPrint('[GuildDashboard] Member kicked: ${member.username}');
  }

  /// 가입 요청 처리
  Future<void) requestJoin({
    required String guildId,
    required String userId,
    required String username,
    String? message,
  }) async {
    final requests = _joinRequests[guildId] ?? [];
    requests.add(userId);
    _joinRequests[guildId] = requests;

    debugPrint('[GuildDashboard] Join request: $username -> $guildId');
  }

  Future<void> acceptJoinRequest({
    required String guildId,
    required String userId,
    required String username,
  }) async {
    final requests = _joinRequests[guildId];
    if (requests == null) return;

    requests.remove(userId);
    await addMember(guildId: guildId, userId: userId, username: username);

    debugPrint('[GuildDashboard] Join request accepted: $username');
  }

  Future<void> rejectJoinRequest({
    required String guildId,
    required String userId,
    required String reason,
  }) async {
    final requests = _joinRequests[guildId];
    if (requests == null) return;

    requests.remove(userId);

    debugPrint('[GuildDashboard] Join request rejected: $userId');
  }

  /// 공지사항 관리
  Future<void> createAnnouncement({
    required String guildId,
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    final announcement = GuildAnnouncement(
      id: 'anno_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      authorId: _currentUserId!,
      authorName: '운영진',
      createdAt: DateTime.now(),
      isPinned: isPinned,
    );

    final announcements = _announcements[guildId] ?? [];
    announcements.insert(0, announcement);
    _announcements[guildId] = announcements;

    _announcementController.add(announcement);

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.announcement,
      title: '새로운 공지사항',
      description: title,
      actorId: _currentUserId,
      actorName: '운영진',
    );

    debugPrint('[GuildDashboard] Announcement created: $title');
  }

  Future<void> updateAnnouncement({
    required String guildId,
    required String announcementId,
    String? title,
    String? content,
    bool? isPinned,
  }) async {
    final announcements = _announcements[guildId];
    if (announcements == null) return;

    final index = announcements.indexWhere((a) => a.id == announcementId);
    if (index == -1) return;

    final updated = GuildAnnouncement(
      id: announcements[index].id,
      title: title ?? announcements[index].title,
      content: content ?? announcements[index].content,
      authorId: announcements[index].authorId,
      authorName: announcements[index].authorName,
      createdAt: announcements[index].createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? announcements[index].isPinned,
      attachments: announcements[index].attachments,
    );

    announcements[index] = updated;
    _announcementController.add(updated);

    debugPrint('[GuildDashboard] Announcement updated: $announcementId');
  }

  Future<void> deleteAnnouncement({
    required String guildId,
    required String announcementId,
  }) async {
    final announcements = _announcements[guildId];
    if (announcements == null) return;

    announcements.removeWhere((a) => a.id == announcementId);

    debugPrint('[GuildDashboard] Announcement deleted: $announcementId');
  }

  /// 투표 관리
  Future<void> createVote({
    required String guildId,
    required String title,
    required String description,
    required List<String> options,
    required Duration duration,
  }) async {
    final vote = GuildVote(
      id: 'vote_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      creatorId: _currentUserId!,
      options: options.asMap().entries.map((entry) {
        return VoteOption(
          id: 'opt_${entry.key}',
          text: entry.value,
        );
      }).toList(),
      createdAt: DateTime.now(),
      endsAt: DateTime.now().add(duration),
      isActive: true,
    );

    final votes = _votes[guildId] ?? [];
    votes.add(vote);
    _votes[guildId] = votes;

    // 활동 로그 추가
    await addActivity(
      guildId: guildId,
      type: GuildActivityType.announcement,
      title: '새로운 투표',
      description: title,
      actorId: _currentUserId,
      actorName: '운영진',
    );

    debugPrint('[GuildDashboard] Vote created: $title');
  }

  Future<void> castVote({
    required String guildId,
    required String voteId,
    required String optionId,
  }) async {
    final votes = _votes[guildId];
    if (votes == null) return;

    final voteIndex = votes.indexWhere((v) => v.id == voteId);
    if (voteIndex == -1) return;

    final vote = votes[voteIndex];
    final optionIndex = vote.options.indexWhere((o) => o.id == optionId);
    if (optionIndex == -1) return;

    final option = vote.options[optionIndex];
    final updatedOption = VoteOption(
      id: option.id,
      text: option.text,
      voteCount: option.voteCount + 1,
      voterIds: [...option.voterIds, _currentUserId!],
    );

    final updatedOptions = List<VoteOption>.from(vote.options);
    updatedOptions[optionIndex] = updatedOption;

    final updatedVote = GuildVote(
      id: vote.id,
      title: vote.title,
      description: vote.description,
      creatorId: vote.creatorId,
      options: updatedOptions,
      createdAt: vote.createdAt,
      endsAt: vote.endsAt,
      isActive: vote.isActive,
      maxVoters: vote.maxVoters + 1,
    );

    votes[voteIndex] = updatedVote;

    debugPrint('[GuildDashboard] Vote cast: $optionId');
  }

  /// 활동 로그 추가
  Future<void> addActivity({
    required String guildId,
    required GuildActivityType type,
    required String title,
    String? description,
    String? actorId,
    String? actorName,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = GuildActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      actorId: actorId,
      actorName: actorName,
      metadata: metadata,
      timestamp: DateTime.now(),
    );

    final activities = _activityLogs[guildId] ?? [];
    activities.insert(0, activity);

    // 최대 1000개만 유지
    if (activities.length > 1000) {
      activities.removeRange(1000, activities.length);
    }

    _activityLogs[guildId] = activities;
    _activityController.add(activity);

    debugPrint('[GuildDashboard] Activity added: $title');
  }

  /// 데이터 조회
  List<GuildMember> getMembers(String guildId) {
    return _guildMembers[guildId] ?? [];
  }

  GuildStats? getStats(String guildId) {
    return _guildStats[guildId];
  }

  GuildAssets? getAssets(String guildId) {
    return _guildAssets[guildId];
  }

  List<GuildActivity> getActivityLogs(String guildId, {int limit = 100}) {
    final activities = _activityLogs[guildId] ?? [];
    return activities.take(limit).toList();
  }

  List<GuildAnnouncement> getAnnouncements(String guildId) {
    final announcements = _announcements[guildId] ?? [];
    announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return announcements;
  }

  List<GuildVote> getVotes(String guildId) {
    final votes = _votes[guildId] ?? [];
    return votes.where((v) => v.isActive).toList();
  }

  List<String> getJoinRequests(String guildId) {
    return _joinRequests[guildId] ?? [];
  }

  /// 길드 설정
  Future<void> updateGuildSettings({
    required String guildId,
    String? name,
    String? description,
    String? emblemUrl,
    Map<String, dynamic>? settings,
  }) async {
    debugPrint('[GuildDashboard] Guild settings updated: $guildId');
  }

  /// 현재 길드 설정
  void setCurrentGuild(String guildId) {
    _currentGuildId = guildId;
    _prefs?.setString('guild_id', guildId);
  }

  void dispose() {
    _memberController.close();
    _statsController.close();
    _activityController.close();
    _announcementController.close();
  }
}

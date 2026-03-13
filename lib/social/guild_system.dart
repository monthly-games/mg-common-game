import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 길드 역할
enum GuildRole {
  master,      // 길드장
  officer,     // 부길드장
  member,      // 길드원
  applicant,   // 가입 신청자
}

/// 길드 상태
enum GuildStatus {
  active,
  disbanded,
  suspended,
  merged,
}

/// 길드 정보
class Guild {
  final String id;
  final String name;
  final String description;
  final String emblemUrl;
  final int level;
  final int exp;
  final int maxMembers;
  final List<GuildMember> members;
  final GuildStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> settings;

  const Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.emblemUrl,
    required this.level,
    required this.exp,
    required this.maxMembers,
    required this.members,
    required this.status,
    required this.createdAt,
    this.settings = const {},
  });

  /// 길드장
  GuildMember? get master => members.firstWhere(
    (m) => m.role == GuildRole.master,
    orElse: () => members.first,
  );

  /// 현재 멤버 수
  int get currentMemberCount => members.length;

  /// 남은 슬롯
  int get availableSlots => maxMembers - currentMemberCount;

  /// 다음 레벨까지 필요 경험치
  int get expToNextLevel => _getRequiredExp(level + 1) - exp;

  static int _getRequiredExp(int level) => level * level * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emblemUrl': emblemUrl,
        'level': level,
        'exp': exp,
        'maxMembers': maxMembers,
        'members': members.map((m) => m.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'settings': settings,
      };

  factory Guild.fromJson(Map<String, dynamic> json) => Guild(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        emblemUrl: json['emblemUrl'] as String,
        level: json['level'] as int,
        exp: json['exp'] as int,
        maxMembers: json['maxMembers'] as int,
        members: (json['members'] as List)
            .map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        status: GuildStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GuildStatus.active,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        settings: json['settings'] as Map<String, dynamic>? ?? {},
      );
}

/// 길드 멤버
class GuildMember {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final GuildRole role;
  final int contribution;
  final DateTime joinedAt;
  final int lastLoginTime; // 타임스탬프

  const GuildMember({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.role,
    required this.contribution,
    required this.joinedAt,
    required this.lastLoginTime,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'contribution': contribution,
        'joinedAt': joinedAt.toIso8601String(),
        'lastLoginTime': lastLoginTime,
      };

  factory GuildMember.fromJson(Map<String, dynamic> json) => GuildMember(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: GuildRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => GuildRole.member,
        ),
        contribution: json['contribution'] as int,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        lastLoginTime: json['lastLoginTime'] as int,
  );
}

/// 길드 전 정보
class GuildWar {
  final String id;
  final String guildId1;
  final String guildId2;
  final DateTime startTime;
  final DateTime endTime;
  final int score1;
  final int score2;
  final String? winnerGuildId;
  final GuildWarStatus status;

  const GuildWar({
    required this.id,
    required this.guildId1,
    required this.guildId2,
    required this.startTime,
    required this.endTime,
    required this.score1,
    required this.score2,
    this.winnerGuildId,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'guildId1': guildId1,
        'guildId2': guildId2,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'score1': score1,
        'score2': score2,
        'winnerGuildId': winnerGuildId,
        'status': status.name,
      };

  factory GuildWar.fromJson(Map<String, dynamic> json) => GuildWar(
        id: json['id'] as String,
        guildId1: json['guildId1'] as String,
        guildId2: json['guildId2'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        score1: json['score1'] as int,
        score2: json['score2'] as int,
        winnerGuildId: json['winnerGuildId'] as String?,
        status: GuildWarStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GuildWarStatus.scheduled,
        ),
  );
}

/// 길드 전 상태
enum GuildWarStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

/// 길드 시스템 매니저
class GuildManager {
  static final GuildManager _instance = GuildManager._();
  static GuildManager get instance => _instance;

  GuildManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, Guild> _guilds = {};
  final Map<String, String> _userGuildMap = {}; // userId -> guildId
  final Map<String, GuildWar> _wars = {};

  final StreamController<Guild> _guildController =
      StreamController<Guild>.broadcast();
  final StreamController<GuildWar> _warController =
      StreamController<GuildWar>.broadcast();
  final StreamController<List<Guild>> _searchController =
      StreamController<List<Guild>>.broadcast();

  // Getters
  Stream<Guild> get onGuildUpdate => _guildController.stream;
  Stream<GuildWar> get onWarUpdate => _warController.stream;
  Stream<List<Guild>> get onSearchResult => _searchController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 데이터 로드
    await _loadGuilds();
    await _loadUserGuildMap();
    await _loadWars();

    debugPrint('[Guild] Initialized');
  }

  Future<void> _loadGuilds() async {
    final guildsJson = _prefs!.getStringList('guilds');
    if (guildsJson != null) {
      for (final json in guildsJson) {
        final guild = Guild.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _guilds[guild.id] = guild;
      }
    }
  }

  Future<void> _loadUserGuildMap() async {
    final mapJson = _prefs!.getString('user_guild_map');
    if (mapJson != null) {
      final json = jsonDecode(mapJson) as Map<String, dynamic>;
      _userGuildMap.addEntries(
        json.entries.map((e) => MapEntry(e.key, e.value as String))
      );
    }
  }

  Future<void> _loadWars() async {
    final warsJson = _prefs!.getStringList('guild_wars');
    if (warsJson != null) {
      for (final json in warsJson) {
        final war = GuildWar.fromJson(jsonDecode(json) as Map<String, dynamic>);
        _wars[war.id] = war;
      }
    }
  }

  // ============================================
  // 길드 관리
  // ============================================

  /// 길드 생성
  Future<Guild?> createGuild({
    required String userId,
    required String name,
    required String description,
    required String emblemUrl,
  }) async {
    if (_userGuildMap.containsKey(userId)) {
      debugPrint('[Guild] User already in a guild');
      return null;
    }

    final guildId = 'guild_${DateTime.now().millisecondsSinceEpoch}';

    final guild = Guild(
      id: guildId,
      name: name,
      description: description,
      emblemUrl: emblemUrl,
      level: 1,
      exp: 0,
      maxMembers: 20,
      members: [
        GuildMember(
          userId: userId,
          nickname: 'Master', // 실제 닉네임으로 대체
          role: GuildRole.master,
          contribution: 0,
          joinedAt: DateTime.now(),
          lastLoginTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ],
      status: GuildStatus.active,
      createdAt: DateTime.now(),
    );

    _guilds[guildId] = guild;
    _userGuildMap[userId] = guildId;

    await _saveGuilds();
    await _saveUserGuildMap();

    _guildController.add(guild);

    // 애널리틱스
    await AnalyticsManager.instance.logEvent('guild_created', parameters: {
      'guild_id': guildId,
      'guild_name': name,
    });

    debugPrint('[Guild] Created: $name');
    return guild;
  }

  /// 길드 가입 신청
  Future<bool> applyToGuild({
    required String userId,
    required String guildId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) {
      debugPrint('[Guild] Guild not found: $guildId');
      return false;
    }

    if (guild.availableSlots <= 0) {
      debugPrint('[Guild] Guild is full');
      return false;
    }

    // 신청자 목록에 추가
    final applicant = GuildMember(
      userId: userId,
      nickname: 'Applicant',
      role: GuildRole.applicant,
      contribution: 0,
      joinedAt: DateTime.now(),
      lastLoginTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final updatedMembers = [...guild.members, applicant];
    _guilds[guildId] = Guild(
      id: guild.id,
      name: guild.name,
      description: guild.description,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: updatedMembers,
      status: guild.status,
      createdAt: guild.createdAt,
      settings: guild.settings,
    );

    await _saveGuilds();

    // 알림 전송
    await _notifyGuildOfficers(guildId, '$userId님이 가입을 신청했습니다');

    debugPrint('[Guild] Applied to: ${guild.name}');
    return true;
  }

  /// 가입 승인
  Future<bool> approveApplication({
    required String guildId,
    required String userId,
    required String approverId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;

    // 권한 확인
    final approver = guild.members.firstWhere((m) => m.userId == approverId);
    if (approver.role == GuildRole.member ||
        approver.role == GuildRole.applicant) {
      return false;
    }

    // 신청자 찾기
    final applicantIndex = guild.members.indexWhere(
      (m) => m.userId == userId && m.role == GuildRole.applicant,
    );

    if (applicantIndex == -1) return false;

    // 멤버로 승격
    final applicant = guild.members[applicantIndex];
    final approvedMember = GuildMember(
      userId: applicant.userId,
      nickname: applicant.nickname,
      avatarUrl: applicant.avatarUrl,
      role: GuildRole.member,
      contribution: 0,
      joinedAt: DateTime.now(),
      lastLoginTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final updatedMembers = List<GuildMember>.from(guild.members)
      ..removeAt(applicantIndex)
      ..add(approvedMember);

    _guilds[guildId] = Guild(
      id: guild.id,
      name: guild.name,
      description: guild.description,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: updatedMembers,
      status: guild.status,
      createdAt: guild.createdAt,
      settings: guild.settings,
    );

    _userGuildMap[userId] = guildId;

    await _saveGuilds();
    await _saveUserGuildMap();

    _guildController.add(_guilds[guildId]!);

    debugPrint('[Guild] Approved: $userId');
    return true;
  }

  /// 길드 탈퇴
  Future<bool> leaveGuild({
    required String userId,
    String? reason,
  }) async {
    final guildId = _userGuildMap[userId];
    if (guildId == null) return false;

    final guild = _guilds[guildId];
    if (guild == null) return false;

    final member = guild.members.firstWhere((m) => m.userId == userId);

    // 길드장은 탈퇴 불가 (길드 해체만 가능)
    if (member.role == GuildRole.master) {
      debugPrint('[Guild] Master cannot leave');
      return false;
    }

    // 멤버 제거
    final updatedMembers = guild.members.where((m) => m.userId != userId).toList();

    _guilds[guildId] = Guild(
      id: guild.id,
      name: guild.name,
      description: guild.description,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: updatedMembers,
      status: guild.status,
      createdAt: guild.createdAt,
      settings: guild.settings,
    );

    _userGuildMap.remove(userId);

    await _saveGuilds();
    await _saveUserGuildMap();

    _guildController.add(_guilds[guildId]!);

    debugPrint('[Guild] Left: ${guild.name}');
    return true;
  }

  /// 길드 해체
  Future<bool> disbandGuild({
    required String guildId,
    required String userId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;

    final master = guild.master;
    if (master == null || master.userId != userId) {
      debugPrint('[Guild] Only master can disband');
      return false;
    }

    // 길드 상태 변경
    _guilds[guildId] = Guild(
      id: guild.id,
      name: guild.name,
      description: guild.description,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: guild.members,
      status: GuildStatus.disbanded,
      createdAt: guild.createdAt,
      settings: guild.settings,
    );

    // 모든 멤버의 맵 제거
    for (final member in guild.members) {
      _userGuildMap.remove(member.userId);
    }

    await _saveGuilds();
    await _saveUserGuildMap();

    debugPrint('[Guild] Disbanded: ${guild.name}');
    return true;
  }

  /// 길드 검색
  Future<List<Guild>> searchGuilds({
    String? query,
    int? minLevel,
    bool? onlyRecruiting,
  }) async {
    var results = _guilds.values.where((g) =>
      g.status == GuildStatus.active &&
      g.availableSlots > 0
    ).toList();

    if (query != null && query.isNotEmpty) {
      results = results.where((g) =>
        g.name.toLowerCase().contains(query.toLowerCase()) ||
        g.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (minLevel != null) {
      results = results.where((g) => g.level >= minLevel).toList();
    }

    results.sort((a, b) => b.level.compareTo(a.level));

    _searchController.add(results);

    return results;
  }

  /// 사용자의 길드 가져오기
  Guild? getUserGuild(String userId) {
    final guildId = _userGuildMap[userId];
    if (guildId == null) return null;
    return _guilds[guildId];
  }

  // ============================================
  // 길드 전
  // ============================================

  /// 길드 전 신청
  Future<String?> declareWar({
    required String guildId1,
    required String guildId2,
    required DateTime startTime,
  }) async {
    if (guildId1 == guildId2) {
      debugPrint('[Guild] Cannot declare war on self');
      return null;
    }

    final guild1 = _guilds[guildId1];
    final guild2 = _guilds[guildId2];

    if (guild1 == null || guild2 == null) return null;

    final warId = 'war_${DateTime.now().millisecondsSinceEpoch}';

    final war = GuildWar(
      id: warId,
      guildId1: guildId1,
      guildId2: guildId2,
      startTime: startTime,
      endTime: startTime.add(const Duration(days: 3)),
      score1: 0,
      score2: 0,
      status: GuildWarStatus.scheduled,
    );

    _wars[warId] = war;

    await _saveWars();

    // 양쪽 길드에 알림
    await _notifyGuildMembers(guildId1, '길드전이 신청되었습니다!');
    await _notifyGuildMembers(guildId2, '길드전이 신청되었습니다!');

    _warController.add(war);

    debugPrint('[Guild] War declared: $guildId1 vs $guildId2');
    return warId;
  }

  /// 길드 전 점수 업데이트
  Future<void> updateWarScore({
    required String warId,
    required String guildId,
    required int score,
  }) async {
    final war = _wars[warId];
    if (war == null) return;

    if (war.status != GuildWarStatus.inProgress) return;

    int newScore1 = war.score1;
    int newScore2 = war.score2;

    if (guildId == war.guildId1) {
      newScore1 += score;
    } else if (guildId == war.guildId2) {
      newScore2 += score;
    }

    _wars[warId] = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildId2: war.guildId2,
      startTime: war.startTime,
      endTime: war.endTime,
      score1: newScore1,
      score2: newScore2,
      winnerGuildId: war.winnerGuildId,
      status: war.status,
    );

    await _saveWars();

    _warController.add(_wars[warId]!);
  }

  /// 길드 전 시작
  Future<void> startWar(String warId) async {
    final war = _wars[warId];
    if (war == null) return;

    _wars[warId] = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildId2: war.guildId2,
      startTime: war.startTime,
      endTime: war.endTime,
      score1: war.score1,
      score2: war.score2,
      winnerGuildId: war.winnerGuildId,
      status: GuildWarStatus.inProgress,
    );

    await _saveWars();

    await _notifyGuildMembers(war.guildId1, '길드전이 시작되었습니다!');
    await _notifyGuildMembers(war.guildId2, '길드전이 시작되었습니다!');

    debugPrint('[Guild] War started: $warId');
  }

  /// 길드 전 종료
  Future<void> endWar(String warId) async {
    final war = _wars[warId];
    if (war == null) return;

    // 승자 결정
    String? winnerId;
    if (war.score1 > war.score2) {
      winnerId = war.guildId1;
    } else if (war.score2 > war.score1) {
      winnerId = war.guildId2;
    }

    _wars[warId] = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildId2: war.guildId2,
      startTime: war.startTime,
      endTime: war.endTime,
      score1: war.score1,
      score2: war.score2,
      winnerGuildId: winnerId,
      status: GuildWarStatus.completed,
    );

    await _saveWars();

    if (winnerId != null) {
      await _notifyGuildMembers(winnerId, '길드전 승리! 🎉');
      final loserId = winnerId == war.guildId1 ? war.guildId2 : war.guildId1;
      await _notifyGuildMembers(loserId, '길드전 패배...');
    }

    _warController.add(_wars[warId]!);

    debugPrint('[Guild] War ended: $warId');
  }

  /// 활성화된 길드 전 목록
  List<GuildWar> getActiveWars() {
    return _wars.values
        .where((w) => w.status == GuildWarStatus.inProgress)
        .toList();
  }

  // ============================================
  // 저장/로드
  // ============================================

  Future<void> _saveGuilds() async {
    final guildsJson = _guilds.values.map((g) => jsonEncode(g.toJson())).toList();
    await _prefs!.setStringList('guilds', guildsJson);
  }

  Future<void> _saveUserGuildMap() async {
    await _prefs!.setString('user_guild_map', jsonEncode(_userGuildMap));
  }

  Future<void> _saveWars() async {
    final warsJson = _wars.values.map((w) => jsonEncode(w.toJson())).toList();
    await _prefs!.setStringList('guild_wars', warsJson);
  }

  // ============================================
  // 알림
  // ============================================

  Future<void> _notifyGuildMembers(String guildId, String message) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    for (final member in guild.members) {
      // 실제 알림 전송 (푸시 등)
      debugPrint('[Guild] Notify ${member.userId}: $message');
    }
  }

  Future<void> _notifyGuildOfficers(String guildId, String message) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    final officers = guild.members.where((m) =>
      m.role == GuildRole.master || m.role == GuildRole.officer
    );

    for (final officer in officers) {
      debugPrint('[Guild] Notify officer ${officer.userId}: $message');
    }
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _guildController.close();
    _warController.close();
    _searchController.close();
  }

  bool get _isInitialized => _prefs != null;
}

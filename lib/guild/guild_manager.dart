import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 길드 역할
enum GuildRole {
  leader,       // 길드장
  viceLeader,   // 부길드장
  officer,      // 간부
  member,       // 일반 회원
  novice,       // 수습생
}

/// 길드 가입 상태
enum GuildJoinStatus {
  invited,      // 초대됨
  requested,    // 신청함
  accepted,     // 승인됨
  rejected,     // 거절됨
  kicked,       // 추방됨
  left,         // 탈퇴함
}

/// 길드전 상태
enum GuildWarStatus {
  preparing,    // 준비 중
  fighting,     // 진행 중
  ended,        // 종료됨
  cancelled,    // 취소됨
}

/// 길드원 정보
class GuildMember {
  final String userId;
  final String username;
  final GuildRole role;
  final int level;
  final int power;
  final int contribution; // 기여도
  final int weeklyContribution; // 주간 기여도
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final bool isOnline;

  const GuildMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.level,
    required this.power,
    required this.contribution,
    required this.weeklyContribution,
    required this.joinedAt,
    this.lastActiveAt,
    required this.isOnline,
  });
}

/// 길드 가입 신청/초대
class GuildApplication {
  final String id;
  final String guildId;
  final String userId;
  final String username;
  final GuildJoinStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? message;

  const GuildApplication({
    required this.id,
    required this.guildId,
    required this.userId,
    required this.username,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.message,
  });
}

/// 길드 상점 아이템
class GuildShopItem {
  final String id;
  final String name;
  final String type;
  final int price; // 길드 코인 가격
  final int? guildLevel;
  final int stock; // 재고 (-1 = 무제한)
  final Map<String, dynamic> itemData;

  const GuildShopItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.guildLevel,
    required this.stock,
    required this.itemData,
  });
}

/// 길드전
class GuildWar {
  final String id;
  final String guildId1;
  final String guildName1;
  final String guildId2;
  final String guildName2;
  final GuildWarStatus status;
  final int score1;
  final int score2;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // minutes
  final String? winnerId;
  final List<String> participants1;
  final List<String> participants2;

  const GuildWar({
    required this.id,
    required this.guildId1,
    required this.guildName1,
    required this.guildId2,
    required this.guildName2,
    required this.status,
    required this.score1,
    required this.score2,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.winnerId,
    required this.participants1,
    required this.participants2,
  });
}

/// 길드
class Guild {
  final String id;
  final String name;
  final String tag; // 길드 태그 (최대 4자)
  final String description;
  final String leaderId;
  final String emblemUrl;
  final int level;
  final int exp;
  final int maxMembers;
  final List<GuildMember> members;
  final int guildCoins; // 길드 코인
  final DateTime createdAt;
  final int totalWins; // 길드전 승리 수
  final int totalLosses; // 길드전 패배 수
  final int rank; // 길드 랭킹

  const Guild({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.leaderId,
    required this.emblemUrl,
    required this.level,
    required this.exp,
    required this.maxMembers,
    required this.members,
    required this.guildCoins,
    required this.createdAt,
    required this.totalWins,
    required this.totalLosses,
    required this.rank,
  });

  /// 경험율
  double get expRate {
    final requiredExp = level * 1000;
    return exp / requiredExp;
  }

  /// 승률
  double get winRate {
    final total = totalWins + totalLosses;
    return total > 0 ? totalWins / total : 0.0;
  }

  /// 현재 인원
  int get currentMembers => members.length;

  /// 가입 가능 여부
  bool get canJoin => currentMembers < maxMembers;
}

/// 길드 관리자
class GuildManager {
  static final GuildManager _instance = GuildManager._();
  static GuildManager get instance => _instance;

  GuildManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Guild> _guilds = {};
  final Map<String, GuildApplication> _applications = {};
  final Map<String, GuildWar> _wars = {};
  final List<GuildShopItem> _shopItems = [];

  final StreamController<Guild> _guildController =
      StreamController<Guild>.broadcast();
  final StreamController<GuildMember> _memberController =
      StreamController<GuildMember>.broadcast();
  final StreamController<GuildWar> _warController =
      StreamController<GuildWar>.broadcast();

  Stream<Guild> get onGuildUpdate => _guildController.stream;
  Stream<GuildMember> get onMemberUpdate => _memberController.stream;
  Stream<GuildWar> get onWarUpdate => _warController.stream;

  Timer? _warTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 상점 아이템 로드
    _loadShopItems();

    // 길드 로드
    await _loadGuilds();

    debugPrint('[Guild] Initialized');
  }

  void _loadShopItems() {
    _shopItems.addAll([
      const GuildShopItem(
        id: 'potion_boost',
        name: '경험치 부스트 (1시간)',
        type: 'consumable',
        price: 100,
        stock: -1,
        itemData: {'exp_bonus': 1.5, 'duration': 3600},
      ),
      const GuildShopItem(
        id: 'rare_material',
        name: '희귀 재료 상자',
        type: 'material',
        price: 500,
        guildLevel: 3,
        stock: 10,
        itemData: {'materials': ['rare_crystal', 'dragon_scale']},
      ),
      const GuildShopItem(
        id: 'guild_banner',
        name: '길드 배너',
        type: 'decoration',
        price: 1000,
        guildLevel: 5,
        stock: 1,
        itemData: {'banner_type': 'legendary'},
      ),
    ]);
  }

  Future<void> _loadGuilds() async {
    // 기본 길드 생성
    _guilds['guild_1'] = Guild(
      id: 'guild_1',
      name: '전설의 기사단',
      tag: 'LEG',
      description: '최고의 전사들이 모인 길드',
      leaderId: 'user_1',
      emblemUrl: 'assets/emblems/guild_1.png',
      level: 10,
      exp: 5000,
      maxMembers: 50,
      members: const [
        GuildMember(
          userId: 'user_1',
          username: '길드장',
          role: GuildRole.leader,
          level: 100,
          power: 50000,
          contribution: 10000,
          weeklyContribution: 500,
          joinedAt: DateTime.now(),
          isOnline: true,
        ),
      ],
      guildCoins: 50000,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      totalWins: 45,
      totalLosses: 20,
      rank: 1,
    );
  }

  /// 길드 생성
  Future<Guild> createGuild({
    required String name,
    required String tag,
    required String description,
    String? emblemUrl,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    // 길드명 중복 체크
    if (_guilds.values.any((g) => g.name == name)) {
      throw Exception('Guild name already exists');
    }

    final guildId = 'guild_${DateTime.now().millisecondsSinceEpoch}';
    final guild = Guild(
      id: guildId,
      name: name,
      tag: tag.toUpperCase(),
      description: description,
      leaderId: _currentUserId!,
      emblemUrl: emblemUrl ?? 'assets/emblems/default.png',
      level: 1,
      exp: 0,
      maxMembers: 20,
      members: [
        GuildMember(
          userId: _currentUserId!,
          username: 'Leader',
          role: GuildRole.leader,
          level: 50,
          power: 10000,
          contribution: 0,
          weeklyContribution: 0,
          joinedAt: DateTime.now(),
          isOnline: true,
        ),
      ],
      guildCoins: 0,
      createdAt: DateTime.now(),
      totalWins: 0,
      totalLosses: 0,
      rank: 0,
    );

    _guilds[guildId] = guild;
    _guildController.add(guild);

    await _saveGuild(guild);

    debugPrint('[Guild] Guild created: $name');

    return guild;
  }

  /// 길드 가입 신청
  Future<GuildApplication> applyToGuild({
    required String guildId,
    String? message,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final guild = _guilds[guildId];
    if (guild == null) {
      throw Exception('Guild not found');
    }

    if (!guild.canJoin) {
      throw Exception('Guild is full');
    }

    // 이미 신청했는지 확인
    if (_applications.values.any((a) =>
        a.userId == _currentUserId && a.guildId == guildId)) {
      throw Exception('Already applied');
    }

    final applicationId = 'app_${DateTime.now().millisecondsSinceEpoch}';
    final application = GuildApplication(
      id: applicationId,
      guildId: guildId,
      userId: _currentUserId!,
      username: 'User $_currentUserId',
      status: GuildJoinStatus.requested,
      createdAt: DateTime.now(),
      message: message,
    );

    _applications[applicationId] = application;

    debugPrint('[Guild] Applied to guild: $guildId');

    return application;
  }

  /// 길드 가입 승인
  Future<void> acceptApplication(String applicationId) async {
    final application = _applications[applicationId];
    if (application == null) return;

    final guild = _guilds[application.guildId];
    if (guild == null) return;

    if (!guild.canJoin) {
      throw Exception('Guild is full');
    }

    // 길드원 추가
    final newMember = GuildMember(
      userId: application.userId,
      username: application.username,
      role: GuildRole.novice,
      level: 1,
      power: 100,
      contribution: 0,
      weeklyContribution: 0,
      joinedAt: DateTime.now(),
      isOnline: false,
    );

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: [...guild.members, newMember],
      guildCoins: guild.guildCoins,
      createdAt: guild.createdAt,
      totalWins: guild.totalWins,
      totalLosses: guild.totalLosses,
      rank: guild.rank,
    );

    _guilds[guild.id] = updated;
    _guildController.add(updated);
    _memberController.add(newMember);

    // 신청 상태 업데이트
    _applications[applicationId] = GuildApplication(
      id: application.id,
      guildId: application.guildId,
      userId: application.userId,
      username: application.username,
      status: GuildJoinStatus.accepted,
      createdAt: application.createdAt,
      processedAt: DateTime.now(),
      message: application.message,
    );

    await _saveGuild(updated);

    debugPrint('[Guild] Member accepted: ${newMember.username}');
  }

  /// 길드원 역할 변경
  Future<void> changeMemberRole({
    required String guildId,
    required String userId,
    required GuildRole newRole,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    final updatedMembers = guild.members.map((m) {
      if (m.userId == userId) {
        return GuildMember(
          userId: m.userId,
          username: m.username,
          role: newRole,
          level: m.level,
          power: m.power,
          contribution: m.contribution,
          weeklyContribution: m.weeklyContribution,
          joinedAt: m.joinedAt,
          lastActiveAt: m.lastActiveAt,
          isOnline: m.isOnline,
        );
      }
      return m;
    }).toList();

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: updatedMembers,
      guildCoins: guild.guildCoins,
      createdAt: guild.createdAt,
      totalWins: guild.totalWins,
      totalLosses: guild.totalLosses,
      rank: guild.rank,
    );

    _guilds[guildId] = updated;
    _guildController.add(updated);

    debugPrint('[Guild] Role changed: $userId -> ${newRole.name}');
  }

  /// 길드원 추방
  Future<void> kickMember({
    required String guildId,
    required String userId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    if (userId == guild.leaderId) {
      throw Exception('Cannot kick guild leader');
    }

    final updatedMembers = guild.members.where((m) => m.userId != userId).toList();

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: updatedMembers,
      guildCoins: guild.guildCoins,
      createdAt: guild.createdAt,
      totalWins: guild.totalWins,
      totalLosses: guild.totalLosses,
      rank: guild.rank,
    );

    _guilds[guildId] = updated;
    _guildController.add(updated);

    debugPrint('[Guild] Member kicked: $userId');
  }

  /// 길드 경험치 획득
  Future<void> addGuildExp(String guildId, int exp) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    var newExp = guild.exp + exp;
    var newLevel = guild.level;

    // 레벨업 체크
    final requiredExp = guild.level * 1000;
    if (newExp >= requiredExp) {
      newLevel += 1;
      newExp -= requiredExp;
    }

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: newLevel,
      exp: newExp,
      maxMembers: guild.maxMembers,
      members: guild.members,
      guildCoins: guild.guildCoins,
      createdAt: guild.createdAt,
      totalWins: guild.totalWins,
      totalLosses: guild.totalLosses,
      rank: guild.rank,
    );

    _guilds[guildId] = updated;
    _guildController.add(updated);

    debugPrint('[Guild] Exp added: $exp, Level: $guild.level -> $newLevel');
  }

  /// 길드전 생성
  Future<GuildWar> createGuildWar({
    required String guildId1,
    required String guildId2,
    int duration = 30, // minutes
  }) async {
    final guild1 = _guilds[guildId1];
    final guild2 = _guilds[guildId2];

    if (guild1 == null || guild2 == null) {
      throw Exception('Guild not found');
    }

    final warId = 'war_${DateTime.now().millisecondsSinceEpoch}';
    final war = GuildWar(
      id: warId,
      guildId1: guildId1,
      guildName1: guild1.name,
      guildId2: guildId2,
      guildName2: guild2.name,
      status: GuildWarStatus.preparing,
      score1: 0,
      score2: 0,
      startTime: DateTime.now(),
      duration: duration,
      participants1: guild1.members.map((m) => m.userId).toList(),
      participants2: guild2.members.map((m) => m.userId).toList(),
    );

    _wars[warId] = war;
    _warController.add(war);

    // 1분 후 시작
    Future.delayed(const Duration(minutes: 1), () {
      _startGuildWar(warId);
    });

    debugPrint('[Guild] Guild war created: $warId');

    return war;
  }

  /// 길드전 시작
  void _startGuildWar(String warId) {
    final war = _wars[warId];
    if (war == null) return;

    final updated = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildName1: war.guildName1,
      guildId2: war.guildId2,
      guildName2: war.guildName2,
      status: GuildWarStatus.fighting,
      score1: war.score1,
      score2: war.score2,
      startTime: war.startTime,
      duration: war.duration,
      participants1: war.participants1,
      participants2: war.participants2,
    );

    _wars[warId] = updated;
    _warController.add(updated);

    // 타이머 시작
    _warTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateGuildWar(warId);
    });
  }

  /// 길드전 업데이트
  void _updateGuildWar(String warId) {
    final war = _wars[warId];
    if (war == null || war.status != GuildWarStatus.fighting) {
      _warTimer?.cancel();
      return;
    }

    // 시간 체크
    final elapsed = DateTime.now().difference(war.startTime).inMinutes;
    if (elapsed >= war.duration) {
      _endGuildWar(warId);
      return;
    }

    // 랜덤 점수 업데이트 (시뮬레이션)
    final scoreChange1 = 0 + Random().nextInt(5);
    final scoreChange2 = 0 + Random().nextInt(5);

    final updated = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildName1: war.guildName1,
      guildId2: war.guildId2,
      guildName2: war.guildName2,
      status: war.status,
      score1: war.score1 + scoreChange1,
      score2: war.score2 + scoreChange2,
      startTime: war.startTime,
      duration: war.duration,
      participants1: war.participants1,
      participants2: war.participants2,
    );

    _wars[warId] = updated;
    _warController.add(updated);
  }

  /// 길드전 종료
  void _endGuildWar(String warId) {
    _warTimer?.cancel();

    final war = _wars[warId];
    if (war == null) return;

    String? winnerId;
    if (war.score1 > war.score2) {
      winnerId = war.guildId1;
    } else if (war.score2 > war.score1) {
      winnerId = war.guildId2;
    }

    final updated = GuildWar(
      id: war.id,
      guildId1: war.guildId1,
      guildName1: war.guildName1,
      guildId2: war.guildId2,
      guildName2: war.guildName2,
      status: GuildWarStatus.ended,
      score1: war.score1,
      score2: war.score2,
      startTime: war.startTime,
      endTime: DateTime.now(),
      duration: war.duration,
      winnerId: winnerId,
      participants1: war.participants1,
      participants2: war.participants2,
    );

    _wars[warId] = updated;
    _warController.add(updated);

    // 길드 전적 업데이트
    if (winnerId != null) {
      _updateGuildWarStats(winnerId, true);
      final loserId = winnerId == war.guildId1 ? war.guildId2 : war.guildId1;
      _updateGuildWarStats(loserId, false);
    }

    debugPrint('[Guild] Guild war ended: $warId, Winner: $winnerId');
  }

  /// 길드 전적 업데이트
  void _updateGuildWarStats(String guildId, bool isWin) {
    final guild = _guilds[guildId];
    if (guild == null) return;

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: guild.members,
      guildCoins: guild.guildCoins + (isWin ? 1000 : 100),
      createdAt: guild.createdAt,
      totalWins: isWin ? guild.totalWins + 1 : guild.totalWins,
      totalLosses: isWin ? guild.totalLosses : guild.totalLosses + 1,
      rank: guild.rank,
    );

    _guilds[guildId] = updated;
    _guildController.add(updated);
  }

  /// 길드 상점 구매
  Future<void> buyShopItem({
    required String guildId,
    required String itemId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return;

    final item = _shopItems.firstWhere((i) => i.id == itemId);
    if (guild.guildCoins < item.price) {
      throw Exception('Not enough guild coins');
    }

    if (item.stock == 0) {
      throw Exception('Out of stock');
    }

    final updated = Guild(
      id: guild.id,
      name: guild.name,
      tag: guild.tag,
      description: guild.description,
      leaderId: guild.leaderId,
      emblemUrl: guild.emblemUrl,
      level: guild.level,
      exp: guild.exp,
      maxMembers: guild.maxMembers,
      members: guild.members,
      guildCoins: guild.guildCoins - item.price,
      createdAt: guild.createdAt,
      totalWins: guild.totalWins,
      totalLosses: guild.totalLosses,
      rank: guild.rank,
    );

    _guilds[guildId] = updated;
    _guildController.add(updated);

    debugPrint('[Guild] Purchased: $itemId');
  }

  /// 길드 랭킹 조회
  List<Guild> getGuildRanking({int limit = 100}) {
    final guilds = _guilds.values.toList()
      ..sort((a, b) {
        // 레벨, 경험치, 승률 순으로 정렬
        if (a.level != b.level) return b.level.compareTo(a.level);
        if (a.exp != b.exp) return b.exp.compareTo(a.exp);
        return b.winRate.compareTo(a.winRate);
      });

    return guilds.take(limit).toList();
  }

  /// 길드 조회
  Guild? getGuild(String guildId) {
    return _guilds[guildId];
  }

  /// 사용자의 길드 조회
  Guild? getUserGuild(String userId) {
    for (final guild in _guilds.values) {
      if (guild.members.any((m) => m.userId == userId)) {
        return guild;
      }
    }
    return null;
  }

  /// 상점 아이템 목록
  List<GuildShopItem> getShopItems({int? guildLevel}) {
    var items = _shopItems.toList();

    if (guildLevel != null) {
      items = items.where((i) =>
          i.guildLevel == null || i.guildLevel! <= guildLevel).toList();
    }

    return items;
  }

  /// 가입 신청 목록
  List<GuildApplication> getApplications(String guildId) {
    return _applications.values
        .where((a) => a.guildId == guildId && a.status == GuildJoinStatus.requested)
        .toList();
  }

  /// 길드전 목록
  List<GuildWar> getGuildWars({String? guildId, GuildWarStatus? status}) {
    var wars = _wars.values.toList();

    if (guildId != null) {
      wars = wars.where((w) => w.guildId1 == guildId || w.guildId2 == guildId).toList();
    }

    if (status != null) {
      wars = wars.where((w) => w.status == status).toList();
    }

    return wars..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<void> _saveGuild(Guild guild) async {
    await _prefs?.setString(
      'guild_${guild.id}',
      jsonEncode({
        'id': guild.id,
        'name': guild.name,
        'tag': guild.tag,
        'level': guild.level,
        'exp': guild.exp,
      }),
    );
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    return {
      'totalGuilds': _guilds.length,
      'totalMembers': _guilds.values.fold<int>(
          0, (sum, g) => sum + g.currentMembers),
      'totalWars': _wars.length,
      'activeWars': _wars.values.where((w) => w.status == GuildWarStatus.fighting).length,
    };
  }

  void dispose() {
    _guildController.close();
    _memberController.close();
    _warController.close();
    _warTimer?.cancel();
  }
}

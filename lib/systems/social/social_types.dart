/// Social System Types and Interfaces
library social_types;

/// Friend status
enum FriendStatus {
  none,
  pending,
  accepted,
  blocked,
}

/// Guild role/permission levels
enum GuildRole {
  member,
  officer,
  coLeader,
  leader,
}

/// Raid participation status
enum RaidStatus {
  notJoined,
  waiting,
  inProgress,
  completed,
  failed,
}

/// Friend model
class Friend {
  final String id;
  final String name;
  final String? avatarUrl;
  final int level;
  final FriendStatus status;
  final DateTime? lastOnline;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.level = 1,
    this.status = FriendStatus.none,
    this.lastOnline,
    this.isOnline = false,
  });

  Friend copyWith({
    String? name,
    String? avatarUrl,
    int? level,
    FriendStatus? status,
    DateTime? lastOnline,
    bool? isOnline,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      status: status ?? this.status,
      lastOnline: lastOnline ?? this.lastOnline,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'level': level,
    'status': status.index,
    'lastOnline': lastOnline?.millisecondsSinceEpoch,
    'isOnline': isOnline,
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    level: json['level'] as int? ?? 1,
    status: FriendStatus.values[json['status'] as int? ?? 0],
    lastOnline: json['lastOnline'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastOnline'] as int)
        : null,
    isOnline: json['isOnline'] as bool? ?? false,
  );
}

/// Guild member model
class GuildMember {
  final String id;
  final String name;
  final GuildRole role;
  final int contribution;
  final DateTime joinedAt;
  final bool isOnline;

  const GuildMember({
    required this.id,
    required this.name,
    this.role = GuildRole.member,
    this.contribution = 0,
    required this.joinedAt,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.index,
    'contribution': contribution,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
    'isOnline': isOnline,
  };

  factory GuildMember.fromJson(Map<String, dynamic> json) => GuildMember(
    id: json['id'] as String,
    name: json['name'] as String,
    role: GuildRole.values[json['role'] as int? ?? 0],
    contribution: json['contribution'] as int? ?? 0,
    joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] as int),
    isOnline: json['isOnline'] as bool? ?? false,
  );
}

/// Guild model
class Guild {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final int level;
  final int maxMembers;
  final List<GuildMember> members;
  final DateTime createdAt;

  const Guild({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.level = 1,
    this.maxMembers = 30,
    this.members = const [],
    required this.createdAt,
  });

  int get memberCount => members.length;
  bool get isFull => memberCount >= maxMembers;

  GuildMember? get leader => members.cast<GuildMember?>().firstWhere(
    (m) => m?.role == GuildRole.leader,
    orElse: () => null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'level': level,
    'maxMembers': maxMembers,
    'members': members.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Guild.fromJson(Map<String, dynamic> json) => Guild(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    iconUrl: json['iconUrl'] as String?,
    level: json['level'] as int? ?? 1,
    maxMembers: json['maxMembers'] as int? ?? 30,
    members: (json['members'] as List<dynamic>?)
        ?.map((m) => GuildMember.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );
}

/// Raid boss model
class RaidBoss {
  final String id;
  final String name;
  final int maxHp;
  final int currentHp;
  final int level;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, int> rewards;

  const RaidBoss({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.currentHp,
    this.level = 1,
    required this.startTime,
    required this.endTime,
    this.rewards = const {},
  });

  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0;
  bool get isDefeated => currentHp <= 0;
  bool get isActive => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  RaidBoss takeDamage(int damage) {
    return RaidBoss(
      id: id,
      name: name,
      maxHp: maxHp,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      level: level,
      startTime: startTime,
      endTime: endTime,
      rewards: rewards,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'maxHp': maxHp,
    'currentHp': currentHp,
    'level': level,
    'startTime': startTime.millisecondsSinceEpoch,
    'endTime': endTime.millisecondsSinceEpoch,
    'rewards': rewards,
  };

  factory RaidBoss.fromJson(Map<String, dynamic> json) => RaidBoss(
    id: json['id'] as String,
    name: json['name'] as String,
    maxHp: json['maxHp'] as int,
    currentHp: json['currentHp'] as int,
    level: json['level'] as int? ?? 1,
    startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
    endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
    rewards: Map<String, int>.from(json['rewards'] as Map? ?? {}),
  );
}

/// Leaderboard entry
class LeaderboardEntry {
  final int rank;
  final String odId;
  final String name;
  final int score;
  final String? avatarUrl;
  final bool isCurrentPlayer;

  const LeaderboardEntry({
    required this.rank,
    required this.odId,
    required this.name,
    required this.score,
    this.avatarUrl,
    this.isCurrentPlayer = false,
  });

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'userId': odId,
    'name': name,
    'score': score,
    'avatarUrl': avatarUrl,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentPlayer = false}) => LeaderboardEntry(
    rank: json['rank'] as int,
    odId: json['userId'] as String,
    name: json['name'] as String,
    score: json['score'] as int,
    avatarUrl: json['avatarUrl'] as String?,
    isCurrentPlayer: isCurrentPlayer,
  );
}

/// Leaderboard type
enum LeaderboardType {
  daily,
  weekly,
  monthly,
  allTime,
  event,
}

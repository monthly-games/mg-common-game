import 'dart:async';
import 'package:flutter/material.dart';

enum PartyMemberRole {
  leader,
  member,
}

enum GuildMemberRole {
  guildMaster,
  officer,
  member,
}

enum GuildRank {
  iron,
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
}

class PartyMember {
  final String memberId;
  final String name;
  final int level;
  final PartyMemberRole role;
  final bool isReady;
  final DateTime joinedAt;
  final String? characterId;

  const PartyMember({
    required this.memberId,
    required this.name,
    required this.level,
    required this.role,
    required this.isReady,
    required this.joinedAt,
    this.characterId,
  });

  PartyMember copyWith({
    String? memberId,
    String? name,
    int? level,
    PartyMemberRole? role,
    bool? isReady,
    DateTime? joinedAt,
    String? characterId,
  }) {
    return PartyMember(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      level: level ?? this.level,
      role: role ?? this.role,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt ?? this.joinedAt,
      characterId: characterId ?? this.characterId,
    );
  }
}

class Party {
  final String partyId;
  final String name;
  final List<PartyMember> members;
  final int maxMembers;
  final int minLevel;
  final int maxLevel;
  final DateTime createdAt;
  final String leaderId;

  const Party({
    required this.partyId,
    required this.name,
    required this.members,
    required this.maxMembers,
    required this.minLevel,
    required this.maxLevel,
    required this.createdAt,
    required this.leaderId,
  });

  bool get isFull => members.length >= maxMembers;
  int get memberCount => members.length;
  List<PartyMember> get readyMembers => members.where((m) => m.isReady).toList();
  bool get allReady => members.every((m) => m.isReady);
}

class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

enum MessageType {
  normal,
  system,
  guild,
  party,
  whisper,
}

class GuildMember {
  final String memberId;
  final String name;
  final int level;
  final GuildMemberRole role;
  final int contribution;
  final DateTime joinedAt;
  final DateTime? lastActive;

  const GuildMember({
    required this.memberId,
    required this.name,
    required this.level,
    required this.role,
    required this.contribution,
    required this.joinedAt,
    this.lastActive,
  });

  GuildMember copyWith({
    String? memberId,
    String? name,
    int? level,
    GuildMemberRole? role,
    int? contribution,
    DateTime? joinedAt,
    DateTime? lastActive,
  }) {
    return GuildMember(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      level: level ?? this.level,
      role: role ?? this.role,
      contribution: contribution ?? this.contribution,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class Guild {
  final String guildId;
  final String name;
  final String description;
  final String emblem;
  final List<GuildMember> members;
  final int maxMembers;
  final int level;
  final int exp;
  final GuildRank rank;
  final int totalContribution;
  final DateTime createdAt;
  final String masterId;

  const Guild({
    required this.guildId,
    required this.name,
    required this.description,
    required this.emblem,
    required this.members,
    required this.maxMembers,
    required this.level,
    required this.exp,
    required this.rank,
    required this.totalContribution,
    required this.createdAt,
    required this.masterId,
  });

  bool get isFull => members.length >= maxMembers;
  int get memberCount => members.length;
  double get expToNextLevel => level * 1000;
  double get expPercent => exp / expToNextLevel;
}

class GuildReward {
  final String rewardId;
  final String name;
  final int levelRequired;
  final Map<String, int> rewards;

  const GuildReward({
    required this.rewardId,
    required this.name,
    required this.levelRequired,
    required this.rewards,
  });
}

class PartyGuildManager {
  static final PartyGuildManager _instance = PartyGuildManager._();
  static PartyGuildManager get instance => _instance;

  PartyGuildManager._();

  final Map<String, Party> _parties = {};
  final Map<String, Guild> _guilds = {};
  final Map<String, List<ChatMessage>> _partyChatHistory = {};
  final Map<String, List<ChatMessage>> _guildChatHistory = {};
  final StreamController<SocialEvent> _eventController = StreamController.broadcast();

  Stream<SocialEvent> get onSocialEvent => _eventController.stream;

  Party createParty({
    required String partyId,
    required String name,
    required String leaderId,
    required String leaderName,
    int maxMembers = 4,
    int minLevel = 1,
    int maxLevel = 100,
  }) {
    final leader = PartyMember(
      memberId: leaderId,
      name: leaderName,
      level: 1,
      role: PartyMemberRole.leader,
      isReady: true,
      joinedAt: DateTime.now(),
    );

    final party = Party(
      partyId: partyId,
      name: name,
      members: [leader],
      maxMembers: maxMembers,
      minLevel: minLevel,
      maxLevel: maxLevel,
      createdAt: DateTime.now(),
      leaderId: leaderId,
    );

    _parties[partyId] = party;
    _partyChatHistory[partyId] = [];

    _eventController.add(SocialEvent(
      type: SocialEventType.partyCreated,
      partyId: partyId,
      timestamp: DateTime.now(),
    ));

    return party;
  }

  Party? getParty(String partyId) {
    return _parties[partyId];
  }

  Future<bool> joinParty({
    required String partyId,
    required String memberId,
    required String memberName,
    required int level,
  }) async {
    final party = _parties[partyId];
    if (party == null) return false;
    if (party.isFull) return false;
    if (level < party.minLevel || level > party.maxLevel) return false;

    final member = PartyMember(
      memberId: memberId,
      name: memberName,
      level: level,
      role: PartyMemberRole.member,
      isReady: false,
      joinedAt: DateTime.now(),
    );

    final updatedMembers = [...party.members, member];
    _parties[partyId] = Party(
      partyId: party.partyId,
      name: party.name,
      members: updatedMembers,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      maxLevel: party.maxLevel,
      createdAt: party.createdAt,
      leaderId: party.leaderId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.partyMemberJoined,
      partyId: partyId,
      memberId: memberId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> leaveParty({
    required String partyId,
    required String memberId,
  }) async {
    final party = _parties[partyId];
    if (party == null) return false;

    if (memberId == party.leaderId) {
      _parties.remove(partyId);
      _partyChatHistory.remove(partyId);

      _eventController.add(SocialEvent(
        type: SocialEventType.partyDisbanded,
        partyId: partyId,
        timestamp: DateTime.now(),
      ));

      return true;
    }

    final updatedMembers = party.members.where((m) => m.memberId != memberId).toList();

    if (updatedMembers.isEmpty) {
      _parties.remove(partyId);
      _partyChatHistory.remove(partyId);

      _eventController.add(SocialEvent(
        type: SocialEventType.partyDisbanded,
        partyId: partyId,
        timestamp: DateTime.now(),
      ));
    } else {
      _parties[partyId] = Party(
        partyId: party.partyId,
        name: party.name,
        members: updatedMembers,
        maxMembers: party.maxMembers,
        minLevel: party.minLevel,
        maxLevel: party.maxLevel,
        createdAt: party.createdAt,
        leaderId: party.leaderId,
      );

      _eventController.add(SocialEvent(
        type: SocialEventType.partyMemberLeft,
        partyId: partyId,
        memberId: memberId,
        timestamp: DateTime.now(),
      ));
    }

    return true;
  }

  Future<bool> setReadyStatus({
    required String partyId,
    required String memberId,
    required bool isReady,
  }) async {
    final party = _parties[partyId];
    if (party == null) return false;

    final updatedMembers = party.members.map((m) {
      if (m.memberId == memberId) {
        return m.copyWith(isReady: isReady);
      }
      return m;
    }).toList();

    _parties[partyId] = Party(
      partyId: party.partyId,
      name: party.name,
      members: updatedMembers,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      maxLevel: party.maxLevel,
      createdAt: party.createdAt,
      leaderId: party.leaderId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.partyMemberReady,
      partyId: partyId,
      memberId: memberId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> transferPartyLeadership({
    required String partyId,
    required String currentLeaderId,
    required String newLeaderId,
  }) async {
    final party = _parties[partyId];
    if (party == null) return false;
    if (party.leaderId != currentLeaderId) return false;

    final updatedMembers = party.members.map((m) {
      if (m.memberId == currentLeaderId) {
        return m.copyWith(role: PartyMemberRole.member);
      }
      if (m.memberId == newLeaderId) {
        return m.copyWith(role: PartyMemberRole.leader);
      }
      return m;
    }).toList();

    _parties[partyId] = Party(
      partyId: party.partyId,
      name: party.name,
      members: updatedMembers,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      maxLevel: party.maxLevel,
      createdAt: party.createdAt,
      leaderId: newLeaderId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.partyLeadershipTransferred,
      partyId: partyId,
      memberId: newLeaderId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<void> sendPartyMessage({
    required String partyId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = ChatMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.party,
    );

    _partyChatHistory[partyId]?.add(message);

    _eventController.add(SocialEvent(
      type: SocialEventType.partyMessage,
      partyId: partyId,
      messageId: message.messageId,
      timestamp: DateTime.now(),
    ));
  }

  List<ChatMessage> getPartyChatHistory(String partyId) {
    return _partyChatHistory[partyId] ?? [];
  }

  Guild createGuild({
    required String guildId,
    required String name,
    required String description,
    required String masterId,
    required String masterName,
    int maxMembers = 50,
    String emblem = '',
  }) {
    final master = GuildMember(
      memberId: masterId,
      name: masterName,
      level: 1,
      role: GuildMemberRole.guildMaster,
      contribution: 0,
      joinedAt: DateTime.now(),
    );

    final guild = Guild(
      guildId: guildId,
      name: name,
      description: description,
      emblem: emblem,
      members: [master],
      maxMembers: maxMembers,
      level: 1,
      exp: 0,
      rank: GuildRank.iron,
      totalContribution: 0,
      createdAt: DateTime.now(),
      masterId: masterId,
    );

    _guilds[guildId] = guild;
    _guildChatHistory[guildId] = [];

    _eventController.add(SocialEvent(
      type: SocialEventType.guildCreated,
      guildId: guildId,
      timestamp: DateTime.now(),
    ));

    return guild;
  }

  Guild? getGuild(String guildId) {
    return _guilds[guildId];
  }

  Future<bool> joinGuild({
    required String guildId,
    required String memberId,
    required String memberName,
    required int level,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;
    if (guild.isFull) return false;

    final member = GuildMember(
      memberId: memberId,
      name: memberName,
      level: level,
      role: GuildMemberRole.member,
      contribution: 0,
      joinedAt: DateTime.now(),
    );

    final updatedMembers = [...guild.members, member];
    _guilds[guildId] = Guild(
      guildId: guild.guildId,
      name: guild.name,
      description: guild.description,
      emblem: guild.emblem,
      members: updatedMembers,
      maxMembers: guild.maxMembers,
      level: guild.level,
      exp: guild.exp,
      rank: guild.rank,
      totalContribution: guild.totalContribution,
      createdAt: guild.createdAt,
      masterId: guild.masterId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.guildMemberJoined,
      guildId: guildId,
      memberId: memberId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> leaveGuild({
    required String guildId,
    required String memberId,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;

    if (memberId == guild.masterId) {
      _guilds.remove(guildId);
      _guildChatHistory.remove(guildId);

      _eventController.add(SocialEvent(
        type: SocialEventType.guildDisbanded,
        guildId: guildId,
        timestamp: DateTime.now(),
      ));

      return true;
    }

    final updatedMembers = guild.members.where((m) => m.memberId != memberId).toList();

    if (updatedMembers.isEmpty) {
      _guilds.remove(guildId);
      _guildChatHistory.remove(guildId);

      _eventController.add(SocialEvent(
        type: SocialEventType.guildDisbanded,
        guildId: guildId,
        timestamp: DateTime.now(),
      ));
    } else {
      _guilds[guildId] = Guild(
        guildId: guild.guildId,
        name: guild.name,
        description: guild.description,
        emblem: guild.emblem,
        members: updatedMembers,
        maxMembers: guild.maxMembers,
        level: guild.level,
        exp: guild.exp,
        rank: guild.rank,
        totalContribution: guild.totalContribution,
        createdAt: guild.createdAt,
        masterId: guild.masterId,
      );

      _eventController.add(SocialEvent(
        type: SocialEventType.guildMemberLeft,
        guildId: guildId,
        memberId: memberId,
        timestamp: DateTime.now(),
      ));
    }

    return true;
  }

  Future<bool> promoteGuildMember({
    required String guildId,
    required String memberId,
    required GuildMemberRole newRole,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;

    final updatedMembers = guild.members.map((m) {
      if (m.memberId == memberId) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();

    _guilds[guildId] = Guild(
      guildId: guild.guildId,
      name: guild.name,
      description: guild.description,
      emblem: guild.emblem,
      members: updatedMembers,
      maxMembers: guild.maxMembers,
      level: guild.level,
      exp: guild.exp,
      rank: guild.rank,
      totalContribution: guild.totalContribution,
      createdAt: guild.createdAt,
      masterId: guild.masterId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.guildMemberPromoted,
      guildId: guildId,
      memberId: memberId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> contributeToGuild({
    required String guildId,
    required String memberId,
    required int amount,
  }) async {
    final guild = _guilds[guildId];
    if (guild == null) return false;

    final updatedMembers = guild.members.map((m) {
      if (m.memberId == memberId) {
        return m.copyWith(
          contribution: m.contribution + amount,
          lastActive: DateTime.now(),
        );
      }
      return m;
    }).toList();

    final newExp = guild.exp + amount;
    int newLevel = guild.level;
    GuildRank newRank = guild.rank;

    if (newExp >= guild.expToNextLevel) {
      newLevel = guild.level + 1;
      if (newLevel >= 10 && guild.rank.index < GuildRank.grandmaster.index) {
        newRank = GuildRank.values[guild.rank.index + 1];
      }
    }

    _guilds[guildId] = Guild(
      guildId: guild.guildId,
      name: guild.name,
      description: guild.description,
      emblem: guild.emblem,
      members: updatedMembers,
      maxMembers: guild.maxMembers,
      level: newLevel,
      exp: newExp,
      rank: newRank,
      totalContribution: guild.totalContribution + amount,
      createdAt: guild.createdAt,
      masterId: guild.masterId,
    );

    _eventController.add(SocialEvent(
      type: SocialEventType.guildContribution,
      guildId: guildId,
      memberId: memberId,
      data: {'amount': amount},
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<void> sendGuildMessage({
    required String guildId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = ChatMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.guild,
    );

    _guildChatHistory[guildId]?.add(message);

    _eventController.add(SocialEvent(
      type: SocialEventType.guildMessage,
      guildId: guildId,
      messageId: message.messageId,
      timestamp: DateTime.now(),
    ));
  }

  List<ChatMessage> getGuildChatHistory(String guildId) {
    return _guildChatHistory[guildId] ?? [];
  }

  List<Guild> getGuildRankings() {
    return _guilds.values.toList()
      ..sort((a, b) => b.totalContribution.compareTo(a.totalContribution));
  }

  void dispose() {
    _eventController.close();
  }
}

class SocialEvent {
  final SocialEventType type;
  final String? partyId;
  final String? guildId;
  final String? memberId;
  final String? messageId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const SocialEvent({
    required this.type,
    this.partyId,
    this.guildId,
    this.memberId,
    this.messageId,
    this.data,
    required this.timestamp,
  });
}

enum SocialEventType {
  partyCreated,
  partyMemberJoined,
  partyMemberLeft,
  partyMemberReady,
  partyLeadershipTransferred,
  partyDisbanded,
  partyMessage,
  guildCreated,
  guildMemberJoined,
  guildMemberLeft,
  guildMemberPromoted,
  guildContribution,
  guildDisbanded,
  guildMessage,
}

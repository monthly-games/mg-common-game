import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 파티 역할
enum PartyRole {
  leader,       // 리더
  member,       // 멤버
}

/// 파티 경험치 분배 방식
enum ExpDistributionType {
  equal,        // 균등 분배
  level,        // 레벨 비례
  damage,       // 데미지 비례
  leader,       // 리더가 전체 획득
}

/// 파티원 정보
class PartyMember {
  final String userId;
  final String username;
  final int level;
  final int power;
  final PartyRole role;
  final int currentHp;
  final int maxHp;
  final bool isReady;
  final bool isOnline;
  final DateTime joinedAt;

  const PartyMember({
    required this.userId,
    required this.username,
    required this.level,
    required this.power,
    required this.role,
    required this.currentHp,
    required this.maxHp,
    required this.isReady,
    required this.isOnline,
    required this.joinedAt,
  });

  /// HP 비율
  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0.0;
}

/// 파티 퀘스트
class PartyQuest {
  final String questId;
  final String name;
  final String description;
  final int targetCount;
  final int currentCount;
  final int expReward;
  final int goldReward;
  final List<String> itemRewards;

  const PartyQuest({
    required this.questId,
    required this.name,
    required this.description,
    required this.targetCount,
    required this.currentCount,
    required this.expReward,
    required this.goldReward,
    required this.itemRewards,
  });

  /// 진행률
  double get progress => targetCount > 0 ? currentCount / targetCount : 0.0;

  /// 완료 여부
  bool get isCompleted => currentCount >= targetCount;
}

/// 파티 던전 정보
class PartyDungeon {
  final String dungeonId;
  final String name;
  final int minLevel;
  final int maxLevel;
  final int minPartySize;
  final int maxPartySize;
  final int recommendedPower;
  final List<String> rewards;
  final int duration; // minutes

  const PartyDungeon({
    required this.dungeonId,
    required this.name,
    required this.minLevel,
    required this.maxLevel,
    required this.minPartySize,
    required this.maxPartySize,
    required this.recommendedPower,
    required this.rewards,
    required this.duration,
  });
}

/// 파티
class Party {
  final String id;
  final String name;
  final List<PartyMember> members;
  final PartyQuest? activeQuest;
  final PartyDungeon? activeDungeon;
  final ExpDistributionType expDistribution;
  final bool isPublic; // 공개 파티 여부
  final int maxMembers;
  final int minLevel;
  final int levelRange; // 레벨 허용 범위
  final DateTime createdAt;
  final DateTime? activityAt;

  const Party({
    required this.id,
    required this.name,
    required this.members,
    this.activeQuest,
    this.activeDungeon,
    required this.expDistribution,
    required this.isPublic,
    required this.maxMembers,
    required this.minLevel,
    required this.levelRange,
    required this.createdAt,
    this.activityAt,
  });

  /// 리더
  PartyMember? get leader {
    try {
      return members.firstWhere((m) => m.role == PartyRole.leader);
    } catch (e) {
      return null;
    }
  }

  /// 현재 인원
  int get currentMembers => members.length;

  /// 참여 가능 여부
  bool get canJoin => currentMembers < maxMembers;

  /// 전체 파워
  int get totalPower => members.fold<int>(0, (sum, m) => sum + m.power);

  /// 평균 레벨
  double get averageLevel {
    if (members.isEmpty) return 0.0;
    return members.map((m) => m.level).reduce((a, b) => a + b) / members.length;
  }
}

/// 파티 관리자
class PartyManager {
  static final PartyManager _instance = PartyManager._();
  static PartyManager get instance => _instance;

  PartyManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Party> _parties = {};
  final Map<String, PartyDungeon> _dungeons = {};

  final StreamController<Party> _partyController =
      StreamController<Party>.broadcast();
  final StreamController<PartyMember> _memberController =
      StreamController<PartyMember>.broadcast();
  final StreamController<PartyQuest> _questController =
      StreamController<PartyQuest>.broadcast();

  Stream<Party> get onPartyUpdate => _partyController.stream;
  Stream<PartyMember> get onMemberUpdate => _memberController.stream;
  Stream<PartyQuest> get onQuestUpdate => _questController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 던전 로드
    _loadDungeons();

    // 파티 로드
    await _loadParties();

    debugPrint('[Party] Initialized');
  }

  void _loadDungeons() {
    _dungeons['dungeon_1'] = const PartyDungeon(
      dungeonId: 'dungeon_1',
      name: '고동 동굴',
      minLevel: 10,
      maxLevel: 20,
      minPartySize: 2,
      maxPartySize: 4,
      recommendedPower: 5000,
      rewards: ['gold', 'exp', 'equipment'],
      duration: 30,
    );

    _dungeons['dungeon_2'] = const PartyDungeon(
      dungeonId: 'dungeon_2',
      name: '화산 심장부',
      minLevel: 30,
      maxLevel: 50,
      minPartySize: 4,
      maxPartySize: 6,
      recommendedPower: 20000,
      rewards: ['rare_equipment', 'materials', 'gold'],
      duration: 60,
    );
  }

  Future<void> _loadParties() async {
    // 시뮬레이션: 저장된 파티 로드
  }

  /// 파티 생성
  Future<Party> createParty({
    String? name,
    int maxMembers = 4,
    int minLevel = 1,
    int levelRange = 10,
    ExpDistributionType expDistribution = ExpDistributionType.equal,
    bool isPublic = true,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    // 이미 파티에 있는지 확인
    if (_parties.values.any((p) => p.members.any((m) => m.userId == _currentUserId))) {
      throw Exception('Already in a party');
    }

    final partyId = 'party_${DateTime.now().millisecondsSinceEpoch}';
    final leader = PartyMember(
      userId: _currentUserId!,
      username: 'Leader',
      level: 50,
      power: 10000,
      role: PartyRole.leader,
      currentHp: 1000,
      maxHp: 1000,
      isReady: true,
      isOnline: true,
      joinedAt: DateTime.now(),
    );

    final party = Party(
      id: partyId,
      name: name ?? '${leader.username}의 파티',
      members: [leader],
      expDistribution: expDistribution,
      isPublic: isPublic,
      maxMembers: maxMembers,
      minLevel: minLevel,
      levelRange: levelRange,
      createdAt: DateTime.now(),
      activityAt: DateTime.now(),
    );

    _parties[partyId] = party;
    _partyController.add(party);

    await _saveParty(party);

    debugPrint('[Party] Party created: $partyId');

    return party;
  }

  /// 파티 참가
  Future<void> joinParty(String partyId) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final party = _parties[partyId];
    if (party == null) {
      throw Exception('Party not found');
    }

    if (!party.canJoin) {
      throw Exception('Party is full');
    }

    // 레벨 체크
    final userLevel = 50; // 실제로는 유저 레벨 조회
    if (userLevel < party.minLevel || userLevel > party.minLevel + party.levelRange) {
      throw Exception('Level requirement not met');
    }

    // 이미 다른 파티에 있는지 확인
    if (_parties.values.any((p) =>
        p.id != partyId && p.members.any((m) => m.userId == _currentUserId))) {
      throw Exception('Already in another party');
    }

    final member = PartyMember(
      userId: _currentUserId!,
      username: 'Member',
      level: userLevel,
      power: 8000,
      role: PartyRole.member,
      currentHp: 800,
      maxHp: 800,
      isReady: false,
      isOnline: true,
      joinedAt: DateTime.now(),
    );

    final updated = Party(
      id: party.id,
      name: party.name,
      members: [...party.members, member],
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);
    _memberController.add(member);

    await _saveParty(updated);

    debugPrint('[Party] Joined party: $partyId');
  }

  /// 파티 탈퇴
  Future<void> leaveParty(String partyId) async {
    if (_currentUserId == null) return;

    final party = _parties[partyId];
    if (party == null) return;

    // 리더가 탈퇴하면 파티 해체
    if (party.leader?.userId == _currentUserId) {
      await _disbandParty(partyId);
      return;
    }

    final updatedMembers = party.members.where((m) => m.userId != _currentUserId).toList();

    if (updatedMembers.isEmpty) {
      await _disbandParty(partyId);
      return;
    }

    final updated = Party(
      id: party.id,
      name: party.name,
      members: updatedMembers,
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Left party: $partyId');
  }

  /// 파티 해체
  Future<void> _disbandParty(String partyId) async {
    _parties.remove(partyId);

    debugPrint('[Party] Party disbanded: $partyId');
  }

  /// 파티원 추방
  Future<void> kickMember({
    required String partyId,
    required String userId,
  }) async {
    if (_currentUserId == null) return;

    final party = _parties[partyId];
    if (party == null) return;

    if (party.leader?.userId != _currentUserId) {
      throw Exception('Only leader can kick members');
    }

    if (userId == party.leader?.userId) {
      throw Exception('Cannot kick leader');
    }

    final updatedMembers = party.members.where((m) => m.userId != userId).toList();

    final updated = Party(
      id: party.id,
      name: party.name,
      members: updatedMembers,
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Member kicked: $userId');
  }

  /// 리더 위임
  Future<void> transferLeadership({
    required String partyId,
    required String newLeaderId,
  }) async {
    if (_currentUserId == null) return;

    final party = _parties[partyId];
    if (party == null) return;

    if (party.leader?.userId != _currentUserId) {
      throw Exception('Only leader can transfer leadership');
    }

    final updatedMembers = party.members.map((m) {
      if (m.userId == newLeaderId) {
        return PartyMember(
          userId: m.userId,
          username: m.username,
          level: m.level,
          power: m.power,
          role: PartyRole.leader,
          currentHp: m.currentHp,
          maxHp: m.maxHp,
          isReady: m.isReady,
          isOnline: m.isOnline,
          joinedAt: m.joinedAt,
        );
      } else if (m.userId == _currentUserId) {
        return PartyMember(
          userId: m.userId,
          username: m.username,
          level: m.level,
          power: m.power,
          role: PartyRole.member,
          currentHp: m.currentHp,
          maxHp: m.maxHp,
          isReady: m.isReady,
          isOnline: m.isOnline,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    final updated = Party(
      id: party.id,
      name: party.name,
      members: updatedMembers,
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Leadership transferred: $newLeaderId');
  }

  /// 레디 상태 토글
  Future<void> toggleReady(String partyId) async {
    if (_currentUserId == null) return;

    final party = _parties[partyId];
    if (party == null) return;

    final updatedMembers = party.members.map((m) {
      if (m.userId == _currentUserId) {
        return PartyMember(
          userId: m.userId,
          username: m.username,
          level: m.level,
          power: m.power,
          role: m.role,
          currentHp: m.currentHp,
          maxHp: m.maxHp,
          isReady: !m.isReady,
          isOnline: m.isOnline,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    final updated = Party(
      id: party.id,
      name: party.name,
      members: updatedMembers,
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Ready toggled');
  }

  /// 파티 퀘스트 시작
  Future<void> startPartyQuest({
    required String partyId,
    required String questId,
  }) async {
    final party = _parties[partyId];
    if (party == null) return;

    // 모든 멤버가 레디인지 확인
    if (!party.members.every((m) => m.isReady)) {
      throw Exception('Not all members are ready');
    }

    final quest = PartyQuest(
      questId: questId,
      name: '파티 퀘스트',
      description: '함께 몬스터를 처치하세요',
      targetCount: 100,
      currentCount: 0,
      expReward: 1000,
      goldReward: 500,
      itemRewards: ['potion'],
    );

    final updated = Party(
      id: party.id,
      name: party.name,
      members: party.members,
      activeQuest: quest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);
    _questController.add(quest);

    debugPrint('[Party] Quest started: $questId');
  }

  /// 퀘스트 진행 업데이트
  Future<void> updateQuestProgress({
    required String partyId,
    required int progress,
  }) async {
    final party = _parties[partyId];
    if (party == null || party.activeQuest == null) return;

    final quest = party.activeQuest!;
    final newCount = (quest.currentCount + progress).clamp(0, quest.targetCount);

    final updatedQuest = PartyQuest(
      questId: quest.questId,
      name: quest.name,
      description: quest.description,
      targetCount: quest.targetCount,
      currentCount: newCount,
      expReward: quest.expReward,
      goldReward: quest.goldReward,
      itemRewards: quest.itemRewards,
    );

    final updated = Party(
      id: party.id,
      name: party.name,
      members: party.members,
      activeQuest: updatedQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);
    _questController.add(updatedQuest);

    // 퀘스트 완료
    if (updatedQuest.isCompleted) {
      await _completeQuest(partyId);
    }

    debugPrint('[Party] Quest progress: $newCount/${quest.targetCount}');
  }

  /// 퀘스트 완료
  Future<void> _completeQuest(String partyId) async {
    final party = _parties[partyId];
    if (party == null || party.activeQuest == null) return;

    final quest = party.activeQuest!;

    // 경험치 분배
    final expPerMember = _distributeExp(
      party.members,
      quest.expReward,
      party.expDistribution,
    );

    for (final member in party.members) {
      // 실제로는 경험치 지급
      debugPrint('[Party] Member ${member.username} received $expPerMember EXP');
    }

    // 퀘스트 제거
    final updated = Party(
      id: party.id,
      name: party.name,
      members: party.members,
      activeQuest: null,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Quest completed: $partyId');
  }

  /// 경험치 분배
  int _distributeExp(
    List<PartyMember> members,
    int totalExp,
    ExpDistributionType type,
  ) {
    switch (type) {
      case ExpDistributionType.equal:
        return totalExp ~/ members.length;
      case ExpDistributionType.level:
        final totalLevel = members.fold<int>(0, (sum, m) => sum + m.level);
        if (totalLevel == 0) return 0;
        return (totalExp * members.first.level / totalLevel).toInt();
      case ExpDistributionType.damage:
        // 데미지 비례 (시뮬레이션)
        return totalExp ~/ members.length;
      case ExpDistributionType.leader:
        return totalExp;
    }
  }

  /// 던전 입장
  Future<void> enterDungeon({
    required String partyId,
    required String dungeonId,
  }) async {
    final party = _parties[partyId];
    final dungeon = _dungeons[dungeonId];

    if (party == null || dungeon == null) return;

    if (party.currentMembers < dungeon.minPartySize) {
      throw Exception('Not enough members');
    }

    if (party.currentMembers > dungeon.maxPartySize) {
      throw Exception('Too many members');
    }

    if (party.totalPower < dungeon.recommendedPower) {
      throw Exception('Power too low');
    }

    final updated = Party(
      id: party.id,
      name: party.name,
      members: party.members,
      activeQuest: party.activeQuest,
      activeDungeon: dungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    debugPrint('[Party] Entered dungeon: $dungeonId');
  }

  /// 파티원 정보 업데이트
  Future<void> updateMemberStatus({
    required String partyId,
    required String userId,
    int? currentHp,
    bool? isOnline,
  }) async {
    final party = _parties[partyId];
    if (party == null) return;

    final updatedMembers = party.members.map((m) {
      if (m.userId == userId) {
        return PartyMember(
          userId: m.userId,
          username: m.username,
          level: m.level,
          power: m.power,
          role: m.role,
          currentHp: currentHp ?? m.currentHp,
          maxHp: m.maxHp,
          isReady: m.isReady,
          isOnline: isOnline ?? m.isOnline,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    final updated = Party(
      id: party.id,
      name: party.name,
      members: updatedMembers,
      activeQuest: party.activeQuest,
      activeDungeon: party.activeDungeon,
      expDistribution: party.expDistribution,
      isPublic: party.isPublic,
      maxMembers: party.maxMembers,
      minLevel: party.minLevel,
      levelRange: party.levelRange,
      createdAt: party.createdAt,
      activityAt: DateTime.now(),
    );

    _parties[partyId] = updated;
    _partyController.add(updated);

    final updatedMember = updatedMembers.firstWhere((m) => m.userId == userId);
    _memberController.add(updatedMember);
  }

  /// 파티 검색
  List<Party> searchParties({
    int? minLevel,
    int? maxLevel,
    bool? isPublic,
  }) {
    var parties = _parties.values.where((p) => p.canJoin).toList();

    if (minLevel != null) {
      parties = parties.where((p) => p.minLevel >= minLevel).toList();
    }

    if (maxLevel != null) {
      parties = parties.where((p) => p.minLevel <= maxLevel).toList();
    }

    if (isPublic != null) {
      parties = parties.where((p) => p.isPublic == isPublic).toList();
    }

    return parties..sort((a, b) => b.activityAt!.compareTo(a.activityAt!));
  }

  /// 파티 조회
  Party? getParty(String partyId) {
    return _parties[partyId];
  }

  /// 사용자의 파티 조회
  Party? getUserParty(String userId) {
    try {
      return _parties.values.firstWhere((p) => p.members.any((m) => m.userId == userId));
    } catch (e) {
      return null;
    }
  }

  /// 던전 목록
  List<PartyDungeon> getDungeons({int? userLevel}) {
    var dungeons = _dungeons.values.toList();

    if (userLevel != null) {
      dungeons = dungeons.where((d) =>
          userLevel >= d.minLevel && userLevel <= d.maxLevel).toList();
    }

    return dungeons;
  }

  Future<void> _saveParty(Party party) async {
    await _prefs?.setString(
      'party_${party.id}',
      jsonEncode({
        'id': party.id,
        'name': party.name,
        'maxMembers': party.maxMembers,
        'currentMembers': party.currentMembers,
      }),
    );
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    return {
      'totalParties': _parties.length,
      'totalMembers': _parties.values.fold<int>(
          0, (sum, p) => sum + p.currentMembers),
      'publicParties': _parties.values.where((p) => p.isPublic).length,
      'activeQuests': _parties.values.where((p) => p.activeQuest != null).length,
      'activeDungeons': _parties.values.where((p) => p.activeDungeon != null).length,
    };
  }

  void dispose() {
    _partyController.close();
    _memberController.close();
    _questController.close();
  }
}

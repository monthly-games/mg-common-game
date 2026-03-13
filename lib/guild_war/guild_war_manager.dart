import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 길드전 타입
enum GuildWarType {
  conquest,      // 정복전
  raid,          // 습격전
  territorial,   // 영토전
  domination,    // 지배전
  tournament,    // 토너먼트
}

/// 길드전 상태
enum GuildWarStatus {
  preparation,   // 준비 중
  inProgress,    // 진행 중
  completed,     // 완료
  cancelled,     // 취소됨
}

/// 영지 타입
enum TerritoryType {
  capital,       // 수도
  city,          // 도시
  fortress,      // 요새
  resource,      // 자원지
  outpost,       // 전초기지
}

/// 방어 시설
class DefenseStructure {
  final String id;
  final String name;
  final int health;
  final int maxHealth;
  final int defenseBonus;
  final bool isDestroyed;

  const DefenseStructure({
    required this.id,
    required this.name,
    required this.health,
    required this.maxHealth,
    this.defenseBonus = 0,
    this.isDestroyed = false,
  });
}

/// 영지
class Territory {
  final String id;
  final String name;
  final TerritoryType type;
  final String? ownerId; // 길드 ID
  final List<DefenseStructure> defenses;
  final int resourceValue;
  final double taxRate;
  final DateTime? lastConquered;

  const Territory({
    required this.id,
    required this.name,
    required this.type,
    this.ownerId,
    this.defenses = const [],
    this.resourceValue = 100,
    this.taxRate = 0.1,
    this.lastConquered,
  });

  /// 방어력
  int get totalDefense {
    if (defenses.isEmpty) return 0;
    return defenses.fold<int>(
        0,
        (sum, d) => sum + (d.isDestroyed ? 0 : d.defenseBonus));
  }
}

/// 길드전 참가자
class GuildWarParticipant {
  final String guildId;
  final String guildName;
  final String? emblemUrl;
  final int score;
  final int territoriesOwned;
  final int memberCount;
  final bool isAttacker;

  const GuildWarParticipant({
    required this.guildId,
    required this.guildName,
    this.emblemUrl,
    required this.score,
    required this.territoriesOwned,
    required this.memberCount,
    this.isAttacker = false,
  });
}

/// 길드전 배틀
class GuildWarBattle {
  final String id;
  final String territoryId;
  final String attackerGuildId;
  final String defenderGuildId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? winnerId;
  final int attackerScore;
  final int defenderScore;
  final List<String> battleLog;
  final bool isCompleted;

  const GuildWarBattle({
    required this.id,
    required this.territoryId,
    required this.attackerGuildId,
    required this.defenderGuildId,
    required this.startTime,
    this.endTime,
    this.winnerId,
    this.attackerScore = 0,
    this.defenderScore = 0,
    this.battleLog = const [],
    this.isCompleted = false,
  });
}

/// 길드전 보상
class GuildWarReward {
  final String id;
  final String type; // gold, gems, items, territory
  final String name;
  final int amount;
  final String? itemId;
  final String? territoryId;

  const GuildWarReward({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    this.itemId,
    this.territoryId,
  });
}

/// 길드전
class GuildWar {
  final String id;
  final String name;
  final GuildWarType type;
  final GuildWarStatus status;
  final List<GuildWarParticipant> participants;
  final List<Territory> territories;
  final List<GuildWarBattle> battles;
  final DateTime startTime;
  final DateTime endTime;
  final List<GuildWarReward> rewards;
  final Map<String, dynamic> rules;

  const GuildWar({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.participants,
    required this.territories,
    required this.battles,
    required this.startTime,
    required this.endTime,
    this.rewards = const [],
    this.rules = const {},
  });

  /// 남은 시간
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
}

/// 길드전 관리자
class GuildWarManager {
  static final GuildWarManager _instance = GuildWarManager._();
  static GuildWarManager get instance => _instance;

  GuildWarManager._();

  SharedPreferences? _prefs;
  String? _currentGuildId;

  final Map<String, GuildWar> _guildWars = {};
  final Map<String, Territory> _territories = {};

  final StreamController<GuildWar> _warController =
      StreamController<GuildWar>.broadcast();
  final StreamController<GuildWarBattle> _battleController =
      StreamController<GuildWarBattle>.broadcast();

  Stream<GuildWar> get onWarUpdate => _warController.stream;
  Stream<GuildWarBattle> get onBattleUpdate => _battleController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentGuildId = _prefs?.getString('guild_id');

    // 영지 로드
    _loadTerritories();

    // 길드전 로드
    _loadGuildWars();

    debugPrint('[GuildWar] Initialized');
  }

  void _loadTerritories() {
    _territories.addAll({
      'capital_1': const Territory(
        id: 'capital_1',
        name: '왕도',
        type: TerritoryType.capital,
        ownerId: 'guild_1',
        defenses: [
          DefenseStructure(
            id: 'wall_1',
            name: '성벽',
            health: 1000,
            maxHealth: 1000,
            defenseBonus: 50,
          ),
          DefenseStructure(
            id: 'tower_1',
            name: '포탑',
            health: 500,
            maxHealth: 500,
            defenseBonus: 30,
          ),
        ],
        resourceValue: 1000,
        taxRate: 0.2,
      ),
      'city_1': const Territory(
        id: 'city_1',
        name: '상업 도시',
        type: TerritoryType.city,
        ownerId: 'guild_2',
        defenses: [
          DefenseStructure(
            id: 'wall_2',
            name: '성벽',
            health: 500,
            maxHealth: 500,
            defenseBonus: 20,
          ),
        ],
        resourceValue: 500,
        taxRate: 0.15,
      ),
      'fortress_1': const Territory(
        id: 'fortress_1',
        name: '국경 요새',
        type: TerritoryType.fortress,
        ownerId: null,
        defenses: [
          DefenseStructure(
            id: 'fortress_wall',
            name: '요새 벽',
            health: 1500,
            maxHealth: 1500,
            defenseBonus: 100,
          ),
        ],
        resourceValue: 200,
        taxRate: 0.1,
      ),
    });
  }

  void _loadGuildWars() {
    // 시뮬레이션: 진행 중인 길드전
    final now = DateTime.now();

    _guildWars['war_1'] = GuildWar(
      id: 'war_1',
      name: '시즌 1 길드전',
      type: GuildWarType.conquest,
      status: GuildWarStatus.inProgress,
      participants: [
        const GuildWarParticipant(
          guildId: 'guild_1',
          guildName: '용사들의 길드',
          score: 1500,
          territoriesOwned: 2,
          memberCount: 50,
          isAttacker: true,
        ),
        const GuildWarParticipant(
          guildId: 'guild_2',
          guildName: '마법사들의 길드',
          score: 1200,
          territoriesOwned: 1,
          memberCount: 45,
          isAttacker: false,
        ),
      ],
      territories: _territories.values.toList(),
      battles: [
        GuildWarBattle(
          id: 'battle_1',
          territoryId: 'city_1',
          attackerGuildId: 'guild_1',
          defenderGuildId: 'guild_2',
          startTime: now.subtract(const Duration(hours: 1)),
          attackerScore: 50,
          defenderScore: 30,
          battleLog: [
            '길드1이 공격을 시작했습니다.',
            '길드2가 방어에 성공했습니다.',
          ],
        ),
      ],
      startTime: now.subtract(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 6)),
      rules: {
        'maxParticipants': 50,
        'battleDuration': 30, // minutes
        'territoryCap': 5,
      },
    );
  }

  /// 길드전 생성
  Future<GuildWar> createGuildWar({
    required String name,
    required GuildWarType type,
    required List<String> participantGuildIds,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? rules,
  }) async {
    final participants = participantGuildIds.map((guildId) {
      return GuildWarParticipant(
        guildId: guildId,
        guildName: '길드 $guildId',
        score: 0,
        territoriesOwned: 0,
        memberCount: 50,
        isAttacker: false,
      );
    }).toList();

    final war = GuildWar(
      id: 'war_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      status: GuildWarStatus.preparation,
      participants: participants,
      territories: _territories.values.toList(),
      battles: [],
      startTime: startTime,
      endTime: endTime,
      rules: rules ?? {},
    );

    _guildWars[war.id] = war;
    _warController.add(war);

    debugPrint('[GuildWar] Created: ${war.name}');
    return war;
  }

  /// 길드전 시작
  Future<void> startGuildWar(String warId) async {
    final war = _guildWars[warId];
    if (war == null) return;

    final updated = GuildWar(
      id: war.id,
      name: war.name,
      type: war.type,
      status: GuildWarStatus.inProgress,
      participants: war.participants,
      territories: war.territories,
      battles: war.battles,
      startTime: war.startTime,
      endTime: war.endTime,
      rewards: war.rewards,
      rules: war.rules,
    );

    _guildWars[warId] = updated;
    _warController.add(updated);

    debugPrint('[GuildWar] Started: $warId');
  }

  /// 공격 시작
  Future<GuildWarBattle> startAttack({
    required String warId,
    required String attackerGuildId,
    required String territoryId,
  }) async {
    final war = _guildWars[warId];
    if (war == null) throw Exception('War not found');

    final territory = _territories[territoryId];
    if (territory == null) throw Exception('Territory not found');

    final battle = GuildWarBattle(
      id: 'battle_${DateTime.now().millisecondsSinceEpoch}',
      territoryId: territoryId,
      attackerGuildId: attackerGuildId,
      defenderGuildId: territory.ownerId ?? 'system',
      startTime: DateTime.now(),
      battleLog: [
        '$attackerGuildId가 $territoryId를 공격했습니다.',
      ],
    );

    final updated = GuildWar(
      id: war.id,
      name: war.name,
      type: war.type,
      status: war.status,
      participants: war.participants,
      territories: war.territories,
      battles: [...war.battles, battle],
      startTime: war.startTime,
      endTime: war.endTime,
      rewards: war.rewards,
      rules: war.rules,
    );

    _guildWars[warId] = updated;
    _battleController.add(battle);

    debugPrint('[GuildWar] Attack started: $territoryId');
    return battle;
  }

  /// 배틀 결과 업데이트
  Future<void> updateBattleResult({
    required String warId,
    required String battleId,
    required int attackerScore,
    required int defenderScore,
    required String winnerId,
  }) async {
    final war = _guildWars[warId];
    if (war == null) return;

    final battleIndex = war.battles.indexWhere((b) => b.id == battleId);
    if (battleIndex == -1) return;

    final battle = war.battles[battleIndex];
    final territory = _territories[battle.territoryId];

    final updatedBattle = GuildWarBattle(
      id: battle.id,
      territoryId: battle.territoryId,
      attackerGuildId: battle.attackerGuildId,
      defenderGuildId: battle.defenderGuildId,
      startTime: battle.startTime,
      endTime: DateTime.now(),
      winnerId: winnerId,
      attackerScore: attackerScore,
      defenderScore: defenderScore,
      battleLog: [...battle.battleLog, '배틀 종료: $winnerId 승리!'],
      isCompleted: true,
    );

    // 영지 소유권 변경
    Territory? updatedTerritory;
    if (winnerId != battle.defenderGuildId && territory != null) {
      updatedTerritory = Territory(
        id: territory.id,
        name: territory.name,
        type: territory.type,
        ownerId: winnerId,
        defenses: territory.defenses,
        resourceValue: territory.resourceValue,
        taxRate: territory.taxRate,
        lastConquered: DateTime.now(),
      );
      _territories[territory.id] = updatedTerritory;
    }

    final updatedBattles = List<GuildWarBattle>.from(war.battles);
    updatedBattles[battleIndex] = updatedBattle;

    final updated = GuildWar(
      id: war.id,
      name: war.name,
      type: war.type,
      status: war.status,
      participants: _updateParticipantScores(
        war.participants,
        updatedBattle,
        updatedTerritory,
      ),
      territories: updatedTerritory != null
          ? war.territories.map((t) => t.id == updatedTerritory.id ? updatedTerritory : t).toList()
          : war.territories,
      battles: updatedBattles,
      startTime: war.startTime,
      endTime: war.endTime,
      rewards: war.rewards,
      rules: war.rules,
    );

    _guildWars[warId] = updated;
    _warController.add(updated);
    _battleController.add(updatedBattle);

    debugPrint('[GuildWar] Battle result updated: $battleId');
  }

  List<GuildWarParticipant> _updateParticipantScores(
    List<GuildWarParticipant> participants,
    GuildWarBattle battle,
    Territory? conqueredTerritory,
  ) {
    return participants.map((p) {
      int newScore = p.score;
      int newTerritories = p.territoriesOwned;

      if (p.guildId == battle.winnerId) {
        newScore += 100;
        if (conqueredTerritory != null) {
          newTerritories++;
        }
      } else if (p.guildId == battle.attackerGuildId || p.guildId == battle.defenderGuildId) {
        newScore += 50; // 참여 보너스
      }

      return GuildWarParticipant(
        guildId: p.guildId,
        guildName: p.guildName,
        emblemUrl: p.emblemUrl,
        score: newScore,
        territoriesOwned: newTerritories,
        memberCount: p.memberCount,
        isAttacker: p.isAttacker,
      );
    }).toList();
  }

  /// 길드전 종료
  Future<void> endGuildWar(String warId) async {
    final war = _guildWars[warId];
    if (war == null) return;

    // 우승자 결정
    final winner = war.participants.reduce((a, b) =>
        a.score > b.score ? a : b);

    // 보상 지급
    final rewards = _calculateRewards(war, winner.guildId);

    final updated = GuildWar(
      id: war.id,
      name: war.name,
      type: war.type,
      status: GuildWarStatus.completed,
      participants: war.participants,
      territories: war.territories,
      battles: war.battles,
      startTime: war.startTime,
      endTime: DateTime.now(),
      rewards: rewards,
      rules: war.rules,
    );

    _guildWars[warId] = updated;
    _warController.add(updated);

    debugPrint('[GuildWar] Ended: ${war.name}, Winner: ${winner.guildName}');
  }

  List<GuildWarReward> _calculateRewards(GuildWar war, String winnerId) {
    return [
      const GuildWarReward(
        id: 'reward_1',
        type: 'gold',
        name: '우승 보상',
        amount: 100000,
      ),
      const GuildWarReward(
        id: 'reward_2',
        type: 'gems',
        name: '참여 보상',
        amount: 500,
      ),
    ];
  }

  /// 영지 조회
  Territory? getTerritory(String territoryId) {
    return _territories[territoryId];
  }

  /// 모든 영지 조회
  List<Territory> getTerritories() {
    return _territories.values.toList();
  }

  /// 길드의 영지
  List<Territory> getGuildTerritories(String guildId) {
    return _territories.values
        .where((t) => t.ownerId == guildId)
        .toList();
  }

  /// 길드전 조회
  GuildWar? getGuildWar(String warId) {
    return _guildWars[warId];
  }

  /// 모든 길드전 조회
  List<GuildWar> getGuildWars({GuildWarStatus? status}) {
    var wars = _guildWars.values.toList();

    if (status != null) {
      wars = wars.where((w) => w.status == status).toList();
    }

    return wars;
  }

  /// 길드의 진행 중인 길드전
  List<GuildWar> getGuildWarsForGuild(String guildId) {
    return _guildWars.values
        .where((w) =>
            w.status == GuildWarStatus.inProgress &&
            w.participants.any((p) => p.guildId == guildId))
        .toList();
  }

  /// 영지 방어 시설 업그레이드
  Future<void> upgradeDefense({
    required String territoryId,
    required String structureId,
    required int upgradeAmount,
  }) async {
    final territory = _territories[territoryId];
    if (territory == null) return;

    final structureIndex = territory.defenses
        .indexWhere((d) => d.id == structureId);
    if (structureIndex == -1) return;

    final structure = territory.defenses[structureIndex];
    final upgraded = DefenseStructure(
      id: structure.id,
      name: structure.name,
      health: structure.health + upgradeAmount,
      maxHealth: structure.maxHealth + upgradeAmount,
      defenseBonus: structure.defenseBonus + (upgradeAmount ~/ 10),
      isDestroyed: structure.isDestroyed,
    );

    final upgradedDefenses = List<DefenseStructure>.from(territory.defenses);
    upgradedDefenses[structureIndex] = upgraded;

    final updated = Territory(
      id: territory.id,
      name: territory.name,
      type: territory.type,
      ownerId: territory.ownerId,
      defenses: upgradedDefenses,
      resourceValue: territory.resourceValue,
      taxRate: territory.taxRate,
      lastConquered: territory.lastConquered,
    );

    _territories[territoryId] = updated;

    debugPrint('[GuildWar] Defense upgraded: $structureId');
  }

  /// 세금 수집
  Future<double> collectTaxes(String guildId) async {
    final territories = getGuildTerrories(guildId);
    if (territories.isEmpty) return 0.0;

    final totalTax = territories.fold<double>(
        0.0,
        (sum, t) => sum + (t.resourceValue * t.taxRate));

    debugPrint('[GuildWar] Tax collected: $guildId - $totalTax');

    return totalTax;
  }

  void dispose() {
    _warController.close();
    _battleController.close();
  }
}

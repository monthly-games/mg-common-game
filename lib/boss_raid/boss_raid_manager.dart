import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 레이드 난이도
enum RaidDifficulty {
  normal,      // 일반
  heroic,      // 영웅
  mythic,      // 신화
  nightmare,   // 악몽
}

/// 레이드 상태
enum RaidStatus {
  waiting,     // 대기 중
  inProgress,  // 진행 중
  completed,   // 완료
  failed,      // 실패
  abandoned,   // 포기
}

/// 보스 공격 패턴
class BossAttackPattern {
  final String id;
  final String name;
  final String description;
  final int damage;
  final double range;
  final Duration chargeTime;
  final Duration cooldown;
  final String? weakness;

  const BossAttackPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.damage,
    required this.range,
    required this.chargeTime,
    required this.cooldown,
    this.weakness,
  });
}

/// 보스 약점
class BossWeakness {
  final String id;
  final String name;
  final String element; // fire, ice, lightning, etc.
  final double multiplier; // 데미지 배율
  final String? description;

  const BossWeakness({
    required this.id,
    required this.name,
    required this.element,
    required this.multiplier,
    this.description,
  });
}

/// 레이드 보스
class RaidBoss {
  final String id;
  final String name;
  final String description;
  final int level;
  final int maxHealth;
  final int currentHealth;
  final List<BossAttackPattern> attackPatterns;
  final List<BossWeakness> weaknesses;
  final String? imageUrl;
  final Map<String, dynamic>? stats;

  const RaidBoss({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.maxHealth,
    required this.currentHealth,
    required this.attackPatterns,
    required this.weaknesses,
    this.imageUrl,
    this.stats,
  });

  /// 남은 체력 비율
  double get healthPercent => maxHealth > 0 ? currentHealth / maxHealth : 0.0;

  /// 생존 여부
  bool get isAlive => currentHealth > 0;
}

/// 레이드 참가자
class RaidParticipant {
  final String userId;
  final String username;
  final int level;
  final int power;
  final String role; // tank, healer, dps
  final int damage;
  final int healing;
  final bool isAlive;
  final DateTime? joinedAt;

  const RaidParticipant({
    required this.userId,
    required this.username,
    required this.level,
    required this.power,
    required this.role,
    this.damage = 0,
    this.healing = 0,
    this.isAlive = true,
    this.joinedAt,
  });
}

/// 레이드 전리
class RaidLoot {
  final String id;
  final String name;
  final String type; // weapon, armor, accessory, material
  final int amount;
  final double dropRate;
  final String? imageUrl;
  final int minItemLevel;
  final int maxItemLevel;

  const RaidLoot({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dropRate,
    this.imageUrl,
    this.minItemLevel = 1,
    this.maxItemLevel = 100,
  });
}

/// 보스 레이드
class BossRaid {
  final String id;
  final String name;
  final String description;
  final RaidDifficulty difficulty;
  final RaidStatus status;
  final List<RaidBoss> bosses;
  final List<RaidParticipant> participants;
  final List<RaidLoot> lootTable;
  final DateTime startTime;
  final DateTime? endTime;
  final int maxParticipants;
  final Duration timeLimit;
  final Map<String, dynamic>? metadata;

  const BossRaid({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.status,
    required this.bosses,
    required this.participants,
    required this.lootTable,
    required this.startTime,
    this.endTime,
    required this.maxParticipants,
    required this.timeLimit,
    this.metadata,
  });

  /// 진행 중인지
  bool get isInProgress => status == RaidStatus.inProgress;

  /// 완료되었는지
  bool get isCompleted => status == RaidStatus.completed;

  /// 남은 시간
  Duration? get remainingTime {
    if (endTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endTime!)) return Duration.zero;
    return endTime!.difference(now);
  }

  /// 전체 데미지
  int getTotalDamage() {
    return participants.fold<int>(0, (sum, p) => sum + p.damage);
  }

  /// 전체 힐링
  int getTotalHealing() {
    return participants.fold<int>(0, (sum, p) => sum + p.healing);
  }
}

/// 동적 난이도 조정
class DynamicDifficulty {
  final int currentDifficulty;
  final double playerPerformance;
  final int adjustFrequency; // seconds

  const DynamicDifficulty({
    required this.currentDifficulty,
    required this.playerPerformance,
    required this.adjustFrequency,
  });

  DynamicDifficulty withPerformance(double performance) {
    final newDifficulty = performance > 0.7
        ? (currentDifficulty + 1).clamp(1, 10)
        : (currentDifficulty - 1).clamp(1, 10);

    return DynamicDifficulty(
      currentDifficulty: newDifficulty,
      playerPerformance: performance,
      adjustFrequency: adjustFrequency,
    );
  }
}

/// 보스 레이드 관리자
class BossRaidManager {
  static final BossRaidManager _instance = BossRaidManager._();
  static BossRaidManager get instance => _instance;

  BossRaidManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, BossRaid> _raids = {};
  final Map<String, List<BossRaid>> _userRaids = {};

  final StreamController<BossRaid> _raidController =
      StreamController<BossRaid>.broadcast();
  final StreamController<RaidBoss> _bossController =
      StreamController<RaidBoss>.broadcast();

  Stream<BossRaid> get onRaidUpdate => _raidController.stream;
  Stream<RaidBoss> get onBossUpdate => _bossController.stream;

  Timer? _raidTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 레이드 로드
    await _loadRaids();

    debugPrint('[BossRaid] Initialized');
  }

  Future<void> _loadRaids() async {
    // 기본 레이드 생성
    final dragonBoss = RaidBoss(
      id: 'dragon_boss',
      name: '고대 용',
      description: '불의 브레스를 내뿜는 고대 용',
      level: 100,
      maxHealth: 1000000,
      currentHealth: 1000000,
      attackPatterns: [
        const BossAttackPattern(
          id: 'fire_breath',
          name: '불의 브레스',
          description: '전방에 불을 뿜음',
          damage: 50000,
          range: 500.0,
          chargeTime: Duration(seconds: 3),
          cooldown: Duration(seconds: 30),
          weakness: 'ice',
        ),
        const BossAttackPattern(
          id: 'tail_swipe',
          name: '꼬리치기',
          description: '주변 적을 공격',
          damage: 30000,
          range: 200.0,
          chargeTime: Duration(milliseconds: 500),
          cooldown: Duration(seconds: 10),
        ),
      ],
      weaknesses: const [
        BossWeakness(
          id: 'ice_weakness',
          name: '얼음 약점',
          element: 'ice',
          multiplier: 1.5,
          description: '얼음 속성에 1.5배 데미지',
        ),
      ],
    );

    _raids['dragon_raid'] = BossRaid(
      id: 'dragon_raid',
      name: '용의 둥지',
      description: '고대 용이 서식하는 둥지',
      difficulty: RaidDifficulty.heroic,
      status: RaidStatus.waiting,
      bosses: [dragonBoss],
      participants: [],
      lootTable: [
        const RaidLoot(
          id: 'dragon_scale',
          name: '용의 비늘',
          type: 'material',
          amount: 10,
          dropRate: 0.5,
          minItemLevel: 80,
          maxItemLevel: 100,
        ),
        const RaidLoot(
          id: 'dragon_sword',
          name: '용검',
          type: 'weapon',
          amount: 1,
          dropRate: 0.1,
          minItemLevel: 90,
          maxItemLevel: 100,
        ),
      ],
      startTime: DateTime.now(),
      maxParticipants: 10,
      timeLimit: const Duration(hours: 2),
    );
  }

  /// 레이드 생성
  Future<BossRaid> createRaid({
    required String name,
    required String description,
    required RaidDifficulty difficulty,
    required List<RaidBoss> bosses,
    required List<RaidLoot> lootTable,
    int maxParticipants = 10,
    Duration? timeLimit,
  }) async {
    final raid = BossRaid(
      id: 'raid_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      difficulty: difficulty,
      status: RaidStatus.waiting,
      bosses: bosses,
      participants: [],
      lootTable: lootTable,
      startTime: DateTime.now(),
      maxParticipants: maxParticipants,
      timeLimit: timeLimit ?? const Duration(hours: 2),
    );

    _raids[raid.id] = raid;
    _raidController.add(raid);

    debugPrint('[BossRaid] Raid created: ${raid.name}');

    return raid;
  }

  /// 레이드 참가
  Future<void> joinRaid({
    required String raidId,
    required RaidParticipant participant,
  }) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    if (raid.participants.length >= raid.maxParticipants) {
      throw Exception('Raid is full');
    }

    final updated = BossRaid(
      id: raid.id,
      name: raid.name,
      description: raid.description,
      difficulty: raid.difficulty,
      status: raid.status,
      bosses: raid.bosses,
      participants: [...raid.participants, participant],
      lootTable: raid.lootTable,
      startTime: raid.startTime,
      endTime: raid.endTime,
      maxParticipants: raid.maxParticipants,
      timeLimit: raid.timeLimit,
      metadata: raid.metadata,
    );

    _raids[raidId] = updated;
    _raidController.add(updated);

    debugPrint('[BossRaid] Joined raid: ${raid.name} - ${participant.username}');
  }

  /// 레이드 시작
  Future<void> startRaid(String raidId) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    final updated = BossRaid(
      id: raid.id,
      name: raid.name,
      description: raid.description,
      difficulty: raid.difficulty,
      status: RaidStatus.inProgress,
      bosses: raid.bosses,
      participants: raid.participants,
      lootTable: raid.lootTable,
      startTime: raid.startTime,
      endTime: DateTime.now().add(raid.timeLimit),
      maxParticipants: raid.maxParticipants,
      timeLimit: raid.timeLimit,
      metadata: raid.metadata,
    );

    _raids[raidId] = updated;
    _raidController.add(updated);

    // 타이머 시작
    _startRaidTimer(raidId);

    debugPrint('[BossRaid] Raid started: ${raid.name}');
  }

  void _startRaidTimer(String raidId) {
    _raidTimer?.cancel();
    _raidTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final raid = _raids[raidId];
      if (raid == null || !raid.isInProgress) {
        _raidTimer?.cancel();
        return;
      }

      // 시간 초과 체크
      if (raid.remainingTime == Duration.zero) {
        _raidTimer?.cancel();
        _failRaid(raidId);
        return;
      }

      // 보스 공격 패턴 실행
      _executeBossPatterns(raid);
    });
  }

  void _executeBossPatterns(BossRaid raid) {
    for (final boss in raid.bosses) {
      if (!boss.isAlive) continue;

      for (final pattern in boss.attackPatterns) {
        // 공격 패턴 실행 (시뮬레이션)
        final random = Random();
        if (random.nextDouble() < 0.1) { // 10% 확률로 공격
          _bossController.add(boss);
          debugPrint('[BossRaid] Boss attack: ${boss.name} - ${pattern.name}');
        }
      }
    }
  }

  /// 보스 공격
  Future<void> attackBoss({
    required String raidId,
    required String bossId,
    required String userId,
    required int damage,
    String? element,
  }) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    final bossIndex = raid.bosses.indexWhere((b) => b.id == bossId);
    if (bossIndex == -1) return;

    final boss = raid.bosses[bossIndex];

    // 약점 체크
    double finalDamage = damage.toDouble();
    for (final weakness in boss.weaknesses) {
      if (element == weakness.element) {
        finalDamage *= weakness.multiplier;
      }
    }

    // 체력 감소
    final newHealth = max(0, boss.currentHealth - finalDamage.toInt());

    final updatedBoss = RaidBoss(
      id: boss.id,
      name: boss.name,
      description: boss.description,
      level: boss.level,
      maxHealth: boss.maxHealth,
      currentHealth: newHealth,
      attackPatterns: boss.attackPatterns,
      weaknesses: boss.weaknesses,
      imageUrl: boss.imageUrl,
      stats: boss.stats,
    );

    // 참가자 데미지 업데이트
    final updatedParticipants = raid.participants.map((p) {
      if (p.userId == userId) {
        return RaidParticipant(
          userId: p.userId,
          username: p.username,
          level: p.level,
          power: p.power,
          role: p.role,
          damage: p.damage + damage,
          healing: p.healing,
          isAlive: p.isAlive,
          joinedAt: p.joinedAt,
        );
      }
      return p;
    }).toList();

    final updatedBosses = List<RaidBoss>.from(raid.bosses);
    updatedBosses[bossIndex] = updatedBoss;

    final updated = BossRaid(
      id: raid.id,
      name: raid.name,
      description: raid.description,
      difficulty: raid.difficulty,
      status: raid.status,
      bosses: updatedBosses,
      participants: updatedParticipants,
      lootTable: raid.lootTable,
      startTime: raid.startTime,
      endTime: raid.endTime,
      maxParticipants: raid.maxParticipants,
      timeLimit: raid.timeLimit,
      metadata: raid.metadata,
    );

    _raids[raidId] = updated;
    _bossController.add(updatedBoss);
    _raidController.add(updated);

    // 보스 처치 체크
    if (!updatedBoss.isAlive) {
      await _onBossDefeated(raidId, bossId);
    }

    debugPrint('[BossRaid] Boss attacked: $bossId - ${finalDamage.toInt()} damage');
  }

  /// 보스 처치
  Future<void> _onBossDefeated(String raidId, String bossId) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    debugPrint('[BossRaid] Boss defeated: $bossId');

    // 모든 보스 처치 체크
    final allBossesDefeated = raid.bosses.every((b) => !b.isAlive);

    if (allBossesDefeated) {
      await _completeRaid(raidId);
    }
  }

  /// 레이드 완료
  Future<void> _completeRaid(String raidId) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    final updated = BossRaid(
      id: raid.id,
      name: raid.name,
      description: raid.description,
      difficulty: raid.difficulty,
      status: RaidStatus.completed,
      bosses: raid.bosses,
      participants: raid.participants,
      lootTable: raid.lootTable,
      startTime: raid.startTime,
      endTime: DateTime.now(),
      maxParticipants: raid.maxParticipants,
      timeLimit: raid.timeLimit,
      metadata: raid.metadata,
    );

    _raids[raidId] = updated;
    _raidController.add(updated);

    // 전리 지급
    await _distributeLoot(raidId);

    debugPrint('[BossRaid] Raid completed: ${raid.name}');
  }

  /// 전리 지급
  Future<void> _distributeLoot(String raidId) async {
    final raid = _raids[raidId];
    if (raid == null) return;

    for (final participant in raid.participants) {
      for (final loot in raid.lootTable) {
        // 드롭 확률 체크
        final random = Random();
        if (random.nextDouble() < loot.dropRate) {
          // 전리 지급
          debugPrint('[BossRaid] Loot distributed: ${participant.username} - ${loot.name}');
        }
      }
    }
  }

  /// 레이드 실패
  void _failRaid(String raidId) {
    final raid = _raids[raidId];
    if (raid == null) return;

    final updated = BossRaid(
      id: raid.id,
      name: raid.name,
      description: raid.description,
      difficulty: raid.difficulty,
      status: RaidStatus.failed,
      bosses: raid.bosses,
      participants: raid.participants,
      lootTable: raid.lootTable,
      startTime: raid.startTime,
      endTime: DateTime.now(),
      maxParticipants: raid.maxParticipants,
      timeLimit: raid.timeLimit,
      metadata: raid.metadata,
    );

    _raids[raidId] = updated;
    _raidController.add(updated);

    debugPrint('[BossRaid] Raid failed: ${raid.name}');
  }

  /// 동적 난이도 조정
  void adjustDifficulty({
    required String raidId,
    required double playerPerformance,
  }) {
    final raid = _raids[raidId];
    if (raid == null) return;

    // 난이도 조정 (시뮬레이션)
    final currentDifficulty = raid.metadata?['difficulty'] as int? ?? 5;
    final newDifficulty = playerPerformance > 0.7
        ? (currentDifficulty + 1).clamp(1, 10)
        : (currentDifficulty - 1).clamp(1, 10);

    debugPrint('[BossRaid] Difficulty adjusted: $raidId - $newDifficulty');
  }

  /// 레이드 조회
  BossRaid? getRaid(String raidId) {
    return _raids[raidId];
  }

  /// 사용자의 레이드 목록
  List<BossRaid> getUserRaids(String userId) {
    return _userRaids[userId] ?? [];
  }

  /// 진행 중인 레이드
  List<BossRaid> getInProgressRaids() {
    return _raids.values.where((r) => r.isInProgress).toList();
  }

  void dispose() {
    _raidTimer?.cancel();
    _raidController.close();
    _bossController.close();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

enum CombatType {
  turnBased,
  realTime,
  autoBattle,
}

enum CombatStatus {
  notStarted,
  inProgress,
  paused,
  victory,
  defeat,
  draw,
}

enum UnitState {
  idle,
  moving,
  attacking,
  casting,
  damaged,
  dead,
}

class CombatUnit {
  final String unitId;
  final String name;
  final int maxHp;
  final int maxMp;
  final int attack;
  final int defense;
  final int speed;
  final bool isPlayer;
  UnitState state;
  int currentHp;
  int currentMp;
  final List<String> skillIds;
  final List<Buff> activeBuffs;
  int position;

  CombatUnit({
    required this.unitId,
    required this.name,
    required this.maxHp,
    required this.maxMp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.isPlayer,
    this.state = UnitState.idle,
    this.currentHp = 0,
    this.currentMp = 0,
    this.skillIds = const [],
    this.activeBuffs = const [],
    this.position = 0,
  }) {
    currentHp = maxHp;
    currentMp = maxMp;
  }

  bool get isAlive => currentHp > 0;
  double get hpPercent => currentHp / maxHp;
  double get mpPercent => currentMp / maxMp;

  CombatUnit copyWith({
    String? unitId,
    String? name,
    int? maxHp,
    int? maxMp,
    int? attack,
    int? defense,
    int? speed,
    bool? isPlayer,
    UnitState? state,
    int? currentHp,
    int? currentMp,
    List<String>? skillIds,
    List<Buff>? activeBuffs,
    int? position,
  }) {
    return CombatUnit(
      unitId: unitId ?? this.unitId,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      maxMp: maxMp ?? this.maxMp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      isPlayer: isPlayer ?? this.isPlayer,
      state: state ?? this.state,
      currentHp: currentHp ?? this.currentHp,
      currentMp: currentMp ?? this.currentMp,
      skillIds: skillIds ?? this.skillIds,
      activeBuffs: activeBuffs ?? this.activeBuffs,
      position: position ?? this.position,
    );
  }
}

class Buff {
  final String buffId;
  final String name;
  final BuffType type;
  final int value;
  final int duration;
  final DateTime startTime;
  final String? sourceUnitId;

  const Buff({
    required this.buffId,
    required this.name,
    required this.type,
    required this.value,
    required this.duration,
    required this.startTime,
    this.sourceUnitId,
  });

  int get remainingTurns => duration - DateTime.now().difference(startTime).inSeconds;
  bool get isActive => remainingTurns > 0;
}

enum BuffType {
  attackBoost,
  defenseBoost,
  speedBoost,
  hpRegen,
  mpRegen,
  poison,
  stun,
  silence,
}

class CombatAction {
  final String actionId;
  final String sourceUnitId;
  final String? targetUnitId;
  final ActionType type;
  final String? skillId;
  final int damage;
  final DateTime timestamp;

  const CombatAction({
    required this.actionId,
    required this.sourceUnitId,
    this.targetUnitId,
    required this.type,
    this.skillId,
    required this.damage,
    required this.timestamp,
  });
}

enum ActionType {
  attack,
  skill,
  defend,
  item,
  escape,
}

class CombatLog {
  final String logId;
  final String message;
  final DateTime timestamp;
  final CombatLogType type;

  const CombatLog({
    required this.logId,
    required this.message,
    required this.timestamp,
    required this.type,
  });
}

enum CombatLogType {
  info,
  damage,
  heal,
  buff,
  debuff,
  system,
}

class CombatSystemManager {
  static final CombatSystemManager _instance = CombatSystemManager._();
  static CombatSystemManager get instance => _instance;

  CombatSystemManager._();

  final Map<String, CombatSession> _activeCombats = {};
  final StreamController<CombatEvent> _eventController = StreamController.broadcast();
  final StreamController<CombatAction> _actionController = StreamController.broadcast();

  Stream<CombatEvent> get onCombatEvent => _eventController.stream;
  Stream<CombatAction> get onAction => _actionController.stream;

  CombatSession? createCombat({
    required String combatId,
    required CombatType type,
    required List<CombatUnit> playerUnits,
    required List<CombatUnit> enemyUnits,
    Map<String, dynamic>? settings,
  }) {
    final combat = CombatSession(
      combatId: combatId,
      type: type,
      playerUnits: playerUnits,
      enemyUnits: enemyUnits,
      settings: settings,
    );

    _activeCombats[combatId] = combat;
    _eventController.add(CombatEvent(
      combatId: combatId,
      type: CombatEventType.started,
      timestamp: DateTime.now(),
    ));

    return combat;
  }

  CombatSession? getCombat(String combatId) {
    return _activeCombats[combatId];
  }

  Future<CombatResult?> executeAction({
    required String combatId,
    required CombatAction action,
  }) async {
    final combat = _activeCombats[combatId];
    if (combat == null || combat.status != CombatStatus.inProgress) {
      return null;
    }

    final result = await combat.executeAction(action);
    _actionController.add(action);

    if (result != null) {
      _eventController.add(CombatEvent(
        combatId: combatId,
        type: result.isVictory ? CombatEventType.victory : CombatEventType.defeat,
        timestamp: DateTime.now(),
      ));
    }

    return result;
  }

  void pauseCombat(String combatId) {
    final combat = _activeCombats[combatId];
    if (combat != null) {
      combat.pause();
    }
  }

  void resumeCombat(String combatId) {
    final combat = _activeCombats[combatId];
    if (combat != null) {
      combat.resume();
    }
  }

  void endCombat(String combatId) {
    _activeCombats.remove(combatId);
    _eventController.add(CombatEvent(
      combatId: combatId,
      type: CombatEventType.ended,
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _eventController.close();
    _actionController.close();
  }
}

class CombatSession {
  final String combatId;
  final CombatType type;
  final List<CombatUnit> playerUnits;
  final List<CombatUnit> enemyUnits;
  final Map<String, dynamic>? settings;
  CombatStatus status;
  final List<CombatLog> logs;
  final List<CombatAction> actions;
  int currentTurn;
  String? currentUnitId;
  final DateTime startTime;

  CombatSession({
    required this.combatId,
    required this.type,
    required this.playerUnits,
    required this.enemyUnits,
    this.settings,
    this.status = CombatStatus.notStarted,
    this.logs = const [],
    this.actions = const [],
    this.currentTurn = 1,
    this.currentUnitId,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  List<CombatUnit> get allUnits => [...playerUnits, ...enemyUnits];
  List<CombatUnit> get aliveUnits => allUnits.where((u) => u.isAlive).toList();
  List<CombatUnit> get alivePlayerUnits => playerUnits.where((u) => u.isAlive).toList();
  List<CombatUnit> get aliveEnemyUnits => enemyUnits.where((u) => u.isAlive).toList();

  Duration get duration => DateTime.now().difference(startTime);

  void start() {
    status = CombatStatus.inProgress;
  }

  void pause() {
    status = CombatStatus.paused;
  }

  void resume() {
    if (status == CombatStatus.paused) {
      status = CombatStatus.inProgress;
    }
  }

  Future<CombatResult?> executeAction(CombatAction action) async {
    actions.add(action);

    final sourceUnit = allUnits.firstWhere(
      (u) => u.unitId == action.sourceUnitId,
      orElse: () => playerUnits.first,
    );

    if (!sourceUnit.isAlive) {
      return null;
    }

    CombatUnit? targetUnit;
    if (action.targetUnitId != null) {
      targetUnit = allUnits.firstWhere(
        (u) => u.unitId == action.targetUnitId,
      );
    }

    switch (action.type) {
      case ActionType.attack:
        if (targetUnit != null) {
          _processAttack(sourceUnit, targetUnit);
        }
        break;
      case ActionType.skill:
        if (targetUnit != null && action.skillId != null) {
          await _processSkill(sourceUnit, targetUnit, action.skillId);
        }
        break;
      case ActionType.defend:
        _processDefend(sourceUnit);
        break;
      case ActionType.item:
        _processItem(sourceUnit);
        break;
      case ActionType.escape:
        return _processEscape();
    }

    return _checkCombatEnd();
  }

  void _processAttack(CombatUnit attacker, CombatUnit defender) {
    attacker.state = UnitState.attacking;
    defender.state = UnitState.damaged;

    final damage = _calculateDamage(attacker, defender, 1.0);
    defender.currentHp = (defender.currentHp - damage).clamp(0, defender.maxHp);

    logs.add(CombatLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      message: '${attacker.name} attacks ${defender.name} for $damage damage!',
      timestamp: DateTime.now(),
      type: CombatLogType.damage,
    ));
  }

  Future<void> _processSkill(CombatUnit caster, CombatUnit target, String skillId) async {
    caster.state = UnitState.casting;
    caster.currentMp = (caster.currentMp - 10).clamp(0, caster.maxMp);

    final damage = _calculateDamage(caster, target, 1.5);
    target.currentHp = (target.currentHp - damage).clamp(0, target.maxHp);

    logs.add(CombatLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      message: '${caster.name} uses $skillId on ${target.name} for $damage damage!',
      timestamp: DateTime.now(),
      type: CombatLogType.damage,
    ));
  }

  void _processDefend(CombatUnit unit) {
    unit.state = UnitState.idle;
    logs.add(CombatLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      message: '${unit.name} is defending!',
      timestamp: DateTime.now(),
      type: CombatLogType.system,
    ));
  }

  void _processItem(CombatUnit unit) {
    unit.currentHp = (unit.currentHp + 50).clamp(0, unit.maxHp);
    logs.add(CombatLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      message: '${unit.name} uses an item and recovers 50 HP!',
      timestamp: DateTime.now(),
      type: CombatLogType.heal,
    ));
  }

  CombatResult _processEscape() {
    final success = DateTime.now().millisecondsSinceEpoch % 100 < 50;
    if (success) {
      status = CombatStatus.draw;
      return CombatResult(
        combatId: combatId,
        isVictory: false,
        isDefeat: false,
        isEscape: true,
        rewards: const {},
        duration: duration,
      );
    }
    logs.add(CombatLog(
      logId: 'log_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Escape failed!',
      timestamp: DateTime.now(),
      type: CombatLogType.system,
    ));
    return CombatResult(
      combatId: combatId,
      isVictory: false,
      isDefeat: false,
      isEscape: false,
      rewards: const {},
      duration: duration,
    );
  }

  int _calculateDamage(CombatUnit attacker, CombatUnit defender, double multiplier) {
    final baseDamage = (attacker.attack - defender.defense * 0.5).clamp(1, double.infinity).toInt();
    return (baseDamage * multiplier).toInt();
  }

  CombatResult? _checkCombatEnd() {
    if (aliveEnemyUnits.isEmpty) {
      status = CombatStatus.victory;
      return CombatResult(
        combatId: combatId,
        isVictory: true,
        isDefeat: false,
        rewards: _generateRewards(true),
        duration: duration,
      );
    }

    if (alivePlayerUnits.isEmpty) {
      status = CombatStatus.defeat;
      return CombatResult(
        combatId: combatId,
        isVictory: false,
        isDefeat: true,
        rewards: _generateRewards(false),
        duration: duration,
      );
    }

    return null;
  }

  Map<String, int> _generateRewards(bool isVictory) {
    if (isVictory) {
      return {
        'gold': 1000,
        'exp': 500,
      };
    }
    return {
      'gold': 100,
      'exp': 50,
    };
  }
}

class CombatResult {
  final String combatId;
  final bool isVictory;
  final bool isDefeat;
  final bool isEscape;
  final Map<String, int> rewards;
  final Duration duration;

  const CombatResult({
    required this.combatId,
    required this.isVictory,
    required this.isDefeat,
    required this.isEscape,
    required this.rewards,
    required this.duration,
  });
}

class CombatEvent {
  final String combatId;
  final CombatEventType type;
  final DateTime timestamp;

  const CombatEvent({
    required this.combatId,
    required this.type,
    required this.timestamp,
  });
}

enum CombatEventType {
  started,
  ended,
  victory,
  defeat,
  turnChanged,
}

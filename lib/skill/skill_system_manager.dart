import 'dart:async';
import 'package:flutter/material.dart';

enum SkillType {
  active,
  passive,
  ultimate,
  toggle,
}

enum SkillElement {
  none,
  fire,
  water,
  earth,
  wind,
  light,
  dark,
}

enum SkillTargetType {
  single,
  multiple,
  self,
  allAllies,
  allEnemies,
  area,
}

class Skill {
  final String skillId;
  final String name;
  final String description;
  final SkillType type;
  final SkillElement element;
  final SkillTargetType targetType;
  final int maxLevel;
  final int cooldown;
  final int manaCost;
  final int power;
  final List<SkillEffect> effects;
  final List<String> prerequisites;
  final String icon;
  final Map<int, SkillLevelData> levelData;

  const Skill({
    required this.skillId,
    required this.name,
    required this.description,
    required this.type,
    required this.element,
    required this.targetType,
    required this.maxLevel,
    required this.cooldown,
    required this.manaCost,
    required this.power,
    required this.effects,
    required this.prerequisites,
    required this.icon,
    required this.levelData,
  });
}

class SkillLevelData {
  final int level;
  final int power;
  final int manaCost;
  final int cooldown;
  final double effectMultiplier;

  const SkillLevelData({
    required this.level,
    required this.power,
    required this.manaCost,
    required this.cooldown,
    required this.effectMultiplier,
  });
}

class SkillEffect {
  final String effectId;
  final EffectType type;
  final double value;
  final int duration;
  final double chance;

  const SkillEffect({
    required this.effectId,
    required this.type,
    required this.value,
    required this.duration,
    required this.chance,
  });
}

enum EffectType {
  damage,
  heal,
  buffAttack,
  buffDefense,
  buffSpeed,
  debuffAttack,
  debuffDefense,
  stun,
  silence,
  poison,
  regenerate,
  shield,
  lifesteal,
  manaDrain,
  manaRestore,
}

class SkillTreeNode {
  final String nodeId;
  final String skillId;
  final List<String> parentIds;
  final int requiredLevel;
  final int cost;
  final int row;
  final int column;
  final bool isUnlocked;

  const SkillTreeNode({
    required this.nodeId,
    required this.skillId,
    required this.parentIds,
    required this.requiredLevel,
    required this.cost,
    required this.row,
    required this.column,
    required this.isUnlocked,
  });
}

class SkillPreset {
  final String presetId;
  final String name;
  final List<String> activeSkillIds;
  final List<String> passiveSkillIds;
  final DateTime createdAt;
  final DateTime? lastModified;

  const SkillPreset({
    required this.presetId,
    required this.name,
    required this.activeSkillIds,
    required this.passiveSkillIds,
    required this.createdAt,
    this.lastModified,
  });
}

class SkillCooldown {
  final String skillId;
  final int remainingTurns;
  final DateTime lastUsed;

  const SkillCooldown({
    required this.skillId,
    required this.remainingTurns,
    required this.lastUsed,
  });

  bool get isReady => remainingTurns <= 0;
}

class SkillSystemManager {
  static final SkillSystemManager _instance = SkillSystemManager._();
  static SkillSystemManager get instance => _instance;

  SkillSystemManager._();

  final Map<String, Skill> _skills = {};
  final Map<String, SkillTreeNode> _skillTree = {};
  final Map<String, List<SkillCooldown>> _unitCooldowns = {};
  final Map<String, List<String>> _unitSkills = {};
  final Map<String, SkillPreset> _presets = {};
  final StreamController<SkillEvent> _eventController = StreamController.broadcast();

  Stream<SkillEvent> get onSkillEvent => _eventController.stream;

  void registerSkill(Skill skill) {
    _skills[skill.skillId] = skill;
  }

  Skill? getSkill(String skillId) {
    return _skills[skillId];
  }

  List<Skill> getAllSkills() {
    return _skills.values.toList();
  }

  List<Skill> getSkillsByType(SkillType type) {
    return _skills.values.where((skill) => skill.type == type).toList();
  }

  List<Skill> getSkillsByElement(SkillElement element) {
    return _skills.values.where((skill) => skill.element == element).toList();
  }

  void buildSkillTree(List<SkillTreeNode> nodes) {
    for (final node in nodes) {
      _skillTree[node.nodeId] = node;
    }
  }

  List<SkillTreeNode> getSkillTree() {
    return _skillTree.values.toList()
      ..sort((a, b) {
        if (a.row != b.row) return a.row.compareTo(b.row);
        return a.column.compareTo(b.column);
      });
  }

  SkillTreeNode? getSkillNode(String nodeId) {
    return _skillTree[nodeId];
  }

  Future<bool> unlockSkillNode({
    required String nodeId,
    required String unitId,
  }) async {
    final node = _skillTree[nodeId];
    if (node == null) return false;

    if (!_canUnlockNode(node)) {
      return false;
    }

    final updatedNode = SkillTreeNode(
      nodeId: node.nodeId,
      skillId: node.skillId,
      parentIds: node.parentIds,
      requiredLevel: node.requiredLevel,
      cost: node.cost,
      row: node.row,
      column: node.column,
      isUnlocked: true,
    );

    _skillTree[nodeId] = updatedNode;
    _addSkillToUnit(unitId, node.skillId);

    _eventController.add(SkillEvent(
      skillId: node.skillId,
      type: SkillEventType.unlocked,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  bool _canUnlockNode(SkillTreeNode node) {
    if (node.isUnlocked) return false;

    for (final parentId in node.parentIds) {
      final parentNode = _skillTree[parentId];
      if (parentNode == null || !parentNode.isUnlocked) {
        return false;
      }
    }

    return true;
  }

  void _addSkillToUnit(String unitId, String skillId) {
    if (!_unitSkills.containsKey(unitId)) {
      _unitSkills[unitId] = [];
    }
    if (!_unitSkills[unitId]!.contains(skillId)) {
      _unitSkills[unitId]!.add(skillId);
    }
  }

  List<String> getUnitSkills(String unitId) {
    return _unitSkills[unitId] ?? [];
  }

  Future<SkillResult?> useSkill({
    required String unitId,
    required String skillId,
    required int level,
    List<String>? targetIds,
  }) async {
    final skill = _skills[skillId];
    if (skill == null) return null;

    if (!_isSkillReady(unitId, skillId)) {
      return SkillResult(
        skillId: skillId,
        success: false,
        reason: 'Skill is on cooldown',
        timestamp: DateTime.now(),
      );
    }

    final levelData = skill.levelData[level];
    if (levelData == null) {
      return SkillResult(
        skillId: skillId,
        success: false,
        reason: 'Invalid skill level',
        timestamp: DateTime.now(),
      );
    }

    final result = await _executeSkill(
      skill: skill,
      level: level,
      levelData: levelData,
      targetIds: targetIds,
    );

    if (result.success) {
      _setCooldown(unitId, skillId, levelData.cooldown);

      _eventController.add(SkillEvent(
        skillId: skillId,
        type: SkillEventType.used,
        timestamp: DateTime.now(),
      ));
    }

    return result;
  }

  bool _isSkillReady(String unitId, String skillId) {
    final cooldowns = _unitCooldowns[unitId];
    if (cooldowns == null) return true;

    final cooldown = cooldowns.firstWhere(
      (c) => c.skillId == skillId,
      orElse: () => const SkillCooldown(
        skillId: '',
        remainingTurns: 0,
        lastUsed: DateTime.now(),
      ),
    );

    return cooldown.isReady;
  }

  void _setCooldown(String unitId, String skillId, int cooldown) {
    if (!_unitCooldowns.containsKey(unitId)) {
      _unitCooldowns[unitId] = [];
    }

    _unitCooldowns[unitId]!.removeWhere((c) => c.skillId == skillId);
    _unitCooldowns[unitId]!.add(SkillCooldown(
      skillId: skillId,
      remainingTurns: cooldown,
      lastUsed: DateTime.now(),
    ));
  }

  Future<SkillResult> _executeSkill({
    required Skill skill,
    required int level,
    required SkillLevelData levelData,
    List<String>? targetIds,
  }) async {
    final effects = <SkillEffectResult>[];

    for (final effect in skill.effects) {
      final effectResult = SkillEffectResult(
        effectId: effect.effectId,
        type: effect.type,
        value: (effect.value * levelData.effectMultiplier).toInt(),
        targets: targetIds ?? [],
        duration: effect.duration,
      );
      effects.add(effectResult);
    }

    return SkillResult(
      skillId: skill.skillId,
      success: true,
      effects: effects,
      timestamp: DateTime.now(),
    );
  }

  void tickCooldowns(String unitId) {
    final cooldowns = _unitCooldowns[unitId];
    if (cooldowns == null) return;

    for (int i = 0; i < cooldowns.length; i++) {
      final current = cooldowns[i];
      if (current.remainingTurns > 0) {
        _unitCooldowns[unitId]![i] = SkillCooldown(
          skillId: current.skillId,
          remainingTurns: current.remainingTurns - 1,
          lastUsed: current.lastUsed,
        );
      }
    }
  }

  List<SkillCooldown> getCooldowns(String unitId) {
    return _unitCooldowns[unitId] ?? [];
  }

  Future<bool> upgradeSkill({
    required String skillId,
    required int currentLevel,
  }) async {
    final skill = _skills[skillId];
    if (skill == null) return false;

    if (currentLevel >= skill.maxLevel) return false;

    _eventController.add(SkillEvent(
      skillId: skillId,
      type: SkillEventType.upgraded,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  SkillPreset createPreset({
    required String presetId,
    required String name,
    required List<String> activeSkillIds,
    required List<String> passiveSkillIds,
  }) {
    final preset = SkillPreset(
      presetId: presetId,
      name: name,
      activeSkillIds: activeSkillIds,
      passiveSkillIds: passiveSkillIds,
      createdAt: DateTime.now(),
    );

    _presets[presetId] = preset;
    return preset;
  }

  SkillPreset? getPreset(String presetId) {
    return _presets[presetId];
  }

  List<SkillPreset> getAllPresets() {
    return _presets.values.toList();
  }

  void updatePreset({
    required String presetId,
    String? name,
    List<String>? activeSkillIds,
    List<String>? passiveSkillIds,
  }) {
    final preset = _presets[presetId];
    if (preset == null) return;

    _presets[presetId] = SkillPreset(
      presetId: presetId,
      name: name ?? preset.name,
      activeSkillIds: activeSkillIds ?? preset.activeSkillIds,
      passiveSkillIds: passiveSkillIds ?? preset.passiveSkillIds,
      createdAt: preset.createdAt,
      lastModified: DateTime.now(),
    );
  }

  void deletePreset(String presetId) {
    _presets.remove(presetId);
  }

  void dispose() {
    _eventController.close();
  }
}

class SkillResult {
  final String skillId;
  final bool success;
  final String? reason;
  final List<SkillEffectResult>? effects;
  final DateTime timestamp;

  const SkillResult({
    required this.skillId,
    required this.success,
    this.reason,
    this.effects,
    required this.timestamp,
  });
}

class SkillEffectResult {
  final String effectId;
  final EffectType type;
  final int value;
  final List<String> targets;
  final int duration;

  const SkillEffectResult({
    required this.effectId,
    required this.type,
    required this.value,
    required this.targets,
    required this.duration,
  });
}

class SkillEvent {
  final String skillId;
  final SkillEventType type;
  final DateTime timestamp;

  const SkillEvent({
    required this.skillId,
    required this.type,
    required this.timestamp,
  });
}

enum SkillEventType {
  unlocked,
  used,
  upgraded,
  cooldownReady,
}

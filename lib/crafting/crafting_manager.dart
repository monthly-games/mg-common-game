import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 재료
class Material {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int rarity; // 1-5
  final bool isStackable;
  final int maxStackSize;

  const Material({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.rarity,
    required this.isStackable,
    required this.maxStackSize,
  });
}

/// 조합법
class Recipe {
  final String id;
  final String name;
  final String description;
  final String resultItemId;
  final int resultQuantity;
  final Map<String, int> materials; // materialId -> quantity
  final int craftingTime; // seconds
  final int requiredLevel;
  final String category;
  final double successRate; // 0.0 - 1.0
  final int expReward;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.resultItemId,
    required this.resultQuantity,
    required this.materials,
    required this.craftingTime,
    required this.requiredLevel,
    required this.category,
    required this.successRate,
    required this.expReward,
  });
}

/// 제작 중인 아이템
class CraftingJob {
  final String id;
  final String recipeId;
  final String userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final CraftingStatus status;

  const CraftingJob({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    required this.status,
  });

  /// 진행률
  double get progress {
    if (completedAt != null) return 1.0;
    return 0.5; // 시뮬레이션
  }

  /// 남은 시간
  Duration? get remainingTime {
    if (completedAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(completedAt!)) return Duration.zero;
    return completedAt!.difference(now);
  }
}

/// 제작 상태
enum CraftingStatus {
  queue,         // 대기 중
  crafting,      // 제작 중
  completed,     // 완료
  failed,        // 실패
  cancelled,     // 취소됨
}

/// 제작 레벨 정보
class CraftingLevel {
  final int level;
  final int currentExp;
  final int requiredExp;
  final int totalCrafts;
  final int successCount;
  final int failCount;

  const CraftingLevel({
    required this.level,
    required this.currentExp,
    required this.requiredExp,
    required this.totalCrafts,
    required this.successCount,
    required this.failCount,
  });

  /// 경험률
  double get expRate => requiredExp > 0 ? currentExp / requiredExp : 0.0;

  /// 성공률
  double get successRate => totalCrafts > 0 ? successCount / totalCrafts : 0.0;
}

/// 제작 관리자
class CraftingManager {
  static final CraftingManager _instance = CraftingManager._();
  static CraftingManager get instance => _instance;

  CraftingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, Recipe> _recipes = {};
  final Map<String, Material> _materials = {};
  final Map<String, CraftingJob> _jobs = {};
  final Map<String, Map<String, int>> _inventories = {}; // userId -> (materialId -> quantity)
  final Map<String, CraftingLevel> _levels = {};

  final StreamController<CraftingJob> _jobController =
      StreamController<CraftingJob>.broadcast();
  final StreamController<CraftingLevel> _levelController =
      StreamController<CraftingLevel>.broadcast();

  Stream<CraftingJob> get onJobUpdate => _jobController.stream;
  Stream<CraftingLevel> get onLevelUpdate => _levelController.stream;

  Timer? _craftingTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 재료 로드
    _loadMaterials();

    // 조합법 로드
    _loadRecipes();

    // 인벤토리 로드
    await _loadInventories();

    // 제작 타이머 시작
    _startCraftingTimer();

    debugPrint('[Crafting] Initialized');
  }

  void _loadMaterials() {
    _materials['iron_ore'] = const Material(
      id: 'iron_ore',
      name: '철광석',
      description: '무기와 방어구를 만드는 기본 재료',
      iconUrl: 'assets/materials/iron_ore.png',
      rarity: 1,
      isStackable: true,
      maxStackSize: 999,
    );

    _materials['leather'] = const Material(
      id: 'leather',
      name: '가죽',
      description: '방어구 제작에 사용되는 재료',
      iconUrl: 'assets/materials/leather.png',
      rarity: 1,
      isStackable: true,
      maxStackSize: 999,
    );

    _materials['rare_crystal'] = const Material(
      id: 'rare_crystal',
      name: '희귀 수정',
      description: '마법적인 힘이 담긴 수정',
      iconUrl: 'assets/materials/rare_crystal.png',
      rarity: 4,
      isStackable: true,
      maxStackSize: 99,
    );

    _materials['dragon_scale'] = const Material(
      id: 'dragon_scale',
      name: '용의 비늘',
      description: '용에서 얻은 희귀한 재료',
      iconUrl: 'assets/materials/dragon_scale.png',
      rarity: 5,
      isStackable: true,
      maxStackSize: 99,
    );
  }

  void _loadRecipes() {
    _recipes['iron_sword'] = const Recipe(
      id: 'iron_sword',
      name: '철검',
      description: '기본적인 철검',
      resultItemId: 'weapon_iron_sword',
      resultQuantity: 1,
      materials: {
        'iron_ore': 10,
        'leather': 2,
      },
      craftingTime: 60,
      requiredLevel: 1,
      category: 'weapon',
      successRate: 0.9,
      expReward: 10,
    );

    _recipes['steel_armor'] = const Recipe(
      id: 'steel_armor',
      name: '강철 갑옷',
      description: '튼튼한 강철 갑옷',
      resultItemId: 'armor_steel',
      resultQuantity: 1,
      materials: {
        'iron_ore': 20,
        'leather': 5,
      },
      craftingTime: 120,
      requiredLevel: 5,
      category: 'armor',
      successRate: 0.8,
      expReward: 25,
    );

    _recipes['magic_staff'] = const Recipe(
      id: 'magic_staff',
      name: '마법 지팡이',
      description: '마법의 힘이 담긴 지팡이',
      resultItemId: 'weapon_magic_staff',
      resultQuantity: 1,
      materials: {
        'rare_crystal': 3,
        'iron_ore': 5,
      },
      craftingTime: 300,
      requiredLevel: 10,
      category: 'weapon',
      successRate: 0.6,
      expReward: 100,
    );

    _recipes['dragon_armor'] = const Recipe(
      id: 'dragon_armor',
      name: '용의 갑옷',
      description: '용의 비늘로 만든 전설의 갑옷',
      resultItemId: 'armor_dragon',
      resultQuantity: 1,
      materials: {
        'dragon_scale': 10,
        'rare_crystal': 5,
        'iron_ore': 50,
      },
      craftingTime: 3600,
      requiredLevel: 20,
      category: 'armor',
      successRate: 0.3,
      expReward: 500,
    );
  }

  Future<void> _loadInventories() async {
    if (_currentUserId != null) {
      _inventories[_currentUserId!] = {
        'iron_ore': 100,
        'leather': 50,
        'rare_crystal': 5,
      };

      // 기본 제작 레벨
      _levels[_currentUserId!] = const CraftingLevel(
        level: 1,
        currentExp: 0,
        requiredExp: 100,
        totalCrafts: 0,
        successCount: 0,
        failCount: 0,
      );
    }
  }

  void _startCraftingTimer() {
    _craftingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCraftingJobs();
    });
  }

  /// 제작 시작
  Future<CraftingJob> startCrafting({
    required String recipeId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }

    final recipe = _recipes[recipeId];
    if (recipe == null) {
      throw Exception('Recipe not found');
    }

    // 레벨 체크
    final level = _levels[_currentUserId];
    if (level == null || level.level < recipe.requiredLevel) {
      throw Exception('Crafting level too low');
    }

    // 재료 확인
    final inventory = _inventories[_currentUserId] ?? {};
    for (final entry in recipe.materials.entries) {
      final available = inventory[entry.key] ?? 0;
      if (available < entry.value) {
        throw Exception('Not enough materials');
      }
    }

    // 재료 소비
    for (final entry in recipe.materials.entries) {
      inventory[entry.key] = (inventory[entry.key] ?? 0) - entry.value;
    }
    _inventories[_currentUserId!] = inventory;

    // 제작 작업 생성
    final jobId = 'job_${DateTime.now().millisecondsSinceEpoch}';
    final job = CraftingJob(
      id: jobId,
      recipeId: recipeId,
      userId: _currentUserId!,
      startedAt: DateTime.now(),
      completedAt: DateTime.now().add(Duration(seconds: recipe.craftingTime)),
      status: CraftingStatus.crafting,
    );

    _jobs[jobId] = job;
    _jobController.add(job);

    debugPrint('[Crafting] Started: $recipeId');

    return job;
  }

  /// 제작 작업 업데이트
  void _updateCraftingJobs() {
    final now = DateTime.now();
    final completed = <CraftingJob>[];

    for (final job in _jobs.values) {
      if (job.status == CraftingStatus.crafting &&
          job.completedAt != null &&
          now.isAfter(job.completedAt!)) {
        completed.add(job);
      }
    }

    for (final job in completed) {
      _completeCraftingJob(job.id);
    }
  }

  /// 제작 완료
  void _completeCraftingJob(String jobId) {
    final job = _jobs[jobId];
    if (job == null) return;

    final recipe = _recipes[job.recipeId];
    if (recipe == null) return;

    // 성공률 체크
    final random = Random().nextDouble();
    final isSuccess = random < recipe.successRate;

    final completedJob = CraftingJob(
      id: job.id,
      recipeId: job.recipeId,
      userId: job.userId,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      status: isSuccess ? CraftingStatus.completed : CraftingStatus.failed,
    );

    _jobs[jobId] = completedJob;
    _jobController.add(completedJob);

    if (isSuccess) {
      // 결과 아이템 지급
      debugPrint('[Crafting] Success: ${recipe.name}');
    } else {
      // 실패 처리
      debugPrint('[Crafting] Failed: ${recipe.name}');
    }

    // 경험치 지급
    _addExp(job.userId, recipe.expReward, isSuccess);
  }

  /// 경험치 추가
  void _addExp(String userId, int exp, bool isSuccess) {
    final level = _levels[userId];
    if (level == null) return;

    var newExp = level.currentExp + exp;
    var newLevel = level.level;
    var newRequiredExp = level.requiredExp;

    // 레벨업 체크
    if (newExp >= newRequiredExp) {
      newLevel += 1;
      newExp -= newRequiredExp;
      newRequiredExp = newLevel * 100;
    }

    final updated = CraftingLevel(
      level: newLevel,
      currentExp: newExp,
      requiredExp: newRequiredExp,
      totalCrafts: level.totalCrafts + 1,
      successCount: isSuccess ? level.successCount + 1 : level.successCount,
      failCount: isSuccess ? level.failCount : level.failCount + 1,
    );

    _levels[userId] = updated;
    _levelController.add(updated);
  }

  /// 제작 취소
  Future<void> cancelCrafting(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    if (job.status != CraftingStatus.crafting) {
      throw Exception('Cannot cancel completed job');
    }

    final cancelled = CraftingJob(
      id: job.id,
      recipeId: job.recipeId,
      userId: job.userId,
      startedAt: job.startedAt,
      completedAt: DateTime.now(),
      status: CraftingStatus.cancelled,
    );

    _jobs[jobId] = cancelled;
    _jobController.add(cancelled);

    debugPrint('[Crafting] Cancelled: $jobId');
  }

  /// 완료된 작업 수령
  Future<void> collectJob(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    if (job.status != CraftingStatus.completed) {
      throw Exception('Job not completed');
    }

    // 결과 아이템 지급
    final recipe = _recipes[job.recipeId];
    if (recipe != null) {
      // 실제로는 아이템 지급
      debugPrint('[Crafting] Collected: ${recipe.name} x${recipe.resultQuantity}');
    }

    _jobs.remove(jobId);

    debugPrint('[Crafting] Collected: $jobId');
  }

  /// 재료 추가
  Future<void> addMaterial({
    required String materialId,
    required int quantity,
  }) async {
    if (_currentUserId == null) return;

    final inventory = _inventories[_currentUserId] ?? {};
    inventory[materialId] = (inventory[materialId] ?? 0) + quantity;
    _inventories[_currentUserId!] = inventory;

    debugPrint('[Crafting] Material added: $materialId x$quantity');
  }

  /// 재료 제거
  bool removeMaterial({
    required String materialId,
    required int quantity,
  }) {
    if (_currentUserId == null) return false;

    final inventory = _inventories[_currentUserId];
    if (inventory == null) return false;

    final available = inventory[materialId] ?? 0;
    if (available < quantity) return false;

    inventory[materialId] = available - quantity;
    _inventories[_currentUserId!] = inventory;

    return true;
  }

  /// 조합법 조회
  Recipe? getRecipe(String recipeId) {
    return _recipes[recipeId];
  }

  /// 조합법 목록
  List<Recipe> getRecipes({String? category, int? maxLevel}) {
    var recipes = _recipes.values.toList();

    if (category != null) {
      recipes = recipes.where((r) => r.category == category).toList();
    }

    if (maxLevel != null) {
      recipes = recipes.where((r) => r.requiredLevel <= maxLevel).toList();
    }

    return recipes;
  }

  /// 제작 가능한 조합법
  List<Recipe> getCraftableRecipes(String userId) {
    final level = _levels[userId];
    if (level == null) return [];

    final inventory = _inventories[userId] ?? {};

    return _recipes.values.where((recipe) {
      // 레벨 체크
      if (level.level < recipe.requiredLevel) return false;

      // 재료 체크
      for (final entry in recipe.materials.entries) {
        final available = inventory[entry.key] ?? 0;
        if (available < entry.value) return false;
      }

      return true;
    }).toList();
  }

  /// 제작 작업 목록
  List<CraftingJob> getJobs(String userId) {
    return _jobs.values
        .where((j) => j.userId == userId)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// 제작 레벨
  CraftingLevel? getLevel(String userId) {
    return _levels[userId];
  }

  /// 인벤토리 조회
  Map<String, int> getInventory(String userId) {
    return _inventories[userId] ?? {};
  }

  /// 재료 정보
  Material? getMaterial(String materialId) {
    return _materials[materialId];
  }

  /// 재료 목록
  List<Material> getMaterials({int? minRarity}) {
    var materials = _materials.values.toList();

    if (minRarity != null) {
      materials = materials.where((m) => m.rarity >= minRarity).toList();
    }

    return materials;
  }

  /// 조합법 검색
  List<Recipe> searchRecipes(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _recipes.values
        .where((r) =>
            r.name.toLowerCase().contains(lowerKeyword) ||
            r.description.toLowerCase().contains(lowerKeyword))
        .toList();
  }

  /// 카테고리 목록
  List<String> getCategories() {
    return _recipes.values
        .map((r) => r.category)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _saveData() async {
    if (_currentUserId == null) return;

    // 인벤토리 저장
    await _prefs?.setString(
      'crafting_inventory_$_currentUserId',
      jsonEncode(_inventories[_currentUserId]),
    );

    // 레벨 저장
    final level = _levels[_currentUserId];
    if (level != null) {
      await _prefs?.setString(
        'crafting_level_$_currentUserId',
        jsonEncode({
          'level': level.level,
          'currentExp': level.currentExp,
          'totalCrafts': level.totalCrafts,
        }),
      );
    }
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final totalJobs = _jobs.length;
    final activeJobs = _jobs.values.where((j) => j.status == CraftingStatus.crafting).length;
    final completedJobs = _jobs.values.where((j) => j.status == CraftingStatus.completed).length;
    final failedJobs = _jobs.values.where((j) => j.status == CraftingStatus.failed).length;

    return {
      'totalJobs': totalJobs,
      'activeJobs': activeJobs,
      'completedJobs': completedJobs,
      'failedJobs': failedJobs,
      'successRate': totalJobs > 0 ? completedJobs / totalJobs : 0.0,
      'totalRecipes': _recipes.length,
      'totalMaterials': _materials.length,
    };
  }

  void dispose() {
    _jobController.close();
    _levelController.close();
    _craftingTimer?.cancel();
  }
}

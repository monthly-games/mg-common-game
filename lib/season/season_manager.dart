import 'dart:async';
import 'dart:convert';
import 'package:mg_common_game/storage/local_storage_service.dart';
import 'package:mg_common_game/competitive/leaderboard_manager.dart';

/// Season status
enum SeasonStatus {
  upcoming,
  active,
  ended,
  archived,
}

/// Season type
enum SeasonType {
  normal,
  special,
  ranked,
  event,
}

/// Season reward tier
enum SeasonRewardTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  champion,
}

/// Season reward
class SeasonReward {
  final String rewardId;
  final String name;
  final String description;
  final SeasonRewardTier tier;
  final int requiredRank;
  final Map<String, dynamic> rewardData;

  SeasonReward({
    required this.rewardId,
    required this.name,
    required this.description,
    required this.tier,
    required this.requiredRank,
    required this.rewardData,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
      'name': name,
      'description': description,
      'tier': tier.name,
      'requiredRank': requiredRank,
      'rewardData': rewardData,
    };
  }

  /// Create from JSON
  factory SeasonReward.fromJson(Map<String, dynamic> json) {
    return SeasonReward(
      rewardId: json['rewardId'],
      name: json['name'],
      description: json['description'],
      tier: SeasonRewardTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SeasonRewardTier.bronze,
      ),
      requiredRank: json['requiredRank'],
      rewardData: json['rewardData'] as Map<String, dynamic>,
    );
  }
}

/// Season pass level
class SeasonPassLevel {
  final int level;
  final int requiredXP;
  final List<SeasonReward> freeRewards;
  final List<SeasonReward> premiumRewards;

  SeasonPassLevel({
    required this.level,
    required this.requiredXP,
    required this.freeRewards,
    required this.premiumRewards,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'requiredXP': requiredXP,
      'freeRewards': freeRewards.map((r) => r.toJson()).toList(),
      'premiumRewards': premiumRewards.map((r) => r.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory SeasonPassLevel.fromJson(Map<String, dynamic> json) {
    return SeasonPassLevel(
      level: json['level'],
      requiredXP: json['requiredXP'],
      freeRewards: (json['freeRewards'] as List)
          .map((r) => SeasonReward.fromJson(r))
          .toList(),
      premiumRewards: (json['premiumRewards'] as List)
          .map((r) => SeasonReward.fromJson(r))
          .toList(),
    );
  }
}

/// Season
class Season {
  final String seasonId;
  final String name;
  final String description;
  final SeasonType type;
  final SeasonStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in days
  final List<SeasonPassLevel> passLevels;
  final String leaderboardId;
  final bool hasPremiumPass;
  final int maxLevel;
  final int xpPerLevel;

  Season({
    required this.seasonId,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.passLevels,
    required this.leaderboardId,
    this.hasPremiumPass = true,
    this.maxLevel = 100,
    this.xpPerLevel = 1000,
  });

  /// Get current season progress
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0.0;
    if (now.isAfter(endTime)) return 1.0;

    final total = endTime.difference(startTime).inMilliseconds;
    final elapsed = now.difference(startTime).inMilliseconds;
    return elapsed / total;
  }

  /// Get remaining days
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return 0;
    return endTime.difference(now).inDays;
  }

  /// Check if season is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'seasonId': seasonId,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'duration': duration,
      'passLevels': passLevels.map((l) => l.toJson()).toList(),
      'leaderboardId': leaderboardId,
      'hasPremiumPass': hasPremiumPass,
      'maxLevel': maxLevel,
      'xpPerLevel': xpPerLevel,
    };
  }

  /// Create from JSON
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonId: json['seasonId'],
      name: json['name'],
      description: json['description'],
      type: SeasonType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SeasonType.normal,
      ),
      status: SeasonStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SeasonStatus.upcoming,
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime']),
      duration: json['duration'],
      passLevels: (json['passLevels'] as List)
          .map((l) => SeasonPassLevel.fromJson(l))
          .toList(),
      leaderboardId: json['leaderboardId'],
      hasPremiumPass: json['hasPremiumPass'] ?? true,
      maxLevel: json['maxLevel'] ?? 100,
      xpPerLevel: json['xpPerLevel'] ?? 1000,
    );
  }
}

/// User season progress
class UserSeasonProgress {
  final String userId;
  final String seasonId;
  final int currentLevel;
  final int currentXP;
  final bool hasPremiumPass;
  final Set<int> claimedFreeLevels;
  final Set<int> claimedPremiumLevels;

  UserSeasonProgress({
    required this.userId,
    required this.seasonId,
    required this.currentLevel,
    required this.currentXP,
    required this.hasPremiumPass,
    required this.claimedFreeLevels,
    required this.claimedPremiumLevels,
  });

  /// Get XP progress to next level
  double get xpProgress {
    return (currentXP % 1000) / 1000.0;
  }

  /// Check if reward is claimable
  bool canClaimReward(int level, {bool isPremium = false}) {
    if (level > currentLevel) return false;
    return isPremium
        ? hasPremiumPass && !claimedPremiumLevels.contains(level)
        : !claimedFreeLevels.contains(level);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'seasonId': seasonId,
      'currentLevel': currentLevel,
      'currentXP': currentXP,
      'hasPremiumPass': hasPremiumPass,
      'claimedFreeLevels': claimedFreeLevels.toList(),
      'claimedPremiumLevels': claimedPremiumLevels.toList(),
    };
  }

  /// Create from JSON
  factory UserSeasonProgress.fromJson(Map<String, dynamic> json) {
    return UserSeasonProgress(
      userId: json['userId'],
      seasonId: json['seasonId'],
      currentLevel: json['currentLevel'],
      currentXP: json['currentXP'],
      hasPremiumPass: json['hasPremiumPass'],
      claimedFreeLevels: (json['claimedFreeLevels'] as List).cast<int>(),
      claimedPremiumLevels: (json['claimedPremiumLevels'] as List).cast<int>(),
    );
  }

  /// Create copy with updated values
  UserSeasonProgress copyWith({
    int? currentLevel,
    int? currentXP,
    bool? hasPremiumPass,
    Set<int>? claimedFreeLevels,
    Set<int>? claimedPremiumLevels,
  }) {
    return UserSeasonProgress(
      userId: userId,
      seasonId: seasonId,
      currentLevel: currentLevel ?? this.currentLevel,
      currentXP: currentXP ?? this.currentXP,
      hasPremiumPass: hasPremiumPass ?? this.hasPremiumPass,
      claimedFreeLevels: claimedFreeLevels ?? this.claimedFreeLevels,
      claimedPremiumLevels: claimedPremiumLevels ?? this.claimedPremiumLevels,
    );
  }
}

/// Season manager
class SeasonManager {
  static final SeasonManager _instance = SeasonManager._internal();
  static SeasonManager get instance => _instance;

  SeasonManager._internal();

  final LocalStorageService _storage = LocalStorageService.instance;
  final LeaderboardManager _leaderboardManager = LeaderboardManager.instance;

  final Map<String, Season> _seasons = {};
  final Map<String, UserSeasonProgress> _userProgress = {};

  final StreamController<Season> _seasonController = StreamController.broadcast();
  final StreamController<UserSeasonProgress> _progressController = StreamController.broadcast();

  /// Stream of season updates
  Stream<Season> get seasonStream => _seasonController.stream;

  /// Stream of progress updates
  Stream<UserSeasonProgress> get progressStream => _progressController.stream;

  bool _isInitialized = false;

  /// Initialize season manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _storage.initialize();
    await _leaderboardManager.initialize();
    await _loadSeasons();
    await _loadUserProgress();

    // Start season status checker
    _startSeasonChecker();

    _isInitialized = true;
  }

  /// Load seasons from storage
  Future<void> _loadSeasons() async {
    final seasonsJson = _storage.getJsonList('seasons');
    if (seasonsJson != null) {
      for (final json in seasonsJson) {
        if (json is Map<String, dynamic>) {
          final season = Season.fromJson(json);
          _seasons[season.seasonId] = season;
        }
      }
    }

    // Create default season if none exist
    if (_seasons.isEmpty) {
      await _createDefaultSeason();
    }
  }

  /// Save seasons to storage
  Future<void> _saveSeasons() async {
    final jsonList = _seasons.values.map((s) => s.toJson()).toList();
    await _storage.setJsonList('seasons', jsonList);
  }

  /// Load user progress from storage
  Future<void> _loadUserProgress() async {
    final progressJson = _storage.getJsonList('user_season_progress');
    if (progressJson != null) {
      for (final json in progressJson) {
        if (json is Map<String, dynamic>) {
          final progress = UserSeasonProgress.fromJson(json);
          _userProgress['${progress.userId}_${progress.seasonId}'] = progress;
        }
      }
    }
  }

  /// Save user progress to storage
  Future<void> _saveUserProgress() async {
    final jsonList = _userProgress.values.map((p) => p.toJson()).toList();
    await _storage.setJsonList('user_season_progress', jsonList);
  }

  /// Create default season
  Future<void> _createDefaultSeason() async {
    final now = DateTime.now();
    final season = Season(
      seasonId: 'season_1',
      name: 'Season 1: New Beginnings',
      description: 'The first competitive season',
      type: SeasonType.normal,
      status: SeasonStatus.active,
      startTime: now,
      endTime: now.add(const Duration(days: 90)),
      duration: 90,
      passLevels: _generateDefaultPassLevels(),
      leaderboardId: 'season_1_leaderboard',
      hasPremiumPass: true,
    );

    _seasons[season.seasonId] = season;
    await _saveSeasons();

    // Create season leaderboard
    await _leaderboardManager.createLeaderboard(
      leaderboardId: season.leaderboardId,
      name: '${season.name} Leaderboard',
      leaderboardType: LeaderboardType.seasonal,
      scoringType: ScoringType.points,
      seasonId: season.seasonId,
    );
  }

  /// Generate default season pass levels
  List<SeasonPassLevel> _generateDefaultPassLevels() {
    final levels = <SeasonPassLevel>[];

    for (int i = 1; i <= 100; i++) {
      final xp = i * 1000;
      final freeRewards = <SeasonReward>[];
      final premiumRewards = <SeasonReward>[];

      // Add rewards every 5 levels
      if (i % 5 == 0) {
        freeRewards.add(SeasonReward(
          rewardId: 'free_${i}_gold',
          name: '$i Gold',
          description: 'Free reward',
          tier: SeasonRewardTier.bronze,
          requiredRank: 0,
          rewardData: {'currencyId': 'gold', 'amount': i * 100},
        ));
      }

      // Add premium rewards every 5 levels
      if (i % 5 == 0) {
        premiumRewards.add(SeasonReward(
          rewardId: 'premium_${i}_gems',
          name: '$i Gems',
          description: 'Premium reward',
          tier: SeasonRewardTier.gold,
          requiredRank: 0,
          rewardData: {'currencyId': 'gems', 'amount': i * 10},
        ));
      }

      // Add special rewards at milestone levels
      if (i == 100) {
        premiumRewards.add(SeasonReward(
          rewardId: 'premium_100_skin',
          name: 'Legendary Skin',
          description: 'Exclusive season 100 reward',
          tier: SeasonRewardTier.champion,
          requiredRank: 0,
          rewardData: {'itemType': 'skin', 'skinId': 'legendary_season_1'},
        ));
      }

      levels.add(SeasonPassLevel(
        level: i,
        requiredXP: xp,
        freeRewards: freeRewards,
        premiumRewards: premiumRewards,
      ));
    }

    return levels;
  }

  /// Get active season
  Season? getActiveSeason() {
    try {
      return _seasons.values.firstWhere((s) => s.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Get season by ID
  Season? getSeason(String seasonId) {
    return _seasons[seasonId];
  }

  /// Get all seasons
  List<Season> getAllSeasons() {
    return _seasons.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Create new season
  Future<bool> createSeason({
    required String seasonId,
    required String name,
    required String description,
    required SeasonType type,
    required DateTime startTime,
    required int durationDays,
    bool hasPremiumPass = true,
  }) async {
    if (_seasons.containsKey(seasonId)) {
      return false;
    }

    final season = Season(
      seasonId: seasonId,
      name: name,
      description: description,
      type: type,
      status: SeasonStatus.upcoming,
      startTime: startTime,
      endTime: startTime.add(Duration(days: durationDays)),
      duration: durationDays,
      passLevels: _generateDefaultPassLevels(),
      leaderboardId: '${seasonId}_leaderboard',
      hasPremiumPass: hasPremiumPass,
    );

    _seasons[seasonId] = season;
    await _saveSeasons();

    return true;
  }

  /// Add season XP for user
  Future<void> addSeasonXP(String userId, String seasonId, int xp) async {
    final season = _seasons[seasonId];
    if (season == null || !season.isActive) {
      return;
    }

    final progressKey = '${userId}_$seasonId';
    var progress = _userProgress[progressKey];

    if (progress == null) {
      progress = UserSeasonProgress(
        userId: userId,
        seasonId: seasonId,
        currentLevel: 1,
        currentXP: 0,
        hasPremiumPass: false,
        claimedFreeLevels: {},
        claimedPremiumLevels: {},
      );
    }

    var newXP = progress.currentXP + xp;
    var newLevel = progress.currentLevel;

    // Check for level up
    while (newLevel < season.maxLevel && newXP >= season.xpPerLevel) {
      newXP -= season.xpPerLevel;
      newLevel++;
    }

    final updatedProgress = progress.copyWith(
      currentLevel: newLevel,
      currentXP: newXP,
    );

    _userProgress[progressKey] = updatedProgress;
    await _saveUserProgress();

    _progressController.add(updatedProgress);
  }

  /// Get user season progress
  UserSeasonProgress? getUserProgress(String userId, String seasonId) {
    return _userProgress['${userId}_$seasonId'];
  }

  /// Claim season reward
  Future<List<SeasonReward>> claimReward(
    String userId,
    String seasonId,
    int level, {
    bool isPremium = false,
  }) async {
    final season = _seasons[seasonId];
    if (season == null) {
      throw Exception('Season not found');
    }

    final progressKey = '${userId}_$seasonId';
    final progress = _userProgress[progressKey];
    if (progress == null) {
      throw Exception('Progress not found');
    }

    if (!progress.canClaimReward(level, isPremium: isPremium)) {
      throw Exception('Reward not claimable');
    }

    final passLevel = season.passLevels.firstWhere(
      (l) => l.level == level,
      orElse: () => throw Exception('Level not found'),
    );

    final rewards = isPremium ? passLevel.premiumRewards : passLevel.freeRewards;

    // Update claimed levels
    final updatedProgress = progress.copyWith(
      claimedFreeLevels: isPremium
          ? progress.claimedFreeLevels
          : {...progress.claimedFreeLevels, level},
      claimedPremiumLevels: isPremium
          ? {...progress.claimedPremiumLevels, level}
          : progress.claimedPremiumLevels,
    );

    _userProgress[progressKey] = updatedProgress;
    await _saveUserProgress();

    _progressController.add(updatedProgress);

    return rewards;
  }

  /// Purchase premium pass
  Future<bool> purchasePremiumPass(String userId, String seasonId) async {
    final season = _seasons[seasonId];
    if (season == null || !season.hasPremiumPass) {
      return false;
    }

    final progressKey = '${userId}_$seasonId';
    final progress = _userProgress[progressKey];

    if (progress?.hasPremiumPass ?? false) {
      return false; // Already has premium pass
    }

    final updatedProgress = (progress ?? UserSeasonProgress(
      userId: userId,
      seasonId: seasonId,
      currentLevel: 1,
      currentXP: 0,
      hasPremiumPass: false,
      claimedFreeLevels: {},
      claimedPremiumLevels: {},
    )).copyWith(hasPremiumPass: true);

    _userProgress[progressKey] = updatedProgress;
    await _saveUserProgress();

    _progressController.add(updatedProgress);

    return true;
  }

  /// Get season rewards for user
  List<SeasonReward> getClaimableRewards(String userId, String seasonId) {
    final progress = getUserProgress(userId, seasonId);
    final season = _seasons[seasonId];

    if (progress == null || season == null) {
      return [];
    }

    final claimableRewards = <SeasonReward>[];

    for (final level in season.passLevels) {
      if (level.level > progress.currentLevel) break;

      // Check free rewards
      for (final reward in level.freeRewards) {
        if (!progress.claimedFreeLevels.contains(level.level)) {
          claimableRewards.add(reward);
        }
      }

      // Check premium rewards
      if (progress.hasPremiumPass) {
        for (final reward in level.premiumRewards) {
          if (!progress.claimedPremiumLevels.contains(level.level)) {
            claimableRewards.add(reward);
          }
        }
      }
    }

    return claimableRewards;
  }

  /// Start season status checker
  void _startSeasonChecker() {
    Timer.periodic(const Duration(hours: 1), (_) {
      _checkSeasonStatus();
    });
  }

  /// Check and update season status
  Future<void> _checkSeasonStatus() async {
    final now = DateTime.now();
    bool needsUpdate = false;

    for (final season in _seasons.values) {
      SeasonStatus newStatus;

      if (now.isBefore(season.startTime)) {
        newStatus = SeasonStatus.upcoming;
      } else if (now.isAfter(season.endTime)) {
        newStatus = SeasonStatus.ended;
      } else {
        newStatus = SeasonStatus.active;
      }

      if (season.status != newStatus) {
        final updated = Season(
          seasonId: season.seasonId,
          name: season.name,
          description: season.description,
          type: season.type,
          status: newStatus,
          startTime: season.startTime,
          endTime: season.endTime,
          duration: season.duration,
          passLevels: season.passLevels,
          leaderboardId: season.leaderboardId,
          hasPremiumPass: season.hasPremiumPass,
          maxLevel: season.maxLevel,
          xpPerLevel: season.xpPerLevel,
        );

        _seasons[season.seasonId] = updated;
        needsUpdate = true;

        _seasonController.add(updated);
      }
    }

    if (needsUpdate) {
      await _saveSeasons();
    }
  }

  /// End season and archive
  Future<void> endSeason(String seasonId) async {
    final season = _seasons[seasonId];
    if (season == null) return;

    final updated = Season(
      seasonId: season.seasonId,
      name: season.name,
      description: season.description,
      type: season.type,
      status: SeasonStatus.ended,
      startTime: season.startTime,
      endTime: season.endTime,
      duration: season.duration,
      passLevels: season.passLevels,
      leaderboardId: season.leaderboardId,
      hasPremiumPass: season.hasPremiumPass,
      maxLevel: season.maxLevel,
      xpPerLevel: season.xpPerLevel,
    );

    _seasons[seasonId] = updated;
    await _saveSeasons();

    _seasonController.add(updated);
  }

  /// Dispose of resources
  void dispose() {
    _seasonController.close();
    _progressController.close();
  }
}

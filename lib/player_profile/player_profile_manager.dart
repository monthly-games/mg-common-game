import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 프로필 배지
class ProfileBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime? earnedAt;
  final int displayOrder;

  const ProfileBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.earnedAt,
    this.displayOrder = 0,
  });

  /// 획득 여부
  bool get isEarned => earnedAt != null;
}

/// 칭호
class Title {
  final String id;
  final String name;
  final String description;
  final String? prefix; // 앞에 붙일 때
  final String? suffix; // 뒤에 붙일 때
  final int rarity; // 1-5
  final DateTime? earnedAt;

  const Title({
    required this.id,
    required this.name,
    required this.description,
    this.prefix,
    this.suffix,
    required this.rarity,
    this.earnedAt,
  });

  /// 획득 여부
  bool get isEarned => earnedAt != null;
}

/// 장비 슬롯
class EquipmentSlot {
  final String slotId;
  final String name;
  final String? itemId;
  final String? itemName;
  final String? itemIcon;
  final int? rarity;

  const EquipmentSlot({
    required this.slotId,
    required this.name,
    this.itemId,
    this.itemName,
    this.itemIcon,
    this.rarity,
  });

  /// 장착 여부
  bool get isEquipped => itemId != null;
}

/// 프로필 통계
class ProfileStatistics {
  final int totalPlayTime; // 초
  final int totalGames;
  final int wins;
  final int losses;
  final double winRate;
  final int totalKills;
  final int totalDeaths;
  final double kda;
  final int maxKillStreak;
  final int totalDamage;
  final int totalHeal;
  final int rank;
  final int level;

  const ProfileStatistics({
    required this.totalPlayTime,
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.totalKills,
    required this.totalDeaths,
    required this.kda,
    required this.maxKillStreak,
    required this.totalDamage,
    required this.totalHeal,
    required this.rank,
    required this.level,
  });

  /// 플레이 시간 형식
  String get formattedPlayTime {
    final hours = totalPlayTime ~/ 3600;
    final minutes = (totalPlayTime % 3600) ~/ 60;
    return '${hours}시간 ${minutes}분';
  }

  /// KDA 형식
  String get formattedKDA {
    return '${kda.toStringAsFixed(2)}';
  }
}

/// 방문 기록
class VisitRecord {
  final String visitorId;
  final String visitorName;
  final DateTime visitedAt;
  final int? profileViews;

  const VisitRecord({
    required this.visitorId,
    required this.visitorName,
    required this.visitedAt,
    this.profileViews,
  });
}

/// 플레이어 프로필
class PlayerProfile {
  final String userId;
  final String username;
  final String? displayName;
  final String? avatar;
  final String? bannerImage;
  final String? bio;
  final int level;
  final int exp;
  final int maxExp;
  final String? titleId;
  final List<ProfileBadge> badges;
  final List<EquipmentSlot> equipment;
  final ProfileStatistics statistics;
  final List<String> favoriteCharacters;
  final String? guildId;
  final String? guildName;
  final String? guildTag;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int profileViews;
  final List<VisitRecord> recentVisitors;

  const PlayerProfile({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatar,
    this.bannerImage,
    this.bio,
    required this.level,
    required this.exp,
    required this.maxExp,
    this.titleId,
    required this.badges,
    required this.equipment,
    required this.statistics,
    required this.favoriteCharacters,
    this.guildId,
    this.guildName,
    this.guildTag,
    this.createdAt,
    this.lastLoginAt,
    required this.profileViews,
    required this.recentVisitors,
  });

  /// 표시 이름
  String get display => displayName ?? username;

  /// 레벨 진행률
  double get levelProgress {
    if (maxExp == 0) return 0.0;
    return exp / maxExp;
  }

  /// 전시 배지 (최대 3개)
  List<ProfileBadge> get displayBadges {
    return badges.where((b) => b.isEarned).take(3).toList();
  }
}

/// 프로필 커스터마이징 설정
class ProfileCustomization {
  final String? bannerImage;
  final Color? bannerColor;
  final String? bio;
  final List<String> selectedBadges;
  final String? titleId;
  final List<EquipmentSlot> equipment;
  final bool showOnlineStatus;
  final bool showStatistics;
  final bool showAchievements;

  const ProfileCustomization({
    this.bannerImage,
    this.bannerColor,
    this.bio,
    this.selectedBadges = const [],
    this.titleId,
    this.equipment = const [],
    this.showOnlineStatus = true,
    this.showStatistics = true,
    this.showAchievements = true,
  });
}

/// 프로필 관리자
class PlayerProfileManager {
  static final PlayerProfileManager _instance = PlayerProfileManager._();
  static PlayerProfileManager get instance => _instance;

  PlayerProfileManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  PlayerProfile? _myProfile;
  final Map<String, PlayerProfile> _cachedProfiles = {};

  final StreamController<PlayerProfile> _profileController =
      StreamController<PlayerProfile>.broadcast();
  final StreamController<VisitRecord> _visitController =
      StreamController<VisitRecord>.broadcast();

  Stream<PlayerProfile> get onProfileUpdate => _profileController.stream;
  Stream<VisitRecord> get onProfileVisit => _visitController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 내 프로필 로드
    if (_currentUserId != null) {
      await _loadMyProfile(_currentUserId!);
    }

    debugPrint('[PlayerProfile] Initialized');
  }

  Future<void> _loadMyProfile(String userId) async {
    final json = _prefs?.getString('profile_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[PlayerProfile] Error loading profile: $e');
      }
    }

    // 기본 프로필 생성
    _myProfile = _generateDefaultProfile(userId);
  }

  PlayerProfile _generateDefaultProfile(String userId) {
    // 샘플 배지
    final badges = [
      const ProfileBadge(
        id: 'badge_1',
        name: '챔피언',
        description: '리그 1위 달성',
        icon: 'assets/badges/champion.png',
        earnedAt: DateTime(2024, 1, 15),
        displayOrder: 1,
      ),
      const ProfileBadge(
        id: 'badge_2',
        name: '레전더리',
        description: '레벨 100 달성',
        icon: 'assets/badges/legendary.png',
        earnedAt: DateTime(2024, 3, 20),
        displayOrder: 2,
      ),
      const ProfileBadge(
        id: 'badge_3',
        name: '베테랑',
        description: '365일 플레이',
        icon: 'assets/badges/veteran.png',
        earnedAt: null,
        displayOrder: 3,
      ),
    ];

    // 샘플 장비
    final equipment = [
      const EquipmentSlot(
        slotId: 'weapon',
        name: '무기',
        itemId: 'weapon_legendary_1',
        itemName: '전설의 검',
        itemIcon: 'assets/items/legendary_sword.png',
        rarity: 5,
      ),
      const EquipmentSlot(
        slotId: 'armor',
        name: '방어구',
        itemId: 'armor_epic_1',
        itemName: '에픽 갑옷',
        itemIcon: 'assets/items/epic_armor.png',
        rarity: 4,
      ),
      const EquipmentSlot(
        slotId: 'accessory',
        name: '악세사리',
        itemId: null,
        itemName: null,
        itemIcon: null,
        rarity: null,
      ),
    ];

    // 샘플 통계
    final statistics = const ProfileStatistics(
      totalPlayTime: 345678, // 약 960시간
      totalGames: 5432,
      wins: 3245,
      losses: 2187,
      winRate: 0.597,
      totalKills: 45678,
      totalDeaths: 23456,
      kda: 2.34,
      maxKillStreak: 15,
      totalDamage: 9876543,
      totalHeal: 2345678,
      rank: 123,
      level: 87,
    );

    // 샘플 방문자
    final visitors = [
      const VisitRecord(
        visitorId: 'user_1',
        visitorName: 'DragonSlayer',
        visitedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        profileViews: 3,
      ),
      const VisitRecord(
        visitorId: 'user_2',
        visitorName: 'StarPlayer',
        visitedAt: DateTime.now().subtract(const Duration(hours: 1)),
        profileViews: 7,
      ),
      const VisitRecord(
        visitorId: 'user_3',
        visitorName: 'NightHawk',
        visitedAt: DateTime.now().subtract(const Duration(hours: 3)),
        profileViews: 2,
      ),
    ];

    return PlayerProfile(
      userId: userId,
      username: 'Player123', // 실제 유저명
      displayName: '용사',
      avatar: 'assets/avatars/default.png',
      bannerImage: 'assets/banners/default.png',
      bio: '열심히 게임하는 플레이어입니다! 같이 해요~',
      level: 87,
      exp: 45000,
      maxExp: 50000,
      titleId: 'title_champion',
      badges: badges,
      equipment: equipment,
      statistics: statistics,
      favoriteCharacters: ['char_1', 'char_3', 'char_5'],
      guildId: 'guild_123',
      guildName: '전설의 길드',
      guildTag: '전설',
      createdAt: DateTime(2023, 6, 15),
      lastLoginAt: DateTime.now().subtract(const Duration(minutes: 10)),
      profileViews: 234,
      recentVisitors: visitors,
    );
  }

  /// 프로필 조회
  Future<PlayerProfile?> getProfile(String userId) async {
    // 내 프로필
    if (userId == _currentUserId) {
      return _myProfile;
    }

    // 캐시 확인
    if (_cachedProfiles.containsKey(userId)) {
      return _cachedProfiles[userId];
    }

    // 서버에서 조회 (시뮬레이션)
    final profile = _generateOtherProfile(userId);
    _cachedProfiles[userId] = profile;

    // 방문 기록 추가
    await _recordVisit(userId);

    return profile;
  }

  PlayerProfile _generateOtherProfile(String userId) {
    return PlayerProfile(
      userId: userId,
      username: 'OtherPlayer',
      displayName: '다른플레이어',
      avatar: 'assets/avatars/other.png',
      bannerImage: 'assets/banners/other.png',
      bio: '안녕하세요!',
      level: 50,
      exp: 25000,
      maxExp: 30000,
      badges: [],
      equipment: const [],
      statistics: const ProfileStatistics(
        totalPlayTime: 100000,
        totalGames: 1000,
        wins: 500,
        losses: 500,
        winRate: 0.5,
        totalKills: 10000,
        totalDeaths: 10000,
        kda: 1.0,
        maxKillStreak: 5,
        totalDamage: 1000000,
        totalHeal: 500000,
        rank: 500,
        level: 50,
      ),
      favoriteCharacters: [],
      profileViews: 50,
      recentVisitors: [],
    );
  }

  /// 프로필 업데이트
  Future<bool> updateProfile(ProfileCustomization customization) async {
    if (_myProfile == null) return false;

    final updated = PlayerProfile(
      userId: _myProfile!.userId,
      username: _myProfile!.username,
      displayName: customization.selectedBadges.isNotEmpty
          ? _myProfile!.displayName
          : null,
      avatar: _myProfile!.avatar,
      bannerImage: customization.bannerImage ?? _myProfile!.bannerImage,
      bio: customization.bio ?? _myProfile!.bio,
      level: _myProfile!.level,
      exp: _myProfile!.exp,
      maxExp: _myProfile!.maxExp,
      titleId: customization.titleId ?? _myProfile!.titleId,
      badges: _updateBadges(customization.selectedBadges),
      equipment: customization.equipment,
      statistics: _myProfile!.statistics,
      favoriteCharacters: _myProfile!.favoriteCharacters,
      guildId: _myProfile!.guildId,
      guildName: _myProfile!.guildName,
      guildTag: _myProfile!.guildTag,
      createdAt: _myProfile!.createdAt,
      lastLoginAt: _myProfile!.lastLoginAt,
      profileViews: _myProfile!.profileViews,
      recentVisitors: _myProfile!.recentVisitors,
    );

    _myProfile = updated;
    _profileController.add(updated);

    await _saveProfile();

    debugPrint('[PlayerProfile] Profile updated');

    return true;
  }

  List<ProfileBadge> _updateBadges(List<String> selectedIds) {
    if (_myProfile == null) return [];

    return _myProfile!.badges.map((badge) {
      final index = selectedIds.indexOf(badge.id);
      return ProfileBadge(
        id: badge.id,
        name: badge.name,
        description: badge.description,
        icon: badge.icon,
        earnedAt: badge.earnedAt,
        displayOrder: index >= 0 ? index : 999,
      );
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// 방문 기록
  Future<void> _recordVisit(String profileUserId) async {
    if (_currentUserId == null) return;

    final visit = VisitRecord(
      visitorId: _currentUserId!,
      visitorName: '나', // 실제 유저명
      visitedAt: DateTime.now(),
    );

    _visitController.add(visit);

    debugPrint('[PlayerProfile] Profile visited: $profileUserId');
  }

  /// 프로필 검색
  Future<List<PlayerProfile>> searchProfiles(String query) async {
    // 실제로는 서버 검색
    return [];
  }

  /// 칭호 변경
  Future<bool> setTitle(String titleId) async {
    if (_myProfile == null) return false;

    final updated = PlayerProfile(
      userId: _myProfile!.userId,
      username: _myProfile!.username,
      displayName: _myProfile!.displayName,
      avatar: _myProfile!.avatar,
      bannerImage: _myProfile!.bannerImage,
      bio: _myProfile!.bio,
      level: _myProfile!.level,
      exp: _myProfile!.exp,
      maxExp: _myProfile!.maxExp,
      titleId: titleId,
      badges: _myProfile!.badges,
      equipment: _myProfile!.equipment,
      statistics: _myProfile!.statistics,
      favoriteCharacters: _myProfile!.favoriteCharacters,
      guildId: _myProfile!.guildId,
      guildName: _myProfile!.guildName,
      guildTag: _myProfile!.guildTag,
      createdAt: _myProfile!.createdAt,
      lastLoginAt: _myProfile!.lastLoginAt,
      profileViews: _myProfile!.profileViews,
      recentVisitors: _myProfile!.recentVisitors,
    );

    _myProfile = updated;
    _profileController.add(updated);

    await _saveProfile();

    return true;
  }

  /// 배지 획득
  Future<bool> earnBadge({
    required String badgeId,
    required String name,
    required String description,
    required String icon,
  }) async {
    if (_myProfile == null) return false;

    // 이미 획득한 배지인지 확인
    if (_myProfile!.badges.any((b) => b.id == badgeId && b.isEarned)) {
      return false;
    }

    final badge = ProfileBadge(
      id: badgeId,
      name: name,
      description: description,
      icon: icon,
      earnedAt: DateTime.now(),
    );

    final updated = PlayerProfile(
      userId: _myProfile!.userId,
      username: _myProfile!.username,
      displayName: _myProfile!.displayName,
      avatar: _myProfile!.avatar,
      bannerImage: _myProfile!.bannerImage,
      bio: _myProfile!.bio,
      level: _myProfile!.level,
      exp: _myProfile!.exp,
      maxExp: _myProfile!.maxExp,
      titleId: _myProfile!.titleId,
      badges: [..._myProfile!.badges, badge],
      equipment: _myProfile!.equipment,
      statistics: _myProfile!.statistics,
      favoriteCharacters: _myProfile!.favoriteCharacters,
      guildId: _myProfile!.guildId,
      guildName: _myProfile!.guildName,
      guildTag: _myProfile!.guildTag,
      createdAt: _myProfile!.createdAt,
      lastLoginAt: _myProfile!.lastLoginAt,
      profileViews: _myProfile!.profileViews,
      recentVisitors: _myProfile!.recentVisitors,
    );

    _myProfile = updated;
    _profileController.add(updated);

    await _saveProfile();

    debugPrint('[PlayerProfile] Badge earned: $name');

    return true;
  }

  /// 장비 변경
  Future<bool> equipItem({
    required String slotId,
    required String itemId,
    required String itemName,
    required String itemIcon,
    required int rarity,
  }) async {
    if (_myProfile == null) return false;

    final slotIndex = _myProfile!.equipment.indexWhere((s) => s.slotId == slotId);
    if (slotIndex == -1) return false;

    final updatedSlot = EquipmentSlot(
      slotId: slotId,
      name: _myProfile!.equipment[slotIndex].name,
      itemId: itemId,
      itemName: itemName,
      itemIcon: itemIcon,
      rarity: rarity,
    );

    final updatedEquipment = List<EquipmentSlot>.from(_myProfile!.equipment);
    updatedEquipment[slotIndex] = updatedSlot;

    final updated = PlayerProfile(
      userId: _myProfile!.userId,
      username: _myProfile!.username,
      displayName: _myProfile!.displayName,
      avatar: _myProfile!.avatar,
      bannerImage: _myProfile!.bannerImage,
      bio: _myProfile!.bio,
      level: _myProfile!.level,
      exp: _myProfile!.exp,
      maxExp: _myProfile!.maxExp,
      titleId: _myProfile!.titleId,
      badges: _myProfile!.badges,
      equipment: updatedEquipment,
      statistics: _myProfile!.statistics,
      favoriteCharacters: _myProfile!.favoriteCharacters,
      guildId: _myProfile!.guildId,
      guildName: _myProfile!.guildName,
      guildTag: _myProfile!.guildTag,
      createdAt: _myProfile!.createdAt,
      lastLoginAt: _myProfile!.lastLoginAt,
      profileViews: _myProfile!.profileViews,
      recentVisitors: _myProfile!.recentVisitors,
    );

    _myProfile = updated;
    _profileController.add(updated);

    await _saveProfile();

    debugPrint('[PlayerProfile] Item equipped: $itemName');

    return true;
  }

  /// 내 프로필
  PlayerProfile? get myProfile => _myProfile;

  Future<void> _saveProfile() async {
    if (_currentUserId == null || _myProfile == null) return;

    final data = {
      'userId': _myProfile!.userId,
      'username': _myProfile!.username,
      'displayName': _myProfile!.displayName,
      'bio': _myProfile!.bio,
      'level': _myProfile!.level,
      'titleId': _myProfile!.titleId,
      'selectedBadges': _myProfile!.displayBadges.map((b) => b.id).toList(),
    };

    await _prefs?.setString(
      'profile_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _profileController.close();
    _visitController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 추천 유형
enum RecommendationType {
  collaborative,  // 협업 필터링
  contentBased,   // 콘텐츠 기반
  hybrid,         // 하이브리드
  popularity,     // 인기도 기반
  contextual,     // 문맥 기반
  personal,       // 개인화
}

/// 추천 아이템
class RecommendationItem {
  final String itemId;
  final String name;
  final String type; // character, item, skin, etc.
  final double score; // 0.0-1.0
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime? recommendedAt;

  const RecommendationItem({
    required this.itemId,
    required this.name,
    required this.type,
    required this.score,
    this.reason,
    this.metadata,
    this.recommendedAt,
  });
}

/// 유저 프로필 (추천용)
class UserProfile {
  final String userId;
  final Map<String, double> itemPreferences; // itemId -> preference score
  final Map<String, int> interactions; // itemId -> interaction count
  final Set<String> ownedItems;
  final Set<String> viewedItems;
  final Set<String> likedItems;
  final List<String> recentItems;
  final Map<String, dynamic> attributes; // 레벨, 클래스 등

  const UserProfile({
    required this.userId,
    required this.itemPreferences,
    required this.interactions,
    required this.ownedItems,
    required this.viewedItems,
    required this.likedItems,
    required this.recentItems,
    required this.attributes,
  });
}

/// 아이템 특성
class ItemFeatures {
  final String itemId;
  final Map<String, double> features; // feature -> value
  final Set<String> tags;
  final String category;
  final int rarity;
  final double popularity;

  const ItemFeatures({
    required this.itemId,
    required this.features,
    required this.tags,
    required this.category,
    required this.rarity,
    required this.popularity,
  });
}

/// 추천 결과
class RecommendationResult {
  final List<RecommendationItem> items;
  final RecommendationType type;
  final String? explanation;
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;

  const RecommendationResult({
    required this.items,
    required this.type,
    this.explanation,
    required this.generatedAt,
    this.metadata,
  });

  /// 상위 N개
  List<RecommendationItem> top(int n) {
    return items.take(n).toList();
  }
}

/// A/B 테스트 그룹
class TestGroup {
  final String groupId;
  final String name;
  final String algorithm;
  final Map<String, dynamic> parameters;

  const TestGroup({
    required this.groupId,
    required this.name,
    required this.algorithm,
    required this.parameters,
  });
}

/// 추천 엔진
class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._();
  static RecommendationEngine get instance => _instance;

  RecommendationEngine._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  UserProfile? _userProfile;
  final Map<String, ItemFeatures> _itemFeatures = {};
  TestGroup? _testGroup;

  final StreamController<RecommendationResult> _recommendationController =
      StreamController<RecommendationResult>.broadcast();

  Stream<RecommendationResult> get onRecommendation =>
      _recommendationController.stream;

  Timer? _updateTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 아이템 특성 로드
    await _loadItemFeatures();

    // 유저 프로필 로드
    if (_currentUserId != null) {
      await _loadUserProfile(_currentUserId!);
    }

    // A/B 테스트 그룹 할당
    _assignTestGroup();

    // 주기 업데이트 시작
    _startPeriodicUpdate();

    debugPrint('[RecommendationEngine] Initialized');
  }

  Future<void> _loadItemFeatures() async {
    // 샘플 아이템 특성
    _itemFeatures['char_1'] = const ItemFeatures(
      itemId: 'char_1',
      features: {
        'damage': 0.9,
        'tank': 0.1,
        'support': 0.2,
        'difficulty': 0.3,
      },
      tags: {'전사', '근접', 'DPS'},
      category: 'character',
      rarity: 5,
      popularity: 0.8,
    );

    _itemFeatures['char_2'] = const ItemFeatures(
      itemId: 'char_2',
      features: {
        'damage': 0.3,
        'tank': 0.9,
        'support': 0.1,
        'difficulty': 0.5,
      },
      tags: {'탱커', '방어', '근접'},
      category: 'character',
      rarity: 4,
      popularity: 0.6,
    );

    _itemFeatures['char_3'] = const ItemFeatures(
      itemId: 'char_3',
      features: {
        'damage': 0.2,
        'tank': 0.1,
        'support': 0.9,
        'difficulty': 0.6,
      },
      tags: {'힐러', '서포트', '원거리'},
      category: 'character',
      rarity: 4,
      popularity: 0.5,
    );

    _itemFeatures['item_legendary_1'] = const ItemFeatures(
      itemId: 'item_legendary_1',
      features: {
        'damage': 0.95,
        'critical': 0.8,
        'speed': 0.3,
      },
      tags: {'무기', '레전더리', 'DPS'},
      category: 'item',
      rarity: 5,
      popularity: 0.9,
    );

    _itemFeatures['skin_rare_1'] = const ItemFeatures(
      itemId: 'skin_rare_1',
      features: {
        'visual': 0.9,
        'effects': 0.7,
        'sound': 0.5,
      },
      tags: {'스킨', '희귀', '불'},
      category: 'skin',
      rarity: 3,
      popularity: 0.7,
    );
  }

  Future<void> _loadUserProfile(String userId) async {
    final json = _prefs?.getString('user_profile_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[RecommendationEngine] Error loading profile: $e');
      }
    }

    // 기본 프로필
    _userProfile = UserProfile(
      userId: userId,
      itemPreferences: {
        'char_1': 0.8,
        'char_2': 0.3,
        'item_legendary_1': 0.9,
      },
      interactions: {
        'char_1': 50,
        'char_2': 10,
      },
      ownedItems: {'char_1', 'char_2'},
      viewedItems: {'char_1', 'char_2', 'char_3'},
      likedItems: {'char_1'},
      recentItems: ['char_1', 'item_legendary_1'],
      attributes: {
        'level': 50,
        'class': 'warrior',
        'playStyle': 'aggressive',
      },
    );
  }

  void _assignTestGroup() {
    // 랜덤 그룹 할당
    final random = Random().nextInt(100);
    TestGroup group;

    if (random < 33) {
      group = const TestGroup(
        groupId: 'group_a',
        name: '협업 필터링',
        algorithm: 'collaborative',
        parameters: {'neighbors': 50},
      );
    } else if (random < 66) {
      group = const TestGroup(
        groupId: 'group_b',
        name: '콘텐츠 기반',
        algorithm: 'content_based',
        parameters: {'similarity_threshold': 0.7},
      );
    } else {
      group = const TestGroup(
        groupId: 'group_c',
        name: '하이브리드',
        algorithm: 'hybrid',
        parameters: {'collaborative_weight': 0.6, 'content_weight': 0.4},
      );
    }

    _testGroup = group;

    debugPrint('[RecommendationEngine] Assigned to group: ${group.name}');
  }

  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _updateUserProfile();
    });
  }

  void _updateUserProfile() {
    if (_userProfile == null) return;

    // 실시간으로 유저 프로필 업데이트
    // 상호작용 추적 등
  }

  /// 추천 생성
  Future<RecommendationResult> generateRecommendations({
    required String type, // character, item, skin
    RecommendationType algorithm = RecommendationType.hybrid,
    int limit = 10,
  }) async {
    if (_userProfile == null) {
      // 기본 추천
      return _generateDefaultRecommendations(type: type, limit: limit);
    }

    List<RecommendationItem> items;

    switch (algorithm) {
      case RecommendationType.collaborative:
        items = _collaborativeFiltering(type: type, limit: limit);
        break;
      case RecommendationType.contentBased:
        items = _contentBasedFiltering(type: type, limit: limit);
        break;
      case RecommendationType.hybrid:
        items = _hybridFiltering(type: type, limit: limit);
        break;
      case RecommendationType.popularity:
        items = _popularityBased(type: type, limit: limit);
        break;
      case RecommendationType.contextual:
        items = _contextualBased(type: type, limit: limit);
        break;
      case RecommendationType.personal:
        items = _personalized(type: type, limit: limit);
        break;
    }

    final result = RecommendationResult(
      items: items,
      type: algorithm,
      explanation: _generateExplanation(algorithm),
      generatedAt: DateTime.now(),
      metadata: {
        'testGroup': _testGroup?.groupId,
        'algorithm': _testGroup?.algorithm,
      },
    );

    _recommendationController.add(result);

    return result;
  }

  /// 협업 필터링
  List<RecommendationItem> _collaborativeFiltering({
    required String type,
    required int limit,
  }) {
    final recommendations = <RecommendationItem>[];

    // 유사 유저 찾기 (시뮬레이션)
    final similarUsers = _findSimilarUsers();

    // 유사 유저가 선호하는 아이템 추천
    for (final userId in similarUsers) {
      // 실제로는 해당 유저의 프로필에서 아이템 가져옴
      // 여기서는 시뮬레이션
    }

    return recommendations..sort((a, b) => b.score.compareTo(a.score));
  }

  List<String> _findSimilarUsers() {
    // 코사인 유사도 계산 (시뮬레이션)
    return ['user_2', 'user_5', 'user_8'];
  }

  /// 콘텐츠 기반 필터링
  List<RecommendationItem> _contentBasedFiltering({
    required String type,
    required int limit,
  }) {
    if (_userProfile == null) return [];

    final recommendations = <RecommendationItem>[];
    final profile = _userProfile!;

    // 사용자가 좋아하는 아이템들의 특성 추출
    final userFeatures = _extractUserFeatures();

    for (final entry in _itemFeatures.entries) {
      final features = entry.value;
      if (features.category != type) continue;
      if (profile.ownedItems.contains(features.itemId)) continue;

      // 특성 유사도 계산
      final similarity = _calculateSimilarity(userFeatures, features.features);

      if (similarity > 0.5) {
        recommendations.add(RecommendationItem(
          itemId: features.itemId,
          name: '${features.category}_${features.itemId}',
          type: features.category,
          score: similarity,
          reason: '취향과 유사함',
        ));
      }
    }

    return recommendations..sort((a, b) => b.score.compareTo(a.score));
  }

  Map<String, double> _extractUserFeatures() {
    if (_userProfile == null) return {};

    final userFeatures = <String, double>{};

    for (final itemId in _userProfile!.likedItems) {
      final features = _itemFeatures[itemId];
      if (features != null) {
        for (final entry in features.features.entries) {
          userFeatures[entry.key] =
              (userFeatures[entry.key] ?? 0) + entry.value * 0.5;
        }
      }
    }

    for (final itemId in _userProfile!.recentItems) {
      final features = _itemFeatures[itemId];
      if (features != null) {
        for (final entry in features.features.entries) {
          userFeatures[entry.key] =
              (userFeatures[entry.key] ?? 0) + entry.value * 0.3;
        }
      }
    }

    return userFeatures;
  }

  double _calculateSimilarity(
    Map<String, double> features1,
    Map<String, double> features2,
  ) {
    // 코사인 유사도
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    final allKeys = {...features1.keys, ...features2.keys};

    for (final key in allKeys) {
      final v1 = features1[key] ?? 0;
      final v2 = features2[key] ?? 0;
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }

    if (norm1 == 0 || norm2 == 0) return 0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// 하이브리드 필터링
  List<RecommendationItem> _hybridFiltering({
    required String type,
    required int limit,
  }) {
    final collaborative = _collaborativeFiltering(type: type, limit: limit * 2);
    final contentBased = _contentBasedFiltering(type: type, limit: limit * 2);

    // 가중 평균 (협업 60%, 콘텐츠 40%)
    final combined = <String, RecommendationItem>{};

    for (final item in collaborative) {
      final existing = combined[item.itemId];
      if (existing != null) {
        // 평균
        combined[item.itemId] = RecommendationItem(
          itemId: item.itemId,
          name: item.name,
          type: item.type,
          score: (existing.score + item.score * 0.6) / 2,
          reason: '비슷한 취향',
        );
      } else {
        combined[item.itemId] = RecommendationItem(
          itemId: item.itemId,
          name: item.name,
          type: item.type,
          score: item.score * 0.6,
          reason: '비슷한 취향',
        );
      }
    }

    for (final item in contentBased) {
      final existing = combined[item.itemId];
      if (existing != null) {
        combined[item.itemId] = RecommendationItem(
          itemId: item.itemId,
          name: item.name,
          type: item.type,
          score: existing.score + item.score * 0.4,
          reason: '유사한 아이템',
        );
      } else {
        combined[item.itemId] = RecommendationItem(
          itemId: item.itemId,
          name: item.name,
          type: item.type,
          score: item.score * 0.4,
          reason: '유사한 아이템',
        );
      }
    }

    return combined.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// 인기도 기반
  List<RecommendationItem> _popularityBased({
    required String type,
    required int limit,
  }) {
    final items = _itemFeatures.values
        .where((f) => f.category == type)
        .toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));

    return items.take(limit).map((f) => RecommendationItem(
      itemId: f.itemId,
      name: f.itemId,
      type: f.category,
      score: f.popularity,
      reason: '인기 아이템',
    )).toList();
  }

  /// 문맥 기반
  List<RecommendationItem> _contextualBased({
    required String type,
    required int limit,
  }) {
    if (_userProfile == null) return [];

    // 유저의 현재 문맥(레벨, 클래스 등) 고려
    final level = _userProfile!.attributes['level'] as int? ?? 1;
    final userClass = _userProfile!.attributes['class'] as String? ?? 'warrior';

    final recommendations = <RecommendationItem>[];

    for (final entry in _itemFeatures.entries) {
      final features = entry.value;
      if (features.category != type) continue;

      var score = 0.0;

      // 레벨 기반 추천
      if (features.rarity <= level ~/ 20) {
        score += 0.3;
      }

      // 클래스 기반 추천
      if (userClass == 'warrior' && features.tags.contains('근접')) {
        score += 0.4;
      }

      if (score > 0.3) {
        recommendations.add(RecommendationItem(
          itemId: features.itemId,
          name: features.itemId,
          type: features.category,
          score: score,
          reason: '현재 상황에 적합',
        ));
      }
    }

    return recommendations..sort((a, b) => b.score.compareTo(a.score));
  }

  /// 개인화 추천
  List<RecommendationItem> _personalized({
    required String type,
    required int limit,
  }) {
    // 다양한 요소 결합
    final collaborative = _collaborativeFiltering(type: type, limit: limit);
    final contentBased = _contentBasedFiltering(type: type, limit: limit);
    final contextual = _contextualBased(type: type, limit: limit);

    final combined = <String, List<double>>{}; // itemId -> [scores]

    for (final item in collaborative) {
      combined.putIfAbsent(item.itemId, () => []).add(item.score);
    }
    for (final item in contentBased) {
      combined.putIfAbsent(item.itemId, () => []).add(item.score);
    }
    for (final item in contextual) {
      combined.putIfAbsent(item.itemId, () => []).add(item.score);
    }

    // 평균 계산
    final recommendations = combined.entries.map((entry) {
      final avgScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return RecommendationItem(
        itemId: entry.key,
        name: entry.key,
        type: type,
        score: avgScore,
        reason: '맞춤 추천',
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return recommendations.take(limit).toList();
  }

  /// 기본 추천
  RecommendationResult _generateDefaultRecommendations({
    required String type,
    required int limit,
  }) {
    final items = _popularityBased(type: type, limit: limit);

    return RecommendationResult(
      items: items,
      type: RecommendationType.popularity,
      explanation: '인기 아이템',
      generatedAt: DateTime.now(),
    );
  }

  String _generateExplanation(RecommendationType type) {
    switch (type) {
      case RecommendationType.collaborative:
        return '비슷한 취향을 가진 유저들이 좋아합니다';
      case RecommendationType.contentBased:
        return '취향과 유사한 아이템입니다';
      case RecommendationType.hybrid:
        return '다양한 요소를 고려한 맞춤 추천입니다';
      case RecommendationType.popularity:
        return '많은 유저들이 관심을 가지고 있습니다';
      case RecommendationType.contextual:
        return '현재 상황에 적합한 아이템입니다';
      case RecommendationType.personal:
        return '나에게 맞는 추천입니다';
    }
  }

  /// 상호작용 기록
  Future<void> recordInteraction({
    required String itemId,
    required String interactionType, // view, like, purchase, etc.
  }) async {
    if (_userProfile == null) return;

    final preferences = Map<String, double>.from(_userProfile!.itemPreferences);
    final interactions = Map<String, int>.from(_userProfile!.interactions);
    final viewed = Set<String>.from(_userProfile!.viewedItems);
    final liked = Set<String>.from(_userProfile!.likedItems);
    final recent = List<String>.from(_userProfile!.recentItems);

    // 상호작용 반영
    interactions[itemId] = (interactions[itemId] ?? 0) + 1;

    switch (interactionType) {
      case 'view':
        viewed.add(itemId);
        preferences[itemId] = (preferences[itemId] ?? 0) + 0.1;
        break;
      case 'like':
        liked.add(itemId);
        preferences[itemId] = (preferences[itemId] ?? 0) + 0.5;
        break;
      case 'purchase':
        preferences[itemId] = (preferences[itemId] ?? 0) + 1.0;
        break;
    }

    recent.insert(0, itemId);
    if (recent.length > 10) {
      recent.removeLast();
    }

    _userProfile = UserProfile(
      userId: _userProfile!.userId,
      itemPreferences: preferences,
      interactions: interactions,
      ownedItems: _userProfile!.ownedItems,
      viewedItems: viewed,
      likedItems: liked,
      recentItems: recent,
      attributes: _userProfile!.attributes,
    );

    await _saveUserProfile();

    debugPrint('[RecommendationEngine] Interaction recorded: $itemId ($interactionType)');
  }

  /// A/B 테스트 결과 보고
  Map<String, dynamic> reportTestResults() {
    if (_testGroup == null) return {};

    return {
      'groupId': _testGroup!.groupId,
      'groupName': _testGroup!.name,
      'algorithm': _testGroup!.algorithm,
      'parameters': _testGroup!.parameters,
    };
  }

  Future<void> _saveUserProfile() async {
    if (_currentUserId == null || _userProfile == null) return;

    final data = {
      'itemPreferences': _userProfile!.itemPreferences,
      'interactions': _userProfile!.interactions,
      'ownedItems': _userProfile!.ownedItems.toList(),
      'viewedItems': _userProfile!.viewedItems.toList(),
      'likedItems': _userProfile!.likedItems.toList(),
      'recentItems': _userProfile!.recentItems,
      'attributes': _userProfile!.attributes,
    };

    await _prefs?.setString(
      'user_profile_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _recommendationController.close();
    _updateTimer?.cancel();
  }
}

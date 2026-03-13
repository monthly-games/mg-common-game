import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 추천 알고리즘 타입
enum RecommendationAlgorithm {
  contentBased,      // 콘텐츠 기반 필터링
  collaborative,      // 협업 필터링
  hybrid,            // 하이브리드
  popularity,        // 인기도 기반
  personalized,      // 개인화된 추천
}

/// 추천 아이템
class RecommendableItem {
  final String id;
  final String type; // 'game', 'quest', 'event', 'shop_item'
  final String name;
  final String description;
  final Map<String, double> features; // 특징 벡터
  final List<String> categories;
  final double popularityScore;
  final DateTime? releaseDate;

  const RecommendableItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.features,
    required this.categories,
    this.popularityScore = 0.0,
    this.releaseDate,
  });

  /// 특징 벡터 정규화
  Map<String, double> get normalizedFeatures {
    if (features.isEmpty) return {};

    final maxVal = features.values.reduce((a, b) => a > b ? a : b);

    return features.map((key, value) =>
      MapEntry(key, maxVal > 0 ? value / maxVal : 0.0));
  }

  /// 코사인 유사도 계산
  double cosineSimilarity(RecommendableItem other) {
    final normFeatures = normalizedFeatures;
    final otherNormFeatures = other.normalizedFeatures;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (final key in {...normFeatures.keys, ...otherNormFeatures.keys}) {
      final a = normFeatures[key] ?? 0;
      final b = otherNormFeatures[key] ?? 0;

      dotProduct += a * b;
      normA += a * a;
      normB += b * b;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB) + 1e-10);
  }
}

/// 사용자 프로필
class UserProfile {
  final String userId;
  final Map<String, double> preferences; // 카테고리별 선호도
  final Map<String, double> itemRatings; // 아이템별 평점
  final List<String> viewedItems;
  final List<String> favoriteItems;
  final Map<String, dynamic> demographics;

  const UserProfile({
    required this.userId,
    required this.preferences,
    required this.itemRatings,
    required this.viewedItems,
    required this.favoriteItems,
    this.demographics = const {},
  });

  /// 평균 평점
  double get averageRating {
    if (itemRatings.isEmpty) return 0;
    return itemRatings.values.reduce((a, b) => a + b) / itemRatings.length;
  }

  /// 선호도 정규화
  Map<String, double> get normalizedPreferences {
    if (preferences.isEmpty) return {};

    final maxVal = preferences.values.reduce((a, b) => a > b ? a : b);

    return preferences.map((key, value) =>
      MapEntry(key, maxVal > 0 ? value / maxVal : 0.0));
  }
}

/// 추천 결과
class RecommendationResult {
  final RecommendableItem item;
  final double score;
  final String reason;
  final RecommendationAlgorithm algorithm;

  const RecommendationResult({
    required this.item,
    required this.score,
    required this.reason,
    required this.algorithm,
  });

  Map<String, dynamic> toJson() => {
        'itemId': item.id,
        'itemType': item.type,
        'itemName': item.name,
        'score': score,
        'reason': reason,
        'algorithm': algorithm.name,
      };
}

/// 추천 엔진
class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._();
  static RecommendationEngine get instance => _instance;

  RecommendationEngine._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;

  final Map<String, RecommendableItem> _items = {};
  final Map<String, UserProfile> _userProfiles = {};

  final StreamController<List<RecommendationResult>> _recommendationController =
      StreamController<List<RecommendationResult>>.broadcast();

  // Getters
  Stream<List<RecommendationResult>> get onRecommendations =>
      _recommendationController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 데이터 로드
    await _loadItems();
    await _loadUserProfiles();

    debugPrint('[Recommendation] Initialized');
  }

  Future<void> _loadItems() async {
    // 실제로는 서버에서 아이템 데이터를 가져옴
    // 여기서는 기본 게임 아이템 등록

    // 게임 아이템 예시
    _items['game_0047'] = RecommendableItem(
      id: 'game_0047',
      type: 'game',
      name: '요리 대작',
      description: '맛있는 요리를 만드는 게임',
      features: {
        'difficulty': 0.3,
        'casual': 0.9,
        'puzzle': 0.7,
        'creative': 0.8,
      },
      categories: ['캐주얼', '퍼즐', '창의'],
      popularityScore: 0.85,
    );

    _items['game_0046'] = RecommendableItem(
      id: 'game_0046',
      type: 'game',
      name: '스피드 레이싱',
      description: '빠른 자동차 레이싱',
      features: {
        'difficulty': 0.7,
        'action': 0.9,
        'competitive': 0.8,
        'racing': 1.0,
      },
      categories: ['액션', '레이싱', '경쟁'],
      popularityScore: 0.92,
    );

    _items['game_0045'] = RecommendableItem(
      id: 'game_0045',
      type: 'game',
      name: '스포츠 스타',
      description: '다양한 스포츠 게임',
      features: {
        'difficulty': 0.5,
        'sports': 1.0,
        'multiplayer': 0.9,
        'competitive': 0.7,
      },
      categories: ['스포츠', '멀티플레이어'],
      popularityScore: 0.78,
    );

    // 퀘스트 아이템
    _items['quest_daily_001'] = RecommendableItem(
      id: 'quest_daily_001',
      type: 'quest',
      name: '일일 퀘스트: 챔피언',
      description: '3번 승리하여 보상 받기',
      features: {
        'difficulty': 0.6,
        'daily': 1.0,
        'reward': 0.8,
        'competitive': 0.9,
      },
      categories: ['일일', '경쟁', '보상'],
      popularityScore: 0.95,
    );

    debugPrint('[Recommendation] Loaded ${_items.length} items');
  }

  Future<void> _loadUserProfiles() async {
    // 서버에서 사용자 프로필 로드
    // 여기서는 빈 프로필로 시작
  }

  // ============================================
  // 콘텐츠 기반 필터링
  // ============================================

  /// 콘텐츠 기반 추천
  List<RecommendationResult> recommendByContent({
    required String userId,
    String? itemType,
    int limit = 10,
  }) {
    final profile = _userProfiles[userId];
    if (profile == null) {
      // 프로필이 없으면 인기도 기반 추천
      return recommendByPopularity(itemType: itemType, limit: limit);
    }

    // 사용자 선호도와 유사한 아이템 찾기
    final results = <RecommendationResult>[];

    for (final item in _items.values) {
      if (itemType != null && item.type != itemType) continue;
      if (profile.viewedItems.contains(item.id)) continue;

      // 카테고리 유사도 계산
      double categoryScore = 0;
      for (final category in item.categories) {
        categoryScore += profile.normalizedPreferences[category] ?? 0;
      }

      // 특징 유사도 계산 (즐겨찾기 아이템과)
      double featureScore = 0;
      if (profile.favoriteItems.isNotEmpty) {
        for (final favId in profile.favoriteItems) {
          final favItem = _items[favId];
          if (favItem != null) {
            featureScore += item.cosineSimilarity(favItem);
          }
        }
        featureScore /= profile.favoriteItems.length;
      }

      // 종합 점수
      final score = categoryScore * 0.6 + featureScore * 0.4;

      if (score > 0.3) { // 임계값
        results.add(RecommendationResult(
          item: item,
          score: score,
          reason: '취향과 유사한 ${item.categories.first} 게임',
          algorithm: RecommendationAlgorithm.contentBased,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  // ============================================
  // 협업 필터링
  // ============================================

  /// 협업 필터링 추천
  List<RecommendationResult> recommendByCollaborative({
    required String userId,
    String? itemType,
    int limit = 10,
  }) {
    final profile = _userProfiles[userId];
    if (profile == null || profile.itemRatings.isEmpty) {
      return recommendByPopularity(itemType: itemType, limit: limit);
    }

    // 유사 사용자 찾기
    final similarUsers = _findSimilarUsers(userId);

    // 유사 사용자들이 좋아한 아이템 추천
    final recommendations = <String, double>{};

    for (final similarUser in similarUsers) {
      final similarProfile = _userProfiles[similarUser];
      if (similarProfile == null) continue;

      for (final entry in similarProfile.itemRatings.entries) {
        final itemId = entry.key;
        final rating = entry.value;

        // 이미 본 아이템 제외
        if (profile.viewedItems.contains(itemId)) continue;
        if (profile.itemRatings.containsKey(itemId)) continue;

        recommendations[itemId] = (recommendations[itemId] ?? 0) + rating;
      }
    }

    // 결과 생성
    final results = recommendations.entries.map((entry) {
      final item = _items[entry.key];
      if (item == null) return null;

      return RecommendationResult(
        item: item,
        score: entry.value / similarUsers.length,
        reason: '비슷한 취향을 가진 유저들이 선호',
        algorithm: RecommendationAlgorithm.collaborative,
      );
    }).whereType<RecommendationResult>().toList();

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// 유사 사용자 찾기 (코사인 유사도)
  List<String> _findSimilarUsers(String userId, {int topK = 10}) {
    final profile = _userProfiles[userId];
    if (profile == null) return [];

    final similarities = <String, double>{};

    for (final otherEntry in _userProfiles.entries) {
      final otherId = otherEntry.key;
      final otherProfile = otherEntry.value;

      if (otherId == userId) continue;

      // 코사인 유사도 계산
      final similarity = _calculateUserSimilarity(profile, otherProfile);
      if (similarity > 0.1) {
        similarities[otherId] = similarity;
      }
    }

    // 상위 K명 반환
    final sorted = similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(topK).map((e) => e.key).toList();
  }

  double _calculateUserSimilarity(UserProfile user1, UserProfile user2) {
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;

    // 공통 평점 아이템
    final commonItems = {...user1.itemRatings.keys, ...user2.itemRatings.keys};

    for (final itemId in commonItems) {
      final rating1 = user1.itemRatings[itemId] ?? 0;
      final rating2 = user2.itemRatings[itemId] ?? 0;

      dotProduct += rating1 * rating2;
      norm1 += rating1 * rating1;
      norm2 += rating2 * rating2;
    }

    return dotProduct / (sqrt(norm1) * sqrt(norm2) + 1e-10);
  }

  // ============================================
  // 인기도 기반 추천
  // ============================================

  List<RecommendationResult> recommendByPopularity({
    String? itemType,
    int limit = 10,
  }) {
    final items = itemType == null
        ? _items.values.toList()
        : _items.values.where((item) => item.type == itemType).toList();

    items.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    return items.take(limit).map((item) =>
      RecommendationResult(
        item: item,
        score: item.popularityScore,
        reason: '많은 유저가 선택',
        algorithm: RecommendationAlgorithm.popularity,
      )
    ).toList();
  }

  // ============================================
  // 하이브리드 추천
  // ============================================

  /// 하이브리드 추천 (여러 알고리즘 결합)
  List<RecommendationResult> recommendHybrid({
    required String userId,
    String? itemType,
    int limit = 10,
    double contentWeight = 0.4,
    double collaborativeWeight = 0.4,
    double popularityWeight = 0.2,
  }) {
    final contentResults = recommendByContent(userId: userId, itemType: itemType);
    final collabResults = recommendByCollaborative(userId: userId, itemType: itemType);
    final popResults = recommendByPopularity(itemType: itemType);

    final combinedScores = <String, _CombinedScore>{};

    // 콘텐츠 기반
    for (final result in contentResults) {
      combinedScores[result.item.id] = _CombinedScore(
        item: result.item,
        contentScore: result.score,
      );
    }

    // 협업 필터링
    for (final result in collabResults) {
      final existing = combinedScores[result.item.id];
      if (existing != null) {
        combinedScores[result.item.id] = existing.copyWith(
          collabScore: result.score,
        );
      } else {
        combinedScores[result.item.id] = _CombinedScore(
          item: result.item,
          collabScore: result.score,
        );
      }
    }

    // 인기도
    for (final result in popResults) {
      final existing = combinedScores[result.item.id];
      if (existing != null) {
        combinedScores[result.item.id] = existing.copyWith(
          popScore: result.score,
        );
      } else {
        combinedScores[result.item.id] = _CombinedScore(
          item: result.item,
          popScore: result.score,
        );
      }
    }

    // 가중 평균 계산
    final results = combinedScores.entries.map((entry) {
      final combined = entry.value;

      final score =
        combined.contentScore * contentWeight +
        combined.collabScore * collaborativeWeight +
        combined.popScore * popularityWeight;

      String reason;
      if (combined.contentScore > combined.collabScore &&
          combined.contentScore > combined.popScore) {
        reason = '취향과 유사';
      } else if (combined.collabScore > combined.popScore) {
        reason = '비슷한 유저들이 선호';
      } else {
        reason = '인기 게임';
      }

      return RecommendationResult(
        item: combined.item,
        score: score,
        reason: reason,
        algorithm: RecommendationAlgorithm.hybrid,
      );
    }).toList();

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  // ============================================
  // 사용자 피드백
  // ============================================

  /// 아이템 조회 기록
  Future<void> recordItemView({
    required String userId,
    required String itemId,
  }) async {
    final profile = _userProfiles[userId];

    if (profile == null) {
      _userProfiles[userId] = UserProfile(
        userId: userId,
        preferences: {},
        itemRatings: {},
        viewedItems: [itemId],
        favoriteItems: [],
      );
    } else {
      final updated = UserProfile(
        userId: userId,
        preferences: profile.preferences,
        itemRatings: profile.itemRatings,
        viewedItems: [...profile.viewedItems, itemId],
        favoriteItems: profile.favoriteItems,
        demographics: profile.demographics,
      );
      _userProfiles[userId] = updated;
    }

    await _saveUserProfiles();
  }

  /// 아이템 평가
  Future<void> rateItem({
    required String userId,
    required String itemId,
    required double rating, // 1.0 - 5.0
  }) async {
    final profile = _userProfiles[userId];

    if (profile == null) return;

    final updatedRatings = Map<String, double>.from(profile.itemRatings);
    updatedRatings[itemId] = rating.clamp(1.0, 5.0);

    _userProfiles[userId] = UserProfile(
      userId: userId,
      preferences: profile.preferences,
      itemRatings: updatedRatings,
      viewedItems: profile.viewedItems,
      favoriteItems: profile.favoriteItems,
      demographics: profile.demographics,
    );

    await _saveUserProfiles();

    // 애널리틱스에 전송
    AnalyticsManager.instance.trackEvent(
      name: 'item_rated',
      category: EventCategory.engagement,
      properties: {
        'user_id': userId,
        'item_id': itemId,
        'rating': rating,
      },
    );
  }

  /// 즐겨찾기 추가
  Future<void> addToFavorites({
    required String userId,
    required String itemId,
  }) async {
    final profile = _userProfiles[userId];

    if (profile == null) return;

    final updatedFavorites = [...profile.favoriteItems, itemId];

    _userProfiles[userId] = UserProfile(
      userId: userId,
      preferences: profile.preferences,
      itemRatings: profile.itemRatings,
      viewedItems: profile.viewedItems,
      favoriteItems: updatedFavorites,
      demographics: profile.demographics,
    );

    // 카테고리 선호도 업데이트
    await _updateCategoryPreferences(userId);

    await _saveUserProfiles();
  }

  /// 카테고리 선호도 업데이트
  Future<void> _updateCategoryPreferences(String userId) async {
    final profile = _userProfiles[userId];
    if (profile == null) return;

    final categoryCounts = <String, int>{};
    final categoryScores = <String, double>{};

    // 즐겨찾기 아이템의 카테고리 집계
    for (final favId in profile.favoriteItems) {
      final item = _items[favId];
      if (item != null) {
        for (final category in item.categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          categoryScores[category] =
            (categoryScores[category] ?? 0) + (profile.itemRatings[favId] ?? 3.0);
        }
      }
    }

    // 정규화
    final maxCount = categoryCounts.values.isEmpty
        ? 1
        : categoryCounts.values.reduce((a, b) => a > b ? a : b);

    final preferences = categoryCounts.map((category, count) =>
      MapEntry(category, count / maxCount));

    _userProfiles[userId] = UserProfile(
      userId: userId,
      preferences: preferences,
      itemRatings: profile.itemRatings,
      viewedItems: profile.viewedItems,
      favoriteItems: profile.favoriteItems,
      demographics: profile.demographics,
    );
  }

  // ============================================
  // 추천 가져오기
  // ============================================

  /// 개인화된 추천 가져오기
  Future<List<RecommendationResult>> getRecommendations({
    required String userId,
    String? itemType,
    int limit = 10,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 하이브리드 추천 사용
    final recommendations = recommendHybrid(
      userId: userId,
      itemType: itemType,
      limit: limit,
    );

    _recommendationController.add(recommendations);

    // 애널리틱스에 전송
    AnalyticsManager.instance.trackEvent(
      name: 'recommendations_shown',
      category: EventCategory.engagement,
      properties: {
        'user_id': userId,
        'item_type': itemType,
        'count': recommendations.length,
      },
    );

    return recommendations;
  }

  // ============================================
  // A/B 테스트 통합
  // ============================================

  /// 추천 알고리즘 A/B 테스트
  Future<List<RecommendationResult>> getRecommendationsForExperiment({
    required String userId,
    required String experimentVariant,
    String? itemType,
    int limit = 10,
  }) async {
    switch (experimentVariant) {
      case 'content_based':
        return recommendByContent(userId: userId, itemType: itemType, limit: limit);
      case 'collaborative':
        return recommendByCollaborative(userId: userId, itemType: itemType, limit: limit);
      case 'popularity':
        return recommendByPopularity(itemType: itemType, limit: limit);
      case 'hybrid':
      default:
        return recommendHybrid(userId: userId, itemType: itemType, limit: limit);
    }
  }

  // ============================================
  // 저장/로드
  // ============================================

  Future<void> _saveUserProfiles() async {
    final json = _userProfiles.map((userId, profile) =>
      MapEntry(userId, jsonEncode({
        'userId': profile.userId,
        'preferences': profile.preferences,
        'itemRatings': profile.itemRatings,
        'viewedItems': profile.viewedItems,
        'favoriteItems': profile.favoriteItems,
        'demographics': profile.demographics,
      }))
    );

    await _prefs!.setString('user_profiles', jsonEncode(json));
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _recommendationController.close();
  }

  bool get _isInitialized => _prefs != null;
}

/// 결합 점수
class _CombinedScore {
  final RecommendableItem item;
  final double contentScore;
  final double collabScore;
  final double popScore;

  const _CombinedScore({
    required this.item,
    this.contentScore = 0,
    this.collabScore = 0,
    this.popScore = 0,
  });

  _CombinedScore copyWith({
    double? contentScore,
    double? collabScore,
    double? popScore,
  }) => _CombinedScore(
    item: item,
    contentScore: contentScore ?? this.contentScore,
    collabScore: collabScore ?? this.collabScore,
    popScore: popScore ?? this.popScore,
  );
}

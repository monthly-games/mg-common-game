import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 추천 알고리즘 타입
enum RecommendationAlgorithm {
  collaborative,     // 협업 필터링
  contentBased,      // 콘텐츠 기반
  hybrid,            // 하이브리드
  matrixFactorization, // 행렬 분해
  deepLearning,      // 딥러닝
}

/// 추천 아이템 타입
enum RecommendationItemType {
  game,              // 게임
  item,              // 아이템
  character,         // 캐릭터
  friend,            // 친구
  guild,             // 길드
  quest,             // 퀘스트
  event,             // 이벤트
}

/// 추천 결과
class RecommendationResult {
  final String itemId;
  final String name;
  final RecommendationItemType type;
  final double score;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const RecommendationResult({
    required this.itemId,
    required this.name,
    required this.type,
    required this.score,
    this.reason,
    this.metadata,
  });
}

/// 사용자 행동
class UserAction {
  final String userId;
  final String itemId;
  final String actionType; // view, purchase, play, like, share
  final double rating;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  const UserAction({
    required this.userId,
    required this.itemId,
    required this.actionType,
    required this.rating,
    required this.timestamp,
    this.context,
  });
}

/// 아이템 특성
class ItemFeatures {
  final String itemId;
  final Map<String, double> features;
  final List<String> categories;
  final List<String> tags;

  const ItemFeatures({
    required this.itemId,
    required this.features,
    this.categories = const [],
    this.tags = const [],
  });
}

/// 추천 모델
class RecommendationModel {
  final String id;
  final String name;
  final RecommendationAlgorithm algorithm;
  final Map<String, dynamic> parameters;
  final double accuracy;
  final DateTime? lastTrained;

  const RecommendationModel({
    required this.id,
    required this.name,
    required this.algorithm,
    required this.parameters,
    required this.accuracy,
    this.lastTrained,
  });
}

/// ML 추천 관리자
class MLRecommendationManager {
  static final MLRecommendationManager _instance = MLRecommendationManager._();
  static MLRecommendationManager get instance => _instance;

  MLRecommendationManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<UserAction> _userActions = [];
  final Map<String, ItemFeatures> _itemFeatures = {};
  final Map<String, RecommendationModel> _models = {};

  final StreamController<List<RecommendationResult>> _recommendationController =
      StreamController<List<RecommendationResult>>.broadcast();

  Stream<List<RecommendationResult>> get onRecommendationUpdate =>
      _recommendationController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 아이템 특성 로드
    _loadItemFeatures();

    // 모델 로드
    _loadModels();

    // 사용자 행동 로드
    _loadUserActions();

    debugPrint('[MLRecommendation] Initialized');
  }

  void _loadItemFeatures() {
    // 게임 특성
    _itemFeatures['game_1'] = const ItemFeatures(
      itemId: 'game_1',
      features: {
        'difficulty': 0.5,
        'social': 0.8,
        'competitive': 0.7,
        'strategy': 0.6,
      },
      categories: ['action', 'multiplayer'],
      tags: ['pvp', 'guild_war', 'ranking'],
    );

    // 아이템 특성
    _itemFeatures['item_sword_legendary'] = const ItemFeatures(
      itemId: 'item_sword_legendary',
      features: {
        'power': 0.9,
        'rarity': 1.0,
        'price': 0.8,
        'popularity': 0.7,
      },
      categories: ['weapon', 'legendary'],
      tags: ['sword', 'damage', 'strength'],
    );
  }

  void _loadModels() {
    _models['collaborative'] = RecommendationModel(
      id: 'collaborative',
      name: 'Collaborative Filtering',
      algorithm: RecommendationAlgorithm.collaborative,
      parameters: {
        'neighbors': 50,
        'minCommonItems': 5,
      },
      accuracy: 0.85,
    );

    _models['content_based'] = RecommendationModel(
      id: 'content_based',
      name: 'Content-Based Filtering',
      algorithm: RecommendationAlgorithm.contentBased,
      parameters: {
        'featureWeight': 0.7,
        'categoryWeight': 0.3,
      },
      accuracy: 0.78,
    );
  }

  Future<void> _loadUserActions() async {
    // 시뮬레이션: 사용자 행동 로드
    if (_currentUserId != null) {
      _userActions.addAll([
        UserAction(
          userId: _currentUserId!,
          itemId: 'game_1',
          actionType: 'play',
          rating: 5.0,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        UserAction(
          userId: _currentUserId!,
          itemId: 'item_sword_legendary',
          actionType: 'view',
          rating: 4.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ]);
    }
  }

  /// 추천 요청
  Future<List<RecommendationResult>> getRecommendations({
    required String userId,
    required RecommendationItemType type,
    RecommendationAlgorithm? algorithm,
    int limit = 10,
  }) async {
    final algo = algorithm ?? RecommendationAlgorithm.collaborative;

    List<RecommendationResult> results;

    switch (algo) {
      case RecommendationAlgorithm.collaborative:
        results = await _collaborativeFiltering(userId, type, limit);
        break;
      case RecommendationAlgorithm.contentBased:
        results = await _contentBasedFiltering(userId, type, limit);
        break;
      case RecommendationAlgorithm.hybrid:
        final collab = await _collaborativeFiltering(userId, type, limit);
        final content = await _contentBasedFiltering(userId, type, limit);
        results = _hybridFiltering(collab, content);
        break;
      default:
        results = await _collaborativeFiltering(userId, type, limit);
    }

    _recommendationController.add(results);

    return results;
  }

  /// 협업 필터링
  Future<List<RecommendationResult>> _collaborativeFiltering(
    String userId,
    RecommendationItemType type,
    int limit,
  ) async {
    // 유사 사용자 찾기
    final similarUsers = await _findSimilarUsers(userId);

    // 유사 사용자의 행동 분석
    final recommendations = <RecommendationResult>[];

    for (final similarUser in similarUsers) {
      final userActions = _userActions
          .where((a) => a.userId == similarUser && a.rating >= 4.0)
          .toList();

      for (final action in userActions) {
        // 이미 상호작용한 아이템 제외
        if (_userActions.any((a) =>
            a.userId == userId && a.itemId == action.itemId)) {
          continue;
        }

        // 점수 계산
        final score = _calculateCollaborativeScore(userId, action.itemId);

        recommendations.add(RecommendationResult(
          itemId: action.itemId,
          name: _getItemName(action.itemId),
          type: type,
          score: score,
          reason: '비슷한 플레이어가 선호합니다',
        ));
      }
    }

    // 점수순 정렬 및 제한
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  /// 콘텐츠 기반 필터링
  Future<List<RecommendationResult>> _contentBasedFiltering(
    String userId,
    RecommendationItemType type,
    int limit,
  ) async {
    // 사용자 프로필 구축
    final userProfile = await _buildUserProfile(userId);

    final recommendations = <RecommendationResult>[];

    for (final entry in _itemFeatures.entries) {
      final itemId = entry.key;
      final features = entry.value;

      // 이미 상호작용한 아이템 제외
      if (_userActions.any((a) =>
          a.userId == userId && a.itemId == itemId)) {
        continue;
      }

      // 유사도 계산
      final similarity = _calculateCosineSimilarity(userProfile, features);

      if (similarity > 0.5) {
        recommendations.add(RecommendationResult(
          itemId: itemId,
          name: _getItemName(itemId),
          type: type,
          score: similarity,
          reason: '당신의 취향과 비슷합니다',
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  /// 하이브리드 필터링
  List<RecommendationResult> _hybridFiltering(
    List<RecommendationResult> collab,
    List<RecommendationResult> content,
  ) {
    final combined = <String, RecommendationResult>{};

    // 협업 필터링 결과 추가
    for (final result in collab) {
      combined[result.itemId] = result.copyWith(
        score: result.score * 0.6,
      );
    }

    // 콘텐츠 기반 결과 병합
    for (final result in content) {
      final existing = combined[result.itemId];
      if (existing != null) {
        combined[result.itemId] = RecommendationResult(
          itemId: result.itemId,
          name: result.name,
          type: result.type,
          score: existing.score + (result.score * 0.4),
          reason: result.reason,
        );
      } else {
        combined[result.itemId] = result.copyWith(
          score: result.score * 0.4,
        );
      }
    }

    final results = combined.values.toList();
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// 유사 사용자 찾기
  Future<List<String>> _findSimilarUsers(String userId) async {
    // 코사인 유사도 계산
    final userActions = _userActions
        .where((a) => a.userId == userId)
        .map((a) => a.itemId)
        .toSet();

    final similarities = <String, double>{};

    for (final action in _userActions) {
      if (action.userId == userId) continue;

      final otherUserActions = _userActions
          .where((a) => a.userId == action.userId)
          .map((a) => a.itemId)
          .toSet();

      // 공통 아이템
      final commonItems = userActions.intersection(otherUserActions);

      if (commonItems.isNotEmpty) {
        final similarity = commonItems.length /
            (userActions.length + otherUserActions.length - commonItems.length);

        similarities[action.userId] = similarity;
      }
    }

    // 상위 N명 반환
    final sorted = similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(10)
        .map((e) => e.key)
        .toList();
  }

  /// 협업 필터링 점수 계산
  double _calculateCollaborativeScore(String userId, String itemId) {
    // 간단한 예측: 유사 사용자의 평균 평점
    final itemActions = _userActions
        .where((a) => a.itemId == itemId)
        .toList();

    if (itemActions.isEmpty) return 0.0;

    return itemActions.map((a) => a.rating).reduce((a, b) => a + b) / itemActions.length;
  }

  /// 사용자 프로필 구축
  Future<Map<String, double>> _buildUserProfile(String userId) async {
    final profile = <String, double>{};

    final userActions = _userActions
        .where((a) => a.userId == userId)
        .toList();

    for (final action in userActions) {
      final features = _itemFeatures[action.itemId];
      if (features != null) {
        features.features.forEach((key, value) {
          profile[key] = (profile[key] ?? 0.0) + (value * action.rating);
        });
      }
    }

    // 정규화
    final maxVal = profile.values.reduce((a, b) => a > b ? a : b);
    if (maxVal > 0) {
      profile.forEach((key, value) {
        profile[key] = value / maxVal;
      });
    }

    return profile;
  }

  /// 코사인 유사도 계산
  double _calculateCosineSimilarity(
    Map<String, double> profile,
    ItemFeatures features,
  ) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    features.features.forEach((key, value) {
      final profileValue = profile[key] ?? 0.0;
      dotProduct += profileValue * value;
      normA += profileValue * profileValue;
      normB += value * value;
    });

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// 행동 기록
  Future<void> trackAction({
    required String userId,
    required String itemId,
    required String actionType,
    double rating = 0.0,
    Map<String, dynamic>? context,
  }) async {
    final action = UserAction(
      userId: userId,
      itemId: itemId,
      actionType: actionType,
      rating: rating,
      timestamp: DateTime.now(),
      context: context,
    );

    _userActions.add(action);

    // 저장
    await _saveUserAction(action);

    debugPrint('[MLRecommendation] Action tracked: $actionType - $itemId');
  }

  /// 아이템 특성 추가
  void addItemFeatures(ItemFeatures features) {
    _itemFeatures[features.itemId] = features;

    debugPrint('[MLRecommendation] Item features added: ${features.itemId}');
  }

  /// 모델 학습
  Future<void> trainModel({
    required String modelId,
    required List<UserAction> trainingData,
  }) async {
    final model = _models[modelId];
    if (model == null) return;

    // 모델 학습 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 5));

    final updated = RecommendationModel(
      id: model.id,
      name: model.name,
      algorithm: model.algorithm,
      parameters: model.parameters,
      accuracy: model.accuracy + 0.05, // 정확도 향상
      lastTrained: DateTime.now(),
    );

    _models[modelId] = updated;

    debugPrint('[MLRecommendation] Model trained: $modelId');
  }

  /// 추천 A/B 테스트
  Future<Map<String, List<RecommendationResult>>> testRecommendations({
    required String userId,
    required RecommendationItemType type,
    required List<RecommendationAlgorithm> algorithms,
  }) async {
    final results = <String, List<RecommendationResult>>{};

    for (final algo in algorithms) {
      final recs = await getRecommendations(
        userId: userId,
        type: type,
        algorithm: algo,
      );

      results[algo.name] = recs;
    }

    return results;
  }

  /// 모델 성능 평가
  Future<Map<String, dynamic>> evaluateModel({
    required String modelId,
    required List<UserAction> testData,
  }) async {
    final model = _models[modelId];
    if (model == null) throw Exception('Model not found');

    // RMSE 계산 (시뮬레이션)
    final predictions = <double>[];
    final actual = <double>[];

    for (final action in testData) {
      final prediction = await _predictRating(action.userId, action.itemId);
      if (prediction != null) {
        predictions.add(prediction);
        actual.add(action.rating);
      }
    }

    double rmse = 0.0;
    if (predictions.isNotEmpty) {
      final sumSquaredError = predictions.asMap().entries.fold<double>(
          0.0,
          (sum, entry) {
            final error = entry.value - actual[entry.key];
            return sum + (error * error);
          });

      rmse = sqrt(sumSquaredError / predictions.length);
    }

    return {
      'modelId': modelId,
      'accuracy': model.accuracy,
      'rmse': rmse,
      'predictions': predictions.length,
    };
  }

  /// 평점 예측
  Future<double?> _predictRating(String userId, String itemId) async {
    // 간단한 예측: 협업 필터링 기반
    final score = _calculateCollaborativeScore(userId, itemId);

    return score > 0 ? score * 5.0 : null; // 0-5 스케일
  }

  /// 개인화된 랭킹
  Future<List<RecommendationResult>> getPersonalizedRanking({
    required String userId,
    required List<String> itemIds,
  }) async {
    final userProfile = await _buildUserProfile(userId);

    final rankings = <RecommendationResult>[];

    for (final itemId in itemIds) {
      final features = _itemFeatures[itemId];
      if (features == null) continue;

      final score = _calculateCosineSimilarity(userProfile, features);

      rankings.add(RecommendationResult(
        itemId: itemId,
        name: _getItemName(itemId),
        type: RecommendationItemType.item,
        score: score,
      ));
    }

    rankings.sort((a, b) => b.score.compareTo(a.score));

    return rankings;
  }

  /// 추천 설명 가능성
  String explainRecommendation(RecommendationResult result) {
    return result.reason ?? '추천 이유: ${result.score.toStringAsFixed(2)}점';
  }

  String _getItemName(String itemId) {
    // 실제로는 아이템 데이터베이스에서 조회
    return itemId.replaceAll('_', ' ').split(' ').map((word) =>
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Future<void> _saveUserAction(UserAction action) async {
    await _prefs?.setString(
      'action_${action.userId}_${action.timestamp.millisecondsSinceEpoch}',
      jsonEncode({
        'userId': action.userId,
        'itemId': action.itemId,
        'actionType': action.actionType,
        'rating': action.rating,
        'timestamp': action.timestamp.toIso8601String(),
      }),
    );
  }

  /// 콜드 스타트 해결
  List<String> getColdStartRecommendations({
    required RecommendationItemType type,
    int limit = 10,
  }) {
    // 인기 아이템 추천
    final popularItems = _itemFeatures.keys.take(limit).toList();

    return popularItems;
  }

  void dispose() {
    _recommendationController.close();
  }
}

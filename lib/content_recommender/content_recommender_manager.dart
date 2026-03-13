import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 콘텐츠 타입
enum ContentType {
  quest,          // 퀘스트
  event,          // 이벤트
  achievement,    // 업적
  item,           // 아이템
  dungeon,        // 던전
  pvp,            // PvP
  raid,           // 레이드
  collection,     // 수집품
  story,          // 스토리
  miniGame,       // 미니게임
}

/// 추천 이유
enum RecommendationReason {
  popular,             // 인기
  similarUsers,        // 비슷한 유저가 선호
  continuedProgress,   // 진행 중인 콘텐츠
  newContent,          // 신규 콘텐츠
  challenge,           // 도전 과제
  socialTrending,      // 소셜 트렌드
  timeLimited,         // 한정 시간
  personalized,        // 개인화된 추천
  difficultyMatch,     // 난이도 매치
  rewardFocus,         // 보상 기반
}

/// 플레이어 선호도
class PlayerPreferences {
  final String userId;
  final Map<ContentType, double> contentAffinity; // 콘텐츠 선호도
  final Map<String, double> itemAffinity; // 아이템 선호도
  final double difficultyPreference; // 0.0 (쉬움) - 1.0 (어려움)
  final double socialPreference; // 0.0 - 1.0 (소셜 선호)
  final double competitionPreference; // 0.0 - 1.0 (경쟁 선호)
  final double explorationPreference; // 0.0 - 1.0 (탐험 선호)
  final DateTime lastUpdated;

  const PlayerPreferences({
    required this.userId,
    required this.contentAffinity,
    required this.itemAffinity,
    required this.difficultyPreference,
    required this.socialPreference,
    required this.competitionPreference,
    required this.explorationPreference,
    required this.lastUpdated,
  });

  PlayerPreferences copyWith({
    String? userId,
    Map<ContentType, double>? contentAffinity,
    Map<String, double>? itemAffinity,
    double? difficultyPreference,
    double? socialPreference,
    double? competitionPreference,
    double? explorationPreference,
    DateTime? lastUpdated,
  }) {
    return PlayerPreferences(
      userId: userId ?? this.userId,
      contentAffinity: contentAffinity ?? this.contentAffinity,
      itemAffinity: itemAffinity ?? this.itemAffinity,
      difficultyPreference: difficultyPreference ?? this.difficultyPreference,
      socialPreference: socialPreference ?? this.socialPreference,
      competitionPreference: competitionPreference ?? this.competitionPreference,
      explorationPreference: explorationPreference ?? this.explorationPreference,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 추천 콘텐츠
class RecommendedContent {
  final String contentId;
  final String name;
  final String description;
  final ContentType type;
  final double score; // 0.0 - 1.0
  final RecommendationReason reason;
  final Map<String, dynamic> metadata;
  final DateTime? expiresAt;
  final int? priority;

  const RecommendedContent({
    required this.contentId,
    required this.name,
    required this.description,
    required this.type,
    required this.score,
    required this.reason,
    required this.metadata,
    this.expiresAt,
    this.priority,
  });
}

/// 콘텐츠 아이템
class ContentItem {
  final String id;
  final String name;
  final String description;
  final ContentType type;
  final int level;
  final double difficulty; // 0.0 - 1.0
  final List<String> tags;
  final Map<String, dynamic> rewards;
  final int? timeLimit; // minutes
  final int maxParticipants;
  final DateTime? availableUntil;
  final double popularityScore; // 0.0 - 1.0

  const ContentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.level,
    required this.difficulty,
    required this.tags,
    required this.rewards,
    this.timeLimit,
    this.maxParticipants = 1,
    this.availableUntil,
    required this.popularityScore,
  });
}

/// 사용자 행동
class UserBehavior {
  final String userId;
  final String contentId;
  final ContentType contentType;
  final String action; // view, start, complete, abandon, like
  final double duration; // minutes
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const UserBehavior({
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.action,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

/// 추천 결과
class RecommendationResult {
  final String userId;
  final List<RecommendedContent> recommendations;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;
  final int cacheDuration; // seconds

  const RecommendationResult({
    required this.userId,
    required this.recommendations,
    required this.generatedAt,
    required this.metadata,
    this.cacheDuration = 300, // 5 minutes
  });

  /// 만료 여부
  bool get isExpired =>
      DateTime.now().difference(generatedAt).inSeconds > cacheDuration;
}

/// 콘텐츠 추천 관리자
class ContentRecommenderManager {
  static final ContentRecommenderManager _instance =
      ContentRecommenderManager._();
  static ContentRecommenderManager get instance => _instance;

  ContentRecommenderManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, ContentItem> _contentCatalog = {};
  final Map<String, PlayerPreferences> _playerPreferences = {};
  final List<UserBehavior> _behaviorHistory = [];
  final Map<String, List<UserBehavior>> _userBehaviors = {};

  final StreamController<RecommendedContent> _recommendationController =
      StreamController<RecommendedContent>.broadcast();
  final StreamController<PlayerPreferences> _preferenceController =
      StreamController<PlayerPreferences>.broadcast();

  Stream<RecommendedContent> get onRecommendation =>
      _recommendationController.stream;
  Stream<PlayerPreferences> get onPreferenceUpdate =>
      _preferenceController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 콘텐츠 카탈로그 로드
    _loadContentCatalog();

    // 사용자 행동 로드
    await _loadUserBehaviors();

    // 정기 분석 시작
    _startPeriodicAnalysis();

    debugPrint('[ContentRecommender] Initialized');
  }

  void _loadContentCatalog() {
    // 퀘스트
    _contentCatalog['quest_1'] = const ContentItem(
      id: 'quest_1',
      name: '용사의 여정',
      description: '첫 번째 퀘스트',
      type: ContentType.quest,
      level: 1,
      difficulty: 0.2,
      tags: ['스토리', '초보자'],
      rewards: {'gold': 100, 'exp': 50},
      popularityScore: 0.9,
    );

    // 이벤트
    _contentCatalog['event_1'] = const ContentItem(
      id: 'event_1',
      name: '한겨울 축제',
      description: '한정된 겨울 이벤트',
      type: ContentType.event,
      level: 20,
      difficulty: 0.5,
      tags: ['시즌', '보너스'],
      rewards: {'event_currency': 500},
      timeLimit: 30,
      popularityScore: 0.95,
    );

    // 던전
    _contentCatalog['dungeon_1'] = const ContentItem(
      id: 'dungeon_1',
      name: '고대 유적',
      description: '고대의 비밀이 숨겨진 던전',
      type: ContentType.dungeon,
      level: 30,
      difficulty: 0.6,
      tags: ['파티', '보스'],
      rewards: {'legendary_shard': 1},
      maxParticipants: 4,
      popularityScore: 0.85,
    );

    // PvP
    _contentCatalog['pvp_1'] = const ContentItem(
      id: 'pvp_1',
      name: '랭크 배틀',
      description: '다른 플레이어와 대전',
      type: ContentType.pvp,
      level: 10,
      difficulty: 0.7,
      tags: ['경쟁', '랭크'],
      rewards: {'rank_points': 20},
      popularityScore: 0.88,
    );

    // 업적
    _contentCatalog['achievement_1'] = const ContentItem(
      id: 'achievement_1',
      name: '첫 보스 토벌',
      description: '첫 보스를 처치',
      type: ContentType.achievement,
      level: 1,
      difficulty: 0.4,
      tags: ['업적', '보스'],
      rewards: {'title': '보스 헌터'},
      popularityScore: 0.92,
    );
  }

  Future<void> _loadUserBehaviors() async {
    if (_currentUserId != null) {
      // 기본 행동 생성
      _userBehaviors[_currentUserId!] = [];
    }
  }

  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _updateAllPreferences();
    });
  }

  /// 행동 추적
  Future<void> trackBehavior({
    required String userId,
    required String contentId,
    required ContentType contentType,
    required String action,
    double duration = 0.0,
    Map<String, dynamic>? metadata,
  }) async {
    final behavior = UserBehavior(
      userId: userId,
      contentId: contentId,
      contentType: contentType,
      action: action,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _behaviorHistory.add(behavior);
    _userBehaviors.putIfAbsent(userId, () => []).add(behavior);

    // 최대 1000개만 유지
    if (_behaviorHistory.length > 1000) {
      _behaviorHistory.removeRange(0, _behaviorHistory.length - 1000);
    }

    final behaviors = _userBehaviors[userId]!;
    if (behaviors.length > 1000) {
      behaviors.removeRange(0, behaviors.length - 1000);
    }

    debugPrint('[ContentRecommender] Behavior tracked: $userId - $action');
  }

  /// 추천 생성
  Future<RecommendationResult> getRecommendations({
    required String userId,
    int limit = 10,
    List<ContentType>? contentTypes,
  }) async {
    final preferences = _playerPreferences[userId];
    final behaviors = _userBehaviors[userId] ?? [];

    final recommendations = <RecommendedContent>[];

    // 인기 콘텐츠 추천
    recommendations.addAll(_getPopularContent(userId, limit ~/ 3));

    // 개인화 추천
    if (preferences != null) {
      recommendations.addAll(
        _getPersonalizedContent(userId, preferences, limit ~/ 3),
      );
    }

    // 진행 중인 콘텐츠 추천
    recommendations.addAll(_getContinuedContent(userId, behaviors, limit ~/ 3));

    // 점수순 정렬
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    // 필터링
    var filtered = recommendations;
    if (contentTypes != null && contentTypes.isNotEmpty) {
      filtered = recommendations
          .where((r) => contentTypes.contains(r.type))
          .toList();
    }

    // 제한
    final limited = filtered.take(limit).toList();

    final result = RecommendationResult(
      userId: userId,
      recommendations: limited,
      generatedAt: DateTime.now(),
      metadata: {
        'total_candidates': recommendations.length,
        'filtered_count': filtered.length,
        'content_types': contentTypes?.map((t) => t.name).toList(),
      },
    );

    // 추천 알림
    for (final rec in limited.take(3)) {
      _recommendationController.add(rec);
    }

    return result;
  }

  /// 인기 콘텐츠
  List<RecommendedContent> _getPopularContent(
    String userId,
    int limit,
  ) {
    final popular = _contentCatalog.values.toList()
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    return popular.take(limit).map((content) {
      return RecommendedContent(
        contentId: content.id,
        name: content.name,
        description: content.description,
        type: content.type,
        score: content.popularityScore * 0.8,
        reason: RecommendationReason.popular,
        metadata: {
          'popularity_score': content.popularityScore,
          'level': content.level,
        },
        expiresAt: content.availableUntil,
        priority: 1,
      );
    }).toList();
  }

  /// 개인화 콘텐츠
  List<RecommendedContent> _getPersonalizedContent(
    String userId,
    PlayerPreferences preferences,
    int limit,
  ) {
    final candidates = <RecommendedContent>[];

    for (final content in _contentCatalog.values) {
      // 콘텐츠 선호도 계산
      final affinityScore =
          preferences.contentAffinity[content.type] ?? 0.5;

      // 난이도 매치
      final difficultyMatch =
          1.0 - (content.difficulty - preferences.difficultyPreference).abs();

      // 태그 매치
      final tagMatch = _calculateTagMatch(content.tags, preferences);

      // 최종 점수
      final score = (affinityScore * 0.4) +
          (difficultyMatch * 0.3) +
          (tagMatch * 0.2) +
          (content.popularityScore * 0.1);

      candidates.add(RecommendedContent(
        contentId: content.id,
        name: content.name,
        description: content.description,
        type: content.type,
        score: score.clamp(0.0, 1.0),
        reason: RecommendationReason.personalized,
        metadata: {
          'affinity_score': affinityScore,
          'difficulty_match': difficultyMatch,
          'tag_match': tagMatch,
        },
        expiresAt: content.availableUntil,
        priority: 2,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(limit).toList();
  }

  /// 진행 중인 콘텐츠
  List<RecommendedContent> _getContinuedContent(
    String userId,
    List<UserBehavior> behaviors,
    int limit,
  ) {
    // 최근 시작했지만 완료하지 않은 콘텐츠
    final started =
        behaviors.where((b) => b.action == 'start').toList();
    final completed =
        behaviors.where((b) => b.action == 'complete').map((b) => b.contentId).toSet();

    final inProgress = started
        .where((b) => !completed.contains(b.contentId))
        .map((b) => b.contentId)
        .toSet();

    final recommendations = <RecommendedContent>[];

    for (final contentId in inProgress) {
      final content = _contentCatalog[contentId];
      if (content == null) continue;

      recommendations.add(RecommendedContent(
        contentId: content.id,
        name: content.name,
        description: content.description,
        type: content.type,
        score: 0.85, // 진행 중인 콘텐츠 우선
        reason: RecommendationReason.continuedProgress,
        metadata: {
          'last_action': 'started',
          'urgency': 'high',
        },
        priority: 3,
      ));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  /// 태그 매치 계산
  double _calculateTagMatch(
    List<String> tags,
    PlayerPreferences preferences,
  ) {
    if (tags.isEmpty) return 0.5;

    // 사용자의 행동에서 선호 태그 추출
    final behaviors = _userBehaviors[preferences.userId] ?? [];
    final preferredTags = <String>{};

    for (final behavior in behaviors) {
      final content = _contentCatalog[behavior.contentId];
      if (content != null) {
        preferredTags.addAll(content.tags);
      }
    }

    if (preferredTags.isEmpty) return 0.5;

    // 태그 오버랩 계산
    final overlap = tags.where((tag) => preferredTags.contains(tag)).length;
    return overlap / tags.length;
  }

  /// 선호도 업데이트
  Future<void> _updateAllPreferences() async {
    for (final userId in _userBehaviors.keys) {
      await _updateUserPreferences(userId);
    }
  }

  Future<PlayerPreferences> _updateUserPreferences(String userId) async {
    final behaviors = _userBehaviors[userId] ?? [];
    if (behaviors.isEmpty) return _getDefaultPreferences(userId);

    // 콘텐츠 타입 선호도 계산
    final contentAffinity = <ContentType, double>{};
    final typeActions = <ContentType, List<String>>{};

    for (final behavior in behaviors) {
      typeActions.putIfAbsent(behavior.contentType, () => [])
          .add(behavior.action);
    }

    for (final entry in typeActions.entries) {
      final actions = entry.value;
      final positiveCount =
          actions.where((a) => ['complete', 'like'].contains(a)).length;
      final negativeCount =
          actions.where((a) => ['abandon'].contains(a)).length;
      final total = actions.length;

      final affinity = total > 0
          ? (positiveCount - negativeCount) / total
          : 0.5;
      contentAffinity[entry.key] = affinity.clamp(0.0, 1.0);
    }

    // 기본 선호도 설정
    for (final type in ContentType.values) {
      contentAffinity.putIfAbsent(type, () => 0.5);
    }

    // 난이도 선호도 계산
    final difficultyScores = <double>[];
    for (final behavior in behaviors) {
      final content = _contentCatalog[behavior.contentId];
      if (content != null && behavior.action == 'complete') {
        difficultyScores.add(content.difficulty);
      }
    }

    final avgDifficulty = difficultyScores.isNotEmpty
        ? difficultyScores.reduce((a, b) => a + b) / difficultyScores.length
        : 0.5;

    // 소셜 선호도 계산
    final socialActions = behaviors.where((b) =>
        b.metadata?['party_size'] != null ||
        ['raid', 'dungeon', 'pvp'].contains(b.contentType.name)).length;
    final socialPreference = behaviors.isNotEmpty
        ? socialActions / behaviors.length
        : 0.5;

    // 경쟁 선호도 계산
    final competitiveActions = behaviors
        .where((b) => b.contentType == ContentType.pvp)
        .where((b) => b.action == 'complete')
        .length;
    final competitionPreference = behaviors.isNotEmpty
        ? competitiveActions / behaviors.length
        : 0.5;

    // 탐험 선호도 계산
    final explorationActions = behaviors
        .where((b) => b.contentType == ContentType.quest ||
                    b.contentType == ContentType.dungeon)
        .where((b) => b.action == 'complete')
        .length;
    final explorationPreference = behaviors.isNotEmpty
        ? explorationActions / behaviors.length
        : 0.5;

    final preferences = PlayerPreferences(
      userId: userId,
      contentAffinity: contentAffinity,
      itemAffinity: {}, // 아이템 선호도는 별도 계산
      difficultyPreference: avgDifficulty.clamp(0.0, 1.0),
      socialPreference: socialPreference.clamp(0.0, 1.0),
      competitionPreference: competitionPreference.clamp(0.0, 1.0),
      explorationPreference: explorationPreference.clamp(0.0, 1.0),
      lastUpdated: DateTime.now(),
    );

    _playerPreferences[userId] = preferences;
    _preferenceController.add(preferences);

    debugPrint('[ContentRecommender] Preferences updated: $userId');

    return preferences;
  }

  PlayerPreferences _getDefaultPreferences(String userId) {
    return PlayerPreferences(
      userId: userId,
      contentAffinity: Map.fromEntries(
        ContentType.values.map((t) => MapEntry(t, 0.5)),
      ),
      itemAffinity: {},
      difficultyPreference: 0.5,
      socialPreference: 0.5,
      competitionPreference: 0.5,
      explorationPreference: 0.5,
      lastUpdated: DateTime.now(),
    );
  }

  /// 실시간 추천
  Future<RecommendedContent?> getRealtimeRecommendation({
    required String userId,
    required String currentContentId,
  }) async {
    final currentContent = _contentCatalog[currentContentId];
    if (currentContent == null) return null;

    // 현재 콘텐츠와 유사한 콘텐츠 찾기
    final similar = _contentCatalog.values
        .where((c) =>
            c.id != currentContentId &&
            c.tags.any((tag) => currentContent.tags.contains(tag)))
        .toList()
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    if (similar.isEmpty) return null;

    final next = similar.first;
    return RecommendedContent(
      contentId: next.id,
      name: next.name,
      description: next.description,
      type: next.type,
      score: next.popularityScore * 0.9,
      reason: RecommendationReason.similarUsers,
      metadata: {
        'similar_to': currentContentId,
        'shared_tags': next.tags
            .where((tag) => currentContent.tags.contains(tag))
            .toList(),
      },
      priority: 4,
    );
  }

  /// 추천 피드백
  Future<void> submitFeedback({
    required String userId,
    required String contentId,
    required bool isHelpful,
    String? reason,
  }) async {
    debugPrint('[ContentRecommender] Feedback: $userId - $contentId - $isHelpful');

    // 피드백을 통해 선호도 업데이트
    if (isHelpful) {
      await _updateUserPreferences(userId);
    }
  }

  /// A/B 테스트 추천
  Future<RecommendationResult> getABTestRecommendations({
    required String userId,
    required String experimentId,
    required String variant,
    int limit = 10,
  }) async {
    final baseResult = await getRecommendations(userId: userId, limit: limit);

    // 변형별 로직
    final modified = baseResult.recommendations.map((rec) {
      switch (variant) {
        case 'A':
          // 인기도 가중치 증가
          return RecommendedContent(
            contentId: rec.contentId,
            name: rec.name,
            description: rec.description,
            type: rec.type,
            score: rec.score * 1.2,
            reason: rec.reason,
            metadata: {...rec.metadata, 'variant': 'A'},
            expiresAt: rec.expiresAt,
            priority: rec.priority,
          );
        case 'B':
          // 개인화 가중치 증가
          return RecommendedContent(
            contentId: rec.contentId,
            name: rec.name,
            description: rec.description,
            type: rec.type,
            score: rec.reason == RecommendationReason.personalized
                ? rec.score * 1.5
                : rec.score,
            reason: rec.reason,
            metadata: {...rec.metadata, 'variant': 'B'},
            expiresAt: rec.expiresAt,
            priority: rec.priority,
          );
        default:
          return rec;
      }
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return RecommendationResult(
      userId: userId,
      recommendations: modified.take(limit).toList(),
      generatedAt: DateTime.now(),
      metadata: {
        ...baseResult.metadata,
        'experiment_id': experimentId,
        'variant': variant,
      },
    );
  }

  /// 콘텐츠 추가
  void addContent(ContentItem content) {
    _contentCatalog[content.id] = content;
    debugPrint('[ContentRecommender] Content added: ${content.id}');
  }

  /// 콘텐츠 제거
  void removeContent(String contentId) {
    _contentCatalog.remove(contentId);
    debugPrint('[ContentRecommender] Content removed: $contentId');
  }

  /// 사용자 선호도 조회
  PlayerPreferences? getUserPreferences(String userId) {
    return _playerPreferences[userId];
  }

  /// 콘텐츠 카탈로그 조회
  List<ContentItem> getContentCatalog({ContentType? type}) {
    var contents = _contentCatalog.values.toList();

    if (type != null) {
      contents = contents.where((c) => c.type == type).toList();
    }

    return contents;
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final typeDistribution = <ContentType, int>{};
    for (final type in ContentType.values) {
      typeDistribution[type] =
          _contentCatalog.values.where((c) => c.type == type).length;
    }

    final avgPopularity = _contentCatalog.values.isEmpty
        ? 0.0
        : _contentCatalog.values
                .map((c) => c.popularityScore)
                .reduce((a, b) => a + b) /
            _contentCatalog.values.length;

    return {
      'totalContent': _contentCatalog.length,
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.name, v)),
      'averagePopularity': avgPopularity,
      'totalBehaviors': _behaviorHistory.length,
      'trackedUsers': _userBehaviors.length,
      'usersWithPreferences': _playerPreferences.length,
    };
  }

  void dispose() {
    _analysisTimer?.cancel();
    _recommendationController.close();
    _preferenceController.close();
  }
}

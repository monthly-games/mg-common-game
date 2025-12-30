/// 리더보드 시스템 타입 정의
///
/// 다양한 리더보드 타입, 스코프, 엔트리 모델 정의
library;

/// 리더보드 시간 범위
enum LeaderboardTimeScope {
  /// 일간
  daily,

  /// 주간
  weekly,

  /// 월간
  monthly,

  /// 전체 기간
  allTime,

  /// 시즌
  seasonal,

  /// 이벤트
  event,
}

/// 리더보드 스코프 (그룹)
enum LeaderboardScope {
  /// 글로벌 (전체 유저)
  global,

  /// 친구만
  friends,

  /// 길드/클랜만
  guild,

  /// 지역별
  regional,

  /// 커스텀 그룹
  custom,
}

/// 점수 정렬 방식
enum ScoreSortOrder {
  /// 높은 점수가 1등
  descending,

  /// 낮은 점수가 1등 (예: 시간 기록)
  ascending,
}

/// 리더보드 설정
class LeaderboardConfig {
  final String id;
  final String name;
  final String? description;
  final LeaderboardTimeScope timeScope;
  final LeaderboardScope scope;
  final ScoreSortOrder sortOrder;
  final int maxEntries;
  final bool allowDuplicateScores;
  final Duration? resetInterval;
  final DateTime? seasonEndDate;

  const LeaderboardConfig({
    required this.id,
    required this.name,
    this.description,
    this.timeScope = LeaderboardTimeScope.allTime,
    this.scope = LeaderboardScope.global,
    this.sortOrder = ScoreSortOrder.descending,
    this.maxEntries = 100,
    this.allowDuplicateScores = true,
    this.resetInterval,
    this.seasonEndDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'timeScope': timeScope.index,
        'scope': scope.index,
        'sortOrder': sortOrder.index,
        'maxEntries': maxEntries,
        'allowDuplicateScores': allowDuplicateScores,
        'resetInterval': resetInterval?.inMilliseconds,
        'seasonEndDate': seasonEndDate?.toIso8601String(),
      };

  factory LeaderboardConfig.fromJson(Map<String, dynamic> json) {
    return LeaderboardConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      timeScope: LeaderboardTimeScope.values[json['timeScope'] as int? ?? 0],
      scope: LeaderboardScope.values[json['scope'] as int? ?? 0],
      sortOrder: ScoreSortOrder.values[json['sortOrder'] as int? ?? 0],
      maxEntries: json['maxEntries'] as int? ?? 100,
      allowDuplicateScores: json['allowDuplicateScores'] as bool? ?? true,
      resetInterval: json['resetInterval'] != null
          ? Duration(milliseconds: json['resetInterval'] as int)
          : null,
      seasonEndDate: json['seasonEndDate'] != null
          ? DateTime.parse(json['seasonEndDate'] as String)
          : null,
    );
  }
}

/// 리더보드 엔트리
class LeaderboardEntry {
  final String odId;
  final String displayName;
  final int score;
  final int rank;
  final String? avatarUrl;
  final DateTime submittedAt;
  final Map<String, dynamic>? metadata;
  final bool isCurrentPlayer;

  const LeaderboardEntry({
    required this.odId,
    required this.displayName,
    required this.score,
    required this.rank,
    this.avatarUrl,
    required this.submittedAt,
    this.metadata,
    this.isCurrentPlayer = false,
  });

  LeaderboardEntry copyWith({
    int? score,
    int? rank,
    String? displayName,
    String? avatarUrl,
    DateTime? submittedAt,
    Map<String, dynamic>? metadata,
    bool? isCurrentPlayer,
  }) {
    return LeaderboardEntry(
      odId: odId,
      displayName: displayName ?? this.displayName,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      metadata: metadata ?? this.metadata,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': odId,
        'displayName': displayName,
        'score': score,
        'rank': rank,
        'avatarUrl': avatarUrl,
        'submittedAt': submittedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json,
      {bool isCurrentPlayer = false}) {
    return LeaderboardEntry(
      odId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? 'Unknown',
      score: json['score'] as int,
      rank: json['rank'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isCurrentPlayer: isCurrentPlayer,
    );
  }

  @override
  String toString() => 'LeaderboardEntry(#$rank $displayName: $score)';
}

/// 리더보드 데이터 (특정 리더보드의 전체 데이터)
class LeaderboardData {
  final String leaderboardId;
  final LeaderboardConfig config;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? currentPlayerEntry;
  final DateTime lastUpdated;
  final int totalPlayers;

  const LeaderboardData({
    required this.leaderboardId,
    required this.config,
    required this.entries,
    this.currentPlayerEntry,
    required this.lastUpdated,
    this.totalPlayers = 0,
  });

  /// 상위 N개 엔트리 가져오기
  List<LeaderboardEntry> getTopEntries(int count) {
    return entries.take(count).toList();
  }

  /// 특정 유저 주변 엔트리 가져오기 (위아래 N명씩)
  List<LeaderboardEntry> getEntriesAroundPlayer(String odId, {int range = 5}) {
    final playerIndex = entries.indexWhere((e) => e.odId == odId);
    if (playerIndex == -1) return [];

    final start = (playerIndex - range).clamp(0, entries.length);
    final end = (playerIndex + range + 1).clamp(0, entries.length);

    return entries.sublist(start, end);
  }

  Map<String, dynamic> toJson() => {
        'leaderboardId': leaderboardId,
        'config': config.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'currentPlayerEntry': currentPlayerEntry?.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'totalPlayers': totalPlayers,
      };

  factory LeaderboardData.fromJson(Map<String, dynamic> json, {String? currentPlayerId}) {
    final config = LeaderboardConfig.fromJson(json['config'] as Map<String, dynamic>);
    return LeaderboardData(
      leaderboardId: json['leaderboardId'] as String,
      config: config,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(
                    e as Map<String, dynamic>,
                    isCurrentPlayer: currentPlayerId != null && e['userId'] == currentPlayerId,
                  ))
              .toList() ??
          [],
      currentPlayerEntry: json['currentPlayerEntry'] != null
          ? LeaderboardEntry.fromJson(
              json['currentPlayerEntry'] as Map<String, dynamic>,
              isCurrentPlayer: true,
            )
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalPlayers: json['totalPlayers'] as int? ?? 0,
    );
  }
}

/// 점수 제출 결과
class ScoreSubmitResult {
  final bool success;
  final int? newRank;
  final int? previousRank;
  final int? rankChange;
  final bool isNewHighScore;
  final bool isNewPersonalBest;
  final String? errorMessage;

  const ScoreSubmitResult({
    required this.success,
    this.newRank,
    this.previousRank,
    this.rankChange,
    this.isNewHighScore = false,
    this.isNewPersonalBest = false,
    this.errorMessage,
  });

  factory ScoreSubmitResult.success({
    required int newRank,
    int? previousRank,
    bool isNewHighScore = false,
    bool isNewPersonalBest = false,
  }) {
    return ScoreSubmitResult(
      success: true,
      newRank: newRank,
      previousRank: previousRank,
      rankChange: previousRank != null ? previousRank - newRank : null,
      isNewHighScore: isNewHighScore,
      isNewPersonalBest: isNewPersonalBest,
    );
  }

  factory ScoreSubmitResult.failure(String errorMessage) {
    return ScoreSubmitResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'newRank': newRank,
        'previousRank': previousRank,
        'rankChange': rankChange,
        'isNewHighScore': isNewHighScore,
        'isNewPersonalBest': isNewPersonalBest,
        'errorMessage': errorMessage,
      };
}

/// 리더보드 보상 티어
class LeaderboardRewardTier {
  final int minRank;
  final int maxRank;
  final Map<String, int> rewards;
  final String? title;
  final String? badgeUrl;

  const LeaderboardRewardTier({
    required this.minRank,
    required this.maxRank,
    required this.rewards,
    this.title,
    this.badgeUrl,
  });

  bool containsRank(int rank) => rank >= minRank && rank <= maxRank;

  Map<String, dynamic> toJson() => {
        'minRank': minRank,
        'maxRank': maxRank,
        'rewards': rewards,
        'title': title,
        'badgeUrl': badgeUrl,
      };

  factory LeaderboardRewardTier.fromJson(Map<String, dynamic> json) {
    return LeaderboardRewardTier(
      minRank: json['minRank'] as int,
      maxRank: json['maxRank'] as int,
      rewards: Map<String, int>.from(json['rewards'] as Map),
      title: json['title'] as String?,
      badgeUrl: json['badgeUrl'] as String?,
    );
  }
}

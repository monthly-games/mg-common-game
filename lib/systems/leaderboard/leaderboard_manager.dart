/// 리더보드 매니저
///
/// 리더보드 데이터 관리, 점수 제출, 순위 조회
library;

import 'package:flutter/foundation.dart';

import 'leaderboard_types.dart';

/// 리더보드 매니저
///
/// 여러 리더보드를 관리하고, 점수 제출 및 순위 조회를 처리
class LeaderboardManager extends ChangeNotifier {
  /// 현재 플레이어 ID
  String? _currentPlayerId;
  String? _currentPlayerName;

  /// 등록된 리더보드 설정
  final Map<String, LeaderboardConfig> _configs = {};

  /// 캐시된 리더보드 데이터
  final Map<String, LeaderboardData> _cache = {};

  /// 로컬 최고 점수 (오프라인 지원용)
  final Map<String, int> _localHighScores = {};

  /// 제출 대기 중인 점수 (오프라인 시)
  final List<_PendingScore> _pendingScores = [];

  /// 콜백 - 백엔드 연동용
  Future<ScoreSubmitResult> Function(String leaderboardId, int score, Map<String, dynamic>? metadata)?
      onSubmitScore;
  Future<LeaderboardData?> Function(String leaderboardId, {int limit, LeaderboardScope? scope})?
      onFetchLeaderboard;
  Future<LeaderboardEntry?> Function(String leaderboardId, String odId)? onFetchPlayerEntry;
  Future<List<LeaderboardEntry>> Function(String leaderboardId, String odId, int range)?
      onFetchEntriesAroundPlayer;

  // ============================================================
  // Getters
  // ============================================================

  /// 현재 플레이어 ID
  String? get currentPlayerId => _currentPlayerId;

  /// 등록된 모든 리더보드 ID
  List<String> get leaderboardIds => _configs.keys.toList();

  /// 대기 중인 점수 제출 수
  int get pendingScoreCount => _pendingScores.length;

  /// 특정 리더보드 설정 가져오기
  LeaderboardConfig? getConfig(String leaderboardId) => _configs[leaderboardId];

  /// 캐시된 리더보드 데이터 가져오기
  LeaderboardData? getCachedData(String leaderboardId) => _cache[leaderboardId];

  /// 로컬 최고 점수 가져오기
  int? getLocalHighScore(String leaderboardId) => _localHighScores[leaderboardId];

  // ============================================================
  // 초기화
  // ============================================================

  /// 플레이어 설정
  void setPlayer(String odId, {String? displayName}) {
    _currentPlayerId = odId;
    _currentPlayerName = displayName;
    notifyListeners();
  }

  /// 리더보드 등록
  void registerLeaderboard(LeaderboardConfig config) {
    _configs[config.id] = config;
    debugPrint('Leaderboard registered: ${config.id} (${config.name})');
  }

  /// 여러 리더보드 한번에 등록
  void registerLeaderboards(List<LeaderboardConfig> configs) {
    for (final config in configs) {
      _configs[config.id] = config;
    }
    debugPrint('${configs.length} leaderboards registered');
  }

  /// 리더보드 등록 해제
  void unregisterLeaderboard(String leaderboardId) {
    _configs.remove(leaderboardId);
    _cache.remove(leaderboardId);
  }

  // ============================================================
  // 점수 제출
  // ============================================================

  /// 점수 제출
  Future<ScoreSubmitResult> submitScore(
    String leaderboardId,
    int score, {
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentPlayerId == null) {
      return ScoreSubmitResult.failure('Player not set');
    }

    final config = _configs[leaderboardId];
    if (config == null) {
      return ScoreSubmitResult.failure('Leaderboard not found: $leaderboardId');
    }

    // 로컬 최고 점수 업데이트
    final previousBest = _localHighScores[leaderboardId];
    bool isNewPersonalBest = false;

    if (config.sortOrder == ScoreSortOrder.descending) {
      if (previousBest == null || score > previousBest) {
        _localHighScores[leaderboardId] = score;
        isNewPersonalBest = true;
      }
    } else {
      if (previousBest == null || score < previousBest) {
        _localHighScores[leaderboardId] = score;
        isNewPersonalBest = true;
      }
    }

    // 백엔드 제출
    if (onSubmitScore != null) {
      try {
        final result = await onSubmitScore!(leaderboardId, score, metadata);

        // 캐시 무효화
        _cache.remove(leaderboardId);

        notifyListeners();
        return ScoreSubmitResult(
          success: result.success,
          newRank: result.newRank,
          previousRank: result.previousRank,
          rankChange: result.rankChange,
          isNewHighScore: result.isNewHighScore,
          isNewPersonalBest: isNewPersonalBest,
          errorMessage: result.errorMessage,
        );
      } catch (e) {
        // 오프라인 - 대기열에 추가
        _pendingScores.add(_PendingScore(
          leaderboardId: leaderboardId,
          score: score,
          metadata: metadata,
          submittedAt: DateTime.now(),
        ));

        debugPrint('Score queued for later submission: $score to $leaderboardId');
        notifyListeners();

        return ScoreSubmitResult(
          success: true,
          isNewPersonalBest: isNewPersonalBest,
          errorMessage: 'Offline - score queued',
        );
      }
    }

    // 콜백 없음 - 로컬 전용 모드
    _updateLocalLeaderboard(leaderboardId, score, metadata);
    notifyListeners();

    return ScoreSubmitResult(
      success: true,
      isNewPersonalBest: isNewPersonalBest,
    );
  }

  /// 대기 중인 점수 모두 제출 (온라인 복귀 시)
  Future<int> submitPendingScores() async {
    if (onSubmitScore == null || _pendingScores.isEmpty) return 0;

    int successCount = 0;
    final toSubmit = List<_PendingScore>.from(_pendingScores);
    _pendingScores.clear();

    for (final pending in toSubmit) {
      try {
        final result = await onSubmitScore!(
          pending.leaderboardId,
          pending.score,
          pending.metadata,
        );
        if (result.success) {
          successCount++;
        } else {
          // 실패 시 다시 대기열에
          _pendingScores.add(pending);
        }
      } catch (e) {
        _pendingScores.add(pending);
      }
    }

    notifyListeners();
    return successCount;
  }

  // ============================================================
  // 리더보드 조회
  // ============================================================

  /// 리더보드 가져오기
  Future<LeaderboardData?> fetchLeaderboard(
    String leaderboardId, {
    int limit = 100,
    LeaderboardScope? scope,
    bool useCache = true,
  }) async {
    // 캐시 사용
    if (useCache && _cache.containsKey(leaderboardId)) {
      final cached = _cache[leaderboardId]!;
      // 5분 이내면 캐시 사용
      if (DateTime.now().difference(cached.lastUpdated).inMinutes < 5) {
        return cached;
      }
    }

    if (onFetchLeaderboard != null) {
      try {
        final data = await onFetchLeaderboard!(leaderboardId, limit: limit, scope: scope);
        if (data != null) {
          _cache[leaderboardId] = data;
          notifyListeners();
          return data;
        }
      } catch (e) {
        debugPrint('Failed to fetch leaderboard: $e');
      }
    }

    // 로컬 데이터 반환
    return _cache[leaderboardId];
  }

  /// 상위 N개 가져오기
  Future<List<LeaderboardEntry>> fetchTopEntries(
    String leaderboardId, {
    int count = 10,
  }) async {
    final data = await fetchLeaderboard(leaderboardId, limit: count);
    return data?.getTopEntries(count) ?? [];
  }

  /// 플레이어 순위 가져오기
  Future<LeaderboardEntry?> fetchPlayerEntry(String leaderboardId) async {
    if (_currentPlayerId == null) return null;

    if (onFetchPlayerEntry != null) {
      try {
        return await onFetchPlayerEntry!(leaderboardId, _currentPlayerId!);
      } catch (e) {
        debugPrint('Failed to fetch player entry: $e');
      }
    }

    // 캐시에서 찾기
    final cached = _cache[leaderboardId];
    if (cached != null) {
      return cached.entries.cast<LeaderboardEntry?>().firstWhere(
            (e) => e?.odId == _currentPlayerId,
            orElse: () => null,
          );
    }

    return null;
  }

  /// 플레이어 주변 순위 가져오기
  Future<List<LeaderboardEntry>> fetchEntriesAroundPlayer(
    String leaderboardId, {
    int range = 5,
  }) async {
    if (_currentPlayerId == null) return [];

    if (onFetchEntriesAroundPlayer != null) {
      try {
        return await onFetchEntriesAroundPlayer!(leaderboardId, _currentPlayerId!, range);
      } catch (e) {
        debugPrint('Failed to fetch entries around player: $e');
      }
    }

    // 캐시에서 찾기
    final cached = _cache[leaderboardId];
    return cached?.getEntriesAroundPlayer(_currentPlayerId!, range: range) ?? [];
  }

  /// 특정 범위 순위 가져오기 (예: 1-10등, 11-20등)
  List<LeaderboardEntry> getEntriesInRange(
    String leaderboardId,
    int startRank,
    int endRank,
  ) {
    final cached = _cache[leaderboardId];
    if (cached == null) return [];

    return cached.entries
        .where((e) => e.rank >= startRank && e.rank <= endRank)
        .toList();
  }

  // ============================================================
  // 로컬 리더보드 (오프라인/테스트용)
  // ============================================================

  void _updateLocalLeaderboard(
    String leaderboardId,
    int score,
    Map<String, dynamic>? metadata,
  ) {
    final config = _configs[leaderboardId];
    if (config == null || _currentPlayerId == null) return;

    final existing = _cache[leaderboardId];
    final entries = List<LeaderboardEntry>.from(existing?.entries ?? []);

    // 기존 엔트리 제거
    entries.removeWhere((e) => e.odId == _currentPlayerId);

    // 새 엔트리 추가
    entries.add(LeaderboardEntry(
      odId: _currentPlayerId!,
      displayName: _currentPlayerName ?? 'Player',
      score: score,
      rank: 0, // 아래에서 재계산
      submittedAt: DateTime.now(),
      metadata: metadata,
      isCurrentPlayer: true,
    ));

    // 정렬
    if (config.sortOrder == ScoreSortOrder.descending) {
      entries.sort((a, b) => b.score.compareTo(a.score));
    } else {
      entries.sort((a, b) => a.score.compareTo(b.score));
    }

    // 순위 부여
    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }

    // 최대 엔트리 수 제한
    final limited = entries.take(config.maxEntries).toList();

    // 현재 플레이어 엔트리 찾기
    final playerEntry = limited.cast<LeaderboardEntry?>().firstWhere(
          (e) => e?.odId == _currentPlayerId,
          orElse: () => null,
        );

    _cache[leaderboardId] = LeaderboardData(
      leaderboardId: leaderboardId,
      config: config,
      entries: limited,
      currentPlayerEntry: playerEntry,
      lastUpdated: DateTime.now(),
      totalPlayers: limited.length,
    );
  }

  /// 로컬 테스트 데이터 추가
  void addTestEntry(String leaderboardId, LeaderboardEntry entry) {
    final config = _configs[leaderboardId];
    if (config == null) return;

    final existing = _cache[leaderboardId];
    final entries = List<LeaderboardEntry>.from(existing?.entries ?? []);

    entries.add(entry);

    // 정렬 및 순위 부여
    if (config.sortOrder == ScoreSortOrder.descending) {
      entries.sort((a, b) => b.score.compareTo(a.score));
    } else {
      entries.sort((a, b) => a.score.compareTo(b.score));
    }

    for (int i = 0; i < entries.length; i++) {
      entries[i] = entries[i].copyWith(rank: i + 1);
    }

    _cache[leaderboardId] = LeaderboardData(
      leaderboardId: leaderboardId,
      config: config,
      entries: entries.take(config.maxEntries).toList(),
      lastUpdated: DateTime.now(),
      totalPlayers: entries.length,
    );

    notifyListeners();
  }

  // ============================================================
  // 보상
  // ============================================================

  /// 순위 기반 보상 티어 찾기
  LeaderboardRewardTier? getRewardTierForRank(
    List<LeaderboardRewardTier> tiers,
    int rank,
  ) {
    for (final tier in tiers) {
      if (tier.containsRank(rank)) {
        return tier;
      }
    }
    return null;
  }

  /// 현재 플레이어의 예상 보상 가져오기
  Future<LeaderboardRewardTier?> getPlayerReward(
    String leaderboardId,
    List<LeaderboardRewardTier> tiers,
  ) async {
    final entry = await fetchPlayerEntry(leaderboardId);
    if (entry == null) return null;

    return getRewardTierForRank(tiers, entry.rank);
  }

  // ============================================================
  // 저장/불러오기
  // ============================================================

  Map<String, dynamic> toJson() => {
        'currentPlayerId': _currentPlayerId,
        'currentPlayerName': _currentPlayerName,
        'localHighScores': _localHighScores,
        'pendingScores': _pendingScores.map((p) => p.toJson()).toList(),
      };

  void fromJson(Map<String, dynamic> json) {
    _currentPlayerId = json['currentPlayerId'] as String?;
    _currentPlayerName = json['currentPlayerName'] as String?;

    _localHighScores.clear();
    if (json['localHighScores'] != null) {
      _localHighScores.addAll(
        Map<String, int>.from(json['localHighScores'] as Map),
      );
    }

    _pendingScores.clear();
    if (json['pendingScores'] != null) {
      for (final p in json['pendingScores'] as List) {
        _pendingScores.add(_PendingScore.fromJson(p as Map<String, dynamic>));
      }
    }

    notifyListeners();
  }

  /// 캐시 클리어
  void clearCache() {
    _cache.clear();
    notifyListeners();
  }

  /// 모든 데이터 클리어
  void clear() {
    _currentPlayerId = null;
    _currentPlayerName = null;
    _configs.clear();
    _cache.clear();
    _localHighScores.clear();
    _pendingScores.clear();
    notifyListeners();
  }
}

/// 대기 중인 점수 제출
class _PendingScore {
  final String leaderboardId;
  final int score;
  final Map<String, dynamic>? metadata;
  final DateTime submittedAt;

  _PendingScore({
    required this.leaderboardId,
    required this.score,
    this.metadata,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'leaderboardId': leaderboardId,
        'score': score,
        'metadata': metadata,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory _PendingScore.fromJson(Map<String, dynamic> json) {
    return _PendingScore(
      leaderboardId: json['leaderboardId'] as String,
      score: json['score'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}

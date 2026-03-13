import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 밸런스 대상 타입
enum BalanceTargetType {
  champion,      // 챔피언/캐릭터
  item,          // 아이템
  skill,         // 스킬
  weapon,        // 무기
  armor,         // 방어구
}

/// 밸런스 메트릭
class BalanceMetric {
  final String targetId;
  final String targetName;
  final BalanceTargetType type;
  final double winRate; // 0.0 - 1.0
  final double pickRate; // 0.0 - 1.0
  final double banRate; // 0.0 - 1.0
  final double avgDamage;
  final double avgKDA;
  final int sampleSize;
  final DateTime lastUpdated;

  const BalanceMetric({
    required this.targetId,
    required this.targetName,
    required this.type,
    required this.winRate,
    required this.pickRate,
    required this.banRate,
    required this.avgDamage,
    required this.avgKDA,
    required this.sampleSize,
    required this.lastUpdated,
  });

  /// 밸런스 상태
  BalanceStatus get status {
    if (winRate > 0.55) return BalanceStatus.overpowered;
    if (winRate < 0.45) return BalanceStatus.underpowered;
    if (pickRate < 0.05) return BalanceStatus.ignored;
    return BalanceStatus.balanced;
  }
}

/// 밸런스 상태
enum BalanceStatus {
  overpowered,   // 너무 강함
  underpowered,  // 너무 약함
  balanced,      // 균형
  ignored,       // 사용률 낮음
}

/// 밸런스 조정 제안
class BalanceSuggestion {
  final String targetId;
  final String targetName;
  final BalanceStatus status;
  final List<BuffNerf> suggestions;
  final double confidence; // 0.0 - 1.0
  final String reason;

  const BalanceSuggestion({
    required this.targetId,
    required this.targetName,
    required this.status,
    required this.suggestions,
    required this.confidence,
    required this.reason,
  });
}

/// 버프/너프
class BuffNerf {
  final String stat; // 스탯 이름
  final double change; // 변경량 (+ 버프, - 너프)
  final String reason;

  const BuffNerf({
    required this.stat,
    required this.change,
    required this.reason,
  });
}

/// 매치 데이터
class MatchData {
  final String matchId;
  final Map<String, int> championPicks;
  final Map<String, int> championBans;
  final Map<String, bool> results; // championId -> isWin
  final Map<String, double> damageDealt;
  final Map<String, double> kda;
  final DateTime timestamp;

  const MatchData({
    required this.matchId,
    required this.championPicks,
    required this.championBans,
    required this.results,
    required this.damageDealt,
    required this.kda,
    required this.timestamp,
  });
}

/// 밸런스 테스트
class BalanceTest {
  final String id;
  final String name;
  final Map<String, double> changes; // targetId -> stat change
  final DateTime startedAt;
  final DateTime? endedAt;
  final BalanceTestStatus status;
  final Map<String, dynamic> results;

  const BalanceTest({
    required this.id,
    required this.name,
    required this.changes,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.results,
  });
}

/// 밸런스 테스트 상태
enum BalanceTestStatus {
  pending,       // 대기 중
  running,       // 진행 중
  completed,     // 완료
  failed,        // 실패
}

/// 게임 밸런스 AI 관리자
class GameBalanceAIManager {
  static final GameBalanceAIManager _instance = GameBalanceAIManager._();
  static GameBalanceAIManager get instance => _instance;

  GameBalanceAIManager._();

  SharedPreferences? _prefs;

  final Map<String, BalanceMetric> _metrics = {};
  final List<MatchData> _matchHistory = [];
  final List<BalanceSuggestion> _suggestions = [];
  final Map<String, BalanceTest> _tests = {};

  final StreamController<BalanceMetric> _metricController =
      StreamController<BalanceMetric>.broadcast();
  final StreamController<BalanceSuggestion> _suggestionController =
      StreamController<BalanceSuggestion>.broadcast();
  final StreamController<BalanceTest> _testController =
      StreamController<BalanceTest>.broadcast();

  Stream<BalanceMetric> get onMetricUpdate => _metricController.stream;
  Stream<BalanceSuggestion> get onSuggestion => _suggestionController.stream;
  Stream<BalanceTest> get onTestUpdate => _testController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // 기본 메트릭 로드
    _loadDefaultMetrics();

    // 분석 타이머 시작
    _startAnalysisTimer();

    debugPrint('[GameBalanceAI] Initialized');
  }

  void _loadDefaultMetrics() {
    // 챔피언 메트릭
    _metrics['champ_1'] = BalanceMetric(
      targetId: 'champ_1',
      targetName: '불의 전사',
      type: BalanceTargetType.champion,
      winRate: 0.52,
      pickRate: 0.15,
      banRate: 0.08,
      avgDamage: 25000,
      avgKDA: 2.5,
      sampleSize: 10000,
      lastUpdated: DateTime.now(),
    );

    _metrics['champ_2'] = BalanceMetric(
      targetId: 'champ_2',
      targetName: '얼음 마법사',
      type: BalanceTargetType.champion,
      winRate: 0.48,
      pickRate: 0.12,
      banRate: 0.05,
      avgDamage: 22000,
      avgKDA: 2.2,
      sampleSize: 9500,
      lastUpdated: DateTime.now(),
    );

    _metrics['item_1'] = BalanceMetric(
      targetId: 'item_1',
      targetName: '죽음의 검',
      type: BalanceTargetType.item,
      winRate: 0.55,
      pickRate: 0.25,
      banRate: 0.0,
      avgDamage: 30000,
      avgKDA: 3.0,
      sampleSize: 15000,
      lastUpdated: DateTime.now(),
    );
  }

  void _startAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _analyzeBalance();
    });
  }

  /// 매치 데이터 추가
  Future<void> addMatchData(MatchData matchData) async {
    _matchHistory.add(matchData);

    // 최대 100,000개만 유지
    if (_matchHistory.length > 100000) {
      _matchHistory.removeRange(0, _matchHistory.length - 100000);
    }

    debugPrint('[GameBalanceAI] Match data added: ${matchData.matchId}');
  }

  /// 밸런스 분석
  Future<void> _analyzeBalance() async {
    debugPrint('[GameBalanceAI] Starting balance analysis...');

    // 각 타겟에 대해 메트릭 계산
    for (final metric in _metrics.values.toList()) {
      final updated = await _calculateMetric(metric.targetId, metric.type);
      _metrics[metric.targetId] = updated;
      _metricController.add(updated);
    }

    // 밸런스 제안 생성
    await _generateSuggestions();

    debugPrint('[GameBalanceAI] Balance analysis completed');
  }

  /// 메트릭 계산
  Future<BalanceMetric> _calculateMetric(
    String targetId,
    BalanceTargetType type,
  ) async {
    // 최근 1000개 매치 분석
    final recentMatches = _matchHistory.take(1000).toList();

    var wins = 0;
    var picks = 0;
    var bans = 0;
    var totalDamage = 0.0;
    var totalKDA = 0.0;
    var damageCount = 0;
    var kdaCount = 0;

    for (final match in recentMatches) {
      // 픽 카운트
      picks += match.championPicks[targetId] ?? 0;
      bans += match.championBans[targetId] ?? 0;

      // 승패
      if (match.results.containsKey(targetId)) {
        if (match.results[targetId] == true) wins++;
      }

      // 데미지
      if (match.damageDealt.containsKey(targetId)) {
        totalDamage += match.damageDealt[targetId]!;
        damageCount++;
      }

      // KDA
      if (match.kda.containsKey(targetId)) {
        totalKDA += match.kda[targetId]!;
        kdaCount++;
      }
    }

    final totalMatches = recentMatches.length;
    final winRate = picks > 0 ? wins / picks : 0.0;
    final pickRate = totalMatches > 0 ? picks / totalMatches : 0.0;
    final banRate = totalMatches > 0 ? bans / totalMatches : 0.0;
    final avgDamage = damageCount > 0 ? totalDamage / damageCount : 0.0;
    final avgKDA = kdaCount > 0 ? totalKDA / kdaCount : 0.0;

    return BalanceMetric(
      targetId: targetId,
      targetName: _metrics[targetId]?.targetName ?? 'Unknown',
      type: type,
      winRate: winRate,
      pickRate: pickRate,
      banRate: banRate,
      avgDamage: avgDamage,
      avgKDA: avgKDA,
      sampleSize: picks,
      lastUpdated: DateTime.now(),
    );
  }

  /// 밸런스 제안 생성
  Future<void> _generateSuggestions() async {
    _suggestions.clear();

    for (final metric in _metrics.values) {
      final suggestion = _createSuggestion(metric);
      if (suggestion != null) {
        _suggestions.add(suggestion);
        _suggestionController.add(suggestion);
      }
    }

    debugPrint('[GameBalanceAI] Generated ${_suggestions.length} suggestions');
  }

  /// 제안 생성
  BalanceSuggestion? _createSuggestion(BalanceMetric metric) {
    switch (metric.status) {
      case BalanceStatus.overpowered:
        return BalanceSuggestion(
          targetId: metric.targetId,
          targetName: metric.targetName,
          status: BalanceStatus.overpowered,
          suggestions: [
            const BuffNerf(
              stat: 'base_damage',
              change: -0.1, // 10% 감소
              reason: '승률이 너무 높음',
            ),
            if (metric.pickRate > 0.2)
              const BuffNerf(
                stat: 'cooldown',
                change: 1.0, // 1초 증가
                reason: '너무 자주 선택됨',
              ),
          ],
          confidence: _calculateConfidence(metric),
          reason: '승률 ${(metric.winRate * 100).toStringAsFixed(1)}%로 기준 초과',
        );

      case BalanceStatus.underpowered:
        return BalanceSuggestion(
          targetId: metric.targetId,
          targetName: metric.targetName,
          status: BalanceStatus.underpowered,
          suggestions: [
            const BuffNerf(
              stat: 'base_damage',
              change: 0.1, // 10% 증가
              reason: '승률이 너무 낮음',
            ),
            if (metric.pickRate < 0.1)
              const BuffNerf(
                stat: 'utility',
                change: 0.15, // 15% 증가
                reason: '선택률 증대 필요',
              ),
          ],
          confidence: _calculateConfidence(metric),
          reason: '승률 ${(metric.winRate * 100).toStringAsFixed(1)}%로 기준 미달',
        );

      case BalanceStatus.ignored:
        return BalanceSuggestion(
          targetId: metric.targetId,
          targetName: metric.targetName,
          status: BalanceStatus.ignored,
          suggestions: [
            const BuffNerf(
              stat: 'base_stats',
              change: 0.2, // 20% 증가
              reason: '선택률이 너무 낮음',
            ),
          ],
          confidence: _calculateConfidence(metric),
          reason: '선택률 ${(metric.pickRate * 100).toStringAsFixed(1)}%로 저조',
        );

      default:
        return null;
    }
  }

  /// 신뢰도 계산
  double _calculateConfidence(BalanceMetric metric) {
    // 샘플 사이즈에 따른 신뢰도
    var confidence = 0.0;
    if (metric.sampleSize >= 10000) {
      confidence = 0.9;
    } else if (metric.sampleSize >= 5000) {
      confidence = 0.7;
    } else if (metric.sampleSize >= 1000) {
      confidence = 0.5;
    } else {
      confidence = 0.3;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// 밸런스 조정 테스트 시작
  Future<BalanceTest> startBalanceTest({
    required String name,
    required Map<String, double> changes,
  }) async {
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final test = BalanceTest(
      id: testId,
      name: name,
      changes: changes,
      startedAt: DateTime.now(),
      status: BalanceTestStatus.pending,
      results: {},
    );

    _tests[testId] = test;
    _testController.add(test);

    // 테스트 시작 (시뮬레이션)
    await Future.delayed(const Duration(seconds: 5));

    final updated = BalanceTest(
      id: testId,
      name: name,
      changes: changes,
      startedAt: test.startedAt,
      endedAt: DateTime.now(),
      status: BalanceTestStatus.running,
      results: {
        'simulated_win_rate': 0.50,
        'simulated_pick_rate': 0.15,
      },
    );

    _tests[testId] = updated;
    _testController.add(updated);

    debugPrint('[GameBalanceAI] Balance test started: $testId');

    return updated;
  }

  /// 밸런스 조정 적용
  Future<void> applyBalanceChanges(String testId) async {
    final test = _tests[testId];
    if (test == null) return;

    for (final entry in test.changes.entries) {
      final metric = _metrics[entry.key];
      if (metric != null) {
        // 실제로는 게임 데이터베이스 업데이트
        debugPrint('[GameBalanceAI] Applied balance change: ${entry.key} -> ${entry.value}');
      }
    }

    debugPrint('[GameBalanceAI] Applied balance changes from test: $testId');
  }

  /// 밸런스 테스트 롤백
  Future<void> rollbackBalanceChanges(String testId) async {
    debugPrint('[GameBalanceAI] Rolled back balance changes from test: $testId');
  }

  /// 시뮬레이션 실행
  Future<Map<String, dynamic>> simulateBalance({
    required String targetId,
    required List<BuffNerf> changes,
  }) async {
    final metric = _metrics[targetId];
    if (metric == null) return {};

    // 시뮬레이션
    var simulatedWinRate = metric.winRate;
    var simulatedPickRate = metric.pickRate;

    for (final change in changes) {
      switch (change.stat) {
        case 'base_damage':
          simulatedWinRate += change.change * 0.3;
          break;
        case 'cooldown':
          simulatedWinRate -= change.change * 0.1;
          break;
        case 'utility':
          simulatedPickRate += change.change * 0.5;
          break;
        default:
          break;
      }
    }

    return {
      'targetId': targetId,
      'currentWinRate': metric.winRate,
      'simulatedWinRate': simulatedWinRate.clamp(0.0, 1.0),
      'currentPickRate': metric.pickRate,
      'simulatedPickRate': simulatedPickRate.clamp(0.0, 1.0),
      'changes': changes.map((c) => c.stat).toList(),
    };
  }

  /// 메트릭 조회
  BalanceMetric? getMetric(String targetId) {
    return _metrics[targetId];
  }

  /// 모든 메트릭
  List<BalanceMetric> getMetrics({BalanceTargetType? type}) {
    var metrics = _metrics.values.toList();

    if (type != null) {
      metrics = metrics.where((m) => m.type == type).toList();
    }

    return metrics..sort((a, b) => b.winRate.compareTo(a.winRate));
  }

  /// 밸런스 제안
  List<BalanceSuggestion> getSuggestions({BalanceStatus? status}) {
    var suggestions = _suggestions.toList();

    if (status != null) {
      suggestions = suggestions.where((s) => s.status == status).toList();
    }

    return suggestions..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// 밸런스 테스트
  List<BalanceTest> getTests({BalanceTestStatus? status}) {
    var tests = _tests.values.toList();

    if (status != null) {
      tests = tests.where((t) => t.status == status).toList();
    }

    return tests..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// 최적 밸런스 계산
  Future<Map<String, double>> calculateOptimalBalance({
    required String targetId,
    double targetWinRate = 0.50,
    double targetPickRate = 0.15,
  }) async {
    final metric = _metrics[targetId];
    if (metric == null) return {};

    final changes = <String, double>{};

    // 승률 조정
    if (metric.winRate < targetWinRate) {
      changes['base_damage'] = (targetWinRate - metric.winRate) * 2.0;
    } else if (metric.winRate > targetWinRate) {
      changes['base_damage'] = (targetWinRate - metric.winRate) * 2.0;
    }

    // 선택률 조정
    if (metric.pickRate < targetPickRate) {
      changes['utility'] = (targetPickRate - metric.pickRate);
    }

    return changes;
  }

  /// 보고서 생성
  Map<String, dynamic> generateReport() {
    final totalTargets = _metrics.length;
    final overpowered = _metrics.values.where((m) => m.status == BalanceStatus.overpowered).length;
    final underpowered = _metrics.values.where((m) => m.status == BalanceStatus.underpowered).length;
    final balanced = _metrics.values.where((m) => m.status == BalanceStatus.balanced).length;
    final ignored = _metrics.values.where((m) => m.status == BalanceStatus.ignored).length;

    return {
      'totalTargets': totalTargets,
      'overpowered': overpowered,
      'underpowered': underpowered,
      'balanced': balanced,
      'ignored': ignored,
      'balanceScore': totalTargets > 0 ? balanced / totalTargets : 0.0,
      'suggestions': _suggestions.length,
      'activeTests': _tests.values.where((t) => t.status == BalanceTestStatus.running).length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveData() async {
    // 메트릭 저장
    for (final metric in _metrics.values) {
      await _prefs?.setString(
        'balance_metric_${metric.targetId}',
        jsonEncode({
          'targetId': metric.targetId,
          'winRate': metric.winRate,
          'pickRate': metric.pickRate,
        }),
      );
    }
  }

  void dispose() {
    _metricController.close();
    _suggestionController.close();
    _testController.close();
    _analysisTimer?.cancel();
  }
}

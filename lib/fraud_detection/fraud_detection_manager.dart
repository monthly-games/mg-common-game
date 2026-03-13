import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사기 타입
enum FraudType {
  accountTheft,       // 계정 도용
  botting,            // 봇 사용
  cheating,           // 치팅
  realMoneyTrading,   // 현금 거래 (RMT)
  exploit,            // 버그 악용
  spamming,           // 스팸
  multiAccounting,    // 다중 계정
  speedHacking,       // 속도 해킹
}

/// 위험 레벨
enum RiskLevel {
  safe,              // 안전 (0-20%)
  low,               // 낮음 (21-40%)
  medium,            // 중간 (41-60%)
  high,              // 높음 (61-80%)
  critical,          // 위험 (81-100%)
}

/// 행동 패턴
class BehaviorPattern {
  final String id;
  final String name;
  final FraudType type;
  final double threshold;
  final int timeWindow;

  const BehaviorPattern({
    required this.id,
    required this.name,
    required this.type,
    required this.threshold,
    required this.timeWindow,
  });
}

/// 사기 이벤트
class FraudEvent {
  final String id;
  final String userId;
  final FraudType type;
  final RiskLevel riskLevel;
  final double confidence;
  final String description;
  final Map<String, dynamic> evidence;
  final DateTime timestamp;

  const FraudEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.riskLevel,
    required this.confidence,
    required this.description,
    required this.evidence,
    required this.timestamp,
  });
}

/// 탐지 규칙
class DetectionRule {
  final String id;
  final String name;
  final FraudType type;
  final bool Function(Map<String, dynamic>) condition;
  final RiskLevel riskLevel;

  const DetectionRule({
    required this.id,
    required this.name,
    required this.type,
    required this.condition,
    required this.riskLevel,
  });
}

/// 사기 탐지 결과
class FraudDetectionResult {
  final String userId;
  final bool isFraudulent;
  final RiskLevel riskLevel;
  final List<FraudType> detectedTypes;
  final double confidence;
  final List<String> reasons;
  final List<FraudEvent> events;
  final DateTime timestamp;

  const FraudDetectionResult({
    required this.userId,
    required this.isFraudulent,
    required this.riskLevel,
    required this.detectedTypes,
    required this.confidence,
    required this.reasons,
    required this.events,
    required this.timestamp,
  });
}

/// 사기 탐지 관리자
class FraudDetectionManager {
  static final FraudDetectionManager _instance = FraudDetectionManager._();
  static FraudDetectionManager get instance => _instance;

  FraudDetectionManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<DetectionRule> _rules = [];
  final List<FraudEvent> _fraudEvents = [];
  final Map<String, List<Map<String, dynamic>>> _userBehaviors = {};
  final Map<String, double> _userRiskScores = {};

  final StreamController<FraudEvent> _eventController =
      StreamController<FraudEvent>.broadcast();
  final StreamController<FraudDetectionResult> _resultController =
      StreamController<FraudDetectionResult>.broadcast();

  Stream<FraudEvent> get onFraudEvent => _eventController.stream;
  Stream<FraudDetectionResult> get onDetectionResult => _resultController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 규칙 로드
    _loadRules();

    // 이벤트 로드
    _loadEvents();

    // 정기 분석 시작
    _startPeriodicAnalysis();

    debugPrint('[FraudDetection] Initialized');
  }

  void _loadRules() {
    // 계정 도용 탐지
    _rules.add(DetectionRule(
      id: 'unusual_location',
      name: '비정상적인 위치 접속',
      type: FraudType.accountTheft,
      condition: (data) {
        final locations = data['locations'] as List?;
        if (locations == null || locations.length < 2) return false;

        // 다른 국가에서 동시 접속
        return true;
      },
      riskLevel: RiskLevel.high,
    ));

    _rules.add(DetectionRule(
      id: 'suspicious_login',
      name: '의심스러운 로그인 패턴',
      type: FraudType.accountTheft,
      condition: (data) {
        final failedAttempts = data['failed_attempts'] as int? ?? 0;
        return failedAttempts >= 5;
      },
      riskLevel: RiskLevel.critical,
    ));

    // 봇 탐지
    _rules.add(DetectionRule(
      id: 'repetitive_actions',
      name: '반복적인 행동',
      type: FraudType.botting,
      condition: (data) {
        final actionInterval = data['avg_interval'] as double? ?? 0.0;
        return actionInterval < 0.1; // 100ms 미만 간격
      },
      riskLevel: RiskLevel.high,
    ));

    _rules.add(DetectionRule(
      id: '247_activity',
      name: '24시간 활동',
      type: FraudType.botting,
      condition: (data) {
        final activeHours = data['active_hours'] as int? ?? 0;
        return activeHours >= 20;
      },
      riskLevel: RiskLevel.critical,
    ));

    // 치팅 탐지
    _rules.add(DetectionRule(
      id: 'impossible_stats',
      name: '불가능한 스탯',
      type: FraudType.cheating,
      condition: (data) {
        final winRate = data['win_rate'] as double? ?? 0.0;
        return winRate > 0.95; // 95% 이상 승률
      },
      riskLevel: RiskLevel.high,
    ));

    _rules.add(DetectionRule(
      id: 'abnormal_damage',
      name: '비정상적인 데미지',
      type: FraudType.cheating,
      condition: (data) {
        final damage = data['damage'] as int? ?? 0;
        final expected = data['expected_damage'] as int? ?? 1;
        return damage > expected * 10; // 기대값의 10배 이상
      },
      riskLevel: RiskLevel.critical,
    ));

    // 현금 거래 탐지
    _rules.add(DetectionRule(
      id: 'rapid_transactions',
      name: '급격한 자산 이동',
      type: FraudType.realMoneyTrading,
      condition: (data) {
        final transactionCount = data['transaction_count'] as int? ?? 0;
        return transactionCount >= 100; // 100회 이상 거래
      },
      riskLevel: RiskLevel.high,
    ));

    _rules.add(DetectionRule(
      id: 'suspicious_trade',
      name: '의심스러운 거래',
      type: FraudType.realMoneyTrading,
      condition: (data) {
        final amount = data['amount'] as int? ?? 0;
        final price = data['price'] as double? ?? 0.0;
        return amount > 1000000 && price < 1.0; // 100만 이상에 1달러 미만
      },
      riskLevel: RiskLevel.medium,
    ));

    // 다중 계정 탐지
    _rules.add(DetectionRule(
      id: 'same_device',
      name: '동일 기기 다중 계정',
      type: FraudType.multiAccounting,
      condition: (data) {
        final accounts = data['accounts'] as int? ?? 0;
        return accounts >= 3;
      },
      riskLevel: RiskLevel.medium,
    ));

    // 스팸 탐지
    _rules.add(DetectionRule(
      id: 'spam_messages',
      name: '스팸 메시지',
      type: FraudType.spamming,
      condition: (data) {
        final messageCount = data['message_count'] as int? ?? 0;
        final uniqueRecipients = data['unique_recipients'] as int? ?? 1;
        return messageCount >= 50 && uniqueRecipients <= 5;
      },
      riskLevel: RiskLevel.medium,
    ));
  }

  Future<void> _loadEvents() async {
    // 시뮬레이션: 저장된 이벤트 로드
    final eventsJson = _prefs?.getString('fraud_events');
    if (eventsJson != null) {
      // 실제로는 파싱
    }
  }

  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      analyzeAllUsers();
    });
  }

  /// 행동 기록
  Future<void> trackBehavior({
    required String userId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final behaviors = _userBehaviors[userId] ?? [];
    behaviors.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // 최대 1000개만 유지
    if (behaviors.length > 1000) {
      behaviors.removeRange(0, behaviors.length - 1000);
    }

    _userBehaviors[userId] = behaviors;

    // 실시간 탐지
    await _checkBehavior(userId, action, data);
  }

  /// 실시간 행동 체크
  Future<void> _checkBehavior(
    String userId,
    String action,
    Map<String, dynamic> data,
  ) async {
    for (final rule in _rules) {
      if (rule.condition(data)) {
        final event = FraudEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: rule.type,
          riskLevel: rule.riskLevel,
          confidence: 0.8 + (Random().nextDouble() * 0.2),
          description: rule.name,
          evidence: {
            'action': action,
            'data': data,
            'rule_id': rule.id,
          },
          timestamp: DateTime.now(),
        );

        _fraudEvents.add(event);
        _eventController.add(event);

        // 위험 사용자 처리
        if (rule.riskLevel == RiskLevel.critical) {
          await _handleCriticalFraud(event);
        }

        debugPrint('[FraudDetection] Suspicious activity: $userId - ${rule.name}');
      }
    }
  }

  /// 사용자 분석
  Future<FraudDetectionResult> analyzeUser(String userId) async {
    final behaviors = _userBehaviors[userId] ?? [];
    final detectedTypes = <FraudType>[];
    final reasons = <String>[];
    final events = <FraudEvent>[];
    double totalRisk = 0.0;

    // 각 규칙에 대해 체크
    for (final rule in _rules) {
      // 행동 데이터 집계
      final aggregated = _aggregateBehavior(behaviors, rule.type);

      if (rule.condition(aggregated)) {
        detectedTypes.add(rule.type);
        reasons.add(rule.name);

        // 위험도 계산
        totalRisk += _ruleToRisk(rule.riskLevel);

        final event = FraudEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}_${rule.id}',
          userId: userId,
          type: rule.type,
          riskLevel: rule.riskLevel,
          confidence: 0.7 + (Random().nextDouble() * 0.3),
          description: rule.name,
          evidence: aggregated,
          timestamp: DateTime.now(),
        );

        events.add(event);
      }
    }

    // 위험 레벨 결정
    final riskLevel = _calculateRiskLevel(totalRisk);
    final isFraudulent = riskLevel == RiskLevel.high ||
        riskLevel == RiskLevel.critical;

    final result = FraudDetectionResult(
      userId: userId,
      isFraudulent: isFraudulent,
      riskLevel: riskLevel,
      detectedTypes: detectedTypes,
      confidence: min(totalRisk, 1.0),
      reasons: reasons,
      events: events,
      timestamp: DateTime.now(),
    );

    // 결과 저장
    _userRiskScores[userId] = totalRisk;

    // 위험 사용자 알림
    if (isFraudulent) {
      _resultController.add(result);
    }

    return result;
  }

  Map<String, dynamic> _aggregateBehavior(
    List<Map<String, dynamic>> behaviors,
    FraudType type,
  ) {
    // 타입별 행동 집계
    final filtered = behaviors.where((b) =>
        b['action'] == _typeToAction(type)).toList();

    if (filtered.isEmpty) return {};

    return {
      'count': filtered.length,
      'avg_interval': _calculateAvgInterval(filtered),
      'locations': _getLocations(filtered),
    };
  }

  double _ruleToRisk(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 0.1;
      case RiskLevel.low:
        return 0.3;
      case RiskLevel.medium:
        return 0.5;
      case RiskLevel.high:
        return 0.7;
      case RiskLevel.critical:
        return 0.9;
    }
  }

  RiskLevel _calculateRiskLevel(double totalRisk) {
    if (totalRisk <= 0.4) return RiskLevel.safe;
    if (totalRisk <= 0.6) return RiskLevel.low;
    if (totalRisk <= 0.8) return RiskLevel.medium;
    if (totalRisk <= 1.0) return RiskLevel.high;
    return RiskLevel.critical;
  }

  String _typeToAction(FraudType type) {
    switch (type) {
      case FraudType.accountTheft:
        return 'login';
      case FraudType.botting:
        return 'repeat_action';
      case FraudType.cheating:
        return 'battle';
      case FraudType.realMoneyTrading:
        return 'trade';
      case FraudType.exploit:
        return 'use_exploit';
      case FraudType.spamming:
        return 'send_message';
      case FraudType.multiAccounting:
        return 'register';
      case FraudType.speedHacking:
        return 'complete_task';
    }
  }

  double _calculateAvgInterval(List<Map<String, dynamic>> behaviors) {
    if (behaviors.length < 2) return 0.0;

    double totalInterval = 0.0;
    for (int i = 1; i < behaviors.length; i++) {
      final current = DateTime.parse(behaviors[i]['timestamp'] as String);
      final previous = DateTime.parse(behaviors[i - 1]['timestamp'] as String);
      totalInterval += current.difference(previous).inMilliseconds.toDouble();
    }

    return totalInterval / (behaviors.length - 1);
  }

  List<String> _getLocations(List<Map<String, dynamic>> behaviors) {
    return behaviors
        .map((b) => b['data']?['location'] as String?)
        .whereType<String>()
        .toList();
  }

  /// 모든 사용자 분석
  Future<List<FraudDetectionResult>> analyzeAllUsers() async {
    final results = <FraudDetectionResult>[];

    for (final userId in _userBehaviors.keys) {
      try {
        final result = await analyzeUser(userId);
        if (result.isFraudulent) {
          results.add(result);
        }
      } catch (e) {
        debugPrint('[FraudDetection] Analysis failed for $userId: $e');
      }
    }

    return results;
  }

  /// 위험 사용자 처리
  Future<void> _handleCriticalFraud(FraudEvent event) async {
    // 계정 정지, 자산 동결 등
    debugPrint('[FraudDetection] Critical fraud detected: ${event.userId}');

    // 자동 조치
    await _suspendAccount(event.userId);
    await _notifySecurityTeam(event);
  }

  /// 계정 정지
  Future<void> _suspendAccount(String userId) async {
    debugPrint('[FraudDetection] Account suspended: $userId');

    // 실제 구현에서는 계정 정지 로직
    await _prefs?.setBool('suspended_$userId', true);
  }

  /// 보안 팀 알림
  Future<void> _notifySecurityTeam(FraudEvent event) async {
    debugPrint('[FraudDetection] Security team notified: ${event.id}');

    // 실제 구현에서는 알림 발송
  }

  /// 머신러닝 기반 탐지
  Future<FraudDetectionResult> mlBasedDetection({
    required String userId,
  }) async {
    // 간단한 ML 모델 (시뮬레이션)
    final behaviors = _userBehaviors[userId] ?? [];

    if (behaviors.isEmpty) {
      return FraudDetectionResult(
        userId: userId,
        isFraudulent: false,
        riskLevel: RiskLevel.safe,
        detectedTypes: [],
        confidence: 0.0,
        reasons: [],
        events: [],
        timestamp: DateTime.now(),
      );
    }

    // 특성 추출
    final features = _extractFeatures(behaviors);

    // 점수 계산
    final score = _calculateFraudScore(features);

    final isFraudulent = score > 0.7;
    final riskLevel = _calculateRiskLevel(score);

    return FraudDetectionResult(
      userId: userId,
      isFraudulent: isFraudulent,
      riskLevel: riskLevel,
      detectedTypes: isFraudulent ? [FraudType.botting] : [],
      confidence: score,
      reasons: isFraudulent ? ['ML 기반 탐지'] : [],
      events: [],
      timestamp: DateTime.now(),
    );
  }

  Map<String, double> _extractFeatures(List<Map<String, dynamic>> behaviors) {
    // 특성 추출
    return {
      'action_count': behaviors.length.toDouble(),
      'unique_actions': behaviors.map((b) => b['action']).toSet().length.toDouble(),
      'avg_interval': _calculateAvgInterval(behaviors),
      'night_activity': behaviors.where((b) {
        final hour = DateTime.parse(b['timestamp'] as String).hour;
        return hour >= 0 && hour < 6;
      }).length.toDouble(),
    };
  }

  double _calculateFraudScore(Map<String, double> features) {
    // 간단한 선형 모델
    var score = 0.0;

    // 행동 수가 많으면 의심
    if (features['action_count']! > 1000) {
      score += 0.3;
    }

    // 밤새 활동하면 의심
    if (features['night_activity']! > 100) {
      score += 0.4;
    }

    // 매우 짧은 간격이면 의심
    if (features['avg_interval']! < 100) {
      score += 0.3;
    }

    return min(score, 1.0);
  }

  /// 규칙 추가
  void addRule(DetectionRule rule) {
    _rules.add(rule);
    debugPrint('[FraudDetection] Rule added: ${rule.name}');
  }

  /// 규칙 제거
  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
    debugPrint('[FraudDetection] Rule removed: $ruleId');
  }

  /// 사용자 위험도 조회
  double? getUserRiskScore(String userId) {
    return _userRiskScores[userId];
  }

  /// 모든 사기 이벤트 조회
  List<FraudEvent> getFraudEvents({FraudType? type}) {
    var events = _fraudEvents.toList();

    if (type != null) {
      events = events.where((e) => e.type == type).toList();
    }

    return events;
  }

  /// 통계
  Map<String, dynamic> getStatistics() {
    final typeCounts = <FraudType, int>{};
    for (final type in FraudType.values) {
      typeCounts[type] = _fraudEvents.where((e) => e.type == type).length;
    }

    final levelCounts = <RiskLevel, int>{};
    for (final level in RiskLevel.values) {
      levelCounts[level] = _fraudEvents.where((e) => e.riskLevel == level).length;
    }

    return {
      'totalEvents': _fraudEvents.length,
      'typeDistribution': typeCounts.map((k, v) => MapEntry(k.name, v)),
      'levelDistribution': levelCounts.map((k, v) => MapEntry(k.name, v)),
      'rulesCount': _rules.length,
      'trackedUsers': _userBehaviors.length,
    };
  }

  void dispose() {
    _analysisTimer?.cancel();
    _eventController.close();
    _resultController.close();
  }
}

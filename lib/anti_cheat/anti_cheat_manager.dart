import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 치팅 타입
enum CheatType {
  speedHack,      // 속도 해킹
  teleport,       // 텔레포트
  godMode,        // 무적 모드
  damageHack,     // 데미지 조작
  resourceHack,   // 리소스 조작
  aimBot,         // 에임봇
  wallHack,       // 벽 핵
  autoPlay,       // 오토플레이
  macro,          // 매크로
  injection,      // 코드 인젝션
  memoryHack,     // 메모리 해킹
  packetManipulation, // 패킷 조작
  timeManipulation,   // 시간 조작
  accountSharing,     // 계정 공유
  boosting,          // 부스팅
  other,              // 기타
}

/// 위험도 레벨
enum RiskLevel {
  safe,           // 안전
  low,            // 낮음
  medium,         // 중간
  high,           // 높음
  critical,       // 치명적
}

/// 조치 타입
enum ActionType {
  none,           // 없음
  warning,        // 경고
  temporaryBan,   // 일시 정지
  permanentBan,   // 영구 정지
  rollback,       // 롤백
  monitor,        // 모니터링
  restrict,       // 제한
}

/// 치팅 의심 이벤트
class CheatEvent {
  final String eventId;
  final String userId;
  final CheatType cheatType;
  final RiskLevel riskLevel;
  final String description;
  final Map<String, dynamic> evidence;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceId;
  final bool isConfirmed;

  const CheatEvent({
    required this.eventId,
    required this.userId,
    required this.cheatType,
    required this.riskLevel,
    required this.description,
    required this.evidence,
    required this.timestamp,
    this.ipAddress,
    this.deviceId,
    this.isConfirmed = false,
  });
}

/// 플레이어 통계
class PlayerStats {
  final String userId;
  final Map<String, double> metrics; // 지표별 값
  final Map<String, num> thresholds; // 임계값
  final DateTime lastUpdated;

  const PlayerStats({
    required this.userId,
    required this.metrics,
    required this.thresholds,
    required this.lastUpdated,
  });
}

/// 행동 패턴
class BehaviorPattern {
  final String patternId;
  final String name;
  final String description;
  final Map<String, dynamic> characteristics;
  final RiskLevel associatedRisk;
  final List<CheatType> relatedCheats;

  const BehaviorPattern({
    required this.patternId,
    required this.name,
    required this.description,
    required this.characteristics,
    required this.associatedRisk,
    required this.relatedCheats,
  });
}

/// 치팅 탐지 규칙
class DetectionRule {
  final String ruleId;
  final String name;
  final CheatType cheatType;
  final RiskLevel baseRiskLevel;
  final Map<String, dynamic> conditions;
  final bool isActive;
  final int priority;

  const DetectionRule({
    required this.ruleId,
    required this.name,
    required this.cheatType,
    required this.baseRiskLevel,
    required this.conditions,
    required this.isActive,
    required this.priority,
  });
}

/// 밴 기록
class BanRecord {
  final String banId;
  final String userId;
  final ActionType actionType;
  final String reason;
  final DateTime startedAt;
  final DateTime? endsAt;
  final List<CheatEvent> relatedEvents;
  final bool isPermanent;

  const BanRecord({
    required this.banId,
    required this.userId,
    required this.actionType,
    required this.reason,
    required this.startedAt,
    this.endsAt,
    required this.relatedEvents,
    required this.isPermanent,
  });

  /// 활성 밴 여부
  bool get isActive {
    if (isPermanent) return true;
    if (endsAt == null) return false;
    return DateTime.now().isBefore(endsAt!);
  }
}

/// 반치팅 관리자
class AntiCheatManager {
  static final AntiCheatManager _instance = AntiCheatManager._();
  static AntiCheatManager get instance => _instance;

  AntiCheatManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<CheatEvent> _cheatEvents = [];
  final Map<String, PlayerStats> _playerStats = {};
  final List<DetectionRule> _detectionRules = [];
  final List<BanRecord> _banRecords = [];
  final Map<String, int> _violationCounts = {};

  final StreamController<CheatEvent> _cheatEventController =
      StreamController<CheatEvent>.broadcast();
  final StreamController<BanRecord> _banController =
      StreamController<BanRecord>.broadcast();

  Stream<CheatEvent> get onCheatDetected => _cheatEventController.stream;
  Stream<BanRecord> get onBanIssued => _banController.stream;

  Timer? _analysisTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 탐지 규칙 로드
    await _loadDetectionRules();

    // 행동 패턴 로드
    await _loadBehaviorPatterns();

    // 분석 타이머 시작
    _startAnalysis();

    debugPrint('[AntiCheat] Initialized');
  }

  Future<void> _loadDetectionRules() async {
    _detectionRules.addAll([
      DetectionRule(
        ruleId: 'speed_check',
        name: '속도 이상 탐지',
        cheatType: CheatType.speedHack,
        baseRiskLevel: RiskLevel.high,
        conditions: {
          'maxSpeed': 10.0, // m/s
          'duration': 2000, // ms
        },
        isActive: true,
        priority: 1,
      ),
      DetectionRule(
        ruleId: 'teleport_check',
        name: '텔레포트 탐지',
        cheatType: CheatType.teleport,
        baseRiskLevel: RiskLevel.critical,
        conditions: {
          'maxDistance': 50, // meters
          'timeWindow': 100, // ms
        },
        isActive: true,
        priority: 1,
      ),
      DetectionRule(
        ruleId: 'aim_check',
        name: '에임봇 탐지',
        cheatType: CheatType.aimBot,
        baseRiskLevel: RiskLevel.high,
        conditions: {
          'accuracy': 0.95, // 95%
          'minShots': 100,
        },
        isActive: true,
        priority: 2,
      ),
      DetectionRule(
        ruleId: 'resource_check',
        name: '리소스 이상 탐지',
        cheatType: CheatType.resourceHack,
        baseRiskLevel: RiskLevel.medium,
        conditions: {
          'maxGrowthRate': 2.0, // 2x per second
        },
        isActive: true,
        priority: 2,
      ),
    ]);
  }

  Future<void> _loadBehaviorPatterns() async {
    // 행동 패턴 로드 (실제로는 서버 또는 파일에서)
  }

  void _startAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _analyzeBehaviors();
    });
  }

  /// 플레이어 동작 보고
  Future<void> reportPlayerAction({
    required String userId,
    required String actionType,
    required Map<String, dynamic> data,
  }) async {
    // 통계 업데이트
    await _updatePlayerStats(userId, actionType, data);

    // 탐지 규칙 체크
    await _checkDetectionRules(userId, actionType, data);
  }

  Future<void> _updatePlayerStats(
    String userId,
    String actionType,
    Map<String, dynamic> data,
  ) async {
    var stats = _playerStats[userId];

    if (stats == null) {
      stats = PlayerStats(
        userId: userId,
        metrics: {},
        thresholds: {},
        lastUpdated: DateTime.now(),
      );
    }

    final metrics = Map<String, double>.from(stats.metrics);

    // 동작 타입별 메트릭 업데이트
    switch (actionType) {
      case 'movement':
        final speed = data['speed'] as double? ?? 0;
        metrics['avgSpeed'] = (metrics['avgSpeed'] ?? 0) * 0.9 + speed * 0.1;
        metrics['maxSpeed'] = max(metrics['maxSpeed'] ?? 0, speed);
        metrics['distance'] = (metrics['distance'] ?? 0) + (data['distance'] as double? ?? 0);
        break;

      case 'combat':
        final accuracy = data['accuracy'] as double? ?? 0;
        metrics['accuracy'] = (metrics['accuracy'] ?? 0) * 0.95 + accuracy * 0.05;
        metrics['totalShots'] = (metrics['totalShots'] ?? 0) + (data['shots'] as int? ?? 0);
        metrics['totalHits'] = (metrics['totalHits'] ?? 0) + (data['hits'] as int? ?? 0);
        break;

      case 'resource':
        final amount = data['amount'] as double? ?? 0;
        metrics['resourceGain'] = (metrics['resourceGain'] ?? 0) + amount;
        metrics['lastGainTime'] = DateTime.now().millisecondsSinceEpoch.toDouble();
        break;
    }

    _playerStats[userId] = PlayerStats(
      userId: userId,
      metrics: metrics,
      thresholds: stats.thresholds,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _checkDetectionRules(
    String userId,
    String actionType,
    Map<String, dynamic> data,
  ) async {
    for (final rule in _detectionRules.where((r) => r.isActive)) {
      if (await _evaluateRule(rule, userId, actionType, data)) {
        await _createCheatEvent(
          userId: userId,
          rule: rule,
          data: data,
        );
      }
    }
  }

  Future<bool> _evaluateRule(
    DetectionRule rule,
    String userId,
    String actionType,
    Map<String, dynamic> data,
  ) async {
    final stats = _playerStats[userId];
    if (stats == null) return false;

    switch (rule.cheatType) {
      case CheatType.speedHack:
        final speed = data['speed'] as double? ?? 0;
        final maxSpeed = rule.conditions['maxSpeed'] as double? ?? 10.0;
        return speed > maxSpeed;

      case CheatType.teleport:
        final distance = data['distance'] as double? ?? 0;
        final maxDistance = rule.conditions['maxDistance'] as double? ?? 50;
        return distance > maxDistance;

      case CheatType.aimBot:
        final accuracy = stats.metrics['accuracy'] ?? 0;
        final minAccuracy = rule.conditions['accuracy'] as double? ?? 0.95;
        final shots = stats.metrics['totalShots'] ?? 0;
        final minShots = rule.conditions['minShots'] as int? ?? 100;
        return accuracy >= minAccuracy && shots >= minShots;

      case CheatType.resourceHack:
        final gainRate = _calculateGainRate(stats);
        final maxRate = rule.conditions['maxGrowthRate'] as double? ?? 2.0;
        return gainRate > maxRate;

      default:
        return false;
    }
  }

  double _calculateGainRate(PlayerStats stats) {
    final gain = stats.metrics['resourceGain'] ?? 0;
    final lastTime = stats.metrics['lastGainTime'] ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (lastTime == 0) return 0;

    final duration = (currentTime - lastTime) / 1000; // seconds
    if (duration <= 0) return 0;

    return gain / duration;
  }

  Future<void> _createCheatEvent({
    required String userId,
    required DetectionRule rule,
    required Map<String, dynamic> data,
  }) async {
    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';

    final event = CheatEvent(
      eventId: eventId,
      userId: userId,
      cheatType: rule.cheatType,
      riskLevel: rule.baseRiskLevel,
      description: '${rule.name} 탐지됨',
      evidence: data,
      timestamp: DateTime.now(),
      deviceId: _currentUserId,
    );

    _cheatEvents.add(event);
    _cheatEventController.add(event);

    // 위반 횟수 증가
    _violationCounts[userId] = (_violationCounts[userId] ?? 0) + 1;

    // 자동 조치
    await _considerAction(event);
  }

  Future<void> _considerAction(CheatEvent event) async {
    final violationCount = _violationCounts[event.userId] ?? 0;

    ActionType action = ActionType.none;

    switch (event.riskLevel) {
      case RiskLevel.safe:
        action = ActionType.none;
        break;

      case RiskLevel.low:
        if (violationCount >= 5) {
          action = ActionType.warning;
        }
        break;

      case RiskLevel.medium:
        if (violationCount >= 3) {
          action = ActionType.temporaryBan;
        } else if (violationCount >= 1) {
          action = ActionType.warning;
        }
        break;

      case RiskLevel.high:
        if (violationCount >= 2) {
          action = ActionType.temporaryBan;
        } else {
          action = ActionType.warning;
        }
        break;

      case RiskLevel.critical:
        action = ActionType.permanentBan;
        break;
    }

    if (action != ActionType.none) {
      await _takeAction(event, action);
    }
  }

  Future<void> _takeAction(CheatEvent event, ActionType action) async {
    final banId = 'ban_${DateTime.now().millisecondsSinceEpoch}';

    BanRecord ban;

    switch (action) {
      case ActionType.temporaryBan:
        ban = BanRecord(
          banId: banId,
          userId: event.userId,
          actionType: action,
          reason: event.description,
          startedAt: DateTime.now(),
          endsAt: DateTime.now().add(const Duration(days: 7)),
          relatedEvents: [event],
          isPermanent: false,
        );
        break;

      case ActionType.permanentBan:
        ban = BanRecord(
          banId: banId,
          userId: event.userId,
          actionType: action,
          reason: event.description,
          startedAt: DateTime.now(),
          relatedEvents: [event],
          isPermanent: true,
        );
        break;

      case ActionType.warning:
        ban = BanRecord(
          banId: banId,
          userId: event.userId,
          actionType: action,
          reason: event.description,
          startedAt: DateTime.now(),
          relatedEvents: [event],
          isPermanent: false,
        );
        break;

      default:
        return;
    }

    _banRecords.add(ban);
    _banController.add(ban);

    debugPrint('[AntiCheat] Action taken: ${action.name} for ${event.userId}');
  }

  void _analyzeBehaviors() {
    // 주기적 행동 분석
    for (final entry in _playerStats.entries) {
      final userId = entry.key;
      final stats = entry.value;

      // 이상 패턴 탐지
      _detectAnomalies(userId, stats);
    }
  }

  void _detectAnomalies(String userId, PlayerStats stats) {
    // 통계적 이상 탐지
    final metrics = stats.metrics;

    // 속도 이상
    final avgSpeed = metrics['avgSpeed'] ?? 0;
    if (avgSpeed > 15) {
      _createAnomalyEvent(
        userId: userId,
        type: CheatType.speedHack,
        description: '평균 속도 이상: $avgSpeed m/s',
      );
    }

    // 정확도 이상
    final accuracy = metrics['accuracy'] ?? 0;
    final shots = metrics['totalShots'] ?? 0;
    if (accuracy > 0.9 && shots > 50) {
      _createAnomalyEvent(
        userId: userId,
        type: CheatType.aimBot,
        description: '비정상적 정확도: ${(accuracy * 100).toStringAsFixed(1)}%',
      );
    }
  }

  Future<void> _createAnomalyEvent({
    required String userId,
    required CheatType type,
    required String description,
  }) async {
    // 이상 이벤트 생성
    debugPrint('[AntiCheat] Anomaly detected: $userId - $description');
  }

  /// 플레이어 통계 조회
  PlayerStats? getPlayerStats(String userId) {
    return _playerStats[userId];
  }

  /// 치팅 이벤트 목록
  List<CheatEvent> getCheatEvents({String? userId}) {
    if (userId != null) {
      return _cheatEvents.where((e) => e.userId == userId).toList();
    }
    return _cheatEvents.toList();
  }

  /// 밴 기록 목록
  List<BanRecord> getBanRecords({String? userId, bool onlyActive = false}) {
    var records = _banRecords;

    if (userId != null) {
      records = records.where((r) => r.userId == userId).toList();
    }

    if (onlyActive) {
      records = records.where((r) => r.isActive).toList();
    }

    return records;
  }

  /// 밴 여부 확인
  bool isUserBanned(String userId) {
    return getBanRecords(userId: userId, onlyActive: true).isNotEmpty;
  }

  /// 플레이어 위험도 계산
  RiskLevel calculatePlayerRisk(String userId) {
    final violationCount = _violationCounts[userId] ?? 0;

    if (violationCount == 0) return RiskLevel.safe;
    if (violationCount <= 2) return RiskLevel.low;
    if (violationCount <= 5) return RiskLevel.medium;
    if (violationCount <= 10) return RiskLevel.high;
    return RiskLevel.critical;
  }

  /// 수동 밴
  Future<bool> banPlayer({
    required String userId,
    required ActionType actionType,
    required String reason,
    Duration? duration,
  }) async {
    final banId = 'ban_${DateTime.now().millisecondsSinceEpoch}';

    final ban = BanRecord(
      banId: banId,
      userId: userId,
      actionType: actionType,
      reason: reason,
      startedAt: DateTime.now(),
      endsAt: duration != null ? DateTime.now().add(duration) : null,
      relatedEvents: [],
      isPermanent: duration == null,
    );

    _banRecords.add(ban);
    _banController.add(ban);

    return true;
  }

  /// 밴 해제
  Future<bool> unbanPlayer(String userId) async {
    final activeBans = getBanRecords(userId: userId, onlyActive: true);

    if (activeBans.isEmpty) return false;

    // 실제로는 밴 상태 업데이트
    debugPrint('[AntiCheat] Unbanned: $userId');

    return true;
  }

  void dispose() {
    _cheatEventController.close();
    _banController.close();
    _analysisTimer?.cancel();
  }
}

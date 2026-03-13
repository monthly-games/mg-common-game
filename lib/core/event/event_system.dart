import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_common_game/core/economy/currency_manager.dart';
import 'package:mg_common_game/core/quest/daily_quest_system.dart';

/// 이벤트 유형
enum EventType {
  daily,       // 일일 이벤트
  weekly,      // 주간 이벤트
  seasonal,    // 시즌 이벤트
  special,     // 특별 이벤트
  limited,     // 한정 이벤트
  campaign,    // 캠페인 이벤트
}

/// 이벤트 상태
enum EventStatus {
  upcoming,    // 시작 전
  active,      // 진행 중
  ended,       // 종료
  archived,    // 보관됨
}

/// 이벤트 참여 조건 타입
enum EventRequirementType {
  level,           // 레벨 요구
  achievement,     // 업적 완료
  item_owned,      // 아이템 보유
  quest_completed, // 퀘스트 완료
  custom,          // 커스텀 조건
}

/// 이벤트 참여 조건
class EventRequirement {
  final EventRequirementType type;
  final String description;
  final Map<String, dynamic> criteria;
  bool isSatisfied;

  EventRequirement({
    required this.type,
    required this.description,
    required this.criteria,
    this.isSatisfied = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'description': description,
        'criteria': criteria,
        'isSatisfied': isSatisfied,
      };

  factory EventRequirement.fromJson(Map<String, dynamic> json) =>
      EventRequirement(
        type: EventRequirementType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EventRequirementType.custom,
        ),
        description: json['description'] as String,
        criteria: json['criteria'] as Map<String, dynamic>,
        isSatisfied: json['isSatisfied'] as bool? ?? false,
      );
}

/// 이벤트 보상
class EventReward {
  final String id;
  final String description;
  final List<QuestReward> rewards;
  final int requiredPoints; // 필요 포인트

  const EventReward({
    required this.id,
    required this.description,
    required this.rewards,
    required this.requiredPoints,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'requiredPoints': requiredPoints,
      };

  factory EventReward.fromJson(Map<String, dynamic> json) => EventReward(
        id: json['id'] as String,
        description: json['description'] as String,
        rewards: (json['rewards'] as List)
            .map((r) => QuestReward.fromJson(r as Map<String, dynamic>))
            .toList(),
        requiredPoints: json['requiredPoints'] as int,
      );
}

/// 게임 이벤트
class GameEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final List<EventRequirement> requirements;
  final List<EventReward> rewards;
  final String? bannerImageUrl;
  final int maxParticipants;
  final int currentParticipants;
  final Map<String, dynamic> eventData;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.requirements,
    required this.rewards,
    this.bannerImageUrl,
    this.maxParticipants = 0,
    this.currentParticipants = 0,
    this.eventData = const {},
  });

  /// 이벤트 활성 여부
  bool get isActive => status == EventStatus.active;

  /// 종료까지 남은 시간
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }

  /// 시작까지 남은 시간
  Duration get timeUntilStart {
    final now = DateTime.now();
    if (now.isAfter(startTime)) return Duration.zero;
    return startTime.difference(now);
  }

  /// 참여 가능 여부
  bool get canParticipate {
    if (!isActive) return false;
    if (maxParticipants > 0 && currentParticipants >= maxParticipants) {
      return false;
    }
    return requirements.every((req) => req.isSatisfied);
  }

  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (startTime.isAfter(DateTime.now())) return 0.0;
    if (endTime.isBefore(DateTime.now())) return 1.0;

    final total = endTime.difference(startTime).inSeconds;
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  GameEvent copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    EventStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    List<EventRequirement>? requirements,
    List<EventReward>? rewards,
    String? bannerImageUrl,
    int? maxParticipants,
    int? currentParticipants,
    Map<String, dynamic>? eventData,
  }) {
    return GameEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      requirements: requirements ?? this.requirements,
      rewards: rewards ?? this.rewards,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      eventData: eventData ?? this.eventData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'requirements': requirements.map((r) => r.toJson()).toList(),
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'bannerImageUrl': bannerImageUrl,
        'maxParticipants': maxParticipants,
        'currentParticipants': currentParticipants,
        'eventData': eventData,
      };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: EventType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => EventType.special,
        ),
        status: EventStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => EventStatus.upcoming,
        ),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        requirements: (json['requirements'] as List)
            .map((r) => EventRequirement.fromJson(r as Map<String, dynamic>))
            .toList(),
        rewards: (json['rewards'] as List)
            .map((r) => EventReward.fromJson(r as Map<String, dynamic>))
            .toList(),
        bannerImageUrl: json['bannerImageUrl'] as String?,
        maxParticipants: json['maxParticipants'] as int? ?? 0,
        currentParticipants: json['currentParticipants'] as int? ?? 0,
        eventData: json['eventData'] as Map<String, dynamic>? ?? {},
      );
}

/// 플레이어 이벤트 참여 데이터
class PlayerEventProgress {
  final String eventId;
  int currentPoints;
  final List<String> claimedRewards;
  DateTime lastUpdateTime;
  Map<String, dynamic> customData;

  PlayerEventProgress({
    required this.eventId,
    this.currentPoints = 0,
    this.claimedRewards = const [],
    DateTime? lastUpdateTime,
    this.customData = const {},
  }) : lastUpdateTime = lastUpdateTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'currentPoints': currentPoints,
        'claimedRewards': claimedRewards,
        'lastUpdateTime': lastUpdateTime.toIso8601String(),
        'customData': customData,
      };

  factory PlayerEventProgress.fromJson(Map<String, dynamic> json) =>
      PlayerEventProgress(
        eventId: json['eventId'] as String,
        currentPoints: json['currentPoints'] as int,
        claimedRewards:
            (json['claimedRewards'] as List).cast<String>(),
        lastUpdateTime: DateTime.parse(json['lastUpdateTime'] as String),
        customData: json['customData'] as Map<String, dynamic>? ?? {},
      );
}

/// 이벤트 시스템
class EventSystem extends ChangeNotifier {
  static final EventSystem _instance = EventSystem._();
  static EventSystem get instance => _instance;

  EventSystem._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;
  final Map<String, GameEvent> _events = {};
  final Map<String, PlayerEventProgress> _playerProgress = {};
  Timer? _statusCheckTimer;

  // ============================================
  // Getters
  // ============================================
  bool get isInitialized => _prefs != null;

  /// 모든 이벤트
  List<GameEvent> get allEvents => _events.values.toList();

  /// 활성화된 이벤트
  List<GameEvent> get activeEvents =>
      allEvents.where((e) => e.isActive).toList();

  /// 참여 가능한 이벤트
  List<GameEvent> get participatableEvents =>
      activeEvents.where((e) => e.canParticipate).toList();

  /// 특정 이벤트 조회
  GameEvent? getEvent(String eventId) => _events[eventId];

  /// 플레이어 진행률 조회
  PlayerEventProgress? getProgress(String eventId) => _playerProgress[eventId];

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_prefs != null) return;

    _prefs = await SharedPreferences.getInstance();

    // 저장된 데이터 로드
    await _loadSavedData();

    // 이벤트 상태 주기적 체크
    _startStatusCheck();

    notifyListeners();
  }

  /// 이벤트 등록
  void registerEvent(GameEvent event) {
    _events[event.id] = event;

    // 플레이어 진행률 초기화
    if (!_playerProgress.containsKey(event.id)) {
      _playerProgress[event.id] = PlayerEventProgress(eventId: event.id);
    }

    notifyListeners();
  }

  /// 여러 이벤트 일괄 등록
  void registerEvents(List<GameEvent> events) {
    for (final event in events) {
      _events[event.id] = event;

      if (!_playerProgress.containsKey(event.id)) {
        _playerProgress[event.id] = PlayerEventProgress(eventId: event.id);
      }
    }

    notifyListeners();
  }

  // ============================================
  // 이벤트 참여 및 진행
  // ============================================

  /// 이벤트 참여
  Future<bool> participateInEvent(String eventId) async {
    final event = _events[eventId];
    if (event == null) return false;
    if (!event.canParticipate) return false;

    // 참여 처리
    final updatedEvent = event.copyWith(
      currentParticipants: event.currentParticipants + 1,
    );
    _events[eventId] = updatedEvent;

    await _saveEventData();

    notifyListeners();
    return true;
  }

  /// 포인트 획득
  Future<bool> earnEventPoints(String eventId, int points) async {
    final event = _events[eventId];
    if (event == null || !event.isActive) return false;

    final progress = _playerProgress[eventId];
    if (progress == null) return false;

    progress.currentPoints += points;
    progress.lastUpdateTime = DateTime.now();

    await _saveProgressData();

    notifyListeners();
    return true;
  }

  /// 보상 수령
  Future<bool> claimReward(String eventId, String rewardId) async {
    final event = _events[eventId];
    if (event == null) return false;

    final progress = _playerProgress[eventId];
    if (progress == null) return false;

    // 이미 수령한 보상인지 확인
    if (progress.claimedRewards.contains(rewardId)) return false;

    // 보상 조회
    final reward = event.rewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => throw Exception('Reward not found'),
    );

    // 포인트 충분 여부 확인
    if (progress.currentPoints < reward.requiredPoints) return false;

    // 보상 지급
    for (final questReward in reward.rewards) {
      await _grantQuestReward(questReward);
    }

    // 수령 처리
    progress.claimedRewards.add(rewardId);
    await _saveProgressData();

    notifyListeners();
    return true;
  }

  /// 커스텀 데이터 업데이트
  Future<void> updateEventCustomData(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final progress = _playerProgress[eventId];
    if (progress == null) return;

    progress.customData = {...progress.customData, ...data};
    progress.lastUpdateTime = DateTime.now();

    await _saveProgressData();

    notifyListeners();
  }

  /// 참여 조건 만족 여부 업데이트
  Future<void> updateRequirementStatus(
    String eventId,
    String requirementId,
    bool isSatisfied,
  ) async {
    final event = _events[eventId];
    if (event == null) return;

    final updatedRequirements = event.requirements.map((req) {
      // description을 ID로 사용 (간단 구현)
      if (req.description == requirementId || req.type.name == requirementId) {
        return EventRequirement(
          type: req.type,
          description: req.description,
          criteria: req.criteria,
          isSatisfied: isSatisfied,
        );
      }
      return req;
    }).toList();

    _events[eventId] = event.copyWith(requirements: updatedRequirements);

    await _saveEventData();

    notifyListeners();
  }

  // ============================================
  // 내부 헬퍼 메서드
  // ============================================

  Future<void> _grantQuestReward(QuestReward reward) async {
    switch (reward.type) {
      case QuestRewardType.coins:
        await CurrencyManager.instance.addCurrency(
          CurrencyType.coin,
          reward.amount,
          source: 'event',
        );
        break;
      case QuestRewardType.gems:
        await CurrencyManager.instance.addCurrency(
          CurrencyType.gem,
          reward.amount,
          source: 'event',
        );
        break;
      case QuestRewardType.experience:
        // 경험치 지급 로직 (게임별 구현)
        break;
      case QuestRewardType.items:
        // 아이템 지급 로직 (게임별 구현)
        break;
      case QuestRewardType.custom:
        // 커스텀 보상 지급
        break;
    }
  }

  // ============================================
  // 이벤트 상태 관리
  // ============================================

  void _startStatusCheck() {
    _statusCheckTimer?.cancel();

    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkEventStatus(),
    );

    // 즉시 한 번 실행
    _checkEventStatus();
  }

  Future<void> _checkEventStatus() async {
    final now = DateTime.now();
    bool hasChanges = false;

    for (final event in _events.values) {
      EventStatus newStatus;

      if (now.isBefore(event.startTime)) {
        newStatus = EventStatus.upcoming;
      } else if (now.isAfter(event.endTime)) {
        newStatus = EventStatus.ended;
      } else {
        newStatus = EventStatus.active;
      }

      if (event.status != newStatus) {
        _events[event.id] = event.copyWith(status: newStatus);
        hasChanges = true;

        if (kDebugMode) {
          debugPrint('[EventSystem] Event ${event.id} status: $newStatus');
        }
      }
    }

    if (hasChanges) {
      await _saveEventData();
      notifyListeners();
    }
  }

  // ============================================
  // 데이터 저장/로드
  // ============================================

  Future<void> _saveEventData() async {
    final eventsJson = <String, dynamic>{};

    for (final entry in _events.entries) {
      eventsJson[entry.key] = entry.value.toJson();
    }

    await _prefs!.setString('events', jsonEncode(eventsJson));
  }

  Future<void> _saveProgressData() async {
    final progressJson = <String, dynamic>{};

    for (final entry in _playerProgress.entries) {
      progressJson[entry.key] = entry.value.toJson();
    }

    await _prefs!.setString('event_progress', jsonEncode(progressJson));
  }

  Future<void> _loadSavedData() async {
    // 이벤트 데이터 로드
    final eventsStr = _prefs!.getString('events');
    if (eventsStr != null) {
      final eventsJson = jsonDecode(eventsStr) as Map<String, dynamic>;

      for (final entry in eventsJson.entries) {
        _events[entry.key] = GameEvent.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    // 진행률 데이터 로드
    final progressStr = _prefs!.getString('event_progress');
    if (progressStr != null) {
      final progressJson = jsonDecode(progressStr) as Map<String, dynamic>;

      for (final entry in progressJson.entries) {
        _playerProgress[entry.key] =
            PlayerEventProgress.fromJson(entry.value as Map<String, dynamic>);
      }
    }
  }

  /// 데이터 초기화
  Future<void> clearData() async {
    if (_prefs != null) {
      await _prefs!.remove('events');
      await _prefs!.remove('event_progress');
    }

    _events.clear();
    _playerProgress.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}

/// 이벤트 통계
class EventStatistics {
  final int totalEventsParticipated;
  final int totalEventsCompleted;
  final int totalPointsEarned;
  final int totalRewardsClaimed;
  final DateTime lastParticipationDate;

  const EventStatistics({
    required this.totalEventsParticipated,
    required this.totalEventsCompleted,
    required this.totalPointsEarned,
    required this.totalRewardsClaimed,
    required this.lastParticipationDate,
  });

  double get completionRate {
    if (totalEventsParticipated == 0) return 0.0;
    return totalEventsCompleted / totalEventsParticipated;
  }

  Map<String, dynamic> toJson() => {
        'totalEventsParticipated': totalEventsParticipated,
        'totalEventsCompleted': totalEventsCompleted,
        'totalPointsEarned': totalPointsEarned,
        'totalRewardsClaimed': totalRewardsClaimed,
        'lastParticipationDate': lastParticipationDate.toIso8601String(),
      };

  factory EventStatistics.fromJson(Map<String, dynamic> json) =>
      EventStatistics(
        totalEventsParticipated: json['totalEventsParticipated'] as int,
        totalEventsCompleted: json['totalEventsCompleted'] as int,
        totalPointsEarned: json['totalPointsEarned'] as int,
        totalRewardsClaimed: json['totalRewardsClaimed'] as int,
        lastParticipationDate:
            DateTime.parse(json['lastParticipationDate'] as String),
      );
}

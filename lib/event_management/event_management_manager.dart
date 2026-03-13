import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이벤트 타입
enum EventType {
  login,          // 로그인 이벤트
  dungeon,        // 던전 이벤트
  raid,           // 레이드 이벤트
  pvp,            // PVP 이벤트
  boss,           // 보스 이벤트
  collection,     // 수집 이벤트
  social,         // 소셜 이벤트
  special,        // 특별 이벤트
}

/// 이벤트 상태
enum EventStatus {
  upcoming,       // 예정
  active,         // 진행 중
  ended,          // 종료
  completed,      // 완료
}

/// 이벤트 참여 조건
class EventRequirement {
  final int? minLevel;
  final int? maxLevel;
  final List<String>? requiredItems;
  final int? requiredGuildLevel;
  final String? prerequisiteEventId;

  const EventRequirement({
    this.minLevel,
    this.maxLevel,
    this.requiredItems,
    this.requiredGuildLevel,
    this.prerequisiteEventId,
  });

  /// 충족 여부
  bool check({
    required int userLevel,
    List<String>? userItems,
    int? guildLevel,
    Set<String>? completedEvents,
  }) {
    if (minLevel != null && userLevel < minLevel!) return false;
    if (maxLevel != null && userLevel > maxLevel!) return false;
    if (requiredItems != null && userItems != null) {
      if (!userItems.any((item) => requiredItems!.contains(item))) {
        return false;
      }
    }
    if (requiredGuildLevel != null &&
        (guildLevel == null || guildLevel! < requiredGuildLevel!)) {
      return false;
    }
    if (prerequisiteEventId != null &&
        completedEvents != null &&
        !completedEvents!.contains(prerequisiteEventId)) {
      return false;
    }
    return true;
  }
}

/// 이벤트 보상
class EventReward {
  final String type; // currency, item, title, badge
  final String id;
  final String name;
  final int? amount;
  final String? itemId;
  final int? itemQuantity;
  final int? rarity;

  const EventReward({
    required this.type,
    required this.id,
    required this.name,
    this.amount,
    this.itemId,
    this.itemQuantity,
    this.rarity,
  });
}

/// 이벤트 미션
class EventMission {
  final String missionId;
  final String title;
  final String description;
  final Map<String, dynamic> criteria; // {type: 'kill', target: 100}
  final int currentProgress;
  final int maxProgress;
  final bool isCompleted;
  final List<EventReward> rewards;

  const EventMission({
    required this.missionId,
    required this.title,
    required this.description,
    required this.criteria,
    required this.currentProgress,
    required this.maxProgress,
    required this.isCompleted,
    required this.rewards,
  });

  /// 진행률
  double get progress {
    if (maxProgress == 0) return 0.0;
    return currentProgress / maxProgress;
  }

  /// 보상 수령 가능
  bool get canClaim => isCompleted;
}

/// 게임 이벤트
class GameEvent {
  final String eventId;
  final String name;
  final String description;
  final EventType type;
  final EventStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final EventRequirement? requirement;
  final List<EventMission> missions;
  final List<EventReward> completionRewards;
  final String? bannerImage;
  final String? icon;
  final int priority; // 표시 우선순위
  final bool isRepeatable; // 반복 가능
  final int? maxParticipations; // 최대 참여 횟수

  const GameEvent({
    required this.eventId,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.requirement,
    required this.missions,
    required this.completionRewards,
    this.bannerImage,
    this.icon,
    this.priority = 0,
    this.isRepeatable = false,
    this.maxParticipations,
  });

  /// 활성 상태
  bool get isActive {
    final now = DateTime.now();
    return status == EventStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  /// 남은 시간
  Duration? get remainingTime {
    if (!isActive) return null;
    return endDate.difference(DateTime.now());
  }

  /// 참여 가능 여부
  bool canParticipate({
    required int userLevel,
    List<String>? userItems,
    int? guildLevel,
    Set<String>? completedEvents,
  }) {
    if (!isActive) return false;
    if (requirement == null) return true;
    return requirement!.check(
      userLevel: userLevel,
      userItems: userItems,
      guildLevel: guildLevel,
      completedEvents: completedEvents,
    );
  }

  /// 전체 진행률
  double get totalProgress {
    if (missions.isEmpty) return 0.0;
    final total = missions.fold<double>(0, (sum, m) => sum + m.progress);
    return total / missions.length;
  }
}

/// 플레이어 이벤트 데이터
class PlayerEventData {
  final String userId;
  final Map<String, int> participationCounts; // eventId -> count
  final Map<String, List<EventMission>> missionProgress; // eventId -> missions
  final Set<String> claimedEvents; // 보상 수령한 이벤트
  final Set<String> completedEvents; // 완료한 이벤트

  const PlayerEventData({
    required this.userId,
    required this.participationCounts,
    required this.missionProgress,
    required this.claimedEvents,
    required this.completedEvents,
  });

  /// 이벤트 진행 데이터
  List<EventMission>? getMissionProgress(String eventId) {
    return missionProgress[eventId];
  }

  /// 참여 횟수
  int getParticipationCount(String eventId) {
    return participationCounts[eventId] ?? 0;
  }

  /// 완료 여부
  bool isCompleted(String eventId) {
    return completedEvents.contains(eventId);
  }
}

/// 이벤트 관리자
class EventManagementManager {
  static final EventManagementManager _instance =
      EventManagementManager._();
  static EventManagementManager get instance => _instance;

  EventManagementManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<GameEvent> _events = [];
  PlayerEventData? _playerData;

  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();
  final StreamController<EventMission> _missionController =
      StreamController<EventMission>.broadcast();

  Stream<GameEvent> get onEventUpdate => _eventController.stream;
  Stream<EventMission> get onMissionUpdate => _missionController.stream;

  Timer? _eventCheckTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 이벤트 로드
    _loadEvents();

    // 플레이어 데이터 로드
    if (_currentUserId != null) {
      await _loadPlayerData(_currentUserId!);
    }

    // 이벤트 체크 시작
    _startEventCheck();

    debugPrint('[EventManagement] Initialized');
  }

  void _loadEvents() {
    _events.clear();

    // 로그인 이벤트
    _events.add(GameEvent(
      eventId: 'login_event_1',
      name: '7일 연속 로그인',
      description: '7일 연속으로 로그인하고 보상을 받으세요!',
      type: EventType.login,
      status: EventStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      missions: List.generate(7, (i) => EventMission(
        missionId: 'login_day_${i + 1}',
        title: '${i + 1}일차 로그인',
        description: '${i + 1}일째 로그인 완료',
        criteria: {'type': 'login', 'day': i + 1},
        currentProgress: 0,
        maxProgress: 1,
        isCompleted: false,
        rewards: const [
          EventReward(
            type: 'currency',
            id: 'gold',
            name: '골드',
            amount: 100 * (i + 1),
          ),
        ],
      )),
      completionRewards: const [
        EventReward(
          type: 'item',
          id: 'exclusive_box',
          name: '독점 상자',
          itemQuantity: 1,
          rarity: 5,
        ),
      ],
      bannerImage: 'assets/events/login_banner.png',
      icon: 'assets/events/login_icon.png',
      priority: 100,
      isRepeatable: false,
    ));

    // 던전 이벤트
    _events.add(GameEvent(
      eventId: 'dungeon_event_1',
      name: '던전 챌린지',
      description: '특정 던전을 클리어하고 보상을 획득하세요',
      type: EventType.dungeon,
      status: EventStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 7)),
      requirement: const EventRequirement(minLevel: 20),
      missions: const [
        EventMission(
          missionId: 'dungeon_easy',
          title: '쉬운 던전 클리어',
          description: '쉬운 난이도 던전 5회 클리어',
          criteria: {'type': 'dungeon_clear', 'difficulty': 'easy', 'count': 5},
          currentProgress: 2,
          maxProgress: 5,
          isCompleted: false,
          rewards: [
            EventReward(
              type: 'currency',
              id: 'gold',
              name: '골드',
              amount: 5000,
            ),
          ],
        ),
        EventMission(
          missionId: 'dungeon_hard',
          title: '어려운 던전 클리어',
          description: '어려운 난이도 던전 3회 클리어',
          criteria: {'type': 'dungeon_clear', 'difficulty': 'hard', 'count': 3},
          currentProgress: 0,
          maxProgress: 3,
          isCompleted: false,
          rewards: [
            EventReward(
              type: 'item',
              id: 'rare_box',
              name: '희귀 상자',
              itemQuantity: 1,
              rarity: 3,
            ),
          ],
        ),
      ],
      completionRewards: const [
        EventReward(
          type: 'title',
          id: 'dungeon_master',
          name: '던전 마스터',
        ),
      ],
      bannerImage: 'assets/events/dungeon_banner.png',
      priority: 80,
    ));

    // 보스 레이드
    _events.add(GameEvent(
      eventId: 'boss_raid_1',
      name: '월드 보스: 불의 정령',
      description: '전 서버가 함께하는 보스 레이드!',
      type: EventType.boss,
      status: EventStatus.active,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
      requirement: const EventRequirement(minLevel: 30),
      missions: const [
        EventMission(
          missionId: 'boss_damage_1m',
          title: '100만 데미지',
          description: '보스에게 100만 데미지 입히기',
          criteria: {'type': 'boss_damage', 'target': 1000000},
          currentProgress: 250000,
          maxProgress: 1000000,
          isCompleted: false,
          rewards: [
            EventReward(
              type: 'currency',
              id: 'raid_currency',
              name: '레이드 코인',
              amount: 1000,
            ),
          ],
        ),
      ],
      completionRewards: const [
        EventReward(
          type: 'badge',
          id: 'boss_slayer',
          name: '보스 슬레이어 배지',
        ),
      ],
      bannerImage: 'assets/events/boss_banner.png',
      priority: 100,
    ));

    // PVP 이벤트
    _events.add(GameEvent(
      eventId: 'pvp_event_1',
      name: 'PVP 대전',
      description: 'PVP 승리하고 특별 보상을 받으세요',
      type: EventType.pvp,
      status: EventStatus.active,
      startDate: DateTime.now().subtract(const Duration(hours: 6)),
      endDate: DateTime.now().add(const Duration(hours: 18)),
      requirement: const EventRequirement(minLevel: 15),
      missions: const [
        EventMission(
          missionId: 'pvp_win_3',
          title: '3승 달성',
          description: 'PVP 3승',
          criteria: {'type': 'pvp_win', 'count': 3},
          currentProgress: 1,
          maxProgress: 3,
          isCompleted: false,
          rewards: [
            EventReward(
              type: 'currency',
              id: 'gems',
              name: '젬',
              amount: 50,
            ),
          ],
        ),
      ],
      completionRewards: const [
        EventReward(
          type: 'item',
          id: 'pvp_box',
          name: 'PVP 상자',
          itemQuantity: 1,
          rarity: 4,
        ),
      ],
      bannerImage: 'assets/events/pvp_banner.png',
      priority: 70,
      isRepeatable: true,
      maxParticipations: 10,
    ));

    // 수집 이벤트
    _events.add(GameEvent(
      eventId: 'collection_1',
      name: '재료 수집',
      description: '특정 재료를 수집하세요',
      type: EventType.collection,
      status: EventStatus.upcoming,
      startDate: DateTime.now().add(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 12)),
      missions: const [
        EventMission(
          missionId: 'collect_iron',
          title: '철 100개 수집',
          description: '철 100개 수집',
          criteria: {'type': 'collect', 'item': 'iron', 'count': 100},
          currentProgress: 0,
          maxProgress: 100,
          isCompleted: false,
          rewards: [
            EventReward(
              type: 'currency',
              id: 'gold',
              name: '골드',
              amount: 2000,
            ),
          ],
        ),
      ],
      completionRewards: const [
        EventReward(
          type: 'item',
          id: 'craft_box',
          name: '제작 상자',
          itemQuantity: 1,
          rarity: 4,
        ),
      ],
      bannerImage: 'assets/events/collection_banner.png',
      priority: 50,
    ));
  }

  Future<void> _loadPlayerData(String userId) async {
    final json = _prefs?.getString('event_data_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[EventManagement] Error loading data: $e');
      }
    }

    _playerData = PlayerEventData(
      userId: userId,
      participationCounts: {},
      missionProgress: {},
      claimedEvents: {},
      completedEvents: {},
    );
  }

  void _startEventCheck() {
    _eventCheckTimer?.cancel();
    _eventCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkEventStatus();
    });
  }

  void _checkEventStatus() {
    var updated = false;

    for (final event in _events) {
      final now = DateTime.now();
      var newStatus = event.status;

      if (event.status == EventStatus.upcoming &&
          now.isAfter(event.startDate)) {
        newStatus = EventStatus.active;
      } else if (event.status == EventStatus.active &&
          now.isAfter(event.endDate)) {
        newStatus = EventStatus.ended;
      }

      if (newStatus != event.status) {
        updated = true;
        _eventController.add(event);
      }
    }
  }

  /// 이벤트 참여
  Future<bool> participateEvent(String eventId) async {
    if (_currentUserId == null) return false;
    if (_playerData == null) return false;

    final event = _events.cast<GameEvent?>.firstWhere(
      (e) => e?.eventId == eventId,
      orElse: () => null,
    );

    if (event == null) return false;
    if (!event.isActive) return false;

    // 참여 조건 확인
    final canParticipate = event.canParticipate(
      userLevel: 50, // 실제 유저 레벨
      userItems: [],
      guildLevel: null,
      completedEvents: _playerData!.completedEvents,
    );

    if (!canParticipate) {
      debugPrint('[EventManagement] Cannot participate: $eventId');
      return false;
    }

    // 참여 횟수 체크
    if (event.maxParticipations != null) {
      final currentCount = _playerData!.getParticipationCount(eventId);
      if (currentCount >= event.maxParticipations!) {
        return false;
      }
    }

    // 참여 기록
    final counts = Map<String, int>.from(_playerData!.participationCounts);
    counts[eventId] = (counts[eventId] ?? 0) + 1;

    final progress = Map<String, List<EventMission>>.from(
      _playerData!.missionProgress
    );
    progress[eventId] = event.missions.map((m) => EventMission(
      missionId: m.missionId,
      title: m.title,
      description: m.description,
      criteria: m.criteria,
      currentProgress: 0,
      maxProgress: m.maxProgress,
      isCompleted: false,
      rewards: m.rewards,
    )).toList();

    _playerData = PlayerEventData(
      userId: _playerData!.userId,
      participationCounts: counts,
      missionProgress: progress,
      claimedEvents: _playerData!.claimedEvents,
      completedEvents: _playerData!.completedEvents,
    );

    _eventController.add(event);

    await _savePlayerData();

    debugPrint('[EventManagement] Participated: $eventId');

    return true;
  }

  /// 미션 진행 업데이트
  Future<void> updateMissionProgress({
    required String eventId,
    required String missionId,
    required int progress,
  }) async {
    if (_playerData == null) return;

    final missions = _playerData!.missionProgress[eventId];
    if (missions == null) return;

    final index = missions.indexWhere((m) => m.missionId == missionId);
    if (index == -1) return;

    final mission = missions[index];
    final isCompleted = progress >= mission.maxProgress;

    final updated = EventMission(
      missionId: mission.missionId,
      title: mission.title,
      description: mission.description,
      criteria: mission.criteria,
      currentProgress: progress,
      maxProgress: mission.maxProgress,
      isCompleted: isCompleted,
      rewards: mission.rewards,
    );

    final updatedMissions = List<EventMission>.from(missions);
    updatedMissions[index] = updated;

    final progressMap = Map<String, List<EventMission>>.from(
      _playerData!.missionProgress
    );
    progressMap[eventId] = updatedMissions;

    _playerData = PlayerEventData(
      userId: _playerData!.userId,
      participationCounts: _playerData!.participationCounts,
      missionProgress: progressMap,
      claimedEvents: _playerData!.claimedEvents,
      completedEvents: _playerData!.completedEvents,
    );

    _missionController.add(updated);

    // 전체 완료 체크
    if (updatedMissions.every((m) => m.isCompleted)) {
      await _completeEvent(eventId);
    }

    await _savePlayerData();
  }

  Future<void> _completeEvent(String eventId) async {
    if (_playerData == null) return;

    final completed = Set<String>.from(_playerData!.completedEvents);
    completed.add(eventId);

    _playerData = PlayerEventData(
      userId: _playerData!.userId,
      participationCounts: _playerData!.participationCounts,
      missionProgress: _playerData!.missionProgress,
      claimedEvents: _playerData!.claimedEvents,
      completedEvents: completed,
    );

    debugPrint('[EventManagement] Event completed: $eventId');
  }

  /// 미션 보상 수령
  Future<bool> claimMissionReward({
    required String eventId,
    required String missionId,
  }) async {
    if (_playerData == null) return false;

    final missions = _playerData!.missionProgress[eventId];
    if (missions == null) return false;

    final mission = missions.cast<EventMission?>.firstWhere(
      (m) => m?.missionId == missionId,
      orElse: () => null,
    );

    if (mission == null) return false;
    if (!mission.isCompleted) return false;

    // 보상 지급
    await _grantRewards(mission.rewards);

    debugPrint('[EventManagement] Mission reward claimed: $missionId');

    return true;
  }

  /// 완료 보상 수령
  Future<bool> claimCompletionReward(String eventId) async {
    if (_playerData == null) return false;

    final event = _events.cast<GameEvent?>.firstWhere(
      (e) => e?.eventId == eventId,
      orElse: () => null,
    );

    if (event == null) return false;
    if (!_playerData!.isCompleted(eventId)) return false;
    if (_playerData!.claimedEvents.contains(eventId)) return false;

    // 보상 지급
    await _grantRewards(event.completionRewards);

    final claimed = Set<String>.from(_playerData!.claimedEvents);
    claimed.add(eventId);

    _playerData = PlayerEventData(
      userId: _playerData!.userId,
      participationCounts: _playerData!.participationCounts,
      missionProgress: _playerData!.missionProgress,
      claimedEvents: claimed,
      completedEvents: _playerData!.completedEvents,
    );

    await _savePlayerData();

    debugPrint('[EventManagement] Completion reward claimed: $eventId');

    return true;
  }

  Future<void> _grantRewards(List<EventReward> rewards) async {
    for (final reward in rewards) {
      debugPrint('[EventManagement] Granted: ${reward.name} x${reward.amount ?? reward.itemQuantity ?? 1}');
    }
  }

  /// 활성 이벤트 목록
  List<GameEvent> getActiveEvents() {
    return _events.where((e) => e.isActive).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 참여 가능 이벤트
  List<GameEvent> getParticipatableEvents({
    required int userLevel,
    List<String>? userItems,
    int? guildLevel,
  }) {
    return _events.where((e) =>
        e.isActive &&
        e.canParticipate(
          userLevel: userLevel,
          userItems: userItems,
          guildLevel: guildLevel,
          completedEvents: _playerData?.completedEvents,
        )
    ).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 이벤트 조회
  GameEvent? getEvent(String eventId) {
    return _events.cast<GameEvent?>.firstWhere(
      (e) => e?.eventId == eventId,
      orElse: () => null,
    );
  }

  /// 플레이어 이벤트 데이터
  PlayerEventData? getPlayerData() {
    return _playerData;
  }

  Future<void> _savePlayerData() async {
    if (_currentUserId == null || _playerData == null) return;

    final data = {
      'participationCounts': _playerData!.participationCounts,
      'claimedEvents': _playerData!.claimedEvents.toList(),
      'completedEvents': _playerData!.completedEvents.toList(),
    };

    await _prefs?.setString(
      'event_data_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _eventController.close();
    _missionController.close();
    _eventCheckTimer?.cancel();
  }
}

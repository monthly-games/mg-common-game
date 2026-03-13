import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이벤트 타입
enum EventType {
  login,              // 로그인 보상
  attendance,         // 출석 체크
  daily_mission,      // 일일 미션
  weekly_mission,     // 주간 미션
  limited_event,      // 한정 이벤트
  seasonal,           // 시즌 이벤트
  special_offer,      // 특별 상점
  community,          // 커뮤니티 이벤트
}

/// 보상 타입
enum RewardType {
  gold,
  gem,
  item,
  exp,
  character,
  skin,
  currency,
}

/// 이벤트 참여 상태
enum EventParticipationStatus {
  notStarted,
  inProgress,
  completed,
  claimed,
  expired,
}

/// 이벤트 보상
class EventReward {
  final String id;
  final String name;
  final RewardType type;
  final int amount;
  final String? itemId;
  final String? itemIconUrl;

  const EventReward({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.itemId,
    this.itemIconUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'amount': amount,
        'itemId': itemId,
        'itemIconUrl': itemIconUrl,
    };
}

/// 이벤트 미션
class EventMission {
  final String id;
  final String title;
  final String description;
  final int target;
  final int current;
  final List<EventReward> rewards;
  final EventParticipationStatus status;

  const EventMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.rewards,
    required this.status,
  });

  /// 진행률
  double get progress => target > 0 ? current / target : 0.0;

  /// 완료 여부
  bool get isCompleted => current >= target;

  /// 완료 가능 여부
  bool get canClaim => isCompleted && status != EventParticipationStatus.claimed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'current': current,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'status': status.name,
    };
}

/// 게임 이벤트
class GameEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final DateTime startTime;
  final DateTime endTime;
  final String? bannerUrl;
  final String? iconUrl;
  final List<EventMission> missions;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.bannerUrl,
    this.iconUrl,
    this.missions = const [],
    this.isActive = false,
    this.metadata,
  });

  /// 진행 중인지
  bool get isOngoing => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);

  /// 종료까지 남은 시간
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return startTime.difference(now);
    } else if (now.isBefore(endTime)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }
}

/// 출석 체크
class AttendanceChecker {
  final Map<String, List<DateTime>> _attendanceRecords = {};
  final List<EventReward> _dailyRewards = [
    const EventReward(
      id: 'day_1',
      name: '1일차 보상',
      type: RewardType.gold,
      amount: 100,
    ),
    const EventReward(
      id: 'day_2',
      name: '2일차 보상',
      type: RewardType.gold,
      amount: 200,
    ),
    const EventReward(
      id: 'day_3',
      name: '3일차 보상',
      type: RewardType.gold,
      amount: 300,
    ),
    const EventReward(
      id: 'day_7',
      name: '7일차 보상',
      type: RewardType.gem,
      amount: 50,
    ),
  ];

  /// 출석 체크
  Future<EventReward?> checkAttendance(String userId) async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    if (!_attendanceRecords.containsKey(userId)) {
      _attendanceRecords[userId] = [];
    }

    final records = _attendanceRecords[userId]!;

    // 이미 출석체크 했는지 확인
    final alreadyChecked = records.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);

    if (alreadyChecked) {
      return null;
    }

    // 출석 기록
    records.add(today);

    // 연속 출석 일수 계산
    final streak = _calculateStreak(records);

    // 보상 반환
    if (streak <= _dailyRewards.length) {
      return _dailyRewards[streak - 1];
    }

    // 7일 이후는 순환 보상
    final cycleIndex = (streak - 1) % _dailyRewards.length;
    return _dailyRewards[cycleIndex];
  }

  int _calculateStreak(List<DateTime> records) {
    if (records.isEmpty) return 0;

    int streak = 1;
    final today = records.last;

    for (int i = records.length - 2; i >= 0; i--) {
      final current = records[i + 1];
      final previous = records[i];

      final diff = current.difference(previous);

      if (diff.inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// 연속 출석 일수
  int getStreak(String userId) {
    final records = _attendanceRecords[userId];
    if (records == null || records.isEmpty) return 0;

    return _calculateStreak(records);
  }

  /// 이번 달 출석 일수
  int getMonthlyAttendance(String userId) {
    final records = _attendanceRecords[userId];
    if (records == null) return 0;

    final now = DateTime.now();
    return records.where((date) =>
        date.year == now.year &&
        date.month == now.month).length;
  }
}

/// 시즌 패스
class SeasonPass {
  final String id;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isPremium;
  final List<SeasonPassTier> freeTiers;
  final List<SeasonPassTier> premiumTiers;
  final int currentTier;

  const SeasonPass({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.isPremium = false,
    this.freeTiers = const [],
    this.premiumTiers = const [],
    this.currentTier = 0,
  });

  /// 남은 시간
  Duration? get timeRemaining {
    final now = DateTime.now();
    if (now.isBefore(endTime)) {
      return endTime.difference(now);
    }
    return null;
  }
}

/// 시즌 패스 티어
class SeasonPassTier {
  final int level;
  final EventReward freeReward;
  final EventReward? premiumReward;

  const SeasonPassTier({
    required this.level,
    required this.freeReward,
    this.premiumReward,
  });
}

/// 이벤트 관리자
class EventManager {
  static final EventManager _instance = EventManager._();
  static EventManager get instance => _instance;

  EventManager._();

  final Map<String, GameEvent> _events = {};
  final AttendanceChecker _attendanceChecker = AttendanceChecker();
  final List<SeasonPass> _seasonPasses = [];

  final StreamController<GameEvent> _eventController =
      StreamController<GameEvent>.broadcast();
  final StreamController<SeasonPass> _seasonController =
      StreamController<SeasonPass>.broadcast();

  Stream<GameEvent> get onEventUpdate => _eventController.stream;
  Stream<SeasonPass> get onSeasonUpdate => _seasonController.stream;

  SharedPreferences? _prefs;
  String? _userId;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _userId = _prefs?.getString('user_id');

    // 이벤트 로드
    _loadEvents();

    // 시즌 패스 로드
    _loadSeasonPasses();

    // 만료된 이벤트 정리
    _cleanupExpiredEvents();

    debugPrint('[Event] Initialized');
  }

  void _loadEvents() {
    final now = DateTime.now();

    _events.addAll({
      'login_event_2024': GameEvent(
        id: 'login_event_2024',
        name: '신규 환영 이벤트',
        description: '첫 로그인 시 특별 보상',
        type: EventType.login,
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now.add(const Duration(days: 30)),
        missions: [
          EventMission(
            id: 'login_1',
            title: '첫 로그인',
            description: '게임에 처음 로그인하세요',
            target: 1,
            current: 0,
            rewards: const [
              EventReward(
                id: 'login_reward',
                name: '환영 보상',
                type: RewardType.gold,
                amount: 1000,
              ),
            ],
            status: EventParticipationStatus.notStarted,
          ),
        ],
        isActive: true,
      ),
      'daily_missions': GameEvent(
        id: 'daily_missions',
        name: '일일 미션',
        description: '매일 새로운 미션을 완료하고 보상을 받으세요',
        type: EventType.daily_mission,
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        missions: [
          EventMission(
            id: 'play_3_games',
            title: '3게임 플레이',
            description: '3게임 플레이 완료',
            target: 3,
            current: 0,
            rewards: const [
              EventReward(
                id: 'mission_reward',
                name: '미션 완료 보상',
                type: RewardType.exp,
                amount: 100,
              ),
            ],
            status: EventParticipationStatus.notStarted,
          ),
        ],
        isActive: true,
      ),
    });
  }

  void _loadSeasonPasses() {
    final now = DateTime.now();

    _seasonPasses.add(
      SeasonPass(
        id: 'season_1',
        name: '시즌 1: 모험의 시작',
        description: '첫 번째 시즌이 시작됩니다',
        startTime: now.subtract(const Duration(days: 7)),
        endTime: now.add(const Duration(days: 23)),
        freeTiers: List.generate(
          50,
          (index) => SeasonPassTier(
            level: index + 1,
            freeReward: EventReward(
              id: 'free_tier_${index + 1}',
              name: '티어 ${index + 1} 보상',
              type: RewardType.gold,
              amount: 100 * (index + 1),
            ),
          ),
        ),
        premiumTiers: List.generate(
          50,
          (index) => SeasonPassTier(
            level: index + 1,
            freeReward: EventReward(
              id: 'free_tier_${index + 1}',
              name: '프리 티어 ${index + 1}',
              type: RewardType.gold,
              amount: 100 * (index + 1),
            ),
            premiumReward: EventReward(
              id: 'premium_tier_${index + 1}',
              name: '프리미엄 보상',
              type: RewardType.gem,
              amount: 10 * (index + 1),
            ),
          ),
        ),
      ),
    );
  }

  void _cleanupExpiredEvents() {
    final now = DateTime.now();

    _events.removeWhere((key, event) {
      if (now.isAfter(event.endTime)) {
        debugPrint('[Event] Removed expired event: ${event.id}');
        return true;
      }
      return false;
    });
  }

  /// 이벤트 목록 조회
  List<GameEvent> getEvents({EventType? type, bool? active}) {
    var events = _events.values.toList();

    if (type != null) {
      events = events.where((e) => e.type == type).toList();
    }

    if (active != null) {
      events = events.where((e) => e.isActive == active).toList();
    }

    return events;
  }

  /// 진행 중인 이벤트
  List<GameEvent> getOngoingEvents() {
    final now = DateTime.now();

    return _events.values
        .where((e) =>
            e.isActive &&
            now.isAfter(e.startTime) &&
            now.isBefore(e.endTime))
        .toList();
  }

  /// 미션 진행 업데이트
  Future<void> updateMissionProgress({
    required String eventId,
    required String missionId,
    required int progress,
  }) async {
    final event = _events[eventId];
    if (event == null) return;

    final missionIndex = event.missions.indexWhere((m) => m.id == missionId);
    if (missionIndex == -1) return;

    final mission = event.missions[missionIndex];

    final updated = EventMission(
      id: mission.id,
      title: mission.title,
      description: mission.description,
      target: mission.target,
      current: mission.current + progress,
      rewards: mission.rewards,
      status: (mission.current + progress) >= mission.target
          ? EventParticipationStatus.completed
          : EventParticipationStatus.inProgress,
    );

    // 실제로는 이벤트 내 미션 업데이트 (불변 객체라 별도 처리 필요)

    _eventController.add(event);

    debugPrint('[Event] Mission progress: $missionId - ${updated.current}/${updated.target}');
  }

  /// 보상 수령
  Future<bool> claimReward({
    required String eventId,
    required String missionId,
  }) async {
    final event = _events[eventId];
    if (event == null) return false;

    final mission = event.missions.firstWhere((m) => m.id == missionId);

    if (!mission.isCompleted || mission.status == EventParticipationStatus.claimed) {
      return false;
    }

    // 보상 지급
    for (final reward in mission.rewards) {
      await _grantReward(reward);
    }

    // 상태 업데이트 (실제로는 불변 객체 처리 필요)

    debugPrint('[Event] Reward claimed: $missionId');

    return true;
  }

  Future<void> _grantReward(EventReward reward) async {
    // 실제 보상 지급 로직
    debugPrint('[Event] Granted: ${reward.type.name} ${reward.amount}');
  }

  /// 출석 체크
  Future<EventReward?> checkAttendance() async {
    if (_userId == null) return null;

    return await _attendanceChecker.checkAttendance(_userId!);
  }

  /// 연속 출석 일수
  int getAttendanceStreak() {
    if (_userId == null) return 0;

    return _attendanceChecker.getStreak(_userId!);
  }

  /// 시즌 패스 목록
  List<SeasonPass> getSeasonPasses() {
    return _seasonPasses.toList();
  }

  /// 시즌 패스 구매
  Future<bool> purchaseSeasonPass(String seasonPassId) async {
    // 실제 구매 로직
    debugPrint('[Event] Season pass purchased: $seasonPassId');
    return true;
  }

  /// 시즌 패스 티어 보상 수령
  Future<bool> claimSeasonPassTier({
    required String seasonPassId,
    required int tier,
    bool usePremium = false,
  }) async {
    final seasonPass = _seasonPasses.firstWhere((s) => s.id == seasonPassId);

    if (tier > seasonPass.currentTier) return false;

    final tierData = usePremium
        ? seasonPass.premiumTiers[tier - 1]
        : seasonPass.freeTiers[tier - 1];

    if (tierData == null) return false;

    // 보상 지급
    await _grantReward(tierData.freeReward);

    if (usePremium && tierData.premiumReward != null) {
      await _grantReward(tierData.premiumReward!);
    }

    debugPrint('[Event] Season pass tier claimed: $tier');

    return true;
  }

  void setCurrentUser(String userId) {
    _userId = userId;
  }

  void dispose() {
    _eventController.close();
    _seasonController.close();
  }
}

/// 프로모션 배너
class PromoBanner {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? actionUrl;
  final DateTime? startTime;
  final DateTime? endTime;
  final int priority;
  final bool isActive;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.actionUrl,
    this.startTime,
    this.endTime,
    this.priority = 0,
    this.isActive = false,
  });

  /// 활성화 여부
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();

    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;

    return true;
  }
}

/// 프로모션 관리자
class PromoManager {
  static final PromoManager _instance = PromoManager._();
  static PromoManager get instance => _instance;

  PromoManager._();

  final List<PromoBanner> _banners = [];

  /// 배너 추가
  void addBanner(PromoBanner banner) {
    _banners.add(banner);
  }

  /// 활성 배너 조회
  List<PromoBanner> getActiveBanners() {
    final now = DateTime.now();

    return _banners
        .where((b) => b.isCurrentlyActive)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 배너 클릭
  void onBannerClick(PromoBanner banner) {
    debugPrint('[Promo] Banner clicked: ${banner.id}');

    if (banner.actionUrl != null) {
      // URL 열기 또는 액션 실행
    }
  }
}

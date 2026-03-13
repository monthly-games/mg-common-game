import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 구독 티어
enum SubscriptionTier {
  bronze,         // 브론즈
  silver,         // 실버
  gold,           // 골드
  platinum,       // 플래티넘
  diamond,        // 다이아몬드
}

/// 구독 상태
enum SubscriptionStatus {
  inactive,       // 비활성
  active,         // 활성
  paused,         // 일시정지
  expired,        // 만료
  pending,        // 결제 대기
  cancelled,      // 취소됨
}

/// 결제 주기
enum BillingCycle {
  weekly,         // 주간
  monthly,        // 월간
  quarterly,      // 분기
  yearly,         // 연간
}

/// 보상 타입
enum RewardType {
  currency,       // 통화
  item,           // 아이템
  boost,          // 부스트
  exclusive,      // 독점
  feature,        // 기능
}

/// 구독 보상
class SubscriptionReward {
  final RewardType type;
  final String id;
  final String name;
  final int? amount;
  final String? itemId;
  final int? itemQuantity;
  final Map<String, dynamic>? metadata;

  const SubscriptionReward({
    required this.type,
    required this.id,
    required this.name,
    this.amount,
    this.itemId,
    this.itemQuantity,
    this.metadata,
  });
}

/// 구독 플랜
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final SubscriptionTier tier;
  final BillingCycle cycle;
  final double price;
  final String currency;
  final List<SubscriptionReward> dailyRewards;
  final List<SubscriptionReward> weeklyRewards;
  final List<SubscriptionReward> monthlyRewards;
  final List<String> benefits;
  final String? icon;
  final String? bannerImage;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.cycle,
    required this.price,
    required this.currency,
    required this.dailyRewards,
    required this.weeklyRewards,
    required this.monthlyRewards,
    required this.benefits,
    this.icon,
    this.bannerImage,
    this.isPopular = false,
  });

  /// 월간 가격 환산
  double get monthlyPrice {
    switch (cycle) {
      case BillingCycle.weekly:
        return price * 4.33;
      case BillingCycle.monthly:
        return price;
      case BillingCycle.quarterly:
        return price / 3;
      case BillingCycle.yearly:
        return price / 12;
    }
  }

  /// 할인율 (월간 기준)
  double get discountRate {
    final monthlyPrice = this.monthlyPrice;
    final standardMonthlyPrice = 9.99; // 기준 가격
    if (standardMonthlyPrice == 0) return 0.0;
    return ((standardMonthlyPrice - monthlyPrice) / standardMonthlyPrice * 100).clamp(0, 100);
  }
}

/// 플레이어 구독
class PlayerSubscription {
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final BillingCycle cycle;
  final bool isAutoRenew;
  final int totalDays;
  final int remainingDays;
  final Set<String> claimedRewards;

  const PlayerSubscription({
    required this.userId,
    required this.planId,
    required this.status,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    required this.cycle,
    required this.isAutoRenew,
    required this.totalDays,
    required this.remainingDays,
    required this.claimedRewards,
  });

  /// 활성 상태
  bool get isActive {
    return status == SubscriptionStatus.active ||
        status == SubscriptionStatus.paused;
  }

  /// 만료까지 남은 시간
  Duration? get timeUntilExpiry {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// 진행률
  double get progress {
    if (totalDays == 0) return 0.0;
    return (totalDays - remainingDays) / totalDays;
  }

  /// 오늘 일일 보상 수령 가능
  bool get canClaimDaily {
    if (!isActive) return false;
    final today = DateTime.now().day;
    return !claimedRewards.contains('daily_$today');
  }

  /// 이번 주간 보상 수령 가능
  bool get canClaimWeekly {
    if (!isActive) return false;
    final week = _getWeekNumber(DateTime.now());
    return !claimedRewards.contains('weekly_$week');
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

/// 구독 관리자
class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._();
  static SubscriptionManager get instance => _instance;

  SubscriptionManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final List<SubscriptionPlan> _plans = [];
  PlayerSubscription? _playerSubscription;

  final StreamController<PlayerSubscription> _subscriptionController =
      StreamController<PlayerSubscription>.broadcast();
  final StreamController<List<SubscriptionReward>> _rewardController =
      StreamController<List<SubscriptionReward>>.broadcast();

  Stream<PlayerSubscription> get onSubscriptionUpdate => _subscriptionController.stream;
  Stream<List<SubscriptionReward>> get onRewardGrant => _rewardController.stream;

  Timer? _billingTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 플랜 로드
    _loadPlans();

    // 플레이어 구독 로드
    if (_currentUserId != null) {
      await _loadPlayerSubscription(_currentUserId!);
    }

    // 빌링 타이머 시작
    _startBillingTimer();

    debugPrint('[Subscription] Initialized');
  }

  void _loadPlans() {
    _plans.clear();

    // 브론즈 (주간)
    _plans.add(const SubscriptionPlan(
      id: 'bronze_weekly',
      name: '브론즈 (주간)',
      description: '기본 구독',
      tier: SubscriptionTier.bronze,
      cycle: BillingCycle.weekly,
      price: 2.99,
      currency: 'USD',
      dailyRewards: [
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 100,
        ),
      ],
      weeklyRewards: [
        SubscriptionReward(
          type: RewardType.item,
          id: 'common_box',
          name: '일반 상자',
          itemQuantity: 1,
        ),
      ],
      monthlyRewards: [],
      benefits: [
        '광고 제거',
        '일일 보상',
        '주간 보너스',
      ],
    ));

    // 실버 (월간)
    _plans.add(const SubscriptionPlan(
      id: 'silver_monthly',
      name: '실버 (월간)',
      description: '인기 구독',
      tier: SubscriptionTier.silver,
      cycle: BillingCycle.monthly,
      price: 9.99,
      currency: 'USD',
      dailyRewards: [
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 200,
        ),
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gems',
          name: '젬',
          amount: 10,
        ),
      ],
      weeklyRewards: [
        SubscriptionReward(
          type: RewardType.item,
          id: 'rare_box',
          name: '희귀 상자',
          itemQuantity: 1,
        ),
      ],
      monthlyRewards: [
        SubscriptionReward(
          type: RewardType.boost,
          id: 'exp_boost',
          name: '경험치 부스트 (3일)',
        ),
      ],
      benefits: [
        '브론즈 혜택 모두 포함',
        '일일 젤 10개',
        '주간 희귀 상자',
        '월간 부스트',
      ],
      isPopular: true,
    ));

    // 골드 (월간)
    _plans.add(const SubscriptionPlan(
      id: 'gold_monthly',
      name: '골드 (월간)',
      description: '프리미엄 구독',
      tier: SubscriptionTier.gold,
      cycle: BillingCycle.monthly,
      price: 19.99,
      currency: 'USD',
      dailyRewards: [
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 500,
        ),
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gems',
          name: '젬',
          amount: 25,
        ),
      ],
      weeklyRewards: [
        SubscriptionReward(
          type: RewardType.item,
          id: 'epic_box',
          name: '에픽 상자',
          itemQuantity: 1,
        ),
      ],
      monthlyRewards: [
        SubscriptionReward(
          type: RewardType.exclusive,
          id: 'exclusive_skin',
          name: '독점 스킨',
        ),
        SubscriptionReward(
          type: RewardType.boost,
          id: 'exp_boost',
          name: '경험치 부스트 (7일)',
        ),
      ],
      benefits: [
        '실버 혜택 모두 포함',
        '일일 젤 25개',
        '주간 에픽 상자',
        '월간 독점 스킨',
        '프리미엄 고객 지원',
      ],
    ));

    // 플래티넘 (연간)
    _plans.add(const SubscriptionPlan(
      id: 'platinum_yearly',
      name: '플래티넘 (연간)',
      description: '최고의 혜택',
      tier: SubscriptionTier.platinum,
      cycle: BillingCycle.yearly,
      price: 199.99,
      currency: 'USD',
      dailyRewards: [
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 1000,
        ),
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gems',
          name: '젬',
          amount: 50,
        ),
      ],
      weeklyRewards: [
        SubscriptionReward(
          type: RewardType.item,
          id: 'legendary_box',
          name: '레전더리 상자',
          itemQuantity: 1,
        ),
      ],
      monthlyRewards: [
        SubscriptionReward(
          type: RewardType.exclusive,
          id: 'exclusive_title',
          name: 'VIP 칭호',
        ),
        SubscriptionReward(
          type: RewardType.boost,
          id: 'all_boost',
          name: '모든 부스트 (7일)',
        ),
      ],
      benefits: [
        '골드 혜택 모두 포함',
        '일일 젤 50개',
        '주간 레전더리 상자',
        '월간 VIP 칭호',
        '전용 채널',
        '우선 지원',
        '연간 17% 할인',
      ],
    ));

    // 다이아몬드 (월간)
    _plans.add(const SubscriptionPlan(
      id: 'diamond_monthly',
      name: '다이아몬드 (월간)',
      description: '최상위 등급',
      tier: SubscriptionTier.diamond,
      cycle: BillingCycle.monthly,
      price: 49.99,
      currency: 'USD',
      dailyRewards: [
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gold',
          name: '골드',
          amount: 2000,
        ),
        SubscriptionReward(
          type: RewardType.currency,
          id: 'gems',
          name: '젬',
          amount: 100,
        ),
      ],
      weeklyRewards: [
        SubscriptionReward(
          type: RewardType.item,
          id: 'mythic_box',
          name: '미식 상자',
          itemQuantity: 1,
        ),
      ],
      monthlyRewards: [
        SubscriptionReward(
          type: RewardType.exclusive,
          id: 'exclusive_character',
          name: '독점 캐릭터',
        ),
      ],
      benefits: [
        '모든 혜택 포함',
        '일일 젤 100개',
        '주간 미식 상자',
        '월간 독점 캐릭터',
        '전용 이벤트',
        '최우선 지원',
      ],
    ));
  }

  Future<void> _loadPlayerSubscription(String userId) async {
    final json = _prefs?.getString('subscription_$userId');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[Subscription] Error loading data: $e');
      }
    }

    // 기본 구독 없음
    _playerSubscription = null;
  }

  void _startBillingTimer() {
    _billingTimer?.cancel();
    _billingTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkBilling();
    });
  }

  void _checkBilling() {
    if (_playerSubscription == null) return;
    if (!_playerSubscription!.isActive) return;

    // 다음 빌링일 확인
    if (_playerSubscription!.nextBillingDate != null) {
      final now = DateTime.now();
      if (now.isAfter(_playerSubscription!.nextBillingDate!)) {
        // 자동 갱신
        if (_playerSubscription!.isAutoRenew) {
          _renewSubscription();
        } else {
          // 만료 처리
          _expireSubscription();
        }
      }
    }
  }

  void _renewSubscription() {
    if (_playerSubscription == null) return;

    final plan = _plans.cast<SubscriptionPlan?>.firstWhere(
      (p) => p?.id == _playerSubscription!.planId,
      orElse: () => null,
    );

    if (plan == null) return;

    // 다음 빌링일 계산
    DateTime nextBilling;
    switch (plan.cycle) {
      case BillingCycle.weekly:
        nextBilling = DateTime.now().add(const Duration(days: 7));
        break;
      case BillingCycle.monthly:
        nextBilling = DateTime.now().add(const Duration(days: 30));
        break;
      case BillingCycle.quarterly:
        nextBilling = DateTime.now().add(const Duration(days: 90));
        break;
      case BillingCycle.yearly:
        nextBilling = DateTime.now().add(const Duration(days: 365));
        break;
    }

    final updated = PlayerSubscription(
      userId: _playerSubscription!.userId,
      planId: _playerSubscription!.planId,
      status: SubscriptionStatus.active,
      startDate: _playerSubscription!.startDate,
      endDate: _playerSubscription!.endDate,
      nextBillingDate: nextBilling,
      cycle: _playerSubscription!.cycle,
      isAutoRenew: _playerSubscription!.isAutoRenew,
      totalDays: _playerSubscription!.totalDays,
      remainingDays: _calculateRemainingDays(nextBilling),
      claimedRewards: {}, // 새로운 주기 시작
    );

    _playerSubscription = updated;
    _subscriptionController.add(updated);

    debugPrint('[Subscription] Renewed: ${plan.name}');
  }

  void _expireSubscription() {
    if (_playerSubscription == null) return;

    final updated = PlayerSubscription(
      userId: _playerSubscription!.userId,
      planId: _playerSubscription!.planId,
      status: SubscriptionStatus.expired,
      startDate: _playerSubscription!.startDate,
      endDate: DateTime.now(),
      nextBillingDate: null,
      cycle: _playerSubscription!.cycle,
      isAutoRenew: false,
      totalDays: _playerSubscription!.totalDays,
      remainingDays: 0,
      claimedRewards: _playerSubscription!.claimedRewards,
    );

    _playerSubscription = updated;
    _subscriptionController.add(updated);

    _savePlayerSubscription();

    debugPrint('[Subscription] Expired');
  }

  int _calculateRemainingDays(DateTime endDate) {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  /// 구독 시작
  Future<bool> subscribe(String planId) async {
    if (_currentUserId == null) return false;

    final plan = _plans.cast<SubscriptionPlan?>.firstWhere(
      (p) => p?.id == planId,
      orElse: () => null,
    );

    if (plan == null) return false;

    // 결제 처리
    final paymentSuccess = await _processPayment(plan);
    if (!paymentSuccess) return false;

    // 시작일/종료일 계산
    final now = DateTime.now();
    DateTime endDate;
    DateTime nextBilling;
    var totalDays = 30;

    switch (plan.cycle) {
      case BillingCycle.weekly:
        endDate = now.add(const Duration(days: 7));
        nextBilling = endDate;
        totalDays = 7;
        break;
      case BillingCycle.monthly:
        endDate = now.add(const Duration(days: 30));
        nextBilling = endDate;
        totalDays = 30;
        break;
      case BillingCycle.quarterly:
        endDate = now.add(const Duration(days: 90));
        nextBilling = endDate;
        totalDays = 90;
        break;
      case BillingCycle.yearly:
        endDate = now.add(const Duration(days: 365));
        nextBilling = endDate;
        totalDays = 365;
        break;
    }

    final subscription = PlayerSubscription(
      userId: _currentUserId!,
      planId: planId,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: endDate,
      nextBillingDate: nextBilling,
      cycle: plan.cycle,
      isAutoRenew: true,
      totalDays: totalDays,
      remainingDays: totalDays,
      claimedRewards: {},
    );

    _playerSubscription = subscription;
    _subscriptionController.add(subscription);

    await _savePlayerSubscription();

    debugPrint('[Subscription] Started: ${plan.name}');

    return true;
  }

  Future<bool> _processPayment(SubscriptionPlan plan) async {
    // 실제 결제 처리 (IAP 연동)
    return true;
  }

  /// 구독 취소
  Future<bool> cancelSubscription() async {
    if (_playerSubscription == null) return false;
    if (!_playerSubscription!.isActive) return false;

    final updated = PlayerSubscription(
      userId: _playerSubscription!.userId,
      planId: _playerSubscription!.planId,
      status: SubscriptionStatus.cancelled,
      startDate: _playerSubscription!.startDate,
      endDate: _playerSubscription!.endDate,
      nextBillingDate: null,
      cycle: _playerSubscription!.cycle,
      isAutoRenew: false,
      totalDays: _playerSubscription!.totalDays,
      remainingDays: _playerSubscription!.remainingDays,
      claimedRewards: _playerSubscription!.claimedRewards,
    );

    _playerSubscription = updated;
    _subscriptionController.add(updated);

    await _savePlayerSubscription();

    debugPrint('[Subscription] Cancelled');

    return true;
  }

  /// 일일 보상 수령
  Future<bool> claimDailyReward() async {
    if (_playerSubscription == null) return false;
    if (!_playerSubscription!.canClaimDaily) return false;

    final plan = _plans.cast<SubscriptionPlan?>.firstWhere(
      (p) => p?.id == _playerSubscription!.planId,
      orElse: () => null,
    );

    if (plan == null) return false;

    final today = DateTime.now().day;
    final claimed = Set<String>.from(_playerSubscription!.claimedRewards);
    claimed.add('daily_$today');

    final updated = PlayerSubscription(
      userId: _playerSubscription!.userId,
      planId: _playerSubscription!.planId,
      status: _playerSubscription!.status,
      startDate: _playerSubscription!.startDate,
      endDate: _playerSubscription!.endDate,
      nextBillingDate: _playerSubscription!.nextBillingDate,
      cycle: _playerSubscription!.cycle,
      isAutoRenew: _playerSubscription!.isAutoRenew,
      totalDays: _playerSubscription!.totalDays,
      remainingDays: _playerSubscription!.remainingDays,
      claimedRewards: claimed,
    );

    _playerSubscription = updated;
    _subscriptionController.add(updated);

    // 보상 지급
    await _grantRewards(plan.dailyRewards);

    debugPrint('[Subscription] Daily reward claimed');

    await _savePlayerSubscription();

    return true;
  }

  /// 주간 보상 수령
  Future<bool> claimWeeklyReward() async {
    if (_playerSubscription == null) return false;
    if (!_playerSubscription!.canClaimWeekly) return false;

    final plan = _plans.cast<SubscriptionPlan?>.firstWhere(
      (p) => p?.id == _playerSubscription!.planId,
      orElse: () => null,
    );

    if (plan == null) return false;

    final week = _getWeekNumber(DateTime.now());
    final claimed = Set<String>.from(_playerSubscription!.claimedRewards);
    claimed.add('weekly_$week');

    final updated = PlayerSubscription(
      userId: _playerSubscription!.userId,
      planId: _playerSubscription!.planId,
      status: _playerSubscription!.status,
      startDate: _playerSubscription!.startDate,
      endDate: _playerSubscription!.endDate,
      nextBillingDate: _playerSubscription!.nextBillingDate,
      cycle: _playerSubscription!.cycle,
      isAutoRenew: _playerSubscription!.isAutoRenew,
      totalDays: _playerSubscription!.totalDays,
      remainingDays: _playerSubscription!.remainingDays,
      claimedRewards: claimed,
    );

    _playerSubscription = updated;
    _subscriptionController.add(updated);

    // 보상 지급
    await _grantRewards(plan.weeklyRewards);

    debugPrint('[Subscription] Weekly reward claimed');

    await _savePlayerSubscription();

    return true;
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse('D'); // 간단화
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Future<void> _grantRewards(List<SubscriptionReward> rewards) async {
    // 실제 보상 지급
    for (final reward in rewards) {
      debugPrint('[Subscription] Granted: ${reward.name} x${reward.amount ?? reward.itemQuantity ?? 1}');
    }
    _rewardController.add(rewards);
  }

  /// 플랜 목록
  List<SubscriptionPlan> getPlans() {
    return _plans.toList();
  }

  /// 현재 구독
  PlayerSubscription? getCurrentSubscription() {
    return _playerSubscription;
  }

  /// 플랜 조회
  SubscriptionPlan? getPlan(String planId) {
    return _plans.cast<SubscriptionPlan?>.firstWhere(
      (p) => p?.id == planId,
      orElse: () => null,
    );
  }

  Future<void> _savePlayerSubscription() async {
    if (_currentUserId == null || _playerSubscription == null) return;

    final data = {
      'planId': _playerSubscription!.planId,
      'status': _playerSubscription!.status.name,
      'startDate': _playerSubscription!.startDate?.toIso8601String(),
      'endDate': _playerSubscription!.endDate?.toIso8601String(),
      'isAutoRenew': _playerSubscription!.isAutoRenew,
      'claimedRewards': _playerSubscription!.claimedRewards.toList(),
    };

    await _prefs?.setString(
      'subscription_$_currentUserId',
      jsonEncode(data),
    );
  }

  void dispose() {
    _subscriptionController.close();
    _rewardController.close();
    _billingTimer?.cancel();
  }
}

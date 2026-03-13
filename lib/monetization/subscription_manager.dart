import 'dart:async';
import 'package:flutter/material.dart';

enum SubscriptionStatus {
  inactive,
  active,
  expired,
  cancelled,
  pending,
  paused,
  inGracePeriod,
}

enum SubscriptionPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
  lifetime,
}

enum SubscriptionTier {
  basic,
  premium,
  platinum,
  enterprise,
}

class SubscriptionPlan {
  final String planId;
  final String name;
  final String description;
  final SubscriptionTier tier;
  final double price;
  final String currencyCode;
  final SubscriptionPeriod period;
  final Duration trialDuration;
  final Map<String, dynamic> benefits;
  final bool isPopular;

  const SubscriptionPlan({
    required this.planId,
    required this.name,
    required this.description,
    required this.tier,
    required this.price,
    required this.currencyCode,
    required this.period,
    required this.trialDuration,
    required this.benefits,
    required this.isPopular,
  });

  Duration get periodDuration {
    switch (period) {
      case SubscriptionPeriod.weekly:
        return const Duration(days: 7);
      case SubscriptionPeriod.monthly:
        return const Duration(days: 30);
      case SubscriptionPeriod.quarterly:
        return const Duration(days: 90);
      case SubscriptionPeriod.yearly:
        return const Duration(days: 365);
      case SubscriptionPeriod.lifetime:
        return const Duration(days: 36500);
    }
  }

  double get monthlyPrice {
    switch (period) {
      case SubscriptionPeriod.weekly:
        return price * 4.33;
      case SubscriptionPeriod.monthly:
        return price;
      case SubscriptionPeriod.quarterly:
        return price / 3;
      case SubscriptionPeriod.yearly:
        return price / 12;
      case SubscriptionPeriod.lifetime:
        return price / 12;
    }
  }
}

class UserSubscription {
  final String subscriptionId;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? cancelDate;
  final DateTime? trialEndDate;
  final bool autoRenew;
  final Map<String, dynamic> metadata;

  const UserSubscription({
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.cancelDate,
    this.trialEndDate,
    required this.autoRenew,
    required this.metadata,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isTrialing => trialEndDate != null && DateTime.now().isBefore(trialEndDate!);
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  Duration get remainingDuration {
    if (endDate == null) return Duration.zero;
    return endDate!.difference(DateTime.now());
  }
  bool get shouldRenew {
    if (!autoRenew) return false;
    if (isCancelled) return false;
    if (isExpired) return false;
    return true;
  }
}

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._();
  static SubscriptionManager get instance => _instance;

  SubscriptionManager._();

  final Map<String, SubscriptionPlan> _plans = {};
  final Map<String, UserSubscription> _subscriptions = {};
  final StreamController<SubscriptionEvent> _eventController = StreamController.broadcast();
  Timer? _renewalTimer;

  Stream<SubscriptionEvent> get onSubscriptionEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadPlans();
    _startRenewalTimer();
  }

  Future<void> _loadPlans() async {
    final plans = [
      SubscriptionPlan(
        planId: 'basic_monthly',
        name: 'Basic Monthly',
        description: 'Basic features monthly',
        tier: SubscriptionTier.basic,
        price: 4.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.monthly,
        trialDuration: const Duration(days: 7),
        benefits: {
          'features': ['basic_1', 'basic_2'],
          'maxProjects': 5,
        },
        isPopular: false,
      ),
      SubscriptionPlan(
        planId: 'premium_monthly',
        name: 'Premium Monthly',
        description: 'Premium features monthly',
        tier: SubscriptionTier.premium,
        price: 9.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.monthly,
        trialDuration: const Duration(days: 14),
        benefits: {
          'features': ['premium_1', 'premium_2', 'premium_3'],
          'maxProjects': 20,
          'prioritySupport': true,
        },
        isPopular: true,
      ),
      SubscriptionPlan(
        planId: 'premium_yearly',
        name: 'Premium Yearly',
        description: 'Premium features yearly (2 months free)',
        tier: SubscriptionTier.premium,
        price: 99.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.yearly,
        trialDuration: const Duration(days: 14),
        benefits: {
          'features': ['premium_1', 'premium_2', 'premium_3'],
          'maxProjects': 20,
          'prioritySupport': true,
        },
        isPopular: true,
      ),
      SubscriptionPlan(
        planId: 'platinum_monthly',
        name: 'Platinum Monthly',
        description: 'Platinum features monthly',
        tier: SubscriptionTier.platinum,
        price: 19.99,
        currencyCode: 'USD',
        period: SubscriptionPeriod.monthly,
        trialDuration: const Duration(days: 14),
        benefits: {
          'features': ['platinum_1', 'platinum_2', 'platinum_3', 'platinum_4'],
          'maxProjects': 100,
          'prioritySupport': true,
          'earlyAccess': true,
        },
        isPopular: false,
      ),
    ];

    for (final plan in plans) {
      _plans[plan.planId] = plan;
    }
  }

  void _startRenewalTimer() {
    _renewalTimer?.cancel();
    _renewalTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkRenewals(),
    );
  }

  Future<void> _checkRenewals() async {
    final now = DateTime.now();

    for (final subscription in _subscriptions.values) {
      if (subscription.shouldRenew && subscription.endDate != null) {
        if (now.isAfter(subscription.endDate!)) {
          await _renewSubscription(subscription.subscriptionId);
        }
      } else if (subscription.endDate != null && now.isAfter(subscription.endDate!)) {
        await _expireSubscription(subscription.subscriptionId);
      }
    }
  }

  List<SubscriptionPlan> getPlans() {
    return _plans.values.toList();
  }

  List<SubscriptionPlan> getPlansByTier(SubscriptionTier tier) {
    return _plans.values
        .where((plan) => plan.tier == tier)
        .toList();
  }

  SubscriptionPlan? getPlan(String planId) {
    return _plans[planId];
  }

  Future<UserSubscription> subscribe({
    required String userId,
    required String planId,
    bool startTrial = false,
  }) async {
    final plan = _plans[planId];
    if (plan == null) {
      throw Exception('Plan not found: $planId');
    }

    final now = DateTime.now();
    final startDate = startTrial ? now : now;
    final trialEndDate = startTrial ? now.add(plan.trialDuration) : null;
    final endDate = startTrial
        ? now.add(plan.trialDuration).add(plan.periodDuration)
        : now.add(plan.periodDuration);

    final subscription = UserSubscription(
      subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      planId: planId,
      status: SubscriptionStatus.active,
      startDate: startDate,
      endDate: endDate,
      trialEndDate: trialEndDate,
      autoRenew: true,
      metadata: {},
    );

    _subscriptions[subscription.subscriptionId] = subscription;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.subscribed,
      subscriptionId: subscription.subscriptionId,
      userId: userId,
      planId: planId,
      timestamp: DateTime.now(),
    ));

    return subscription;
  }

  Future<bool> cancelSubscription({
    required String subscriptionId,
    required String userId,
  }) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;
    if (subscription.userId != userId) return false;

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: subscription.planId,
      status: SubscriptionStatus.cancelled,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      cancelDate: DateTime.now(),
      trialEndDate: subscription.trialEndDate,
      autoRenew: false,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.cancelled,
      subscriptionId: subscriptionId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> renewSubscription(String subscriptionId) async {
    return await _renewSubscription(subscriptionId);
  }

  Future<bool> _renewSubscription(String subscriptionId) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;

    final plan = _plans[subscription.planId];
    if (plan == null) return false;

    final newEndDate = (subscription.endDate ?? DateTime.now()).add(plan.periodDuration);

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: subscription.planId,
      status: SubscriptionStatus.active,
      startDate: subscription.startDate,
      endDate: newEndDate,
      cancelDate: subscription.cancelDate,
      trialEndDate: subscription.trialEndDate,
      autoRenew: subscription.autoRenew,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.renewed,
      subscriptionId: subscriptionId,
      userId: subscription.userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> _expireSubscription(String subscriptionId) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: subscription.planId,
      status: SubscriptionStatus.expired,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      cancelDate: subscription.cancelDate,
      trialEndDate: subscription.trialEndDate,
      autoRenew: subscription.autoRenew,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.expired,
      subscriptionId: subscriptionId,
      userId: subscription.userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> upgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
    required String userId,
  }) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;
    if (subscription.userId != userId) return false;

    final newPlan = _plans[newPlanId];
    if (newPlan == null) return false;

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: newPlanId,
      status: SubscriptionStatus.active,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      cancelDate: subscription.cancelDate,
      trialEndDate: subscription.trialEndDate,
      autoRenew: subscription.autoRenew,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.upgraded,
      subscriptionId: subscriptionId,
      userId: userId,
      planId: newPlanId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> pauseSubscription({
    required String subscriptionId,
    required String userId,
  }) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;
    if (subscription.userId != userId) return false;

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: subscription.planId,
      status: SubscriptionStatus.paused,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      cancelDate: subscription.cancelDate,
      trialEndDate: subscription.trialEndDate,
      autoRenew: false,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.paused,
      subscriptionId: subscriptionId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> resumeSubscription({
    required String subscriptionId,
    required String userId,
  }) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return false;
    if (subscription.userId != userId) return false;

    final updated = UserSubscription(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      planId: subscription.planId,
      status: SubscriptionStatus.active,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      cancelDate: subscription.cancelDate,
      trialEndDate: subscription.trialEndDate,
      autoRenew: true,
      metadata: subscription.metadata,
    );

    _subscriptions[subscriptionId] = updated;

    _eventController.add(SubscriptionEvent(
      type: SubscriptionEventType.resumed,
      subscriptionId: subscriptionId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  UserSubscription? getUserSubscription(String userId) {
    return _subscriptions.values
        .where((sub) => sub.userId == userId)
        .FirstOrDefault((s) => true);
  }

  List<UserSubscription> getUserSubscriptions(String userId) {
    return _subscriptions.values
        .where((sub) => sub.userId == userId)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  bool hasActiveSubscription(String userId) {
    final subscription = getUserSubscription(userId);
    return subscription != null && subscription.isActive;
  }

  bool hasTrialAvailable(String userId) {
    final subscriptions = getUserSubscriptions(userId);
    return !subscriptions.any((sub) => sub.trialEndDate != null);
  }

  Map<String, dynamic> getSubscriptionStats() {
    final total = _subscriptions.length;
    final active = _subscriptions.values.where((s) => s.isActive).length;
    final cancelled = _subscriptions.values.where((s) => s.isCancelled).length;
    final expired = _subscriptions.values.where((s) => s.isExpired).length;
    final trialing = _subscriptions.values.where((s) => s.isTrialing).length;

    return {
      'total': total,
      'active': active,
      'cancelled': cancelled,
      'expired': expired,
      'trialing': trialing,
      'activeRate': total > 0 ? active / total : 0,
    };
  }

  Map<String, int> getPlanDistribution() {
    final distribution = <String, int>{};

    for (final subscription in _subscriptions.values) {
      distribution[subscription.planId] = (distribution[subscription.planId] ?? 0) + 1;
    }

    return distribution;
  }

  void dispose() {
    _renewalTimer?.cancel();
    _eventController.close();
  }
}

class SubscriptionEvent {
  final SubscriptionEventType type;
  final String? subscriptionId;
  final String? userId;
  final String? planId;
  final DateTime timestamp;

  const SubscriptionEvent({
    required this.type,
    this.subscriptionId,
    this.userId,
    this.planId,
    required this.timestamp,
  });
}

enum SubscriptionEventType {
  subscribed,
  cancelled,
  renewed,
  expired,
  upgraded,
  downgraded,
  paused,
  resumed,
}

extension ListExtensions<T> on List<T> {
  T? FirstOrDefault(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mg_common_game/analytics/analytics_manager.dart';

/// 수익 이벤트
class RevenueEvent {
  final String type; // 'ad_impression', 'purchase', 'subscription'
  final double amount;
  final String currency;
  final String? itemId;
  final String? itemName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const RevenueEvent({
    required this.type,
    required this.amount,
    required this.currency,
    this.itemId,
    this.itemName,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'currency': currency,
        'itemId': itemId,
        'itemName': itemName,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory RevenueEvent.fromJson(Map<String, dynamic> json) => RevenueEvent(
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        itemId: json['itemId'] as String?,
        itemName: json['itemName'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      );
}

/// 일일 수익 요약
class DailyRevenueSummary {
  final DateTime date;
  final double totalRevenue;
  final int adImpressions;
  final double adRevenue;
  final int purchases;
  final double purchaseRevenue;
  final int subscriptions;
  final double subscriptionRevenue;

  const DailyRevenueSummary({
    required this.date,
    required this.totalRevenue,
    required this.adImpressions,
    required this.adRevenue,
    required this.purchases,
    required this.purchaseRevenue,
    required this.subscriptions,
    required this.subscriptionRevenue,
  });

  double get arpu => adImpressions > 0 ? totalRevenue / adImpressions : 0;
}

/// 수익 추적 매니저
class RevenueTracker {
  static final RevenueTracker _instance = RevenueTracker._();
  static RevenueTracker get instance => _instance;

  RevenueTracker._();

  // ============================================
  // 상태
  // ============================================
  final List<RevenueEvent> _events = [];
  final Map<String, double> _revenueBySource = {};
  final Map<DateTime, DailyRevenueSummary> _dailySummaries = {};

  final StreamController<RevenueEvent> _eventController =
      StreamController<RevenueEvent>.broadcast();
  final StreamController<DailyRevenueSummary> _summaryController =
      StreamController<DailyRevenueSummary>.broadcast();

  double _totalRevenue = 0;
  int _totalAdImpressions = 0;
  int _totalPurchases = 0;
  int _totalSubscriptions = 0;

  // Getters
  List<RevenueEvent> get events => List.unmodifiable(_events);
  double get totalRevenue => _totalRevenue;
  int get totalAdImpressions => _totalAdImpressions;
  int get totalPurchases => _totalPurchases;
  int get totalSubscriptions => _totalSubscriptions;
  Stream<RevenueEvent> get onRevenueEvent => _eventController.stream;
  Stream<DailyRevenueSummary> get onDailySummary => _summaryController.stream;

  // ============================================
  // 수익 추적
  // ============================================

  /// 광고 수익 추적
  Future<void> trackAdImpression({
    required double amount,
    required String adUnitId,
    required String adFormat, // 'banner', 'interstitial', 'rewarded'
    required String currency,
  }) async {
    final event = RevenueEvent(
      type: 'ad_impression',
      amount: amount,
      currency: currency,
      itemId: adUnitId,
      itemName: adFormat,
      timestamp: DateTime.now(),
      metadata: {
        'adFormat': adFormat,
        'adUnitId': adUnitId,
      },
    );

    _addEvent(event);

    // 애널리틱스에 전송
    await AnalyticsManager.instance.logEvent('ad_impression', parameters: {
      'ad_unit_id': adUnitId,
      'ad_format': adFormat,
      'revenue': amount,
      'currency': currency,
    });

    debugPrint('[RevenueTracker] Ad impression: $amount $currency');
  }

  /// 구매 수익 추적
  Future<void> trackPurchase({
    required double amount,
    required String productId,
    required String productName,
    required String currency,
    String? transactionId,
  }) async {
    final event = RevenueEvent(
      type: 'purchase',
      amount: amount,
      currency: currency,
      itemId: productId,
      itemName: productName,
      timestamp: DateTime.now(),
      metadata: {
        'transactionId': transactionId,
      },
    );

    _addEvent(event);

    // 애널리틱스에 구매 이벤트 전송
    await AnalyticsManager.instance.logPurchase(
      itemId: productId,
      price: amount.toInt(),
      currency: currency,
    );

    debugPrint('[RevenueTracker] Purchase: $productName ($amount $currency)');
  }

  /// 구독 수익 추적
  Future<void> trackSubscription({
    required double amount,
    required String subscriptionId,
    required String planName,
    required String currency,
    required String billingPeriod, // 'monthly', 'yearly'
  }) async {
    final event = RevenueEvent(
      type: 'subscription',
      amount: amount,
      currency: currency,
      itemId: subscriptionId,
      itemName: planName,
      timestamp: DateTime.now(),
      metadata: {
        'billingPeriod': billingPeriod,
      },
    );

    _addEvent(event);

    // 애널리틱스에 구독 이벤트 전송
    await AnalyticsManager.instance.logEvent('subscription_purchased', parameters: {
      'subscription_id': subscriptionId,
      'plan_name': planName,
      'revenue': amount,
      'currency': currency,
      'billing_period': billingPeriod,
    });

    debugPrint('[RevenueTracker] Subscription: $planName ($amount $currency)');
  }

  void _addEvent(RevenueEvent event) {
    _events.add(event);
    _eventController.add(event);

    _totalRevenue += event.amount;

    // 소스별 수익 집계
    final sourceKey = '${event.type}_${event.itemId ?? "unknown"}';
    _revenueBySource[sourceKey] =
        (_revenueBySource[sourceKey] ?? 0) + event.amount;

    // 카운터 업데이트
    switch (event.type) {
      case 'ad_impression':
        _totalAdImpressions++;
        break;
      case 'purchase':
        _totalPurchases++;
        break;
      case 'subscription':
        _totalSubscriptions++;
        break;
    }

    // 일일 요약 업데이트
    _updateDailySummary();
  }

  /// 일일 요약 생성
  void _updateDailySummary() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // 오늘의 이벤트 필터링
    final todayEvents = _events.where((e) {
      final eventDate = DateTime(
        e.timestamp.year,
        e.timestamp.month,
        e.timestamp.day,
      );
      return eventDate.isAtSameMomentAs(today);
    }).toList();

    // 요약 계산
    double adRevenue = 0;
    double purchaseRevenue = 0;
    double subscriptionRevenue = 0;
    int adImpressions = 0;
    int purchases = 0;
    int subscriptions = 0;

    for (final event in todayEvents) {
      switch (event.type) {
        case 'ad_impression':
          adRevenue += event.amount;
          adImpressions++;
          break;
        case 'purchase':
          purchaseRevenue += event.amount;
          purchases++;
          break;
        case 'subscription':
          subscriptionRevenue += event.amount;
          subscriptions++;
          break;
      }
    }

    final summary = DailyRevenueSummary(
      date: today,
      totalRevenue: adRevenue + purchaseRevenue + subscriptionRevenue,
      adImpressions: adImpressions,
      adRevenue: adRevenue,
      purchases: purchases,
      purchaseRevenue: purchaseRevenue,
      subscriptions: subscriptions,
      subscriptionRevenue: subscriptionRevenue,
    );

    _dailySummaries[today] = summary;
    _summaryController.add(summary);
  }

  // ============================================
  // 보고서 생성
  // ============================================

  /// 일일 수익 리포트
  DailyRevenueSummary? getDailySummary(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _dailySummaries[key];
  }

  /// 주간 수익 리포트
  double getWeeklyRevenue({DateTime? startDate}) {
    final now = startDate ?? DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _events
        .where((e) => e.timestamp.isAfter(weekAgo) && e.timestamp.isBefore(now))
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// 월간 수익 리포트
  double getMonthlyRevenue({DateTime? startDate}) {
    final now = startDate ?? DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    return _events
        .where((e) => e.timestamp.isAfter(monthAgo) && e.timestamp.isBefore(now))
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// 소스별 수익 분석
  Map<String, double> getRevenueBySource() {
    return Map.unmodifiable(_revenueBySource);
  }

  /// 최고 수익 상품
  List<MapEntry<String, double>> getTopRevenueItems({int limit = 10}) {
    final itemRevenue = <String, double>{};

    for (final event in _events) {
      if (event.itemId != null) {
        itemRevenue[event.itemId!] =
            (itemRevenue[event.itemId!] ?? 0) + event.amount;
      }
    }

    final entries = itemRevenue.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).toList();
  }

  /// 수익 트렌드 분석
  Map<String, dynamic> getRevenueTrends() {
    final now = DateTime.now();

    return {
      'today': getDailySummary(now)?.totalRevenue ?? 0,
      'yesterday': getDailySummary(now.subtract(const Duration(days: 1)))?.totalRevenue ?? 0,
      'this_week': getWeeklyRevenue(),
      'this_month': getMonthlyRevenue(),
      'total': _totalRevenue,
      'ad_impressions': _totalAdImpressions,
      'purchases': _totalPurchases,
      'subscriptions': _totalSubscriptions,
    };
  }

  /// 수익 보고서 내보내기
  Future<String> exportRevenueReport() async {
    final buffer = StringBuffer();

    buffer.writeln('=== Revenue Report ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    buffer.writeln('Total Revenue: ₩${_totalRevenue.toStringAsFixed(2)}');
    buffer.writeln('Ad Impressions: $_totalAdImpressions');
    buffer.writeln('Purchases: $_totalPurchases');
    buffer.writeln('Subscriptions: $_totalSubscriptions');
    buffer.writeln();

    buffer.writeln('Revenue by Source:');
    for (final entry in _revenueBySource.entries) {
      buffer.writeln('  ${entry.key}: ₩${entry.value.toStringAsFixed(2)}');
    }

    buffer.writeln();

    buffer.writeln('Daily Summaries (Last 7 days):');
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final summary = getDailySummary(date);

      if (summary != null) {
        buffer.writeln(
          '  ${date.toIso8601String().split('T')[0]}: ₩${summary.totalRevenue.toStringAsFixed(2)}',
        );
      }
    }

    return buffer.toString();
  }

  // ============================================
  // 리소스 정리
  // ============================================

  void dispose() {
    _eventController.close();
    _summaryController.close();
  }
}

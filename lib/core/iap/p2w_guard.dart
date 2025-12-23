/// Pay-to-Win Guard for MG-Games
/// Monitors and enforces P2W index limits across 52 games

import 'dart:math';
import 'models/purchase.dart';

/// P2W index thresholds
class P2wThresholds {
  /// Maximum P2W index (default: 0.35)
  static const double maxIndex = 0.35;

  /// Warning threshold (default: 0.25)
  static const double warningIndex = 0.25;

  /// Soft cap daily spending (USD)
  static const double softCapDaily = 20.0;

  /// Hard cap daily spending (USD)
  static const double hardCapDaily = 50.0;

  /// Monthly spending warning (USD)
  static const double monthlyWarning = 100.0;
}

/// P2W index calculation result
class P2wIndexResult {
  /// Calculated P2W index (0.0 - 1.0)
  final double index;

  /// Whether index exceeds threshold
  final bool isExceeded;

  /// Whether index is in warning zone
  final bool isWarning;

  /// Recommendation for adjustment
  final String? recommendation;

  /// Component breakdown
  final Map<String, double> components;

  P2wIndexResult({
    required this.index,
    required this.isExceeded,
    required this.isWarning,
    this.recommendation,
    required this.components,
  });
}

/// Spending limit result
class SpendingLimitResult {
  /// Whether purchase is allowed
  final bool isAllowed;

  /// Reason if blocked
  final String? blockReason;

  /// Daily spending so far (USD)
  final double dailySpending;

  /// Monthly spending so far (USD)
  final double monthlySpending;

  /// Remaining daily limit (USD)
  final double remainingDailyLimit;

  /// Should show warning
  final bool showWarning;

  /// Warning message
  final String? warningMessage;

  SpendingLimitResult({
    required this.isAllowed,
    this.blockReason,
    required this.dailySpending,
    required this.monthlySpending,
    required this.remainingDailyLimit,
    required this.showWarning,
    this.warningMessage,
  });
}

/// P2W Guard implementation
class P2wGuard {
  /// Singleton instance
  static final P2wGuard _instance = P2wGuard._internal();
  factory P2wGuard() => _instance;
  P2wGuard._internal();

  /// User spending history (userId -> purchases)
  final Map<String, List<Purchase>> _userPurchases = {};

  /// Calculate P2W index for a game design
  ///
  /// Components:
  /// - Power gap (paying vs non-paying): 0-40%
  /// - Content gate (pay-only content): 0-25%
  /// - Progression speed (pay acceleration): 0-20%
  /// - Competitive advantage: 0-15%
  P2wIndexResult calculateP2wIndex({
    required double powerGapRatio,
    required double contentGateRatio,
    required double progressionSpeedRatio,
    required double competitiveAdvantageRatio,
  }) {
    // Weight each component
    const powerGapWeight = 0.40;
    const contentGateWeight = 0.25;
    const progressionWeight = 0.20;
    const competitiveWeight = 0.15;

    // Clamp ratios to 0-1
    final cPowerGap = powerGapRatio.clamp(0.0, 1.0);
    final cContentGate = contentGateRatio.clamp(0.0, 1.0);
    final cProgression = progressionSpeedRatio.clamp(0.0, 1.0);
    final cCompetitive = competitiveAdvantageRatio.clamp(0.0, 1.0);

    // Calculate weighted index
    final index = (cPowerGap * powerGapWeight) +
        (cContentGate * contentGateWeight) +
        (cProgression * progressionWeight) +
        (cCompetitive * competitiveWeight);

    // Determine status
    final isExceeded = index > P2wThresholds.maxIndex;
    final isWarning = index > P2wThresholds.warningIndex && !isExceeded;

    // Generate recommendation
    String? recommendation;
    if (isExceeded) {
      // Find highest contributing component
      final components = {
        'powerGap': cPowerGap * powerGapWeight,
        'contentGate': cContentGate * contentGateWeight,
        'progression': cProgression * progressionWeight,
        'competitive': cCompetitive * competitiveWeight,
      };
      final highest = components.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      recommendation = 'Reduce ${highest.key} to lower P2W index. '
          'Current contribution: ${(highest.value * 100).toStringAsFixed(1)}%';
    } else if (isWarning) {
      recommendation = 'P2W index is approaching threshold. Consider monitoring.';
    }

    return P2wIndexResult(
      index: index,
      isExceeded: isExceeded,
      isWarning: isWarning,
      recommendation: recommendation,
      components: {
        'powerGap': cPowerGap * powerGapWeight,
        'contentGate': cContentGate * contentGateWeight,
        'progression': cProgression * progressionWeight,
        'competitive': cCompetitive * competitiveWeight,
      },
    );
  }

  /// Check spending limit before purchase
  SpendingLimitResult checkSpendingLimit({
    required String userId,
    required double purchaseAmountUsd,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    // Get user purchases
    final purchases = _userPurchases[userId] ?? [];

    // Calculate daily spending
    final dailySpending = purchases
        .where((p) =>
            p.status == PurchaseStatus.verified &&
            DateTime.fromMillisecondsSinceEpoch(p.purchaseTimestamp)
                .isAfter(todayStart))
        .fold<double>(0.0, (sum, p) => sum + p.priceUsd);

    // Calculate monthly spending
    final monthlySpending = purchases
        .where((p) =>
            p.status == PurchaseStatus.verified &&
            DateTime.fromMillisecondsSinceEpoch(p.purchaseTimestamp)
                .isAfter(monthStart))
        .fold<double>(0.0, (sum, p) => sum + p.priceUsd);

    // Check hard cap
    if (dailySpending + purchaseAmountUsd > P2wThresholds.hardCapDaily) {
      return SpendingLimitResult(
        isAllowed: false,
        blockReason: 'Daily spending limit reached (\$${P2wThresholds.hardCapDaily}). '
            'Please try again tomorrow.',
        dailySpending: dailySpending,
        monthlySpending: monthlySpending,
        remainingDailyLimit: max(0, P2wThresholds.hardCapDaily - dailySpending),
        showWarning: false,
      );
    }

    // Check soft cap warning
    final showWarning =
        dailySpending + purchaseAmountUsd > P2wThresholds.softCapDaily ||
            monthlySpending > P2wThresholds.monthlyWarning;

    String? warningMessage;
    if (dailySpending + purchaseAmountUsd > P2wThresholds.softCapDaily) {
      warningMessage = 'You\'ve spent \$${dailySpending.toStringAsFixed(2)} today. '
          'Consider taking a break!';
    } else if (monthlySpending > P2wThresholds.monthlyWarning) {
      warningMessage = 'Your monthly spending is \$${monthlySpending.toStringAsFixed(2)}. '
          'Please spend responsibly.';
    }

    return SpendingLimitResult(
      isAllowed: true,
      dailySpending: dailySpending,
      monthlySpending: monthlySpending,
      remainingDailyLimit: max(0, P2wThresholds.hardCapDaily - dailySpending),
      showWarning: showWarning,
      warningMessage: warningMessage,
    );
  }

  /// Record a verified purchase
  void recordPurchase(Purchase purchase) {
    _userPurchases.putIfAbsent(purchase.userId, () => []);
    _userPurchases[purchase.userId]!.add(purchase);
  }

  /// Get user spending statistics
  Map<String, dynamic> getUserSpendingStats(String userId) {
    final purchases = _userPurchases[userId] ?? [];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final verifiedPurchases =
        purchases.where((p) => p.status == PurchaseStatus.verified).toList();

    final weeklySpending = verifiedPurchases
        .where((p) => DateTime.fromMillisecondsSinceEpoch(p.purchaseTimestamp)
            .isAfter(weekStart))
        .fold<double>(0.0, (sum, p) => sum + p.priceUsd);

    final monthlySpending = verifiedPurchases
        .where((p) => DateTime.fromMillisecondsSinceEpoch(p.purchaseTimestamp)
            .isAfter(monthStart))
        .fold<double>(0.0, (sum, p) => sum + p.priceUsd);

    final totalSpending =
        verifiedPurchases.fold<double>(0.0, (sum, p) => sum + p.priceUsd);

    return {
      'userId': userId,
      'totalPurchases': verifiedPurchases.length,
      'weeklySpending': weeklySpending,
      'monthlySpending': monthlySpending,
      'totalSpending': totalSpending,
      'lastPurchaseTimestamp': verifiedPurchases.isNotEmpty
          ? verifiedPurchases.last.purchaseTimestamp
          : null,
    };
  }

  /// Clear user data (for testing or GDPR compliance)
  void clearUserData(String userId) {
    _userPurchases.remove(userId);
  }
}

/// P2W design guidelines for MG-Games
class P2wDesignGuidelines {
  /// Casual games (MG-0001~0024, MG-0037~0052)
  static const casualGameGuidelines = '''
# P2W Guidelines for Casual Games

## Allowed Monetization
- Time-skip (energy, timers)
- Cosmetics only
- Convenience features
- Content unlock shortcuts

## Not Allowed
- Direct power increases
- Exclusive gameplay content
- Competitive advantages
- Required purchases for progression

## Target P2W Index: < 0.20
''';

  /// Level A games (MG-0025~0036)
  static const levelAGameGuidelines = '''
# P2W Guidelines for Level A Games (JRPG)

## Allowed Monetization
- Gacha with pity system (100 pulls guaranteed)
- Battle Pass (cosmetic + resources)
- Monthly Card (daily login rewards)
- Stamina/Energy refill

## Guardrails Required
- SSR pity at 90 pulls
- Banner rotation transparency
- No limited-time exclusive units
- F2P path to endgame content

## Target P2W Index: < 0.35
''';

  /// Get guidelines for game category
  static String getGuidelines(int gameNumber) {
    if (gameNumber >= 25 && gameNumber <= 36) {
      return levelAGameGuidelines;
    }
    return casualGameGuidelines;
  }
}

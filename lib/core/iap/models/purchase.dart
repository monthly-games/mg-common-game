/// IAP Purchase Model for MG-Games
/// Handles purchase records and verification

/// Purchase status
enum PurchaseStatus {
  /// Purchase initiated
  pending,

  /// Purchase completed, awaiting verification
  purchased,

  /// Purchase verified by server
  verified,

  /// Purchase consumed (for consumables)
  consumed,

  /// Purchase failed
  failed,

  /// Purchase cancelled by user
  cancelled,

  /// Purchase refunded
  refunded,

  /// Subscription expired
  expired,
}

/// Purchase source platform
enum PurchasePlatform {
  /// Google Play Store
  googlePlay,

  /// Apple App Store
  appStore,

  /// Amazon Appstore
  amazon,

  /// Huawei AppGallery
  huawei,
}

/// Purchase record
class Purchase {
  /// Unique purchase ID (from store)
  final String purchaseId;

  /// Product ID purchased
  final String productId;

  /// User ID who made the purchase
  final String userId;

  /// Game ID where purchase was made
  final String gameId;

  /// Purchase platform
  final PurchasePlatform platform;

  /// Purchase status
  PurchaseStatus status;

  /// Purchase timestamp (milliseconds since epoch)
  final int purchaseTimestamp;

  /// Verification timestamp
  int? verificationTimestamp;

  /// Original transaction ID (for subscriptions)
  final String? originalTransactionId;

  /// Receipt data for verification
  final String? receiptData;

  /// Server verification response
  Map<String, dynamic>? verificationResponse;

  /// Price paid (in local currency)
  final double pricePaid;

  /// Currency code
  final String currencyCode;

  /// USD equivalent (for analytics)
  final double priceUsd;

  /// Error message if failed
  String? errorMessage;

  /// Custom attributes
  final Map<String, dynamic>? attributes;

  Purchase({
    required this.purchaseId,
    required this.productId,
    required this.userId,
    required this.gameId,
    required this.platform,
    required this.status,
    required this.purchaseTimestamp,
    required this.pricePaid,
    required this.currencyCode,
    required this.priceUsd,
    this.verificationTimestamp,
    this.originalTransactionId,
    this.receiptData,
    this.verificationResponse,
    this.errorMessage,
    this.attributes,
  });

  /// Check if purchase is valid and verified
  bool get isValid => status == PurchaseStatus.verified || status == PurchaseStatus.consumed;

  /// Check if purchase needs verification
  bool get needsVerification => status == PurchaseStatus.purchased;

  /// Check if purchase is a subscription
  bool get isSubscription => originalTransactionId != null;

  /// Create from JSON
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchaseId'] as String,
      productId: json['productId'] as String,
      userId: json['userId'] as String,
      gameId: json['gameId'] as String,
      platform: PurchasePlatform.values.byName(json['platform'] as String),
      status: PurchaseStatus.values.byName(json['status'] as String),
      purchaseTimestamp: json['purchaseTimestamp'] as int,
      pricePaid: (json['pricePaid'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      priceUsd: (json['priceUsd'] as num).toDouble(),
      verificationTimestamp: json['verificationTimestamp'] as int?,
      originalTransactionId: json['originalTransactionId'] as String?,
      receiptData: json['receiptData'] as String?,
      verificationResponse: json['verificationResponse'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'productId': productId,
      'userId': userId,
      'gameId': gameId,
      'platform': platform.name,
      'status': status.name,
      'purchaseTimestamp': purchaseTimestamp,
      'pricePaid': pricePaid,
      'currencyCode': currencyCode,
      'priceUsd': priceUsd,
      'verificationTimestamp': verificationTimestamp,
      'originalTransactionId': originalTransactionId,
      'receiptData': receiptData,
      'verificationResponse': verificationResponse,
      'errorMessage': errorMessage,
      'attributes': attributes,
    };
  }

  /// Create a copy with updated fields
  Purchase copyWith({
    PurchaseStatus? status,
    int? verificationTimestamp,
    Map<String, dynamic>? verificationResponse,
    String? errorMessage,
    String? receiptData,
  }) {
    return Purchase(
      purchaseId: purchaseId,
      productId: productId,
      userId: userId,
      gameId: gameId,
      platform: platform,
      status: status ?? this.status,
      purchaseTimestamp: purchaseTimestamp,
      pricePaid: pricePaid,
      currencyCode: currencyCode,
      priceUsd: priceUsd,
      verificationTimestamp: verificationTimestamp ?? this.verificationTimestamp,
      originalTransactionId: originalTransactionId,
      receiptData: receiptData ?? this.receiptData,
      verificationResponse: verificationResponse ?? this.verificationResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      attributes: attributes,
    );
  }

  @override
  String toString() => 'Purchase($purchaseId, $productId, $status)';
}

/// Subscription status for active subscriptions
class SubscriptionStatus {
  /// Product ID
  final String productId;

  /// User ID
  final String userId;

  /// Whether subscription is active
  final bool isActive;

  /// Expiration timestamp
  final int expirationTimestamp;

  /// Auto-renew status
  final bool willRenew;

  /// Original purchase timestamp
  final int originalPurchaseTimestamp;

  /// Latest purchase/renewal timestamp
  final int latestPurchaseTimestamp;

  /// Is in free trial
  final bool isInFreeTrial;

  /// Is in grace period (payment failed but still active)
  final bool isInGracePeriod;

  /// Platform
  final PurchasePlatform platform;

  SubscriptionStatus({
    required this.productId,
    required this.userId,
    required this.isActive,
    required this.expirationTimestamp,
    required this.willRenew,
    required this.originalPurchaseTimestamp,
    required this.latestPurchaseTimestamp,
    required this.platform,
    this.isInFreeTrial = false,
    this.isInGracePeriod = false,
  });

  /// Check if subscription will expire soon (within 3 days)
  bool get willExpireSoon {
    final now = DateTime.now().millisecondsSinceEpoch;
    final threeDaysMs = 3 * 24 * 60 * 60 * 1000;
    return isActive && !willRenew && (expirationTimestamp - now) < threeDaysMs;
  }

  /// Get remaining days
  int get remainingDays {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = expirationTimestamp - now;
    return (remainingMs / (24 * 60 * 60 * 1000)).ceil();
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      productId: json['productId'] as String,
      userId: json['userId'] as String,
      isActive: json['isActive'] as bool,
      expirationTimestamp: json['expirationTimestamp'] as int,
      willRenew: json['willRenew'] as bool,
      originalPurchaseTimestamp: json['originalPurchaseTimestamp'] as int,
      latestPurchaseTimestamp: json['latestPurchaseTimestamp'] as int,
      platform: PurchasePlatform.values.byName(json['platform'] as String),
      isInFreeTrial: json['isInFreeTrial'] as bool? ?? false,
      isInGracePeriod: json['isInGracePeriod'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'isActive': isActive,
      'expirationTimestamp': expirationTimestamp,
      'willRenew': willRenew,
      'originalPurchaseTimestamp': originalPurchaseTimestamp,
      'latestPurchaseTimestamp': latestPurchaseTimestamp,
      'platform': platform.name,
      'isInFreeTrial': isInFreeTrial,
      'isInGracePeriod': isInGracePeriod,
    };
  }
}

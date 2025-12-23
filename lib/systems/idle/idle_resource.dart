/// Represents a resource that produces items over time (idle production)
class IdleResource {
  final String id;
  final String name;
  final double baseProductionRate; // items per hour
  final int maxStorage;
  final int tier;

  int currentAmount;
  DateTime lastUpdateTime;
  bool isProducing;

  IdleResource({
    required this.id,
    required this.name,
    required this.baseProductionRate,
    required this.maxStorage,
    required this.tier,
    this.currentAmount = 0,
    DateTime? lastUpdateTime,
    this.isProducing = true,
  }) : lastUpdateTime = lastUpdateTime ?? DateTime.now();

  /// Calculate production for a given time period
  int calculateProduction(Duration duration, {double modifier = 1.0}) {
    if (!isProducing || baseProductionRate <= 0) return 0;

    final hours = duration.inSeconds / 3600.0;
    final produced = (baseProductionRate * modifier * hours).floor();

    return produced;
  }

  /// Add produced items (respecting max storage)
  int addProduction(int amount) {
    final spaceAvailable = maxStorage - currentAmount;
    final actualAmount = amount > spaceAvailable ? spaceAvailable : amount;

    currentAmount += actualAmount;
    return actualAmount;
  }

  /// Collect items from storage
  int collect(int amount) {
    final actualAmount = amount > currentAmount ? currentAmount : amount;
    currentAmount -= actualAmount;
    return actualAmount;
  }

  /// Collect all items
  int collectAll() {
    final amount = currentAmount;
    currentAmount = 0;
    return amount;
  }

  /// Check if storage is full
  bool get isFull => currentAmount >= maxStorage;

  /// Get storage percentage (0.0 to 1.0)
  double get storagePercentage => currentAmount / maxStorage;

  /// Update last update time
  void updateTime() {
    lastUpdateTime = DateTime.now();
  }

  /// Get production rate with modifier
  double getProductionRate(double modifier) {
    return baseProductionRate * modifier;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentAmount': currentAmount,
      'lastUpdateTime': lastUpdateTime.millisecondsSinceEpoch,
      'isProducing': isProducing,
    };
  }

  /// Deserialize from JSON
  factory IdleResource.fromJson(
    Map<String, dynamic> json, {
    required String name,
    required double baseProductionRate,
    required int maxStorage,
    required int tier,
  }) {
    return IdleResource(
      id: json['id'] as String,
      name: name,
      baseProductionRate: baseProductionRate,
      maxStorage: maxStorage,
      tier: tier,
      currentAmount: json['currentAmount'] as int? ?? 0,
      lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdateTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isProducing: json['isProducing'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'IdleResource($id: $currentAmount/$maxStorage, rate: $baseProductionRate/h)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdleResource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

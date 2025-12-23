/// Represents an item in the inventory
class InventoryItem {
  final String id;
  int amount;
  final DateTime? acquiredTime;
  final Map<String, dynamic>? metadata; // Additional item data

  InventoryItem({
    required this.id,
    required this.amount,
    this.acquiredTime,
    this.metadata,
  });

  /// Create a copy with updated amount
  InventoryItem copyWith({
    int? amount,
    DateTime? acquiredTime,
    Map<String, dynamic>? metadata,
  }) {
    return InventoryItem(
      id: id,
      amount: amount ?? this.amount,
      acquiredTime: acquiredTime ?? this.acquiredTime,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      if (acquiredTime != null)
        'acquiredTime': acquiredTime!.millisecondsSinceEpoch,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Deserialize from JSON
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      amount: json['amount'] as int,
      acquiredTime: json['acquiredTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['acquiredTime'] as int)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'InventoryItem($id × $amount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single crafting job in the queue
class CraftingJob {
  final String id; // Unique job ID
  final String recipeId;
  final DateTime startTime;
  final Duration craftDuration;
  final Map<String, int> result; // itemId -> amount

  CraftingJob({
    required this.id,
    required this.recipeId,
    required this.startTime,
    required this.craftDuration,
    required this.result,
  });

  /// Check if crafting is complete
  bool isComplete([DateTime? now]) {
    now ??= DateTime.now();
    return now.difference(startTime) >= craftDuration;
  }

  /// Get completion time
  DateTime get completionTime => startTime.add(craftDuration);

  /// Get remaining time
  Duration getRemainingTime([DateTime? now]) {
    now ??= DateTime.now();
    if (isComplete(now)) return Duration.zero;

    return completionTime.difference(now);
  }

  /// Get progress (0.0 to 1.0)
  double getProgress([DateTime? now]) {
    now ??= DateTime.now();
    final elapsed = now.difference(startTime);
    final progress = elapsed.inMilliseconds / craftDuration.inMilliseconds;

    return progress.clamp(0.0, 1.0);
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'startTime': startTime.millisecondsSinceEpoch,
      'craftDuration': craftDuration.inSeconds,
      'result': result,
    };
  }

  /// Deserialize from JSON
  factory CraftingJob.fromJson(Map<String, dynamic> json) {
    return CraftingJob(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        json['startTime'] as int,
      ),
      craftDuration: Duration(seconds: json['craftDuration'] as int),
      result: (json['result'] as Map<String, dynamic>).cast<String, int>(),
    );
  }

  @override
  String toString() {
    return 'CraftingJob($recipeId, ${getProgress().toStringAsFixed(2)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CraftingJob && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

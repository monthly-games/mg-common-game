import 'dart:async';
import 'crafting_queue.dart';

/// Result of a crafting attempt
class CraftingResult {
  final bool success;
  final String? message;
  final CraftingJob? job;

  const CraftingResult({
    required this.success,
    this.message,
    this.job,
  });

  factory CraftingResult.success(CraftingJob job) {
    return CraftingResult(success: true, job: job);
  }

  factory CraftingResult.failure(String message) {
    return CraftingResult(success: false, message: message);
  }
}

/// Manager for crafting system
class CraftingManager {
  static final CraftingManager instance = CraftingManager._internal();

  factory CraftingManager() => instance;

  CraftingManager._internal();

  final List<CraftingJob> _queue = [];
  int _maxQueueSize = 3;
  double _craftTimeModifier = 1.0;
  Timer? _updateTimer;
  bool _isRunning = false;

  // Callbacks
  void Function(CraftingJob job)? onCraftingComplete;
  void Function(String recipeId)? onCraftingStart;
  void Function()? onQueueFull;

  /// Get max queue size
  int get maxQueueSize => _maxQueueSize;

  /// Set max queue size
  void setMaxQueueSize(int size) {
    _maxQueueSize = size;
  }

  /// Get craft time modifier (from upgrades, bonuses)
  double get craftTimeModifier => _craftTimeModifier;

  /// Set craft time modifier (0.8 = 20% faster)
  void setCraftTimeModifier(double modifier) {
    _craftTimeModifier = modifier;
  }

  /// Get current queue
  List<CraftingJob> get queue => List.unmodifiable(_queue);

  /// Get queue size
  int get queueSize => _queue.length;

  /// Check if queue is full
  bool get isQueueFull => _queue.length >= _maxQueueSize;

  /// Check if queue is empty
  bool get isQueueEmpty => _queue.isEmpty;

  /// Start crafting a recipe
  CraftingResult startCrafting({
    required String recipeId,
    required Duration baseCraftTime,
    required Map<String, int> result,
  }) {
    // Check queue capacity
    if (isQueueFull) {
      onQueueFull?.call();
      return CraftingResult.failure('Crafting queue is full');
    }

    // Calculate actual craft time with modifiers
    final actualDuration = Duration(
      seconds: (baseCraftTime.inSeconds * _craftTimeModifier).round(),
    );

    // Create job
    final job = CraftingJob(
      id: '${DateTime.now().millisecondsSinceEpoch}_$recipeId',
      recipeId: recipeId,
      startTime: DateTime.now(),
      craftDuration: actualDuration,
      result: result,
    );

    // Add to queue
    _queue.add(job);

    onCraftingStart?.call(recipeId);

    return CraftingResult.success(job);
  }

  /// Get completed jobs
  List<CraftingJob> getCompletedJobs() {
    return _queue.where((job) => job.isComplete()).toList();
  }

  /// Collect completed job
  Map<String, int>? collectCompleted(String jobId) {
    final index = _queue.indexWhere((job) => job.id == jobId);
    if (index == -1) return null;

    final job = _queue[index];
    if (!job.isComplete()) return null;

    _queue.removeAt(index);
    return job.result;
  }

  /// Collect all completed jobs
  Map<String, int> collectAllCompleted() {
    final completed = getCompletedJobs();
    final allResults = <String, int>{};

    for (final job in completed) {
      _queue.remove(job);

      // Merge results
      for (final entry in job.result.entries) {
        allResults[entry.key] = (allResults[entry.key] ?? 0) + entry.value;
      }
    }

    return allResults;
  }

  /// Cancel a crafting job
  bool cancelJob(String jobId) {
    final index = _queue.indexWhere((job) => job.id == jobId);
    if (index == -1) return false;

    _queue.removeAt(index);
    return true;
  }

  /// Get job by ID
  CraftingJob? getJob(String jobId) {
    try {
      return _queue.firstWhere((job) => job.id == jobId);
    } catch (_) {
      return null;
    }
  }

  /// Get job at queue position
  CraftingJob? getJobAt(int index) {
    if (index < 0 || index >= _queue.length) return null;
    return _queue[index];
  }

  /// Get time until next completion
  Duration? getTimeUntilNextCompletion() {
    if (_queue.isEmpty) return null;

    Duration? shortest;
    for (final job in _queue) {
      if (job.isComplete()) {
        return Duration.zero;
      }

      final remaining = job.getRemainingTime();
      if (shortest == null || remaining < shortest) {
        shortest = remaining;
      }
    }

    return shortest;
  }

  /// Start auto-check timer for completions
  void startAutoCheck({Duration checkInterval = const Duration(seconds: 1)}) {
    if (_isRunning) return;

    _isRunning = true;
    _updateTimer = Timer.periodic(checkInterval, (_) {
      _checkCompletions();
    });
  }

  /// Stop auto-check timer
  void stopAutoCheck() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;
  }

  /// Manual check for completions
  void _checkCompletions() {
    final completed = getCompletedJobs();

    for (final job in completed) {
      onCraftingComplete?.call(job);
    }
  }

  /// Process offline crafting (when player returns)
  Map<String, int> processOfflineCrafting(DateTime lastLoginTime) {
    final now = DateTime.now();
    final offlineTime = now.difference(lastLoginTime);

    // Calculate which jobs would have completed
    final completedResults = <String, int>{};

    // Sort queue by completion time
    final sortedQueue = List<CraftingJob>.from(_queue)
      ..sort((a, b) => a.completionTime.compareTo(b.completionTime));

    for (final job in sortedQueue) {
      final completionTime = job.completionTime;

      // If job was completed during offline time
      if (completionTime.isBefore(now)) {
        // Add results
        for (final entry in job.result.entries) {
          completedResults[entry.key] =
              (completedResults[entry.key] ?? 0) + entry.value;
        }

        _queue.remove(job);
      }
    }

    return completedResults;
  }

  /// Get total crafting time for all jobs in queue
  Duration getTotalQueueTime() {
    Duration total = Duration.zero;

    for (final job in _queue) {
      if (!job.isComplete()) {
        total += job.getRemainingTime();
      }
    }

    return total;
  }

  /// Instantly complete a job (premium feature)
  Map<String, int>? instantComplete(String jobId) {
    final index = _queue.indexWhere((job) => job.id == jobId);
    if (index == -1) return null;

    final job = _queue.removeAt(index);
    return job.result;
  }

  /// Instantly complete all jobs (premium feature)
  Map<String, int> instantCompleteAll() {
    final allResults = <String, int>{};

    for (final job in List.from(_queue)) {
      _queue.remove(job);

      for (final entry in job.result.entries) {
        allResults[entry.key] =
            ((allResults[entry.key] ?? 0) + entry.value).toInt();
      }
    }

    return allResults;
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'queue': _queue.map((job) => job.toJson()).toList(),
      'maxQueueSize': _maxQueueSize,
      'craftTimeModifier': _craftTimeModifier,
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    _queue.clear();

    if (json['queue'] != null) {
      final queueJson = json['queue'] as List;
      for (final jobJson in queueJson) {
        _queue.add(CraftingJob.fromJson(jobJson as Map<String, dynamic>));
      }
    }

    _maxQueueSize = json['maxQueueSize'] as int? ?? 3;
    _craftTimeModifier = (json['craftTimeModifier'] as num?)?.toDouble() ?? 1.0;
  }

  /// Clear queue (for testing)
  void clear() {
    stopAutoCheck();
    _queue.clear();
    _maxQueueSize = 3;
    _craftTimeModifier = 1.0;
  }

  @override
  String toString() {
    return 'CraftingManager(queue: ${_queue.length}/$_maxQueueSize, '
        'modifier: $_craftTimeModifier)';
  }
}

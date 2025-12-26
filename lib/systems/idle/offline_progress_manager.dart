import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'idle_manager.dart';

/// Callback for offline progress events
typedef OfflineProgressCallback = void Function(OfflineProgressData data);

/// Data class for offline progress information
class OfflineProgressData {
  final Duration offlineDuration;
  final Map<String, int> rewards;
  final DateTime lastLoginTime;
  final DateTime currentTime;
  final bool wasAwayLongEnough;

  OfflineProgressData({
    required this.offlineDuration,
    required this.rewards,
    required this.lastLoginTime,
    required this.currentTime,
    this.wasAwayLongEnough = true,
  });

  /// Total rewards across all resources
  int get totalRewards => rewards.values.fold(0, (sum, v) => sum + v);

  /// Check if there are any rewards
  bool get hasRewards => rewards.isNotEmpty && totalRewards > 0;

  /// Get formatted offline time string
  String get formattedDuration {
    if (offlineDuration.inDays > 0) {
      return '${offlineDuration.inDays}d ${offlineDuration.inHours % 24}h';
    } else if (offlineDuration.inHours > 0) {
      return '${offlineDuration.inHours}h ${offlineDuration.inMinutes % 60}m';
    } else if (offlineDuration.inMinutes > 0) {
      return '${offlineDuration.inMinutes}m ${offlineDuration.inSeconds % 60}s';
    } else {
      return '${offlineDuration.inSeconds}s';
    }
  }

  @override
  String toString() {
    return 'OfflineProgressData(duration: $formattedDuration, rewards: $rewards)';
  }
}

/// Manages offline progress tracking and rewards
class OfflineProgressManager extends ChangeNotifier {
  static const String _lastLoginKey = 'offline_progress_last_login';
  static const String _totalOfflineTimeKey = 'offline_progress_total_time';

  final IdleManager _idleManager;
  SharedPreferences? _prefs;

  DateTime? _lastLoginTime;
  Duration _totalOfflineTime = Duration.zero;
  OfflineProgressData? _pendingRewards;

  /// Minimum offline time to show rewards (in seconds)
  int minOfflineSeconds = 60;

  /// Maximum offline time to calculate rewards (in hours)
  double maxOfflineHours = 8.0;

  /// Offline efficiency (0.0 to 1.0) - reduces rewards while offline
  double offlineEfficiency = 1.0;

  /// Callback when offline progress is calculated
  OfflineProgressCallback? onOfflineProgress;

  OfflineProgressManager({
    IdleManager? idleManager,
  }) : _idleManager = idleManager ?? IdleManager();

  /// Initialize the manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLastLoginTime();
    _loadTotalOfflineTime();
  }

  void _loadLastLoginTime() {
    final timestamp = _prefs?.getInt(_lastLoginKey);
    if (timestamp != null) {
      _lastLoginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  void _loadTotalOfflineTime() {
    final seconds = _prefs?.getInt(_totalOfflineTimeKey) ?? 0;
    _totalOfflineTime = Duration(seconds: seconds);
  }

  /// Get last login time
  DateTime? get lastLoginTime => _lastLoginTime;

  /// Get total offline time accumulated
  Duration get totalOfflineTime => _totalOfflineTime;

  /// Get pending rewards (if any)
  OfflineProgressData? get pendingRewards => _pendingRewards;

  /// Check if there are pending rewards to claim
  bool get hasPendingRewards => _pendingRewards != null && _pendingRewards!.hasRewards;

  /// Calculate and store offline progress
  /// Call this when the app resumes or starts
  Future<OfflineProgressData?> checkOfflineProgress() async {
    if (_lastLoginTime == null) {
      // First login, no offline rewards
      await _saveCurrentLoginTime();
      return null;
    }

    final now = DateTime.now();
    final offlineDuration = now.difference(_lastLoginTime!);

    // Check minimum offline time
    if (offlineDuration.inSeconds < minOfflineSeconds) {
      await _saveCurrentLoginTime();
      return null;
    }

    // Calculate rewards with efficiency modifier
    final cappedHours = (offlineDuration.inSeconds / 3600.0).clamp(0.0, maxOfflineHours);
    final cappedDuration = Duration(seconds: (cappedHours * 3600).toInt());

    // Temporarily modify global modifier for offline efficiency
    final originalModifier = _idleManager.globalModifier;
    _idleManager.setGlobalModifier(originalModifier * offlineEfficiency);

    final rewards = _idleManager.calculateOfflineRewards(cappedDuration);

    // Restore original modifier
    _idleManager.setGlobalModifier(originalModifier);

    // Update total offline time
    _totalOfflineTime += offlineDuration;
    await _prefs?.setInt(_totalOfflineTimeKey, _totalOfflineTime.inSeconds);

    // Create progress data
    final progressData = OfflineProgressData(
      offlineDuration: offlineDuration,
      rewards: rewards,
      lastLoginTime: _lastLoginTime!,
      currentTime: now,
      wasAwayLongEnough: offlineDuration.inSeconds >= minOfflineSeconds,
    );

    _pendingRewards = progressData;
    notifyListeners();

    // Notify callback
    onOfflineProgress?.call(progressData);

    return progressData;
  }

  /// Claim pending rewards
  /// Returns the rewards that were claimed
  Map<String, int> claimRewards() {
    if (_pendingRewards == null) return {};

    final rewards = Map<String, int>.from(_pendingRewards!.rewards);
    _pendingRewards = null;
    _saveCurrentLoginTime();
    notifyListeners();

    return rewards;
  }

  /// Claim rewards with multiplier (e.g., from watching ad)
  Map<String, int> claimRewardsWithMultiplier(double multiplier) {
    if (_pendingRewards == null) return {};

    final rewards = <String, int>{};
    for (final entry in _pendingRewards!.rewards.entries) {
      final multipliedAmount = (entry.value * multiplier).floor();
      rewards[entry.key] = multipliedAmount;

      // Add extra rewards to the resource
      final extraAmount = multipliedAmount - entry.value;
      if (extraAmount > 0) {
        final resource = _idleManager.getResource(entry.key);
        resource?.addProduction(extraAmount);
      }
    }

    _pendingRewards = null;
    _saveCurrentLoginTime();
    notifyListeners();

    return rewards;
  }

  /// Skip/dismiss pending rewards without claiming
  void skipRewards() {
    _pendingRewards = null;
    _saveCurrentLoginTime();
    notifyListeners();
  }

  Future<void> _saveCurrentLoginTime() async {
    _lastLoginTime = DateTime.now();
    await _prefs?.setInt(_lastLoginKey, _lastLoginTime!.millisecondsSinceEpoch);
  }

  /// Record app going to background
  Future<void> onAppPaused() async {
    await _saveCurrentLoginTime();
  }

  /// Record app coming to foreground
  Future<OfflineProgressData?> onAppResumed() async {
    return await checkOfflineProgress();
  }

  /// Reset all offline progress data
  Future<void> reset() async {
    _lastLoginTime = null;
    _totalOfflineTime = Duration.zero;
    _pendingRewards = null;
    await _prefs?.remove(_lastLoginKey);
    await _prefs?.remove(_totalOfflineTimeKey);
    notifyListeners();
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'lastLoginTime': _lastLoginTime?.millisecondsSinceEpoch,
      'totalOfflineTime': _totalOfflineTime.inSeconds,
      'minOfflineSeconds': minOfflineSeconds,
      'maxOfflineHours': maxOfflineHours,
      'offlineEfficiency': offlineEfficiency,
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    if (json['lastLoginTime'] != null) {
      _lastLoginTime = DateTime.fromMillisecondsSinceEpoch(
        json['lastLoginTime'] as int,
      );
    }
    if (json['totalOfflineTime'] != null) {
      _totalOfflineTime = Duration(seconds: json['totalOfflineTime'] as int);
    }
    if (json['minOfflineSeconds'] != null) {
      minOfflineSeconds = json['minOfflineSeconds'] as int;
    }
    if (json['maxOfflineHours'] != null) {
      maxOfflineHours = (json['maxOfflineHours'] as num).toDouble();
    }
    if (json['offlineEfficiency'] != null) {
      offlineEfficiency = (json['offlineEfficiency'] as num).toDouble();
    }
    notifyListeners();
  }

  @override
  String toString() {
    return 'OfflineProgressManager(lastLogin: $_lastLoginTime, totalOffline: $_totalOfflineTime)';
  }
}

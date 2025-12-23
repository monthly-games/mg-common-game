import 'dart:async';
import 'idle_resource.dart';

/// Manager for idle/incremental resource production
class IdleManager {
  static final IdleManager instance = IdleManager._internal();

  factory IdleManager() => instance;

  IdleManager._internal();

  final Map<String, IdleResource> _resources = {};
  Timer? _updateTimer;
  double _globalModifier = 1.0;
  bool _isRunning = false;

  /// Maximum offline time to calculate (in hours)
  static const double maxOfflineHours = 8.0;

  // Callbacks
  void Function(String resourceId, int amount)? onResourceProduced;
  void Function(String resourceId)? onStorageFull;

  /// Register a resource for idle production
  void registerResource(IdleResource resource) {
    _resources[resource.id] = resource;
  }

  /// Unregister a resource
  void unregisterResource(String resourceId) {
    _resources.remove(resourceId);
  }

  /// Get a resource by ID
  IdleResource? getResource(String resourceId) {
    return _resources[resourceId];
  }

  /// Get all resources
  List<IdleResource> getAllResources() {
    return _resources.values.toList();
  }

  /// Set global production modifier (from upgrades, cat bonuses, etc.)
  void setGlobalModifier(double modifier) {
    _globalModifier = modifier;
  }

  /// Get global modifier
  double get globalModifier => _globalModifier;

  /// Get all resources map
  Map<String, IdleResource> get resources => _resources;

  final Map<String, double> _resourceModifiers = {};

  /// Set production modifier for a specific resource
  void setProductionModifier(String resourceId, double modifier) {
    _resourceModifiers[resourceId] = modifier;
  }

  /// Get modifier for a resource
  double getProductionModifier(String resourceId) {
    return _resourceModifiers[resourceId] ?? 1.0;
  }

  /// Get total production multiplier for a resource
  double getTotalModifier(String resourceId) {
    return _globalModifier * getProductionModifier(resourceId);
  }

  /// Start idle production (tick-based)
  void startProduction({Duration tickInterval = const Duration(seconds: 1)}) {
    if (_isRunning) return;

    _isRunning = true;
    _updateTimer = Timer.periodic(tickInterval, (_) {
      _tick(tickInterval);
    });
  }

  /// Stop idle production
  void stopProduction() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;
  }

  /// Manual tick update
  void _tick(Duration deltaTime) {
    final now = DateTime.now();

    for (final resource in _resources.values) {
      if (!resource.isProducing || resource.isFull) continue;

      final timeSinceLastUpdate = now.difference(resource.lastUpdateTime);
      final produced = resource.calculateProduction(
        timeSinceLastUpdate,
        modifier: getTotalModifier(resource.id),
      );

      if (produced > 0) {
        final added = resource.addProduction(produced);
        resource.updateTime();

        if (added > 0) {
          onResourceProduced?.call(resource.id, added);
        }

        if (resource.isFull) {
          onStorageFull?.call(resource.id);
        }
      }
    }
  }

  /// Calculate offline rewards (when player returns after being away)
  Map<String, int> calculateOfflineRewards(Duration offlineTime) {
    final rewards = <String, int>{};

    // Cap offline time
    final cappedHours =
        (offlineTime.inSeconds / 3600.0).clamp(0.0, maxOfflineHours);
    final cappedDuration = Duration(seconds: (cappedHours * 3600).toInt());

    for (final resource in _resources.values) {
      if (!resource.isProducing) continue;

      final produced = resource.calculateProduction(
        cappedDuration,
        modifier: getTotalModifier(resource.id),
      );

      if (produced > 0) {
        final added = resource.addProduction(produced);
        rewards[resource.id] = added;
      }
    }

    // Update all resource times
    for (final resource in _resources.values) {
      resource.updateTime();
    }

    return rewards;
  }

  /// Process offline time and return rewards
  Map<String, int> processOfflineTime(DateTime lastLoginTime) {
    final now = DateTime.now();
    final offlineTime = now.difference(lastLoginTime);

    return calculateOfflineRewards(offlineTime);
  }

  /// Collect from a resource
  int collect(String resourceId, int amount) {
    final resource = _resources[resourceId];
    if (resource == null) return 0;

    return resource.collect(amount);
  }

  /// Collect all from a resource
  int collectAll(String resourceId) {
    final resource = _resources[resourceId];
    if (resource == null) return 0;

    return resource.collectAll();
  }

  /// Collect all from all resources
  Map<String, int> collectAllResources() {
    final collected = <String, int>{};

    for (final resource in _resources.values) {
      final amount = resource.collectAll();
      if (amount > 0) {
        collected[resource.id] = amount;
      }
    }

    return collected;
  }

  /// Get current production rate for a resource (per hour)
  double getProductionRate(String resourceId) {
    final resource = _resources[resourceId];
    if (resource == null) return 0.0;

    return resource.getProductionRate(_globalModifier);
  }

  /// Get estimated time to fill storage for a resource
  Duration? getTimeToFillStorage(String resourceId) {
    final resource = _resources[resourceId];
    if (resource == null || !resource.isProducing || resource.isFull) {
      return null;
    }

    final rate = getProductionRate(resourceId);
    if (rate <= 0) return null;

    final remaining = resource.maxStorage - resource.currentAmount;
    final hours = remaining / rate;
    return Duration(seconds: (hours * 3600).toInt());
  }

  /// Pause production for a resource
  void pauseProduction(String resourceId) {
    final resource = _resources[resourceId];
    if (resource != null) {
      resource.isProducing = false;
    }
  }

  /// Resume production for a resource
  void resumeProduction(String resourceId) {
    final resource = _resources[resourceId];
    if (resource != null) {
      resource.isProducing = true;
      resource.updateTime();
    }
  }

  /// Serialize all resources to JSON
  Map<String, dynamic> toJson() {
    return {
      'resources':
          _resources.map((key, value) => MapEntry(key, value.toJson())),
      'globalModifier': _globalModifier,
    };
  }

  /// Deserialize from JSON
  void fromJson(Map<String, dynamic> json) {
    if (json['globalModifier'] != null) {
      _globalModifier = (json['globalModifier'] as num).toDouble();
    }

    // Note: Resources need to be registered with their base configs first
    // This only updates their state
    if (json['resources'] != null) {
      final resourcesJson = json['resources'] as Map<String, dynamic>;
      for (final entry in resourcesJson.entries) {
        final resource = _resources[entry.key];
        if (resource != null) {
          final stateJson = entry.value as Map<String, dynamic>;
          resource.currentAmount = stateJson['currentAmount'] as int? ?? 0;
          resource.lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
            stateJson['lastUpdateTime'] as int? ??
                DateTime.now().millisecondsSinceEpoch,
          );
          resource.isProducing = stateJson['isProducing'] as bool? ?? true;
        }
      }
    }
  }

  /// Clear all resources (for testing)
  void clear() {
    stopProduction();
    _resources.clear();
    _globalModifier = 1.0;
  }

  /// Get total storage capacity across all resources
  int getTotalStorageCapacity() {
    return _resources.values.fold(0, (sum, r) => sum + r.maxStorage);
  }

  /// Get total current amount across all resources
  int getTotalCurrentAmount() {
    return _resources.values.fold(0, (sum, r) => sum + r.currentAmount);
  }

  /// Get overall storage percentage
  double getOverallStoragePercentage() {
    final total = getTotalStorageCapacity();
    if (total == 0) return 0.0;

    return getTotalCurrentAmount() / total;
  }

  @override
  String toString() {
    return 'IdleManager(resources: ${_resources.length}, '
        'modifier: $_globalModifier, running: $_isRunning)';
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:mg_common_game/systems/idle/idle_config.dart';

class UnifiedIdleManager {
  UnifiedIdleManager({
    required this.config,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final IdleConfig config;
  final DateTime Function() _nowProvider;

  final Map<String, IdleBoost> _boosts = <String, IdleBoost>{};
  final Map<String, IdleModifier> _modifiers = <String, IdleModifier>{};

  Timer? _timer;
  DateTime? _lastProductionAt;
  Map<String, dynamic>? _savedState;

  bool _isProducing = false;
  double _totalProduced = 0;

  double get totalProduced => _totalProduced;
  int get activeBoostCount {
    _cleanupExpiredBoosts();
    return _boosts.length;
  }

  bool get isProducing => _isProducing;

  double calculateIdleIncome(Duration offlineDuration, IdleConfig config) {
    final seconds = math.max(0, offlineDuration.inSeconds);
    if (seconds == 0) {
      return 0;
    }

    final hours = seconds / 3600.0;
    final resourceRate = config.resources.fold<double>(
      0,
      (total, resource) => total + resource.baseRate,
    );

    final baseRate = config.baseProductionRate + resourceRate;
    final income = baseRate * hours * getTotalMultiplier();

    if (!income.isFinite || income.isNaN) {
      return double.maxFinite;
    }
    if (income < 0) {
      return 0;
    }
    return income;
  }

  IdleReward getOfflineReward(DateTime lastLogin, OfflineCaps caps) {
    final now = _nowProvider();
    final rawDuration = now.difference(lastLogin);

    final safeDuration = rawDuration.isNegative ? Duration.zero : rawDuration;
    final cappedByTime = safeDuration > caps.maxOfflineTime;
    final effectiveDuration = cappedByTime ? caps.maxOfflineTime : safeDuration;

    final baseIncome = calculateIdleIncome(effectiveDuration, config);
    final rewardWithEfficiency = baseIncome * caps.offlineEfficiency;

    final cappedByReward = rewardWithEfficiency > caps.maxOfflineReward;
    final amount = cappedByReward ? caps.maxOfflineReward : rewardWithEfficiency;

    return IdleReward(
      offlineDuration: effectiveDuration,
      amount: amount.isFinite ? math.max(0, amount) : caps.maxOfflineReward,
      wasCapped: cappedByTime || cappedByReward,
    );
  }

  void applyBoost(IdleBoost boost) {
    if (!config.enableBoosts) {
      return;
    }
    _boosts[boost.id] = boost;
  }

  void removeBoost(String boostId) {
    _boosts.remove(boostId);
  }

  void addModifier(IdleModifier modifier) {
    if (!config.enableModifiers) {
      return;
    }
    _modifiers[modifier.id] = modifier;
  }

  double getTotalMultiplier() {
    _cleanupExpiredBoosts();

    final additive = _modifiers.values
        .where((modifier) => modifier.type == IdleModifierType.additive)
        .fold<double>(0, (sum, modifier) => sum + modifier.value);

    final multiplicative = _modifiers.values
        .where((modifier) => modifier.type == IdleModifierType.multiplicative)
        .fold<double>(1, (product, modifier) => product * modifier.value);

    final boostMultiplier = _boosts.values.fold<double>(
      1,
      (product, boost) => product * boost.multiplier,
    );

    final total = (1 + additive) * multiplicative * boostMultiplier;
    if (!total.isFinite || total.isNaN) {
      return 1;
    }
    return math.max(0, total);
  }

  void startProduction() {
    if (_isProducing) {
      return;
    }

    _isProducing = true;
    _lastProductionAt = _nowProvider();
    _timer = Timer.periodic(config.tickInterval, (_) {
      _runProductionTick();
    });
  }

  void stopProduction() {
    _timer?.cancel();
    _timer = null;
    _isProducing = false;
  }

  void saveState() {
    _savedState = exportState();
  }

  void loadState() {
    if (_savedState == null) {
      return;
    }

    _totalProduced = (_savedState!['totalProduced'] as num?)?.toDouble() ?? 0;

    final lastProductionAtMs = _savedState!['lastProductionAtMs'] as int?;
    _lastProductionAt =
        lastProductionAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastProductionAtMs);

    _modifiers
      ..clear()
      ..addEntries(
        ((_savedState!['modifiers'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .map(IdleModifier.fromJson)
            .map((modifier) => MapEntry(modifier.id, modifier))),
      );

    _boosts
      ..clear()
      ..addEntries(
        ((_savedState!['boosts'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .map(IdleBoost.fromJson)
            .map((boost) => MapEntry(boost.id, boost))),
      );

    _cleanupExpiredBoosts();
  }

  void onPrestige() {
    _totalProduced = 0;
    _lastProductionAt = _nowProvider();
  }

  void onUpgrade(String upgradeId) {
    final existing = _modifiers[upgradeId];
    if (existing == null) {
      addModifier(
        IdleModifier(
          id: upgradeId,
          value: 1.05,
          type: IdleModifierType.multiplicative,
        ),
      );
      return;
    }

    addModifier(
      IdleModifier(
        id: upgradeId,
        value: existing.value + 0.05,
        type: existing.type,
      ),
    );
  }

  Map<String, dynamic> exportState() {
    return <String, dynamic>{
      'totalProduced': _totalProduced,
      'lastProductionAtMs': _lastProductionAt?.millisecondsSinceEpoch,
      'modifiers': _modifiers.values.map((modifier) => modifier.toJson()).toList(growable: false),
      'boosts': _boosts.values.map((boost) => boost.toJson()).toList(growable: false),
    };
  }

  void importState(Map<String, dynamic> state) {
    _savedState = Map<String, dynamic>.from(state);
  }

  void debugForceTick(Duration elapsed) {
    _produceForDuration(elapsed);
  }

  void _runProductionTick() {
    final now = _nowProvider();
    final reference = _lastProductionAt ?? now;
    final elapsed = now.difference(reference);

    _produceForDuration(elapsed);
    _lastProductionAt = now;
  }

  void _produceForDuration(Duration elapsed) {
    if (!_isProducing && elapsed == Duration.zero) {
      return;
    }

    final income = calculateIdleIncome(elapsed, config);
    if (income <= 0) {
      return;
    }

    final nextTotal = _totalProduced + income;
    _totalProduced = nextTotal.isFinite ? nextTotal : double.maxFinite;
  }

  void _cleanupExpiredBoosts() {
    final now = _nowProvider();
    _boosts.removeWhere((_, boost) => !boost.isActiveAt(now));
  }
}

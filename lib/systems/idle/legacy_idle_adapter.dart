import 'package:mg_common_game/systems/idle/idle_config.dart';
import 'package:mg_common_game/systems/idle/unified_idle_manager.dart';

class LegacyIdleAdapter {
  static UnifiedIdleManager fromLegacy(dynamic oldManager) {
    final config = _configFromLegacyState(exportState(oldManager));
    final manager = UnifiedIdleManager(config: config);
    importState(manager, exportState(oldManager));
    return manager;
  }

  static IdleConfig detectConfig(String gamePath) {
    final normalized = gamePath.toLowerCase();

    if (normalized.contains('mg-game-0004')) {
      return IdleConfig(
        tickInterval: const Duration(seconds: 1),
        baseProductionRate: 10,
        offlineCaps: OfflineCaps(
          maxOfflineTime: const Duration(hours: 8),
          maxOfflineReward: 50000,
          offlineEfficiency: 1.0,
        ),
      );
    }

    if (normalized.contains('mg-game-0010')) {
      return IdleConfig(
        tickInterval: const Duration(seconds: 1),
        baseProductionRate: 8,
        offlineCaps: OfflineCaps(
          maxOfflineTime: const Duration(hours: 2),
          maxOfflineReward: 15000,
          offlineEfficiency: 0.8,
        ),
      );
    }

    if (normalized.contains('mg-game-0030')) {
      return IdleConfig(
        tickInterval: const Duration(seconds: 1),
        baseProductionRate: 10,
        offlineCaps: OfflineCaps(
          maxOfflineTime: const Duration(hours: 24),
          maxOfflineReward: 50000,
          offlineEfficiency: 1.0,
        ),
      );
    }

    if (normalized.contains('mg-game-0045')) {
      return IdleConfig(
        tickInterval: const Duration(seconds: 1),
        baseProductionRate: 12,
        offlineCaps: OfflineCaps(
          maxOfflineTime: const Duration(hours: 24),
          maxOfflineReward: 100000,
          offlineEfficiency: 1.0,
        ),
      );
    }

    return IdleConfig.standard();
  }

  static Map<String, dynamic> exportState(dynamic oldManager) {
    if (oldManager == null) {
      return <String, dynamic>{};
    }

    try {
      final dynamic jsonState = oldManager.toJson();
      if (jsonState is Map) {
        return Map<String, dynamic>.from(jsonState);
      }
    } catch (_) {
      // Fallback to best-effort field extraction.
    }

    return <String, dynamic>{
      'totalProduced': _extractDouble(oldManager, 'totalProduced') ?? 0,
      'globalModifier': _extractDouble(oldManager, 'globalModifier') ?? 1,
      'resources': _extractMap(oldManager, 'resources') ?? <String, dynamic>{},
    };
  }

  static void importState(
    UnifiedIdleManager newManager,
    Map<String, dynamic> state,
  ) {
    final transformed = <String, dynamic>{
      'totalProduced': (state['totalProduced'] as num?)?.toDouble() ?? 0,
      'lastProductionAtMs': (state['lastProductionAtMs'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      'modifiers': _legacyModifiers(state),
      'boosts': _legacyBoosts(state),
    };

    newManager.importState(transformed);
    newManager.loadState();
  }

  static IdleConfig _configFromLegacyState(Map<String, dynamic> state) {
    final globalModifier = (state['globalModifier'] as num?)?.toDouble() ?? 1.0;
    final baseRate = (state['baseProductionRate'] as num?)?.toDouble() ?? 1.0;

    return IdleConfig(
      tickInterval: const Duration(seconds: 1),
      baseProductionRate: baseRate,
      offlineCaps: OfflineCaps.standard(),
      enableBoosts: true,
      enableModifiers: true,
      resources: const <IdleResource>[],
    ).copyWith(
      enableModifiers: globalModifier != 1.0,
    );
  }

  static List<Map<String, dynamic>> _legacyModifiers(Map<String, dynamic> state) {
    final modifiers = <Map<String, dynamic>>[];

    final globalModifier = (state['globalModifier'] as num?)?.toDouble();
    if (globalModifier != null && globalModifier != 1.0) {
      modifiers.add(
        IdleModifier(
          id: 'legacy_global_modifier',
          value: globalModifier,
          type: IdleModifierType.multiplicative,
        ).toJson(),
      );
    }

    return modifiers;
  }

  static List<Map<String, dynamic>> _legacyBoosts(Map<String, dynamic> state) {
    final rawBoosts = state['boosts'];
    if (rawBoosts is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawBoosts
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(IdleBoost.fromJson)
        .map((boost) => boost.toJson())
        .toList(growable: false);
  }

  static double? _extractDouble(dynamic source, String property) {
    try {
      final dynamic value = source.toJson()[property];
      return (value as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _extractMap(dynamic source, String property) {
    try {
      final dynamic value = source.toJson()[property];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

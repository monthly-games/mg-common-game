import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interface for systems that can be saved/loaded
abstract class Saveable {
  /// Unique identifier for this saveable system
  String get saveKey;

  /// Save data to a map
  Map<String, dynamic> toSaveData();

  /// Load data from a map
  void fromSaveData(Map<String, dynamic> data);
}

/// Centralized save/load manager for all game systems
class SaveManager extends ChangeNotifier {
  final Map<String, Saveable> _saveableSystems = {};
  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = true;
  int _autoSaveIntervalSeconds = 30; // Default: save every 30 seconds

  DateTime? _lastSaveTime;
  DateTime? _lastLoadTime;

  // Getters
  bool get autoSaveEnabled => _autoSaveEnabled;
  int get autoSaveIntervalSeconds => _autoSaveIntervalSeconds;
  DateTime? get lastSaveTime => _lastSaveTime;
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Register a system that can be saved/loaded
  void registerSaveable(Saveable saveable) {
    _saveableSystems[saveable.saveKey] = saveable;
    debugPrint('[SaveManager] Registered: ${saveable.saveKey}');
  }

  /// Unregister a saveable system
  void unregisterSaveable(String key) {
    _saveableSystems.remove(key);
    debugPrint('[SaveManager] Unregistered: $key');
  }

  /// Enable or disable auto-save
  void setAutoSaveEnabled(bool enabled) {
    _autoSaveEnabled = enabled;
    if (enabled) {
      _startAutoSave();
    } else {
      _stopAutoSave();
    }
    notifyListeners();
  }

  /// Set auto-save interval in seconds
  void setAutoSaveInterval(int seconds) {
    if (seconds < 5) {
      debugPrint('[SaveManager] Auto-save interval too short, using minimum of 5 seconds');
      seconds = 5;
    }
    _autoSaveIntervalSeconds = seconds;

    // Restart timer with new interval if auto-save is enabled
    if (_autoSaveEnabled) {
      _stopAutoSave();
      _startAutoSave();
    }
    notifyListeners();
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _autoSaveIntervalSeconds),
      (_) => saveAll(),
    );
    debugPrint('[SaveManager] Auto-save started (interval: ${_autoSaveIntervalSeconds}s)');
  }

  /// Stop auto-save timer
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    debugPrint('[SaveManager] Auto-save stopped');
  }

  /// Save all registered systems
  Future<void> saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in _saveableSystems.entries) {
        final key = entry.key;
        final saveable = entry.value;

        try {
          final data = saveable.toSaveData();
          final jsonString = _encodeMap(data);
          await prefs.setString('save_$key', jsonString);
        } catch (e) {
          debugPrint('[SaveManager] Error saving $key: $e');
        }
      }

      _lastSaveTime = DateTime.now();
      await prefs.setString('save_last_save_time', _lastSaveTime!.toIso8601String());

      debugPrint('[SaveManager] Saved ${_saveableSystems.length} systems');
      notifyListeners();
    } catch (e) {
      debugPrint('[SaveManager] Error in saveAll: $e');
    }
  }

  /// Load all registered systems
  Future<void> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in _saveableSystems.entries) {
        final key = entry.key;
        final saveable = entry.value;

        try {
          final jsonString = prefs.getString('save_$key');
          if (jsonString != null) {
            final data = _decodeMap(jsonString);
            saveable.fromSaveData(data);
          }
        } catch (e) {
          debugPrint('[SaveManager] Error loading $key: $e');
        }
      }

      final lastSaveString = prefs.getString('save_last_save_time');
      if (lastSaveString != null) {
        _lastSaveTime = DateTime.parse(lastSaveString);
      }

      _lastLoadTime = DateTime.now();

      debugPrint('[SaveManager] Loaded ${_saveableSystems.length} systems');
      notifyListeners();
    } catch (e) {
      debugPrint('[SaveManager] Error in loadAll: $e');
    }
  }

  /// Save a specific system by key
  Future<void> saveSystem(String key) async {
    final saveable = _saveableSystems[key];
    if (saveable == null) {
      debugPrint('[SaveManager] System not found: $key');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = saveable.toSaveData();
      final jsonString = _encodeMap(data);
      await prefs.setString('save_$key', jsonString);

      debugPrint('[SaveManager] Saved system: $key');
    } catch (e) {
      debugPrint('[SaveManager] Error saving $key: $e');
    }
  }

  /// Load a specific system by key
  Future<void> loadSystem(String key) async {
    final saveable = _saveableSystems[key];
    if (saveable == null) {
      debugPrint('[SaveManager] System not found: $key');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('save_$key');
      if (jsonString != null) {
        final data = _decodeMap(jsonString);
        saveable.fromSaveData(data);

        debugPrint('[SaveManager] Loaded system: $key');
      }
    } catch (e) {
      debugPrint('[SaveManager] Error loading $key: $e');
    }
  }

  /// Clear all saved data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final key in _saveableSystems.keys) {
        await prefs.remove('save_$key');
      }

      await prefs.remove('save_last_save_time');
      _lastSaveTime = null;
      _lastLoadTime = null;

      debugPrint('[SaveManager] Cleared all save data');
      notifyListeners();
    } catch (e) {
      debugPrint('[SaveManager] Error clearing data: $e');
    }
  }

  /// Check if save data exists for a specific system
  Future<bool> hasSaveData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('save_$key');
    } catch (e) {
      debugPrint('[SaveManager] Error checking save data: $e');
      return false;
    }
  }

  /// Get list of all registered system keys
  List<String> getRegisteredKeys() {
    return _saveableSystems.keys.toList();
  }

  // Simple JSON encoding/decoding for Map<String, dynamic>
  String _encodeMap(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;

    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;

      buffer.write('"$key":');

      if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is int || value is double || value is bool) {
        buffer.write(value.toString());
      } else if (value == null) {
        buffer.write('null');
      } else {
        buffer.write('"$value"');
      }
    });

    buffer.write('}');
    return buffer.toString();
  }

  Map<String, dynamic> _decodeMap(String jsonString) {
    final map = <String, dynamic>{};

    // Simple JSON parser for our use case
    final content = jsonString.substring(1, jsonString.length - 1);
    if (content.isEmpty) return map;

    final pairs = <String>[];
    var current = '';
    var inString = false;
    var depth = 0;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"' && (i == 0 || content[i - 1] != '\\')) {
        inString = !inString;
      }

      if (!inString && (char == '{' || char == '[')) depth++;
      if (!inString && (char == '}' || char == ']')) depth--;

      if (!inString && char == ',' && depth == 0) {
        pairs.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      pairs.add(current.trim());
    }

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex == -1) continue;

      var key = pair.substring(0, colonIndex).trim();
      var value = pair.substring(colonIndex + 1).trim();

      // Remove quotes from key
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }

      // Parse value
      if (value == 'null') {
        map[key] = null;
      } else if (value == 'true') {
        map[key] = true;
      } else if (value == 'false') {
        map[key] = false;
      } else if (value.startsWith('"') && value.endsWith('"')) {
        map[key] = value.substring(1, value.length - 1).replaceAll('\\"', '"');
      } else if (value.contains('.')) {
        map[key] = double.tryParse(value) ?? value;
      } else {
        map[key] = int.tryParse(value) ?? value;
      }
    }

    return map;
  }

  @override
  void dispose() {
    _stopAutoSave();
    super.dispose();
  }
}

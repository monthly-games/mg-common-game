import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for persisting game data
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  static LocalStorageService get instance => _instance;

  LocalStorageService._internal();

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('LocalStorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ==================== String Operations ====================

  /// Save a string value
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  /// Get a string value
  String? getString(String key) {
    return _preferences.getString(key);
  }

  // ==================== Integer Operations ====================

  /// Save an integer value
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  /// Get an integer value
  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  // ==================== Boolean Operations ====================

  /// Save a boolean value
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  /// Get a boolean value
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  // ==================== Double Operations ====================

  /// Save a double value
  Future<bool> setDouble(String key, double value) async {
    return await _preferences.setDouble(key, value);
  }

  /// Get a double value
  double? getDouble(String key) {
    return _preferences.getDouble(key);
  }

  // ==================== JSON Operations ====================

  /// Save a JSON object
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  /// Get a JSON object
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save a JSON list
  Future<bool> setJsonList(String key, List<dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  /// Get a JSON list
  List<dynamic>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ==================== String List Operations ====================

  /// Save a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }

  /// Get a list of strings
  List<String>? getStringList(String key) {
    return _preferences.getStringList(key);
  }

  // ==================== Generic Operations ====================

  /// Check if a key exists
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  /// Clear all data
  Future<bool> clear() async {
    return await _preferences.clear();
  }

  /// Get all keys
  Set<String> getKeys() {
    return _preferences.getKeys();
  }

  // ==================== Batch Operations ====================

  /// Remove multiple keys
  Future<void> removeMultiple(List<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }

  /// Clear all keys with a specific prefix
  Future<void> clearWithPrefix(String prefix) async {
    final keys = getKeys().where((key) => key.startsWith(prefix)).toList();
    await removeMultiple(keys);
  }

  // ==================== Game Specific Helpers ====================

  /// Save user progress data
  Future<bool> saveUserProgress(String userId, Map<String, dynamic> progress) async {
    return await setJson('user_progress_$userId', progress);
  }

  /// Get user progress data
  Map<String, dynamic>? getUserProgress(String userId) {
    return getJson('user_progress_$userId');
  }

  /// Save inventory data
  Future<bool> saveInventory(String userId, List<Map<String, dynamic>> items) async {
    return await setJsonList('inventory_$userId', items);
  }

  /// Get inventory data
  List<Map<String, dynamic>>? getInventory(String userId) {
    final list = getJsonList('inventory_$userId');
    return list?.cast<Map<String, dynamic>>();
  }

  /// Save settings
  Future<bool> saveSettings(String userId, Map<String, dynamic> settings) async {
    return await setJson('settings_$userId', settings);
  }

  /// Get settings
  Map<String, dynamic>? getSettings(String userId) {
    return getJson('settings_$userId');
  }

  /// Save cached data with timestamp
  Future<bool> setCache(String key, dynamic data, {Duration? ttl}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (ttl != null) 'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
    };
    return await setJson('cache_$key', cacheData);
  }

  /// Get cached data
  T? getCache<T>(String key) {
    final cacheData = getJson('cache_$key');
    if (cacheData == null) return null;

    // Check if expired
    final expiresAt = cacheData['expiresAt'] as int?;
    if (expiresAt != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > expiresAt) {
        remove('cache_$key');
        return null;
      }
    }

    return cacheData['data'] as T?;
  }

  /// Check if cache is valid
  bool isCacheValid(String key) {
    final cacheData = getJson('cache_$key');
    if (cacheData == null) return false;

    final expiresAt = cacheData['expiresAt'] as int?;
    if (expiresAt == null) return true;

    return DateTime.now().millisecondsSinceEpoch <= expiresAt;
  }
}

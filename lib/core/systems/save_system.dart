import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SaveSystem {
  Future<void> init();
  Future<void> save(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> load(String key);
}

class LocalSaveSystem implements SaveSystem {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await _prefs?.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('CoreSystem: Failed to decode save data for $key: $e');
      return null;
    }
  }
}

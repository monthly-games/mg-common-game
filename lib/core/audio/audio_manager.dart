import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_settings.dart';

/// Audio Manager for BGM and SFX playback with persistence
@singleton
class AudioManager extends ChangeNotifier {
  static const String _settingsKey = 'audio_settings';

  AudioSettings _settings = AudioSettings.defaults;
  final Set<String> _preloadedSfx = {};
  final Set<String> _preloadedBgm = {};
  bool _initialized = false;

  /// Current audio settings
  AudioSettings get settings => _settings;

  /// Check if audio is muted
  bool get isMuted => _settings.isMuted;

  /// Master volume (0.0 to 1.0)
  double get masterVolume => _settings.masterVolume;

  /// BGM volume (0.0 to 1.0)
  double get bgmVolume => _settings.bgmVolume;

  /// SFX volume (0.0 to 1.0)
  double get sfxVolume => _settings.sfxVolume;

  /// Initialize audio manager and load saved settings
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_settingsKey);
      if (savedData != null) {
        final json = _parseJson(savedData);
        if (json != null) {
          _settings = AudioSettings.fromJson(json);
        }
      }
    } catch (e) {
      debugPrint('AudioManager: Failed to load settings: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  /// Preload SFX files for faster playback
  Future<void> preloadSfx(List<String> fileNames) async {
    for (final fileName in fileNames) {
      if (!_preloadedSfx.contains(fileName)) {
        try {
          await FlameAudio.audioCache.load(fileName);
          _preloadedSfx.add(fileName);
        } catch (e) {
          debugPrint('AudioManager: Failed to preload SFX $fileName: $e');
        }
      }
    }
  }

  /// Preload BGM files
  Future<void> preloadBgm(List<String> fileNames) async {
    for (final fileName in fileNames) {
      if (!_preloadedBgm.contains(fileName)) {
        try {
          await FlameAudio.audioCache.load(fileName);
          _preloadedBgm.add(fileName);
        } catch (e) {
          debugPrint('AudioManager: Failed to preload BGM $fileName: $e');
        }
      }
    }
  }

  /// Clear all preloaded audio cache
  void clearCache() {
    FlameAudio.audioCache.clearAll();
    _preloadedSfx.clear();
    _preloadedBgm.clear();
  }

  /// Play background music (loops by default)
  void playBgm(String fileName, {double volume = 1.0}) {
    if (_settings.isMuted) return;
    final effectiveVolume = volume * _settings.effectiveBgmVolume;
    FlameAudio.bgm.play(fileName, volume: effectiveVolume);
  }

  /// Stop background music
  void stopBgm() {
    FlameAudio.bgm.stop();
  }

  /// Pause background music
  void pauseBgm() {
    FlameAudio.bgm.pause();
  }

  /// Resume background music
  void resumeBgm() {
    if (_settings.isMuted) return;
    FlameAudio.bgm.resume();
  }

  /// Play a sound effect once
  Future<void> playSfx(
    String fileName, {
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    if (_settings.isMuted) return;
    try {
      final effectiveVolume = volume * _settings.effectiveSfxVolume;
      final player = await FlameAudio.play(fileName, volume: effectiveVolume);
      if (pitch != 1.0) {
        await player.setPlaybackRate(pitch);
      }
    } catch (e) {
      debugPrint('AudioManager: Error playing SFX $fileName: $e');
    }
  }

  /// Play UI sound (uses SFX channel with slightly reduced volume)
  Future<void> playUiSound(String fileName) async {
    await playSfx(fileName, volume: 0.7);
  }

  /// Set Master Volume (0.0 to 1.0)
  Future<void> setMasterVolume(double value) async {
    _settings = _settings.copyWith(masterVolume: value.clamp(0.0, 1.0));
    await _saveSettings();
    notifyListeners();
  }

  /// Set BGM Volume (0.0 to 1.0)
  Future<void> setBgmVolume(double value) async {
    _settings = _settings.copyWith(bgmVolume: value.clamp(0.0, 1.0));
    await _saveSettings();
    notifyListeners();
  }

  /// Set SFX Volume (0.0 to 1.0)
  Future<void> setSfxVolume(double value) async {
    _settings = _settings.copyWith(sfxVolume: value.clamp(0.0, 1.0));
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle mute state
  Future<void> toggleMute() async {
    _settings = _settings.copyWith(isMuted: !_settings.isMuted);
    if (_settings.isMuted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
    await _saveSettings();
    notifyListeners();
  }

  /// Set mute state directly
  Future<void> setMuted(bool muted) async {
    if (_settings.isMuted == muted) return;
    _settings = _settings.copyWith(isMuted: muted);
    if (muted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
    await _saveSettings();
    notifyListeners();
  }

  /// Apply all settings at once
  Future<void> applySettings(AudioSettings newSettings) async {
    final wasMuted = _settings.isMuted;
    _settings = newSettings;

    if (newSettings.isMuted && !wasMuted) {
      FlameAudio.bgm.pause();
    } else if (!newSettings.isMuted && wasMuted) {
      FlameAudio.bgm.resume();
    }

    await _saveSettings();
    notifyListeners();
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await applySettings(AudioSettings.defaults);
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _encodeJson(_settings.toJson());
      await prefs.setString(_settingsKey, json);
    } catch (e) {
      debugPrint('AudioManager: Failed to save settings: $e');
    }
  }

  Map<String, dynamic>? _parseJson(String data) {
    try {
      // Simple JSON parsing without importing dart:convert in header
      // This handles the basic format we save
      final result = <String, dynamic>{};
      final content = data.trim();
      if (!content.startsWith('{') || !content.endsWith('}')) return null;

      final inner = content.substring(1, content.length - 1);
      final pairs = inner.split(',');

      for (final pair in pairs) {
        final colonIndex = pair.indexOf(':');
        if (colonIndex == -1) continue;

        final key =
            pair.substring(0, colonIndex).trim().replaceAll('"', '');
        final valueStr = pair.substring(colonIndex + 1).trim();

        if (valueStr == 'true') {
          result[key] = true;
        } else if (valueStr == 'false') {
          result[key] = false;
        } else {
          result[key] = double.tryParse(valueStr) ?? valueStr;
        }
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  String _encodeJson(Map<String, dynamic> data) {
    final pairs = data.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return '"${e.key}":"$value"';
      }
      return '"${e.key}":$value';
    }).join(',');
    return '{$pairs}';
  }
}

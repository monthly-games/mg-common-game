import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';

/// Intensity levels for haptic feedback
enum VibrationIntensity {
  light,
  medium,
  heavy,
}

/// Manages game settings (sound, music, vibration)
class SettingsManager extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;

  AudioManager? _audioManager;

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  /// Connect to AudioManager for audio control
  void setAudioManager(AudioManager audioManager) {
    _audioManager = audioManager;
    _applyAudioSettings();
  }

  /// Enable/disable sound effects
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _applyAudioSettings();
    notifyListeners();
    saveSettings();
  }

  /// Enable/disable background music
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    _applyAudioSettings();
    notifyListeners();
    saveSettings();
  }

  /// Enable/disable vibration
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
    saveSettings();
  }

  /// Apply audio settings to AudioManager
  void _applyAudioSettings() {
    if (_audioManager == null) return;

    // Control SFX volume
    if (_soundEnabled) {
      _audioManager!.setSfxVolume(1.0);
    } else {
      _audioManager!.setSfxVolume(0.0);
    }

    // Control BGM
    if (_musicEnabled) {
      _audioManager!.resumeBgm();
    } else {
      _audioManager!.pauseBgm();
    }
  }

  /// Trigger vibration with specified intensity
  Future<void> triggerVibration({
    VibrationIntensity intensity = VibrationIntensity.light,
  }) async {
    if (!_vibrationEnabled) return;

    // Check if device has vibrator
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    // Vibrate based on intensity
    switch (intensity) {
      case VibrationIntensity.light:
        await Vibration.vibrate(duration: 50);
        break;
      case VibrationIntensity.medium:
        await Vibration.vibrate(duration: 100);
        break;
      case VibrationIntensity.heavy:
        await Vibration.vibrate(duration: 200);
        break;
    }
  }

  // ========== SAVE/LOAD SYSTEM ==========

  /// Save settings to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_sound', _soundEnabled);
    await prefs.setBool('settings_music', _musicEnabled);
    await prefs.setBool('settings_vibration', _vibrationEnabled);
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('settings_sound') ?? true;
    _musicEnabled = prefs.getBool('settings_music') ?? true;
    _vibrationEnabled = prefs.getBool('settings_vibration') ?? true;

    // Apply to AudioManager if connected
    _applyAudioSettings();

    notifyListeners();
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('settings_sound');
    await prefs.remove('settings_music');
    await prefs.remove('settings_vibration');

    // Reset to defaults
    _soundEnabled = true;
    _musicEnabled = true;
    _vibrationEnabled = true;

    _applyAudioSettings();
    notifyListeners();
  }
}

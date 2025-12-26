import 'package:flame_audio/flame_audio.dart';

/// Audio feedback manager for UI sounds
class AudioFeedbackManager {
  bool _enabled = true;
  double _volume = 1.0;
  bool _initialized = false;

  final Map<String, String> _soundPaths = {};

  bool get enabled => _enabled;
  double get volume => _volume;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  /// Register sound paths for feedback types
  void registerSounds({
    String? buttonClick,
    String? buttonHover,
    String? popupOpen,
    String? popupClose,
    String? success,
    String? error,
    String? warning,
    String? levelUp,
    String? coinCollect,
    String? purchase,
    String? notification,
  }) {
    if (buttonClick != null) _soundPaths['buttonClick'] = buttonClick;
    if (buttonHover != null) _soundPaths['buttonHover'] = buttonHover;
    if (popupOpen != null) _soundPaths['popupOpen'] = popupOpen;
    if (popupClose != null) _soundPaths['popupClose'] = popupClose;
    if (success != null) _soundPaths['success'] = success;
    if (error != null) _soundPaths['error'] = error;
    if (warning != null) _soundPaths['warning'] = warning;
    if (levelUp != null) _soundPaths['levelUp'] = levelUp;
    if (coinCollect != null) _soundPaths['coinCollect'] = coinCollect;
    if (purchase != null) _soundPaths['purchase'] = purchase;
    if (notification != null) _soundPaths['notification'] = notification;
  }

  /// Preload all registered sounds
  Future<void> preload() async {
    for (final path in _soundPaths.values) {
      try {
        await FlameAudio.audioCache.load(path);
      } catch (e) {
        // Ignore missing files
      }
    }
    _initialized = true;
  }

  /// Play a registered sound
  Future<void> _play(String key) async {
    if (!_enabled || !_initialized) return;

    final path = _soundPaths[key];
    if (path == null) return;

    try {
      await FlameAudio.play(path, volume: _volume);
    } catch (e) {
      // Ignore playback errors
    }
  }

  // ============================================================
  // UI Feedback Sounds
  // ============================================================

  /// Button click sound
  Future<void> buttonClick() async {
    await _play('buttonClick');
  }

  /// Button hover sound
  Future<void> buttonHover() async {
    await _play('buttonHover');
  }

  /// Popup open sound
  Future<void> popupOpen() async {
    await _play('popupOpen');
  }

  /// Popup close sound
  Future<void> popupClose() async {
    await _play('popupClose');
  }

  // ============================================================
  // Game Feedback Sounds
  // ============================================================

  /// Success sound
  Future<void> success() async {
    await _play('success');
  }

  /// Error sound
  Future<void> error() async {
    await _play('error');
  }

  /// Warning sound
  Future<void> warning() async {
    await _play('warning');
  }

  /// Level up sound
  Future<void> levelUp() async {
    await _play('levelUp');
  }

  /// Coin collect sound
  Future<void> coinCollect() async {
    await _play('coinCollect');
  }

  /// Purchase sound
  Future<void> purchase() async {
    await _play('purchase');
  }

  /// Notification sound
  Future<void> notification() async {
    await _play('notification');
  }
}

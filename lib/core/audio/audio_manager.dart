import 'package:flame_audio/flame_audio.dart';
import 'package:injectable/injectable.dart';

@singleton
class AudioManager {
  double _masterVolume = 1.0;
  double _bgmVolume = 1.0;
  double _sfxVolume = 1.0;
  bool _isMuted = false;

  Future<void> initialize() async {
    // Preload common sounds if any?
    // FlameAudio.bgm.initialize(); // Not strictly needed in newer versions but good constraint
  }

  /// Play background music (loops by default)
  void playBgm(String fileName, {double volume = 1.0}) {
    if (_isMuted) return;
    FlameAudio.bgm.play(fileName, volume: volume * _bgmVolume * _masterVolume);
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
    if (_isMuted) return;
    FlameAudio.bgm.resume();
  }

  /// Play a sound effect once
  Future<void> playSfx(String fileName,
      {double volume = 1.0, double pitch = 1.0}) async {
    if (_isMuted) return;
    try {
      final player = await FlameAudio.play(fileName,
          volume: volume * _sfxVolume * _masterVolume);
      if (pitch != 1.0) {
        await player.setPlaybackRate(pitch);
      }
    } catch (e) {
      print('Error playing SFX $fileName: $e');
    }
  }

  /// Set Master Volume (0.0 to 1.0)
  void setMasterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
    _updateBgmVolume();
  }

  /// Set BGM Volume (0.0 to 1.0)
  void setBgmVolume(double value) {
    _bgmVolume = value.clamp(0.0, 1.0);
    _updateBgmVolume();
  }

  /// Set SFX Volume (0.0 to 1.0)
  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
  }

  void _updateBgmVolume() {
    // FlameAudio.bgm.audioPlayer is exposed? Or likely just re-play logic needed if dynamic
    // FlameAudio.bgm doesn't support dynamic volume change easily without stopping in some versions
    // But for now let's assume play API handles it or future plays use it.
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오디오 타입
enum AudioType {
  bgm,
  sfx,
  voice,
}

/// 볼륨 타입
enum VolumeType {
  master,
  bgm,
  sfx,
  voice,
}

/// 오디오 트랙
class AudioTrack {
  final String id;
  final String path;
  final AudioType type;
  final double volume;
  final bool loop;
  final String? assetPath;

  const AudioTrack({
    required this.id,
    required this.path,
    required this.type,
    this.volume = 1.0,
    this.loop = false,
    this.assetPath,
  });
}

/// BGM 트랙 정보
class BgmTrack {
  final String id;
  final String name;
  final String assetPath;
  final double fadeIn;
  final double fadeOut;

  const BgmTrack({
    required this.id,
    required this.name,
    required this.assetPath,
    this.fadeIn = 1.0,
    this.fadeOut = 1.0,
  });
}

/// 효과음 (풀링용)
class SfxPool {
  final String id;
  final AudioPlayer player;
  int referenceCount;

  SfxPool({
    required this.id,
    required this.player,
    this.referenceCount = 0,
  });
}

/// 오디오 매니저
class AudioManager {
  static final AudioManager _instance = AudioManager._();
  static AudioManager get instance => _instance;

  AudioManager._();

  // ============================================
  // 상태
  // ============================================
  SharedPreferences? _prefs;

  // 플레이어
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _sfxPlayers = {};
  final Map<String, AudioPlayer> _voicePlayers = {};

  // 풀
  final List<SfxPool> _sfxPool = [];
  static const int _maxPoolSize = 10;

  // 볼륨
  double _masterVolume = 1.0;
  double _bgmVolume = 0.7;
  double _sfxVolume = 1.0;
  double _voiceVolume = 1.0;

  // 상태
  bool _isMuted = false;
  bool _isInitialized = false;
  BgmTrack? _currentBgm;

  // 리스너
  final StreamController<String> _bgmChangeController =
      StreamController<String>.broadcast();
  final StreamController<bool> _muteController =
      StreamController<bool>.broadcast();

  // Getters
  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  double get masterVolume => _masterVolume;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  double get voiceVolume => _voiceVolume;
  BgmTrack? get currentBgm => _currentBgm;
  Stream<String> get onBgmChanged => _bgmChangeController.stream;
  Stream<bool> get onMuteChanged => _muteController.stream;

  // ============================================
  // 초기화
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // 설정 로드
    _masterVolume = _prefs!.getDouble('master_volume') ?? 1.0;
    _bgmVolume = _prefs!.getDouble('bgm_volume') ?? 0.7;
    _sfxVolume = _prefs!.getDouble('sfx_volume') ?? 1.0;
    _voiceVolume = _prefs!.getDouble('voice_volume') ?? 1.0;
    _isMuted = _prefs!.getBool('is_muted') ?? false;

    _isInitialized = true;

    debugPrint('[Audio] Initialized');
  }

  // ============================================
  // BGM 관리
  // ============================================

  /// BGM 재생
  Future<void> playBgm({
    required BgmTrack track,
    bool fadeIn = true,
  }) async {
    if (!_isInitialized) await initialize();

    // 현재 BGM과 같으면 무시
    if (_currentBgm?.id == track.id) {
      if (_bgmPlayer.playing) return;
      await _bgmPlayer.play();
      return;
    }

    // 이전 BGM 중지
    await stopBgm(fadeOut: fadeIn);

    _currentBgm = track;

    try {
      if (track.assetPath != null) {
        // Asset에서 로드
        await _bgmPlayer.setAsset(track.assetPath!);
      } else {
        // 파일/URL에서 로드
        await _bgmPlayer.setUrl(track.path);
      }

      // 볼륨 설정 (페이드인)
      final volume = _calculateVolume(AudioType.bgm);
      if (fadeIn) {
        await _bgmPlayer.setVolume(0);
        await _bgmPlayer.play();
        await _bgmPlayer.fadeIn(duration: Duration(milliseconds: (track.fadeIn * 1000).toInt()), toVolume: volume * _bgmVolume);
      } else {
        await _bgmPlayer.setVolume(volume);
        await _bgmPlayer.play();
      }

      // 루프 설정
      if (track.loop) {
        await _bgmPlayer.setLoopMode(LoopMode.one);
      }

      _bgmChangeController.add(track.id);
      debugPrint('[Audio] BGM started: ${track.name}');
    } catch (e) {
      debugPrint('[Audio] Error playing BGM: $e');
    }
  }

  /// BGM 중지
  Future<void> stopBgm({bool fadeOut = true}) async {
    if (!_bgmPlayer.playing) return;

    if (fadeOut && _currentBgm != null) {
      final duration = Duration(milliseconds: ((_currentBgm?.fadeOut ?? 1.0) * 1000).toInt());
      await _bgmPlayer.fadeOut(duration: duration, toVolume: 0);
    }

    await _bgmPlayer.stop();
    await _bgmPlayer.seek(Duration.zero);

    _currentBgm = null;
    debugPrint('[Audio] BGM stopped');
  }

  /// BGM 일시정지
  Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
    debugPrint('[Audio] BGM paused');
  }

  /// BGM 재개
  Future<void> resumeBgm() async {
    await _bgmPlayer.play();
    debugPrint('[Audio] BGM resumed');
  }

  /// BGM 볼륨 변경
  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    await _prefs!.setDouble('bgm_volume', _bgmVolume);

    final effectiveVolume = _calculateVolume(AudioType.bgm);
    await _bgmPlayer.setVolume(effectiveVolume);

    debugPrint('[Audio] BGM volume: $_bgmVolume');
  }

  // ============================================
  // 효과음 (SFX) 관리
  // ============================================

  /// SFX 재생
  Future<void> playSfx({
    required String assetPath,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (!_isInitialized) await initialize();

    // 풀에서 사용 가능한 플레이어 찾기
    final pool = _sfxPool.firstWhere(
      (p) => !p.player.playing,
      orElse: () {
        if (_sfxPool.length < _maxPoolSize) {
          // 새 플레이어 생성
          final player = AudioPlayer();
          final newPool = SfxPool(id: assetPath, player: player);
          _sfxPool.add(newPool);
          return newPool;
        }
        // 가장 오래된 플레이어 재사용
        return _sfxPool.removeAt(0);
      },
    );

    try {
      await pool.player.setAsset(assetPath);
      await pool.player.setVolume(_calculateVolume(AudioType.sfx) * volume);

      if (loop) {
        await pool.player.setLoopMode(LoopMode.one);
      }

      await pool.player.play();
      debugPrint('[Audio] SFX played: $assetPath');
    } catch (e) {
      debugPrint('[Audio] Error playing SFX: $e');
    }
  }

  /// SFX 중지
  Future<void> stopSfx(String assetPath) async {
    for (final pool in _sfxPool) {
      if (pool.id == assetPath && pool.player.playing) {
        await pool.player.stop();
        break;
      }
    }
  }

  /// 모든 SFX 중지
  Future<void> stopAllSfx() async {
    for (final pool in _sfxPool) {
      if (pool.player.playing) {
        await pool.player.stop();
      }
    }
  }

  /// SFX 볼륨 변경
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _prefs!.setDouble('sfx_volume', _sfxVolume);

    for (final pool in _sfxPool) {
      if (pool.player.playing) {
        await pool.player.setVolume(_calculateVolume(AudioType.sfx));
      }
    }

    debugPrint('[Audio] SFX volume: $_sfxVolume');
  }

  // ============================================
  // 보이스 관리
  // ============================================

  /// 보이스 재생
  Future<void> playVoice({
    required String assetPath,
    double volume = 1.0,
  }) async {
    if (!_isInitialized) await initialize();

    final playerId = 'voice_${assetPath.hashCode}';
    AudioPlayer? player = _voicePlayers[playerId];

    if (player == null) {
      player = AudioPlayer();
      _voicePlayers[playerId] = player;

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          player!.dispose();
          _voicePlayers.remove(playerId);
        }
      });
    }

    try {
      await player!.setAsset(assetPath);
      await player.setVolume(_calculateVolume(AudioType.voice) * volume);
      await player.play();
      debugPrint('[Audio] Voice played: $assetPath');
    } catch (e) {
      debugPrint('[Audio] Error playing voice: $e');
    }
  }

  /// 보이스 중지
  Future<void> stopVoice(String assetPath) async {
    final playerId = 'voice_${assetPath.hashCode}';
    final player = _voicePlayers[playerId];

    if (player != null) {
      await player.stop();
    }
  }

  /// 보이스 볼륨 변경
  Future<void> setVoiceVolume(double volume) async {
    _voiceVolume = volume.clamp(0.0, 1.0);
    await _prefs!.setDouble('voice_volume', _voiceVolume);

    for (final player in _voicePlayers.values) {
      if (player.playing) {
        await player.setVolume(_calculateVolume(AudioType.voice));
      }
    }

    debugPrint('[Audio] Voice volume: $_voiceVolume');
  }

  // ============================================
  // 마스터 볼륨
  // ============================================

  /// 마스터 볼륨 설정
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _prefs!.setDouble('master_volume', _masterVolume);

    // 모든 플레이어 볼륨 업데이트
    await _bgmPlayer.setVolume(_calculateVolume(AudioType.bgm));

    for (final pool in _sfxPool) {
      if (pool.player.playing) {
        await pool.player.setVolume(_calculateVolume(AudioType.sfx));
      }
    }

    for (final player in _voicePlayers.values) {
      if (player.playing) {
        await player.setVolume(_calculateVolume(AudioType.voice));
      }
    }

    debugPrint('[Audio] Master volume: $_masterVolume');
  }

  /// 볼륨 타입별 설정
  Future<void> setVolume(VolumeType type, double volume) async {
    switch (type) {
      case VolumeType.master:
        await setMasterVolume(volume);
        break;
      case VolumeType.bgm:
        await setBgmVolume(volume);
        break;
      case VolumeType.sfx:
        await setSfxVolume(volume);
        break;
      case VolumeType.voice:
        await setVoiceVolume(volume);
        break;
    }
  }

  /// 유효 볼륨 계산
  double _calculateVolume(AudioType type) {
    double typeVolume;

    switch (type) {
      case AudioType.bgm:
        typeVolume = _bgmVolume;
        break;
      case AudioType.sfx:
        typeVolume = _sfxVolume;
        break;
      case AudioType.voice:
        typeVolume = _voiceVolume;
        break;
    }

    return _masterVolume * typeVolume * (_isMuted ? 0 : 1);
  }

  // ============================================
  // 뮤트
  // ============================================

  /// 뮤트 토글
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _prefs!.setBool('is_muted', _isMuted);

    // 모든 볼륨 업데이트
    await _bgmPlayer.setVolume(_calculateVolume(AudioType.bgm));

    for (final pool in _sfxPool) {
      if (pool.player.playing) {
        await pool.player.setVolume(_calculateVolume(AudioType.sfx));
      }
    }

    _muteController.add(_isMuted);
    debugPrint('[Audio] Muted: $_isMuted');
  }

  /// 뮤트 설정
  Future<void> setMute(bool muted) async {
    if (_isMuted != muted) {
      await toggleMute();
    }
  }

  // ============================================
  // 오디오 프리로딩
  // ============================================

  /// SFX 프리로드
  Future<void> preloadSfx(List<String> assetPaths) async {
    for (final path in assetPaths) {
      if (_sfxPool.any((p) => p.id == path)) continue;

      try {
        final player = AudioPlayer();
        await player.setAsset(path);
        _sfxPool.add(SfxPool(id: path, player: player));
      } catch (e) {
        debugPrint('[Audio] Error preloading SFX: $path - $e');
      }
    }

    debugPrint('[Audio] Preloaded ${assetPaths.length} SFX');
  }

  /// BGM 프리로드
  Future<void> preloadBgm(BgmTrack track) async {
    try {
      if (track.assetPath != null) {
        await _bgmPlayer.setAsset(track.assetPath!);
      } else {
        await _bgmPlayer.setUrl(track.path);
      }

      debugPrint('[Audio] Preloaded BGM: ${track.name}');
    } catch (e) {
      debugPrint('[Audio] Error preloading BGM: $e');
    }
  }

  // ============================================
  // 리소스 정리
  // ============================================

  Future<void> dispose() async {
    await stopBgm(fadeOut: false);
    await stopAllSfx();

    for (final pool in _sfxPool) {
      await pool.player.dispose();
    }
    _sfxPool.clear();

    for (final player in _voicePlayers.values) {
      await player.dispose();
    }
    _voicePlayers.clear();

    await _bgmPlayer.dispose();

    _bgmChangeController.close();
    _muteController.close();

    debugPrint('[Audio] Disposed');
  }
}

/// AudioPlayer 확장 (페이드 인/아웃)
extension AudioPlayerFade on AudioPlayer {
  Future<void> fadeIn({required Duration duration, required double toVolume}) async {
    final steps = 20;
    final stepDuration = duration ~/ steps;
    final volumeStep = toVolume / steps;

    for (int i = 0; i < steps; i++) {
      await setVolume(volumeStep * (i + 1));
      await Future.delayed(stepDuration);
    }
  }

  Future<void> fadeOut({required Duration duration, required double toVolume}) async {
    final steps = 20;
    final stepDuration = duration ~/ steps;

    for (int i = steps; i > 0; i--) {
      await setVolume(toVolume / steps * i);
      await Future.delayed(stepDuration);
    }
  }
}

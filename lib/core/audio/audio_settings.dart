/// Audio settings model for persistence and state management
class AudioSettings {
  final double masterVolume;
  final double bgmVolume;
  final double sfxVolume;
  final bool isMuted;

  const AudioSettings({
    this.masterVolume = 1.0,
    this.bgmVolume = 1.0,
    this.sfxVolume = 1.0,
    this.isMuted = false,
  });

  /// Default settings
  static const AudioSettings defaults = AudioSettings();

  /// Create from JSON map
  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 1.0,
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 1.0,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'masterVolume': masterVolume,
      'bgmVolume': bgmVolume,
      'sfxVolume': sfxVolume,
      'isMuted': isMuted,
    };
  }

  /// Create a copy with updated values
  AudioSettings copyWith({
    double? masterVolume,
    double? bgmVolume,
    double? sfxVolume,
    bool? isMuted,
  }) {
    return AudioSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  /// Calculate effective BGM volume
  double get effectiveBgmVolume => isMuted ? 0.0 : masterVolume * bgmVolume;

  /// Calculate effective SFX volume
  double get effectiveSfxVolume => isMuted ? 0.0 : masterVolume * sfxVolume;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioSettings &&
        other.masterVolume == masterVolume &&
        other.bgmVolume == bgmVolume &&
        other.sfxVolume == sfxVolume &&
        other.isMuted == isMuted;
  }

  @override
  int get hashCode {
    return Object.hash(masterVolume, bgmVolume, sfxVolume, isMuted);
  }

  @override
  String toString() {
    return 'AudioSettings(master: $masterVolume, bgm: $bgmVolume, sfx: $sfxVolume, muted: $isMuted)';
  }
}

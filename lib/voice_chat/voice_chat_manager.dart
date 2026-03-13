import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 음성 채널 타입
enum VoiceChannelType {
  proximity,      // 근접 (근처 유저만)
  room,           // 방 (전체)
  party,          // 파티
  guild,          // 길드
  whisper,        // 귓속말
  broadcast,      // 방송
}

/// 음성 상태
enum VoiceState {
  disconnected,   // 연결 안됨
  connecting,     // 연결 중
  connected,      // 연결됨
  muted,          // 음소거
  deafened,       // 듣기 안함
  error,          // 에러
}

/// 오디오 코덱
enum AudioCodec {
  opus,           // Opus (권장)
  speex,          // Speex
  pcm,            // PCM
  aac,            // AAC
}

/// 음성 품질
enum VoiceQuality {
  low,            // 저음질 (~8 kbps)
  medium,         // 중음질 (~16 kbps)
  high,           // 고음질 (~32 kbps)
  ultra,          // 초고음질 (~64 kbps)
}

/// 참가자 정보
class VoiceParticipant {
  final String participantId;
  final String username;
  final String? avatar;
  final VoiceState state;
  final double volume; // 0.0-1.0
  final bool isSpeaking;
  final bool isMuted;
  final bool isDeafened;
  final DateTime joinedAt;

  const VoiceParticipant({
    required this.participantId,
    required this.username,
    this.avatar,
    required this.state,
    required this.volume,
    required this.isSpeaking,
    required this.isMuted,
    required this.isDeafened,
    required this.joinedAt,
  });
}

/// 음성 채널
class VoiceChannel {
  final String channelId;
  final String name;
  final VoiceChannelType type;
  final List<VoiceParticipant> participants;
  final int maxParticipants;
  final bool isPasswordProtected;
  final VoiceQuality quality;
  final AudioCodec codec;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const VoiceChannel({
    required this.channelId,
    required this.name,
    required this.type,
    required this.participants,
    required this.maxParticipants,
    required this.isPasswordProtected,
    required this.quality,
    required this.codec,
    required this.createdAt,
    this.metadata,
  });

  /// 참가 가능 여부
  bool get canJoin => participants.length < maxParticipants;

  /// 현재 참가자 수
  int get participantCount => participants.length;
}

/// 음성 세션
class VoiceSession {
  final String sessionId;
  final String channelId;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;
  final int bytesSent;
  final int bytesReceived;
  final double averageLatency;

  const VoiceSession({
    required this.sessionId,
    required this.channelId,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.bytesSent,
    required this.bytesReceived,
    required this.averageLatency,
  });

  /// 활성 상태
  bool get isActive => endedAt == null;
}

/// 음성 채팅 관리자
class VoiceChatManager {
  static final VoiceChatManager _instance = VoiceChatManager._();
  static VoiceChatManager get instance => _instance;

  VoiceChatManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  VoiceState _state = VoiceState.disconnected;
  VoiceChannel? _currentChannel;
  final Map<String, VoiceChannel> _channels = {};
  final Map<String, VoiceParticipant> _participants = {};
  final List<VoiceSession> _sessions = [];

  final StreamController<VoiceState> _stateController =
      StreamController<VoiceState>.broadcast();
  final StreamController<VoiceChannel> _channelController =
      StreamController<VoiceChannel>.broadcast();
  final StreamController<VoiceParticipant> _participantController =
      StreamController<VoiceParticipant>.broadcast();

  Stream<VoiceState> get onStateChange => _stateController.stream;
  Stream<VoiceChannel> get onChannelUpdate => _channelController.stream;
  Stream<VoiceParticipant> get onParticipantUpdate =>
      _participantController.stream;

  Timer? _speakingTimer;

  // 설정
  VoiceQuality _quality = VoiceQuality.medium;
  AudioCodec _codec = AudioCodec.opus;
  double _inputVolume = 1.0;
  double _outputVolume = 1.0;
  bool _pushToTalk = false;
  double _voiceActivationThreshold = 0.5;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 설정 로드
    await _loadSettings();

    // 채널 로드
    await _loadChannels();

    debugPrint('[VoiceChat] Initialized');
  }

  Future<void> _loadSettings() async {
    _quality = VoiceQuality.values.firstWhere(
      (q) => q.name == _prefs?.getString('voice_quality'),
      orElse: () => VoiceQuality.medium,
    );

    _codec = AudioCodec.values.firstWhere(
      (c) => c.name == _prefs?.getString('voice_codec'),
      orElse: () => AudioCodec.opus,
    );

    _inputVolume = _prefs?.getDouble('input_volume') ?? 1.0;
    _outputVolume = _prefs?.getDouble('output_volume') ?? 1.0;
    _pushToTalk = _prefs?.getBool('push_to_talk') ?? false;
    _voiceActivationThreshold = _prefs?.getDouble('vat') ?? 0.5;
  }

  Future<void> _loadChannels() async {
    // 기본 채널 생성
    _channels['lobby'] = VoiceChannel(
      channelId: 'lobby',
      name: '로비',
      type: VoiceChannelType.room,
      participants: [],
      maxParticipants: 50,
      isPasswordProtected: false,
      quality: VoiceQuality.medium,
      codec: AudioCodec.opus,
      createdAt: DateTime.now(),
    );

    _channels['party_001'] = VoiceChannel(
      channelId: 'party_001',
      name: '파티 채널',
      type: VoiceChannelType.party,
      participants: [],
      maxParticipants: 5,
      isPasswordProtected: false,
      quality: VoiceQuality.high,
      codec: AudioCodec.opus,
      createdAt: DateTime.now(),
    );

    _channels['guild_001'] = VoiceChannel(
      channelId: 'guild_001',
      name: '길드 채널',
      type: VoiceChannelType.guild,
      participants: [],
      maxParticipants: 100,
      isPasswordProtected: false,
      quality: VoiceQuality.medium,
      codec: AudioCodec.opus,
      createdAt: DateTime.now(),
    );
  }

  /// 채널 참가
  Future<bool> joinChannel({
    required String channelId,
    String? password,
  }) async {
    final channel = _channels[channelId];
    if (channel == null) {
      debugPrint('[VoiceChat] Channel not found: $channelId');
      return false;
    }

    if (!channel.canJoin) {
      debugPrint('[VoiceChat] Channel full: $channelId');
      return false;
    }

    // 비밀번호 체크
    if (channel.isPasswordProtected && password == null) {
      debugPrint('[VoiceChat] Password required');
      return false;
    }

    // 연결 시작
    _state = VoiceState.connecting;
    _stateController.add(_state);

    // 실제로는 WebSocket/WebRTC 연결
    await Future.delayed(const Duration(milliseconds: 500));

    // 참가자 추가
    final participant = VoiceParticipant(
      participantId: _currentUserId ?? 'unknown',
      username: 'Player',
      state: VoiceState.connected,
      volume: 1.0,
      isSpeaking: false,
      isMuted: false,
      isDeafened: false,
      joinedAt: DateTime.now(),
    );

    _participants[participant.participantId] = participant;
    _participantController.add(participant);

    // 채널 업데이트
    final updatedChannel = VoiceChannel(
      channelId: channel.channelId,
      name: channel.name,
      type: channel.type,
      participants: [...channel.participants, participant],
      maxParticipants: channel.maxParticipants,
      isPasswordProtected: channel.isPasswordProtected,
      quality: channel.quality,
      codec: channel.codec,
      createdAt: channel.createdAt,
      metadata: channel.metadata,
    );

    _channels[channelId] = updatedChannel;
    _currentChannel = updatedChannel;

    _state = VoiceState.connected;
    _stateController.add(_state);

    // 세션 시작
    _startSession(channelId);

    _channelController.add(updatedChannel);

    debugPrint('[VoiceChat] Joined channel: $channelId');

    return true;
  }

  /// 채널 나가기
  Future<bool> leaveChannel() async {
    if (_currentChannel == null) return false;

    // 참가자 제거
    _participants.remove(_currentUserId);

    // 세션 종료
    await _endSession();

    _state = VoiceState.disconnected;
    _stateController.add(_state);

    final channelId = _currentChannel!.channelId;
    _currentChannel = null;

    debugPrint('[VoiceChat] Left channel: $channelId');

    return true;
  }

  /// 음소거 토글
  Future<void> toggleMute() async {
    if (_state == VoiceState.disconnected) return;

    final newState = _state == VoiceState.connected
        ? VoiceState.muted
        : VoiceState.connected;

    _state = newState;
    _stateController.add(_state);

    debugPrint('[VoiceChat] Muted: ${newState == VoiceState.muted}');
  }

  /// 듣기 안함 토글
  Future<void> toggleDeafen() async {
    if (_state == VoiceState.disconnected) return;

    final newState = _state == VoiceState.connected
        ? VoiceState.deafened
        : VoiceState.connected;

    _state = newState;
    _stateController.add(_state);

    debugPrint('[VoiceChat] Deafened: ${newState == VoiceState.deafened}');
  }

  /// 음소거 상태
  bool get isMuted => _state == VoiceState.muted;

  /// 듣기 안함 상태
  bool get isDeafened => _state == VoiceState.deafened;

  /// 현재 상태
  VoiceState get currentState => _state;

  /// 현재 채널
  VoiceChannel? get currentChannel => _currentChannel;

  /// 음성 품질 설정
  Future<void> setQuality(VoiceQuality quality) async {
    _quality = quality;

    await _prefs?.setString('voice_quality', quality.name);

    debugPrint('[VoiceChat] Quality: ${quality.name}');
  }

  /// 코덱 설정
  Future<void> setCodec(AudioCodec codec) async {
    _codec = codec;

    await _prefs?.setString('voice_codec', codec.name);

    debugPrint('[VoiceChat] Codec: ${codec.name}');
  }

  /// 입력 볼륨 설정
  Future<void> setInputVolume(double volume) async {
    _inputVolume = volume.clamp(0.0, 2.0);

    await _prefs?.setDouble('input_volume', _inputVolume);
  }

  /// 출력 볼륨 설정
  Future<void> setOutputVolume(double volume) async {
    _outputVolume = volume.clamp(0.0, 2.0);

    await _prefs?.setDouble('output_volume', _outputVolume);
  }

  /// 입력 볼륨
  double get inputVolume => _inputVolume;

  /// 출력 볼륨
  double get outputVolume => _outputVolume;

  /// PTT 설정
  Future<void> setPushToTalk(bool enabled) async {
    _pushToTalk = enabled;

    await _prefs?.setBool('push_to_talk', enabled);

    debugPrint('[VoiceChat] PTT: $enabled');
  }

  /// PTT 여부
  bool get pushToTalk => _pushToTalk;

  /// 음성 활성화 임계값
  Future<void> setVoiceActivationThreshold(double threshold) async {
    _voiceActivationThreshold = threshold.clamp(0.0, 1.0);

    await _prefs?.setDouble('vat', _voiceActivationThreshold);
  }

  /// 음성 활성화 시작
  void startSpeaking() {
    if (_currentUserId == null) return;

    final participant = _participants[_currentUserId];
    if (participant == null) return;

    final updated = VoiceParticipant(
      participantId: participant.participantId,
      username: participant.username,
      avatar: participant.avatar,
      state: participant.state,
      volume: participant.volume,
      isSpeaking: true,
      isMuted: participant.isMuted,
      isDeafened: participant.isDeafened,
      joinedAt: participant.joinedAt,
    );

    _participants[_currentUserId!] = updated;
    _participantController.add(updated);

    // speaking timer 시작
    _speakingTimer?.cancel();
    _speakingTimer = Timer(const Duration(milliseconds: 200), () {
      stopSpeaking();
    });
  }

  /// 음성 활성화 중지
  void stopSpeaking() {
    if (_currentUserId == null) return;

    final participant = _participants[_currentUserId];
    if (participant == null) return;

    final updated = VoiceParticipant(
      participantId: participant.participantId,
      username: participant.username,
      avatar: participant.avatar,
      state: participant.state,
      volume: participant.volume,
      isSpeaking: false,
      isMuted: participant.isMuted,
      isDeafened: participant.isDeafened,
      joinedAt: participant.joinedAt,
    );

    _participants[_currentUserId!] = updated;
    _participantController.add(updated);
  }

  /// 참가자 볼륨 설정
  Future<void> setParticipantVolume({
    required String participantId,
    required double volume,
  }) async {
    final participant = _participants[participantId];
    if (participant == null) return;

    final updated = VoiceParticipant(
      participantId: participant.participantId,
      username: participant.username,
      avatar: participant.avatar,
      state: participant.state,
      volume: volume.clamp(0.0, 1.0),
      isSpeaking: participant.isSpeaking,
      isMuted: participant.isMuted,
      isDeafened: participant.isDeafened,
      joinedAt: participant.joinedAt,
    );

    _participants[participantId] = updated;
    _participantController.add(updated);
  }

  /// 채널 생성
  Future<String> createChannel({
    required String name,
    required VoiceChannelType type,
    int maxParticipants = 10,
    bool isPasswordProtected = false,
    VoiceQuality quality = VoiceQuality.medium,
    AudioCodec codec = AudioCodec.opus,
  }) async {
    final channelId = 'channel_${DateTime.now().millisecondsSinceEpoch}';

    final channel = VoiceChannel(
      channelId: channelId,
      name: name,
      type: type,
      participants: [],
      maxParticipants: maxParticipants,
      isPasswordProtected: isPasswordProtected,
      quality: quality,
      codec: codec,
      createdAt: DateTime.now(),
    );

    _channels[channelId] = channel;

    debugPrint('[VoiceChat] Channel created: $channelId');

    return channelId;
  }

  /// 채널 삭제
  Future<bool> deleteChannel(String channelId) async {
    if (!_channels.containsKey(channelId)) return false;

    _channels.remove(channelId);

    debugPrint('[VoiceChat] Channel deleted: $channelId');

    return true;
  }

  /// 채널 목록
  List<VoiceChannel> getChannels({VoiceChannelType? type}) {
    final channels = _channels.values.toList();

    if (type != null) {
      return channels.where((c) => c.type == type).toList();
    }

    return channels;
  }

  /// 현재 참가자 목록
  List<VoiceParticipant> getParticipants() {
    if (_currentChannel == null) return [];

    return _currentChannel!.participants;
  }

  void _startSession(String channelId) {
    final session = VoiceSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      userId: _currentUserId ?? 'unknown',
      startedAt: DateTime.now(),
      endedAt: null,
      duration: Duration.zero,
      bytesSent: 0,
      bytesReceived: 0,
      averageLatency: 0,
    );

    _sessions.add(session);
  }

  Future<void> _endSession() async {
    if (_sessions.isEmpty) return;

    final lastSession = _sessions.last;
    final index = _sessions.length - 1;

    final updated = VoiceSession(
      sessionId: lastSession.sessionId,
      channelId: lastSession.channelId,
      userId: lastSession.userId,
      startedAt: lastSession.startedAt,
      endedAt: DateTime.now(),
      duration: DateTime.now().difference(lastSession.startedAt),
      bytesSent: lastSession.bytesSent,
      bytesReceived: lastSession.bytesReceived,
      averageLatency: lastSession.averageLatency,
    );

    _sessions[index] = updated;
  }

  /// 세션 목록
  List<VoiceSession> getSessions() {
    return _sessions.toList();
  }

  void dispose() {
    _stateController.close();
    _channelController.close();
    _participantController.close();
    _speakingTimer?.cancel();
  }
}

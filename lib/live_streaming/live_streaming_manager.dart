import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스트리밍 플랫폼
enum StreamingPlatform {
  twitch,         // 트위치
  youtube,        // 유튜브
  facebook,       // 페이스북
  tiktok,         // 틱톡
  custom,         // 커스텀 (RTMP)
}

/// 스트림 상태
enum StreamStatus {
  offline,        // 오프라인
  preparing,      // 준비 중
  live,           // 라이브
  paused,         // 일시정지
  ended,          // 종료됨
  error,          // 에러
}

/// 스트림 품질
enum StreamQuality {
  source,         // 원본
  _1080p,         // 1080p
  _720p,          // 720p
  _480p,          // 480p
  _360p,          // 360p
  _160p,          // 160p
  audio_only,     // 음성만
}

/// 스트림 설정
class StreamSettings {
  final StreamingPlatform platform;
  final String streamKey;
  final String serverUrl; // RTMP URL
  final StreamQuality quality;
  final int bitrate; // kbps
  final int fps;
  final bool includeAudio;
  final int audioBitrate;
  final bool includeMic;
  final bool includeCamera;
  final bool includeSystemAudio;
  final Map<String, dynamic>? customSettings;

  const StreamSettings({
    required this.platform,
    required this.streamKey,
    required this.serverUrl,
    required this.quality,
    required this.bitrate,
    required this.fps,
    required this.includeAudio,
    required this.audioBitrate,
    required this.includeMic,
    required this.includeCamera,
    required this.includeSystemAudio,
    this.customSettings,
  });
}

/// 스트림 정보
class StreamInfo {
  final String streamId;
  final String streamerId;
  final String title;
  final String? description;
  final StreamStatus status;
  final StreamingPlatform platform;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;
  final int currentViewers;
  final int totalViews;
  final List<String> tags;
  final String? thumbnailUrl;
  final String? streamUrl;
  final Map<String, dynamic>? metadata;

  const StreamInfo({
    required this.streamId,
    required this.streamerId,
    required this.title,
    this.description,
    required this.status,
    required this.platform,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.currentViewers,
    required this.totalViews,
    required this.tags,
    this.thumbnailUrl,
    this.streamUrl,
    this.metadata,
  });

  /// 현재 라이브 여부
  bool get isLive => status == StreamStatus.live;

  /// URL 생성
  String? getUrl() {
    if (streamUrl != null) return streamUrl;

    switch (platform) {
      case StreamingPlatform.twitch:
        return 'https://twitch.tv/$streamerId';
      case StreamingPlatform.youtube:
        return 'https://youtube.com/watch?v=$streamId';
      case StreamingPlatform.facebook:
        return 'https://facebook.com/watch/$streamId';
      default:
        return null;
    }
  }
}

/// 채팅 메시지
class StreamChatMessage {
  final String messageId;
  final String userId;
  final String username;
  final String? avatar;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? badges;
  final bool isSubscriber;
  final bool isModerator;
  final String? customColor;

  const StreamChatMessage({
    required this.messageId,
    required this.userId,
    required this.username,
    this.avatar,
    required this.message,
    required this.timestamp,
    this.badges,
    this.isSubscriber = false,
    this.isModerator = false,
    this.customColor,
  });
}

/// 스트림 통계
class StreamStatistics {
  final String streamId;
  final DateTime timestamp;
  final int currentViewers;
  final int newFollowers;
  final int newSubscribers;
  final double totalRevenue; // donations + subs
  final List<String> activeChatters;
  final int chatMessagesCount;

  const StreamStatistics({
    required this.streamId,
    required this.timestamp,
    required this.currentViewers,
    required this.newFollowers,
    required this.newSubscribers,
    required this.totalRevenue,
    required this.activeChatters,
    required this.chatMessagesCount,
  });
}

/// 기부/후원
class Donation {
  final String donationId;
  final String donorId;
  final String donorName;
  final double amount;
  final String currency;
  final String? message;
  final DateTime timestamp;

  const Donation({
    required this.donationId,
    required this.donorId,
    required this.donorName,
    required this.amount,
    required this.currency,
    this.message,
    required this.timestamp,
  });
}

/// 스트림러 설정
class StreamerProfile {
  final String streamerId;
  final String displayName;
  final String? description;
  final List<StreamingPlatform> connectedPlatforms;
  final Map<StreamingPlatform, String> platformUsernames;
  final List<String> moderators;
  final List<String> bannedUsers;
  final String? overlayTheme;
  final Map<String, dynamic>? customCommands;

  const StreamerProfile({
    required this.streamerId,
    required this.displayName,
    this.description,
    required this.connectedPlatforms,
    required this.platformUsernames,
    required this.modererators,
    required this.bannedUsers,
    this.overlayTheme,
    this.customCommands,
  });
}

/// 라이브 스트리밍 관리자
class LiveStreamingManager {
  static final LiveStreamingManager _instance =
      LiveStreamingManager._();
  static LiveStreamingManager get instance => _instance;

  LiveStreamingManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  StreamInfo? _currentStream;
  StreamSettings? _streamSettings;
  StreamerProfile? _streamerProfile;

  final List<StreamChatMessage> _chatMessages = [];
  final List<Donation> _donations = [];
  final List<StreamStatistics> _statistics = [];

  final StreamController<StreamInfo> _streamController =
      StreamController<StreamInfo>.broadcast();
  final StreamController<StreamChatMessage> _chatController =
      StreamController<StreamChatMessage>.broadcast();
  final StreamController<Donation> _donationController =
      StreamController<Donation>.broadcast();
  final StreamController<StreamStatistics> _statsController =
      StreamController<StreamStatistics>.broadcast();

  Stream<StreamInfo> get onStreamUpdate => _streamController.stream;
  Stream<StreamChatMessage> get onChatMessage => _chatController.stream;
  Stream<Donation> get onDonation => _donationController.stream;
  Stream<StreamStatistics> get onStatsUpdate => _statsController.stream;

  Timer? _statsTimer;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 프로필 로드
    await _loadStreamerProfile();

    // 설정 로드
    await _loadStreamSettings();

    debugPrint('[LiveStreaming] Initialized');
  }

  Future<void> _loadStreamerProfile() async {
    final json = _prefs?.getString('streamer_profile');

    if (json != null) {
      try {
        final data = jsonDecode(json) as Map<String, dynamic>;
        // 파싱
      } catch (e) {
        debugPrint('[LiveStreaming] Error loading profile: $e');
      }
    }

    // 기본 프로필
    _streamerProfile = StreamerProfile(
      streamerId: _currentUserId ?? 'unknown',
      displayName: 'Streamer',
      connectedPlatforms: [],
      platformUsernames: {},
      moderators: [],
      bannedUsers: [],
    );
  }

  Future<void> _loadStreamSettings() async {
    // 기본 설정
    _streamSettings = const StreamSettings(
      platform: StreamingPlatform.twitch,
      streamKey: '',
      serverUrl: 'rtmp://live.twitch.tv/app',
      quality: StreamQuality._720p,
      bitrate: 4500,
      fps: 60,
      includeAudio: true,
      audioBitrate: 160,
      includeMic: true,
      includeCamera: false,
      includeSystemAudio: true,
    );
  }

  /// 스트리밍 시작
  Future<bool> startStreaming({
    required String title,
    String? description,
    required StreamSettings settings,
    List<String> tags = const [],
  }) async {
    if (_currentStream != null && _currentStream!.isLive) {
      debugPrint('[LiveStreaming] Already streaming');
      return false;
    }

    _streamSettings = settings;

    // 스트림 정보 생성
    final stream = StreamInfo(
      streamId: 'stream_${DateTime.now().millisecondsSinceEpoch}',
      streamerId: _currentUserId ?? 'unknown',
      title: title,
      description: description,
      status: StreamStatus.preparing,
      platform: settings.platform,
      startedAt: DateTime.now(),
      duration: Duration.zero,
      currentViewers: 0,
      totalViews: 0,
      tags: tags,
    );

    _currentStream = stream;
    _streamController.add(stream);

    // 실제 스트리밍 시작 연결
    await Future.delayed(const Duration(seconds: 2));

    // 라이브 상태로 변경
    final liveStream = StreamInfo(
      streamId: stream.streamId,
      streamerId: stream.streamerId,
      title: stream.title,
      description: stream.description,
      status: StreamStatus.live,
      platform: stream.platform,
      startedAt: stream.startedAt,
      duration: DateTime.now().difference(stream.startedAt),
      currentViewers: 0,
      totalViews: 0,
      tags: stream.tags,
      streamUrl: stream.getUrl(),
    );

    _currentStream = liveStream;
    _streamController.add(liveStream);

    // 통계 업데이트 시작
    _startStatsUpdate();

    // 채팅 연결
    _connectChat();

    debugPrint('[LiveStreaming] Started: ${stream.streamId}');

    return true;
  }

  /// 스트리밍 중지
  Future<bool> stopStreaming() async {
    if (_currentStream == null || !_currentStream!.isLive) {
      return false;
    }

    // 종료 상태로 변경
    final endedStream = StreamInfo(
      streamId: _currentStream!.streamId,
      streamerId: _currentStream!.streamerId,
      title: _currentStream!.title,
      description: _currentStream!.description,
      status: StreamStatus.ended,
      platform: _currentStream!.platform,
      startedAt: _currentStream!.startedAt,
      endedAt: DateTime.now(),
      duration: DateTime.now().difference(_currentStream!.startedAt),
      currentViewers: _currentStream!.currentViewers,
      totalViews: _currentStream!.totalViews,
      tags: _currentStream!.tags,
      streamUrl: _currentStream!.streamUrl,
    );

    _currentStream = endedStream;
    _streamController.add(endedStream);

    // 통계 업데이트 중지
    _statsTimer?.cancel();

    debugPrint('[LiveStreaming] Stopped: ${endedStream.streamId}');

    return true;
  }

  /// 스트림 일시정지
  Future<bool> pauseStreaming() async {
    if (_currentStream == null || !_currentStream!.isLive) {
      return false;
    }

    final pausedStream = StreamInfo(
      streamId: _currentStream!.streamId,
      streamerId: _currentStream!.streamerId,
      title: _currentStream!.title,
      description: _currentStream!.description,
      status: StreamStatus.paused,
      platform: _currentStream!.platform,
      startedAt: _currentStream!.startedAt,
      endedAt: _currentStream!.endedAt,
      duration: DateTime.now().difference(_currentStream!.startedAt),
      currentViewers: _currentStream!.currentViewers,
      totalViews: _currentStream!.totalViews,
      tags: _currentStream!.tags,
      streamUrl: _currentStream!.streamUrl,
    );

    _currentStream = pausedStream;
    _streamController.add(pausedStream);

    return true;
  }

  /// 스트림 재개
  Future<bool> resumeStreaming() async {
    if (_currentStream == null || _currentStream!.status != StreamStatus.paused) {
      return false;
    }

    final liveStream = StreamInfo(
      streamId: _currentStream!.streamId,
      streamerId: _currentStream!.streamerId,
      title: _currentStream!.title,
      description: _currentStream!.description,
      status: StreamStatus.live,
      platform: _currentStream!.platform,
      startedAt: _currentStream!.startedAt,
      endedAt: _currentStream!.endedAt,
      duration: DateTime.now().difference(_currentStream!.startedAt),
      currentViewers: _currentStream!.currentViewers,
      totalViews: _currentStream!.totalViews,
      tags: _currentStream!.tags,
      streamUrl: _currentStream!.streamUrl,
    );

    _currentStream = liveStream;
    _streamController.add(liveStream);

    return true;
  }

  /// 현재 스트림
  StreamInfo? get currentStream => _currentStream;

  /// 스트림 설정
  StreamSettings? get streamSettings => _streamSettings;

  void _startStatsUpdate() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateStats();
    });
  }

  void _updateStats() {
    if (_currentStream == null || !_currentStream!.isLive) return;

    final stats = StreamStatistics(
      streamId: _currentStream!.streamId,
      timestamp: DateTime.now(),
      currentViewers: _currentStream!.currentViewers + Random().nextInt(10) - 5,
      newFollowers: Random().nextInt(3),
      newSubscribers: Random().nextInt(2),
      totalRevenue: Random().nextDouble() * 100,
      activeChatters: [],
      chatMessagesCount: _chatMessages.length,
    );

    _statistics.add(stats);
    _statsController.add(stats);

    // 스트림 정보 업데이트
    final updatedStream = StreamInfo(
      streamId: _currentStream!.streamId,
      streamerId: _currentStream!.streamerId,
      title: _currentStream!.title,
      description: _currentStream!.description,
      status: _currentStream!.status,
      platform: _currentStream!.platform,
      startedAt: _currentStream!.startedAt,
      endedAt: _currentStream!.endedAt,
      duration: DateTime.now().difference(_currentStream!.startedAt),
      currentViewers: stats.currentViewers,
      totalViews: _currentStream!.totalViews,
      tags: _currentStream!.tags,
      streamUrl: _currentStream!.streamUrl,
    );

    _currentStream = updatedStream;
    _streamController.add(updatedStream);
  }

  void _connectChat() {
    // 채팅 연결 (시뮬레이션)
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentStream == null || !_currentStream!.isLive) {
        timer.cancel();
        return;
      }

      // 랜덤 채팅 메시지 생성
      final message = StreamChatMessage(
        messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${Random().nextInt(100)}',
        username: 'User${Random().nextInt(100)}',
        message: _getRandomMessage(),
        timestamp: DateTime.now(),
        isSubscriber: Random().nextBool(),
        isModerator: false,
      );

      _chatMessages.add(message);
      _chatController.add(message);
    });
  }

  String _getRandomMessage() {
    final messages = [
      '안녕하세요!',
      '잘 보고 있어요',
      '대박',
      'ㅋㅋㅋㅋ',
      '좋아요',
      '완전 재밌다',
      '화이팅!',
      'gg',
      '프로이다',
      '어떻게 그렇게 함?',
    ];

    return messages[Random().nextInt(messages.length)];
  }

  /// 채팅 메시지 전송
  Future<void> sendChatMessage(String message) async {
    if (_currentStream == null || !_currentStream!.isLive) return;

    final chatMessage = StreamChatMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId ?? 'unknown',
      username: 'Streamer',
      message: message,
      timestamp: DateTime.now(),
      isModerator: true,
    );

    _chatMessages.add(chatMessage);
    _chatController.add(chatMessage);
  }

  /// 기부 받기
  void receiveDonation({
    required String donorId,
    required String donorName,
    required double amount,
    required String currency,
    String? message,
  }) {
    final donation = Donation(
      donationId: 'donation_${DateTime.now().millisecondsSinceEpoch}',
      donorId: donorId,
      donorName: donorName,
      amount: amount,
      currency: currency,
      message: message,
      timestamp: DateTime.now(),
    );

    _donations.add(donation);
    _donationController.add(donation);

    debugPrint('[LiveStreaming] Donation: $amount$currency from $donorName');
  }

  /// 플랫폼 연결
  Future<bool> connectPlatform({
    required StreamingPlatform platform,
    required String accessToken,
    String? username,
  }) async {
    if (_streamerProfile == null) return false;

    final connected = [..._streamerProfile!.connectedPlatforms];
    if (!connected.contains(platform)) {
      connected.add(platform);
    }

    final usernames = Map<StreamingPlatform, String>.from(
      _streamerProfile!.platformUsernames,
    );

    if (username != null) {
      usernames[platform] = username;
    }

    _streamerProfile = StreamerProfile(
      streamerId: _streamerProfile!.streamerId,
      displayName: _streamerProfile!.displayName,
      description: _streamerProfile!.description,
      connectedPlatforms: connected,
      platformUsernames: usernames,
      moderators: _streamerProfile!.moderators,
      bannedUsers: _streamerProfile!.bannedUsers,
      overlayTheme: _streamerProfile!.overlayTheme,
      customCommands: _streamerProfile!.customCommands,
    );

    await _saveStreamerProfile();

    debugPrint('[LiveStreaming] Connected: ${platform.name}');

    return true;
  }

  /// 스트리머 프로필
  StreamerProfile? get streamerProfile => _streamerProfile;

  /// 통계 조회
  List<StreamStatistics> getStatistics() {
    return _statistics.toList();
  }

  /// 채팅 메시지 조회
  List<StreamChatMessage> getChatMessages({int limit = 100}) {
    return _chatMessages.take(limit).toList();
  }

  /// 기부 내역 조회
  List<Donation> getDonations() {
    return _donations.toList();
  }

  Future<void> _saveStreamerProfile() async {
    if (_streamerProfile == null) return;

    final data = {
      'streamerId': _streamerProfile!.streamerId,
      'displayName': _streamerProfile!.displayName,
      'connectedPlatforms': _streamerProfile!.connectedPlatforms
          .map((p) => p.name)
          .toList(),
    };

    await _prefs?.setString('streamer_profile', jsonEncode(data));
  }

  void dispose() {
    _streamController.close();
    _chatController.close();
    _donationController.close();
    _statsController.close();
    _statsTimer?.cancel();
  }
}

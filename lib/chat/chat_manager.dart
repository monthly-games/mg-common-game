import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 채팅 채널 타입
enum ChatChannelType {
  world,          // 월드 (전체)
  guild,          // 길드
  party,          // 파티
  whisper,        // 귓속말
  system,         // 시스템
  announcement,   // 공지
  trade,          // 거래
  help,           // 도움말
}

/// 메시지 타입
enum ChatMessageType {
  text,           // 텍스트
  emoji,          // 이모지
  sticker,        // 스티커
  image,          // 이미지
  item,           // 아이템 공유
  system,         // 시스템 메시지
  command,        // 명령어
}

/// 메시지
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final ChatChannelType channelType;
  final String? channelId; // 길드ID, 파티ID 등
  final ChatMessageType type;
  final String content;
  final List<String>? mentions; // 멘션된 유저
  final DateTime timestamp;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final String? replyToId; // 답글 대상
  final List<ChatReaction>? reactions;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.channelType,
    this.channelId,
    required this.type,
    required this.content,
    this.mentions,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.replyToId,
    this.reactions,
    this.metadata,
  });

  /// 멘션 포함 여부
  bool hasMention(String userId) {
    return mentions?.contains(userId) ?? false;
  }

  /// 표시 텍스트
  String get displayText {
    if (isDeleted) return '[삭제된 메시지]';
    return content;
  }

  /// 시간 형식
  String get timeDisplay {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// 리액션
class ChatReaction {
  final String emoji;
  final List<String> userIds;
  final int count;

  const ChatReaction({
    required this.emoji,
    required this.userIds,
    required this.count,
  });
}

/// 채팅 채널
class ChatChannel {
  final String id;
  final ChatChannelType type;
  final String name;
  final String? description;
  final List<ChatMessage> messages;
  final int memberCount;
  final bool isReadOnly;
  final bool isMuted;
  final DateTime? lastActivity;

  const ChatChannel({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.messages,
    required this.memberCount,
    this.isReadOnly = false,
    this.isMuted = false,
    this.lastActivity,
  });

  /// 마지막 메시지
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// 안읽은 메시지 수
  int get unreadCount {
    // 실제로는 유저별 안읽음 카운트
    return 0;
  }
}

/// 채팅 필터
class ChatFilter {
  final bool blockProfanity;
  final bool blockSpam;
  final int minLevel;
  final List<String> blockedWords;
  final List<String> blockedUsers;

  const ChatFilter({
    this.blockProfanity = true,
    this.blockSpam = true,
    this.minLevel = 0,
    this.blockedWords = const [],
    this.blockedUsers = const [],
  });

  /// 필터링
  String filter(String text) {
    var filtered = text;

    if (blockProfanity) {
      filtered = _filterProfanity(filtered);
    }

    if (blockedWords.isNotEmpty) {
      for (final word in blockedWords) {
        filtered = filtered.replaceAll(word, '***');
      }
    }

    return filtered;
  }

  String _filterProfanity(String text) {
    // 욕설 필터링
    return text;
  }

  /// 전송 가능 여부
  bool canSend({
    required int userLevel,
    required String userId,
  }) {
    if (userLevel < minLevel) return false;
    if (blockedUsers.contains(userId)) return false;
    return true;
  }
}

/// 채팅 설정
class ChatSettings {
  final bool showTimestamp;
  final bool showAvatars;
  final int fontSize;
  final bool enableSound;
  final bool enableNotifications;
  final Map<ChatChannelType, bool> mutedChannels;

  const ChatSettings({
    this.showTimestamp = true,
    this.showAvatars = true,
    this.fontSize = 14,
    this.enableSound = true,
    this.enableNotifications = true,
    this.mutedChannels = const {},
  });

  /// 채널 음소거 여부
  bool isChannelMuted(ChatChannelType type) {
    return mutedChannels[type] ?? false;
  }
}

/// 채팅 관리자
class ChatManager {
  static final ChatManager _instance = ChatManager._();
  static ChatManager get instance => _instance;

  ChatManager._();

  SharedPreferences? _prefs;
  String? _currentUserId;

  final Map<String, ChatChannel> _channels = {};
  ChatFilter? _filter;
  ChatSettings? _settings;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatChannel> _channelController =
      StreamController<ChatChannel>.broadcast();

  Stream<ChatMessage> get onMessage => _messageController.stream;
  Stream<ChatChannel> get onChannelUpdate => _channelController.stream;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentUserId = _prefs?.getString('user_id');

    // 채널 로드
    _loadChannels();

    // 필터 로드
    await _loadFilter();

    // 설정 로드
    await _loadSettings();

    debugPrint('[Chat] Initialized');
  }

  void _loadChannels() {
    // 월드 채널
    _channels['world'] = ChatChannel(
      id: 'world',
      type: ChatChannelType.world,
      name: '월드',
      description: '전체 유저와 대화',
      messages: _generateSampleMessages(),
      memberCount: 15234,
      isReadOnly: false,
      lastActivity: DateTime.now(),
    );

    // 시스템 채널
    _channels['system'] = ChatChannel(
      id: 'system',
      type: ChatChannelType.system,
      name: '시스템',
      description: '시스템 공지사항',
      messages: [
        ChatMessage(
          id: 'sys_1',
          senderId: 'system',
          senderName: '시스템',
          channelType: ChatChannelType.system,
          type: ChatMessageType.system,
          content: '환영합니다! 게임을 즐겨주세요.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
      memberCount: 0,
      isReadOnly: true,
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
    );

    // 거래 채널
    _channels['trade'] = ChatChannel(
      id: 'trade',
      type: ChatChannelType.trade,
      name: '거래',
      description: '아이템 거래',
      messages: [],
      memberCount: 8923,
      isReadOnly: false,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  List<ChatMessage> _generateSampleMessages() {
    return [
      ChatMessage(
        id: 'msg_1',
        senderId: 'user_123',
        senderName: 'DragonSlayer',
        channelType: ChatChannelType.world,
        type: ChatMessageType.text,
        content: '안녕하세요! 새로운 업데이트 정말 좋네요',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'msg_2',
        senderId: 'user_456',
        senderName: 'StarPlayer',
        channelType: ChatChannelType.world,
        type: ChatMessageType.text,
        content: '누구 던전 같이 하실래요?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 'msg_3',
        senderId: 'user_789',
        senderName: 'NightHawk',
        channelType: ChatChannelType.world,
        type: ChatMessageType.text,
        content: '저요! 같이 가요',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
  }

  Future<void> _loadFilter() async {
    // 기본 필터
    _filter = const ChatFilter(
      blockProfanity: true,
      blockSpam: true,
      minLevel: 5,
    );
  }

  Future<void> _loadSettings() async {
    // 기본 설정
    _settings = const ChatSettings();
  }

  /// 메시지 전송
  Future<ChatMessage?> sendMessage({
    required String channelId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    String? replyToId,
  }) async {
    if (_currentUserId == null) return null;

    final channel = _channels[channelId];
    if (channel == null) return null;
    if (channel.isReadOnly) return null;

    // 필터링 체크
    if (_filter != null) {
      final canSend = _filter!.canSend(
        userLevel: 10, // 실제로는 유저 레벨
        userId: _currentUserId!,
      );
      if (!canSend) {
        debugPrint('[Chat] Cannot send message');
        return null;
      }
    }

    // 내용 필터링
    final filteredContent = _filter?.filter(content) ?? content;

    // 메시지 생성
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId!,
      senderName: '나', // 실제로는 유저 이름
      channelType: channel.type,
      channelId: channelId,
      type: type,
      content: filteredContent,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );

    // 채널에 추가
    final updatedMessages = [...channel.messages, message];
    final updated = ChatChannel(
      id: channel.id,
      type: channel.type,
      name: channel.name,
      description: channel.description,
      messages: updatedMessages,
      memberCount: channel.memberCount,
      isReadOnly: channel.isReadOnly,
      isMuted: channel.isMuted,
      lastActivity: DateTime.now(),
    );

    _channels[channelId] = updated;
    _messageController.add(message);
    _channelController.add(updated);

    debugPrint('[Chat] Message sent: $channelId');

    return message;
  }

  /// 귓속말 전송
  Future<ChatMessage?> sendWhisper({
    required String targetUserId,
    required String content,
  }) async {
    if (_currentUserId == null) return null;

    // 귓속말 채널 생성 (없으면)
    final channelId = 'whisper_${_currentUserId!}_$targetUserId';
    if (!_channels.containsKey(channelId)) {
      _channels[channelId] = ChatChannel(
        id: channelId,
        type: ChatChannelType.whisper,
        name: '귓속말',
        messages: [],
        memberCount: 2,
        isReadOnly: false,
      );
    }

    return sendMessage(
      channelId: channelId,
      content: content,
    );
  }

  /// 메시지 삭제
  Future<bool> deleteMessage({
    required String channelId,
    required String messageId,
  }) async {
    if (_currentUserId == null) return false;

    final channel = _channels[channelId];
    if (channel == null) return false;

    final messageIndex = channel.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;

    // 본인 메시지만 삭제 가능
    final message = channel.messages[messageIndex];
    if (message.senderId != _currentUserId) return false;

    final deleted = ChatMessage(
      id: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      channelType: message.channelType,
      channelId: message.channelId,
      type: message.type,
      content: '',
      timestamp: message.timestamp,
      isDeleted: true,
    );

    final updatedMessages = List<ChatMessage>.from(channel.messages);
    updatedMessages[messageIndex] = deleted;

    final updated = ChatChannel(
      id: channel.id,
      type: channel.type,
      name: channel.name,
      description: channel.description,
      messages: updatedMessages,
      memberCount: channel.memberCount,
      isReadOnly: channel.isReadOnly,
      isMuted: channel.isMuted,
      lastActivity: DateTime.now(),
    );

    _channels[channelId] = updated;
    _channelController.add(updated);

    debugPrint('[Chat] Message deleted: $messageId');

    return true;
  }

  /// 리액션 추가
  Future<bool> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    if (_currentUserId == null) return false;

    final channel = _channels[channelId];
    if (channel == null) return false;

    final messageIndex = channel.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return false;

    final message = channel.messages[messageIndex];

    // 기존 리액션 확인
    var reactions = message.reactions ?? [];
    final reactionIndex = reactions.indexWhere((r) => r.emoji == emoji);

    if (reactionIndex == -1) {
      // 새 리액션
      reactions = [
        ...reactions,
        ChatReaction(
          emoji: emoji,
          userIds: [_currentUserId!],
          count: 1,
        ),
      ];
    } else {
      // 기존 리액션에 추가
      final existing = reactions[reactionIndex];
      if (!existing.userIds.contains(_currentUserId)) {
        final updatedUserIds = [...existing.userIds, _currentUserId!];
        reactions = List<ChatReaction>.from(reactions);
        reactions[reactionIndex] = ChatReaction(
          emoji: emoji,
          userIds: updatedUserIds,
          count: updatedUserIds.length,
        );
      }
    }

    final updated = ChatMessage(
      id: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      channelType: message.channelType,
      channelId: message.channelId,
      type: message.type,
      content: message.content,
      mentions: message.mentions,
      timestamp: message.timestamp,
      isEdited: message.isEdited,
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
      replyToId: message.replyToId,
      reactions: reactions,
      metadata: message.metadata,
    );

    final updatedMessages = List<ChatMessage>.from(channel.messages);
    updatedMessages[messageIndex] = updated;

    final updatedChannel = ChatChannel(
      id: channel.id,
      type: channel.type,
      name: channel.name,
      description: channel.description,
      messages: updatedMessages,
      memberCount: channel.memberCount,
      isReadOnly: channel.isReadOnly,
      isMuted: channel.isMuted,
      lastActivity: DateTime.now(),
    );

    _channels[channelId] = updatedChannel;
    _channelController.add(updatedChannel);

    return true;
  }

  /// 채널 조회
  ChatChannel? getChannel(String channelId) {
    return _channels[channelId];
  }

  /// 채널 목록
  List<ChatChannel> getChannels() {
    return _channels.values.toList()
      ..sort((a, b) {
        final aTime = a.lastActivity ?? DateTime(0);
        final bTime = b.lastActivity ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
  }

  /// 메시지 검색
  List<ChatMessage> searchMessages({
    String? channelId,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var messages = <ChatMessage>[];

    if (channelId != null) {
      final channel = _channels[channelId];
      if (channel != null) {
        messages = channel.messages;
      }
    } else {
      // 전체 채널
      for (final channel in _channels.values) {
        messages.addAll(channel.messages);
      }
    }

    // 필터링
    if (keyword != null && keyword.isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      messages = messages.where((m) =>
          m.content.toLowerCase().contains(lowerKeyword) ||
          m.senderName.toLowerCase().contains(lowerKeyword)
      ).toList();
    }

    if (startDate != null) {
      messages = messages.where((m) => m.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      messages = messages.where((m) => m.timestamp.isBefore(endDate)).toList();
    }

    return messages..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 최근 대화
  List<Map<String, String>> getRecentConversations() {
    final conversations = <Map<String, String>>[];

    for (final channel in _channels.values) {
      if (channel.type == ChatChannelType.whisper) {
        final lastMsg = channel.lastMessage;
        if (lastMsg != null) {
          conversations.add({
            'userId': lastMsg.senderId,
            'userName': lastMsg.senderName,
            'lastMessage': lastMsg.content,
            'timestamp': lastMsg.timeDisplay,
          });
        }
      }
    }

    return conversations;
  }

  /// 필터 설정
  void setFilter(ChatFilter filter) {
    _filter = filter;
    _saveFilter();
  }

  /// 설정 업데이트
  void updateSettings(ChatSettings settings) {
    _settings = settings;
    _saveSettings();
  }

  Future<void> _saveFilter() async {
    // 필터 저장
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final data = {
      'showTimestamp': _settings!.showTimestamp,
      'showAvatars': _settings!.showAvatars,
      'fontSize': _settings!.fontSize,
    };

    await _prefs?.setString(
      'chat_settings',
      jsonEncode(data),
    );
  }

  void dispose() {
    _messageController.close();
    _channelController.close();
  }
}

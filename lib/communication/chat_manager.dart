import 'dart:async';
import 'package:flutter/material.dart';

enum MessageType {
  text,
  emoji,
  image,
  audio,
  system,
}

enum ChatChannelType {
  global,
  guild,
  party,
  private,
  announcement,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String messageId;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String content;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;

  const ChatMessage({
    required this.messageId,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    required this.status,
    required this.timestamp,
    this.editedAt,
    this.metadata,
    this.replyToMessageId,
  });

  bool get isEdited => editedAt != null;
  bool get isSystemMessage => type == MessageType.system;
  bool get isFromMe => false;
}

class ChatChannel {
  final String channelId;
  final String name;
  final ChatChannelType type;
  final String? description;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? ownerId;
  final int maxMembers;
  final DateTime createdAt;
  final bool isMuted;
  final bool isPinned;
  final int unreadCount;

  const ChatChannel({
    required this.channelId,
    required this.name,
    required this.type,
    this.description,
    required this.memberIds,
    required this.adminIds,
    this.ownerId,
    required this.maxMembers,
    required this.createdAt,
    required this.isMuted,
    required this.isPinned,
    required this.unreadCount,
  });

  bool get isFull => memberIds.length >= maxMembers;
  bool get isPrivate => type == ChatChannelType.private;
  bool get isGlobal => type == ChatChannelType.global;
}

class ChatFilter {
  final String filterId;
  final String name;
  final List<String> blockedWords;
  final List<String> allowedWords;
  final bool isEnabled;
  final bool isCaseSensitive;

  const ChatFilter({
    required this.filterId,
    required this.name,
    required this.blockedWords,
    required this.allowedWords,
    required this.isEnabled,
    required this.isCaseSensitive,
  });

  bool shouldBlock(String message) {
    if (!isEnabled) return false;

    final searchMessage = isCaseSensitive ? message : message.toLowerCase();

    for (final word in blockedWords) {
      final searchWord = isCaseSensitive ? word : word.toLowerCase();
      if (searchMessage.contains(searchWord)) {
        return true;
      }
    }

    return false;
  }
}

class TypingIndicator {
  final String userId;
  final String channelId;
  final DateTime timestamp;

  const TypingIndicator({
    required this.userId,
    required this.channelId,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 5;
}

class ChatManager {
  static final ChatManager _instance = ChatManager._();
  static ChatManager get instance => _instance;

  ChatManager._();

  final Map<String, ChatChannel> _channels = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, ChatFilter> _filters = {};
  final Map<String, Set<String>> _blockedUsers = {};
  final Map<String, List<TypingIndicator>> _typingIndicators = {};
  final StreamController<ChatEvent> _eventController = StreamController.broadcast();
  final Map<String, DateTime> _lastMessageTime = {};
  Timer? _cleanupTimer;

  static const int _maxMessageLength = 500;
  static const int _maxMessagesPerMinute = 60;
  static const Duration _typingTimeout = Duration(seconds: 5);

  Stream<ChatEvent> get onChatEvent => _eventController.stream;

  Future<void> initialize() async {
    await _loadDefaultChannels();
    await _loadDefaultFilters();
    _startCleanupTimer();
  }

  Future<void> _loadDefaultChannels() async {
    final channels = [
      ChatChannel(
        channelId: 'global',
        name: 'Global Chat',
        type: ChatChannelType.global,
        description: 'Chat with all players',
        memberIds: [],
        adminIds: [],
        maxMembers: -1,
        createdAt: DateTime.now(),
        isMuted: false,
        isPinned: true,
        unreadCount: 0,
      ),
      ChatChannel(
        channelId: 'announcement',
        name: 'Announcements',
        type: ChatChannelType.announcement,
        description: 'Official announcements',
        memberIds: [],
        adminIds: ['system'],
        maxMembers: -1,
        createdAt: DateTime.now(),
        isMuted: false,
        isPinned: true,
        unreadCount: 0,
      ),
    ];

    for (final channel in channels) {
      _channels[channel.channelId] = channel;
      _messages[channel.channelId] = [];
    }
  }

  Future<void> _loadDefaultFilters() async {
    final filters = [
      ChatFilter(
        filterId: 'profanity',
        name: 'Profanity Filter',
        blockedWords: ['badword1', 'badword2'],
        allowedWords: [],
        isEnabled: true,
        isCaseSensitive: false,
      ),
      ChatFilter(
        filterId: 'spam',
        name: 'Spam Filter',
        blockedWords: ['buy gold', 'cheap items'],
        allowedWords: [],
        isEnabled: true,
        isCaseSensitive: false,
      ),
    ];

    for (final filter in filters) {
      _filters[filter.filterId] = filter;
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupTypingIndicators(),
    );
  }

  List<ChatChannel> getAllChannels() {
    return _channels.values.toList();
  }

  List<ChatChannel> getChannelsForUser(String userId) {
    return _channels.values
        .where((channel) =>
            channel.type == ChatChannelType.global ||
            channel.type == ChatChannelType.announcement ||
            channel.memberIds.contains(userId))
        .toList();
  }

  ChatChannel? getChannel(String channelId) {
    return _channels[channelId];
  }

  ChatChannel createChannel({
    required String channelId,
    required String name,
    required ChatChannelType type,
    String? description,
    String? ownerId,
    int maxMembers = 100,
  }) {
    final channel = ChatChannel(
      channelId: channelId,
      name: name,
      type: type,
      description: description,
      memberIds: [],
      adminIds: ownerId != null ? [ownerId] : [],
      ownerId: ownerId,
      maxMembers: maxMembers,
      createdAt: DateTime.now(),
      isMuted: false,
      isPinned: false,
      unreadCount: 0,
    );

    _channels[channelId] = channel;
    _messages[channelId] = [];

    _eventController.add(ChatEvent(
      type: ChatEventType.channelCreated,
      channelId: channelId,
      timestamp: DateTime.now(),
    ));

    return channel;
  }

  Future<bool> joinChannel({
    required String channelId,
    required String userId,
  }) async {
    final channel = _channels[channelId];
    if (channel == null) return false;
    if (channel.isFull) return false;

    final updated = ChatChannel(
      channelId: channel.channelId,
      name: channel.name,
      type: channel.type,
      description: channel.description,
      memberIds: [...channel.memberIds, userId],
      adminIds: channel.adminIds,
      ownerId: channel.ownerId,
      maxMembers: channel.maxMembers,
      createdAt: channel.createdAt,
      isMuted: channel.isMuted,
      isPinned: channel.isPinned,
      unreadCount: channel.unreadCount,
    );

    _channels[channelId] = updated;

    _eventController.add(ChatEvent(
      type: ChatEventType.userJoined,
      channelId: channelId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<bool> leaveChannel({
    required String channelId,
    required String userId,
  }) async {
    final channel = _channels[channelId];
    if (channel == null) return false;

    final updated = ChatChannel(
      channelId: channel.channelId,
      name: channel.name,
      type: channel.type,
      description: channel.description,
      memberIds: channel.memberIds..remove(userId),
      adminIds: channel.adminIds..remove(userId),
      ownerId: channel.ownerId,
      maxMembers: channel.maxMembers,
      createdAt: channel.createdAt,
      isMuted: channel.isMuted,
      isPinned: channel.isPinned,
      unreadCount: channel.unreadCount,
    );

    _channels[channelId] = updated;

    _eventController.add(ChatEvent(
      type: ChatEventType.userLeft,
      channelId: channelId,
      userId: userId,
      timestamp: DateTime.now(),
    ));

    return true;
  }

  Future<ChatMessage?> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    String? replyToMessageId,
  }) async {
    final channel = _channels[channelId];
    if (channel == null) return null;
    if (channel.isMuted) return null;

    if (!_canSend(senderId)) {
      return null;
    }

    if (!_applyFilters(content)) {
      _eventController.add(ChatEvent(
        type: ChatEventType.messageBlocked,
        channelId: channelId,
        userId: senderId,
        timestamp: DateTime.now(),
        data: {'reason': 'filtered'},
      ));
      return null;
    }

    final message = ChatMessage(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      type: type,
      content: content,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      replyToMessageId: replyToMessageId,
    );

    _messages[channelId]?.add(message);
    _lastMessageTime[senderId] = DateTime.now();

    _eventController.add(ChatEvent(
      type: ChatEventType.messageSent,
      channelId: channelId,
      messageId: message.messageId,
      timestamp: DateTime.now(),
    ));

    return message;
  }

  bool _canSend(String userId) {
    final lastTime = _lastMessageTime[userId];
    if (lastTime == null) return true;

    final elapsed = DateTime.now().difference(lastTime);
    if (elapsed.inSeconds < 1) {
      return false;
    }

    return true;
  }

  bool _applyFilters(String content) {
    for (final filter in _filters.values) {
      if (filter.shouldBlock(content)) {
        return false;
      }
    }
    return true;
  }

  List<ChatMessage> getMessages({
    required String channelId,
    int limit = 50,
    String? beforeMessageId,
  }) {
    final messages = _messages[channelId] ?? [];
    final result = messages.toList();

    if (beforeMessageId != null) {
      final index = result.indexWhere((m) => m.messageId == beforeMessageId);
      if (index >= 0) {
        result.removeRange(0, index + 1);
      }
    }

    if (result.length > limit) {
      result.removeRange(limit, result.length);
    }

    return result;
  }

  Future<bool> editMessage({
    required String messageId,
    required String newContent,
    required String userId,
  }) async {
    for (final messages in _messages.values) {
      final index = messages.indexWhere((m) => m.messageId == messageId);
      if (index >= 0) {
        final message = messages[index];
        if (message.senderId != userId) return false;

        final edited = ChatMessage(
          messageId: message.messageId,
          channelId: message.channelId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          type: message.type,
          content: newContent,
          status: message.status,
          timestamp: message.timestamp,
          editedAt: DateTime.now(),
          metadata: message.metadata,
          replyToMessageId: message.replyToMessageId,
        );

        messages[index] = edited;

        _eventController.add(ChatEvent(
          type: ChatEventType.messageEdited,
          channelId: message.channelId,
          messageId: messageId,
          timestamp: DateTime.now(),
        ));

        return true;
      }
    }
    return false;
  }

  Future<bool> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    for (final messages in _messages.values) {
      final index = messages.indexWhere((m) => m.messageId == messageId);
      if (index >= 0) {
        final message = messages[index];
        if (message.senderId != userId) return false;

        messages.removeAt(index);

        _eventController.add(ChatEvent(
          type: ChatEventType.messageDeleted,
          channelId: message.channelId,
          messageId: messageId,
          timestamp: DateTime.now(),
        ));

        return true;
      }
    }
    return false;
  }

  void startTyping({
    required String channelId,
    required String userId,
  }) {
    final indicators = _typingIndicators[channelId] ?? [];
    indicators.removeWhere((indicator) => indicator.userId == userId);
    indicators.add(TypingIndicator(
      userId: userId,
      channelId: channelId,
      timestamp: DateTime.now(),
    ));
    _typingIndicators[channelId] = indicators;

    _eventController.add(ChatEvent(
      type: ChatEventType.typingStarted,
      channelId: channelId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  void stopTyping({
    required String channelId,
    required String userId,
  }) {
    final indicators = _typingIndicators[channelId];
    if (indicators != null) {
      indicators.removeWhere((indicator) => indicator.userId == userId);
    }

    _eventController.add(ChatEvent(
      type: ChatEventType.typingStopped,
      channelId: channelId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  List<TypingIndicator> getTypingIndicators(String channelId) {
    final indicators = _typingIndicators[channelId] ?? [];
    return indicators.where((indicator) => !indicator.isExpired).toList();
  }

  void _cleanupTypingIndicators() {
    for (final channelId in _typingIndicators.keys) {
      final indicators = _typingIndicators[channelId];
      if (indicators != null) {
        indicators.removeWhere((indicator) => indicator.isExpired);
      }
    }
  }

  void blockUser({
    required String userId,
    required String blockedUserId,
  }) {
    _blockedUsers.putIfAbsent(userId, () => {});
    _blockedUsers[userId]!.add(blockedUserId);

    _eventController.add(ChatEvent(
      type: ChatEventType.userBlocked,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'blockedUserId': blockedUserId},
    ));
  }

  void unblockUser({
    required String userId,
    required String blockedUserId,
  }) {
    _blockedUsers[userId]?.remove(blockedUserId);

    _eventController.add(ChatEvent(
      type: ChatEventType.userUnblocked,
      userId: userId,
      timestamp: DateTime.now(),
      data: {'blockedUserId': blockedUserId},
    ));
  }

  bool isUserBlocked({
    required String userId,
    required String targetUserId,
  }) {
    return _blockedUsers[userId]?.contains(targetUserId) ?? false;
  }

  List<String> getBlockedUsers(String userId) {
    return _blockedUsers[userId]?.toList() ?? [];
  }

  Future<bool> muteChannel({
    required String channelId,
    required String userId,
  }) async {
    return true;
  }

  Future<bool> pinChannel({
    required String channelId,
    required String userId,
  }) async {
    return true;
  }

  void markChannelAsRead({
    required String channelId,
    required String userId,
  }) {
    _eventController.add(ChatEvent(
      type: ChatEventType.channelRead,
      channelId: channelId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  Map<String, dynamic> getChatStats() {
    int totalMessages = 0;
    for (final messages in _messages.values) {
      totalMessages += messages.length;
    }

    return {
      'totalChannels': _channels.length,
      'totalMessages': totalMessages,
      'totalFilters': _filters.length,
      'blockedUsersCount': _blockedUsers.length,
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _eventController.close();
  }
}

class ChatEvent {
  final ChatEventType type;
  final String? channelId;
  final String? messageId;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const ChatEvent({
    required this.type,
    this.channelId,
    this.messageId,
    this.userId,
    required this.timestamp,
    this.data,
  });
}

enum ChatEventType {
  channelCreated,
  channelDeleted,
  userJoined,
  userLeft,
  messageSent,
  messageEdited,
  messageDeleted,
  messageBlocked,
  typingStarted,
  typingStopped,
  userBlocked,
  userUnblocked,
  channelRead,
  channelMuted,
  channelUnmuted,
}

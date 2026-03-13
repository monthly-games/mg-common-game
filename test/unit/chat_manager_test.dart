import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/communication/chat_manager.dart';

void main() {
  late ChatManager chatManager;

  setUp(() {
    chatManager = ChatManager.instance;
  });

  tearDown(() async {
    await chatManager.dispose();
  });

  group('ChatManager Tests', () {
    test('should be singleton instance', () {
      final instance1 = ChatManager.instance;
      final instance2 = ChatManager.instance;
      expect(instance1, equals(instance2));
    });

    test('should initialize channels', () async {
      await chatManager.initialize();
      final channels = chatManager.getAllChannels();
      expect(channels, isNotEmpty);
    });

    test('should create channel successfully', () async {
      await chatManager.initialize();
      final channel = await chatManager.createChannel(
        channelId: 'test_channel',
        name: 'Test Channel',
        type: ChatChannelType.global,
      );
      expect(channel, isNotNull);
      expect(channel?.channelId, equals('test_channel'));
    });

    test('should send message successfully', () async {
      await chatManager.initialize();
      await chatManager.createChannel(
        channelId: 'test_msg',
        name: 'Test Msg',
        type: ChatChannelType.global,
      );

      final message = await chatManager.sendMessage(
        channelId: 'test_msg',
        senderId: 'user1',
        senderName: 'Test User',
        content: 'Hello World',
      );

      expect(message, isNotNull);
      expect(message?.content, equals('Hello World'));
    });

    test('should block profanity messages', () async {
      await chatManager.initialize();
      await chatManager.createChannel(
        channelId: 'test_profanity',
        name: 'Test Profanity',
        type: ChatChannelType.global,
      );

      final message = await chatManager.sendMessage(
        channelId: 'test_profanity',
        senderId: 'user1',
        senderName: 'Test User',
        content: 'bad word here',
      );

      expect(message, isNull);
    });

    test('should get channel messages', () async {
      await chatManager.initialize();
      final channelId = 'test_messages';
      await chatManager.createChannel(
        channelId: channelId,
        name: 'Test Messages',
        type: ChatChannelType.global,
      );

      await chatManager.sendMessage(
        channelId: channelId,
        senderId: 'user1',
        senderName: 'User 1',
        content: 'Message 1',
      );

      final messages = chatManager.getMessages(channelId);
      expect(messages, isNotEmpty);
    });

    test('should block user successfully', () async {
      await chatManager.initialize();
      final result = await chatManager.blockUser(
        blockerId: 'user1',
        blockedId: 'user2',
      );
      expect(result, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/social/friend_manager.dart';
import 'package:mg_common_game/communication/chat_manager.dart';
import 'package:mg_common_game/communication/mail_manager.dart';

void main() {
  group('Social Integration Tests', () {
    late FriendManager friendManager;
    late ChatManager chatManager;
    late MailManager mailManager;

    setUp(() async {
      friendManager = FriendManager.instance;
      chatManager = ChatManager.instance;
      mailManager = MailManager.instance;

      await friendManager.initialize(maxFriends: 100);
      await chatManager.initialize();
      await mailManager.initialize(maxMailSlots: 100);
    });

    test('should send friend request and create mail notification', () async {
      const senderId = 'user1';
      const receiverId = 'user2';

      // Send friend request
      await friendManager.sendFriendRequest(senderId, receiverId);

      // Check if request exists
      final requests = friendManager.getFriendRequests(receiverId);
      expect(requests.any((r) => r.userId == senderId), isTrue);
    });

    test('should allow chat between friends', () async {
      const user1 = 'chat_user1';
      const user2 = 'chat_user2';

      // Add as friends
      await friendManager.addFriend(user1, user2);

      // Create chat channel
      final channel = await chatManager.createChannel(
        channelId: 'chat_test_1',
        channelType: ChannelType.direct,
        name: 'Direct Chat',
        members: [user1, user2],
      );

      expect(channel, isNotNull);

      // Send message
      final message = await chatManager.sendMessage(
        channelId: 'chat_test_1',
        senderId: user1,
        senderName: 'User 1',
        content: 'Hello friend!',
      );

      expect(message, isNotNull);
      expect(message?.content, 'Hello friend!');
    });

    test('should send mail with item attachment', () async {
      const senderId = 'mail_sender';
      const receiverId = 'mail_receiver';

      await mailManager.sendMail(
        mailId: 'mail_test_1',
        senderId: senderId,
        receiverId: receiverId,
        senderName: 'System',
        title: 'Reward Mail',
        body: 'Here is your reward!',
        type: MailType.reward,
        attachments: [
          MailAttachment(
            itemId: 'reward_item',
            itemName: 'Reward Item',
            itemType: 'consumable',
            quantity: 5,
          ),
        ],
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final mails = mailManager.getMails(receiverId);
      expect(mails.any((m) => m.mailId == 'mail_test_1'), isTrue);
    });

    test('should collect mail attachments and add to inventory', () async {
      const userId = 'mail_collect_user';

      await mailManager.sendMail(
        mailId: 'mail_collect_1',
        senderId: 'system',
        receiverId: userId,
        senderName: 'System',
        title: 'Gift',
        body: 'Enjoy!',
        type: MailType.reward,
        attachments: [
          MailAttachment(
            itemId: 'gift_item',
            itemName: 'Gift',
            itemType: 'material',
            quantity: 10,
          ),
        ],
      );

      final success = await mailManager.collectAttachments(
        userId: userId,
        mailId: 'mail_collect_1',
      );

      expect(success, isTrue);
    });

    test('should block chat messages from blocked users', () async {
      const user1 = 'block_user1';
      const user2 = 'block_user2';

      await friendManager.blockUser(user1, user2);

      final channel = await chatManager.createChannel(
        channelId: 'block_test_channel',
        channelType: ChannelType.direct,
        name: 'Block Test',
        members: [user1, user2],
      );

      // Try to send message from blocked user
      final message = await chatManager.sendMessage(
        channelId: 'block_test_channel',
        senderId: user2,
        senderName: 'User 2',
        content: 'This should be blocked',
      );

      expect(message, isNull);
    });

    test('should unfriend and remove from friend list', () async {
      const user1 = 'unfriend_user1';
      const user2 = 'unfriend_user2';

      await friendManager.addFriend(user1, user2);
      expect(friendManager.getFriends(user1).any((f) => f.userId == user2), isTrue);

      await friendManager.removeFriend(user1, user2);
      expect(friendManager.getFriends(user1).any((f) => f.userId == user2), isFalse);
    });

    test('should suggest friends based on mutual connections', () async {
      const user1 = 'suggest_user1';
      const user2 = 'suggest_user2';
      const user3 = 'suggest_user3';

      await friendManager.addFriend(user1, user2);

      final suggestions = friendManager.getFriendSuggestions(user3, limit: 10);
      expect(suggestions, isNotEmpty);
    });

    test('should mark mail as read when opened', () async {
      const userId = 'read_mail_user';

      await mailManager.sendMail(
        mailId: 'read_mail_test',
        senderId: 'system',
        receiverId: userId,
        senderName: 'System',
        title: 'Test Mail',
        body: 'Test',
        type: MailType.system,
      );

      await mailManager.markAsRead(userId: userId, mailId: 'read_mail_test');

      final mails = mailManager.getMails(userId);
      final mail = mails.firstWhere((m) => m.mailId == 'read_mail_test');

      expect(mail.isRead, isTrue);
    });
  });
}

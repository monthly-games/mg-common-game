import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/social/friend_manager.dart';
import 'package:mg_common_game/communication/chat_manager.dart';
import 'package:mg_common_game/communication/mail_manager.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/shop/shop_manager.dart';
import 'package:mg_common_game/player/currency_manager.dart';
import 'package:mg_common_game/guild/guild_manager.dart';

void main() {
  group('Social & Economy Golden Test', () {
    late FriendManager friendManager;
    late ChatManager chatManager;
    late MailManager mailManager;
    late InventoryManager inventoryManager;
    late ShopManager shopManager;
    late CurrencyManager currencyManager;
    late GuildManager guildManager;

    setUp(() async {
      friendManager = FriendManager.instance;
      chatManager = ChatManager.instance;
      mailManager = MailManager.instance;
      inventoryManager = InventoryManager.instance;
      shopManager = ShopManager.instance;
      currencyManager = CurrencyManager.instance;
      guildManager = GuildManager.instance;

      await friendManager.initialize(maxFriends: 100);
      await chatManager.initialize();
      await mailManager.initialize(maxMailSlots: 100);
      await inventoryManager.initialize(maxSlots: 100);
      await shopManager.initialize();
      await currencyManager.initialize();
      await guildManager.initialize();
    });

    test('complete social interaction flow', () async {
      const user1Id = 'social_user_1';
      const user2Id = 'social_user_2';

      // Step 1: Send friend request
      await friendManager.sendFriendRequest(user1Id, user2Id);

      var requests = friendManager.getFriendRequests(user2Id);
      expect(requests.any((r) => r.userId == user1Id), isTrue);

      // Step 2: Accept friend request
      await friendManager.acceptFriendRequest(user2Id, user1Id);

      var friends1 = friendManager.getFriends(user1Id);
      var friends2 = friendManager.getFriends(user2Id);

      expect(friends1.any((f) => f.userId == user2Id), isTrue);
      expect(friends2.any((f) => f.userId == user1Id), isTrue);

      // Step 3: Create chat channel
      final channel = await chatManager.createChannel(
        channelId: 'social_chat_1',
        channelType: ChannelType.direct,
        name: 'Private Chat',
        members: [user1Id, user2Id],
      );

      expect(channel, isNotNull);

      // Step 4: Exchange messages
      for (int i = 0; i < 5; i++) {
        await chatManager.sendMessage(
          channelId: 'social_chat_1',
          senderId: user1Id,
          senderName: 'User 1',
          content: 'Message $i from user 1',
        );

        await chatManager.sendMessage(
          channelId: 'social_chat_1',
          senderId: user2Id,
          senderName: 'User 2',
          content: 'Message $i from user 2',
        );
      }

      final messages = chatManager.getMessages('social_chat_1', limit: 20);
      expect(messages.length, greaterThanOrEqualTo(10);

      // Step 5: Send gift mail
      await mailManager.sendMail(
        mailId: 'gift_mail_1',
        senderId: user1Id,
        receiverId: user2Id,
        senderName: 'User 1',
        title: 'Gift for you!',
        body: 'Here is a special gift',
        type: MailType.social,
        attachments: [
          MailAttachment(
            itemId: 'gift_item',
            itemName: 'Special Gift',
            itemType: 'material',
            quantity: 10,
          ),
        ],
      );

      final mails = mailManager.getMails(user2Id);
      expect(mails.any((m) => m.mailId == 'gift_mail_1'), isTrue);

      // Step 6: Collect gift
      await mailManager.collectAttachments(
        userId: user2Id,
        mailId: 'gift_mail_1',
      );

      final inventory = inventoryManager.getInventory(user2Id);
      expect(inventory?.items.any((i) => i.itemId == 'gift_item'), isTrue);
    });

    test('guild creation and management flow', () async {
      const guildId = 'test_guild';
      const leaderId = 'guild_leader';
      final memberIds = ['member_1', 'member_2', 'member_3'];

      // Step 1: Create guild
      await guildManager.createGuild(
        guildId: guildId,
        name: 'Test Guild',
        description: 'A test guild',
        leaderId: leaderId,
        maxMembers: 50,
      );

      final guild = guildManager.getGuild(guildId);
      expect(guild, isNotNull);
      expect(guild?.leaderId, leaderId);

      // Step 2: Members join guild
      for (final memberId in memberIds) {
        await guildManager.joinGuild(guildId, memberId);
      }

      final updatedGuild = guildManager.getGuild(guildId);
      expect(updatedGuild?.members.length, greaterThanOrEqualTo(memberIds.length));

      // Step 3: Send guild announcement
      await guildManager.sendAnnouncement(
        guildId: guildId,
        title: 'Welcome!',
        message: 'Welcome to our guild!',
      );

      // Step 4: Contribute to guild
      for (final memberId in memberIds) {
        await guildManager.contribute(
          guildId: guildId,
          userId: memberId,
          amount: 100,
        );
      }

      final finalGuild = guildManager.getGuild(guildId);
      expect(finalGuild?.totalContributions, greaterThanOrEqualTo(300));
    });

    test('complete economy flow', () async {
      const playerId = 'economy_player';

      // Step 1: Initial currency
      await currencyManager.addCurrency(
        userId: playerId,
        currencyId: 'gold',
        amount: 1000,
      );

      await currencyManager.addCurrency(
        userId: playerId,
        currencyId: 'gems',
        amount: 100,
      );

      // Step 2: Purchase items
      await shopManager.createShopItem(
        itemId: 'sword',
        name: 'Iron Sword',
        description: 'A basic sword',
        basePrice: 200,
        currencyId: 'gold',
        category: ShopItemCategory.equipment,
      );

      await shopManager.createShopItem(
        itemId: 'potion',
        name: 'Health Potion',
        description: 'Restores health',
        basePrice: 50,
        currencyId: 'gold',
        category: ShopItemCategory.consumable,
      );

      await shopManager.purchaseItem(userId: playerId, itemId: 'sword', quantity: 1);
      await shopManager.purchaseItem(userId: playerId, itemId: 'potion', quantity: 5);

      var goldBalance = currencyManager.getBalance(playerId, 'gold');
      expect(goldBalance, lessThan(1000)); // Should have spent money

      // Step 3: Sell items back (if implemented)
      final inventory = inventoryManager.getInventory(playerId);
      expect(inventory?.items.length, greaterThan(0));

      // Step 4: Use consumable
      await inventoryManager.useItem(
        userId: playerId,
        itemId: 'potion',
        quantity: 1,
      );

      final updatedInventory = inventoryManager.getInventory(playerId);
      final potionItem = updatedInventory?.items.firstWhere((i) => i.itemId == 'potion');
      expect(potionItem?.quantity, lessThan(5)); // Should have used one

      // Step 5: Purchase premium item with gems
      await shopManager.createShopItem(
        itemId: 'premium_skin',
        name: 'Premium Skin',
        description: 'Exclusive skin',
        basePrice: 50,
        currencyId: 'gems',
        category: ShopItemCategory.cosmetic,
      );

      await shopManager.purchaseItem(
        userId: playerId,
        itemId: 'premium_skin',
        quantity: 1,
      );

      final gemsBalance = currencyManager.getBalance(playerId, 'gems');
      expect(gemsBalance, lessThan(100)); // Should have spent gems
    });

    test('trading between players flow', () async {
      const player1Id = 'trader_1';
      const player2Id = 'trader_2';

      // Give player 1 items to trade
      await inventoryManager.addItem(
        userId: player1Id,
        itemId: 'trade_item',
        name: 'Tradeable Item',
        quantity: 10,
        type: InventoryItemType.material,
      );

      // Give player 2 currency
      await currencyManager.addCurrency(
        userId: player2Id,
        currencyId: 'gold',
        amount: 5000,
      );

      // Player 1 sends trade offer (via mail for simplicity)
      await mailManager.sendMail(
        mailId: 'trade_offer_1',
        senderId: player1Id,
        receiverId: player2Id,
        senderName: 'Trader 1',
        title: 'Trade Offer',
        body: 'I\'ll trade 10 items for 1000 gold',
        type: MailType.social,
        attachments: [
          MailAttachment(
            itemId: 'trade_item',
            itemName: 'Tradeable Item',
            itemType: 'material',
            quantity: 10,
          ),
        ],
      );

      // Verify offer received
      final mails = mailManager.getMails(player2Id);
      expect(mails.any((m) => m.mailId == 'trade_offer_1'), isTrue);
    });

    test('daily rewards economy cycle', () async {
      const playerId = 'daily_rewards_player';

      // Simulate 30 days of daily rewards
      for (int day = 1; day <= 30; day++) {
        // Daily login reward
        final dailyGold = 100 * day;
        await currencyManager.addCurrency(
          userId: playerId,
          currencyId: 'gold',
          amount: dailyGold,
        );

        // Every 7 days bonus
        if (day % 7 == 0) {
          await currencyManager.addCurrency(
            userId: playerId,
            currencyId: 'gems',
            amount: 50,
          );
        }

        // Monthly bonus
        if (day == 30) {
          await mailManager.sendMail(
            mailId: 'monthly_bonus',
            senderId: 'system',
            receiverId: playerId,
            senderName: 'System',
            title: 'Monthly Bonus!',
            body: 'Congratulations on 30 days!',
            type: MailType.reward,
            attachments: [
              MailAttachment(
                itemId: 'monthly_reward',
                itemName: 'Monthly Chest',
                itemType: 'bundle',
                quantity: 1,
              ),
            ],
          );
        }
      }

      // Check total accumulated
      final totalGold = currencyManager.getBalance(playerId, 'gold');
      final totalGems = currencyManager.getBalance(playerId, 'gems');

      expect(totalGold, greaterThan(0));
      expect(totalGems, greaterThan(0));

      // Verify monthly bonus mail
      final mails = mailManager.getMails(playerId);
      expect(mails.any((m) => m.mailId == 'monthly_bonus'), isTrue);
    });
  });
}

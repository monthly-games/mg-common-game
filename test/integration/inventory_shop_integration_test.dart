import 'package:flutter_test/flutter_test.dart';
import 'package:mg_common_game/inventory/inventory_manager.dart';
import 'package:mg_common_game/shop/shop_manager.dart';
import 'package:mg_common_game/player/currency_manager.dart';

void main() {
  group('Inventory Shop Integration Tests', () {
    late InventoryManager inventoryManager;
    late ShopManager shopManager;
    late CurrencyManager currencyManager;

    setUp(() async {
      inventoryManager = InventoryManager.instance;
      shopManager = ShopManager.instance;
      currencyManager = CurrencyManager.instance;

      await inventoryManager.initialize(maxSlots: 100);
      await shopManager.initialize();
      await currencyManager.initialize();
    });

    test('should purchase item and add to inventory', () async {
      const userId = 'test_user_purchase';

      // Add currency to user
      await currencyManager.addCurrency(
        userId: userId,
        currencyId: 'gold',
        amount: 1000,
      );

      // Create shop item
      await shopManager.createShopItem(
        itemId: 'shop_item_1',
        name: 'Test Item',
        description: 'Test item for shop',
        basePrice: 100,
        currencyId: 'gold',
        category: ShopItemCategory.consumable,
      );

      // Purchase item
      final success = await shopManager.purchaseItem(
        userId: userId,
        itemId: 'shop_item_1',
        quantity: 1,
      );

      expect(success, isTrue);

      // Verify item in inventory
      final inventory = inventoryManager.getInventory(userId);
      final item = inventory?.items.firstWhere(
        (i) => i.itemId == 'shop_item_1',
        orElse: () => throw Exception('Item not found'),
      );

      expect(item, isNotNull);
      expect(item?.quantity, greaterThanOrEqualTo(1));
    });

    test('should deduct currency on purchase', () async {
      const userId = 'test_user_currency';

      await currencyManager.addCurrency(
        userId: userId,
        currencyId: 'gold',
        amount: 1000,
      );

      final initialBalance = currencyManager.getBalance(userId, 'gold');

      await shopManager.createShopItem(
        itemId: 'shop_item_2',
        name: 'Test Item 2',
        description: 'Test item 2',
        basePrice: 100,
        currencyId: 'gold',
        category: ShopItemCategory.consumable,
      );

      await shopManager.purchaseItem(
        userId: userId,
        itemId: 'shop_item_2',
        quantity: 1,
      );

      final finalBalance = currencyManager.getBalance(userId, 'gold');

      expect(finalBalance, lessThan(initialBalance!));
    });

    test('should prevent purchase when insufficient currency', () async {
      const userId = 'test_user_insufficient';

      await currencyManager.addCurrency(
        userId: userId,
        currencyId: 'gold',
        amount: 50,
      );

      await shopManager.createShopItem(
        itemId: 'shop_item_3',
        name: 'Expensive Item',
        description: 'Expensive item',
        basePrice: 100,
        currencyId: 'gold',
        category: ShopItemCategory.consumable,
      );

      final success = await shopManager.purchaseItem(
        userId: userId,
        itemId: 'shop_item_3',
        quantity: 1,
      );

      expect(success, isFalse);
    });

    test('should prevent purchase when inventory full', () async {
      const userId = 'test_user_full';

      await inventoryManager.initialize(maxSlots: 1);
      await currencyManager.addCurrency(
        userId: userId,
        currencyId: 'gold',
        amount: 1000,
      );

      // Fill inventory
      await inventoryManager.addItem(
        userId: userId,
        itemId: 'filler_item',
        name: 'Filler',
        quantity: 1,
        type: InventoryItemType consumable,
      );

      await shopManager.createShopItem(
        itemId: 'shop_item_4',
        name: 'Test Item 4',
        description: 'Test',
        basePrice: 100,
        currencyId: 'gold',
        category: ShopItemCategory.consumable,
      );

      final success = await shopManager.purchaseItem(
        userId: userId,
        itemId: 'shop_item_4',
        quantity: 1,
      );

      expect(success, isFalse);
    });

    test('should handle bundle purchase correctly', () async {
      const userId = 'test_user_bundle';

      await currencyManager.addCurrency(
        userId: userId,
        currencyId: 'gold',
        amount: 2000,
      );

      await shopManager.createBundle(
        bundleId: 'bundle_1',
        name: 'Starter Bundle',
        description: 'Starter pack',
        basePrice: 500,
        currencyId: 'gold',
        items: [
          BundleItem(itemId: 'item1', quantity: 2),
          BundleItem(itemId: 'item2', quantity: 3),
        ],
      );

      final success = await shopManager.purchaseBundle(
        userId: userId,
        bundleId: 'bundle_1',
      );

      expect(success, isTrue);
    });
  });
}

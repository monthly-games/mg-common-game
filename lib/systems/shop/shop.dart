/// Shop System for MG-Games
///
/// Manages in-game shops, bundles, currency, and purchases.
///
/// ## Basic Usage
/// ```dart
/// import 'package:mg_common_game/systems/shop/shop.dart';
///
/// final shop = ShopManager();
///
/// // Set up currency
/// shop.setCurrency(CurrencyType.softCurrency, 1000);
/// shop.setCurrency(CurrencyType.hardCurrency, 100);
///
/// // Register items
/// shop.registerItem(ShopItem(
///   id: 'gold_pack_1',
///   name: '1000 Gold',
///   description: 'A pack of gold coins',
///   category: ShopCategory.currency,
///   currencyType: CurrencyType.hardCurrency,
///   price: 50,
///   rewards: {'gold': 1000},
/// ));
///
/// // Purchase
/// final result = await shop.purchaseItem('gold_pack_1');
/// if (result == PurchaseResult.success) {
///   print('Purchase successful!');
/// }
/// ```
///
/// ## Limited Time Offers
/// ```dart
/// shop.registerItem(ShopItem(
///   id: 'holiday_bundle',
///   name: 'Holiday Special',
///   category: ShopCategory.bundles,
///   currencyType: CurrencyType.hardCurrency,
///   price: 100,
///   originalPrice: 200, // 50% off!
///   availableUntil: DateTime(2024, 12, 31),
///   purchaseLimit: 1, // Once per user
/// ));
/// ```
///
/// ## Refresh Shop (Daily Deals)
/// ```dart
/// shop.registerRefreshSection(RefreshShopSection(
///   id: 'daily_deals',
///   name: 'Daily Deals',
///   items: [...],
///   nextRefresh: DateTime.now().add(Duration(hours: 24)),
///   manualRefreshCost: 50,
///   refreshCurrencyType: CurrencyType.hardCurrency,
/// ));
/// ```
library shop;

export 'shop_types.dart';
export 'shop_manager.dart';

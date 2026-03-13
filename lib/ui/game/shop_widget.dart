import 'package:flutter/material.dart';
import 'package:mg_common_game/monetization/item_shop_manager.dart';

class ShopWidget extends StatefulWidget {
  final String userId;

  const ShopWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ShopWidget> createState() => _ShopWidgetState();
}

class _ShopWidgetState extends State<ShopWidget> {
  final ItemShopManager _shopManager = ItemShopManager.instance;
  List<ShopItem> _items = [];
  List<ShopBundle> _bundles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    await _shopManager.initialize();
    setState(() => _isLoading = true);
    _items = _shopManager.getAllItems();
    _bundles = _shopManager.getAllBundles();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Items'),
              Tab(text: 'Bundles'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildItemsTab(),
                  _buildBundlesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildItemsTab() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildShopItemCard(item);
      },
    );
  }

  Widget _buildBundlesTab() {
    return ListView.builder(
      itemCount: _bundles.length,
      itemBuilder: (context, index) {
        final bundle = _bundles[index];
        return _buildBundleCard(bundle);
      },
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    final price = _shopManager.calculatePrice(item.itemId);
    final originalPrice = item.basePrice;
    final discount = originalPrice > price;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Featured',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            const Spacer(),
            Center(
              child: Icon(
                Icons.shopping_bag,
                size: 48,
                color: _getRarityColor(item.itemType),
              ),
            ),
            const Spacer(),
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (discount)
              Text(
                '$originalPrice',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            Text(
              '$price ${item.currencyId}',
              style: TextStyle(
                color: discount ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: () => _purchaseItem(item),
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleCard(ShopBundle bundle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(bundle.name),
        subtitle: Text('Save ${bundle.discountPercentage.toStringAsFixed(0)}%'),
        trailing: Text(
          '${bundle.discountedPrice} ${bundle.currencyId}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: [
          ...bundle.items.map((item) => ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(item.name),
                subtitle: Text('x${item.quantity}'),
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _purchaseBundle(bundle),
              child: const Text('Purchase Bundle'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String itemType) {
    switch (itemType) {
      case 'bundle':
        return Colors.purple;
      case 'consumable':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _purchaseItem(ShopItem item) async {
    final purchase = await _shopManager.purchaseItem(
      userId: widget.userId,
      itemId: item.itemId,
    );

    if (purchase != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} purchased!')),
      );
    }
  }

  Future<void> _purchaseBundle(ShopBundle bundle) async {
    final purchase = await _shopManager.purchaseBundle(
      userId: widget.userId,
      bundleId: bundle.bundleId,
    );

    if (purchase != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bundle.name} purchased!')),
      );
    }
  }
}

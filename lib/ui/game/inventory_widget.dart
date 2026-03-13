import 'package:flutter/material.dart';
import 'package:mg_common_game/player/inventory_manager.dart';

class InventoryWidget extends StatefulWidget {
  final String userId;

  const InventoryWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  final InventoryManager _inventoryManager = InventoryManager.instance;
  List<InventoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    _items = _inventoryManager.getInventory(widget.userId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildInventoryItem(item);
              },
            ),
    );
  }

  Widget _buildInventoryItem(InventoryItem item) {
    return Card(
      child: InkWell(
        onTap: () => _showItemDetails(item),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.quantity > 1)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  void _showItemDetails(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${item.type.name}'),
            Text('Rarity: ${item.rarity.name}'),
            Text('Quantity: ${item.quantity}'),
            if (item.durability > 0)
              LinearProgressIndicator(
                value: item.durabilityPercent,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

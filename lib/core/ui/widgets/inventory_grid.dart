import 'package:flutter/material.dart';
import '../../systems/rpg/inventory_system.dart';

class InventoryGrid extends StatelessWidget {
  final InventorySystem inventory;
  final int crossAxisCount;
  final ValueChanged<InventorySlot>? onSlotTap;

  const InventoryGrid({
    super.key,
    required this.inventory,
    this.crossAxisCount = 5,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final slots = inventory.slots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: inventory.capacity,
      itemBuilder: (context, index) {
        if (index >= slots.length) {
          return _buildEmptySlot();
        }
        return _buildItemSlot(slots[index]);
      },
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
    );
  }

  Widget _buildItemSlot(InventorySlot slot) {
    return GestureDetector(
      onTap: () => onSlotTap?.call(slot),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            // Icon Placeholder
            Center(
              child: Icon(Icons.backpack, color: Colors.white54, size: 24),
            ),
            // Quantity
            if (slot.quantity > 1)
              Positioned(
                bottom: 2,
                right: 4,
                child: Text(
                  '${slot.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

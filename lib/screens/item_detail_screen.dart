import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

class ItemDetailScreen extends StatelessWidget {
  final InventoryItem item;
  const ItemDetailScreen({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Category', item.category ?? '—'),
          _row('Motorcycle', item.motorcycle ?? '—'),
          _row('Barcode', item.barcode ?? '—'),
          _row('Buying Price', '₱${item.buyingPrice.toStringAsFixed(2)}'),
          _row('Selling Price', '₱${item.sellingPrice.toStringAsFixed(2)}'),
          _row('Quantity', '${item.quantity}'),
          _row('Low Stock Alert', '${item.lowStockThreshold}'),
          _row('Supplier', item.supplierName ?? '—'),
          _row('Contact', item.supplierContact ?? '—'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Inventory'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value),
        ],
      ),
    );
  }
}

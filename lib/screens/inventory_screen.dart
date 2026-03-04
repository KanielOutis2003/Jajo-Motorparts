import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import 'add_edit_item_screen.dart';
import 'sell_screen.dart';
import 'item_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  const InventoryScreen({super.key, this.onRefresh});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = InventoryService();
  List<InventoryItem> _items = [];
  List<InventoryItem> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _service.getAllItems();
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _items
        .where((i) =>
            i.name.toLowerCase().contains(_search.toLowerCase()) ||
            (i.barcode?.contains(_search) ?? false) ||
            (i.category?.toLowerCase().contains(_search.toLowerCase()) ??
                false))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱');
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      _search = v;
                      _applyFilter();
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Search items, barcode, category...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  backgroundColor: const Color(0xFFE53935),
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddEditItemScreen()));
                    _load();
                    widget.onRefresh?.call();
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No items found',
                            style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _itemCard(_filtered[i], currency),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(InventoryItem item, NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: item.isLowStock
            ? Border.all(color: Colors.orange.withValues(alpha: 0.5))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
        leading: CircleAvatar(
          backgroundColor: item.isLowStock
              ? Colors.orange.withValues(alpha: 0.2)
              : const Color(0xFFE53935).withValues(alpha: 0.2),
          child: Icon(
            Icons.build_circle_outlined,
            color: item.isLowStock ? Colors.orange : const Color(0xFFE53935),
          ),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15))),
            if (item.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('LOW',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (item.motorcycle != null)
              Text('Model: ${item.motorcycle}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
                'Qty: ${item.quantity}  •  Sell: ${currency.format(item.sellingPrice)}',
                style: const TextStyle(color: Colors.grey)),
            if (item.supplierName != null)
              Text('Supplier: ${item.supplierName}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'sell') {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SellScreen(item: item)));
              _load();
            } else if (val == 'edit') {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEditItemScreen(item: item)));
              _load();
            } else if (val == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Item'),
                  content: Text('Delete "${item.name}"?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await _service.deleteItem(item.id);
                _load();
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'sell', child: Text('💰 Sell')),
            const PopupMenuItem(value: 'edit', child: Text('✏️ Edit')),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ Delete')),
          ],
        ),
      ),
    );
  }
}

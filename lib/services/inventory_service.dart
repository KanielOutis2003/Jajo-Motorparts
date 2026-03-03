import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item.dart';

class InventoryService {
  final _db = Supabase.instance.client;

  // ── ITEMS ──────────────────────────────────────────────

  Future<List<InventoryItem>> getAllItems() async {
    final data = await _db
        .from('items')
        .select()
        .order('name', ascending: true);
    return (data as List).map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<InventoryItem?> getItemByBarcode(String barcode) async {
    final data = await _db
        .from('items')
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
    return data != null ? InventoryItem.fromMap(data) : null;
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final all = await getAllItems();
    return all.where((item) => item.isLowStock).toList();
  }

  Future<void> addItem(InventoryItem item) async {
    await _db.from('items').insert(item.toMap());
  }

  Future<void> updateItem(InventoryItem item) async {
    await _db.from('items').update(item.toMap()).eq('id', item.id);
  }

  Future<void> deleteItem(String id) async {
    await _db.from('items').delete().eq('id', id);
  }

  // ── STOCK IN (Restock) ────────────────────────────────

  Future<void> restockItem({
    required InventoryItem item,
    required int qty,
    required double unitPrice,
    String? notes,
  }) async {
    // Update quantity
    await _db.from('items').update({
      'quantity': item.quantity + qty,
    }).eq('id', item.id);

    // Log transaction
    await _db.from('transactions').insert({
      'item_id': item.id,
      'item_name': item.name,
      'type': 'restock',
      'quantity': qty,
      'unit_price': unitPrice,
      'total_price': unitPrice * qty,
      'notes': notes,
    });
  }

  // ── SELL (Stock Out) ──────────────────────────────────

  Future<String?> sellItem({
    required InventoryItem item,
    required int qty,
    String? notes,
  }) async {
    if (item.quantity < qty) return 'Not enough stock!';

    await _db.from('items').update({
      'quantity': item.quantity - qty,
    }).eq('id', item.id);

    await _db.from('transactions').insert({
      'item_id': item.id,
      'item_name': item.name,
      'type': 'sale',
      'quantity': qty,
      'unit_price': item.sellingPrice,
      'total_price': item.sellingPrice * qty,
      'notes': notes,
    });

    return null; // success
  }

  // ── REPORTS ───────────────────────────────────────────

  Future<List<Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
    String? type,
  }) async {
    var query = _db.from('transactions').select().order('created_at', ascending: false);

    final data = await query;
    List<Transaction> txns = (data as List).map((e) => Transaction.fromMap(e)).toList();

    if (type != null) txns = txns.where((t) => t.type == type).toList();
    if (from != null) txns = txns.where((t) => t.createdAt.isAfter(from)).toList();
    if (to != null) txns = txns.where((t) => t.createdAt.isBefore(to)).toList();

    return txns;
  }

  Future<Map<String, double>> getSalesSummary() async {
    final txns = await getTransactions(type: 'sale');
    final restocks = await getTransactions(type: 'restock');

    double totalRevenue = txns.fold(0, (sum, t) => sum + t.totalPrice);
    double totalCost = restocks.fold(0, (sum, t) => sum + t.totalPrice);

    return {
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalRevenue - totalCost,
    };
  }
}
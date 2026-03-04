import 'package:uuid/uuid.dart';
import 'local_database.dart';
import 'sync_service.dart';
import 'notification_service.dart';
import '../models/inventory_item.dart' as models;

class InventoryService {
  final _sync = SyncService();

  // ── READ (always from local SQLite — instant!) ────────

  Future<List<models.InventoryItem>> getAllItems() =>
      LocalDatabase.getAllItems();

  Future<models.InventoryItem?> getItemByBarcode(String barcode) =>
      LocalDatabase.getItemByBarcode(barcode);

  Future<List<models.InventoryItem>> getLowStockItems() async {
    final all = await getAllItems();
    return all.where((i) => i.isLowStock).toList();
  }

  Future<List<models.Transaction>> getAllTransactions() =>
      LocalDatabase.getAllTransactions();

  Future<Map<String, double>> getSalesSummary() =>
      LocalDatabase.getSalesSummary();

  // ── WRITE (local first, sync to cloud if online) ──────

  Future<void> addItem(models.InventoryItem item) => _sync.saveItem(item);

  Future<void> updateItem(models.InventoryItem item) => _sync.updateItem(item);

  Future<void> deleteItem(String id) => _sync.deleteItem(id);

  Future<void> restockItem({
    required models.InventoryItem item,
    required int qty,
    required double unitPrice,
    String? notes,
  }) async {
    final newQty = item.quantity + qty;
    await _sync.updateItemQuantity(item.id, newQty);

    final txn = models.Transaction(
      id: const Uuid().v4(),
      itemId: item.id,
      itemName: item.name,
      type: 'restock',
      quantity: qty,
      unitPrice: unitPrice,
      totalPrice: unitPrice * qty,
      notes: notes,
      createdAt: DateTime.now(),
      isSynced: false,
    );
    await _sync.saveTransaction(txn);
    await NotificationService().notifyRestock(item.name, qty);
  }

  Future<String?> sellItem({
    required models.InventoryItem item,
    required int qty,
    String? notes,
  }) async {
    if (item.quantity < qty) return 'Not enough stock!';

    final newQty = item.quantity - qty;
    await _sync.updateItemQuantity(item.id, newQty);

    final txn = models.Transaction(
      id: const Uuid().v4(),
      itemId: item.id,
      itemName: item.name,
      type: 'sale',
      quantity: qty,
      unitPrice: item.sellingPrice,
      totalPrice: item.sellingPrice * qty,
      notes: notes,
      createdAt: DateTime.now(),
      isSynced: false,
    );
    await _sync.saveTransaction(txn);
    await NotificationService()
        .notifySale(item.name, qty, item.sellingPrice * qty);
    return null;
  }
}

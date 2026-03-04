import 'package:sqflite/sqflite.dart' as sqflite hide Transaction;
import 'package:path/path.dart';
import '../models/inventory_item.dart';

class LocalDatabase {
  static sqflite.Database? _db;

  static Future<sqflite.Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<sqflite.Database> _initDb() async {
    final path = join(await sqflite.getDatabasesPath(), 'jajo_motorparts.db');
    return await sqflite.openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id TEXT PRIMARY KEY,
            barcode TEXT,
            name TEXT NOT NULL,
            category TEXT,
            motorcycle TEXT,
            buying_price REAL NOT NULL DEFAULT 0,
            selling_price REAL NOT NULL DEFAULT 0,
            quantity INTEGER NOT NULL DEFAULT 0,
            low_stock_threshold INTEGER NOT NULL DEFAULT 5,
            supplier_name TEXT,
            supplier_contact TEXT,
            created_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            item_id TEXT NOT NULL,
            item_name TEXT NOT NULL,
            type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            total_price REAL NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE items ADD COLUMN motorcycle TEXT');
        }
      },
    );
  }

  // ── ITEMS ─────────────────────────────────────────────

  static Future<List<InventoryItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'name ASC');
    return maps.map((m) => InventoryItem.fromSqlite(m)).toList();
  }

  static Future<InventoryItem?> getItemByBarcode(String barcode) async {
    final db = await database;
    final maps =
        await db.query('items', where: 'barcode = ?', whereArgs: [barcode]);
    return maps.isEmpty ? null : InventoryItem.fromSqlite(maps.first);
  }

  static Future<InventoryItem?> getItemById(String id) async {
    final db = await database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : InventoryItem.fromSqlite(maps.first);
  }

  static Future<void> insertItem(InventoryItem item) async {
    final db = await database;
    await db.insert('items', item.toSqlite(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  static Future<void> updateItem(InventoryItem item) async {
    final db = await database;
    await db.update('items', item.toSqlite(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<void> updateItemQuantity(String id, int quantity,
      {bool isSynced = false}) async {
    final db = await database;
    await db.update(
      'items',
      {'quantity': quantity, 'is_synced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<InventoryItem>> getUnsyncedItems() async {
    final db = await database;
    final maps = await db.query('items', where: 'is_synced = 0');
    return maps.map((m) => InventoryItem.fromSqlite(m)).toList();
  }

  static Future<void> markItemSynced(String id) async {
    final db = await database;
    await db.update('items', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── TRANSACTIONS ──────────────────────────────────────

  static Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'created_at DESC');
    return maps.map((m) => Transaction.fromSqlite(m)).toList();
  }

  static Future<void> insertTransaction(Transaction txn) async {
    final db = await database;
    await db.insert('transactions', txn.toSqlite(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  static Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', where: 'is_synced = 0');
    return maps.map((m) => Transaction.fromSqlite(m)).toList();
  }

  static Future<void> markTransactionSynced(String id) async {
    final db = await database;
    await db.update('transactions', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── REPORTS ───────────────────────────────────────────

  static Future<Map<String, double>> getSalesSummary() async {
    final txns = await getAllTransactions();
    final sales = txns.where((t) => t.type == 'sale');
    final restocks = txns.where((t) => t.type == 'restock');
    final revenue = sales.fold(0.0, (sum, t) => sum + t.totalPrice);
    final cost = restocks.fold(0.0, (sum, t) => sum + t.totalPrice);
    return {'revenue': revenue, 'cost': cost, 'profit': revenue - cost};
  }
}

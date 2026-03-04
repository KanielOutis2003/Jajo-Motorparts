class InventoryItem {
  final String id;
  final String? barcode;
  final String name;
  final String? category;
  final String? motorcycle;
  final double buyingPrice;
  final double sellingPrice;
  int quantity;
  final int lowStockThreshold;
  final String? supplierName;
  final String? supplierContact;
  final DateTime createdAt;
  bool isSynced;

  InventoryItem({
    required this.id,
    this.barcode,
    required this.name,
    this.category,
    this.motorcycle,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    this.lowStockThreshold = 5,
    this.supplierName,
    this.supplierContact,
    required this.createdAt,
    this.isSynced = false,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  double get profitMargin => sellingPrice - buyingPrice;

  // From SQLite
  factory InventoryItem.fromSqlite(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      category: map['category'],
      motorcycle: map['motorcycle'],
      buyingPrice: map['buying_price'] as double,
      sellingPrice: map['selling_price'] as double,
      quantity: map['quantity'] as int,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 5,
      supplierName: map['supplier_name'],
      supplierContact: map['supplier_contact'],
      createdAt: DateTime.parse(map['created_at']),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  // To SQLite
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'motorcycle': motorcycle,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // To Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'category': category,
      'motorcycle': motorcycle,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // From Supabase
  factory InventoryItem.fromSupabase(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      category: map['category'],
      buyingPrice: (map['buying_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 5,
      supplierName: map['supplier_name'],
      supplierContact: map['supplier_contact'],
      createdAt: DateTime.parse(map['created_at']),
      isSynced: true,
    );
  }

  InventoryItem copyWith({int? quantity, bool? isSynced}) {
    return InventoryItem(
      id: id,
      barcode: barcode,
      name: name,
      category: category,
      motorcycle: motorcycle,
      buyingPrice: buyingPrice,
      sellingPrice: sellingPrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold,
      supplierName: supplierName,
      supplierContact: supplierContact,
      createdAt: createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class Transaction {
  final String id;
  final String itemId;
  final String itemName;
  final String type; // 'restock' or 'sale'
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  bool isSynced;

  Transaction({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    this.isSynced = false,
  });

  factory Transaction.fromSqlite(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      type: map['type'],
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as double,
      totalPrice: map['total_price'] as double,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'type': type,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'type': type,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromSupabase(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      type: map['type'],
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      isSynced: true,
    );
  }
}

class InventoryItem {
  final String id;
  final String? barcode;
  final String name;
  final String? category;
  final double buyingPrice;
  final double sellingPrice;
  int quantity;
  final int lowStockThreshold;
  final String? supplierName;
  final String? supplierContact;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    this.barcode,
    required this.name,
    this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    this.lowStockThreshold = 5,
    this.supplierName,
    this.supplierContact,
    required this.createdAt,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  double get profitMargin => sellingPrice - buyingPrice;

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'category': category,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'low_stock_threshold': lowStockThreshold,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
    };
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
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
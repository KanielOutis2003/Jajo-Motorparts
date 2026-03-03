import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final InventoryItem? item;
  final String? prefilledBarcode;
  const AddEditItemScreen({super.key, this.item, this.prefilledBarcode});
  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _service = InventoryService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcode, _name, _category,
      _buyPrice, _sellPrice, _qty, _lowThreshold, _supplierName, _supplierContact;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _barcode = TextEditingController(text: i?.barcode ?? widget.prefilledBarcode ?? '');
    _name = TextEditingController(text: i?.name ?? '');
    _category = TextEditingController(text: i?.category ?? '');
    _buyPrice = TextEditingController(text: i?.buyingPrice.toString() ?? '');
    _sellPrice = TextEditingController(text: i?.sellingPrice.toString() ?? '');
    _qty = TextEditingController(text: i?.quantity.toString() ?? '0');
    _lowThreshold = TextEditingController(text: i?.lowStockThreshold.toString() ?? '5');
    _supplierName = TextEditingController(text: i?.supplierName ?? '');
    _supplierContact = TextEditingController(text: i?.supplierContact ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = InventoryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      buyingPrice: double.parse(_buyPrice.text),
      sellingPrice: double.parse(_sellPrice.text),
      quantity: int.parse(_qty.text),
      lowStockThreshold: int.tryParse(_lowThreshold.text) ?? 5,
      supplierName: _supplierName.text.trim().isEmpty ? null : _supplierName.text.trim(),
      supplierContact: _supplierContact.text.trim().isEmpty ? null : _supplierContact.text.trim(),
      createdAt: widget.item?.createdAt ?? DateTime.now(),
    );

    if (widget.item == null) {
      await _service.addItem(item);
    } else {
      await _service.updateItem(item);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add New Item' : 'Edit Item'),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE', style: TextStyle(color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Item Info'),
            _field(_barcode, 'Barcode / QR Code', Icons.qr_code, required: false),
            _field(_name, 'Item Name', Icons.build, required: true),
            _field(_category, 'Category (e.g. Engine, Brake)', Icons.category, required: false),
            const SizedBox(height: 20),
            _section('Pricing'),
            Row(children: [
              Expanded(child: _field(_buyPrice, 'Buying Price', Icons.shopping_cart,
                  required: true, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_sellPrice, 'Selling Price', Icons.sell,
                  required: true, isNumber: true)),
            ]),
            const SizedBox(height: 20),
            _section('Stock'),
            Row(children: [
              Expanded(child: _field(_qty, 'Initial Quantity', Icons.inventory,
                  required: true, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_lowThreshold, 'Low Stock Alert At', Icons.warning,
                  required: false, isNumber: true)),
            ]),
            const SizedBox(height: 20),
            _section('Supplier Info'),
            _field(_supplierName, 'Supplier Name', Icons.person, required: false),
            _field(_supplierContact, 'Supplier Contact', Icons.phone, required: false),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
        style: const TextStyle(color: Color(0xFFE53935),
            fontWeight: FontWeight.bold, fontSize: 13)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
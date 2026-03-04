import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import 'item_detail_screen.dart';

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
  late final TextEditingController _barcode,
      _name,
      _category,
      _motorcycle,
      _buyPrice,
      _sellPrice,
      _qty,
      _lowThreshold,
      _supplierName,
      _supplierContact;
  bool _saving = false;

  String? _suggestCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('oil') || n.contains('lubric')) return 'Lubricants';
    if (n.contains('tire') || n.contains('tube')) return 'Tires';
    if (n.contains('chain') || n.contains('sprocket')) return 'Drive';
    if (n.contains('variator') ||
        n.contains('roller') ||
        n.contains('belt') ||
        n.contains('pulley')) return 'Drive';
    if (n.contains('clutch') || n.contains('lining')) return 'Clutch';
    if (n.contains('torque drive')) return 'Drive';
    if (n.contains('brake') || n.contains('pad') || n.contains('disc'))
      return 'Braking';
    if (n.contains('spark') ||
        n.contains('plug') ||
        n.contains('battery') ||
        n.contains('horn')) return 'Electrical';
    if (n.contains('filter')) return 'Filters';
    if (n.contains('helmet') || n.contains('glove') || n.contains('accessor'))
      return 'Accessories';
    if (n.contains('bolt') || n.contains('nut') || n.contains('screw'))
      return 'Fasteners';
    if (n.contains('engine')) return 'Engine';
    if (n.contains('jvt') ||
        n.contains('uma') ||
        n.contains('daytona') ||
        n.contains('rcb') ||
        n.contains('racingboy')) return 'Performance';
    return null;
  }

  String? _suggestMotorcycle(String name) {
    final n = name.toLowerCase();
    if (n.contains('aerox')) return 'Yamaha Aerox 155';
    if (n.contains('nmax')) return 'Yamaha NMAX 155';
    if (n.contains('mio i') || n.contains('mio 125') || n.contains('mio i125'))
      return 'Yamaha Mio i125';
    if (n.contains('mio sporty')) return 'Yamaha Mio Sporty';
    if (n.contains('sniper 150') || n.contains('sniper 155'))
      return 'Yamaha Sniper';
    if (n.contains('raider 150')) return 'Suzuki Raider 150';
    if (n.contains('smash')) return 'Suzuki Smash 115';
    if (n.contains('click 125')) return 'Honda Click 125';
    if (n.contains('click 150')) return 'Honda Click 150';
    if (n.contains('beat')) return 'Honda Beat 110';
    if (n.contains('wave')) return 'Honda Wave 110';
    if (n.contains('xrm')) return 'Honda XRM 125';
    if (n.contains('tmx')) return 'Honda TMX';
    if (n.contains('pcx')) return 'Honda PCX';
    if (n.contains('adv')) return 'Honda ADV 150';
    if (n.contains('rouser')) return 'Kawasaki Rouser';
    return null;
  }

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _barcode = TextEditingController(
        text: i?.barcode ?? widget.prefilledBarcode ?? '');
    _name = TextEditingController(text: i?.name ?? '');
    _category = TextEditingController(text: i?.category ?? '');
    _motorcycle = TextEditingController(text: i?.motorcycle ?? '');
    _buyPrice = TextEditingController(text: i?.buyingPrice.toString() ?? '');
    _sellPrice = TextEditingController(text: i?.sellingPrice.toString() ?? '');
    _qty = TextEditingController(text: i?.quantity.toString() ?? '0');
    _lowThreshold =
        TextEditingController(text: i?.lowStockThreshold.toString() ?? '5');
    _supplierName = TextEditingController(text: i?.supplierName ?? '');
    _supplierContact = TextEditingController(text: i?.supplierContact ?? '');

    _name.addListener(() {
      final suggestion = _suggestCategory(_name.text);
      if (suggestion != null &&
          (_category.text.isEmpty || _category.text == '')) {
        _category.text = suggestion;
      }
      final m = _suggestMotorcycle(_name.text);
      if (m != null && (_motorcycle.text.isEmpty || _motorcycle.text == '')) {
        _motorcycle.text = m;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = InventoryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      motorcycle:
          _motorcycle.text.trim().isEmpty ? null : _motorcycle.text.trim(),
      buyingPrice: double.parse(_buyPrice.text),
      sellingPrice: double.parse(_sellPrice.text),
      quantity: int.parse(_qty.text),
      lowStockThreshold: int.tryParse(_lowThreshold.text) ?? 5,
      supplierName:
          _supplierName.text.trim().isEmpty ? null : _supplierName.text.trim(),
      supplierContact: _supplierContact.text.trim().isEmpty
          ? null
          : _supplierContact.text.trim(),
      createdAt: widget.item?.createdAt ?? DateTime.now(),
    );

    if (widget.item == null) {
      await _service.addItem(item);
    } else {
      await _service.updateItem(item);
    }

    if (!mounted) return;
    if (widget.item == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add New Item' : 'Edit Item'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.item == null ? 'ADD ITEM' : 'SAVE',
                    style: const TextStyle(
                        color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Item Info'),
            _field(_barcode, 'Barcode / QR Code', Icons.qr_code,
                required: false, capitalize: false),
            _field(_name, 'Item Name', Icons.build,
                required: true, capitalize: true),
            _field(_category, 'Category (e.g. Engine, Brake)', Icons.category,
                required: false, capitalize: true),
            _field(_motorcycle, 'Motorcycle (e.g. Aerox 155, Mio i125)',
                Icons.motorcycle,
                required: false, capitalize: true),
            const SizedBox(height: 20),
            _section('Pricing'),
            Row(children: [
              Expanded(
                  child: _field(_buyPrice, 'Buying Price', Icons.shopping_cart,
                      required: true, isNumber: true, capitalize: false)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_sellPrice, 'Selling Price', Icons.sell,
                      required: true, isNumber: true, capitalize: false)),
            ]),
            const SizedBox(height: 20),
            _section('Stock'),
            Row(children: [
              Expanded(
                  child: _field(_qty, 'Initial Quantity', Icons.inventory,
                      required: true, isNumber: true, capitalize: false)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(
                      _lowThreshold, 'Low Stock Alert At', Icons.warning,
                      required: false, isNumber: true, capitalize: false)),
            ]),
            const SizedBox(height: 20),
            _section('Supplier Info'),
            _field(_supplierName, 'Supplier Name', Icons.person,
                required: false, capitalize: true),
            _field(_supplierContact, 'Supplier Contact', Icons.phone,
                required: false, capitalize: false),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool isNumber = false, bool capitalize = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textCapitalization:
            capitalize ? TextCapitalization.words : TextCapitalization.none,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import 'add_edit_item_screen.dart';
import 'sell_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _service = InventoryService();
  final _controller = MobileScannerController();
  bool _processing = false;
  String _mode = 'restock'; // or 'sell'

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _processing = true);
    _controller.stop();

    final item = await _service.getItemByBarcode(code);

    if (!mounted) return;

    if (item == null) {
      // New item — go to Add screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddEditItemScreen(prefilledBarcode: code)),
      );
      if (result == true) {
        _showSnack('✅ Item added successfully!');
      }
    } else {
      if (_mode == 'sell') {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => SellScreen(item: item)));
      } else {
        await _showRestockDialog(item);
      }
    }

    setState(() => _processing = false);
    _controller.start();
  }

  Future<void> _showRestockDialog(InventoryItem item) async {
    final qtyController = TextEditingController(text: '1');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restock: ${item.name}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Current stock: ${item.quantity}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to add',
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final qty = int.tryParse(qtyController.text) ?? 0;
                  if (qty > 0) {
                    await _service.restockItem(
                        item: item, qty: qty, unitPrice: item.buyingPrice);
                    Navigator.pop(context);
                    _showSnack('✅ Added $qty units to ${item.name}');
                  }
                },
                child: const Text('Confirm Restock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: Color(0xFFE53935)),
                const SizedBox(width: 8),
                const Text('Scanner',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _modeBtn('Restock', 'restock', Colors.green),
                      _modeBtn('Sell', 'sell', const Color(0xFFE53935)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onBarcodeDetected,
                ),
                // Overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE53935), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _mode == 'restock'
                            ? '📦 Scan barcode to restock'
                            : '💰 Scan barcode to sell',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE53935))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, String mode, Color color) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
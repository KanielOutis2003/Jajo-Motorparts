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
  String _mode = 'restock';

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _processing = true);
    _controller.stop();

    final item = await _service.getItemByBarcode(code);

    if (!mounted) return;

    if (item == null) {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddEditItemScreen(prefilledBarcode: code)));
      if (result == true) _showSnack('✅ Item added!', Colors.green);
    } else {
      if (_mode == 'sell') {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => SellScreen(item: item)));
      } else {
        await _showRestockSheet(item);
      }
    }

    setState(() => _processing = false);
    _controller.start();
  }

  Future<void> _showRestockSheet(InventoryItem item) async {
    final qtyCtrl = TextEditingController(text: '1');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
                child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text(item.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text('Current stock: ${item.quantity} units',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity to add',
                prefixIcon: const Icon(Icons.add_box_outlined),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.check),
                label: const Text('Confirm Restock',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty > 0) {
                    await _service.restockItem(
                        item: item, qty: qty, unitPrice: item.buyingPrice);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showSnack(
                        '✅ Added $qty units to ${item.name}', Colors.green);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: Color(0xFFE53935)),
                const SizedBox(width: 8),
                const Text('Scanner',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Mode toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    _modeBtn('📦 Restock', 'restock', Colors.blue),
                    _modeBtn('💰 Sell', 'sell', const Color(0xFFE53935)),
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                // Scan frame overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE53935), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(children: [
                      // Corner accents
                      ..._corners(),
                    ]),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24)),
                      child: Text(
                        _mode == 'restock'
                            ? '📦 Scan to add stock'
                            : '💰 Scan to record sale',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                if (_processing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFE53935))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const color = Color(0xFFE53935);
    const size = 20.0;
    const thick = 3.0;
    return [
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: thick, height: size, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: size, height: thick, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: thick, height: size, color: color)),
    ];
  }

  Widget _modeBtn(String label, String mode, Color color) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }
}

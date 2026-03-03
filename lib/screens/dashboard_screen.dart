import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../models/inventory_screen.dart';
import '../models/scanner_screen.dart';
import '../models/reports_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = InventoryService();
  List<InventoryItem> _allItems = [];
  Map<String, double> _summary = {};
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _allItems = await _service.getAllItems();
    _summary = await _service.getSalesSummary();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _allItems.where((i) => i.isLowStock).toList();
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    final screens = [
      _buildHome(lowStock, currency),
      InventoryScreen(onRefresh: _load),
      const ScannerScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) _load();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        ],
      ),
    );
  }

  Widget _buildHome(List<InventoryItem> lowStock, NumberFormat currency) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFFE53935),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.motorcycle, color: Color(0xFFE53935), size: 32),
                const SizedBox(width: 8),
                Text('Moto Inventory',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Today: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              _statCard('Total Items', '${_allItems.length}', Icons.inventory_2, Colors.blue),
              const SizedBox(width: 12),
              _statCard('Low Stock', '${lowStock.length}', Icons.warning_amber, Colors.orange),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _statCard('Revenue', currency.format(_summary['revenue'] ?? 0),
                  Icons.trending_up, Colors.green),
              const SizedBox(width: 12),
              _statCard('Profit', currency.format(_summary['profit'] ?? 0),
                  Icons.attach_money, const Color(0xFFE53935)),
            ]),

            // Low stock alert
            if (lowStock.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Low Stock Alert (${lowStock.length} items)',
                          style: const TextStyle(
                              color: Colors.orange, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    ...lowStock.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item.name,
                                  style: const TextStyle(color: Colors.white70))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${item.quantity} left',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // Quick action buttons
            const SizedBox(height: 24),
            Text('Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              _quickAction(context, 'Scan & Add Stock', Icons.add_circle_outline,
                  const Color(0xFF1E88E5), () {
                setState(() => _selectedIndex = 2);
              }),
              const SizedBox(width: 12),
              _quickAction(context, 'View All Items', Icons.list_alt_rounded,
                  const Color(0xFF43A047), () {
                setState(() => _selectedIndex = 1);
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
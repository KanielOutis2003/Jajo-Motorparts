import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _service = InventoryService();
  late TabController _tabs;
  List<Transaction> _txns = [];
  Map<String, double> _summary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _txns = await _service.getTransactions();
    _summary = await _service.getSalesSummary();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱');
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFFE53935)),
                const SizedBox(width: 8),
                const Text('Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Summary cards
          if (!_loading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryCard('Revenue', _summary['revenue'] ?? 0, Colors.blue, currency),
                  const SizedBox(width: 8),
                  _summaryCard('Cost', _summary['cost'] ?? 0, Colors.orange, currency),
                  const SizedBox(width: 8),
                  _summaryCard('Profit', _summary['profit'] ?? 0,
                      (_summary['profit'] ?? 0) >= 0 ? Colors.green : Colors.red, currency),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFE53935),
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: 'All'), Tab(text: 'Sales Only')],
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _txnList(_txns, dateFormat, currency),
                      _txnList(
                          _txns.where((t) => t.type == 'sale').toList(),
                          dateFormat,
                          currency),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color, NumberFormat fmt) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(fmt.format(value),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _txnList(List<Transaction> txns, DateFormat dateFmt, NumberFormat currency) {
    if (txns.isEmpty) {
      return const Center(child: Text('No transactions yet',
          style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txns.length,
      itemBuilder: (_, i) {
        final t = txns[i];
        final isSale = t.type == 'sale';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isSale ? Colors.green : Colors.blue).withOpacity(0.2),
              child: Icon(
                isSale ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSale ? Colors.green : Colors.blue,
                size: 18,
              ),
            ),
            title: Text(t.itemName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(dateFmt.format(t.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currency.format(t.totalPrice),
                    style: TextStyle(
                        color: isSale ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold)),
                Text('${isSale ? "-" : "+"}${t.quantity} pcs',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart' as models;
import '../services/inventory_service.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _service = InventoryService();
  late TabController _tabs;
  List<models.Transaction> _txns = [];
  Map<String, double> _summary = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _txns = await _service.getAllTransactions();
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFFE53935)),
                const SizedBox(width: 8),
                const Text('Reports',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  tooltip: 'Export CSV',
                  icon: const Icon(Icons.file_download),
                  onPressed: _exportCsv,
                ),
                IconButton(
                  tooltip: 'Export PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _exportPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          if (!_loading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _summaryCard(
                    'Revenue', _summary['revenue'] ?? 0, Colors.blue, currency),
                const SizedBox(width: 8),
                _summaryCard(
                    'Cost', _summary['cost'] ?? 0, Colors.orange, currency),
                const SizedBox(width: 8),
                _summaryCard(
                    'Profit',
                    _summary['profit'] ?? 0,
                    (_summary['profit'] ?? 0) >= 0 ? Colors.green : Colors.red,
                    currency),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFE53935),
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Sales'),
              Tab(text: 'Restocks'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _txnList(_txns, dateFormat, currency),
                      _txnList(_txns.where((t) => t.type == 'sale').toList(),
                          dateFormat, currency),
                      _txnList(_txns.where((t) => t.type == 'restock').toList(),
                          dateFormat, currency),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, double value, Color color, NumberFormat fmt) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Text(fmt.format(value),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _txnList(List<models.Transaction> txns, DateFormat dateFmt,
      NumberFormat currency) {
    if (txns.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text('No transactions yet', style: TextStyle(color: Colors.grey)),
            ]),
      );
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (isSale ? Colors.green : Colors.blue).withValues(alpha: 0.2),
              child: Icon(
                isSale
                    ? Icons.arrow_circle_up_rounded
                    : Icons.arrow_circle_down_rounded,
                color: isSale ? Colors.green : Colors.blue,
              ),
            ),
            title: Row(children: [
              Expanded(
                  child: Text(t.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              if (!t.isSynced)
                const Icon(Icons.sync_problem, color: Colors.orange, size: 14),
            ]),
            subtitle: Text(dateFmt.format(t.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currency.format(t.totalPrice),
                    style: TextStyle(
                        color: isSale ? Colors.green : Colors.blue,
                        fontWeight: FontWeight.bold)),
                Text('${isSale ? "-" : "+"}${t.quantity} pcs',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final headers = [
      'id',
      'item_id',
      'item_name',
      'type',
      'quantity',
      'unit_price',
      'total_price',
      'created_at'
    ];
    final rows = _txns.map((t) {
      return [
        t.id,
        t.itemId,
        t.itemName,
        t.type,
        t.quantity,
        t.unitPrice,
        t.totalPrice,
        t.createdAt.toIso8601String()
      ].join(',');
    }).toList();
    final csv = '${headers.join(',')}\n${rows.join('\n')}';
    try {
      final dir = await DownloadsPathProvider.downloadsDirectory;
      final path = dir?.path ?? '/storage/emulated/0/Download';
      final file =
          File('$path/reports_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to Downloads: ${file.path}')));
    } catch (_) {}
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Transaction Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Type', 'Qty', 'Unit', 'Total', 'Date'],
                data: _txns
                    .map((t) => [
                          t.itemName,
                          t.type,
                          t.quantity,
                          t.unitPrice.toStringAsFixed(2),
                          t.totalPrice.toStringAsFixed(2),
                          DateFormat('yyyy-MM-dd').format(t.createdAt),
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
    try {
      final dir = await DownloadsPathProvider.downloadsDirectory;
      final path = dir?.path ?? '/storage/emulated/0/Download';
      final file =
          File('$path/reports_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await doc.save());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to Downloads: ${file.path}')));
    } catch (_) {}
  }
}

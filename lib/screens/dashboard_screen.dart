import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sync_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/inventory_service.dart';
import '../models/inventory_item.dart' as models;
import 'inventory_screen.dart' as inv;
import 'reports_screen.dart' as rep;
import 'scanner_screen.dart' as scan;
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  bool _online = true;
  bool _physical = false;
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = SyncService();
    _online = _sync.isOnline;
    _sync.onlineStream.listen((v) {
      if (!mounted) return;
      setState(() => _online = v);
    });
    _detectDevice();
  }

  Future<void> _detectDevice() async {
    final info = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final android = await info.androidInfo;
        if (!mounted) return;
        setState(() => _physical = android.isPhysicalDevice);
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        if (!mounted) return;
        setState(() => _physical = ios.isPhysicalDevice);
      } else {
        setState(() => _physical = false);
      }
    } catch (_) {
      setState(() => _physical = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeDashboardPage(),
      inv.InventoryScreen(onRefresh: () {}),
      const rep.ReportsScreen(),
      const scan.ScannerScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE53935),
              child: SvgPicture.asset(
                'assets/images/jajo_motorparts_icon.svg',
                height: 14,
                width: 14,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Jajo Motorparts'),
          ],
        ),
        actions: [
          if (_physical)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.phone_android, color: Colors.green),
            ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: const Icon(Icons.brightness_6),
            onPressed: () => AppTheme.toggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_online)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Offline mode: changes will sync later')),
                ],
              ),
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        ],
      ),
    );
  }
}

class _HomeDashboardPage extends StatefulWidget {
  const _HomeDashboardPage({super.key});
  @override
  State<_HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<_HomeDashboardPage> {
  final _service = InventoryService();
  List<models.Transaction> _txns = [];
  List<models.InventoryItem> _items = [];
  DateTime _now = DateTime.now();
  DateTime? _selectedDate;
  bool _loading = true;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txns = await _service.getAllTransactions();
    final items = await _service.getAllItems();
    setState(() {
      _txns = txns;
      _items = items;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _calendar(),
          const SizedBox(height: 12),
          _lineChart(),
          const SizedBox(height: 12),
          if (_selectedDate != null) _daySales(),
          if (_selectedDate != null) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Text('No items',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)))
                else
                  ..._items.take(10).map((i) => ListTile(
                        dense: true,
                        leading: Icon(Icons.inventory_2,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(i.name),
                        subtitle: Text(
                            'Qty: ${i.quantity} • Sell: ₱${i.sellingPrice}'),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendar() {
    final firstDay = DateTime(_now.year, _now.month, 1);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = d == _now.day;
      final isSelected =
          _selectedDate?.day == d && _selectedDate?.month == _now.month;
      cells.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = DateTime(_now.year, _now.month, d);
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isToday
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: isToday || isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          child: Center(
            child: Text('$d',
                style: TextStyle(
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                )),
          ),
        ),
      ));
    }
    final time12h = DateFormat('hh:mm:ss a').format(_now);
    final date =
        '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calendar • $date',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              Row(
                children: [
                  Text(time12h,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8))),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _load,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Sun Mon Tue Wed Thu Fri Sat',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 12)),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _lineChart() {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final days = List.generate(14, (i) {
      final d = DateTime(_now.year, _now.month, _now.day)
          .subtract(Duration(days: 13 - i));
      final sum = _txns
          .where((t) => t.type == 'sale')
          .where((t) =>
              t.createdAt.year == d.year &&
              t.createdAt.month == d.month &&
              t.createdAt.day == d.day)
          .fold(0.0, (s, t) => s + t.totalPrice);
      return sum;
    });
    final spots =
        List.generate(days.length, (i) => FlSpot(i.toDouble(), days[i]));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Revenue (14 days)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                backgroundColor: bg,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('D${v.toInt() + 1}',
                            style: TextStyle(color: textColor, fontSize: 10)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primary,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true, color: primary.withValues(alpha: 0.15)),
                    barWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _daySales() {
    final d = _selectedDate!;
    final sales = _txns
        .where((t) => t.type == 'sale')
        .where((t) =>
            t.createdAt.year == d.year &&
            t.createdAt.month == d.month &&
            t.createdAt.day == d.day)
        .toList();
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Sales on ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          if (sales.isEmpty)
            Text('No sales', style: TextStyle(color: muted))
          else
            ...sales.take(6).map((t) => ListTile(
                  dense: true,
                  leading: Icon(Icons.sell,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(t.itemName),
                  trailing: Text('₱${t.totalPrice.toStringAsFixed(0)}'),
                )),
        ],
      ),
    );
  }
}

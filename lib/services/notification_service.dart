import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _show(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'moto_inventory_channel',
      'Moto Inventory',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<void> notifyOnline() => _show('Online', 'Sync will resume');
  Future<void> notifyOffline() => _show('Offline', 'Changes will sync later');
  Future<void> notifySynced() => _show('Synced', 'Pending data synced');
  Future<void> notifySale(String item, int qty, double total) =>
      _show('Sale', '$item • $qty pcs • ₱${total.toStringAsFixed(0)}');
  Future<void> notifyRestock(String item, int qty) =>
      _show('Restock', '$item • +$qty pcs');
}

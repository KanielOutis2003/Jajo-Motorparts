import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database.dart';
import '../models/inventory_item.dart' as models;
import 'notification_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  StreamSubscription? _connectivitySub;
  bool _isOnline = false;
  bool _isSyncing = false;

  // Notifier so UI can react to connectivity changes
  final _onlineController = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _onlineController.stream;
  bool get isOnline => _isOnline;

  // ── INIT ──────────────────────────────────────────────

  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _onlineController.add(_isOnline);

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      _onlineController.add(_isOnline);

      if (!wasOnline && _isOnline) {
        await NotificationService().notifyOnline();
        await syncPendingData();
      } else if (wasOnline && !_isOnline) {
        await NotificationService().notifyOffline();
      }
    });

    if (_isOnline) await syncPendingData();
  }

  void dispose() {
    _connectivitySub?.cancel();
    _onlineController.close();
  }

  // ── SYNC PENDING DATA TO SUPABASE ─────────────────────

  Future<void> syncPendingData() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;

    try {
      await _syncItems();
      await _syncTransactions();
      await NotificationService().notifySynced();
    } catch (e) {
      // Silent fail — will retry next time online
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItems() async {
    final unsynced = await LocalDatabase.getUnsyncedItems();
    for (final item in unsynced) {
      try {
        await _supabase.from('items').upsert(item.toSupabase());
        await LocalDatabase.markItemSynced(item.id);
      } catch (_) {}
    }
  }

  Future<void> _syncTransactions() async {
    final unsynced = await LocalDatabase.getUnsyncedTransactions();
    for (final txn in unsynced) {
      try {
        await _supabase.from('transactions').upsert(txn.toSupabase());
        await LocalDatabase.markTransactionSynced(txn.id);
      } catch (_) {}
    }
  }

  // ── WRITE OPERATIONS (always local first, then cloud if online) ──

  Future<void> saveItem(models.InventoryItem item) async {
    item.isSynced = false;
    await LocalDatabase.insertItem(item);

    if (_isOnline) {
      try {
        await _supabase.from('items').upsert(item.toSupabase());
        await LocalDatabase.markItemSynced(item.id);
      } catch (_) {}
    }
  }

  Future<void> updateItem(models.InventoryItem item) async {
    item.isSynced = false;
    await LocalDatabase.updateItem(item);

    if (_isOnline) {
      try {
        await _supabase.from('items').upsert(item.toSupabase());
        await LocalDatabase.markItemSynced(item.id);
      } catch (_) {}
    }
  }

  Future<void> updateItemQuantity(String id, int newQty) async {
    await LocalDatabase.updateItemQuantity(id, newQty, isSynced: false);

    if (_isOnline) {
      try {
        await _supabase.from('items').update({'quantity': newQty}).eq('id', id);
        await LocalDatabase.markItemSynced(id);
      } catch (_) {}
    }
  }

  Future<void> deleteItem(String id) async {
    await LocalDatabase.deleteItem(id);

    if (_isOnline) {
      try {
        await _supabase.from('items').delete().eq('id', id);
      } catch (_) {}
    }
  }

  Future<void> saveTransaction(models.Transaction txn) async {
    txn.isSynced = false;
    await LocalDatabase.insertTransaction(txn);

    if (_isOnline) {
      try {
        await _supabase.from('transactions').upsert(txn.toSupabase());
        await LocalDatabase.markTransactionSynced(txn.id);
      } catch (_) {}
    }
  }
}

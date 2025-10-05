import 'package:flutter/foundation.dart';
import 'package:trackify/dao/payment_dao.dart';
import 'package:trackify/types/payment_method.dart';

/// Replace usages of your old PaymentStore with this one.
/// API kept identical where possible (load/add/remove/clearAll & getters).
class PaymentStore extends ChangeNotifier {
  static const legacyPrefsKey = 'payment_methods_v1';

  final PaymentDao _dao = PaymentDao();
  final List<PaymentMethod> _items = [];

  List<PaymentMethod> get items => List.unmodifiable(_items);
  List<PaymentMethod> get cards =>
      _items.where((e) => e.type == PaymentType.card).toList();
  List<PaymentMethod> get banks =>
      _items.where((e) => e.type == PaymentType.bank).toList();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Loads from DB. If first run after upgrade, migrates from prefs -> DB.
  Future<void> load({bool allowLegacyMigration = true}) async {
    if (allowLegacyMigration) {
      // Try migrating once (safe even if no prefs data).
      await _dao.migrateFromPrefsOnce(legacyPrefsKey: legacyPrefsKey);
    }
    final all = await _dao.getAll();
    _items
      ..clear()
      ..addAll(all);
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(PaymentMethod m) async {
    await _dao.upsert(m);
    _items.removeWhere((e) => e.id == m.id);
    _items.insert(0, m); // keep newest first
    notifyListeners();
  }

  Future<void> update(PaymentMethod m) async {
    await _dao.upsert(m);
    final index = _items.indexWhere((e) => e.id == m.id);
    if (index != -1) {
      _items[index] = m;
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await _dao.deleteById(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _dao.clearAll();
    _items.clear();
    notifyListeners();
  }
}

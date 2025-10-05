import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackify/services/database_service.dart';
import 'package:trackify/types/payment_method.dart';
import 'package:trackify/utils/payment_helper.dart';

/// Maps your PaymentType enum to DB string.
String _typeToDb(PaymentType t) => t == PaymentType.card ? 'card' : 'bank';
PaymentType _typeFromDb(String v) =>
    v == 'card' ? PaymentType.card : PaymentType.bank;

/// ---- Mappers --------------------------------------------------------------
/// Adjust these to match your PaymentMethod fields if names differ.
/// The below assumes (commonly used):
/// PaymentMethod {
///   String id;
///   PaymentType type; // card | bank
///   String label;     // display name
///   String? brand;
///   String? last4;
///   int? expiryMonth;
///   int? expiryYear;
///   String? holder;
///   String? bankName;
///   String? accountMask;
///   String? ifsc;
///   String? upiId;
/// }
Map<String, Object?> paymentToMap(PaymentMethod m) {
  return {
    'id': m.id,
    'type': _typeToDb(m.type),
    // If your model doesn't have 'label', either remove this line
    // or replace with your property name.
    'label': m.label,
    'brand': m.brand,
    'last4': m.last4,
    'expiry_month': m.expiryMonth,
    'expiry_year': m.expiryYear,
    'holder': m.holder,
    'bank_name': m.bankName,
    'account_mask': m.accountMask,
    'ifsc': m.ifsc,
    'upi_id': m.upiId,
    'variant': m.variant,
    'card_type': m.cardType,
    'card_network': m.cardNetwork,
    // created_at is defaulted by DB
  };
}

PaymentMethod paymentFromMap(Map<String, Object?> row) {
  final typeStr = asString(row['type']) ?? 'card';
  final labelStr = asString(row['label']) ?? fallbackLabel(row);

  return PaymentMethod(
    id: asString(row['id']) ?? '',
    type: _typeFromDb(typeStr),
    // If your model doesn't have 'label' in the ctor, remove this argument
    // or rename to match your actual ctor field.
    label: labelStr,
    brand: asString(row['brand']),
    last4: asString(row['last4']),
    expiryMonth: asInt(row['expiry_month']),
    expiryYear: asInt(row['expiry_year']),
    holder: asString(row['holder']),
    bankName: asString(row['bank_name']),
    accountMask: asString(row['account_mask']),
    ifsc: asString(row['ifsc']),
    upiId: asString(row['upi_id']),
    variant: asInt(row['variant']),
    cardType: asString(row['card_type']),
    cardNetwork: asString(row['card_network']),
  );
}

/// ---- DAO ------------------------------------------------------------------
class PaymentDao {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<PaymentMethod>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'payment_methods',
      orderBy: 'created_at DESC',
    );
    return rows.map(paymentFromMap).toList();
  }

  Future<List<PaymentMethod>> getByType(PaymentType type) async {
    final db = await _db;
    final rows = await db.query(
      'payment_methods',
      where: 'type = ?',
      whereArgs: [_typeToDb(type)],
      orderBy: 'created_at DESC',
    );
    return rows.map(paymentFromMap).toList();
  }

  /// Upsert by primary key id.
  Future<void> upsert(PaymentMethod m) async {
    final db = await _db;
    await db.insert(
      'payment_methods',
      paymentToMap(m),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<PaymentMethod> items) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final m in items) {
        batch.insert(
          'payment_methods',
          paymentToMap(m),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteById(String id) async {
    final db = await _db;
    await db.delete('payment_methods', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('payment_methods');
  }

  /// ---- One-time migration from SharedPreferences blob --------------------
  /// Provide the legacy key used in your PaymentStore.
  Future<int> migrateFromPrefsOnce({
    required String legacyPrefsKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(legacyPrefsKey);
    if (raw == null || raw.isEmpty) return 0;

    // Reuse your existing JSON helpers:
    final items = PaymentMethod.listFromJson(raw);
    if (items.isEmpty) {
      await prefs.remove(legacyPrefsKey);
      return 0;
    }

    await insertMany(items);
    await prefs.remove(legacyPrefsKey);
    return items.length;
  }
}

import 'package:trackify/types/payment_method.dart';

String? asString(Object? v) => v?.toString();

int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String typeToDb(PaymentType t) => t == PaymentType.card ? 'card' : 'bank';
PaymentType typeFromDb(String v) => v == 'card' ? PaymentType.card : PaymentType.bank;

/// Fallback label builder in case your row/DB doesn't carry a label.
/// Tweak to your taste.
String fallbackLabel(Map<String, Object?> row) {
  final type = asString(row['type']) ?? 'card';
  final brand = asString(row['brand']);
  final last4 = asString(row['last4']);
  final bank = asString(row['bank_name']);
  final mask = asString(row['account_mask']);

  if (type == 'card') {
    if (brand != null && last4 != null) return '$brand •••• $last4';
    if (last4 != null) return 'Card •••• $last4';
    return 'Card';
  } else {
    if (bank != null && mask != null) return '$bank $mask';
    if (bank != null) return bank!;
    return 'Bank Account';
  }
}
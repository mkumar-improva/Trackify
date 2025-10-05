import 'dart:convert';

enum PaymentType { card, bank }

extension PaymentTypeSerialize on PaymentType {
  String toDb() => this == PaymentType.card ? 'card' : 'bank';
  static PaymentType fromDb(String v) => v == 'card' ? PaymentType.card : PaymentType.bank;
}

class PaymentMethod {
  final String id;
  final PaymentType type;

  /// Display label for UI, e.g. "VISA •••• 1234" or "HDFC XX4321"
  final String label;

  // ----- Optional card/bank details -----
  final String? brand;        // Visa/Master/HDFC/etc
  final String? last4;        // last 4 digits
  final int? expiryMonth;     // nullable for bank
  final int? expiryYear;      // nullable for bank
  final String? holder;       // cardholder / acc holder
  final String? bankName;     // for bank accounts
  final String? accountMask;  // e.g., XX1234
  final String? ifsc;         // optional
  final String? upiId;        // optional
  final int? variant;     // reserved for future use
  final String? cardType;    // reserved for future use (e.g., credit/debit)
  final String? cardNetwork; // reserved for future use (e.g., Visa/Master/RuPay/etc)

  /// Unnamed constructor (required by DAO mappers)
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.brand,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
    this.holder,
    this.bankName,
    this.accountMask,
    this.ifsc,
    this.upiId,
    this.variant,
    this.cardType,
    this.cardNetwork,
  });

  // ---------- JSON helpers (to support your old SharedPreferences blob) ----------
  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.toDb(),
    'label': label,
    'brand': brand,
    'last4': last4,
    'expiry_month': expiryMonth,
    'expiry_year': expiryYear,
    'holder': holder,
    'bank_name': bankName,
    'account_mask': accountMask,
    'ifsc': ifsc,
    'upi_id': upiId,
    'variant': variant,
    'card_type': cardType,
    'card_network': cardNetwork,
  };

  factory PaymentMethod.fromMap(Map<String, Object?> map) {
    int? asInt(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? asString(Object? v) => v?.toString();

    final typeStr = asString(map['type']) ?? 'card';
    return PaymentMethod(
      id: asString(map['id']) ?? '',
      type: PaymentTypeSerialize.fromDb(typeStr),
      label: asString(map['label']) ??
          _fallbackLabelForMap(map), // build something readable if missing
      brand: asString(map['brand']),
      last4: asString(map['last4']),
      expiryMonth: asInt(map['expiry_month']),
      expiryYear: asInt(map['expiry_year']),
      holder: asString(map['holder']),
      bankName: asString(map['bank_name']),
      accountMask: asString(map['account_mask']),
      ifsc: asString(map['ifsc']),
      upiId: asString(map['upi_id']),
      variant: asInt(map['variant']),
      cardType: asString(map['card_type']),
      cardNetwork: asString(map['card_network']),
    );
  }

  static String _fallbackLabelForMap(Map<String, Object?> row) {
    String? s(Object? v) => v?.toString();
    final type = s(row['type']) ?? 'card';
    if (type == 'card') {
      final brand = s(row['brand']);
      final last4 = s(row['last4']);
      if (brand != null && last4 != null) return '$brand •••• $last4';
      if (last4 != null) return 'Card •••• $last4';
      return 'Card';
    } else {
      final bank = s(row['bank_name']);
      final mask = s(row['account_mask']);
      if (bank != null && mask != null) return '$bank $mask';
      if (bank != null) return bank;
      return 'Bank Account';
    }
  }

  // Old helpers compatibility
  static List<PaymentMethod> listFromJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => PaymentMethod.fromMap(m))
          .toList();
    }
    return const [];
  }

  static String listToJson(List<PaymentMethod> list) {
    final arr = list.map((e) => e.toMap()).toList();
    return jsonEncode(arr);
  }
}

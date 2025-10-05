import 'dart:convert';

enum PaymentType { card, bank }

extension PaymentTypeSerialize on PaymentType {
  String toDb() => this == PaymentType.card ? 'card' : 'bank';
  static PaymentType fromDb(String v) => v == 'card' ? PaymentType.card : PaymentType.bank;
}

class PaymentMethod {
  final String id;
  final PaymentType type;
  final String label;

  // Optional card/bank details
  final String? brand;
  final String? last4;
  final int? expiryMonth;
  final int? expiryYear;
  final String? holder;
  final String? bankName;
  final String? accountMask;
  final String? ifsc;
  final String? upiId;
  final int? variant;
  final String? cardType;
  final String? cardNetwork;

  /// Comma-separated SMS senders in DB
  final String? senders;

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
    this.senders,
  });

  /// Create a modified copy (immutability helper)
  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? label,
    String? brand,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
    String? holder,
    String? bankName,
    String? accountMask,
    String? ifsc,
    String? upiId,
    int? variant,
    String? cardType,
    String? cardNetwork,
    String? senders,
    bool clearSenders = false,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      holder: holder ?? this.holder,
      bankName: bankName ?? this.bankName,
      accountMask: accountMask ?? this.accountMask,
      ifsc: ifsc ?? this.ifsc,
      upiId: upiId ?? this.upiId,
      variant: variant ?? this.variant,
      cardType: cardType ?? this.cardType,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      senders: senders ?? this.senders,
    );
  }

  /// Convert to DB-compatible map
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
    'senders': senders == null ? null : senders // store as comma-separated
  };

  /// Parse from DB map
  factory PaymentMethod.fromMap(Map<String, Object?> map) {
    int? asInt(Object? v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? asString(Object? v) => v?.toString();

    List<String>? parseSenders(Object? raw) {
      if (raw == null) return null;
      final s = raw.toString().trim();
      if (s.isEmpty) return null;
      return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final typeStr = asString(map['type']) ?? 'card';

    return PaymentMethod(
      id: asString(map['id']) ?? '',
      type: PaymentTypeSerialize.fromDb(typeStr),
      label: asString(map['label']) ?? _fallbackLabelForMap(map),
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
      senders: asString(map['senders']),
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

  // ---------- List serialization helpers ----------
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

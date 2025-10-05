String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

String? reqIf(bool required, String? v) {
  if (!required) return null;
  return req(v);
}

String? ifscValidator(String? v) {
  if (req(v) != null) return 'Required';
  final re = RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$');
  if (!re.hasMatch(v!.trim())) return 'Invalid IFSC';
  return null;
}

String? cardNumberValidator(bool required, String? v) {
  if (!required) return null;
  if (req(v) != null) return 'Required';
  final digits = v!.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12) return 'Too short';
  return null;
}

String? expiryValidator(bool required, String? v) {
  if (!required) return null;
  if (req(v) != null) return 'Required';
  final parts = v!.split('/');
  if (parts.length != 2) return 'Use MM/YY';
  final mm = int.tryParse(parts[0]);
  final yy = int.tryParse(parts[1]);
  if (mm == null || yy == null || mm < 1 || mm > 12) return 'Invalid';
  return null;
}

String? cvvValidator(bool required, String? v) {
  if (!required) return null;
  if (req(v) != null) return 'Required';
  if (v!.length < 3) return 'Invalid';
  return null;
}

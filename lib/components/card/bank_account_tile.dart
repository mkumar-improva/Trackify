import 'package:flutter/material.dart';
import 'package:trackify/types/payment_method.dart';

class BankAccountTile extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback? onTap;
  const BankAccountTile({super.key, required this.method, this.onTap});

  /// Accepts masked or raw. If already masked (has X/•), returns as-is.
  /// If raw digits, shows "•••• 1234". If empty, returns "••••".
  String _displayMask(String? maskedOrRaw) {
    if (maskedOrRaw == null || maskedOrRaw.trim().isEmpty) return '••••';
    final s = maskedOrRaw.trim();
    if (RegExp(r'[Xx•]').hasMatch(s)) return s; // already masked
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '••••';
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFFF5F6F8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.account_balance, size: 22),
      ),
      title: Text(method.bankName ?? 'Bank'),
      subtitle: Text(
        '${method.holder ?? 'Account Holder'} · ${_displayMask(method.accountMask)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

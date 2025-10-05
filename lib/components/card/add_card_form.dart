import 'package:flutter/material.dart';
import 'package:trackify/types/payment_method.dart';

class AddCardForm extends StatefulWidget {
  const AddCardForm({super.key});

  @override
  State<AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<AddCardForm> {
  final _form = GlobalKey<FormState>();
  final _holderCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _expiryVal(String? v) {
    if (_req(v) != null) return 'Required';
    final parts = v!.split('/');
    if (parts.length != 2) return 'Use MM/YY';
    final mm = int.tryParse(parts[0]);
    final yy = int.tryParse(parts[1]);
    if (mm == null || yy == null || mm < 1 || mm > 12) return 'Invalid';
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    final holder = _holderCtrl.text.trim();

    // digits-only card number (we DO NOT store this)
    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.isEmpty
        ? ''
        : digits.substring(digits.length - (digits.length >= 4 ? 4 : digits.length));
    final brand = _detectBrand(digits);

    // parse "MM/YY"
    int? month;
    int? year;
    final parts = _expiryCtrl.text.trim().split('/');
    if (parts.length == 2) {
      month = int.tryParse(parts[0]);
      final yy = int.tryParse(parts[1]);
      if (yy != null) {
        year = yy < 100 ? (2000 + yy) : yy;
      }
    }

    // friendly label for lists
    final label = '${brand ?? 'Card'} ${last4.isNotEmpty ? '•••• $last4' : ''}'.trim();

    // Do NOT store full card number or CVV.
    final method = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PaymentType.card,
      label: label,
      brand: brand,
      last4: last4,
      expiryMonth: month,
      expiryYear: year,
      holder: holder,
    );

    Navigator.pop(context, method);
  }

  String? _detectBrand(String digits) {
    if (digits.isEmpty) return null;
    if (RegExp(r'^4').hasMatch(digits)) return 'VISA';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^(34|37)').hasMatch(digits)) return 'Amex';
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return 'Discover';
    if (RegExp(r'^(50|60|65|81|82)').hasMatch(digits)) return 'RuPay';
    if (RegExp(r'^(50|56|57|58)').hasMatch(digits)) return 'Maestro';
    return 'Card';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _holderCtrl,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: (v) {
                if (_req(v) != null) return 'Required';
                final digits = v!.replaceAll(RegExp(r'\s+'), '');
                if (digits.length < 12) return 'Too short';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '08/29',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: _expiryVal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '***',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    validator: (v) {
                      if (_req(v) != null) return 'Required';
                      if (v!.length < 3) return 'Invalid';
                      return null;
                    },
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:trackify/types/payment_method.dart';

class AddBankForm extends StatefulWidget {
  const AddBankForm({super.key});

  @override
  State<AddBankForm> createState() => _AddBankFormState();
}

class _AddBankFormState extends State<AddBankForm> {
  final _form = GlobalKey<FormState>();
  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  /// Mask account number → "XX1234" (stores only masked value)
  String _maskAccount(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), ''); // keep only digits
    if (digits.isEmpty) return 'XX••••';
    final last4 = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    return 'XX$last4';
  }

  void _save() {
    if (!_form.currentState!.validate()) return;

    final bank = _bankCtrl.text.trim();
    final holder = _holderCtrl.text.trim();
    final accMasked = _maskAccount(_accCtrl.text);
    final ifsc = _ifscCtrl.text.trim().toUpperCase();

    final label = bank.isNotEmpty ? '$bank $accMasked' : 'Bank $accMasked';

    final method = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PaymentType.bank,
      label: label,
      bankName: bank,
      accountMask: accMasked,
      holder: holder,
      ifsc: ifsc,
      // upiId: null, brand/last4/expiry* are card-specific, so omitted here
    );

    Navigator.pop(context, method);
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
              controller: _bankCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _holderCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Holder',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: _req,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'IFSC Code',
                hintText: 'HDFC0001234',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: _req,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:trackify/components/primary_button.dart';
import 'package:trackify/types/payment_method.dart';
import 'package:trackify/components/add_payment/bank_section.dart';
import 'package:trackify/components/add_payment/card_preview.dart';
import 'package:trackify/components/add_payment/brand_dropdown.dart';
import 'package:trackify/components/add_payment/color_grid.dart';
import 'package:trackify/components/add_payment/card_details_section.dart';
import 'package:trackify/utils/card_utils.dart';
import 'package:trackify/utils/validators.dart';
import 'package:trackify/types/card_theme.dart';

class AddPaymentForm extends StatefulWidget {
  final PaymentMethod? existing; // if provided → edit mode
  const AddPaymentForm({super.key, this.existing});

  @override
  State<AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<AddPaymentForm> {
  final _form = GlobalKey<FormState>();
  bool _isEdit = false;
  bool isDebitCard = false;

  // Bank fields
  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // Card fields (optional)
  final _cardHolderCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _addCard = false;

  // Brand dropdown
  static const brandOptions = CardBrandOptions.values;
  CardBrandOptions _selectedBrand = CardBrandOptions.auto;

  // theme variant
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existing != null;

    // Live preview updates
    for (final c in [
      _cardHolderCtrl,
      _cardNumberCtrl,
      _expiryCtrl,
      _cvvCtrl,
      _holderCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }

    if (_isEdit) _prefillFromExisting(widget.existing!);
  }

  void _prefillFromExisting(PaymentMethod m) {
    // bank side
    _bankCtrl.text   = m.bankName ?? '';
    _holderCtrl.text = m.holder ?? '';
    // we only ever stored mask/last4; don’t try to guess full account number
    _accCtrl.text    = m.accountMask ?? ''; // leave empty; mask will be regenerated on save
    _ifscCtrl.text   = (m.ifsc ?? '').toUpperCase();

    // ui tweaks
    _selectedColorIndex = m.variant ?? 0;

    // card side
    _addCard = m.type == PaymentType.card || m.brand != null || m.last4 != null;

    isDebitCard = (m.cardType ?? '').toLowerCase() == 'debit';

    // If card present, prefill with safe values we have
    if (_addCard) {
      _cardHolderCtrl.text = (m.holder ?? '').trim();
      if ((m.last4 ?? '').isNotEmpty) {
        // Show masked number so user gets context; extracting digits still yields last4
        _cardNumberCtrl.text = '•••• •••• •••• ${m.last4}';
      }
      if ((m.expiryMonth ?? 0) > 0 && (m.expiryYear ?? 0) > 0) {
        final mm = (m.expiryMonth!).toString().padLeft(2, '0');
        final yy = (m.expiryYear! % 100).toString().padLeft(2, '0');
        _expiryCtrl.text = '$mm/$yy';
      }
      _selectedBrand = _brandStringToOption(m.brand);
    }
  }

  CardBrandOptions _brandStringToOption(String? brand) {
    if (brand == null || brand.isEmpty) return CardBrandOptions.auto;
    final b = brand.toLowerCase();
    if (b.contains('visa')) return CardBrandOptions.visa;
    if (b.contains('master')) return CardBrandOptions.mastercard;
    if (b.contains('amex') || b.contains('american')) return CardBrandOptions.amex;
    if (b.contains('rupay')) return CardBrandOptions.rupay;
    if (b.contains('discover')) return CardBrandOptions.discover;
    if (b.contains('maestro')) return CardBrandOptions.maestro;
    if (b.contains('other')) return CardBrandOptions.other;
    return CardBrandOptions.auto;
  }

  String _optionToBrandString(CardBrandOptions opt, String? fallback) {
    switch (opt) {
      case CardBrandOptions.visa:
        return 'Visa';
      case CardBrandOptions.mastercard:
        return 'Mastercard';
      case CardBrandOptions.amex:
        return 'Amex';
      case CardBrandOptions.rupay:
        return 'RuPay';
      case CardBrandOptions.discover:
        return 'Discover';
      case CardBrandOptions.maestro:
        return 'maestro';
      case CardBrandOptions.other:
        return 'Other';
      case CardBrandOptions.auto:
        return fallback ?? 'Card';
    }
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _cardHolderCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  // -------------------- Save --------------------
  void _save() {
    if (!_form.currentState!.validate()) return;

    final bank = _bankCtrl.text.trim();
    final holder = _holderCtrl.text.trim();
    final accMasked = maskAccount(_accCtrl.text); // regenerates mask from whatever user typed
    final ifsc = _ifscCtrl.text.trim().toUpperCase();

    // Optional card
    String? brand;
    String? last4;
    int? expMonth;
    int? expYear;

    if (_addCard) {
      final digits = _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
      // accept either fresh entry (16 digits) or masked with just last4
      if (digits.isNotEmpty) {
        final len = digits.length;
        last4 = digits.substring(len - (len >= 4 ? 4 : len));
      } else if (_isEdit) {
        // keep existing last4 if user didn’t modify
        last4 = widget.existing?.last4 ?? '';
      }

      // brand: dropdown wins; auto can infer from digits; else fallback to existing
      final inferred = effectiveBrand(
        dropdown: _selectedBrand,
        numberDigits: digits,
      );
      brand = inferred ?? widget.existing?.brand ?? _optionToBrandString(_selectedBrand, null);

      // expiry: parse if provided, else keep existing in edit
      final parts = _expiryCtrl.text.trim().split('/');
      if (parts.length == 2) {
        expMonth = int.tryParse(parts[0]);
        final yy = int.tryParse(parts[1]);
        if (yy != null) expYear = yy < 100 ? (2000 + yy) : yy;
      } else if (_isEdit) {
        expMonth = widget.existing?.expiryMonth;
        expYear = widget.existing?.expiryYear;
      }
    }

    final bankPart = bank.isNotEmpty ? bank : 'Bank';
    final baseLabel = '$bankPart $accMasked';
    final cardBrandLabel = brand ?? widget.existing?.brand ?? 'Card';
    final last4Label = (last4 ?? widget.existing?.last4 ?? '').isNotEmpty ? ' • $cardBrandLabel •••• ${last4 ?? widget.existing?.last4}' : '';
    final label = (_addCard ? (baseLabel + last4Label) : baseLabel).trim();

    final method = PaymentMethod(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _addCard ? PaymentType.card : PaymentType.bank,
      label: label,
      // bank
      bankName: bank,
      holder: holder,
      accountMask: accMasked,
      ifsc: ifsc,
      // card
      brand: _addCard ? brand : null,
      last4: _addCard ? (last4 ?? widget.existing?.last4) : null,
      expiryMonth: _addCard ? (expMonth ?? widget.existing?.expiryMonth) : null,
      expiryYear: _addCard ? (expYear ?? widget.existing?.expiryYear) : null,
      variant: _selectedColorIndex,
      cardType: isDebitCard ? 'debit' : 'credit',
      cardNetwork: (brand ?? widget.existing?.brand)?.toLowerCase(),
    );

    Navigator.pop(context, method);
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final brandForPreview = effectiveBrand(
      dropdown: _selectedBrand,
      numberDigits: _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), ''),
    ) ??
        widget.existing?.brand;

    final colors = colorOptions[_selectedColorIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BankSection(
                  bankCtrl: _bankCtrl,
                  holderCtrl: _holderCtrl,
                  accCtrl: _accCtrl,
                  ifscCtrl: _ifscCtrl,
                  onHolderChanged: () {
                    if (_addCard && _cardHolderCtrl.text.trim().isEmpty) {
                      _cardHolderCtrl.text = _holderCtrl.text.trim();
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                SwitchListTile.adaptive(
                  value: _addCard,
                  onChanged: (v) => setState(() {
                    _addCard = v;
                    if (v && _cardHolderCtrl.text.trim().isEmpty) {
                      _cardHolderCtrl.text = _holderCtrl.text.trim();
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Add card for this bank'),
                  subtitle: const Text(
                    'Store only brand, last4, and expiry — we never store full number or CVV',
                  ),
                ),

                if (_addCard) ...[
                  Text(
                    'Card Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  CardPreview(
                    cardHolder: _cardHolderCtrl.text.trim().isEmpty
                        ? 'Card Holder'
                        : _cardHolderCtrl.text.trim(),
                    cardNumber: _cardNumberCtrl.text.trim().isEmpty
                        ? '•••• •••• •••• ••••'
                        : _cardNumberCtrl.text.trim(),
                    validThru: _expiryCtrl.text.trim().isEmpty
                        ? 'MM/YY'
                        : _expiryCtrl.text.trim(),
                    cvv: _cvvCtrl.text.trim().isEmpty ? '***' : _cvvCtrl.text.trim(),
                    brand: brandForPreview,
                    theme: colors,
                    isDebitCard: isDebitCard,
                  ),
                  const SizedBox(height: 16),
                  ColorGrid(
                    options: colorOptions,
                    selectedIndex: _selectedColorIndex,
                    onChanged: (i) => setState(() => _selectedColorIndex = i),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    title: const Text('Credit / Debit Card Type'),
                    subtitle: Text(isDebitCard ? 'Debit Card' : 'Credit Card'),
                    contentPadding: EdgeInsets.zero,
                    trailing: Switch(
                      value: isDebitCard,
                      onChanged: (bool value) => setState(() => isDebitCard = value),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // While editing, allow empty card number (keep existing last4)
                  CardDetailsSection(
                    cardHolderCtrl: _cardHolderCtrl,
                    cardNumberCtrl: _cardNumberCtrl,
                    expiryCtrl: _expiryCtrl,
                    onAnyChanged: () => setState(() {}),
                    cardHolderValidator: (v) => reqIf(_addCard, v),
                    cardNumberValidator: (v) =>
                    // Don’t force number re-entry in edit mode:
                    _isEdit ? null : cardNumberValidator(_addCard, v),
                    expiryValidator: (v) => expiryValidator(_addCard, v),
                    cvvValidator: (v) => cvvValidator(_addCard, v),
                  ),
                  const SizedBox(height: 22),

                  BrandDropdown(
                    value: _selectedBrand,
                    onChanged: (v) => setState(() => _selectedBrand = v),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: PrimaryButton(
          onPressed: _save,
          text: _isEdit ? 'Update' : 'Save',
        ),
      ),
    );
  }
}

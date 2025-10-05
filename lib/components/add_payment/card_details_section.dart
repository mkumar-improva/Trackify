import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackify/utils/card_input_formatters.dart';

class CardDetailsSection extends StatelessWidget {
  final TextEditingController cardHolderCtrl;
  final TextEditingController cardNumberCtrl;
  final TextEditingController expiryCtrl;

  final VoidCallback? onAnyChanged;

  final String? Function(String?) cardHolderValidator;
  final String? Function(String?) cardNumberValidator;
  final String? Function(String?) expiryValidator;
  final String? Function(String?) cvvValidator;

  const CardDetailsSection({
    super.key,
    required this.cardHolderCtrl,
    required this.cardNumberCtrl,
    required this.expiryCtrl,
    required this.cardHolderValidator,
    required this.cardNumberValidator,
    required this.expiryValidator,
    required this.cvvValidator,
    this.onAnyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: cardHolderCtrl,
          decoration: const InputDecoration(
            labelText: 'Cardholder Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: cardHolderValidator,
          onChanged: (_) => onAnyChanged?.call(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cardNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CardNumberInputFormatter(),
          ],
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: cardNumberValidator,
          onChanged: (_) => onAnyChanged?.call(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: expiryCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ExpiryInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  hintText: '08/29',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: expiryValidator,
                onChanged: (_) => onAnyChanged?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:trackify/utils/validators.dart';

class BankSection extends StatelessWidget {
  final TextEditingController bankCtrl;
  final TextEditingController holderCtrl;
  final TextEditingController accCtrl;
  final TextEditingController ifscCtrl;
  final VoidCallback? onHolderChanged;

  const BankSection({
    super.key,
    required this.bankCtrl,
    required this.holderCtrl,
    required this.accCtrl,
    required this.ifscCtrl,
    this.onHolderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: bankCtrl,
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: req,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: holderCtrl,
          decoration: const InputDecoration(
            labelText: 'Account Holder',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: req,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onHolderChanged?.call(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: accCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Account Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: req,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: ifscCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'IFSC Code',
            hintText: 'HDFC0001234',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          validator: ifscValidator,
        ),
      ],
    );
  }
}

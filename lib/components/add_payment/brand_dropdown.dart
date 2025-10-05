import 'package:flutter/material.dart';
import 'package:trackify/utils/card_utils.dart';

class BrandDropdown extends StatelessWidget {
  final CardBrandOptions value;
  final ValueChanged<CardBrandOptions> onChanged;

  const BrandDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CardBrandOptions>(
      value: value,
      items: CardBrandOptions.values
          .map((b) => DropdownMenuItem(
        value: b,
        child: Text(b.label),
      ))
          .toList(),
      onChanged: (v) => onChanged(v ?? CardBrandOptions.auto),
      decoration: const InputDecoration(
        labelText: 'Card Brand',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}

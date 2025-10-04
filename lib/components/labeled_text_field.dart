import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator; // ✅ Added validator support
  final bool? obscureText; // optional for password reuse

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText ?? false,
          validator: validator, // ✅ Validation linked here
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

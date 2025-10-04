import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator; // ✅ added validator

  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.validator,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          validator: widget.validator, // ✅ Validation support
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

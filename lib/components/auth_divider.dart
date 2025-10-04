import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String text;
  const AuthDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black54)),
        ),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

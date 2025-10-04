import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(minHeight: 3, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Text('Kubo is typing…', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

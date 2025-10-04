import 'package:flutter/material.dart';

class RefreshFab extends StatelessWidget {
  final VoidCallback onPressed;
  const RefreshFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.refresh),
      label: const Text('Refresh'),
    );
  }
}

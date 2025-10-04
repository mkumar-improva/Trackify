import 'package:flutter/material.dart';
import 'package:trackify/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple badge that won’t break if you don’t have assets yet.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Image.asset("assets/images/piggy_bank.png"),
    );
}
}

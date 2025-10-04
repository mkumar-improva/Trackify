import 'package:flutter/material.dart';
import 'package:trackify/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // match height with social btn
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // same radius as social login
          ),
          backgroundColor: AppTheme.colorSchemeLight.primary, // neon yellow-green like mock
          foregroundColor: Colors.white, // black text
          elevation: 0, // flat style
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

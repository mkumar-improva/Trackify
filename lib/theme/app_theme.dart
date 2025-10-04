import 'package:flutter/material.dart';

class AppTheme {
  // Colors tuned to the mock (neon button + purple link)
  static const Color neonLime = Color(0xFF5F935A);
  static const Color linkPurple = Color(0xFF5B5BF7);
  static const Color fieldFill = Color(0xFFF7F7F9);

  static const _primary = Color(0xFF5F935A);

  static const colorSchemeLight = ColorScheme.light(
    primary: _primary,
    surface: Colors.white,
  );

  static const inputDecoration = InputDecorationTheme(
    filled: true,
    fillColor: fieldFill,
    hintStyle: TextStyle(color: Color(0xFF5F935A)),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Colors.black12),
    ),
  );

  static final elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: neonLime,
      foregroundColor: Colors.black,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      elevation: 0,
    ),
  );
}

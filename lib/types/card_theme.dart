import 'package:flutter/material.dart';

class CardThemeColors {
  final Color topLeft;
  final Color bottomRight;
  const CardThemeColors(this.topLeft, this.bottomRight);
}

// add more color options
const List<CardThemeColors> colorOptions = [
  CardThemeColors(Color(0xFF3B87FE), Color(0xFF9B18F1)), // blue → purple
  CardThemeColors(Color(0xFF0EA5E9), Color(0xFF22C55E)), // sky → green
  CardThemeColors(Color(0xFFEF4444), Color(0xFFF97316)), // red → orange
  CardThemeColors(Color(0xFF8B5CF6), Color(0xFF06B6D4)), // violet → cyan
  CardThemeColors(Color(0xFF111827), Color(0xFF4B5563)), // slate darks
  CardThemeColors(Color(0xFFFF5F6D), Color(0xFFFFC371)), // coral → peach
  CardThemeColors(Color(0xFF14B8A6), Color(0xFF84CC16)), // teal → lime
  CardThemeColors(Color(0xFF1D4ED8), Color(0xFF10B981)), // indigo → emerald)
];

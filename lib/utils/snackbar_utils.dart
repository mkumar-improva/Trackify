import 'package:flutter/material.dart';

class Snackbars {
  static const Duration defaultDuration = Duration(seconds: 2);

  static void showFloating(ScaffoldMessengerState messenger, String text,
      {Duration duration = defaultDuration}) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

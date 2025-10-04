import 'package:flutter/material.dart';
import 'snackbar_utils.dart';

mixin BackExitHelper {
  DateTime? _lastBackPressedAt;
  static const Duration _exitInterval = Duration(seconds: 2);

  Future<bool> handleBackPress(
      BuildContext context, {
        String message = 'Press back again to exit',
      }) async {
    final now = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > _exitInterval) {
      _lastBackPressedAt = now;
      Snackbars.showFloating(messenger, message, duration: _exitInterval);
      return false;
    }

    messenger.hideCurrentSnackBar();
    return true;
  }
}

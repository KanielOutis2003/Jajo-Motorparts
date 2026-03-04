import 'package:flutter/material.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static void toggle() {
    notifier.value =
        notifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

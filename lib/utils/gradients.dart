import 'package:flutter/material.dart';

class AppGradients {
  static Gradient primaryLight = const LinearGradient(
    colors: [Color(0xFFFF6A6A), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient primaryDark = const LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFF5E35B1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static double padding(BuildContext context) =>
      isTablet(context) ? 32.0 : 16.0;

  static double fontSize(BuildContext context, double base) =>
      isTablet(context) ? base * 1.3 : base;
}

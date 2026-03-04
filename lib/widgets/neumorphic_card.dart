import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const NeumorphicCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade400).withOpacity(0.6),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: (isDark ? Colors.white10 : Colors.white).withOpacity(isDark ? 0.08 : 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}

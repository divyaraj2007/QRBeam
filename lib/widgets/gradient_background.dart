import 'package:flutter/material.dart';

/// Full-screen gradient backdrop used by every screen.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? const [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)]
        : const [Color(0xFFE8E4FF), Color(0xFFF5F7FF), Color(0xFFDDF6FF)];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}

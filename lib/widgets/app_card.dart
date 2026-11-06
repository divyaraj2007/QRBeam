import 'package:flutter/material.dart';

/// Rounded, subtly bordered card used for grouped content.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surface.withValues(alpha: 0.6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}

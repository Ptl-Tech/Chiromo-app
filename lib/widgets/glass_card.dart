import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glass‑morphism card.
///
/// This widget applies a blur effect to the background and a semi‑transparent
/// surface with optional border radius and elevation. Use it wherever a
/// Material [Card] would be appropriate but you want a modern glass look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? color;
  final double elevation;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 12.0,
    this.color,
    this.elevation = 0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = color ?? Colors.white.withValues(alpha: 0.2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: elevation,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

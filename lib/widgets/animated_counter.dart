import 'package:flutter/material.dart';

/// A simple animated counter widget that smoothly animates from 0 to the
/// provided [value] using a [TweenAnimationBuilder].
///
/// The widget is deliberately lightweight and only depends on Flutter's core
/// libraries. It can be used anywhere a numeric value should be displayed with
/// a subtle counting animation – for example in health metric cards.
class AnimatedCounter extends StatelessWidget {
  /// The target value to animate to. It is expected to be a non‑negative
  /// integer; the widget will animate from 0 up to this value.
  final int value;

  /// Optional text style applied to the displayed number. If omitted the
  /// default [DefaultTextStyle] of the surrounding context is used.
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    // Use a short but noticeable duration. The curve gives a natural ease‑out.
    const duration = Duration(seconds: 2);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$animatedValue',
          style: style ?? DefaultTextStyle.of(context).style,
        );
      },
    );
  }
}

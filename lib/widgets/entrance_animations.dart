import 'package:flutter/material.dart';

/// Entrance animations ported from the Expo prototype's Progress screen.
///
/// The prototype used Reanimated: `FadeInDown.duration(500).delay(n)` on each
/// block, and `withDelay(n, withSpring(1))` on the streak flame and the weekly
/// activity dots. Both are expressible with plain [TweenAnimationBuilder], so
/// nothing is added to pubspec for this.
///
/// Every animation here checks [MediaQuery.disableAnimationsOf] and renders
/// its child immediately when the platform asks for reduced motion. That is
/// worth honouring anywhere, and more so on a screen a patient may be opening
/// while anxious — motion sensitivity and anxiety overlap, and this is the one
/// screen whose whole job is to feel calm to look at.

/// How long a single block takes to fade and rise, once its turn comes.
const Duration _kEntranceDuration = Duration(milliseconds: 460);

/// Gap between one block starting and the next.
const Duration _kStaggerStep = Duration(milliseconds: 90);

/// Fade in while rising a little, starting after [index] steps.
///
/// The delay is real: the whole cascade shares one duration and each child gets
/// an [Interval] that holds it at its start value until its turn. An earlier
/// attempt at this stretched the *duration* per index instead, which is a
/// different effect — everything starts together and later items simply move
/// more slowly, so the sequence never reads as a sequence.
class StaggerIn extends StatelessWidget {
  /// Position in the cascade, from zero. Blocks on one screen should number
  /// consecutively, including across widget boundaries.
  final int index;

  final Widget child;

  const StaggerIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final delay = _kStaggerStep * index;
    final total = delay + _kEntranceDuration;
    final start = delay.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Scale up from nothing with a single overshoot, after [delay].
///
/// Stands in for the prototype's `withSpring`. [Curves.elasticOut] is the
/// closer literal translation but oscillates several times; on seven activity
/// dots in a row that reads as a toy. One overshoot keeps the liveliness and
/// settles.
class PopIn extends StatelessWidget {
  final Duration delay;
  final Widget child;

  const PopIn({super.key, this.delay = Duration.zero, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    const pop = Duration(milliseconds: 420);
    final total = delay + pop;
    final start = delay.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Transform.scale(
        // easeOutBack undershoots below zero on the way in; a negative scale
        // would mirror the child for a frame.
        scale: t.clamp(0, double.infinity),
        child: child,
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../providers/wellbeing_stats_provider.dart';

/// The summary tiles from the Expo prototype's Progress screen, rebuilt on the
/// Business-Central-backed check-in data: a streak card and average mood side
/// by side, then sleep, anxiety and check-in count in a row beneath.
///
/// The staggered entrance is done with plain [TweenAnimationBuilder] rather
/// than a package — Reanimated's `FadeInDown.delay(n)` is a fade plus a short
/// upward slide, which Flutter does natively.
///
/// Every tile shows a dash rather than a zero when nothing was recorded. "You
/// have not logged sleep this week" and "you slept zero hours" are different
/// statements, and only the first one is true.
class WellbeingStatCards extends ConsumerWidget {
  const WellbeingStatCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(wellbeingStatsProvider);

    return stats.maybeWhen(
      data: (data) {
        if (!data.hasData) return const SizedBox.shrink();

        return Column(
          children: [
            _Stagger(
              index: 0,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _StreakCard(streak: data.dayStreak),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _MoodHeroCard(
                        average: data.averageMood,
                        trendPercent: data.moodTrendPercent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Stagger(
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    child: _PillCard(
                      icon: Icons.nightlight_round,
                      tint: ChiromoColors.info,
                      value: _oneDecimal(data.averageSleepHours),
                      suffix: 'h',
                      label: 'Sleep Avg',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillCard(
                      icon: Icons.monitor_heart_outlined,
                      tint: ChiromoColors.crimson,
                      value: _whole(data.averageAnxiety),
                      suffix: '/10',
                      label: 'Anxiety',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillCard(
                      icon: Icons.event_available_outlined,
                      tint: ChiromoColors.gold,
                      value: '${data.checkinCount}',
                      suffix: '',
                      label: 'Check-ins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Stagger(index: 2, child: _WeekStrip(activity: data.weekActivity)),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Fade-and-rise, delayed by position. The Flutter equivalent of the
/// prototype's `FadeInDown.duration(500).delay(index * 100)`.
class _Stagger extends StatelessWidget {
  final int index;
  final Widget child;

  const _Stagger({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 120)),
      curve: Curves.easeOutCubic,
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

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: ChiromoColors.primarySurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: ChiromoColors.warning,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
              color: ChiromoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'day streak',
            style: TextStyle(fontSize: 12, color: ChiromoColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MoodHeroCard extends StatelessWidget {
  final double? average;
  final double? trendPercent;

  const _MoodHeroCard({required this.average, required this.trendPercent});

  @override
  Widget build(BuildContext context) {
    final trend = trendPercent;
    final rising = (trend ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: ChiromoColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sentiment_satisfied_alt,
                  size: 19,
                  color: ChiromoColors.primary,
                ),
              ),
              const Spacer(),
              // Only drawn when there is an earlier week to compare against.
              // A first week has no trend, and showing 0% would read as "no
              // change" rather than "no comparison".
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rising
                        ? ChiromoColors.successLight
                        : ChiromoColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rising ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 11,
                        color: rising
                            ? ChiromoColors.statusCompleted
                            : ChiromoColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trend.abs().round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rising
                              ? ChiromoColors.statusCompleted
                              : ChiromoColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _whole(average),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: ChiromoColors.textPrimary,
                ),
              ),
              const Text(
                '/10',
                style: TextStyle(
                  fontSize: 13,
                  color: ChiromoColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Avg Mood',
            style: TextStyle(fontSize: 12, color: ChiromoColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PillCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String value;
  final String suffix;
  final String label;

  const _PillCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.suffix,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ChiromoColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ChiromoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The prototype's weekly heatmap, reduced to a checked / not-checked strip.
///
/// The original graded each day by activity level; there is no honest way to
/// grade a check-in, so this only says whether one happened. A fabricated
/// intensity would look like data.
class _WeekStrip extends StatelessWidget {
  final List<int> activity;

  const _WeekStrip({required this.activity});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ChiromoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: activity[i] > 0
                            ? ChiromoColors.primary
                            : ChiromoColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[i],
                      style: const TextStyle(
                        fontSize: 11,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _whole(double? value) => value == null ? '—' : value.round().toString();

String _oneDecimal(double? value) =>
    value == null ? '—' : value.toStringAsFixed(1);

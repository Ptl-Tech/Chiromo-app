import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/entrance_animations.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../appointments/data/models/app_appointment_model.dart';
import '../../../appointments/presentation/providers/app_appointment_providers.dart';
import '../providers/activity_providers.dart';
import '../providers/checkin_providers.dart';
import '../providers/insights_provider.dart';
import '../providers/thought_providers.dart';
import '../widgets/wellbeing_stat_cards.dart';

/// The patient's health hub: how they have been doing, what they are taking,
/// and what the clinic has written for them.
///
/// This absorbed the separate Analytics tab. Mood trends are health data, and
/// splitting them across two destinations meant two half screens and a choice
/// nobody wanted to make.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'My Health',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(checkinHistoryProvider);
          ref.invalidate(sleepLogsProvider);
          // The insights read these two as well, so a pull that left them
          // stale would refresh the charts and not the conclusions drawn
          // from them.
          ref.invalidate(thoughtRecordsProvider);
          ref.invalidate(activityPlansProvider);
        },
        // One cascade down the whole screen. The stat cards contribute three
        // steps of their own from index 1, so the blocks after them resume at
        // 4 — the numbering is continuous even though it crosses a widget
        // boundary, which is what keeps it reading as a single sequence.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            StaggerIn(
              index: 0,
              child: _Heading(
                title: 'Your Progress',
                subtitle: 'Visualising your mental health journey',
              ),
            ),
            SizedBox(height: 16),
            WellbeingStatCards(baseIndex: 1),
            SizedBox(height: 20),
            StaggerIn(index: 4, child: _MoodTrendCard()),
            SizedBox(height: 20),
            StaggerIn(index: 5, child: _InsightsCard()),
            StaggerIn(index: 6, child: _RecordsRows()),
            SizedBox(height: 20),
            StaggerIn(index: 7, child: _CareTeam()),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Heading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: ChiromoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: ChiromoColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Mood over the check-ins the patient has actually recorded.
///
/// Gaps are gaps: a day with no check-in is simply absent rather than plotted
/// as zero, which would draw a crash that never happened.
class _MoodTrendCard extends ConsumerWidget {
  const _MoodTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(moodTrendProvider);

    return trend.maybeWhen(
      data: (points) {
        // Two points is the minimum that makes a line mean anything. One
        // reading drawn as a trend implies a direction it cannot show.
        if (points.length < 2) return const SizedBox.shrink();

        final recent = points.length > 14
            ? points.sublist(points.length - 14)
            : points;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: ChiromoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ChiromoColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ChiromoColors.textPrimary,
                ),
              ),
              Text(
                'Your last ${recent.length} check-ins',
                style: const TextStyle(
                  fontSize: 12,
                  color: ChiromoColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 10,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: ChiromoColors.divider,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(),
                      bottomTitles: AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          reservedSize: 26,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < recent.length; i++)
                            FlSpot(i.toDouble(), recent[i].value.toDouble()),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.28,
                        color: ChiromoColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: ChiromoColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Patterns computed from the patient's own entries.
///
/// The card is absent, rather than empty or apologetic, until something clears
/// the thresholds in [insightsProvider]. A "no insights yet" panel would take
/// up the same room while telling the patient they have not done enough.
class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(insightsProvider)
        .maybeWhen(
          data: (insights) {
            if (insights.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                decoration: BoxDecoration(
                  color: ChiromoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ChiromoColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What we can see so far',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < insights.length; i++)
                      _InsightRow(insight: insights[i], index: i),
                    const SizedBox(height: 4),
                    // Said plainly, because everything above is a pattern in
                    // the patient's own entries and none of it is a cause.
                    const Text(
                      'Patterns in your own entries, not conclusions. Your '
                      'clinician is the one to read them with.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: ChiromoColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _InsightRow extends StatelessWidget {
  final Insight insight;
  final int index;

  const _InsightRow({required this.insight, required this.index});

  @override
  Widget build(BuildContext context) {
    final tint = insight.favourable
        ? ChiromoColors.statusCompleted
        : ChiromoColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopIn(
            delay: Duration(milliseconds: 520 + (index * 90)),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), size: 15, color: tint),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                // The sample size sits with the claim rather than in a
                // footnote. A pattern over six days and one over sixty read
                // the same otherwise, and they are not the same.
                Text(
                  'Based on ${insight.basis}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (insight.kind) {
      case InsightKind.activitySurprise:
        return Icons.emoji_objects_outlined;
      case InsightKind.thoughtRecordDistress:
        return Icons.psychology_outlined;
      // The only one whose arrow has to follow the finding. A rising arrow
      // over "your mood is 9% lower" is the card contradicting itself.
      case InsightKind.moodTrend:
        return insight.favourable ? Icons.trending_up : Icons.trending_down;
      case InsightKind.thoughtRecordDays:
        return Icons.event_note_outlined;
      case InsightKind.sleepAndMood:
        return Icons.bedtime_outlined;
    }
  }
}

/// Ways into what the clinic has recorded. Both land on My Records, which is
/// the single home for it — these are doors, not separate destinations.
class _RecordsRows extends StatelessWidget {
  const _RecordsRows();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChiromoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
      ),
      child: Column(
        children: [
          _NavRow(
            icon: Icons.medication_outlined,
            title: 'Medications',
            subtitle: 'What your doctor has you taking',
            onTap: () => context.push('/patient/records?tab=0'),
          ),
          const Divider(height: 1, indent: 60, color: ChiromoColors.divider),
          _NavRow(
            icon: Icons.description_outlined,
            title: 'Notes from your visits',
            subtitle: 'What your doctor wrote for you',
            onTap: () => context.push('/patient/records?tab=1'),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ChiromoColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: ChiromoColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ChiromoColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: ChiromoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// The doctors this patient has actually been booked with, taken from their
/// own appointments rather than a directory.
class _CareTeam extends ConsumerWidget {
  const _CareTeam();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appAppointmentsProvider);

    return appointments.maybeWhen(
      data: (items) {
        final byId = <String, AppAppointment>{};
        for (final appointment in items) {
          if (appointment.doctorId.isEmpty) continue;
          byId.putIfAbsent(appointment.doctorId, () => appointment);
        }
        if (byId.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My care team',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (final appointment in byId.values)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChiromoColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ChiromoColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ChiromoColors.primarySurface,
                      child: Text(
                        appointment.doctorName.isEmpty
                            ? '?'
                            : appointment.doctorName.characters.first
                                  .toUpperCase(),
                        style: const TextStyle(
                          color: ChiromoColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appointment.doctorName.isEmpty
                            ? 'Your doctor'
                            : appointment.doctorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ChiromoColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

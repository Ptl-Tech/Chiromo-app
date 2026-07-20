import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../../presentation/providers/cbt_providers.dart';
import '../widgets/patient_dashboard_widgets.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/loading/shimmer_loading.dart';
import 'package:chiromo/widgets/error/error_retry_widget.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final theme = Theme.of(context);
    final recentProgress = ref.watch(cbtRecentProgressProvider);
    
    String dayStreak = '-';
    String avgMood = '-';
    final bool hasSubmittedMoodToday = recentProgress.when(
      data: (exercises) {
        final checkins = exercises
            .where((e) => e.type == CbtExerciseType.dailyCheckin && e.mood != null)
            .toList();
        if (checkins.isNotEmpty) {
          // Compute stats
          final sum = checkins.fold<int>(0, (prev, e) => prev + (e.mood ?? 0));
          avgMood = '${(sum / checkins.length).toStringAsFixed(1)}/10';
          dayStreak = checkins.length.toString();
          // Ensure checkins are sorted by date to get the most recent entry
          checkins.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final lastCheckin = checkins.last;
          final now = DateTime.now();
          return lastCheckin.createdAt.year == now.year &&
              lastCheckin.createdAt.month == now.month &&
              lastCheckin.createdAt.day == now.day;
        }
        return false;
      },
      loading: () => false,
      error: (_, __) => false,
    );

    return AppScaffold(
      title: 'Patient Portal',
      showBack: false,
      showAppBar: false,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header (Does not scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!) as ImageProvider
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            (user?.fullName ?? 'P')
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.fullName ?? 'Patient',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: ChiromoColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasSubmittedMoodToday) ...[
              // Mood selector card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling today?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start your day with a moment of awareness.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        MoodButton(label: 'Awful', emoji: '😞', onTap: () => _saveMood(context, ref, 2, user?.id)),
                        MoodButton(label: 'Bad', emoji: '😕', onTap: () => _saveMood(context, ref, 4, user?.id)),
                        MoodButton(label: 'Okay', emoji: '😐', onTap: () => _saveMood(context, ref, 6, user?.id)),
                        MoodButton(label: 'Good', emoji: '🙂', onTap: () => _saveMood(context, ref, 8, user?.id)),
                        MoodButton(label: 'Great', emoji: '😁', onTap: () => _saveMood(context, ref, 10, user?.id)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Appointment / Session tabs
            const AppointmentTabs(),

            const SizedBox(height: 14),

            // Quick actions grid
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                QuickActionCard(
                  icon: Icons.calendar_month,
                  title: 'Book Appointment',
                  subtitle: 'Schedule a session',
                  imagePath: 'assets/images/quick_actions/find_doctor.png',
                  onTap: () => context.push('/patient/book'),
                ),
                QuickActionCard(
                  icon: Icons.edit,
                  title: 'Record a thought',
                  subtitle: 'Challenge a negative thought',
                  imagePath: 'assets/images/quick_actions/record_thought.png',
                  onTap: () => context.push('/patient/cbt/thought-record'),
                ),
                QuickActionCard(
                  icon: Icons.directions_walk,
                  title: 'Log Activity',
                  subtitle: 'Track your behavior activation',
                  imagePath: 'assets/images/quick_actions/log_activity.png',
                  onTap: () => context.push('/patient/cbt/behavioral-activation'),
                ),
                QuickActionCard(
                  icon: Icons.bar_chart,
                  title: "CBT Tools",
                  subtitle: 'View your progress',
                  imagePath: 'assets/images/quick_actions/cbt_tools.png',
                  onTap: () => context.push('/patient/cbt'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Progress summary (simple visual placeholders)
            Text(
              'Your Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SmallStat(title: dayStreak, subtitle: 'check-ins'),
                const SizedBox(width: 12),
                Expanded(
                  child: SmallStat(title: avgMood, subtitle: 'Avg Mood'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mood chart wired to recent CBT daily check-ins
            ref
                .watch(cbtRecentProgressProvider)
                .when(
                  loading: () => const ShimmerCard(height: 140),
                  error: (e, st) => ErrorRetryWidget(
                    message: 'Failed to load mood chart',
                    onRetry: () => ref.invalidate(cbtRecentProgressProvider),
                  ),
                  data: (exercises) {
                    final checkins =
                        exercises
                            .where(
                              (e) =>
                                  e.type == CbtExerciseType.dailyCheckin &&
                                  (e.mood != null),
                            )
                            .toList()
                          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                    if (checkins.isEmpty) {
                      return Container(
                        height: 140,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'No mood data yet.\nCheck-in to start tracking!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      );
                    }

                    // take last 7 values
                    final recentCheckins = checkins.reversed.take(7).toList().reversed.toList();
                    final chartData = recentCheckins.map((e) => _ChartDataPoint(
                      date: e.createdAt,
                      mood: (e.mood ?? 0).clamp(0, 10).toInt(),
                    )).toList();

                    return _MoodChart(data: chartData);
                  },
                ),
            const SizedBox(height: 24),
                  ],
                ), // Column
              ), // SingleChildScrollView
            ), // Expanded
          ], // children
        ), // Column
      ), // SafeArea
    ); // AppScaffold
  }

  void _saveMood(BuildContext context, WidgetRef ref, int score, String? patientId) async {
    if (patientId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cbtRepositoryProvider).createExercise(
            CbtExerciseEntity(
              id: '',
              patientId: patientId,
              type: CbtExerciseType.dailyCheckin,
              data: {'mood': score},
              isShared: false,
              hasDoctorFeedback: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Mood saved successfully!')),
      );
      ref.invalidate(cbtRecentProgressProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save mood: $e')),
      );
    }
  }
}





class _ChartDataPoint {
  final DateTime date;
  final int mood;
  _ChartDataPoint({required this.date, required this.mood});
}

class _MoodChart extends StatelessWidget {
  final List<_ChartDataPoint> data;
  const _MoodChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].mood.toDouble()));
    }

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 20, color: ChiromoColors.primary),
              const SizedBox(width: 8),
              Text(
                'Mood Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          'Mood: ${touchedSpot.y.toInt()}/10',
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox();
                        final date = data[idx].date;
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final text = days[date.weekday - 1];
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.length > 0 ? (data.length - 1).toDouble() : 1,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: ChiromoColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: ChiromoColors.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          ChiromoColors.primary.withValues(alpha: 0.4),
                          ChiromoColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

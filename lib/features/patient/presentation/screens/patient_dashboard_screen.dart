import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
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
            .where(
              (e) => e.type == CbtExerciseType.dailyCheckin && e.mood != null,
            )
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
          return now.difference(lastCheckin.createdAt).inHours < 6;
        }
        return false;
      },
      loading: () => false,
      error: (_, _) => false,
    );

    return AppScaffold(
      title: 'Patient Portal',
      showBack: false,
      showAppBar: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/emergency'),
        backgroundColor: const Color(0xFFE57373).withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.emergency, size: 22),
        label: const Text(
          'SOS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header (Does not scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                  Builder(
                    builder: (context) {
                      final unreadCount = ref.watch(
                        unreadNotificationCountProvider,
                      );
                      return GestureDetector(
                        onTap: () => context.push('/patient/notifications'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: ChiromoColors.primaryDark,
                                size: 22,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: ChiromoColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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
                                MoodButton(
                                  label: 'Awful',
                                  imageUrl:
                                      'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Disappointed%20face/3D/disappointed_face_3d.png',
                                  onTap: () =>
                                      _saveMood(context, ref, 2, user?.id),
                                ),
                                MoodButton(
                                  label: 'Bad',
                                  imageUrl:
                                      'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Confused%20face/3D/confused_face_3d.png',
                                  onTap: () =>
                                      _saveMood(context, ref, 4, user?.id),
                                ),
                                MoodButton(
                                  label: 'Okay',
                                  imageUrl:
                                      'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Neutral%20face/3D/neutral_face_3d.png',
                                  onTap: () =>
                                      _saveMood(context, ref, 6, user?.id),
                                ),
                                MoodButton(
                                  label: 'Good',
                                  imageUrl:
                                      'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Slightly%20smiling%20face/3D/slightly_smiling_face_3d.png',
                                  onTap: () =>
                                      _saveMood(context, ref, 8, user?.id),
                                ),
                                MoodButton(
                                  label: 'Great',
                                  imageUrl:
                                      'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Beaming%20face%20with%20smiling%20eyes/3D/beaming_face_with_smiling_eyes_3d.png',
                                  onTap: () =>
                                      _saveMood(context, ref, 10, user?.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

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
                          imagePath:
                              'assets/images/quick_actions/find_doctor.png',
                          onTap: () => context.push('/patient/book'),
                        ),
                        QuickActionCard(
                          icon: Icons.edit,
                          title: 'Record a thought',
                          subtitle: 'Challenge a negative thought',
                          imagePath:
                              'assets/images/quick_actions/record_thought.png',
                          onTap: () =>
                              context.push('/patient/cbt/thought-record'),
                        ),
                        QuickActionCard(
                          icon: Icons.directions_walk,
                          title: 'Log Activity',
                          subtitle: 'Track your behavior activation',
                          imagePath:
                              'assets/images/quick_actions/log_activity.png',
                          onTap: () => context.push(
                            '/patient/cbt/behavioral-activation',
                          ),
                        ),
                        QuickActionCard(
                          icon: Icons.bar_chart,
                          title: "CBT Tools",
                          subtitle: 'View your progress',
                          imagePath:
                              'assets/images/quick_actions/cbt_tools.png',
                          onTap: () => context.push('/patient/cbt'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Appointment / Session tabs
                    const AppointmentTabs(),

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
                        SmallStat(title: avgMood, subtitle: 'Avg Mood'),
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
                            onRetry: () =>
                                ref.invalidate(cbtRecentProgressProvider),
                          ),
                          data: (exercises) {
                            final checkins =
                                exercises
                                    .where(
                                      (e) =>
                                          e.type ==
                                              CbtExerciseType.dailyCheckin &&
                                          (e.mood != null),
                                    )
                                    .toList()
                                  ..sort(
                                    (a, b) =>
                                        a.createdAt.compareTo(b.createdAt),
                                  );

                            if (checkins.isEmpty) {
                              return Container(
                                height: 140,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  'No mood data yet.\nCheck-in to start tracking!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              );
                            }

                            // take last 7 values
                            final recentCheckins = checkins.reversed
                                .take(7)
                                .toList()
                                .reversed
                                .toList();
                            final chartData = recentCheckins
                                .map(
                                  (e) => _ChartDataPoint(
                                    date: e.createdAt,
                                    mood: (e.mood ?? 0).clamp(0, 10).toInt(),
                                  ),
                                )
                                .toList();

                            return Column(
                              children: [
                                _MoodChart(data: chartData),
                                const SizedBox(height: 16),
                                _MoodInsightsCard(data: chartData),
                              ],
                            );
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

  void _saveMood(
    BuildContext context,
    WidgetRef ref,
    int score,
    String? patientId,
  ) async {
    if (patientId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(cbtRepositoryProvider)
          .createExercise(
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

    // Calculate average mood
    final avgMood = data.isEmpty
        ? 0.0
        : data.map((e) => e.mood).reduce((a, b) => a + b) / data.length;
    // Determine trend
    String trendLabel = 'Stable';
    IconData trendIcon = Icons.remove;
    Color trendColor = ChiromoColors.textSecondary;
    if (data.length >= 2) {
      final last = data.last.mood;
      final prev = data[data.length - 2].mood;
      if (last > prev) {
        trendLabel = 'Improving';
        trendIcon = Icons.trending_up_rounded;
        trendColor = ChiromoColors.success;
      } else if (last < prev) {
        trendLabel = 'Declining';
        trendIcon = Icons.trending_down_rounded;
        trendColor = ChiromoColors.error;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with stats ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChiromoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 20,
                  color: ChiromoColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Trends',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Last ${data.length} check-ins',
                      style: TextStyle(
                        fontSize: 12,
                        color: ChiromoColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Avg Mood badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _moodColor(avgMood).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      _moodEmojiUrl(avgMood),
                      width: 18,
                      height: 18,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.mood, size: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      avgMood.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _moodColor(avgMood),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Trend indicator
          Row(
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trendLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Chart ──
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final mood = touchedSpot.y.toInt();
                        return LineTooltipItem(
                          'Mood: $mood/10',
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                      color: theme.dividerColor.withValues(alpha: 0.08),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox();
                        }
                        final date = data[idx].date;
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        final text = days[date.weekday - 1];
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 10,
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
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final v = value.toInt();
                        String url;
                        if (v == 0) {
                          url =
                              'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Disappointed%20face/3D/disappointed_face_3d.png';
                        } else if (v == 5) {
                          url =
                              'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Neutral%20face/3D/neutral_face_3d.png';
                        } else if (v == 10) {
                          url =
                              'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Beaming%20face%20with%20smiling%20eyes/3D/beaming_face_with_smiling_eyes_3d.png';
                        } else {
                          return const SizedBox();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Image.network(
                            url,
                            width: 16,
                            height: 16,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.mood, size: 16),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: data.length > 1 ? (data.length - 1).toDouble() : 1,
                minY: 0,
                maxY: 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF42A5F5),
                        ChiromoColors.primary,
                        Color(0xFF66BB6A),
                      ],
                    ),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: _moodColor(spot.y),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          ChiromoColors.primary.withValues(alpha: 0.25),
                          ChiromoColors.primary.withValues(alpha: 0.05),
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

  Color _moodColor(double mood) {
    if (mood <= 3) return const Color(0xFFEF5350);
    if (mood <= 5) return const Color(0xFFFFA726);
    if (mood <= 7) return const Color(0xFF42A5F5);
    return const Color(0xFF66BB6A);
  }

  String _moodEmojiUrl(double mood) {
    if (mood <= 2) {
      return 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Disappointed%20face/3D/disappointed_face_3d.png';
    }
    if (mood <= 4) {
      return 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Confused%20face/3D/confused_face_3d.png';
    }
    if (mood <= 6) {
      return 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Neutral%20face/3D/neutral_face_3d.png';
    }
    if (mood <= 8) {
      return 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Slightly%20smiling%20face/3D/slightly_smiling_face_3d.png';
    }
    return 'https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/Beaming%20face%20with%20smiling%20eyes/3D/beaming_face_with_smiling_eyes_3d.png';
  }
}

class _MoodInsightsCard extends StatelessWidget {
  final List<_ChartDataPoint> data;
  const _MoodInsightsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final avgMood =
        data.map((e) => e.mood).reduce((a, b) => a + b) / data.length;

    String title = '';
    String description = '';
    IconData icon = Icons.auto_awesome;
    Color color = ChiromoColors.primary;

    if (avgMood >= 7.5) {
      title = 'Doing Great!';
      description =
          'Your mood has been consistently high. Keep up the positive habits and behaviors that are working for you.';
      icon = Icons.sentiment_very_satisfied;
      color = ChiromoColors.success;
    } else if (avgMood >= 4.5) {
      title = 'Holding Steady';
      description =
          'You are maintaining a balanced mood. This is a great time to practice some mindfulness or CBT exercises to build resilience.';
      icon = Icons.balance;
      color = const Color(0xFF42A5F5);
    } else {
      title = 'Needs Attention';
      description =
          'We noticed your mood has been a bit low lately. Consider booking a session with your specialist or trying a Thought Record exercise today.';
      icon = Icons.health_and_safety_outlined;
      color = const Color(0xFFFFA726); // Orange warning
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

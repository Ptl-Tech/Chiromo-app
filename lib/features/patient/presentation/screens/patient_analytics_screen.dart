import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/loading/shimmer_loading.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../domain/entities/patient_analytics_entity.dart';
import '../providers/patient_analytics_provider.dart';

class PatientAnalyticsScreen extends ConsumerWidget {
  const PatientAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnalytics = ref.watch(patientAnalyticsProvider);

    return AppScaffold(
      title: 'My Health Analytics',
      showBack: true,
      body: asyncAnalytics.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              ShimmerCard(height: 120),
              SizedBox(height: 24),
              ShimmerCard(height: 300),
              SizedBox(height: 24),
              ShimmerCard(height: 300),
            ],
          ),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: 'Unable to load your health analytics',
          onRetry: () => ref.invalidate(patientAnalyticsProvider),
        ),
        data: (analytics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Stats Cards
                _buildHealthStatsCards(context, analytics.healthStats),
                const SizedBox(height: 32),

                // Mood History Chart
                _buildSectionHeader(
                  '😊 Mood Tracker',
                  'Your mood over the past 2 weeks',
                ),
                const SizedBox(height: 16),
                _buildMoodChart(context, analytics.moodHistory),
                const SizedBox(height: 32),

                // Appointment History
                _buildSectionHeader(
                  '📅 Appointment History',
                  'Appointments by month',
                ),
                const SizedBox(height: 16),
                _buildAppointmentChart(context, analytics.appointmentStats),
                const SizedBox(height: 32),

                // Two Column: Medications & Sleep
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '💊 Medication Adherence',
                            'Your adherence %',
                          ),
                          const SizedBox(height: 16),
                          _buildMedicationList(context, analytics.medications),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            '😴 Sleep Tracker',
                            'Recent sleep records',
                          ),
                          const SizedBox(height: 16),
                          _buildSleepList(context, analytics.sleepRecords),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Exercise Records
                _buildSectionHeader('🏃 Exercise Activity', 'Your workouts'),
                const SizedBox(height: 16),
                _buildExerciseList(context, analytics.exercises),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthStatsCards(
    BuildContext context,
    PatientHealthStats stats,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            context,
            'Appointments',
            '${stats.completedAppointments}/${stats.totalAppointments}',
            'Completed',
            Icons.event_available,
            ChiromoColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Completion Rate',
            '${stats.appointmentCompletionRate.toStringAsFixed(1)}%',
            'On track',
            Icons.trending_up,
            ChiromoColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Avg Mood',
            '${stats.averageMood.toStringAsFixed(1)}/10',
            'Stable',
            Icons.mood,
            ChiromoColors.gold,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            'Check-in Streak',
            '${stats.streak} days',
            'Consistent',
            Icons.local_fire_department,
            ChiromoColors.crimson,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ChiromoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ChiromoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: ChiromoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ChiromoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildMoodChart(BuildContext context, List<MoodEntry> data) {
    final chartData = data
        .map((p) => ChartData(p.date, p.moodScore.toDouble()))
        .toList();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.gold.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 11,
          ),
        ),
        primaryYAxis: const NumericAxis(
          minimum: 0,
          maximum: 10,
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 11,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 8),
        series: <CartesianSeries>[
          LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: ChiromoColors.gold,
            width: 2,
            markerSettings: const MarkerSettings(
              isVisible: true,
              color: ChiromoColors.gold,
              borderColor: Colors.white,
              borderWidth: 2,
            ),
            animationDuration: 1200,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentChart(
    BuildContext context,
    List<AppointmentStats> data,
  ) {
    final chartData = data
        .map((p) => ChartData(p.month, p.count.toDouble()))
        .toList();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 11,
          ),
        ),
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: ChiromoColors.textSecondary,
            fontSize: 11,
          ),
          majorGridLines: MajorGridLines(
            width: 1,
            color: Color(0x1A000000),
            dashArray: <double>[5, 5],
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, elevation: 8),
        series: <CartesianSeries>[
          ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: ChiromoColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            animationDuration: 1200,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList(
    BuildContext context,
    List<MedicationAdherence> meds,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(meds.length, (index) {
          final med = meds[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.medicationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: ChiromoColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                med.frequency,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ChiromoColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${med.adherencePercentage}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: ChiromoColors.success.withValues(
                            alpha: 0.15,
                          ),
                          labelStyle: const TextStyle(
                            color: ChiromoColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: med.adherencePercentage / 100,
                        minHeight: 6,
                        backgroundColor: ChiromoColors.border.withValues(
                          alpha: 0.3,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          med.adherencePercentage >= 90
                              ? ChiromoColors.success
                              : med.adherencePercentage >= 75
                              ? ChiromoColors.gold
                              : ChiromoColors.crimson,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < meds.length - 1)
                Divider(
                  height: 1,
                  color: ChiromoColors.divider.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSleepList(BuildContext context, List<SleepRecord> records) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(records.length, (index) {
          final record = records[index];
          final qualityColor = record.quality == 'Good'
              ? ChiromoColors.success
              : record.quality == 'Fair'
              ? ChiromoColors.gold
              : ChiromoColors.crimson;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.date,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ChiromoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.hoursSlept} hours',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: qualityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.quality,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: qualityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < records.length - 1)
                Divider(
                  height: 1,
                  color: ChiromoColors.divider.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    List<ExerciseRecord> exercises,
  ) {
    if (exercises.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ChiromoColors.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.directions_run,
                size: 48,
                color: ChiromoColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No exercise records yet',
                style: TextStyle(
                  color: ChiromoColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ChiromoColors.border.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(exercises.length, (index) {
          final ex = exercises[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ChiromoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ex.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ChiromoColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ex.minutesDone} min',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: ChiromoColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < exercises.length - 1)
                Divider(
                  height: 1,
                  color: ChiromoColors.divider.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../theme/chiromo_colors.dart';
import '../screens/appointment_detail_screen.dart';

class MoodButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).canvasColor,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? imagePath;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Image or Icon
                Expanded(
                  child: Center(
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              imagePath!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ChiromoColors.primaryLighter, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: ChiromoColors.primaryDark.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 32, color: ChiromoColors.primary),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SmallStat extends StatelessWidget {
  final String title;
  final String subtitle;

  const SmallStat({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
              Theme.of(context).cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentTabs extends ConsumerWidget {
  const AppointmentTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.hintColor,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 12),
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Recent'),
                Tab(text: 'Cancelled'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: TabBarView(
                children: const [
                  _AppointmentsByFilter(filter: _AppointmentFilter.upcoming),
                  _AppointmentsByFilter(filter: _AppointmentFilter.recent),
                  _AppointmentsByFilter(filter: _AppointmentFilter.cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AppointmentFilter { upcoming, recent, cancelled }

class _AppointmentsByFilter extends ConsumerWidget {
  final _AppointmentFilter filter;
  const _AppointmentsByFilter({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ref
        .watch(patientAppointmentsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Unable to load appointments',
              style: theme.textTheme.bodySmall,
            ),
          ),
          data: (appointments) {
            final now = DateTime.now();
            late final List<AppointmentEntity> appts;

            switch (filter) {
              case _AppointmentFilter.upcoming:
                appts =
                    appointments
                        .where(
                          (a) =>
                              a.scheduledAt.isAfter(now) &&
                              a.status != AppConstants.statusCancelled,
                        )
                        .toList()
                      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                break;
              case _AppointmentFilter.recent:
                appts =
                    appointments
                        .where(
                          (a) =>
                              a.scheduledAt.isBefore(now) &&
                              a.status == AppConstants.statusCompleted,
                        )
                        .toList()
                      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
                break;
              case _AppointmentFilter.cancelled:
                appts =
                    appointments
                        .where((a) => a.status == AppConstants.statusCancelled)
                        .toList()
                      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
                break;
            }

            if (appts.isEmpty) {
              String emptyText = 'No upcoming sessions';
              IconData emptyIcon = Icons.calendar_month_outlined;
              if (filter == _AppointmentFilter.recent) {
                emptyText = 'No recent sessions';
                emptyIcon = Icons.history_rounded;
              } else if (filter == _AppointmentFilter.cancelled) {
                emptyText = 'No cancelled sessions';
                emptyIcon = Icons.event_busy_outlined;
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(emptyIcon, size: 48, color: theme.dividerColor),
                    const SizedBox(height: 12),
                    Text(
                      emptyText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: appts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final appt = appts[idx];
                final doctorName =
                    appt.doctor?.userProfile?.fullName ?? 'Unknown Doctor';
                final specialty = appt.doctor?.specialty ?? 'Specialist';
                final dateStr =
                    '${appt.scheduledAt.day}/${appt.scheduledAt.month}/${appt.scheduledAt.year}';
                final start = appt.scheduledAt;
                final end = appt.scheduledAt.add(const Duration(hours: 1));
                final timeStr =
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                Color statusColor = ChiromoColors.primary;
                String statusText = 'Upcoming';
                if (filter == _AppointmentFilter.recent) {
                  statusColor = ChiromoColors.success;
                  statusText = 'Completed';
                } else if (filter == _AppointmentFilter.cancelled) {
                  statusColor = ChiromoColors.error;
                  statusText = 'Cancelled';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AppointmentDetailScreen(appointment: appt),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: filter == _AppointmentFilter.cancelled 
                                ? ChiromoColors.error.withValues(alpha: 0.3)
                                : theme.dividerColor.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: filter == _AppointmentFilter.cancelled
                              ? ChiromoColors.error.withValues(alpha: 0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                appt.doctor?.userProfile?.avatarUrl ??
                                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(doctorName)}&background=random',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                color: filter == _AppointmentFilter.cancelled ? Colors.grey : null,
                                colorBlendMode: filter == _AppointmentFilter.cancelled ? BlendMode.saturation : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          doctorName,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            decoration: filter == _AppointmentFilter.cancelled ? TextDecoration.lineThrough : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    specialty,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: filter == _AppointmentFilter.cancelled ? Colors.grey : ChiromoColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: theme.hintColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$dateStr • $timeStr',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
  }
}

class MoodChart extends StatelessWidget {
  final List<int> values;

  const MoodChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal + 2).toDouble(),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (idx, meta) {
                  const labels = ['Tue', 'Wed', 'Thu', 'Fri'];
                  final i = idx.toInt();
                  final text = i >= 0 && i < labels.length ? labels[i] : '';
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(text, style: theme.textTheme.bodySmall),
                  );
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: ChiromoColors.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

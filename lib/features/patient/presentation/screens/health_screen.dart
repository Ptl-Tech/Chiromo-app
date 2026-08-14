import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import 'package:chiromo/widgets/glass_card.dart';
import '../providers/health_metrics_provider.dart';
import '../../../../widgets/animated_counter.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMetrics = ref.watch(healthMetricsProvider);

    return AppScaffold(
      title: 'My Health',
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: asyncMetrics.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load health data: $e',
                    style: const TextStyle(color: ChiromoColors.textPrimary),
                  ),
                ),
                data: (metrics) {
                  if (metrics.isEmpty) {
                    return const Center(child: Text('No health data yet.'));
                  }
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: metrics
                        .map((m) => _MetricCard(metric: m))
                        .toList(),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'My Care Team',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ref
                .watch(patientAppointmentsProvider)
                .when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, st) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Failed to load your doctors: $err'),
                  ),
                  data: (appointments) {
                    // Extract unique doctors
                    final doctorsMap = <String, dynamic>{};
                    for (final appt in appointments) {
                      if (appt.doctor != null) {
                        doctorsMap[appt.doctor!.id] = appt.doctor;
                      }
                    }

                    final doctors = doctorsMap.values.toList();

                    if (doctors.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'You haven\'t interacted with any doctors yet.',
                          style: TextStyle(color: ChiromoColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: doctors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = doctors[index];
                        final name =
                            doc.userProfile?.fullName ?? 'Unknown Doctor';
                        final specialty = doc.specialty;
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ChiromoColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: ChiromoColors.primarySurface,
                              backgroundImage:
                                  doc.userProfile?.avatarUrl != null
                                  ? NetworkImage(doc.userProfile!.avatarUrl!)
                                  : null,
                              child: doc.userProfile?.avatarUrl == null
                                  ? Text(
                                      name.substring(0, 1),
                                      style: const TextStyle(
                                        color: ChiromoColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              specialty,
                              style: const TextStyle(
                                color: ChiromoColors.primary,
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: ChiromoColors.primary,
                              ),
                              onPressed: () {
                                context.push(
                                  '/patient/messages/chat/${doc.id}?doctorName=${Uri.encodeComponent(name)}&specialty=${Uri.encodeComponent(specialty)}',
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final HealthMetric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.type.capitalize(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: metric.value.toInt(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Recorded: ${metric.recordedAt.toLocal().toString().split('.').first}',
              style: const TextStyle(
                fontSize: 12,
                color: ChiromoColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

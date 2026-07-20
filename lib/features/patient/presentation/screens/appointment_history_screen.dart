import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import 'appointment_detail_screen.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';

class AppointmentHistoryScreen extends ConsumerWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAppointments = ref.watch(patientAppointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: asyncAppointments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (appointments) {
            final now = DateTime.now();
            final upcoming =
                appointments.where((a) => a.scheduledAt.isAfter(now)).toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            final past =
                appointments.where((a) => !a.scheduledAt.isAfter(now)).toList()
                  ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

            return TabBarView(
              children: [_buildList(upcoming), _buildList(past)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentEntity> appointments) {
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final doctorName =
            appt.doctor?.userProfile?.fullName ?? 'Unknown Doctor';
        final specialty = appt.doctor?.specialty ?? 'Specialist';
        final dateStr =
            '${appt.scheduledAt.day}/${appt.scheduledAt.month}/${appt.scheduledAt.year}';
        final timeStr =
            '${appt.scheduledAt.hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}';

        Color statusColor = ChiromoColors.textSecondary;
        if (appt.status == 'confirmed') {
          statusColor = ChiromoColors.statusConfirmed;
        }
        if (appt.status == 'cancelled') {
          statusColor = ChiromoColors.statusCancelled;
        }
        if (appt.status == 'completed') {
          statusColor = ChiromoColors.statusCompleted;
        }

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentDetailScreen(appointment: appt),
            ),
          ),
          child: _buildAppointmentCard(
            doctorName: doctorName,
            specialty: specialty,
            date: dateStr,
            time: timeStr,
            type: appt.type,
            status: appt.status.toUpperCase(),
            statusColor: statusColor,
            avatarUrl: appt.doctor?.userProfile?.avatarUrl,
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard({
    required String doctorName,
    required String specialty,
    required String date,
    required String time,
    required String type,
    required String status,
    required Color statusColor,
    String? avatarUrl,
  }) {
    return GlassCard(
      elevation: 2,
      borderRadius: 16,
      blurSigma: 12,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ChiromoColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ChiromoColors.surfaceVariant,
                foregroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        color: ChiromoColors.textTertiary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: ChiromoColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: ChiromoColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(color: ChiromoColors.textSecondary),
              ),
              const SizedBox(width: 24),
              Icon(
                type == 'In-Person' ? Icons.local_hospital : Icons.videocam,
                size: 16,
                color: ChiromoColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: const TextStyle(color: ChiromoColors.textSecondary),
              ),
            ],
          ),
          if (status == 'COMPLETED') ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Invoice'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.medication, size: 18),
                    label: const Text('Prescription'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

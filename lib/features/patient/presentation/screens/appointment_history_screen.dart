import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import 'appointment_detail_screen.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import 'package:go_router/go_router.dart';

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
              children: [_buildList(upcoming, context), _buildList(past, context)],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/patient/book'),
          icon: const Icon(Icons.add),
          label: const Text('Book Appointment'),
          backgroundColor: ChiromoColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentEntity> appointments, BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
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
        if (appt.status == 'cancelled' || appt.status == 'rejected') {
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
            onBookAgain: () => context.push('/patient/book'),
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
    required VoidCallback onBookAgain,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ChiromoColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: ChiromoColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ChiromoColors.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: ChiromoColors.surfaceVariant,
                          foregroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: ChiromoColors.textTertiary,
                                  size: 28,
                                )
                              : null,
                        ),
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
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              specialty,
                              style: const TextStyle(
                                color: ChiromoColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: ChiromoColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ChiromoColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: ChiromoColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: ChiromoColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consultation Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ChiromoColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    type.toLowerCase().contains('person') || type.toLowerCase().contains('physical')
                                        ? Icons.local_hospital_rounded 
                                        : Icons.videocam_rounded,
                                    size: 16,
                                    color: ChiromoColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      type.toUpperCase() == 'VIDEO' || type.toLowerCase().contains('online') 
                                        ? 'Video Call' 
                                        : 'In-Person',
                                      style: const TextStyle(
                                        color: ChiromoColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onBookAgain,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Book Appointment'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ChiromoColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (status == 'COMPLETED') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Invoice'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

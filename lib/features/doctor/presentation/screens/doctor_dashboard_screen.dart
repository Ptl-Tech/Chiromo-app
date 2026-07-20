import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../widgets/cards/chiromo_action_card.dart';
import 'package:chiromo/widgets/loading/shimmer_loading.dart';
import 'package:chiromo/widgets/error/error_retry_widget.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final asyncAppointments = ref.watch(doctorAppointmentsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Doctor Portal',
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${user?.fullName?.split(' ').last ?? 'Specialist'}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Have a great day at work!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: ChiromoColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Live stats
            asyncAppointments.when(
              loading: () => const ShimmerCard(height: 80),
              error: (error, _) => ErrorRetryWidget(
                message: 'Could not load stats',
                onRetry: () => ref.invalidate(doctorAppointmentsProvider),
              ),
              data: (appointments) {
                final now = DateTime.now();
                final todayCount = appointments.where((a) {
                  final sameDay =
                      a.scheduledAt.year == now.year &&
                      a.scheduledAt.month == now.month &&
                      a.scheduledAt.day == now.day;
                  return sameDay && a.status != AppConstants.statusCancelled;
                }).length;
                final pendingCount = appointments
                    .where((a) => a.status == AppConstants.statusPending)
                    .length;
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Today',
                        todayCount.toString(),
                        Icons.people_outline,
                        gradient: ChiromoColors.cardGradientBlue,
                        iconColor: ChiromoColors.white,
                        textColor: ChiromoColors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingCount.toString(),
                        Icons.pending_actions,
                        gradient: ChiromoColors.cardGradientGold,
                        iconColor: ChiromoColors.primaryDarkest,
                        textColor: ChiromoColors.primaryDarkest,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            Text(
              'Quick Links',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            ChiromoActionCard(
              title: 'My Schedule',
              subtitle: 'View your appointments for the week',
              icon: Icons.calendar_month,
              onTap: () => context.go('/doctor/calendar'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Patient Directory',
              subtitle: 'Access records of patients under your care',
              icon: Icons.folder_shared_outlined,
              onTap: () => context.go('/doctor/patients'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Patient Notes',
              subtitle: 'View and write patient session records',
              icon: Icons.note_alt_outlined,
              onTap: () => context.go('/doctor/notes'),
            ),

            const SizedBox(height: 32),
            Text(
              'Next Appointment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            asyncAppointments.when(
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Container(
                height: 140,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Unable to load upcoming appointments',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              data: (appointments) =>
                  _buildNextAppointmentCard(context, ref, appointments),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon, {
    required LinearGradient gradient,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickNewDateTime(
    BuildContext context,
    DateTime initialDateTime,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _approveAppointment(
    BuildContext context,
    WidgetRef ref,
    AppointmentEntity appointment,
  ) async {
    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointmentStatus(
        appointment.id,
        AppConstants.statusConfirmed,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment confirmed successfully')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm appointment: $error')),
        );
      }
    }
  }

  Future<void> _requestNewTime(
    BuildContext context,
    WidgetRef ref,
    AppointmentEntity appointment,
  ) async {
    final selected = await _pickNewDateTime(context, appointment.scheduledAt);
    if (selected == null) return;
    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointment(
        appointment.id,
        status: AppConstants.statusRescheduleRequested,
        scheduledAt: selected,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requested a new appointment time.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request a new time: $error')),
        );
      }
    }
  }

  Future<void> _rejectAppointment(
    BuildContext context,
    WidgetRef ref,
    AppointmentEntity appointment,
  ) async {
    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointment(
        appointment.id,
        status: AppConstants.statusRejected,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment rejected. Patient will select another doctor.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reject appointment: $error')),
        );
      }
    }
  }

  Widget _buildNextAppointmentCard(
    BuildContext context,
    WidgetRef ref,
    List<AppointmentEntity> appointments,
  ) {
    final now = DateTime.now();
    final upcoming =
        appointments
            .where(
              (a) =>
                  a.scheduledAt.isAfter(now) &&
                  a.status != AppConstants.statusCancelled,
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (upcoming.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_busy,
                size: 36,
                color: ChiromoColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No upcoming appointments scheduled yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ChiromoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final appointment = upcoming.first;
    final patientName = appointment.patient?.fullName ?? 'Patient';
    final appointmentType = appointment.type == 'telemedicine'
        ? 'Video Visit'
        : 'In-Person';
    final timeLabel =
        '${appointment.scheduledAt.hour.toString().padLeft(2, '0')}:${appointment.scheduledAt.minute.toString().padLeft(2, '0')}';

    final bool isPending = appointment.status == AppConstants.statusPending;
    final textColor = isPending ? ChiromoColors.primaryDarkest : Colors.white;
    final badgeBackground = isPending ? ChiromoColors.white : Colors.white24;
    final statusLabel = appointment.status.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: isPending
            ? ChiromoColors.goldGradient
            : ChiromoColors.cardGradientBlue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  foregroundImage: appointment.patient?.avatarUrl != null
                      ? NetworkImage(appointment.patient!.avatarUrl!)
                      : null,
                  child: appointment.patient?.avatarUrl == null
                      ? Text(
                          patientName
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        appointmentType,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.88),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: isPending
                          ? ChiromoColors.primaryDarkest
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appointmentType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isPending ||
                appointment.status ==
                    AppConstants.statusRescheduleRequested) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ChiromoColors.primaryDarkest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () =>
                          _approveAppointment(context, ref, appointment),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          _requestNewTime(context, ref, appointment),
                      child: const Text('Request new time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _rejectAppointment(context, ref, appointment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Reject appointment'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPending
                            ? Colors.white
                            : Colors.white24,
                        foregroundColor: isPending
                            ? ChiromoColors.primaryDarkest
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isPending
                          ? () => _approveAppointment(context, ref, appointment)
                          : () {},
                      child: Text(
                        isPending ? 'Confirm appointment' : 'View details',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isPending
                              ? ChiromoColors.primaryDarkest
                              : Colors.white,
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
    );
  }
}

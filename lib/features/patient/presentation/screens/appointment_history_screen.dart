import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../appointments/data/models/app_appointment_model.dart';
import '../../../appointments/presentation/providers/app_appointment_providers.dart';
import 'app_appointment_detail_screen.dart';

/// The patient's appointment requests, split into what is still ahead of them
/// and what is behind.
///
/// Backed by Business Central through the Go API, not Supabase: these are
/// requests the hospital's own system knows about, which is the only place
/// that can say whether one has actually been confirmed.
class AppointmentHistoryScreen extends ConsumerWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final pastAsync = ref.watch(pastAppointmentsProvider);

    final upcoming = upcomingAsync.valueOrNull ?? const <AppAppointment>[];
    final past = pastAsync.valueOrNull ?? const <AppAppointment>[];

    // Open on Past when there is nothing coming up — otherwise the first thing
    // someone with history sees is an empty tab.
    final initialIndex = upcoming.isEmpty && past.isNotEmpty ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
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
        body: upcomingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(appAppointmentsProvider),
          ),
          data: (_) => TabBarView(
            children: [
              _AppointmentList(
                appointments: upcoming,
                emptyMessage: 'Nothing booked at the moment.',
                onRefresh: () async => ref.invalidate(appAppointmentsProvider),
              ),
              _AppointmentList(
                appointments: past,
                emptyMessage: 'No past appointments yet.',
                onRefresh: () async => ref.invalidate(appAppointmentsProvider),
              ),
            ],
          ),
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
}

class _AppointmentList extends StatelessWidget {
  final List<AppAppointment> appointments;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      // Still wrapped in a scroll view so pull-to-refresh works on an empty
      // tab — otherwise the only way to recheck is to leave and come back.
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(top: 120),
          children: [
            Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(color: ChiromoColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: appointments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _AppointmentCard(
            appointment: appointment,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AppAppointmentDetailScreen(appointment: appointment),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppAppointment appointment;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colour = statusColour(appointment.status);
    final date = appointment.date;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(color: colour.withValues(alpha: 0.15)),
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
                          color: colour,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date == null
                              ? 'Date to confirm'
                              : '${date.day}/${date.month}/${date.year}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colour,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status.label.toUpperCase(),
                        style: TextStyle(
                          color: colour,
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ChiromoColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: ChiromoColors.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          color: ChiromoColors.textTertiary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctorName.isEmpty
                                ? 'Doctor to be assigned'
                                : appointment.doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: ChiromoColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.appointmentType.isEmpty
                                ? 'Consultation'
                                : appointment.appointmentType,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ChiromoColors.textSecondary,
                            ),
                          ),
                          if (appointment.timeRange.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: ChiromoColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appointment.timeRange,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: ChiromoColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: ChiromoColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: ChiromoColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ChiromoColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

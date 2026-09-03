import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../appointments/data/models/app_appointment_model.dart';
import '../../../appointments/presentation/providers/app_appointment_providers.dart';
import '../providers/clinical_providers.dart';
import 'visit_notes_screen.dart';

/// One appointment request the patient raised from the app.
///
/// The screen is careful about a distinction the patient has a real stake in:
/// a request is not a booking. Until reception accepts it, this says so
/// plainly rather than showing a date as though the clinic had agreed to it —
/// somebody turning up for an unconfirmed slot is a wasted journey.
class AppAppointmentDetailScreen extends ConsumerWidget {
  final AppAppointment appointment;

  const AppAppointmentDetailScreen({required this.appointment, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colour = statusColour(appointment.status);

    return AppScaffold(
      title: 'Appointment',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colour.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: colour,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusExplanation(appointment),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
                if (appointment.decisionReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    appointment.decisionReason,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Doctor',
            value: appointment.doctorName.isEmpty
                ? 'To be assigned'
                : appointment.doctorName,
          ),
          _DetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Date',
            value: appointment.date == null
                ? '—'
                : _longDate(appointment.date!),
          ),
          _DetailRow(
            icon: Icons.schedule,
            label: 'Time',
            value: appointment.timeRange.isEmpty ? '—' : appointment.timeRange,
          ),
          if (appointment.appointmentType.isNotEmpty)
            _DetailRow(
              icon: Icons.medical_services_outlined,
              label: 'Type',
              value: appointment.appointmentType,
            ),
          if (appointment.branch.isNotEmpty)
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Branch',
              value: appointment.branch,
            ),
          if (appointment.reason.isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Your note',
              value: appointment.reason,
            ),
          _VisitNotesSection(appointmentNo: appointment.hospitalBookingNo),
          if (appointment.cancellable) ...[
            const SizedBox(height: 24),
            ChiromoButton(
              label: 'Cancel this appointment',
              variant: ChiromoButtonVariant.outline,
              onPressed: () => _confirmCancel(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  /// Says what the current state actually means for the patient, in the terms
  /// they care about — whether to turn up.
  String _statusExplanation(AppAppointment appointment) {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return 'Your request has been sent. Reception will confirm it, and '
            'you will see it here once they have. Please wait for that before '
            'travelling in.';
      case AppointmentStatus.confirmed:
        return appointment.confirmed
            ? 'This is confirmed. The clinic is expecting you.'
            : 'Reception has accepted this and is finalising it with the '
                  'clinic.';
      case AppointmentStatus.rejected:
        return 'Reception could not take this one.';
      case AppointmentStatus.cancelled:
        return 'This was cancelled.';
      case AppointmentStatus.attended:
        return 'You attended this appointment.';
      case AppointmentStatus.noShow:
        return 'This was recorded as missed.';
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this appointment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The slot will be released for someone else.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChiromoColors.error),
            child: const Text('Cancel it'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(appAppointmentNotifierProvider.notifier)
          .cancel(entryNo: appointment.entryNo, reason: reason);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

/// What the doctor wrote for the patient about this visit.
///
/// Anchored on the clinic's own appointment number rather than the app's
/// request number, because that is the key the note carries — and it is blank
/// until reception accepts the booking, so nothing renders for a request the
/// hospital never took up.
///
/// Silent when there is nothing: an "awaiting notes" placeholder under every
/// past appointment would set an expectation the clinic has not made. A note
/// is written when there is something worth saying, not as a matter of course.
class _VisitNotesSection extends ConsumerWidget {
  final String appointmentNo;

  const _VisitNotesSection({required this.appointmentNo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointmentNo.isEmpty) return const SizedBox.shrink();

    final notes = ref.watch(visitNotesForAppointmentProvider(appointmentNo));

    return notes.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'FROM YOUR VISIT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: ChiromoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            for (final note in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VisitNoteCard(note: note),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// The colour a request's state is drawn in. Shared with the history list so
/// a request looks the same in both places.
Color statusColour(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return ChiromoColors.statusPending;
    case AppointmentStatus.confirmed:
      return ChiromoColors.statusConfirmed;
    case AppointmentStatus.attended:
      return ChiromoColors.statusCompleted;
    case AppointmentStatus.rejected:
    case AppointmentStatus.cancelled:
      return ChiromoColors.statusCancelled;
    case AppointmentStatus.noShow:
      return ChiromoColors.statusNoShow;
  }
}

String _longDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ChiromoColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: ChiromoColors.textPrimary,
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

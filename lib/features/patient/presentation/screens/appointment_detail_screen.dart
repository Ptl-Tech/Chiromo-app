import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'video_consultation_screen.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final AppointmentEntity appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  late AppointmentEntity _appointment;
  final _feedbackCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _join() {
    if (_appointment.type == 'telemedicine') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoConsultationScreen(appointment: _appointment),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This appointment is not a telemedicine session.'),
      ),
    );
  }

  Future<DateTime?> _pickNewDateTime(DateTime initialDateTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (!mounted || date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (!mounted || time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _updateAppointment({
    String? status,
    DateTime? scheduledAt,
    String? doctorId,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final updated = await repository.updateAppointment(
        _appointment.id,
        status: status,
        scheduledAt: scheduledAt,
        doctorId: doctorId,
      );
      if (mounted) {
        setState(() {
          _appointment = updated;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update appointment: $error')),
        );
      }
    }
  }

  Future<void> _reschedule() async {
    final selected = await _pickNewDateTime(_appointment.scheduledAt);
    if (selected == null) return;
    await _updateAppointment(
      status: AppConstants.statusRescheduleRequested,
      scheduledAt: selected,
    );
  }

  Future<void> _acceptProposedTime() async {
    await _updateAppointment(status: AppConstants.statusConfirmed);
  }

  void _cancelAppointment() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No, keep it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateAppointment(status: AppConstants.statusCancelled);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeDoctor() {
    context.go('/patient/doctors');
  }

  void _bookAnotherAppointment() {
    context.go('/patient/book');
  }

  void _submitFeedback(BuildContext dialogContext) {
    final text = _feedbackCtrl.text.trim();
    if (text.isEmpty) return;
    _feedbackCtrl.clear();
    Navigator.of(dialogContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks — feedback submitted')),
    );
  }

  void _openFeedbackDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave feedback'),
        content: TextField(
          controller: _feedbackCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'How was your session?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitFeedback(ctx),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = _appointment;
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isDoctor = authUser?.role.isDoctor ?? false;
    final doctorName = appt.doctor?.userProfile?.fullName ?? 'Doctor';
    final specialty = appt.doctor?.specialty ?? '';
    final patientName = appt.patient?.fullName ?? 'Patient';
    final patientPhone = appt.patient?.phone ?? 'No phone';
    final date =
        '${appt.scheduledAt.day}/${appt.scheduledAt.month}/${appt.scheduledAt.year}';
    final time =
        '${appt.scheduledAt.hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}';
    final isTelemedicine = appt.type.toLowerCase() == 'telemedicine';

    Widget sectionChip(IconData icon, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          foregroundImage: isDoctor
                              ? (appt.patient?.avatarUrl != null
                                    ? NetworkImage(appt.patient!.avatarUrl!)
                                    : null)
                              : (appt.doctor?.userProfile?.avatarUrl != null
                                    ? NetworkImage(
                                        appt.doctor!.userProfile!.avatarUrl!,
                                      )
                                    : null),
                          child:
                              (isDoctor
                                      ? appt.patient?.avatarUrl
                                      : appt.doctor?.userProfile?.avatarUrl) ==
                                  null
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDoctor ? patientName : doctorName,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isDoctor ? patientPhone : specialty,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: appt.status == AppConstants.statusConfirmed
                                ? ChiromoColors.statusConfirmed.withValues(
                                    alpha: 0.14,
                                  )
                                : ChiromoColors.primaryLighter,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            appt.status.toUpperCase(),
                            style: TextStyle(
                              color: appt.status == AppConstants.statusConfirmed
                                  ? ChiromoColors.statusConfirmed
                                  : ChiromoColors.primary,
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
                          child: sectionChip(
                            Icons.calendar_today_outlined,
                            date,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: sectionChip(Icons.access_time, time)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appt.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              isTelemedicine &&
                                  _appointment.status ==
                                      AppConstants.statusConfirmed
                              ? _join
                              : null,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Join'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _reschedule,
                          icon: const Icon(Icons.schedule),
                          label: const Text('Reschedule'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        if (appt.status != AppConstants.statusCancelled && appt.status != AppConstants.statusCompleted && appt.status != AppConstants.statusRejected) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _cancelAppointment,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Appointment'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_appointment.status == AppConstants.statusConfirmed &&
                        !isTelemedicine) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This appointment is confirmed. Please arrive on time at the scheduled location.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!isDoctor &&
                        _appointment.status ==
                            AppConstants.statusRescheduleRequested) ...[
                      FilledButton(
                        onPressed: _isProcessing ? null : _acceptProposedTime,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Accept new time'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isProcessing ? null : _changeDoctor,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Choose another doctor'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!isDoctor &&
                        _appointment.status == AppConstants.statusRejected) ...[
                      OutlinedButton(
                        onPressed: _changeDoctor,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Book another doctor'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (!isDoctor) ...[
                      ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _bookAnotherAppointment,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Book another appointment'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: _openFeedbackDialog,
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Leave feedback'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

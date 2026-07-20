import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../theme/chiromo_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../patient/presentation/screens/video_consultation_screen.dart';

class DoctorCalendarScreen extends ConsumerStatefulWidget {
  const DoctorCalendarScreen({super.key});

  @override
  ConsumerState<DoctorCalendarScreen> createState() =>
      _DoctorCalendarScreenState();
}

class _DoctorCalendarScreenState extends ConsumerState<DoctorCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isRequestingReschedule = false;

  @override
  void initState() {
    super.initState();
  }

  Future<DateTime?> _pickNewDateTime(DateTime initialDateTime) async {
    if (!mounted) return null;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (!mounted) return null;
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (!mounted) return null;
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _requestNewTime(_Appointment appointment) async {
    final selected = await _pickNewDateTime(appointment.scheduledAt);
    if (selected == null) return;

    setState(() {
      _isRequestingReschedule = true;
    });

    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointment(
        appointment.appointmentId,
        status: AppConstants.statusRescheduleRequested,
        scheduledAt: selected,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment reschedule requested successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not request a new time: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingReschedule = false;
        });
      }
    }
  }

  Future<void> _approveAppointment(_Appointment appointment) async {
    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointmentStatus(
        appointment.appointmentId,
        AppConstants.statusConfirmed,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment approved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not approve appointment: $error')),
      );
    }
  }

  Future<void> _rejectAppointment(_Appointment appointment) async {
    final repository = ref.read(appointmentRepositoryProvider);
    try {
      await repository.updateAppointment(
        appointment.appointmentId,
        status: AppConstants.statusRejected,
      );
      ref.invalidate(doctorAppointmentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment rejected.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject appointment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncAppointments = ref.watch(doctorAppointmentsProvider);

    return asyncAppointments.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (appointments) {
        final Map<DateTime, List<_Appointment>> eventsMap = {};
        for (final appt in appointments) {
          final normalized = DateTime(
            appt.scheduledAt.year,
            appt.scheduledAt.month,
            appt.scheduledAt.day,
          );
          if (!eventsMap.containsKey(normalized)) {
            eventsMap[normalized] = [];
          }

          // Choose event color based on appointment status
          Color eventColor = ChiromoColors.primary;
          switch (appt.status) {
            case 'pending':
              eventColor = ChiromoColors.gold;
              break;
            case 'confirmed':
              eventColor = ChiromoColors.primary;
              break;
            case 'reschedule_requested':
              eventColor = Colors.orange;
              break;
            case 'rejected':
              eventColor = ChiromoColors.crimson;
              break;
            case 'completed':
              eventColor = ChiromoColors.success;
              break;
            case 'cancelled':
              eventColor = ChiromoColors.statusCancelled;
              break;
            default:
              eventColor = ChiromoColors.primary;
          }

          eventsMap[normalized]!.add(
            _Appointment(
              appointment: appt,
              appointmentId: appt.id,
              patientId: appt.patientId,
              patientName: appt.patient?.fullName ?? 'Unknown',
              type: appt.type,
              status: appt.status,
              scheduledAt: appt.scheduledAt,
              startTime:
                  '${appt.scheduledAt.hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}',
              endTime:
                  '${appt.scheduledAt.add(const Duration(hours: 1)).hour.toString().padLeft(2, '0')}:${appt.scheduledAt.minute.toString().padLeft(2, '0')}',
              color: eventColor,
            ),
          );
        }

        List<_Appointment> getEventsForDay(DateTime day) {
          final normalized = DateTime(day.year, day.month, day.day);
          return eventsMap[normalized] ?? [];
        }

        final selectedEvents = getEventsForDay(_selectedDay ?? _focusedDay);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Schedule'),
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Go to Today',
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Calendar Header
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TableCalendar<_Appointment>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: ChiromoColors.primaryLight.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: ChiromoColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: ChiromoColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: ChiromoColors.gold,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 6,
                    markersMaxCount: 3,
                    outsideDaysVisible: false,
                  ),
                  calendarBuilders: CalendarBuilders<_Appointment>(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      // draw a small row of colored dots corresponding to events
                      return Padding(
                        padding: const EdgeInsets.only(top: 28.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events
                              .take(3)
                              .map(
                                (e) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (e).color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Appointments List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Appointments (${selectedEvents.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedDay != null
                          ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
                          : 'Today',
                      style: const TextStyle(
                        color: ChiromoColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: ChiromoColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No appointments scheduled',
                              style: TextStyle(
                                color: ChiromoColors.textTertiary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedEvents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final appt = selectedEvents[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  _showAppointmentDetails(context, appt),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: appt.color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appt.patientName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            appt.type,
                                            style: const TextStyle(
                                              color:
                                                  ChiromoColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          appt.startTime,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appt.endTime,
                                          style: const TextStyle(
                                            color: ChiromoColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: ChiromoColors.textTertiary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAppointmentDetails(BuildContext context, _Appointment appt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ChiromoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                appt.patientName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    color: ChiromoColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(appt.type),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: ChiromoColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text('${appt.startTime} - ${appt.endTime}'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Status: ${appt.status.replaceAll('_', ' ').toUpperCase()}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              if (appt.type == 'telemedicine') ...[
                Text(
                  'This is a telemedicine appointment. Use the live session button to start video, audio, and chat.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isRequestingReschedule
                          ? null
                          : () => _requestNewTime(appt),
                      child: Text(
                        _isRequestingReschedule
                            ? 'Requesting...'
                            : 'Reschedule',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (appt.type == 'telemedicine') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideoConsultationScreen(
                                appointment: appt.appointment,
                              ),
                            ),
                          );
                        } else {
                          context.go(
                            '/doctor/consultation/${appt.appointmentId}/${appt.patientId}',
                          );
                        }
                      },
                      icon: Icon(
                        appt.type == 'telemedicine'
                            ? Icons.video_call
                            : Icons.edit_document,
                      ),
                      label: Text(
                        appt.type == 'telemedicine'
                            ? 'Start Session'
                            : 'Consult',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (appt.status == AppConstants.statusPending ||
                  appt.status == AppConstants.statusRescheduleRequested) ...[
                OutlinedButton(
                  onPressed: () => _approveAppointment(appt),
                  child: const Text('Approve Appointment'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _rejectAppointment(appt),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Reject Appointment'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Appointment {
  final AppointmentEntity appointment;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String type;
  final String status;
  final DateTime scheduledAt;
  final String startTime;
  final String endTime;
  final Color color;

  _Appointment({
    required this.appointment,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.status,
    required this.scheduledAt,
    required this.startTime,
    required this.endTime,
    required this.color,
  });
}

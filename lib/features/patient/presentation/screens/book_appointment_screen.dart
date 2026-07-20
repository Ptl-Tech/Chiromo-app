import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../doctor/domain/entities/doctor_entity.dart';
import '../../../doctor/presentation/providers/doctor_providers.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../admin/domain/entities/branch_entity.dart';
import '../../../admin/presentation/providers/admin_providers.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  int _currentStep = 0;
  BranchEntity? _selectedBranch;
  String? _selectedType;
  DoctorEntity? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;

  void _nextStep() {
    if (_currentStep == 0 && _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch.')),
      );
      return;
    }
    if (_currentStep == 1 && _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a consultation type.')),
      );
      return;
    }
    if (_currentStep == 2 && _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specialist.')),
      );
      return;
    }
    if (_currentStep == 3 && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a date for your appointment.'),
        ),
      );
      return;
    }
    if (_currentStep == 3 && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a time slot for your appointment.'),
        ),
      );
      return;
    }
    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
    }
  }

  void _cancelStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book Appointment',
      showBack: true,
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _cancelStep,
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 4;
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: ChiromoButton(
                    label: isLast ? 'Confirm Booking' : 'Continue',
                    onPressed: () {
                      if (isLast) {
                        _submitBooking();
                      } else {
                        details.onStepContinue?.call();
                      }
                    },
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChiromoButton(
                      label: 'Back',
                      variant: ChiromoButtonVariant.outline,
                      onPressed: details.onStepCancel,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select Branch'),
            content: ref.watch(branchesProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Error loading branches: $err'),
              data: (branches) {
                if (branches.isEmpty) {
                  return const Text('No branches available.');
                }
                return Column(
                  children: branches.map((branch) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildChoiceTile(
                        title: branch.name,
                        subtitle: 'Book an appointment at our ${branch.name} clinic',
                        icon: Icons.business_outlined,
                        isSelected: _selectedBranch?.id == branch.id,
                        onTap: () => setState(() => _selectedBranch = branch),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Consultation Type'),
            content: Column(
              children: [
                _buildChoiceTile(
                  title: 'In-Person Visit',
                  subtitle: 'Visit our hospital for a physical checkup',
                  icon: Icons.local_hospital_outlined,
                  isSelected: _selectedType == 'in-person',
                  onTap: () => setState(() => _selectedType = 'in-person'),
                ),
                const SizedBox(height: 12),
                _buildChoiceTile(
                  title: 'Telemedicine (Video Call)',
                  subtitle: 'Face-to-face consultation via video',
                  icon: Icons.videocam_outlined,
                  isSelected: _selectedType == 'video',
                  onTap: () => setState(() => _selectedType = 'video'),
                ),
                const SizedBox(height: 12),
                _buildChoiceTile(
                  title: 'Telemedicine (Voice Call)',
                  subtitle: 'Consult a doctor over a phone call',
                  icon: Icons.phone_outlined,
                  isSelected: _selectedType == 'voice',
                  onTap: () => setState(() => _selectedType = 'voice'),
                ),
                const SizedBox(height: 12),
                _buildChoiceTile(
                  title: 'Telemedicine (Chat)',
                  subtitle: 'Message a doctor securely in the app',
                  icon: Icons.chat_outlined,
                  isSelected: _selectedType == 'chat',
                  onTap: () => setState(() => _selectedType = 'chat'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Select Specialist'),
            content: ref
                .watch(allDoctorsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error loading doctors: $e'),
                  data: (doctors) {
                    if (doctors.isEmpty) {
                      return const Text('No specialists available.');
                    }
                    return Column(
                      children: doctors.map((doc) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildChoiceTile(
                            title:
                                doc.userProfile?.fullName ?? 'Unknown Doctor',
                            subtitle: doc.specialty,
                            icon: Icons.person_outline,
                            isSelected: _selectedDoctor?.id == doc.id,
                            onTap: () => setState(() => _selectedDoctor = doc),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Choose Date & Time'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CalendarDatePicker(
                  initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedTime = null; // reset time when date changes
                    });
                  },
                ),
                if (_selectedDate != null && _selectedDoctor != null) ...[
                  const SizedBox(height: 16),
                  const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ref.watch(doctorAppointmentsForDateProvider((_selectedDoctor!.id, _selectedDate!))).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Text('Error loading slots: $err'),
                    data: (existingAppts) {
                      final bookedTimes = existingAppts
                          .where((a) => a.status != AppConstants.statusCancelled && a.status != AppConstants.statusRejected)
                          .map((a) => TimeOfDay(hour: a.scheduledAt.toLocal().hour, minute: a.scheduledAt.toLocal().minute))
                          .toSet();

                      // Generate slots 9 AM to 4 PM
                      final slots = List.generate(8, (i) => TimeOfDay(hour: 9 + i, minute: 0));

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: slots.map((slot) {
                          final isBooked = bookedTimes.contains(slot);
                          final isSelected = _selectedTime == slot;
                          return InkWell(
                            onTap: isBooked ? null : () => setState(() => _selectedTime = slot),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ChiromoColors.primary
                                    : (isBooked ? ChiromoColors.surfaceVariant.withValues(alpha: 0.5) : Colors.transparent),
                                border: Border.all(
                                  color: isSelected ? ChiromoColors.primary : (isBooked ? ChiromoColors.border.withValues(alpha: 0.5) : ChiromoColors.border),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                slot.format(context),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isBooked ? ChiromoColors.textTertiary : ChiromoColors.textPrimary),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  decoration: isBooked ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Confirm Details'),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ChiromoColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Divider(),
                  _buildSummaryRow('Branch', _selectedBranch?.name ?? 'Not selected'),
                  _buildSummaryRow(
                    'Type',
                    _selectedType == 'video'
                        ? 'Video Call'
                        : _selectedType == 'voice'
                            ? 'Voice Call'
                            : _selectedType == 'chat'
                                ? 'Chat'
                                : 'In-Person',
                  ),
                  _buildSummaryRow(
                    'Doctor',
                    _selectedDoctor?.userProfile?.fullName ?? 'Not selected',
                  ),
                  _buildSummaryRow(
                    'Date',
                    _selectedDate?.toString().split(' ')[0] ?? 'Not selected',
                  ),
                  _buildSummaryRow(
                    'Time',
                    _selectedTime?.format(context) ?? 'Not selected',
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Repeat Weekly?'),
                    subtitle: const Text('Book 4 sessions at this same time'),
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedBranch == null || _selectedType == null ||
        _selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps')),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      
      final numSessions = _isRecurring ? 4 : 1;
      
      for (int i = 0; i < numSessions; i++) {
        final date = _selectedDate!.add(Duration(days: i * 7));
        final model = AppointmentModel(
          id: '',
          patientId: user.id,
          doctorId: _selectedDoctor!.id,
          branchId: _selectedBranch!.id,
          scheduledAt: DateTime(
            date.year,
            date.month,
            date.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          ),
          status: AppConstants.statusPending,
          type: _selectedType!,
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repo.bookAppointment(model);
      }

      // Refresh patient appointments
      ref.invalidate(patientAppointmentsProvider);
      // Also refresh doctor appointments for date so it disables correctly
      ref.invalidate(doctorAppointmentsForDateProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isRecurring ? 'All 4 recurring appointments booked successfully!' : 'Appointment booked successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: ChiromoColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? ChiromoColors.primary : ChiromoColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      tileColor: isSelected ? ChiromoColors.primarySurface : null,
      leading: Icon(
        icon,
        color: isSelected ? ChiromoColors.primary : ChiromoColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? ChiromoColors.primary : ChiromoColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: ChiromoColors.primary)
          : null,
    );
  }
}

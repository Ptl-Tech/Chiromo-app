import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/error/error_retry_widget.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../appointments/data/models/app_appointment_model.dart';
import '../../../appointments/presentation/providers/app_appointment_providers.dart';

/// Raises an appointment request.
///
/// The screen is honest about what the button does: this asks reception for a
/// slot, it does not book one. Saying "booked" here and then having the
/// request rejected is how somebody ends up travelling to a clinic that is not
/// expecting them.
///
/// Doctors and slots both come from Business Central's live diary — a doctor
/// with nothing free simply does not appear, so there is no way to pick a slot
/// that was never on offer.
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _reasonController = TextEditingController();

  AvailableDoctor? _doctor;
  DateTime? _day;
  DoctorSlot? _slot;
  AppointmentType? _type;
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(availabilityProvider(null));
    final types = ref.watch(appointmentTypesProvider);

    return AppScaffold(
      title: 'Request an Appointment',
      body: availability.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetryWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(availabilityProvider),
        ),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const _NoAvailability();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _Note(
                'Choosing a slot sends a request to reception. They will '
                'confirm it, and you will see it in your appointments once '
                'they have.',
              ),
              const SizedBox(height: 20),
              const _SectionLabel('DOCTOR'),
              const SizedBox(height: 8),
              for (final doctor in doctors)
                _DoctorTile(
                  doctor: doctor,
                  selected: _doctor?.doctorId == doctor.doctorId,
                  onTap: () => setState(() {
                    _doctor = doctor;
                    // A day and slot only mean anything for one doctor, so
                    // switching doctor clears both rather than carrying over a
                    // selection that doctor may not offer.
                    _day = null;
                    _slot = null;
                  }),
                ),
              if (_doctor != null) ...[
                const SizedBox(height: 20),
                const _SectionLabel('DAY'),
                const SizedBox(height: 8),
                _DayPicker(
                  days: _doctor!.availableDates,
                  selected: _day,
                  onSelect: (day) => setState(() {
                    _day = day;
                    _slot = null;
                  }),
                ),
              ],
              if (_doctor != null && _day != null) ...[
                const SizedBox(height: 20),
                const _SectionLabel('TIME'),
                const SizedBox(height: 8),
                _SlotPicker(
                  slots: _doctor!.slotsOn(_day!),
                  selected: _slot,
                  onSelect: (slot) => setState(() => _slot = slot),
                ),
              ],
              const SizedBox(height: 20),
              const _SectionLabel('APPOINTMENT TYPE'),
              const SizedBox(height: 8),
              types.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text(
                  'Types could not be loaded — reception will set this.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
                data: (items) => _TypePicker(
                  types: items,
                  selected: _type,
                  onSelect: (type) => setState(() => _type = type),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('WHAT WOULD YOU LIKE TO DISCUSS?'),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 250,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Optional — a short note for the clinic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ChiromoButton(
                label: 'Send request',
                isLoading: _saving,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _canSubmit =>
      !_saving && _doctor != null && _day != null && _slot != null;

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      await ref
          .read(appAppointmentNotifierProvider.notifier)
          .book(
            doctorId: _doctor!.doctorId,
            date: _day!,
            // BC matches the diary line on its own slot key, so this sends
            // what BC gave us rather than a formatted time.
            slot: _slot!.slot,
            branch: _doctor!.branch,
            appointmentType: _type?.code ?? '',
            reason: _reasonController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent. Reception will confirm it shortly.'),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _DoctorTile extends StatelessWidget {
  final AvailableDoctor doctor;
  final bool selected;
  final VoidCallback onTap;

  const _DoctorTile({
    required this.doctor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      doctor.specialization,
      doctor.clinic,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? ChiromoColors.primarySurface
                : ChiromoColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ChiromoColors.primary : ChiromoColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: ChiromoColors.surfaceVariant,
                child: Icon(
                  Icons.person,
                  size: 22,
                  color: ChiromoColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ChiromoColors.textSecondary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${doctor.slots.length} slots free',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ChiromoColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: ChiromoColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  const _DayPicker({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected =
              selected != null &&
              selected!.year == day.year &&
              selected!.month == day.month &&
              selected!.day == day.day;

          return InkWell(
            onTap: () => onSelect(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? ChiromoColors.primary
                    : ChiromoColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? ChiromoColors.primary
                      : ChiromoColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : ChiromoColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : ChiromoColors.textPrimary,
                    ),
                  ),
                  Text(
                    _month(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white70
                          : ChiromoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _weekday(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  static String _month(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
  }
}

class _SlotPicker extends StatelessWidget {
  final List<DoctorSlot> slots;
  final DoctorSlot? selected;
  final ValueChanged<DoctorSlot> onSelect;

  const _SlotPicker({
    required this.slots,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Text(
        'Nothing free that day.',
        style: TextStyle(fontSize: 13, color: ChiromoColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in slots)
          ChoiceChip(
            label: Text(slot.label),
            selected: selected?.slot == slot.slot,
            onSelected: (_) => onSelect(slot),
            selectedColor: ChiromoColors.primary,
            labelStyle: TextStyle(
              color: selected?.slot == slot.slot
                  ? Colors.white
                  : ChiromoColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _TypePicker extends StatelessWidget {
  final List<AppointmentType> types;
  final AppointmentType? selected;
  final ValueChanged<AppointmentType> onSelect;

  const _TypePicker({
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in types)
          ChoiceChip(
            label: Text(type.label),
            selected: selected?.code == type.code,
            onSelected: (_) => onSelect(type),
            selectedColor: ChiromoColors.primary,
            labelStyle: TextStyle(
              color: selected?.code == type.code
                  ? Colors.white
                  : ChiromoColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _NoAvailability extends StatelessWidget {
  const _NoAvailability();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: ChiromoColors.primaryLighter,
            ),
            SizedBox(height: 16),
            Text(
              'No slots in the next two weeks',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check back shortly, or call the clinic if it is urgent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: ChiromoColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChiromoColors.goldSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: ChiromoColors.textPrimary,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ChiromoColors.textTertiary,
      ),
    );
  }
}

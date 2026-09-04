import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../data/models/activity_plan_model.dart';
import '../providers/activity_providers.dart';

/// Plans an activity, or records how one turned out.
///
/// One sheet for both halves, because it is one record and the patient is
/// looking at the same thing either way — what they expected sits above what
/// they found, which is the comparison the exercise is built on.
///
/// Pushed on the root navigator so it covers the shell's bottom nav bar.
Future<void> showActivityPlanSheet({
  required BuildContext context,
  required WidgetRef ref,
  ActivityPlan? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActivityPlanSheet(existing: existing),
  );
}

class _ActivityPlanSheet extends ConsumerStatefulWidget {
  final ActivityPlan? existing;

  const _ActivityPlanSheet({this.existing});

  @override
  ConsumerState<_ActivityPlanSheet> createState() => _ActivityPlanSheetState();
}

class _ActivityPlanSheetState extends ConsumerState<_ActivityPlanSheet> {
  late final TextEditingController _activity;
  late final TextEditingController _skipReason;
  late final TextEditingController _notes;

  late DateTime _plannedAt;
  late int _anticipatedPleasure;
  late int _anticipatedAchievement;
  late int _actualPleasure;
  late int _actualAchievement;

  ActivityStatus _status = ActivityStatus.planned;
  bool _saving = false;

  /// Whether the prediction is still editable. BC refuses to move it once the
  /// activity has left Planned, so the form must not offer to.
  bool get _predictionEditable =>
      widget.existing == null || widget.existing!.isPlanned;

  bool get _isRecording => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _activity = TextEditingController(text: e?.activity ?? '');
    _skipReason = TextEditingController(text: e?.skipReason ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _plannedAt = e?.plannedAt ?? DateTime.now();
    _anticipatedPleasure = e?.anticipatedPleasure ?? 5;
    _anticipatedAchievement = e?.anticipatedAchievement ?? 5;
    // Seeded from the prediction so the sliders start somewhere sensible; what
    // gets stored is wherever the patient leaves them.
    _actualPleasure = e?.actualPleasure ?? (e?.anticipatedPleasure ?? 5);
    _actualAchievement =
        e?.actualAchievement ?? (e?.anticipatedAchievement ?? 5);
    _status = e?.status ?? ActivityStatus.planned;
  }

  @override
  void dispose() {
    _activity.dispose();
    _skipReason.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isRecording ? 'How did it go?' : 'Plan an activity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _Label('What will you do?'),
              const SizedBox(height: 8),
              TextField(
                controller: _activity,
                maxLength: 250,
                minLines: 1,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Walk to the shop and back',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              _DateRow(value: _plannedAt, onPick: _pickDate),
              const SizedBox(height: 20),
              _Label(
                _predictionEditable
                    ? 'How do you think it will go?'
                    : 'What you expected',
              ),
              const SizedBox(height: 4),
              if (_predictionEditable)
                const Text(
                  'A guess is fine. The point is to have one written down '
                  'before you find out.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              _Rating(
                label: 'Enjoyment',
                value: _anticipatedPleasure,
                enabled: _predictionEditable,
                onChanged: (v) => setState(() => _anticipatedPleasure = v),
              ),
              _Rating(
                label: 'Sense of achievement',
                value: _anticipatedAchievement,
                enabled: _predictionEditable,
                onChanged: (v) => setState(() => _anticipatedAchievement = v),
              ),
              if (_isRecording) ...[
                const SizedBox(height: 20),
                const _Label('What happened?'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final option in const [
                      ActivityStatus.done,
                      ActivityStatus.skipped,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            option == ActivityStatus.done
                                ? 'I did it'
                                : 'It did not happen',
                          ),
                          selected: _status == option,
                          onSelected: (_) => setState(() => _status = option),
                          selectedColor: ChiromoColors.primary,
                          labelStyle: TextStyle(
                            color: _status == option
                                ? Colors.white
                                : ChiromoColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_status == ActivityStatus.done) ...[
                  const SizedBox(height: 16),
                  const _Label('How was it actually?'),
                  const SizedBox(height: 8),
                  _Rating(
                    label: 'Enjoyment',
                    value: _actualPleasure,
                    onChanged: (v) => setState(() => _actualPleasure = v),
                  ),
                  _Rating(
                    label: 'Sense of achievement',
                    value: _actualAchievement,
                    onChanged: (v) => setState(() => _actualAchievement = v),
                  ),
                ],
                if (_status == ActivityStatus.skipped) ...[
                  const SizedBox(height: 16),
                  const _Label('What got in the way?'),
                  const SizedBox(height: 4),
                  const Text(
                    'Worth writing down. What stops things happening is often '
                    'more useful to know than the times they do.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: ChiromoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _skipReason,
                    maxLength: 250,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Ran out of time after work',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
              if (_isRecording) ...[
                const SizedBox(height: 16),
                const _Label('Anything worth noting?'),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ChiromoButton(
                label: _isRecording ? 'Save' : 'Add to my plan',
                isLoading: _saving,
                onPressed: _canSave ? _save : null,
              ),
              if (_isRecording) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: ChiromoColors.error,
                  ),
                  child: const Text('Remove this activity'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSave {
    if (_saving) return false;
    if (_activity.text.trim().isEmpty) return false;
    // The one required reason: a skipped activity with no explanation records
    // that nothing happened without recording why, which is the useful half.
    if (_status == ActivityStatus.skipped && _skipReason.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _plannedAt = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await ref
          .read(activityNotifierProvider.notifier)
          .save(
            entryNo: widget.existing?.entryNo,
            activity: _activity.text.trim(),
            plannedAt: _plannedAt,
            anticipatedPleasure: _anticipatedPleasure,
            anticipatedAchievement: _anticipatedAchievement,
            status: _status,
            actualPleasure: _status == ActivityStatus.done
                ? _actualPleasure
                : 0,
            actualAchievement: _status == ActivityStatus.done
                ? _actualAchievement
                : 0,
            skipReason: _status == ActivityStatus.skipped
                ? _skipReason.text.trim()
                : '',
            notes: _notes.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete() async {
    final entryNo = widget.existing?.entryNo;
    if (entryNo == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(activityNotifierProvider.notifier).delete(entryNo);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _DateRow extends StatelessWidget {
  final DateTime value;
  final VoidCallback onPick;

  const _DateRow({required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: ChiromoColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: ChiromoColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _longDate(value),
                style: const TextStyle(
                  fontSize: 14,
                  color: ChiromoColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar,
              size: 18,
              color: ChiromoColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _Rating({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: enabled
                  ? ChiromoColors.textPrimary
                  : ChiromoColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: kRatingMin.toDouble(),
            max: kRatingMax.toDouble(),
            divisions: kRatingMax - kRatingMin,
            label: '$value',
            activeColor: ChiromoColors.primary,
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value/10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: enabled
                  ? ChiromoColors.textPrimary
                  : ChiromoColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ChiromoColors.textPrimary,
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/buttons/chiromo_button.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/exposure_ladder_model.dart';
import '../providers/exposure_providers.dart';

/// Records one attempt at a rung.
///
/// The whole form is two numbers and an optional note. That is deliberate: the
/// thing that decides whether someone logs a second session is how little the
/// first one cost them, and a long form after a hard exposure is exactly when
/// people stop.
class LogExposureTrialScreen extends ConsumerStatefulWidget {
  final int ladderEntryNo;
  final int stepRank;

  const LogExposureTrialScreen({
    required this.ladderEntryNo,
    required this.stepRank,
    super.key,
  });

  @override
  ConsumerState<LogExposureTrialScreen> createState() =>
      _LogExposureTrialScreenState();
}

class _LogExposureTrialScreenState
    extends ConsumerState<LogExposureTrialScreen> {
  final _notesController = TextEditingController();

  int? _before;
  int _after = 5;
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ladderAsync = ref.watch(exposureLadderProvider(widget.ladderEntryNo));
    final step = ladderAsync.valueOrNull?.steps
        .where((s) => s.rank == widget.stepRank)
        .firstOrNull;

    // The template's suggested rating seeds the "before" slider once, as a
    // starting position for the thumb. It is never sent unless the patient
    // leaves it where it is — and it is not shown as a number anywhere, so it
    // cannot quietly become the answer they think they are supposed to give.
    if (!_prefilled && step != null) {
      _prefilled = true;
      _before = step.suggestedSuds > 0 ? step.suggestedSuds : 5;
    }

    return AppScaffold(
      title: 'Log a Session',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (step != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ChiromoColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THE STEP YOU WORKED ON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ChiromoColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
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
            const SizedBox(height: 24),
          ],
          _SudsField(
            title: 'Before you started',
            caption: 'How anxious did you feel going in?',
            value: _before ?? 5,
            onChanged: (value) => setState(() => _before = value),
          ),
          const SizedBox(height: 20),
          _SudsField(
            title: 'By the end',
            caption: 'How anxious did you feel as you finished?',
            value: _after,
            onChanged: (value) => setState(() => _after = value),
          ),
          const SizedBox(height: 24),
          const Text(
            'ANYTHING YOU WANT TO NOTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ChiromoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            maxLength: 2048,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Optional — in your own words',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ChiromoButton(
            label: 'Save session',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await ref
          .read(exposureNotifierProvider.notifier)
          .logTrial(
            ladderEntryNo: widget.ladderEntryNo,
            stepRank: widget.stepRank,
            recordedAt: DateTime.now(),
            sudsBefore: _before ?? 5,
            sudsAfter: _after,
            notes: _notesController.text.trim(),
          );

      if (!mounted) return;
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

/// A 0-10 distress rating.
///
/// The scale is labelled at its ends rather than described in words per value:
/// what a 6 means is the patient's own business, and it only has to be
/// consistent with their other sixes for the trend to mean something.
class _SudsField extends StatelessWidget {
  final String title;
  final String caption;
  final int value;
  final ValueChanged<int> onChanged;

  const _SudsField({
    required this.title,
    required this.caption,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ChiromoColors.primary,
              ),
            ),
            const Text(
              '/10',
              style: TextStyle(fontSize: 13, color: ChiromoColors.textTertiary),
            ),
          ],
        ),
        Text(
          caption,
          style: const TextStyle(
            fontSize: 13,
            color: ChiromoColors.textSecondary,
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: kSudsMin.toDouble(),
          max: kSudsMax.toDouble(),
          divisions: kSudsMax - kSudsMin,
          label: '$value',
          activeColor: ChiromoColors.primary,
          onChanged: (v) => onChanged(v.round()),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calm',
                style: TextStyle(
                  fontSize: 12,
                  color: ChiromoColors.textTertiary,
                ),
              ),
              Text(
                'As bad as it gets',
                style: TextStyle(
                  fontSize: 12,
                  color: ChiromoColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

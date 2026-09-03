import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../data/models/checkin_model.dart';
import '../providers/checkin_providers.dart';

/// Records a wellbeing check-in against Business Central.
///
/// The scales are not hardcoded here. BC decides which exist, their range,
/// their band labels and colours, and which direction is the good one — so
/// adding "Pain" as a rating type in BC makes a pain slider appear with no
/// change to this file.
class DailyCheckinScreen extends ConsumerStatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  ConsumerState<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  /// Current score per rating type code, seeded from each scale's midpoint.
  final Map<String, int> _scores = {};
  final TextEditingController _notesCtrl = TextEditingController();

  double _sleepHours = 7.5;
  bool _logSleep = true;
  bool _isShared = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Seeds any scale we haven't got a score for yet. Called as the types
  /// arrive, and again if BC gains a new scale while the screen is open.
  void _ensureDefaults(List<RatingType> types) {
    for (final type in types) {
      _scores.putIfAbsent(type.code, () => type.defaultValue);
    }
  }

  Future<void> _save(List<RatingType> types) async {
    setState(() => _isSaving = true);

    final ratings = types
        .map(
          (type) => Rating(
            typeCode: type.code,
            value: _scores[type.code] ?? type.defaultValue,
            bandCaption: '',
          ),
        )
        .toList();

    try {
      await ref
          .read(checkinNotifierProvider.notifier)
          .saveCheckin(
            // Sent from the device clock so a late-night entry is dated by the
            // patient's day, not the server's.
            recordedAt: DateTime.now(),
            notes: _notesCtrl.text.trim(),
            shareWithDoctor: _isShared,
            ratings: ratings,
            sleepHours: _logSleep ? _sleepHours : null,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typesAsync = ref.watch(ratingTypesProvider);

    return AppScaffold(
      title: 'Daily Check-in',
      showBack: true,
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(theme, err),
        data: (types) {
          _ensureDefaults(types);
          return _buildForm(theme, types);
        },
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: ChiromoColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: ChiromoColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => ref.invalidate(ratingTypesProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, List<RatingType> types) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      children: [
        Text(
          'How are you doing?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Record this as often as you like — patterns matter more than any '
          'single entry.',
          style: TextStyle(fontSize: 13, color: ChiromoColors.textSecondary),
        ),
        const SizedBox(height: 28),

        if (types.isEmpty)
          Text(
            'No check-in questions are set up yet. Please contact Client '
            'Services.',
            style: TextStyle(color: ChiromoColors.textSecondary),
          ),

        for (final type in types) ...[
          _buildRatingSlider(theme, type),
          const SizedBox(height: 24),
        ],

        _buildSleepSection(theme),
        const SizedBox(height: 24),

        Text(
          'Notes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Anything you want to remember about today',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isShared,
          onChanged: (v) => setState(() => _isShared = v),
          title: const Text('Share with my care team'),
          subtitle: Text(
            'Your clinician can see this entry',
            style: TextStyle(fontSize: 12, color: ChiromoColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: (_isSaving || types.isEmpty) ? null : () => _save(types),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save check-in'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRatingSlider(ThemeData theme, RatingType type) {
    final value = _scores[type.code] ?? type.defaultValue;
    final band = type.bandFor(value);
    final accent = band?.colour ?? ChiromoColors.primary;
    final steps = type.maxValue - type.minValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.prompt.isNotEmpty ? type.prompt : type.description,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                '$value/${type.maxValue}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: type.minValue.toDouble(),
                max: type.maxValue.toDouble(),
                // A scale is always whole numbers; guard against a
                // misconfigured min == max producing zero divisions.
                divisions: steps > 0 ? steps : null,
                activeColor: accent,
                label: band?.caption,
                onChanged: (v) =>
                    setState(() => _scores[type.code] = v.round()),
              ),
            ),
          ],
        ),
        if (band != null && band.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Text(
              band.caption,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSleepSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hours slept last night',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: _logSleep,
              onChanged: (v) => setState(() => _logSleep = v),
            ),
          ],
        ),
        if (_logSleep) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  '${_sleepHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ChiromoColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _sleepHours,
                  min: 0,
                  max: 14,
                  // Half-hour steps; BC stores this as a decimal so the .5
                  // survives the round trip.
                  divisions: 28,
                  activeColor: ChiromoColors.primary,
                  onChanged: (v) => setState(() => _sleepHours = v),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Text(
              'Recorded once per day, separately from your check-ins',
              style: TextStyle(
                fontSize: 12,
                color: ChiromoColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

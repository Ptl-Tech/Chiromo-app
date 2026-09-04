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
///
/// Two things on this screen run on different clocks, and the form now says so.
/// Ratings describe a moment and may be recorded as often as the patient likes.
/// Sleep describes the night and is stored once, keyed on the date in BC — so
/// the first check-in of a day asks about it, and the ones in between show what
/// was already logged instead of offering to overwrite it.
class DailyCheckinScreen extends ConsumerStatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  ConsumerState<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  /// Current score per rating type code, seeded from each scale's midpoint.
  final Map<String, int> _scores = {};
  final TextEditingController _notesCtrl = TextEditingController();

  /// Sleep hours as they stand in the form, seeded from today's logged value
  /// when there is one — so reopening the screen shows what the patient
  /// actually recorded rather than a default.
  double _sleepHours = 7.5;

  /// Whether the sleep slider is on screen. This doubles as the decision to
  /// write: sleep is sent only when the patient has deliberately opened it,
  /// which is what stops a later check-in from replacing a real figure with
  /// whatever the slider happened to default to.
  bool _sleepOpen = false;

  bool _seeded = false;
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

  /// Takes the starting sleep figure from today's log, once.
  void _seedSleep(SleepLog? logged) {
    if (_seeded) return;
    _seeded = true;
    if (logged != null) _sleepHours = logged.hours;
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
            sleepHours: _sleepOpen ? _sleepHours : null,
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
    final sleepAsync = ref.watch(todaySleepProvider);
    final earlierAsync = ref.watch(todaysCheckinsProvider);

    final error = typesAsync.error ?? sleepAsync.error ?? earlierAsync.error;
    final types = typesAsync.valueOrNull;
    final earlier = earlierAsync.valueOrNull;
    final ready = types != null && earlier != null && sleepAsync.hasValue;

    // The day's earlier entries decide the shape of this form, so the title
    // waits for them rather than saying "Daily Check-in" and changing its mind.
    final title = ready
        ? (earlier.isEmpty ? 'Daily Check-in' : 'Check in again')
        : 'Check-in';

    return AppScaffold(
      title: title,
      showBack: true,
      body: Builder(
        builder: (_) {
          if (error != null) return _buildError(theme, error);
          if (!ready) return const Center(child: CircularProgressIndicator());
          _ensureDefaults(types);
          _seedSleep(sleepAsync.value);
          return _buildForm(theme, types, sleepAsync.value, earlier);
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
              onPressed: () {
                ref.invalidate(ratingTypesProvider);
                ref.invalidate(sleepLogsProvider);
                ref.invalidate(checkinHistoryProvider);
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    ThemeData theme,
    List<RatingType> types,
    SleepLog? loggedSleep,
    List<Checkin> earlier,
  ) {
    final first = earlier.isEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      children: [
        Text(
          first ? 'How are you starting the day?' : 'How are you right now?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          first
              ? 'Your first entry today. It also carries last night’s sleep.'
              : 'This adds to today rather than replacing what you recorded '
                    'earlier — how things shift across a day is worth seeing.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: ChiromoColors.textSecondary,
          ),
        ),

        if (!first) ...[
          const SizedBox(height: 18),
          _EarlierToday(entries: earlier, types: types),
        ],

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

        _buildSleepSection(theme, loggedSleep),
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
          decoration: InputDecoration(
            hintText: first
                ? 'Anything you want to remember about today'
                : 'What has happened since your last entry?',
            border: const OutlineInputBorder(),
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
              : Text(first ? 'Save check-in' : 'Add this check-in'),
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

  /// Last night's sleep, either put away or open for editing.
  ///
  /// Put away is the important state: with no slider on screen nothing is
  /// written, so a check-in later in the day cannot quietly replace a recorded
  /// figure with an untouched default.
  Widget _buildSleepSection(ThemeData theme, SleepLog? logged) {
    if (!_sleepOpen) {
      return _SleepClosed(
        logged: logged,
        onOpen: () => setState(() => _sleepOpen = true),
      );
    }

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
            TextButton(
              onPressed: () => setState(() {
                _sleepOpen = false;
                // Drop back to what is on record, so putting the slider away
                // really does leave things as they were.
                if (logged != null) _sleepHours = logged.hours;
              }),
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
            logged == null
                ? 'Saved with this check-in, against last night.'
                : 'This replaces the ${logged.hours.toStringAsFixed(1)}h '
                      'already recorded for last night.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: ChiromoColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The sleep row when the slider is put away: either what is on record, or an
/// invitation to add it.
class _SleepClosed extends StatelessWidget {
  final SleepLog? logged;
  final VoidCallback onOpen;

  const _SleepClosed({required this.logged, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final hours = logged?.hours;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 20,
            color: hours == null
                ? ChiromoColors.textTertiary
                : ChiromoColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hours == null
                      ? 'Last night’s sleep'
                      : 'Last night · ${hours.toStringAsFixed(1)} hours',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ChiromoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hours == null
                      ? 'Not recorded yet'
                      : 'Already recorded for today',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ChiromoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpen,
            child: Text(hours == null ? 'Add' : 'Change'),
          ),
        ],
      ),
    );
  }
}

/// What the patient already recorded today, so a later entry is made in view of
/// the earlier ones rather than in isolation.
class _EarlierToday extends StatelessWidget {
  final List<Checkin> entries;
  final List<RatingType> types;

  const _EarlierToday({required this.entries, required this.types});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChiromoColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EARLIER TODAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ChiromoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      _clockTime(entry.recordedAt),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ChiromoColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _summarise(entry),
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: ChiromoColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Scores read back with the scale's own wording, so a line means the same
  /// thing here as it did on the form.
  String _summarise(Checkin entry) {
    if (entry.ratings.isEmpty) {
      return entry.notes.isEmpty ? 'Notes only' : entry.notes;
    }

    final parts = <String>[];
    for (final rating in entry.ratings) {
      final type = _typeFor(rating.typeCode);
      final label = (type != null && type.description.isNotEmpty)
          ? type.description
          : rating.typeCode;
      final suffix = type == null ? '' : '/${type.maxValue}';
      parts.add('$label ${rating.value}$suffix');
    }
    return parts.join(' · ');
  }

  RatingType? _typeFor(String code) {
    for (final type in types) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// 12-hour clock, which is how patients describe their own day.
String _clockTime(DateTime? at) {
  if (at == null) return '';
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${at.hour < 12 ? 'am' : 'pm'}';
}

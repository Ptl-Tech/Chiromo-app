import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/checkin_remote_datasource.dart';
import '../../data/models/checkin_model.dart';

/// Providers for the Business-Central-backed wellbeing check-in feature.

final checkinDataSourceProvider = Provider<CheckinRemoteDataSource>((ref) {
  return CheckinRemoteDataSource();
});

/// The scales to render, as configured in BC. Cached for the session: the
/// setup changes rarely, and re-fetching on every visit to the check-in
/// screen would put a round trip in front of the form for no benefit.
final ratingTypesProvider = FutureProvider<List<RatingType>>((ref) {
  return ref.watch(checkinDataSourceProvider).getRatingTypes();
});

/// How far back the app pulls check-ins and sleep logs.
///
/// Everything downstream reads a tail of this: the stat tiles compare a 7-day
/// window against the 7 before it, the mood chart draws the last 14 entries,
/// the chat sparkline the last 7. Six months leaves all of that room to spare
/// while keeping a patient who has been with the clinic for years from
/// re-downloading their whole history on every app open.
///
/// The one figure that could otherwise run past this is the day streak, which
/// is capped at the window and labelled as a floor rather than silently
/// rounded down — see [WellbeingStats.streakAtWindowEdge].
const int kHistoryWindowDays = 180;

/// The first day still fetched. Time is stripped so the boundary lands on a
/// date, matching how BC filters.
DateTime historyWindowStart() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: kHistoryWindowDays - 1));
}

/// The signed-in patient's check-in history, newest first.
///
/// No upper bound is sent. A device clock running ahead can date an entry
/// tomorrow, and a `to` of today would hide the check-in the patient just
/// saved — an entry vanishing on save reads as data loss.
final checkinHistoryProvider = FutureProvider<List<Checkin>>((ref) {
  return ref
      .watch(checkinDataSourceProvider)
      .getCheckins(from: historyWindowStart());
});

/// The signed-in patient's nightly sleep durations, newest first.
final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) {
  return ref
      .watch(checkinDataSourceProvider)
      .getSleepLogs(from: historyWindowStart());
});

/// Last night's sleep as already recorded, or null when nothing is logged for
/// today yet.
///
/// The check-in form needs this before it can show a sleep slider. BC keys
/// sleep on the date and a save replaces the row, so a form that opened on a
/// hardcoded default would overwrite a real figure with a guess the moment a
/// patient checked in a second time.
final todaySleepProvider = FutureProvider<SleepLog?>((ref) async {
  final logs = await ref.watch(sleepLogsProvider.future);
  final today = DateTime.now();
  for (final log in logs) {
    final date = log.date;
    if (date == null) continue;
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return log;
    }
  }
  return null;
});

/// Check-ins already recorded today, newest first.
///
/// Empty means the next entry is the first of the day — the one that carries
/// last night's sleep. Non-empty means it is a check-in in between, which is a
/// different thing to record and reads differently on the form.
final todaysCheckinsProvider = FutureProvider<List<Checkin>>((ref) async {
  final checkins = await ref.watch(checkinHistoryProvider.future);
  final today = DateTime.now();

  final mine = <Checkin>[];
  for (final checkin in checkins) {
    final at = checkin.recordedAt;
    if (at == null) continue;
    if (at.year == today.year &&
        at.month == today.month &&
        at.day == today.day) {
      mine.add(checkin);
    }
  }

  mine.sort((a, b) => b.recordedAt!.compareTo(a.recordedAt!));
  return mine;
});

/// Imperative check-in actions. Errors are rethrown so the calling screen can
/// show them inline rather than having them swallowed into global state.
final checkinNotifierProvider =
    StateNotifierProvider<CheckinNotifier, AsyncValue<void>>((ref) {
      return CheckinNotifier(ref);
    });

class CheckinNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CheckinNotifier(this._ref) : super(const AsyncValue.data(null));

  CheckinRemoteDataSource get _source => _ref.read(checkinDataSourceProvider);

  /// Saves a check-in and, when the patient entered them, that night's sleep
  /// hours. The two are separate records in BC — a check-in is a moment, sleep
  /// is a property of the day — so this writes both rather than pretending
  /// sleep belongs to the entry.
  Future<void> saveCheckin({
    int? entryNo,
    required DateTime recordedAt,
    required String notes,
    required bool shareWithDoctor,
    required List<Rating> ratings,
    double? sleepHours,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _source.saveCheckin(
        entryNo: entryNo,
        recordedAt: recordedAt,
        notes: notes,
        shareWithDoctor: shareWithDoctor,
        ratings: ratings,
      );

      if (sleepHours != null) {
        await _source.saveSleepLog(
          date: recordedAt,
          hours: sleepHours,
          shareWithDoctor: shareWithDoctor,
        );
        _ref.invalidate(sleepLogsProvider);
      }

      _ref.invalidate(checkinHistoryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCheckin(int entryNo) async {
    await _source.deleteCheckin(entryNo);
    _ref.invalidate(checkinHistoryProvider);
  }
}

/// Business Central's code for the mood scale.
///
/// The check-in form itself is fully generic and names no scale — but a "mood
/// over time" chart is inherently about mood, so the one code it depends on is
/// named here rather than left as a literal scattered across screens. If the
/// clinic ever renames the scale, this is the only line to change.
const String kMoodRatingCode = 'MOOD';

/// One mood score plotted against when it was recorded.
class MoodPoint {
  final DateTime date;
  final int value;

  const MoodPoint({required this.date, required this.value});
}

/// Mood scores oldest-first — the order a trend chart reads in.
///
/// Check-ins that recorded no mood (notes-only entries, or a day the patient
/// only scored anxiety) are skipped rather than plotted as zero, which would
/// read as a crisis rather than a gap.
final moodTrendProvider = FutureProvider<List<MoodPoint>>((ref) async {
  final checkins = await ref.watch(checkinHistoryProvider.future);

  final points = <MoodPoint>[];
  for (final checkin in checkins) {
    final rating = checkin.ratingFor(kMoodRatingCode);
    final recordedAt = checkin.recordedAt;
    if (rating == null || recordedAt == null) continue;
    points.add(MoodPoint(date: recordedAt, value: rating.value));
  }

  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
});

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

/// The signed-in patient's check-in history, newest first.
final checkinHistoryProvider = FutureProvider<List<Checkin>>((ref) {
  return ref.watch(checkinDataSourceProvider).getCheckins();
});

/// The signed-in patient's nightly sleep durations, newest first.
final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) {
  return ref.watch(checkinDataSourceProvider).getSleepLogs();
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

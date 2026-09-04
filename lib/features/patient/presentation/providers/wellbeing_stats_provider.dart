import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/checkin_model.dart';
import 'checkin_providers.dart';

/// Summary statistics over the patient's own check-ins and sleep logs.
///
/// Everything here is derived from what they have already recorded — nothing
/// is estimated, and no figure is shown for a period they logged nothing in.
/// A zero that means "you did not check in" and a zero that means "you felt
/// nothing" are different claims, and only one of them is ours to make.

/// Business Central's code for the anxiety scale.
///
/// The check-in form itself names no scale — it renders whatever BC returns —
/// but a summary tile labelled "Anxiety" is inherently about anxiety, so the
/// one code it depends on is named here rather than left as a literal.
const String kAnxietyRatingCode = 'ANXIETY';

/// How many days of history the summary covers.
const int kStatsWindowDays = 7;

class WellbeingStats {
  /// Consecutive days ending today (or yesterday, if today's check-in has not
  /// happened yet) on which the patient checked in.
  final int dayStreak;

  /// Mean mood over the window, or null when nothing was scored.
  final double? averageMood;

  /// Change against the previous window as a percentage, or null when there is
  /// no earlier period to compare with. A first week has no trend, and drawing
  /// one would be inventing a comparison.
  final double? moodTrendPercent;

  final double? averageAnxiety;
  final double? averageSleepHours;

  /// Whether [dayStreak] ran back as far as the fetched history goes, so the
  /// real streak is at least that and possibly longer.
  ///
  /// Shown as "180+" rather than "180". Quietly printing the cap as though it
  /// were exact would shorten someone's streak on the one screen that exists
  /// to credit it.
  final bool streakAtWindowEdge;

  /// Check-ins recorded in the window.
  final int checkinCount;

  /// Seven entries, Monday to Sunday of the current week, each counting the
  /// check-ins recorded that day.
  final List<int> weekActivity;

  const WellbeingStats({
    this.dayStreak = 0,
    this.averageMood,
    this.moodTrendPercent,
    this.averageAnxiety,
    this.averageSleepHours,
    this.streakAtWindowEdge = false,
    this.checkinCount = 0,
    this.weekActivity = const [0, 0, 0, 0, 0, 0, 0],
  });

  /// Whether there is enough here to be worth drawing at all.
  bool get hasData => checkinCount > 0 || averageSleepHours != null;
}

final wellbeingStatsProvider = FutureProvider<WellbeingStats>((ref) async {
  final checkins = await ref.watch(checkinHistoryProvider.future);
  final sleepLogs = await ref.watch(sleepLogsProvider.future);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final windowStart = today.subtract(
    const Duration(days: kStatsWindowDays - 1),
  );
  final previousStart = windowStart.subtract(
    const Duration(days: kStatsWindowDays),
  );

  final recent = <Checkin>[];
  final previous = <Checkin>[];
  final checkinDays = <DateTime>{};

  for (final checkin in checkins) {
    final recordedAt = checkin.recordedAt;
    if (recordedAt == null) continue;
    final day = DateTime(recordedAt.year, recordedAt.month, recordedAt.day);

    checkinDays.add(day);

    if (!day.isBefore(windowStart)) {
      recent.add(checkin);
    } else if (!day.isBefore(previousStart)) {
      previous.add(checkin);
    }
  }

  final averageMood = _averageRating(recent, kMoodRatingCode);
  final previousMood = _averageRating(previous, kMoodRatingCode);

  double? trend;
  if (averageMood != null && previousMood != null && previousMood > 0) {
    trend = ((averageMood - previousMood) / previousMood) * 100;
  }

  final streak = _streak(checkinDays, today);

  return WellbeingStats(
    dayStreak: streak.days,
    streakAtWindowEdge: streak.atWindowEdge,
    averageMood: averageMood,
    moodTrendPercent: trend,
    averageAnxiety: _averageRating(recent, kAnxietyRatingCode),
    averageSleepHours: _averageSleep(sleepLogs, windowStart),
    checkinCount: recent.length,
    weekActivity: _weekActivity(checkinDays, today),
  );
});

/// Mean of one scale across a set of check-ins, ignoring entries that did not
/// score it. A notes-only check-in is not a zero.
double? _averageRating(List<Checkin> checkins, String code) {
  var total = 0;
  var count = 0;

  for (final checkin in checkins) {
    final rating = checkin.ratingFor(code);
    if (rating == null) continue;
    total += rating.value;
    count++;
  }

  if (count == 0) return null;
  return total / count;
}

double? _averageSleep(List<SleepLog> logs, DateTime from) {
  var total = 0.0;
  var count = 0;

  for (final log in logs) {
    final date = log.date;
    if (date == null || date.isBefore(from)) continue;
    total += log.hours;
    count++;
  }

  if (count == 0) return null;
  return total / count;
}

/// Consecutive check-in days ending today or yesterday.
///
/// Yesterday counts as the anchor so a streak does not appear broken at
/// breakfast simply because today's check-in has not happened yet — which
/// would punish someone for the time of day they opened the app.
///
/// [atWindowEdge] is set when the walk reached the oldest day we fetched. The
/// run may well continue past it; we simply cannot see that far, and the caller
/// says so rather than presenting the cap as the answer.
({int days, bool atWindowEdge}) _streak(Set<DateTime> days, DateTime today) {
  if (days.isEmpty) return (days: 0, atWindowEdge: false);

  var cursor = today;
  if (!days.contains(cursor)) {
    cursor = today.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return (days: 0, atWindowEdge: false);
  }

  final oldest = historyWindowStart();

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    if (!cursor.isAfter(oldest)) {
      return (days: streak, atWindowEdge: true);
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return (days: streak, atWindowEdge: false);
}

/// Check-ins per day for the current week, Monday first.
List<int> _weekActivity(Set<DateTime> days, DateTime today) {
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return List<int>.generate(7, (index) {
    final day = monday.add(Duration(days: index));
    return days.contains(day) ? 1 : 0;
  });
}

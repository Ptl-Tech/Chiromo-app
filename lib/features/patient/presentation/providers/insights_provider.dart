import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/activity_plan_model.dart';
import '../../data/models/checkin_model.dart';
import '../../data/models/thought_record_model.dart';
import 'activity_providers.dart';
import 'checkin_providers.dart';
import 'thought_providers.dart';
import 'wellbeing_stats_provider.dart';

/// Observations drawn from what the patient has actually recorded.
///
/// The Expo prototype had a "Key Insights" card whose three items were
/// hardcoded strings — "improved by 12% compared to last week" was a literal,
/// not a calculation. Three of those claims can be computed honestly from data
/// this app already holds; this file computes them, and the rules below are
/// what keep them from becoming the same thing in a more convincing costume.
///
/// Every insight is an observation, never advice and never a cause. "Your mood
/// averaged higher on days you did X" is something we can see. "Doing X will
/// lift your mood" is not, and a patient acting on the second because we
/// phrased the first that way is a harm this screen can do.
///
/// Each carries the number of entries behind it, shown to the reader. A pattern
/// over six days and one over sixty should not look alike, and only the reader
/// can weigh that.
///
/// The prototype's third claim — that checking in before 9 AM correlates with
/// lower anxiety — is deliberately not built. The cutoff is arbitrary, and the
/// days someone manages an early check-in differ from their other days in ways
/// that have nothing to do with the clock. There is no honest version of it.

/// Paired measurements — the same event scored twice — are far less noisy than
/// comparing two sets of days, so they clear at a lower count.
const int _kMinPaired = 4;

/// Comparing groups of days needs this many on each side before it is worth
/// putting in front of someone.
const int _kMinPerGroup = 5;

/// Differences smaller than this on a 0–10 scale are not distinguishable from
/// how the same person rates the same day twice.
const double _kMinPointDelta = 1.0;

/// Below this, a week-on-week move is drift rather than a change.
const double _kMinTrendPercent = 5.0;

enum InsightKind {
  activitySurprise,
  thoughtRecordDistress,
  moodTrend,
  thoughtRecordDays,
  sleepAndMood,
}

class Insight {
  final InsightKind kind;
  final String text;

  /// Whether the observation is a favourable one. Drives the tint only — an
  /// unfavourable pattern is still shown, because a tool that reports only
  /// good news is not reporting.
  final bool favourable;

  /// How many entries the figure rests on, in words ("9 records", "12 days").
  final String basis;

  const Insight({
    required this.kind,
    required this.text,
    required this.favourable,
    required this.basis,
  });
}

/// At most three, strongest evidence first.
///
/// The two paired comparisons lead because they measure the same event twice
/// and show whether the technique itself is doing anything. The correlational
/// ones come last because that is what they are worth.
final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final checkins = await ref.watch(checkinHistoryProvider.future);
  final sleepLogs = await ref.watch(sleepLogsProvider.future);
  final thoughts = await ref.watch(thoughtRecordsProvider.future);
  final activities = await ref.watch(activityPlansProvider.future);
  final stats = await ref.watch(wellbeingStatsProvider.future);

  final moodByDay = _meanMoodByDay(checkins);

  final found = <Insight?>[
    _activitySurprise(activities),
    _thoughtRecordDistress(thoughts),
    _moodTrend(stats),
    _thoughtRecordDays(thoughts, moodByDay),
    _sleepAndMood(sleepLogs, moodByDay),
  ];

  return found.whereType<Insight>().take(3).toList();
});

/// Behavioural activation's own measure: predicted enjoyment against what the
/// patient found. A persistent gap in either direction is the finding.
Insight? _activitySurprise(List<ActivityPlan> activities) {
  final surprises = <int>[];
  for (final plan in activities) {
    final surprise = plan.pleasureSurprise;
    if (plan.status != ActivityStatus.done || surprise == null) continue;
    surprises.add(surprise);
  }

  if (surprises.length < _kMinPaired) return null;

  final mean = _mean(surprises.map((s) => s.toDouble()));
  if (mean == null || mean.abs() < _kMinPointDelta) return null;

  final size = _oneDecimal(mean.abs());
  final count = surprises.length;

  return Insight(
    kind: InsightKind.activitySurprise,
    text: mean > 0
        ? 'Activities have turned out better than you expected — by $size '
              'points on average.'
        : 'Activities have been coming out $size points below what you '
              'expected, on average.',
    favourable: mean > 0,
    basis: '$count activities',
  );
}

/// Distress before working a thought through, against after.
Insight? _thoughtRecordDistress(List<ThoughtRecord> thoughts) {
  final drops = <double>[];
  for (final record in thoughts) {
    // Zero is this API's "not scored", so a record missing either end is left
    // out rather than counted as a ten-point drop to nothing.
    if (record.emotionBefore <= 0 || record.emotionAfter <= 0) continue;
    drops.add((record.emotionBefore - record.emotionAfter).toDouble());
  }

  if (drops.length < _kMinPaired) return null;

  final mean = _mean(drops);
  if (mean == null || mean.abs() < _kMinPointDelta) return null;

  final size = _oneDecimal(mean.abs());
  final count = drops.length;

  return Insight(
    kind: InsightKind.thoughtRecordDistress,
    text: mean > 0
        ? 'Working a thought through has left you $size points less '
              'distressed, on average.'
        : 'Your distress has been $size points higher after working a thought '
              'through than before it, on average.',
    favourable: mean > 0,
    basis: '$count records',
  );
}

/// The prototype's "improved by 12%", computed rather than typed.
Insight? _moodTrend(WellbeingStats stats) {
  final trend = stats.moodTrendPercent;
  if (trend == null || trend.abs() < _kMinTrendPercent) return null;

  final size = trend.abs().round();

  return Insight(
    kind: InsightKind.moodTrend,
    text: trend > 0
        ? 'Your average mood is $size% higher than the week before.'
        : 'Your average mood is $size% lower than the week before.',
    favourable: trend > 0,
    basis: 'last $kStatsWindowDays days vs the $kStatsWindowDays before',
  );
}

/// Mood on days a thought record was completed, against days none was.
///
/// Correlational and reported as such. Which days someone reaches for the tool
/// is not random, and the arrow could run either way.
Insight? _thoughtRecordDays(
  List<ThoughtRecord> thoughts,
  Map<DateTime, double> moodByDay,
) {
  final recordDays = <DateTime>{};
  for (final record in thoughts) {
    final at = record.recordedAt;
    if (at == null) continue;
    recordDays.add(DateTime(at.year, at.month, at.day));
  }

  final withRecord = <double>[];
  final without = <double>[];
  moodByDay.forEach((day, mood) {
    (recordDays.contains(day) ? withRecord : without).add(mood);
  });

  if (withRecord.length < _kMinPerGroup || without.length < _kMinPerGroup) {
    return null;
  }

  final a = _mean(withRecord)!;
  final b = _mean(without)!;
  if ((a - b).abs() < _kMinPointDelta) return null;

  return Insight(
    kind: InsightKind.thoughtRecordDays,
    text:
        'On days you completed a thought record your mood averaged '
        '${_oneDecimal(a)}, against ${_oneDecimal(b)} on the days you did not.',
    favourable: a > b,
    basis: '${withRecord.length} days vs ${without.length}',
  );
}

/// Mood after the patient's longer nights, against their shorter ones.
///
/// The split is their own median rather than a fixed number of hours, so this
/// compares someone against themselves instead of against a guideline.
Insight? _sleepAndMood(
  List<SleepLog> sleepLogs,
  Map<DateTime, double> moodByDay,
) {
  final paired = <({DateTime day, double hours, double mood})>[];
  for (final log in sleepLogs) {
    final date = log.date;
    if (date == null || log.hours <= 0) continue;
    final day = DateTime(date.year, date.month, date.day);
    final mood = moodByDay[day];
    if (mood == null) continue;
    paired.add((day: day, hours: log.hours, mood: mood));
  }

  if (paired.length < _kMinPerGroup * 2) return null;

  final hours = paired.map((p) => p.hours).toList()..sort();
  final median = hours[hours.length ~/ 2];

  final longer = <double>[];
  final shorter = <double>[];
  for (final entry in paired) {
    (entry.hours >= median ? longer : shorter).add(entry.mood);
  }

  // A patient who sleeps the same length every night lands everything on one
  // side of their own median. There is no comparison to draw.
  if (longer.length < _kMinPerGroup || shorter.length < _kMinPerGroup) {
    return null;
  }

  final a = _mean(longer)!;
  final b = _mean(shorter)!;
  if ((a - b).abs() < _kMinPointDelta) return null;

  return Insight(
    kind: InsightKind.sleepAndMood,
    text:
        'After your longer nights — ${_oneDecimal(median)} hours or more — '
        'your mood averaged ${_oneDecimal(a)}, against ${_oneDecimal(b)} '
        'after the shorter ones.',
    favourable: a > b,
    basis: '${longer.length} nights vs ${shorter.length}',
  );
}

/// One mood figure per day, averaging the days with more than one check-in.
///
/// Days that recorded no mood are absent rather than zero — the same rule the
/// mood chart follows.
Map<DateTime, double> _meanMoodByDay(List<Checkin> checkins) {
  final byDay = <DateTime, List<int>>{};

  for (final checkin in checkins) {
    final at = checkin.recordedAt;
    final rating = checkin.ratingFor(kMoodRatingCode);
    if (at == null || rating == null) continue;
    final day = DateTime(at.year, at.month, at.day);
    byDay.putIfAbsent(day, () => <int>[]).add(rating.value);
  }

  return byDay.map(
    (day, values) => MapEntry(day, _mean(values.map((v) => v.toDouble()))!),
  );
}

double? _mean(Iterable<double> values) {
  if (values.isEmpty) return null;
  var total = 0.0;
  var count = 0;
  for (final value in values) {
    total += value;
    count++;
  }
  return total / count;
}

String _oneDecimal(double value) => value.toStringAsFixed(1);

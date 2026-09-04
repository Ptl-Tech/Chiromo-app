/// Models for behavioural activation, mapping the Go API's `/activities`
/// responses.
///
/// The technique addresses a specific trap: motivation is expected to arrive
/// before action, and in depression it does not, so nothing gets done and the
/// flatness deepens. It breaks that by scheduling the activity anyway and then
/// comparing what was predicted against what was found — depressed prediction
/// is systematically pessimistic, and noticing that repeatedly is the point.
///
/// So the anticipated ratings are kept beside the actual ones rather than
/// replaced by them. An outcome alone cannot show the gap.
library;

const int kRatingMin = 0;
const int kRatingMax = 10;

/// Where a planned activity has got to.
enum ActivityStatus {
  planned('planned', 'Planned'),
  done('done', 'Done'),
  skipped('skipped', 'Did not happen');

  final String wireValue;
  final String label;

  const ActivityStatus(this.wireValue, this.label);

  static ActivityStatus fromJson(String? value) {
    for (final status in ActivityStatus.values) {
      if (status.wireValue == value) return status;
    }
    return ActivityStatus.planned;
  }
}

/// One activity the patient planned, and what happened when the time came.
class ActivityPlan {
  final int entryNo;
  final String activity;
  final DateTime? plannedAt;

  /// What the patient expected before doing it. Never rewritten afterwards —
  /// a prediction edited to match the outcome erases the only thing this
  /// record exists to show.
  final int anticipatedPleasure;
  final int anticipatedAchievement;

  final ActivityStatus status;
  final int actualPleasure;
  final int actualAchievement;
  final int moodBefore;
  final int moodAfter;

  /// Why it did not happen. Required when skipping, because what gets in the
  /// way is often more useful than the activities that went ahead.
  final String skipReason;

  final String notes;
  final bool shareWithDoctor;

  /// Actual minus anticipated, served by the API only once the activity is
  /// done. Null while it is still planned or was skipped — there is nothing to
  /// compare against.
  final int? pleasureSurprise;
  final int? achievementSurprise;

  const ActivityPlan({
    required this.entryNo,
    required this.activity,
    required this.status,
    this.plannedAt,
    this.anticipatedPleasure = 0,
    this.anticipatedAchievement = 0,
    this.actualPleasure = 0,
    this.actualAchievement = 0,
    this.moodBefore = 0,
    this.moodAfter = 0,
    this.skipReason = '',
    this.notes = '',
    this.shareWithDoctor = false,
    this.pleasureSurprise,
    this.achievementSurprise,
  });

  factory ActivityPlan.fromJson(Map<String, dynamic> json) {
    return ActivityPlan(
      entryNo: json['entryNo'] as int? ?? 0,
      activity: json['activity'] as String? ?? '',
      plannedAt: _parseDateTime(
        json['plannedDate'] as String?,
        json['plannedTime'] as String?,
      ),
      anticipatedPleasure: json['anticipatedPleasure'] as int? ?? 0,
      anticipatedAchievement: json['anticipatedAchievement'] as int? ?? 0,
      status: ActivityStatus.fromJson(json['status'] as String?),
      actualPleasure: json['actualPleasure'] as int? ?? 0,
      actualAchievement: json['actualAchievement'] as int? ?? 0,
      moodBefore: json['moodBefore'] as int? ?? 0,
      moodAfter: json['moodAfter'] as int? ?? 0,
      skipReason: json['skipReason'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      shareWithDoctor: json['shareWithDoctor'] as bool? ?? false,
      pleasureSurprise: json['pleasureSurprise'] as int?,
      achievementSurprise: json['achievementSurprise'] as int?,
    );
  }

  bool get isPlanned => status == ActivityStatus.planned;

  /// Whether this is still ahead of the patient and waiting to be done.
  bool get isUpcoming {
    if (!isPlanned) return false;
    final at = plannedAt;
    if (at == null) return true;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return !at.isBefore(startOfToday);
  }

  /// A planned activity whose day has passed without being marked either way.
  ///
  /// Surfaced rather than hidden: the prompt to say what happened — including
  /// that nothing did — is the part of the exercise that produces evidence,
  /// and an activity that quietly ages out produces none.
  bool get isOverdue => isPlanned && !isUpcoming;

  static DateTime? _parseDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    if (time == null || time.isEmpty) return day;

    final parts = time.split(':');
    if (parts.length < 2) return day;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

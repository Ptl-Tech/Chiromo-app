/// Models for the thought record, mapping the Go API's `/thoughts` responses.
///
/// A thought record takes a thought that arrived as a verdict — "I humiliated
/// myself in that meeting" — and demotes it to a hypothesis, then gathers
/// evidence about it the way a third party would. The reappraisal at the end
/// is meant to be what falls out of having looked, not an instruction to think
/// positively.
///
/// Evidence is a list of separate items, not two blocks of text, and that is
/// the whole design. Prose has a direction: "I froze and everyone noticed and
/// I always do this" reads as one coherent verdict, and is the same argument
/// the patient was already having with themselves. Split into items, most of
/// it stops being evidence at all — a generalisation, a prediction, an
/// interpretation — and the patient can see that for themselves.
library;

/// The rating scale for emotional intensity, fixed in Business Central.
const int kEmotionMin = 0;
const int kEmotionMax = 10;

/// Which side of the question a piece of evidence sits on.
enum EvidenceSide {
  forThought('for', 'Evidence for'),
  against('against', 'Evidence against');

  final String wireValue;
  final String label;

  const EvidenceSide(this.wireValue, this.label);

  static EvidenceSide fromJson(String? value) =>
      value == 'against' ? against : forThought;
}

/// One thing the patient noticed.
class Evidence {
  final int lineNo;
  final EvidenceSide side;
  final String text;

  const Evidence({required this.side, required this.text, this.lineNo = 0});

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      lineNo: json['lineNo'] as int? ?? 0,
      side: EvidenceSide.fromJson(json['side'] as String?),
      text: json['text'] as String? ?? '',
    );
  }

  /// Line numbers are not sent. BC assigns them by position, so the order the
  /// patient sees is the order stored and two items cannot collide.
  Map<String, dynamic> toRequestJson() => {
    'side': side.wireValue,
    'text': text,
  };
}

/// One worked-through thought.
class ThoughtRecord {
  final int entryNo;
  final DateTime? recordedAt;

  /// What happened, before any interpretation of it.
  final String situation;

  /// The thought as it arrived, in the patient's own words. Shown verbatim
  /// rather than tidied — the wording is the thing being examined.
  final String automaticThought;

  /// The named feeling. Free text, because the word someone reaches for is
  /// their own and a fixed list would make them pick the nearest available
  /// one instead.
  final String emotion;

  final int emotionBefore;
  final int emotionAfter;

  /// The reappraisal.
  final String balancedThought;

  final String notes;
  final bool shareWithDoctor;
  final List<Evidence> evidence;

  const ThoughtRecord({
    required this.entryNo,
    required this.automaticThought,
    this.recordedAt,
    this.situation = '',
    this.emotion = '',
    this.emotionBefore = 0,
    this.emotionAfter = 0,
    this.balancedThought = '',
    this.notes = '',
    this.shareWithDoctor = false,
    this.evidence = const [],
  });

  factory ThoughtRecord.fromJson(Map<String, dynamic> json) {
    final evidence = (json['evidence'] as List<dynamic>? ?? const [])
        .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
        .toList();

    return ThoughtRecord(
      entryNo: json['entryNo'] as int? ?? 0,
      recordedAt: _parseDateTime(
        json['date'] as String?,
        json['time'] as String?,
      ),
      situation: json['situation'] as String? ?? '',
      automaticThought: json['automaticThought'] as String? ?? '',
      emotion: json['emotion'] as String? ?? '',
      emotionBefore: json['emotionBefore'] as int? ?? 0,
      emotionAfter: json['emotionAfter'] as int? ?? 0,
      balancedThought: json['balancedThought'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      shareWithDoctor: json['shareWithDoctor'] as bool? ?? false,
      evidence: evidence,
    );
  }

  List<Evidence> get evidenceFor =>
      evidence.where((e) => e.side == EvidenceSide.forThought).toList();

  List<Evidence> get evidenceAgainst =>
      evidence.where((e) => e.side == EvidenceSide.against).toList();

  /// How far the intensity fell. Negative when it rose, which happens and is
  /// worth showing honestly rather than clamping to zero.
  int get shift => emotionBefore - emotionAfter;

  static DateTime? _parseDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final day = DateTime.tryParse(date);
    if (day == null) return null;
    if (time == null || time.isEmpty) return day;

    final parts = time.split(':');
    if (parts.length < 2) return day;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }
}

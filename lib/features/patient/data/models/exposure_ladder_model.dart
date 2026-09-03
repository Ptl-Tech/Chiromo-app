/// Models for the exposure ladder feature, mapping the Go API's `/exposure`
/// responses.
///
/// The template library is configuration, not code: Business Central decides
/// which starting-point ladders exist, what their rungs say, and in what order
/// they are offered. Adding "Driving Anxiety" in BC must make it appear here
/// without a release, so nothing in this file may hardcode a template.
///
/// A ladder's rungs are copied out of its template when it is created and
/// never rewritten afterwards, so a patient keeps the wording they started
/// with even if the clinic retunes the template later. That is why a ladder
/// carries its own steps rather than a pointer back to the template's.
library;

/// The subjective units of distress scale every rating in this feature uses.
/// It is fixed in Business Central, unlike the check-in scales, so unlike
/// those it is safe to name here.
const int kSudsMin = 0;
const int kSudsMax = 10;

/// One rung: what to do, roughly how hard it is expected to feel, and a short
/// note to read before starting.
class ExposureStep {
  final int rank;
  final String description;

  /// A starting point the form pre-fills, never a claim about what the patient
  /// will feel. What gets recorded is always their own rating from the trial.
  final int suggestedSuds;

  /// One short paragraph, deliberately not a checklist. Empty for a rung the
  /// patient wrote themselves — guidance comes from the clinic's templates.
  final String guidance;

  const ExposureStep({
    required this.rank,
    required this.description,
    this.suggestedSuds = 0,
    this.guidance = '',
  });

  factory ExposureStep.fromJson(Map<String, dynamic> json) {
    return ExposureStep(
      rank: json['rank'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      suggestedSuds: json['suggestedSuds'] as int? ?? 0,
      guidance: json['guidance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'rank': rank,
    'description': description,
    'suggestedSuds': suggestedSuds,
  };
}

/// One starting-point ladder from the clinic's library.
class ExposureTemplate {
  final String code;
  final String title;

  /// A single emoji chosen in BC. May be empty — the UI supplies a fallback
  /// rather than leaving a gap.
  final String icon;
  final int sequence;
  final List<ExposureStep> steps;

  const ExposureTemplate({
    required this.code,
    required this.title,
    this.icon = '',
    this.sequence = 0,
    this.steps = const [],
  });

  factory ExposureTemplate.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map((s) => ExposureStep.fromJson(s as Map<String, dynamic>))
        .toList();

    return ExposureTemplate(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 0,
      steps: steps,
    );
  }
}

/// One patient's ladder, with the rungs it was built with.
class ExposureLadder {
  final int entryNo;

  /// Blank when the patient wrote their own rungs.
  final String templateCode;

  /// The situation or goal, in the patient's own words.
  final String fear;

  /// Where the patient says they are. They move this themselves — nothing
  /// advances a ladder automatically, because readiness is a judgement a
  /// threshold rule would get wrong for somebody.
  final int currentStepRank;

  final bool shareWithDoctor;
  final DateTime? createdAt;
  final List<ExposureStep> steps;

  const ExposureLadder({
    required this.entryNo,
    required this.fear,
    required this.currentStepRank,
    this.templateCode = '',
    this.shareWithDoctor = false,
    this.createdAt,
    this.steps = const [],
  });

  factory ExposureLadder.fromJson(Map<String, dynamic> json) {
    final steps =
        (json['steps'] as List<dynamic>? ?? const [])
            .map((s) => ExposureStep.fromJson(s as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

    return ExposureLadder(
      entryNo: json['entryNo'] as int? ?? 0,
      templateCode: json['templateCode'] as String? ?? '',
      fear: json['fear'] as String? ?? '',
      currentStepRank: json['currentStepRank'] as int? ?? 0,
      shareWithDoctor: json['shareWithDoctor'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      steps: steps,
    );
  }

  /// The rung the patient is on, or null if the ladder has no steps.
  ///
  /// Falls back to the lowest rung rather than returning null when
  /// currentStepRank names one that is not there. That should not happen —
  /// BC points a new ladder at its real lowest rung — but a ladder the patient
  /// cannot open is a worse failure than one that opens at the bottom.
  ExposureStep? get currentStep {
    if (steps.isEmpty) return null;
    for (final step in steps) {
      if (step.rank == currentStepRank) return step;
    }
    return steps.first;
  }

  /// How far up the ladder the patient is, 0.0 to 1.0, for a progress bar.
  double get progress {
    if (steps.isEmpty) return 0;
    final position = steps.indexWhere((s) => s.rank == currentStepRank);
    if (position < 0) return 0;
    return (position + 1) / steps.length;
  }

  /// 1-based position of the current rung, for "Step 3 of 7".
  int get currentStepNumber {
    final position = steps.indexWhere((s) => s.rank == currentStepRank);
    return position < 0 ? 1 : position + 1;
  }

  /// The next rung up, or null when the patient is already at the top.
  ExposureStep? get nextStep {
    final position = steps.indexWhere((s) => s.rank == currentStepRank);
    if (position < 0 || position + 1 >= steps.length) return null;
    return steps[position + 1];
  }

  /// The rung below, or null at the bottom. Dropping back down is allowed —
  /// after a hard attempt it is often the right call.
  ExposureStep? get previousStep {
    final position = steps.indexWhere((s) => s.rank == currentStepRank);
    if (position <= 0) return null;
    return steps[position - 1];
  }
}

/// One logged attempt at a rung.
///
/// A rung is attempted as many times as it takes, so these accumulate rather
/// than replacing each other. That repetition is the point: the drop that
/// matters is the one across attempts, and it is invisible unless every
/// attempt is kept.
class ExposureTrial {
  final int entryNo;
  final int ladderEntryNo;
  final int stepRank;
  final DateTime? recordedAt;
  final int sudsBefore;
  final int sudsAfter;
  final String notes;

  const ExposureTrial({
    required this.entryNo,
    required this.ladderEntryNo,
    required this.stepRank,
    required this.sudsBefore,
    required this.sudsAfter,
    this.recordedAt,
    this.notes = '',
  });

  factory ExposureTrial.fromJson(Map<String, dynamic> json) {
    return ExposureTrial(
      entryNo: json['entryNo'] as int? ?? 0,
      ladderEntryNo: json['ladderEntryNo'] as int? ?? 0,
      stepRank: json['stepRank'] as int? ?? 0,
      sudsBefore: json['sudsBefore'] as int? ?? 0,
      sudsAfter: json['sudsAfter'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      recordedAt: _parseDateTime(
        json['date'] as String?,
        json['time'] as String?,
      ),
    );
  }

  /// How far the distress fell during the attempt. Negative when it rose,
  /// which happens and is worth showing honestly rather than clamping.
  int get drop => sudsBefore - sudsAfter;

  /// BC serves the date and time as separate fields. Either can be missing, so
  /// this returns null rather than inventing an epoch date that would sort a
  /// trial to 1970.
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

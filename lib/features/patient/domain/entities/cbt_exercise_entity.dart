/// The type of CBT exercise.
///
/// Daily check-ins used to live here as a fourth type. They are now a feature
/// in their own right, backed by Business Central rather than Supabase — see
/// `data/models/checkin_model.dart` and the `/checkins` endpoints.
enum CbtExerciseType {
  thoughtRecord,
  behavioralActivation,
  exposureLadder;

  String get value {
    switch (this) {
      case CbtExerciseType.thoughtRecord:
        return 'thought_record';
      case CbtExerciseType.behavioralActivation:
        return 'behavioral_activation';
      case CbtExerciseType.exposureLadder:
        return 'exposure_ladder';
    }
  }

  String get label {
    switch (this) {
      case CbtExerciseType.thoughtRecord:
        return 'Thought Record';
      case CbtExerciseType.behavioralActivation:
        return 'Behavioral Activation';
      case CbtExerciseType.exposureLadder:
        return 'Exposure Ladder';
    }
  }

  static CbtExerciseType fromString(String value) {
    switch (value) {
      case 'thought_record':
        return CbtExerciseType.thoughtRecord;
      case 'behavioral_activation':
        return CbtExerciseType.behavioralActivation;
      case 'exposure_ladder':
        return CbtExerciseType.exposureLadder;
      default:
        return CbtExerciseType.thoughtRecord;
    }
  }
}

/// Domain entity for a CBT exercise entry.
class CbtExerciseEntity {
  final String id;
  final String patientId;
  final CbtExerciseType type;
  final String? title;
  final Map<String, dynamic> data;
  final bool isShared;
  final bool hasDoctorFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CbtExerciseEntity({
    required this.id,
    required this.patientId,
    required this.type,
    this.title,
    required this.data,
    required this.isShared,
    required this.hasDoctorFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Thought Record helpers ──
  String? get situation => data['situation'] as String?;
  String? get automaticThought => data['automatic_thought'] as String?;
  String? get emotion => data['emotion'] as String?;
  String? get evidenceFor => data['evidence_for'] as String?;
  String? get evidenceAgainst => data['evidence_against'] as String?;
  String? get balancedThought => data['balanced_thought'] as String?;
  int? get reliefPercent => data['relief_percent'] as int?;
  int? get anxietyBefore => data['anxiety_before'] as int?;
  int? get anxietyAfter => data['anxiety_after'] as int?;

  // ── Behavioral Activation helpers ──
  String? get activity => data['activity'] as String?;
  int? get moodLift => data['mood_lift'] as int?;
  int? get streak => data['streak'] as int?;

  // ── Exposure Ladder helpers ──
  String? get fear => data['fear'] as String?;
  int? get currentStep => data['current_step'] as int?;
  int? get totalSteps => data['total_steps'] as int?;
  List<String> get steps =>
      (data['steps'] as List<dynamic>?)?.cast<String>() ?? [];
}

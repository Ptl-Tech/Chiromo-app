import '../../domain/entities/cbt_exercise_entity.dart';

/// Data model for CBT exercises with Supabase JSON serialisation.
class CbtExerciseModel extends CbtExerciseEntity {
  const CbtExerciseModel({
    required super.id,
    required super.patientId,
    required super.type,
    super.title,
    required super.data,
    required super.isShared,
    required super.hasDoctorFeedback,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CbtExerciseModel.fromJson(Map<String, dynamic> json) {
    return CbtExerciseModel(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      type: CbtExerciseType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isShared: json['is_shared'] as bool? ?? false,
      hasDoctorFeedback: json['has_doctor_feedback'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'patient_id': patientId,
      'type': type.value,
      'title': title,
      'data': data,
      'is_shared': isShared,
      'has_doctor_feedback': hasDoctorFeedback,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'data': data,
      'is_shared': isShared,
      'has_doctor_feedback': hasDoctorFeedback,
    };
  }

  /// Convert any [CbtExerciseEntity] to a model.
  factory CbtExerciseModel.fromEntity(CbtExerciseEntity entity) {
    return CbtExerciseModel(
      id: entity.id,
      patientId: entity.patientId,
      type: entity.type,
      title: entity.title,
      data: entity.data,
      isShared: entity.isShared,
      hasDoctorFeedback: entity.hasDoctorFeedback,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

import '../../domain/entities/safety_plan_entity.dart';

class SafetyPlanModel extends SafetyPlanEntity {
  const SafetyPlanModel({
    required super.id,
    required super.patientId,
    super.warningSigns,
    super.copingStrategies,
    super.reasonsToLive,
    super.professionalContacts,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SafetyPlanModel.fromJson(Map<String, dynamic> json) {
    return SafetyPlanModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      warningSigns: json['warning_signs'] as String?,
      copingStrategies: json['coping_strategies'] as String?,
      reasonsToLive: json['reasons_to_live'] as String?,
      professionalContacts: json['professional_contacts'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'warning_signs': warningSigns,
      'coping_strategies': copingStrategies,
      'reasons_to_live': reasonsToLive,
      'professional_contacts': professionalContacts,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SafetyPlanModel.fromEntity(SafetyPlanEntity entity) {
    return SafetyPlanModel(
      id: entity.id,
      patientId: entity.patientId,
      warningSigns: entity.warningSigns,
      copingStrategies: entity.copingStrategies,
      reasonsToLive: entity.reasonsToLive,
      professionalContacts: entity.professionalContacts,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

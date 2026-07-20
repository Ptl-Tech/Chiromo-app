import '../../domain/entities/diagnosis_entity.dart';

class DiagnosisModel extends DiagnosisEntity {
  const DiagnosisModel({
    required super.id,
    required super.medicalRecordId,
    super.icd10Code,
    required super.description,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String,
      medicalRecordId: json['medical_record_id'] as String,
      icd10Code: json['icd_10_code'] as String?,
      description: json['description'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'icd_10_code': icd10Code,
      'description': description,
      'notes': notes,
    };
  }
}

import '../../domain/entities/prescription_entity.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required super.id,
    required super.medicalRecordId,
    required super.medicationName,
    required super.dosage,
    required super.frequency,
    required super.durationDays,
    super.instructions,
    required super.isDispensed,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String,
      medicalRecordId: json['medical_record_id'] as String,
      medicationName: json['medication_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      durationDays: json['duration_days'] as int,
      instructions: json['instructions'] as String?,
      isDispensed: json['is_dispensed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medical_record_id': medicalRecordId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration_days': durationDays,
      'instructions': instructions,
    };
  }
}

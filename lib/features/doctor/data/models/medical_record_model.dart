import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordModel extends MedicalRecordEntity {
  const MedicalRecordModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    super.appointmentId,
    super.chiefComplaint,
    super.clinicalNotes,
    super.bloodPressure,
    super.heartRate,
    super.temperature,
    super.weight,
    super.height,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      chiefComplaint: json['chief_complaint'] as String?,
      clinicalNotes: json['clinical_notes'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      heartRate: json['heart_rate'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_id': appointmentId,
      'chief_complaint': chiefComplaint,
      'clinical_notes': clinicalNotes,
      'blood_pressure': bloodPressure,
      'heart_rate': heartRate,
      'temperature': temperature,
      'weight': weight,
      'height': height,
    };
  }
}

import '../../domain/entities/emergency_contact_entity.dart';

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({
    required super.id,
    required super.patientId,
    required super.name,
    required super.phoneNumber,
    super.relationship,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyContactModel.fromEntity(EmergencyContactEntity entity) {
    return EmergencyContactModel(
      id: entity.id,
      patientId: entity.patientId,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      relationship: entity.relationship,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

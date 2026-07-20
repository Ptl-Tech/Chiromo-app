import '../../domain/entities/referral_entity.dart';
import 'package:chiromo/features/auth/data/models/user_model.dart';
import 'package:chiromo/features/doctor/data/models/doctor_model.dart';

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.id,
    required super.patientId,
    required super.referringDoctorId,
    required super.referredDoctorId,
    required super.reason,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.patient,
    super.referringDoctor,
    super.referredDoctor,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      referringDoctorId: json['referring_doctor_id'] as String,
      referredDoctorId: json['referred_doctor_id'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      patient: json['patient'] != null ? UserModel.fromJson(json['patient']).toEntity() : null,
      referringDoctor: json['referring_doctor'] != null ? DoctorModel.fromJson(json['referring_doctor']).toEntity() : null,
      referredDoctor: json['referred_doctor'] != null ? DoctorModel.fromJson(json['referred_doctor']).toEntity() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'referring_doctor_id': referringDoctorId,
      'referred_doctor_id': referredDoctorId,
      'reason': reason,
      'status': status,
    };
  }

  ReferralEntity toEntity() => ReferralEntity(
    id: id,
    patientId: patientId,
    referringDoctorId: referringDoctorId,
    referredDoctorId: referredDoctorId,
    reason: reason,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    patient: patient,
    referringDoctor: referringDoctor,
    referredDoctor: referredDoctor,
  );
}

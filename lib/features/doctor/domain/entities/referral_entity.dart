import 'package:chiromo/features/auth/domain/entities/user_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/doctor_entity.dart';

class ReferralEntity {
  final String id;
  final String patientId;
  final String referringDoctorId;
  final String referredDoctorId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  final UserEntity? patient;
  final DoctorEntity? referringDoctor;
  final DoctorEntity? referredDoctor;

  const ReferralEntity({
    required this.id,
    required this.patientId,
    required this.referringDoctorId,
    required this.referredDoctorId,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.patient,
    this.referringDoctor,
    this.referredDoctor,
  });
}

import 'package:chiromo/features/auth/domain/entities/user_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/doctor_entity.dart';

/// Represents an appointment in the domain layer.
class AppointmentEntity {
  final String id;
  final String patientId;
  final String doctorId;
  final String branchId;
  final DateTime scheduledAt;
  final String status;
  final String type;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRated;

  // Optional relations
  final UserEntity? patient;
  final DoctorEntity? doctor;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.branchId,
    required this.scheduledAt,
    required this.status,
    required this.type,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isRated = false,
    this.patient,
    this.doctor,
  });
}

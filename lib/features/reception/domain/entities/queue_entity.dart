import '../../../auth/domain/entities/user_entity.dart';
import '../../../doctor/domain/entities/doctor_entity.dart';

class QueueEntity {
  final String id;
  final String patientId;
  final String? appointmentId;
  final String? branchId;
  final String? assignedDoctorId;
  final String status;
  final DateTime checkInTime;
  final String? notes;
  final UserEntity? patient;
  final DoctorEntity? doctor;

  const QueueEntity({
    required this.id,
    required this.patientId,
    this.appointmentId,
    this.branchId,
    this.assignedDoctorId,
    required this.status,
    required this.checkInTime,
    this.notes,
    this.patient,
    this.doctor,
  });
}

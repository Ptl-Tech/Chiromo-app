import '../../domain/entities/queue_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../doctor/data/models/doctor_model.dart';

class QueueModel {
  final String id;
  final String patientId;
  final String? appointmentId;
  final String? branchId;
  final String? assignedDoctorId;
  final String status;
  final DateTime checkInTime;
  final String? notes;
  final UserModel? patient;
  final DoctorModel? doctor;

  const QueueModel({
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

  factory QueueModel.fromJson(Map<String, dynamic> json) {
    return QueueModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      branchId: json['branch_id'] as String?,
      assignedDoctorId: json['assigned_doctor_id'] as String?,
      status: json['status'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      notes: json['notes'] as String?,
      patient: json['patient'] != null ? UserModel.fromJson(json['patient']) : null,
      doctor: json['doctor'] != null ? DoctorModel.fromJson(json['doctor']) : null,
    );
  }

  QueueEntity toEntity() {
    return QueueEntity(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      branchId: branchId,
      assignedDoctorId: assignedDoctorId,
      status: status,
      checkInTime: checkInTime,
      notes: notes,
      patient: patient?.toEntity(),
      doctor: doctor?.toEntity(),
    );
  }
}

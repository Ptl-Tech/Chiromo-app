import 'package:chiromo/features/auth/data/models/user_model.dart';
import '../../domain/entities/appointment_entity.dart';
import 'package:chiromo/features/doctor/data/models/doctor_model.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String? branchId;
  final DateTime scheduledAt;
  final String status;
  final String type;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? patient;
  final DoctorModel? doctor;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.branchId,
    required this.scheduledAt,
    required this.status,
    required this.type,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.patient,
    this.doctor,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      branchId: json['branch_id'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: json['status'] as String,
      type: json['type'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      patient: json['patient'] != null
          ? UserModel.fromJson(json['patient'])
          : null,
      doctor: json['doctor'] != null
          ? DoctorModel.fromJson(json['doctor'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'branch_id': branchId,
    'scheduled_at': scheduledAt.toIso8601String(),
    'status': status,
    'type': type,
    'notes': notes,
  }..removeWhere((key, value) => value == null);

  AppointmentEntity toEntity() => AppointmentEntity(
    id: id,
    patientId: patientId,
    doctorId: doctorId,
    branchId: branchId ?? '',
    scheduledAt: scheduledAt,
    status: status,
    type: type,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
    patient: patient?.toEntity(),
    doctor: doctor?.toEntity(),
  );
}

import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppointmentEntity>> getDoctorAppointments(String doctorId) async {
    final models = await remoteDataSource.getAppointmentsByDoctor(doctorId);
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<AppointmentEntity>> getDoctorAppointmentsForDate(String doctorId, DateTime date) async {
    final models = await remoteDataSource.getDoctorAppointmentsForDate(doctorId, date);
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<AppointmentEntity>> getPatientAppointments(
    String patientId,
  ) async {
    final models = await remoteDataSource.getAppointmentsByPatient(patientId);
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<AppointmentEntity> bookAppointment(
    AppointmentModel appointment,
  ) async {
    final model = await remoteDataSource.createAppointment(appointment);
    return model.toEntity();
  }

  @override
  Future<AppointmentEntity> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    final model = await remoteDataSource.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );
    return model.toEntity();
  }

  @override
  Future<AppointmentEntity> updateAppointment(
    String appointmentId, {
    String? status,
    DateTime? scheduledAt,
    String? doctorId,
  }) async {
    final model = await remoteDataSource.updateAppointment(
      appointmentId,
      status: status,
      scheduledAt: scheduledAt,
      doctorId: doctorId,
    );
    return model.toEntity();
  }
}

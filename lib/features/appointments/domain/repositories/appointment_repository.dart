import '../entities/appointment_entity.dart';
import 'package:chiromo/features/appointments/data/models/appointment_model.dart';

abstract class AppointmentRepository {
  /// Fetch all appointments for a specific patient.
  Future<List<AppointmentEntity>> getPatientAppointments(String patientId);

  /// Fetch all appointments for a specific doctor.
  Future<List<AppointmentEntity>> getDoctorAppointments(String doctorId);

  /// Fetch all appointments for a specific doctor on a specific date.
  Future<List<AppointmentEntity>> getDoctorAppointmentsForDate(String doctorId, DateTime date);

  /// Book a new appointment.
  Future<AppointmentEntity> bookAppointment(AppointmentModel appointment);

  /// Update the status of an appointment.
  Future<AppointmentEntity> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  );

  /// Update an appointment with new fields such as status, scheduled date/time, or doctor.
  Future<AppointmentEntity> updateAppointment(
    String appointmentId, {
    String? status,
    DateTime? scheduledAt,
    String? doctorId,
  });
}

import '../../../../core/services/supabase_service.dart';
import '../models/appointment_model.dart';

class AppointmentRemoteDataSource {
  final _client = SupabaseService.client;

  Future<List<AppointmentModel>> getAppointmentsByPatient(
    String patientId,
  ) async {
    final response = await _client
        .from('appointments')
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .eq('patient_id', patientId)
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }

  Future<List<AppointmentModel>> getAppointmentsByDoctor(
    String doctorId,
  ) async {
    final response = await _client
        .from('appointments')
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .eq('doctor_id', doctorId)
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }

  Future<List<AppointmentModel>> getDoctorAppointmentsForDate(
    String doctorId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

    final response = await _client
        .from('appointments')
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .eq('doctor_id', doctorId)
        .gte('scheduled_at', startOfDay)
        .lte('scheduled_at', endOfDay)
        .order('scheduled_at', ascending: true);

    return (response as List)
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }

  Future<AppointmentModel> createAppointment(
    AppointmentModel appointment,
  ) async {
    final Map<String, dynamic> data = {
      'patient_id': appointment.patientId,
      'doctor_id': appointment.doctorId,
      'branch_id': appointment.branchId == null || appointment.branchId!.isEmpty
          ? null
          : appointment.branchId,
      'scheduled_at': appointment.scheduledAt.toIso8601String(),
      'status': appointment.status,
      'type': appointment.type,
      'notes': appointment.notes,
    };

    // We remove the nulls for the insert to avoid issues if branchId is truly null
    data.removeWhere((key, value) => value == null);

    final response = await _client
        .from('appointments')
        .insert(data)
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .single();

    return AppointmentModel.fromJson(response);
  }

  Future<AppointmentModel> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    final response = await _client
        .from('appointments')
        .update({'status': status})
        .eq('id', appointmentId)
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .single();

    return AppointmentModel.fromJson(response);
  }

  Future<AppointmentModel> updateAppointment(
    String appointmentId, {
    String? status,
    DateTime? scheduledAt,
    String? doctorId,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (scheduledAt != null) {
      data['scheduled_at'] = scheduledAt.toIso8601String();
    }
    if (doctorId != null) data['doctor_id'] = doctorId;
    if (data.isEmpty) {
      throw ArgumentError(
        'At least one field must be provided to update an appointment.',
      );
    }

    final response = await _client
        .from('appointments')
        .update(data)
        .eq('id', appointmentId)
        .select(
          '*, doctor:doctors(*, profiles(*)), patient:profiles!appointments_patient_id_fkey(*)',
        )
        .single();

    return AppointmentModel.fromJson(response);
  }
}

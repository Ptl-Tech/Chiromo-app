import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/queue_model.dart';

class ReceptionRemoteDataSource {
  final SupabaseClient _client;

  ReceptionRemoteDataSource(this._client);

  Future<List<QueueModel>> getQueue() async {
    final response = await _client
        .from('queues')
        .select('''
          *,
          patient:profiles!patient_id(*),
          doctor:doctors!assigned_doctor_id(
            *,
            profiles!user_id(*)
          )
        ''')
        .order('check_in_time', ascending: true);

    return (response as List).map((e) => QueueModel.fromJson(e)).toList();
  }

  Future<QueueModel> addToQueue({
    required String patientId,
    String? appointmentId,
    String? branchId,
    String? assignedDoctorId,
    String? notes,
  }) async {
    final response = await _client.from('queues').insert({
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'branch_id': branchId,
      'assigned_doctor_id': assignedDoctorId,
      'notes': notes,
      'status': 'waiting',
    }).select('''
          *,
          patient:profiles!patient_id(*),
          doctor:doctors!assigned_doctor_id(
            *,
            profiles!user_id(*)
          )
        ''').single();

    return QueueModel.fromJson(response);
  }

  Future<void> updateQueueStatus(String queueId, String status) async {
    await _client.from('queues').update({'status': status}).eq('id', queueId);
  }
}

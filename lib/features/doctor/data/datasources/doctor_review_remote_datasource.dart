import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor_review_model.dart';

class DoctorReviewRemoteDataSource {
  final SupabaseClient _client;

  DoctorReviewRemoteDataSource(this._client);

  Future<DoctorReviewModel> createReview(DoctorReviewModel model) async {
    final data = model.toJson();
    if (data['id'] == null || data['id'] == '') {
      data.remove('id');
    }

    final response = await _client
        .from('doctor_reviews')
        .insert(data)
        .select()
        .single();

    return DoctorReviewModel.fromJson(response);
  }

  Future<DoctorReviewModel?> getReviewForAppointment(String appointmentId) async {
    final response = await _client
        .from('doctor_reviews')
        .select()
        .eq('appointment_id', appointmentId)
        .maybeSingle();

    if (response == null) return null;
    return DoctorReviewModel.fromJson(response);
  }
}

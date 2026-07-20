import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cbt_exercise_model.dart';

/// Remote data source for CBT exercises using Supabase.
class CbtRemoteDataSource {
  final SupabaseClient _client;

  CbtRemoteDataSource(this._client);

  Future<List<CbtExerciseModel>> getExercises(String patientId) async {
    final response = await _client
        .from('cbt_exercises')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CbtExerciseModel.fromJson(json))
        .toList();
  }

  Future<CbtExerciseModel> createExercise(CbtExerciseModel model) async {
    final response = await _client
        .from('cbt_exercises')
        .insert(model.toInsertJson())
        .select()
        .single();

    return CbtExerciseModel.fromJson(response);
  }

  Future<CbtExerciseModel> updateExercise(CbtExerciseModel model) async {
    final response = await _client
        .from('cbt_exercises')
        .update(model.toUpdateJson())
        .eq('id', model.id)
        .select()
        .single();

    return CbtExerciseModel.fromJson(response);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _client.from('cbt_exercises').delete().eq('id', exerciseId);
  }
}

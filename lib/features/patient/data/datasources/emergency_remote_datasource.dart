import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/safety_plan_model.dart';
import '../models/emergency_contact_model.dart';

class EmergencyRemoteDataSource {
  final SupabaseClient _client;

  EmergencyRemoteDataSource(this._client);

  // --- Safety Plan ---

  Future<SafetyPlanModel?> getSafetyPlan(String patientId) async {
    final response = await _client
        .from('safety_plans')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (response == null) return null;
    return SafetyPlanModel.fromJson(response);
  }

  Future<SafetyPlanModel> upsertSafetyPlan(SafetyPlanModel model) async {
    final Map<String, dynamic> data = model.toJson();
    // Remove id if we are creating a new one and it's empty, 
    // or let Supabase handle it if we are using an upsert that relies on patient_id constraint.
    // The migration has UNIQUE(patient_id) on safety_plans.
    // We can use upsert on patient_id constraint.
    
    // We don't want to pass 'id' if it's empty to allow uuid_generate_v4()
    if (data['id'] == null || data['id'] == '') {
      data.remove('id');
    }

    final response = await _client
        .from('safety_plans')
        .upsert(data, onConflict: 'patient_id')
        .select()
        .single();

    return SafetyPlanModel.fromJson(response);
  }

  // --- Emergency Contacts ---

  Future<List<EmergencyContactModel>> getEmergencyContacts(String patientId) async {
    final response = await _client
        .from('emergency_contacts')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => EmergencyContactModel.fromJson(json))
        .toList();
  }

  Future<EmergencyContactModel> createEmergencyContact(EmergencyContactModel model) async {
    final data = model.toJson();
    if (data['id'] == null || data['id'] == '') {
      data.remove('id');
    }

    final response = await _client
        .from('emergency_contacts')
        .insert(data)
        .select()
        .single();

    return EmergencyContactModel.fromJson(response);
  }

  Future<EmergencyContactModel> updateEmergencyContact(EmergencyContactModel model) async {
    final response = await _client
        .from('emergency_contacts')
        .update(model.toJson())
        .eq('id', model.id)
        .select()
        .single();

    return EmergencyContactModel.fromJson(response);
  }

  Future<void> deleteEmergencyContact(String id) async {
    await _client.from('emergency_contacts').delete().eq('id', id);
  }
}

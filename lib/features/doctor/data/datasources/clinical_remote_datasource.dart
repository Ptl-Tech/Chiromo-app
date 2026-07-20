import 'package:chiromo/core/services/supabase_service.dart';
import 'package:chiromo/features/doctor/data/models/medical_record_model.dart';
import 'package:chiromo/features/doctor/data/models/prescription_model.dart';
import 'package:chiromo/features/doctor/data/models/referral_model.dart';

class ClinicalRemoteDataSource {
  final _client = SupabaseService.client;

  Future<List<MedicalRecordModel>> getPatientMedicalRecords(String patientId) async {
    final response = await _client
        .from('medical_records')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => MedicalRecordModel.fromJson(json)).toList();
  }

  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    final response = await _client
        .from('prescriptions')
        .select('*, medical_records!inner(patient_id)')
        .eq('medical_records.patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => PrescriptionModel.fromJson(json)).toList();
  }

  Future<ReferralModel> createReferral(ReferralModel referral) async {
    final data = referral.toJson();
    final response = await _client
        .from('referrals')
        .insert(data)
        .select('*, patient:profiles!referrals_patient_id_fkey(*), referring_doctor:doctors!referrals_referring_doctor_id_fkey(*, profiles(*)), referred_doctor:doctors!referrals_referred_doctor_id_fkey(*, profiles(*))')
        .single();

    return ReferralModel.fromJson(response);
  }
}

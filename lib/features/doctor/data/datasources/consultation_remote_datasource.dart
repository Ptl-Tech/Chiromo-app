import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_record_model.dart';
import '../models/diagnosis_model.dart';
import '../models/prescription_model.dart';

class ConsultationRemoteDataSource {
  final SupabaseClient _supabase;

  ConsultationRemoteDataSource(this._supabase);

  Future<MedicalRecordModel> createMedicalRecord(MedicalRecordModel record) async {
    final data = await _supabase
        .from('medical_records')
        .insert(record.toJson())
        .select()
        .single();
    return MedicalRecordModel.fromJson(data);
  }

  Future<void> addDiagnoses(List<DiagnosisModel> diagnoses) async {
    if (diagnoses.isEmpty) return;
    final jsonList = diagnoses.map((d) => d.toJson()).toList();
    await _supabase.from('diagnoses').insert(jsonList);
  }

  Future<void> addPrescriptions(List<PrescriptionModel> prescriptions) async {
    if (prescriptions.isEmpty) return;
    final jsonList = prescriptions.map((p) => p.toJson()).toList();
    await _supabase.from('prescriptions').insert(jsonList);
  }

  Future<List<MedicalRecordModel>> getPatientHistory(String patientId) async {
    final data = await _supabase
        .from('medical_records')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return data.map((json) => MedicalRecordModel.fromJson(json)).toList();
  }

  Future<List<DiagnosisModel>> getRecordDiagnoses(String recordId) async {
    final data = await _supabase
        .from('diagnoses')
        .select()
        .eq('medical_record_id', recordId);
    return data.map((json) => DiagnosisModel.fromJson(json)).toList();
  }

  Future<List<PrescriptionModel>> getRecordPrescriptions(String recordId) async {
    final data = await _supabase
        .from('prescriptions')
        .select()
        .eq('medical_record_id', recordId);
    return data.map((json) => PrescriptionModel.fromJson(json)).toList();
  }
}

import '../entities/medical_record_entity.dart';
import '../entities/diagnosis_entity.dart';
import '../entities/prescription_entity.dart';

abstract class ConsultationRepository {
  Future<MedicalRecordEntity> createMedicalRecord(MedicalRecordEntity record);
  Future<void> addDiagnoses(List<DiagnosisEntity> diagnoses);
  Future<void> addPrescriptions(List<PrescriptionEntity> prescriptions);
  Future<List<MedicalRecordEntity>> getPatientHistory(String patientId);
  Future<List<DiagnosisEntity>> getRecordDiagnoses(String recordId);
  Future<List<PrescriptionEntity>> getRecordPrescriptions(String recordId);
}

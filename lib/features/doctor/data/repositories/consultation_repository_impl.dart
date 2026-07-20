import '../../domain/entities/medical_record_entity.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../datasources/consultation_remote_datasource.dart';
import '../models/medical_record_model.dart';
import '../models/diagnosis_model.dart';
import '../models/prescription_model.dart';

class ConsultationRepositoryImpl implements ConsultationRepository {
  final ConsultationRemoteDataSource remoteDataSource;

  ConsultationRepositoryImpl(this.remoteDataSource);

  @override
  Future<MedicalRecordEntity> createMedicalRecord(MedicalRecordEntity record) async {
    final model = MedicalRecordModel(
      id: record.id,
      patientId: record.patientId,
      doctorId: record.doctorId,
      appointmentId: record.appointmentId,
      chiefComplaint: record.chiefComplaint,
      clinicalNotes: record.clinicalNotes,
      bloodPressure: record.bloodPressure,
      heartRate: record.heartRate,
      temperature: record.temperature,
      weight: record.weight,
      height: record.height,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
    return await remoteDataSource.createMedicalRecord(model);
  }

  @override
  Future<void> addDiagnoses(List<DiagnosisEntity> diagnoses) async {
    final models = diagnoses.map((d) => DiagnosisModel(
      id: d.id,
      medicalRecordId: d.medicalRecordId,
      icd10Code: d.icd10Code,
      description: d.description,
      notes: d.notes,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
    )).toList();
    return await remoteDataSource.addDiagnoses(models);
  }

  @override
  Future<void> addPrescriptions(List<PrescriptionEntity> prescriptions) async {
    final models = prescriptions.map((p) => PrescriptionModel(
      id: p.id,
      medicalRecordId: p.medicalRecordId,
      medicationName: p.medicationName,
      dosage: p.dosage,
      frequency: p.frequency,
      durationDays: p.durationDays,
      instructions: p.instructions,
      isDispensed: p.isDispensed,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    )).toList();
    return await remoteDataSource.addPrescriptions(models);
  }

  @override
  Future<List<MedicalRecordEntity>> getPatientHistory(String patientId) async {
    return await remoteDataSource.getPatientHistory(patientId);
  }

  @override
  Future<List<DiagnosisEntity>> getRecordDiagnoses(String recordId) async {
    return await remoteDataSource.getRecordDiagnoses(recordId);
  }

  @override
  Future<List<PrescriptionEntity>> getRecordPrescriptions(String recordId) async {
    return await remoteDataSource.getRecordPrescriptions(recordId);
  }
}

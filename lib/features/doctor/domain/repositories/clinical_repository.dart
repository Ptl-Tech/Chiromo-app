import 'package:chiromo/features/doctor/domain/entities/medical_record_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/prescription_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/referral_entity.dart';
import 'package:chiromo/features/doctor/data/models/referral_model.dart';

abstract class ClinicalRepository {
  /// Fetch all medical records for a specific patient
  Future<List<MedicalRecordEntity>> getPatientMedicalRecords(String patientId);

  /// Fetch all prescriptions for a specific patient
  Future<List<PrescriptionEntity>> getPatientPrescriptions(String patientId);
  
  /// Create a new referral
  Future<ReferralEntity> createReferral(ReferralModel referral);
}

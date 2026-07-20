import 'package:chiromo/features/doctor/domain/entities/medical_record_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/prescription_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/referral_entity.dart';
import 'package:chiromo/features/doctor/domain/repositories/clinical_repository.dart';
import 'package:chiromo/features/doctor/data/datasources/clinical_remote_datasource.dart';
import 'package:chiromo/features/doctor/data/models/referral_model.dart';

class ClinicalRepositoryImpl implements ClinicalRepository {
  final ClinicalRemoteDataSource remoteDataSource;

  ClinicalRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<MedicalRecordEntity>> getPatientMedicalRecords(String patientId) async {
    final models = await remoteDataSource.getPatientMedicalRecords(patientId);
    return models;
  }

  @override
  Future<List<PrescriptionEntity>> getPatientPrescriptions(String patientId) async {
    final models = await remoteDataSource.getPatientPrescriptions(patientId);
    return models;
  }

  @override
  Future<ReferralEntity> createReferral(ReferralModel referral) async {
    final model = await remoteDataSource.createReferral(referral);
    return model.toEntity();
  }
}

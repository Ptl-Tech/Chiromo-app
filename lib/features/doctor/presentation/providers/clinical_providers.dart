import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chiromo/features/auth/presentation/providers/auth_providers.dart';
import 'package:chiromo/features/doctor/domain/entities/medical_record_entity.dart';
import 'package:chiromo/features/doctor/domain/entities/prescription_entity.dart';
import 'package:chiromo/features/doctor/domain/repositories/clinical_repository.dart';
import 'package:chiromo/features/doctor/data/datasources/clinical_remote_datasource.dart';
import 'package:chiromo/features/doctor/data/repositories/clinical_repository_impl.dart';

final clinicalRemoteDataSourceProvider = Provider<ClinicalRemoteDataSource>((ref) {
  return ClinicalRemoteDataSource();
});

final clinicalRepositoryProvider = Provider<ClinicalRepository>((ref) {
  final dataSource = ref.watch(clinicalRemoteDataSourceProvider);
  return ClinicalRepositoryImpl(dataSource);
});

final patientMedicalRecordsProvider = FutureProvider<List<MedicalRecordEntity>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final repository = ref.watch(clinicalRepositoryProvider);
  return repository.getPatientMedicalRecords(user.id);
});

final patientPrescriptionsProvider = FutureProvider<List<PrescriptionEntity>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final repository = ref.watch(clinicalRepositoryProvider);
  return repository.getPatientPrescriptions(user.id);
});

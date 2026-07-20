import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/consultation_remote_datasource.dart';
import '../../data/repositories/consultation_repository_impl.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../../domain/entities/medical_record_entity.dart';

// Repository Provider
final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  final supabase = SupabaseService.client;
  final remoteDataSource = ConsultationRemoteDataSource(supabase);
  return ConsultationRepositoryImpl(remoteDataSource);
});

// Patient History Provider
final patientMedicalHistoryProvider = FutureProvider.family<List<MedicalRecordEntity>, String>((ref, patientId) async {
  final repository = ref.read(consultationRepositoryProvider);
  return repository.getPatientHistory(patientId);
});
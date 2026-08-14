import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/doctor_review_remote_datasource.dart';
import '../../data/repositories/doctor_review_repository_impl.dart';
import '../../domain/repositories/doctor_review_repository.dart';

/// Provides the [DoctorReviewRepository] instance.
final doctorReviewRepositoryProvider = Provider<DoctorReviewRepository>((ref) {
  final client = SupabaseService.client;
  return DoctorReviewRepositoryImpl(DoctorReviewRemoteDataSource(client));
});

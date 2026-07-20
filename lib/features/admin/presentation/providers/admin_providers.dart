import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/analytics_data_entity.dart';
import '../../domain/repositories/admin_repository.dart';

/// Provides the [AdminRepository] singleton.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = SupabaseService.client;
  return AdminRepositoryImpl(AdminRemoteDataSource(client));
});

/// Fetches all hospital branches.
final branchesProvider =
    FutureProvider<List<BranchEntity>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getBranches();
});

/// Fetches executive analytics data (revenue, departments).
final analyticsProvider =
    FutureProvider<AnalyticsDataEntity>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAnalyticsData();
});

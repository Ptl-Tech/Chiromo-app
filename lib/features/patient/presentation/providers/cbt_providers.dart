import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/cbt_remote_datasource.dart';
import '../../data/repositories/cbt_repository_impl.dart';
import '../../domain/entities/cbt_exercise_entity.dart';
import '../../domain/repositories/cbt_repository.dart';

/// Provides the [CbtRepository] instance.
final cbtRepositoryProvider = Provider<CbtRepository>((ref) {
  final client = SupabaseService.client;
  return CbtRepositoryImpl(CbtRemoteDataSource(client));
});

/// Fetches all CBT exercises for the currently logged-in patient.
final cbtExercisesProvider =
    FutureProvider<List<CbtExerciseEntity>>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(cbtRepositoryProvider);
  return repo.getExercises(user.id);
});

/// Filtered view: recent progress entries (last 10, newest first).
final cbtRecentProgressProvider =
    FutureProvider<List<CbtExerciseEntity>>((ref) async {
  final exercises = await ref.watch(cbtExercisesProvider.future);
  final sorted = List<CbtExerciseEntity>.from(exercises)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(10).toList();
});

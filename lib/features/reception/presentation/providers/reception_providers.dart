import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/queue_entity.dart';
import '../../domain/repositories/reception_repository.dart';
import '../../data/datasources/reception_remote_datasource.dart';
import '../../data/repositories/reception_repository_impl.dart';

final receptionRepositoryProvider = Provider<ReceptionRepository>((ref) {
  final client = SupabaseService.client;
  return ReceptionRepositoryImpl(ReceptionRemoteDataSource(client));
});

final currentQueueProvider = FutureProvider<List<QueueEntity>>((ref) async {
  final repo = ref.watch(receptionRepositoryProvider);
  return repo.getQueue();
});

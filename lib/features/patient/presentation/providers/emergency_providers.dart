import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/emergency_remote_datasource.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/entities/safety_plan_entity.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_repository.dart';

/// Provides the [EmergencyRepository] instance.
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final client = SupabaseService.client;
  return EmergencyRepositoryImpl(EmergencyRemoteDataSource(client));
});

/// Fetches the Safety Plan for the currently logged-in patient.
final safetyPlanProvider = FutureProvider<SafetyPlanEntity?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;

  final repo = ref.watch(emergencyRepositoryProvider);
  return repo.getSafetyPlan(user.id);
});

/// Fetches the Emergency Contacts for the currently logged-in patient.
final emergencyContactsProvider = FutureProvider<List<EmergencyContactEntity>>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(emergencyRepositoryProvider);
  return repo.getEmergencyContacts(user.id);
});

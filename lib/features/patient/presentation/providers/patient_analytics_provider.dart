import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/patient_analytics_datasource.dart';
import '../../domain/entities/patient_analytics_entity.dart';

/// Provides the [PatientAnalyticsDataSource] singleton.
final patientAnalyticsDataSourceProvider = Provider<PatientAnalyticsDataSource>(
  (ref) {
    final client = SupabaseService.client;
    return PatientAnalyticsDataSource(client);
  },
);

/// Fetches personal analytics data for the logged-in patient.
///
/// If auth is still resolving, we avoid throwing so the analytics tab does not
/// trigger the yellow error banner while the app is booting.
final patientAnalyticsProvider = FutureProvider<PatientAnalyticsEntity>((
  ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.valueOrNull;
  final dataSource = ref.watch(patientAnalyticsDataSourceProvider);

  final patientId = user?.id ?? 'guest-user';
  return dataSource.getPatientAnalytics(patientId);
});

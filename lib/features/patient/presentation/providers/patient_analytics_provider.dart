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
final patientAnalyticsProvider = FutureProvider<PatientAnalyticsEntity>((
  ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  final dataSource = ref.watch(patientAnalyticsDataSourceProvider);
  return dataSource.getPatientAnalytics(user.id);
});

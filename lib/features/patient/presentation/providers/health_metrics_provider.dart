import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';

/// Simple data model for a health metric.
class HealthMetric {
  final String id;
  final String type; // e.g., 'steps', 'blood_pressure', 'heart_rate'
  final double value;
  final DateTime recordedAt;

  HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    required this.recordedAt,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) => HealthMetric(
    id: json['id'] as String,
    type: json['type'] as String,
    value: (json['value'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recorded_at'] as String),
  );
}

/// Provider that fetches a list of health metrics for the current patient.
final healthMetricsProvider = FutureProvider.autoDispose<List<HealthMetric>>((ref) async {
  // Use the authStateProvider to get the current authenticated user
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final client = SupabaseService.client;
  // Explicitly select required columns
  final data = await client
      .from('health_metrics')
      .select('id, type, value, recorded_at')
      .eq('patient_id', user.id)
      .order('recorded_at', ascending: false);

  // Debug logging (only in debug mode)
  if (kDebugMode) {
    print('Fetched ${data.length} health metric rows for patient ${user.id}');
  }

  return (data as List<dynamic>)
      .map((e) => HealthMetric.fromJson(e as Map<String, dynamic>))
      .toList();
});

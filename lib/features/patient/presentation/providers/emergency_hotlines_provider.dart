import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/emergency_hotline_entity.dart';

final emergencyHotlinesProvider = FutureProvider<List<EmergencyHotlineEntity>>((ref) async {
  final response = await SupabaseService.client
      .from('emergency_hotlines')
      .select()
      .eq('is_active', true)
      .order('sort_order', ascending: true);

  return (response as List).map((e) => EmergencyHotlineEntity.fromJson(e)).toList();
});

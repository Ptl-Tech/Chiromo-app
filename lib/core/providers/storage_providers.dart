import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(SupabaseService.client);
});

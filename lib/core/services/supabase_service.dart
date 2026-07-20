import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around [Supabase] to centralise configuration and
/// provide convenient getters used by all data-sources.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialise Supabase – call once in main().
  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  // ── Quick accessors ───────────────────────────────────────────
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

  /// Current authenticated user (nullable).
  static User? get currentUser => auth.currentUser;

  /// Current session (nullable).
  static Session? get currentSession => auth.currentSession;

  /// Stream of auth state changes.
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;
}

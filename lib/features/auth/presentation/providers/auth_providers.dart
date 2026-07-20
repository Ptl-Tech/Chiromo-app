import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Holds the current authenticated [UserEntity] or null.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Notifier for imperative auth actions (sign-in, sign-up, etc.).
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
      return AuthNotifier(ref.watch(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null)) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithMagicLink(email);
      state = const AsyncValue.data(null); // waiting for redirect
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repo.resetPassword(email);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  void updateCurrentUser(UserEntity user) {
    state = AsyncValue.data(user);
  }

  /// Refresh the current user profile from the repository (useful after admin/upstream changes).
  Future<void> refreshCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

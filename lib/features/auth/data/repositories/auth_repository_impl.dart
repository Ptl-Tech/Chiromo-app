import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

Map<String, dynamic> buildProfileUpsertPayload({
  required String userId,
  String? firstName,
  String? lastName,
  String? phone,
  String? avatarUrl,
  String? role,
  String? bio,
}) {
  final payload = <String, dynamic>{'id': userId};

  final normalizedFirstName = firstName?.trim();
  if (normalizedFirstName != null && normalizedFirstName.isNotEmpty) {
    payload['first_name'] = normalizedFirstName;
  }

  final normalizedLastName = lastName?.trim();
  if (normalizedLastName != null && normalizedLastName.isNotEmpty) {
    payload['last_name'] = normalizedLastName;
  }

  final normalizedPhone = phone?.trim();
  if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
    payload['phone_number'] = normalizedPhone;
  }

  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    payload['avatar_url'] = avatarUrl;
  }

  final normalizedBio = bio?.trim();
  if (normalizedBio != null && normalizedBio.isNotEmpty) {
    payload['bio'] = normalizedBio;
  }

  payload['role'] = role ?? 'patient';
  return payload;
}

/// Supabase-backed implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final _auth = SupabaseService.auth;
  final _client = SupabaseService.client;

  // ── helpers ───────────────────────────────────────────────────
  Future<UserEntity> _fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      await _client
          .from('profiles')
          .upsert(buildProfileUpsertPayload(userId: userId), onConflict: 'id');

      final createdRow = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(createdRow).toEntity();
    }

    return UserModel.fromJson(row).toEntity();
  }

  // ── email / password ──────────────────────────────────────────
  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    final res = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _fetchProfile(res.user!.id);
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    // Split full name into first/last for the DB trigger
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName, 'last_name': lastName, 'role': 'patient'},
    );
    final userId = res.user!.id;
    debugPrint('✅ New patient user created with ID: $userId');

    await _client
        .from('profiles')
        .upsert(
          buildProfileUpsertPayload(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            role: 'patient',
          ),
          onConflict: 'id',
        );

    return _fetchProfile(userId);
  }

  // ── magic link ────────────────────────────────────────────────
  @override
  Future<void> signInWithMagicLink(String email) async {
    await _auth.signInWithOtp(email: email);
  }

  // ── google ────────────────────────────────────────────────────
  @override
  Future<UserEntity> signInWithGoogle() async {
    await _auth.signInWithOAuth(OAuthProvider.google);
    // After redirect the session is available; fetch profile.
    final userId = _auth.currentUser!.id;
    return _fetchProfile(userId);
  }

  // ── OTP ───────────────────────────────────────────────────────
  @override
  Future<void> sendOtp(String phone) async {
    await _auth.signInWithOtp(phone: phone);
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final res = await _auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    return _fetchProfile(res.user!.id);
  }

  // ── password reset ────────────────────────────────────────────
  @override
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to update profile for.');
    }

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone_number'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (bio != null) updates['bio'] = bio;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', user.id);
    }

    return _fetchProfile(user.id);
  }

  // ── sign out ──────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── current user ──────────────────────────────────────────────
  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  // ── stream ────────────────────────────────────────────────────
  @override
  Stream<UserEntity?> get authStateChanges =>
      _auth.onAuthStateChange.asyncMap((state) async {
        final user = state.session?.user;
        if (user == null) return null;
        return _fetchProfile(user.id);
      });
}

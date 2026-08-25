import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Thrown by [AuthRepositoryImpl] for operations the Business Central API
/// doesn't (yet) support, so the existing AsyncError-driven UI can surface a
/// clean, user-facing message instead of a stack trace.
class AuthFeatureUnavailableException implements Exception {
  final String message;
  AuthFeatureUnavailableException(this.message);

  @override
  String toString() => message;
}

/// Business-Central-backed implementation of [AuthRepository]. Talks to the
/// custom Go API (see hospital-app-api) instead of Supabase Auth.
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    try {
      final res = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final token = res.data['token'] as String;
      await TokenService.saveToken(token);

      // Fetch the canonical profile after storing the token. The login
      // response can contain stale or reduced user details.
      final currentUser = await getCurrentUser();
      if (currentUser != null) return currentUser;

      return UserModel.fromJson(
        res.data['user'] as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (e) {
      throw Exception(_messageFrom(e, 'Unable to sign in. Please try again.'));
    }
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : firstName;

    try {
      await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'password': password,
          'confirmPassword': password,
          'phoneNumber': phone,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        _messageFrom(e, 'Unable to create your account. Please try again.'),
      );
    }
  }

  @override
  Future<void> signInWithMagicLink(String email) async {
    throw AuthFeatureUnavailableException(
      'Magic link sign-in is not available yet.',
    );
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    throw AuthFeatureUnavailableException(
      'Google sign-in is not available yet.',
    );
  }

  @override
  Future<void> sendOtp(String phone) async {
    throw AuthFeatureUnavailableException(
      'Phone sign-in is not available yet.',
    );
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    throw AuthFeatureUnavailableException(
      'Phone sign-in is not available yet.',
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _dio.post('/api/v1/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(
        _messageFrom(e, 'Unable to send the reset code. Please try again.'),
      );
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/reset-password',
        data: {
          'email': email,
          'otpCode': otpCode,
          'password': newPassword,
          'confirmPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        _messageFrom(
          e,
          'Unable to reset your password. Please check the code and try again.',
        ),
      );
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    throw AuthFeatureUnavailableException(
      'Changing your password from within the app isn\'t available yet — use "Forgot password" instead.',
    );
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
    throw AuthFeatureUnavailableException(
      'Profile editing is not available yet with the new authentication system.',
    );
  }

  @override
  Future<void> signOut() async {
    await TokenService.deleteToken();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final res = await _dio.get('/api/v1/auth/me');
      final data = res.data['success']['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await TokenService.deleteToken();
      }
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => Stream.fromFuture(getCurrentUser());
}

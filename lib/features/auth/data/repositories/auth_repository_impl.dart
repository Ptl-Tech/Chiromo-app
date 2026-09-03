import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/token_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Thrown by [AuthRepositoryImpl] for operations the Business Central API
/// doesn't (yet) support, so the existing AsyncError-driven UI can surface a
/// clean, user-facing message instead of a stack trace.
/// An auth operation that failed with a message worth showing the user —
/// usually the API's own wording, extracted from the error envelope.
///
/// [toString] returns the bare message so screens that interpolate the error
/// into a banner or snackbar don't leak a "Exception: " prefix.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

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
      throw AuthException(
        _messageFrom(e, 'Unable to sign in. Please try again.'),
      );
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
      throw AuthException(
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
      throw AuthException(
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
      throw AuthException(
        _messageFrom(
          e,
          'Unable to reset your password. Please check the code and try again.',
        ),
      );
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, 'Unable to change your password. Please try again.'),
      );
    }
  }

  @override
  Future<void> sendVerificationOtp(String email) async {
    try {
      await _dio.post(
        '/api/v1/auth/send-verification-otp',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(
          e,
          'Unable to send the verification code. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    try {
      await _dio.post(
        '/api/v1/auth/verify-email',
        data: {'email': email, 'otpCode': otpCode},
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(
          e,
          'Unable to verify your email. Please check the code and try again.',
        ),
      );
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? gender,
    String? idNumber,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    // Only send what the caller actually supplied — the API treats an absent
    // key as "leave unchanged" and an empty string as "clear this field".
    final payload = <String, dynamic>{
      'firstName': ?firstName,
      'middleName': ?middleName,
      'lastName': ?lastName,
      'phoneNumber': ?phone,
      'gender': ?gender,
      'idNumber': ?idNumber,
      'avatarUrl': ?avatarUrl,
      'bio': ?bio,
      if (dateOfBirth != null) 'dateOfBirth': _formatDate(dateOfBirth),
    };

    try {
      final res = await _dio.patch('/api/v1/auth/me', data: payload);
      final data = res.data['success']['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data).toEntity();
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, 'Unable to update your profile. Please try again.'),
      );
    }
  }

  @override
  Future<void> deactivateAccount() async {
    try {
      await _dio.delete('/api/v1/auth/me');
    } on DioException catch (e) {
      throw AuthException(
        _messageFrom(e, 'Unable to deactivate your account. Please try again.'),
      );
    }
    // The account can no longer sign in, so the stored token is dead weight.
    await TokenService.deleteToken();
  }

  /// Business Central parses dates as YYYY-MM-DD.
  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
  Stream<UserEntity?> get authStateChanges =>
      Stream.fromFuture(getCurrentUser());
}

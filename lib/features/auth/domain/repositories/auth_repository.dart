import '../entities/user_entity.dart';

/// Contract for authentication operations.
/// Implemented by [AuthRepositoryImpl] in the data layer.
abstract class AuthRepository {
  /// Sign in with email and password.
  Future<UserEntity> signInWithEmail(String email, String password);

  /// Register with email and password. Business Central does not log the
  /// user in on registration — they must verify their email and sign in
  /// separately, so this returns nothing on success.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  /// Send a magic link to the given email.
  Future<void> signInWithMagicLink(String email);

  /// Sign in with Google OAuth.
  Future<UserEntity> signInWithGoogle();

  /// Send OTP to phone number.
  Future<void> sendOtp(String phone);

  /// Verify OTP.
  Future<UserEntity> verifyOtp(String phone, String otp);

  /// Request a password-reset OTP be emailed to [email].
  Future<void> resetPassword(String email);

  /// Apply a password-reset OTP previously sent via [resetPassword].
  Future<void> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  /// Change the signed-in user's password. Unlike [confirmPasswordReset]
  /// this proves identity with the current password rather than an OTP.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Ask the API to email an OTP for verifying [email].
  Future<void> sendVerificationOtp(String email);

  /// Confirm an email address with the OTP sent by [sendVerificationOtp].
  Future<void> verifyEmail({required String email, required String otpCode});

  /// Partially update the current user's profile and return the saved result.
  ///
  /// A null argument leaves that field untouched; an empty string clears it.
  /// Email is not editable here — it is the identity the API issues tokens
  /// against.
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
  });

  /// Deactivate the current user's account and sign them out. The Business
  /// Central record is retained — clinical history references it — but it can
  /// no longer be used to sign in.
  Future<void> deactivateAccount();

  /// Sign out the current user.
  Future<void> signOut();

  /// Get the currently authenticated user profile, or null.
  Future<UserEntity?> getCurrentUser();

  /// Stream of auth state changes mapped to [UserEntity].
  Stream<UserEntity?> get authStateChanges;
}

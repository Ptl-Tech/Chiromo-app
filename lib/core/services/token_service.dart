import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages JWT token persistence using secure storage.
///
/// This service is shared across all features that migrate to the
/// custom API. It wraps [FlutterSecureStorage] so callers never
/// interact with the storage layer directly.
class TokenService {
  TokenService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  /// Persist a JWT token securely.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve the stored JWT token, or `null` if none exists.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Remove the stored JWT token (e.g. on logout).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Check whether a token is currently stored.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

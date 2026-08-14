import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'token_service.dart';

/// Centralised HTTP client backed by [Dio].
///
/// Provides a pre-configured [Dio] instance with:
/// - Base URL from [AppConstants.apiBaseUrl]
/// - Automatic JWT injection via an interceptor
/// - Logging in debug builds
///
/// Usage:
/// ```dart
/// final response = await ApiService.dio.get('/doctors');
/// ```
class ApiService {
  ApiService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode) _LogInterceptor(),
    ]);

  /// The shared [Dio] instance — use this for all API calls.
  static Dio get dio => _dio;
}

// ── Auth Interceptor ────────────────────────────────────────────────
/// Reads the JWT from [TokenService] and attaches it as a Bearer token.
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If the server returns 401 we could trigger a logout / token-refresh
    // flow here in a future phase.
    handler.next(err);
  }
}

// ── Log Interceptor (debug only) ────────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✖ ${err.type} ${err.message}');
    handler.next(err);
  }
}

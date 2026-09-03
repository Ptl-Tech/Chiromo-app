import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/clinical_model.dart';

/// Thrown when a clinical call fails with a message worth showing the user.
/// [toString] returns the bare message so screens can interpolate it without
/// leaking an "Exception: " prefix.
class ClinicalException implements Exception {
  final String message;
  ClinicalException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's clinical endpoints, which are backed by Business
/// Central.
///
/// Read-only by design. Both records are authored by the clinician responsible
/// for them, and there is no endpoint to change either.
class ClinicalRemoteDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// Notes the patient's doctors have written for them, newest first.
  Future<List<VisitNote>> getVisitNotes() async {
    try {
      final res = await _dio.get('/api/v1/clinical/notes');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((n) => VisitNote.fromJson(n as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ClinicalException(
        _messageFrom(e, 'Unable to load your notes from the clinic.'),
      );
    }
  }

  /// The medication list the patient's doctors maintain.
  Future<List<Medication>> getMedications() async {
    try {
      final res = await _dio.get('/api/v1/clinical/medications');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((m) => Medication.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ClinicalException(
        _messageFrom(e, 'Unable to load your medications.'),
      );
    }
  }
}

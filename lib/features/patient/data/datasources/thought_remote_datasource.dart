import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/thought_record_model.dart';

/// Thrown when a thought record call fails with a message worth showing the
/// user. [toString] returns the bare message so screens can interpolate it
/// without leaking an "Exception: " prefix.
class ThoughtException implements Exception {
  final String message;
  ThoughtException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's thought record endpoints, backed by Business Central.
class ThoughtRemoteDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// The patient's worked-through thoughts, newest first.
  Future<List<ThoughtRecord>> getThoughtRecords() async {
    try {
      final res = await _dio.get('/api/v1/thoughts');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((r) => ThoughtRecord.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ThoughtException(
        _messageFrom(e, 'Unable to load your thought records.'),
      );
    }
  }

  /// Records a thought record, or corrects one when [entryNo] is supplied.
  ///
  /// [recordedAt] is sent explicitly rather than left to the server: BC stamps
  /// defaults in its own timezone, which would misdate a late-night entry for
  /// a patient several hours ahead of the server.
  Future<int> saveThoughtRecord({
    int? entryNo,
    required DateTime recordedAt,
    required String situation,
    required String automaticThought,
    required String emotion,
    required int emotionBefore,
    required int emotionAfter,
    required String balancedThought,
    String notes = '',
    bool shareWithDoctor = false,
    List<Evidence> evidence = const [],
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/thoughts',
        data: {
          'entryNo': ?entryNo,
          'date': formatDate(recordedAt),
          'time': formatTime(recordedAt),
          'situation': situation,
          'automaticThought': automaticThought,
          'emotion': emotion,
          'emotionBefore': emotionBefore,
          'emotionAfter': emotionAfter,
          'balancedThought': balancedThought,
          'notes': notes,
          'shareWithDoctor': shareWithDoctor,
          'evidence': evidence.map((e) => e.toRequestJson()).toList(),
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw ThoughtException(
        _messageFrom(e, 'Unable to save that thought record.'),
      );
    }
  }

  Future<void> deleteThoughtRecord(int entryNo) async {
    try {
      await _dio.delete('/api/v1/thoughts/$entryNo');
    } on DioException catch (e) {
      throw ThoughtException(
        _messageFrom(e, 'Unable to delete that thought record.'),
      );
    }
  }

  /// Business Central parses dates as YYYY-MM-DD.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Business Central parses times as HH:MM:SS.
  static String formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';
}

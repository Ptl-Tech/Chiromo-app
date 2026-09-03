import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/checkin_model.dart';

/// Thrown when a check-in call fails with a message worth showing the user —
/// usually the API's own wording. [toString] returns the bare message so
/// screens can interpolate it without leaking an "Exception: " prefix.
class CheckinException implements Exception {
  final String message;
  CheckinException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's wellbeing check-in endpoints, which are backed by
/// Business Central rather than Supabase.
class CheckinRemoteDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// The scales to render. Driven entirely by BC configuration.
  Future<List<RatingType>> getRatingTypes() async {
    try {
      final res = await _dio.get('/api/v1/checkins/rating-types');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((t) => RatingType.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CheckinException(
        _messageFrom(e, 'Unable to load the check-in questions.'),
      );
    }
  }

  /// Check-in history, newest first. [from] and [to] narrow it to a window.
  Future<List<Checkin>> getCheckins({DateTime? from, DateTime? to}) async {
    try {
      final res = await _dio.get(
        '/api/v1/checkins',
        queryParameters: {
          if (from != null) 'from': formatDate(from),
          if (to != null) 'to': formatDate(to),
        },
      );
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((c) => Checkin.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CheckinException(_messageFrom(e, 'Unable to load your check-ins.'));
    }
  }

  /// Records a check-in, or corrects one when [entryNo] is supplied.
  ///
  /// [recordedAt] is sent explicitly rather than left to the server: BC stamps
  /// defaults in its own timezone, which would misdate a late-night entry for
  /// a patient several hours ahead of the server.
  Future<int> saveCheckin({
    int? entryNo,
    required DateTime recordedAt,
    required String notes,
    required bool shareWithDoctor,
    required List<Rating> ratings,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/checkins',
        data: {
          'entryNo': ?entryNo,
          'date': formatDate(recordedAt),
          'time': formatTime(recordedAt),
          'notes': notes,
          'shareWithDoctor': shareWithDoctor,
          'ratings': ratings.map((r) => r.toRequestJson()).toList(),
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw CheckinException(
        _messageFrom(e, 'Unable to save your check-in. Please try again.'),
      );
    }
  }

  Future<void> deleteCheckin(int entryNo) async {
    try {
      await _dio.delete('/api/v1/checkins/$entryNo');
    } on DioException catch (e) {
      throw CheckinException(
        _messageFrom(e, 'Unable to delete that check-in.'),
      );
    }
  }

  /// Nightly sleep durations, newest first.
  Future<List<SleepLog>> getSleepLogs({DateTime? from, DateTime? to}) async {
    try {
      final res = await _dio.get(
        '/api/v1/sleep',
        queryParameters: {
          if (from != null) 'from': formatDate(from),
          if (to != null) 'to': formatDate(to),
        },
      );
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((s) => SleepLog.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw CheckinException(_messageFrom(e, 'Unable to load your sleep log.'));
    }
  }

  /// Records a night's sleep. One entry per date — re-saving replaces it.
  Future<void> saveSleepLog({
    required DateTime date,
    required double hours,
    String notes = '',
    bool shareWithDoctor = false,
  }) async {
    try {
      await _dio.put(
        '/api/v1/sleep',
        data: {
          'date': formatDate(date),
          'hours': hours,
          'notes': notes,
          'shareWithDoctor': shareWithDoctor,
        },
      );
    } on DioException catch (e) {
      throw CheckinException(
        _messageFrom(e, 'Unable to save your sleep hours.'),
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

import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/activity_plan_model.dart';

/// Thrown when an activity call fails with a message worth showing the user.
class ActivityException implements Exception {
  final String message;
  ActivityException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's behavioural activation endpoints, backed by Business
/// Central.
class ActivityRemoteDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<List<ActivityPlan>> getActivityPlans() async {
    try {
      final res = await _dio.get('/api/v1/activities');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((a) => ActivityPlan.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ActivityException(
        _messageFrom(e, 'Unable to load your activities.'),
      );
    }
  }

  /// Plans an activity, or records how one turned out when [entryNo] is given.
  ///
  /// One call for both halves — the status and the actual ratings are more
  /// fields on the same record, and a second write path would be a second way
  /// for it to disagree with itself.
  Future<int> saveActivityPlan({
    int? entryNo,
    required String activity,
    required DateTime plannedAt,
    bool includeTime = false,
    int anticipatedPleasure = 0,
    int anticipatedAchievement = 0,
    ActivityStatus status = ActivityStatus.planned,
    int actualPleasure = 0,
    int actualAchievement = 0,
    int moodBefore = 0,
    int moodAfter = 0,
    String skipReason = '',
    String notes = '',
    bool shareWithDoctor = false,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/activities',
        data: {
          'entryNo': ?entryNo,
          'activity': activity,
          'plannedDate': formatDate(plannedAt),
          'plannedTime': includeTime ? formatTime(plannedAt) : '',
          'anticipatedPleasure': anticipatedPleasure,
          'anticipatedAchievement': anticipatedAchievement,
          'status': status.wireValue,
          'actualPleasure': actualPleasure,
          'actualAchievement': actualAchievement,
          'moodBefore': moodBefore,
          'moodAfter': moodAfter,
          'skipReason': skipReason,
          'notes': notes,
          'shareWithDoctor': shareWithDoctor,
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw ActivityException(_messageFrom(e, 'Unable to save that activity.'));
    }
  }

  Future<void> deleteActivityPlan(int entryNo) async {
    try {
      await _dio.delete('/api/v1/activities/$entryNo');
    } on DioException catch (e) {
      throw ActivityException(
        _messageFrom(e, 'Unable to delete that activity.'),
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

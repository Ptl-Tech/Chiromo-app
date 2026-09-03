import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/exposure_ladder_model.dart';

/// Thrown when an exposure ladder call fails with a message worth showing the
/// user — usually the API's own wording, which names the offending step or
/// field. [toString] returns the bare message so screens can interpolate it
/// without leaking an "Exception: " prefix.
class ExposureException implements Exception {
  final String message;
  ExposureException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's exposure ladder endpoints, which are backed by
/// Business Central rather than Supabase.
class ExposureRemoteDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// The clinic's library of starting-point ladders. Driven entirely by BC
  /// configuration — the app renders whatever comes back and hardcodes none
  /// of it.
  Future<List<ExposureTemplate>> getTemplates() async {
    try {
      final res = await _dio.get('/api/v1/exposure/templates');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((t) => ExposureTemplate.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExposureException(
        _messageFrom(e, 'Unable to load the ladder templates.'),
      );
    }
  }

  /// The patient's own ladders, newest first, each with its rungs.
  Future<List<ExposureLadder>> getLadders() async {
    try {
      final res = await _dio.get('/api/v1/exposure/ladders');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((l) => ExposureLadder.fromJson(l as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExposureException(_messageFrom(e, 'Unable to load your ladders.'));
    }
  }

  /// Logged attempts, newest first. [ladderEntryNo] narrows them to one
  /// ladder, which is how a rung's recent history is drawn.
  Future<List<ExposureTrial>> getTrials({int? ladderEntryNo}) async {
    try {
      final res = await _dio.get(
        '/api/v1/exposure/trials',
        queryParameters: {'ladder': ?ladderEntryNo},
      );
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((t) => ExposureTrial.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExposureException(
        _messageFrom(e, 'Unable to load your logged sessions.'),
      );
    }
  }

  /// Starts a ladder, either from a template or from the patient's own steps.
  ///
  /// Exactly one of [templateCode] and [steps] is sent — the API rejects a
  /// request carrying both rather than silently preferring one, since guessing
  /// wrong builds a ladder the patient did not ask for.
  Future<int> createLadder({
    String? templateCode,
    required String fear,
    List<ExposureStep> steps = const [],
    bool shareWithDoctor = false,
  }) async {
    final usingTemplate = templateCode != null && templateCode.isNotEmpty;

    try {
      final res = await _dio.post(
        '/api/v1/exposure/ladders',
        data: {
          if (usingTemplate) 'templateCode': templateCode,
          'fear': fear,
          if (!usingTemplate)
            'steps': steps.map((s) => s.toRequestJson()).toList(),
          'shareWithDoctor': shareWithDoctor,
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw ExposureException(
        _messageFrom(e, 'Unable to create that ladder. Please try again.'),
      );
    }
  }

  /// Moves a ladder to a different rung. Moving down is allowed as well as up.
  Future<void> setCurrentStep({
    required int ladderEntryNo,
    required int stepRank,
  }) async {
    try {
      await _dio.patch(
        '/api/v1/exposure/ladders/$ladderEntryNo/step',
        data: {'stepRank': stepRank},
      );
    } on DioException catch (e) {
      throw ExposureException(_messageFrom(e, 'Unable to change your step.'));
    }
  }

  /// Records one attempt at a rung.
  ///
  /// [recordedAt] is sent explicitly rather than left to the server: BC stamps
  /// defaults in its own timezone, which would misdate a late-evening session
  /// for a patient several hours ahead of the server.
  Future<int> logTrial({
    required int ladderEntryNo,
    required int stepRank,
    required DateTime recordedAt,
    required int sudsBefore,
    required int sudsAfter,
    String notes = '',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/exposure/ladders/$ladderEntryNo/trials',
        data: {
          'stepRank': stepRank,
          'date': formatDate(recordedAt),
          'time': formatTime(recordedAt),
          'sudsBefore': sudsBefore,
          'sudsAfter': sudsAfter,
          'notes': notes,
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw ExposureException(
        _messageFrom(e, 'Unable to save that session. Please try again.'),
      );
    }
  }

  /// Removes a ladder, its rungs and everything logged against it.
  Future<void> deleteLadder(int ladderEntryNo) async {
    try {
      await _dio.delete('/api/v1/exposure/ladders/$ladderEntryNo');
    } on DioException catch (e) {
      throw ExposureException(_messageFrom(e, 'Unable to delete that ladder.'));
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

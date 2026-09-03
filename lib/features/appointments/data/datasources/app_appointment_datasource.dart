import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../models/app_appointment_model.dart';

/// Thrown when an appointment call fails with a message worth showing the
/// user — usually the API's own wording, which for a booking is often Business
/// Central explaining why the slot could not be taken. [toString] returns the
/// bare message so screens can interpolate it without an "Exception: " prefix.
class AppointmentException implements Exception {
  final String message;
  AppointmentException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Go API's appointment endpoints, which are backed by Business
/// Central rather than Supabase.
///
/// This covers the patient's own requests only — raising one, listing them,
/// withdrawing one. The doctor and reception views run on a different dataset
/// and are not served here.
class AppAppointmentDataSource {
  final Dio _dio = ApiService.dio;

  String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// The patient's own requests.
  Future<List<AppAppointment>> getAppointments() async {
    try {
      final res = await _dio.get('/api/v1/appointments');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((a) => AppAppointment.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppointmentException(
        _messageFrom(e, 'Unable to load your appointments.'),
      );
    }
  }

  /// Doctors bookable in a date window, each with the slots they have free.
  ///
  /// A window is always sent rather than asking for everything: the diary is
  /// large, and a patient booking is always thinking about the next week or
  /// two, not the next year.
  Future<List<AvailableDoctor>> getAvailability({
    DateTime? from,
    DateTime? to,
    String? branch,
  }) async {
    try {
      final res = await _dio.get(
        '/api/v1/appointments/availability',
        queryParameters: {
          if (from != null) 'from': formatDate(from),
          if (to != null) 'to': formatDate(to),
          'branch': ?branch,
        },
      );
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((d) => AvailableDoctor.fromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppointmentException(
        _messageFrom(e, 'Unable to load doctor availability.'),
      );
    }
  }

  /// The kinds of appointment the clinic offers.
  Future<List<AppointmentType>> getAppointmentTypes() async {
    try {
      final res = await _dio.get('/api/v1/appointments/types');
      final data = res.data['success']['data'] as List<dynamic>? ?? const [];
      return data
          .map((t) => AppointmentType.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppointmentException(
        _messageFrom(e, 'Unable to load appointment types.'),
      );
    }
  }

  /// Raises a request. This does not book a clinic slot — reception has to
  /// accept it first — so the caller should say so rather than confirming
  /// something that has not happened.
  ///
  /// [slot] must be the value BC supplied on the slot, not a formatted time:
  /// it is the key BC matches the diary line on.
  Future<int> book({
    required String doctorId,
    required DateTime date,
    required String slot,
    String branch = '',
    String appointmentType = '',
    String reason = '',
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/appointments',
        data: {
          'doctorId': doctorId,
          'date': formatDate(date),
          'slot': slot,
          'branch': branch,
          'appointmentType': appointmentType,
          'reason': reason,
        },
      );
      return res.data['success']['data']['entryNo'] as int? ?? 0;
    } on DioException catch (e) {
      throw AppointmentException(
        _messageFrom(e, 'Unable to request that appointment.'),
      );
    }
  }

  /// Withdraws a request the patient raised.
  Future<void> cancel({required int entryNo, String reason = ''}) async {
    try {
      await _dio.delete(
        '/api/v1/appointments/$entryNo',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw AppointmentException(
        _messageFrom(e, 'Unable to cancel that appointment.'),
      );
    }
  }

  /// Business Central parses dates as YYYY-MM-DD.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

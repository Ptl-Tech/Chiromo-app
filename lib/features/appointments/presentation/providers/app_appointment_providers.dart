import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/app_appointment_datasource.dart';
import '../../data/models/app_appointment_model.dart';

/// Providers for the Business-Central-backed appointment request feature.
///
/// Kept apart from `appointment_providers.dart`, which serves the doctor and
/// reception screens off Supabase. Both exist on purpose: a request raised in
/// the app and a booking the hospital has accepted are different things, and
/// only Business Central knows when one becomes the other.

final appAppointmentDataSourceProvider = Provider<AppAppointmentDataSource>((
  ref,
) {
  return AppAppointmentDataSource();
});

/// The signed-in patient's requests.
final appAppointmentsProvider = FutureProvider<List<AppAppointment>>((ref) {
  return ref.watch(appAppointmentDataSourceProvider).getAppointments();
});

/// Requests still ahead of the patient, soonest first — what the dashboard and
/// the top of the history screen show.
final upcomingAppointmentsProvider = FutureProvider<List<AppAppointment>>((
  ref,
) async {
  final all = await ref.watch(appAppointmentsProvider.future);
  final upcoming = all.where((a) => a.isUpcoming).toList()
    ..sort(_byDateAscending);
  return upcoming;
});

/// Everything already behind the patient, most recent first.
final pastAppointmentsProvider = FutureProvider<List<AppAppointment>>((
  ref,
) async {
  final all = await ref.watch(appAppointmentsProvider.future);
  final past = all.where((a) => !a.isUpcoming).toList()
    ..sort((a, b) => _byDateAscending(b, a));
  return past;
});

/// The kinds of appointment on offer. Cached for the session — it is clinic
/// configuration and changes rarely.
final appointmentTypesProvider = FutureProvider<List<AppointmentType>>((ref) {
  return ref.watch(appAppointmentDataSourceProvider).getAppointmentTypes();
});

/// How far ahead the booking screen looks. Two weeks is enough to find a slot
/// without pulling a diary nobody scrolls through.
const Duration kAvailabilityWindow = Duration(days: 14);

/// Doctors bookable in a window, with their free slots.
///
/// Not cached for the session, unlike the appointment types: a slot someone
/// else takes while this patient is deciding must stop being offered, so this
/// is re-read whenever the booking screen is opened or refreshed.
final availabilityProvider =
    FutureProvider.family<List<AvailableDoctor>, String?>((ref, branch) {
      final from = DateTime.now();
      return ref
          .watch(appAppointmentDataSourceProvider)
          .getAvailability(
            from: from,
            to: from.add(kAvailabilityWindow),
            branch: branch,
          );
    });

/// Imperative appointment actions. Errors are rethrown so the calling screen
/// can show them inline — for a booking clash the API's message is the useful
/// one, since it is Business Central saying why.
final appAppointmentNotifierProvider =
    StateNotifierProvider<AppAppointmentNotifier, AsyncValue<void>>((ref) {
      return AppAppointmentNotifier(ref);
    });

class AppAppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AppAppointmentNotifier(this._ref) : super(const AsyncValue.data(null));

  AppAppointmentDataSource get _source =>
      _ref.read(appAppointmentDataSourceProvider);

  /// Raises a request and returns its entry number.
  ///
  /// Invalidates availability as well as the request list: the slot just asked
  /// for should stop being offered to this patient immediately, whatever
  /// reception later decides.
  Future<int> book({
    required String doctorId,
    required DateTime date,
    required String slot,
    String branch = '',
    String appointmentType = '',
    String reason = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final entryNo = await _source.book(
        doctorId: doctorId,
        date: date,
        slot: slot,
        branch: branch,
        appointmentType: appointmentType,
        reason: reason,
      );
      _ref.invalidate(appAppointmentsProvider);
      _ref.invalidate(availabilityProvider);
      state = const AsyncValue.data(null);
      return entryNo;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancel({required int entryNo, String reason = ''}) async {
    state = const AsyncValue.loading();
    try {
      await _source.cancel(entryNo: entryNo, reason: reason);
      _ref.invalidate(appAppointmentsProvider);
      _ref.invalidate(availabilityProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Sorts by day, then by the slot's start time so a morning appointment comes
/// before an afternoon one on the same day. Requests with no parseable date
/// sort last rather than to the epoch.
int _byDateAscending(AppAppointment a, AppAppointment b) {
  final left = a.date;
  final right = b.date;
  if (left == null && right == null) return a.entryNo.compareTo(b.entryNo);
  if (left == null) return 1;
  if (right == null) return -1;

  final byDay = left.compareTo(right);
  if (byDay != 0) return byDay;
  return a.startTime.compareTo(b.startTime);
}

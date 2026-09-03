import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/clinical_remote_datasource.dart';
import '../../data/models/clinical_model.dart';

/// Providers for the Business-Central-backed clinical feeds — the doctor's
/// notes to the patient, and the medication list the doctor maintains.

final clinicalDataSourceProvider = Provider<ClinicalRemoteDataSource>((ref) {
  return ClinicalRemoteDataSource();
});

/// Notes written for the patient, newest first.
final visitNotesProvider = FutureProvider<List<VisitNote>>((ref) {
  return ref.watch(clinicalDataSourceProvider).getVisitNotes();
});

/// The notes attached to one appointment, so an attended appointment can show
/// what the doctor wrote about it.
final visitNotesForAppointmentProvider =
    FutureProvider.family<List<VisitNote>, String>((ref, appointmentNo) async {
      if (appointmentNo.isEmpty) return const [];
      final notes = await ref.watch(visitNotesProvider.future);
      return notes.where((n) => n.appointmentNo == appointmentNo).toList();
    });

/// Every medication entry, current and past.
final medicationsProvider = FutureProvider<List<Medication>>((ref) {
  return ref.watch(clinicalDataSourceProvider).getMedications();
});

/// What the patient should be taking now.
final currentMedicationsProvider = FutureProvider<List<Medication>>((
  ref,
) async {
  final all = await ref.watch(medicationsProvider.future);
  return all.where((m) => m.active).toList();
});

/// What they were taking and no longer are.
///
/// Kept visible rather than hidden: "why did I stop that?" is a question
/// people otherwise ring the clinic to ask, and the stop reason is right here.
final pastMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final all = await ref.watch(medicationsProvider.future);
  final past = all.where((m) => !m.active).toList()
    ..sort((a, b) => _byStartDateDescending(a, b));
  return past;
});

/// When the current list was last confirmed by a doctor, or null if none of it
/// ever has been.
///
/// The most recent review across the active entries — the list is only as
/// fresh as its newest check, and claiming otherwise would overstate it.
final medicationsLastReviewedProvider = FutureProvider<DateTime?>((ref) async {
  final current = await ref.watch(currentMedicationsProvider.future);

  DateTime? latest;
  for (final medication in current) {
    final reviewed = medication.lastReviewedOn;
    if (reviewed == null) continue;
    if (latest == null || reviewed.isAfter(latest)) latest = reviewed;
  }
  return latest;
});

/// Whether the list has gone long enough without a check that the app should
/// say so rather than presenting it as current.
///
/// A list that has never been reviewed counts as stale. That is the honest
/// reading: nobody has confirmed it, so the app should not imply anybody has.
final medicationsAreStaleProvider = FutureProvider<bool>((ref) async {
  final current = await ref.watch(currentMedicationsProvider.future);
  if (current.isEmpty) return false;

  final reviewed = await ref.watch(medicationsLastReviewedProvider.future);
  if (reviewed == null) return true;

  return DateTime.now().difference(reviewed) > kMedicationReviewWindow;
});

int _byStartDateDescending(Medication a, Medication b) {
  final left = a.startDate;
  final right = b.startDate;
  if (left == null && right == null) return b.entryNo.compareTo(a.entryNo);
  if (left == null) return 1;
  if (right == null) return -1;
  return right.compareTo(left);
}

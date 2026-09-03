/// Models for the two clinical feeds a patient gets once they have been seen:
/// the notes their doctor wrote for them, and the medication list their doctor
/// maintains.
///
/// Both are authored by a clinician in Business Central and are read-only
/// here. The app never edits either — a medication list the patient could
/// change would stop being a record of what their doctor decided.
library;

/// A note written for the patient after a visit.
///
/// This is not the clinical documentation the doctor writes for colleagues.
/// That is a separate record, written in a register that reads badly and
/// sometimes harmfully to the person it is about, and the API does not serve
/// it at all.
class VisitNote {
  final int entryNo;

  /// The visit this belongs to, so it can be shown under the right
  /// appointment rather than as a free-floating message. Blank when the note
  /// followed something other than a booked appointment.
  final String appointmentNo;

  final DateTime? date;
  final String doctorId;
  final String doctorName;

  /// What happened, in the patient's terms.
  final String summary;

  /// What to do before next time. In practice the part people come back to
  /// re-read, which is why it is a separate field rather than a paragraph
  /// buried in the summary.
  final String nextSteps;

  const VisitNote({
    required this.entryNo,
    this.appointmentNo = '',
    this.date,
    this.doctorId = '',
    this.doctorName = '',
    this.summary = '',
    this.nextSteps = '',
  });

  factory VisitNote.fromJson(Map<String, dynamic> json) {
    return VisitNote(
      entryNo: json['entryNo'] as int? ?? 0,
      appointmentNo: json['appointmentNo'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      nextSteps: json['nextSteps'] as String? ?? '',
    );
  }
}

/// Where a medication has got to.
enum MedicationStatus {
  active('Active'),
  stopped('Stopped'),
  completed('Completed');

  final String wireValue;
  const MedicationStatus(this.wireValue);

  static MedicationStatus fromJson(String? value) {
    for (final status in MedicationStatus.values) {
      if (status.wireValue == value) return status;
    }
    return MedicationStatus.active;
  }
}

/// One entry on the patient's medication list.
class Medication {
  final int entryNo;
  final String appointmentNo;
  final String drugName;

  /// Plain language, addressed to the patient — "one tablet twice a day, after
  /// food". The line they actually act on.
  final String instructions;

  final String dosage;
  final String frequency;
  final DateTime? startDate;

  /// Null means ongoing.
  final DateTime? endDate;

  final MedicationStatus status;

  /// Why it was stopped. Shown alongside a stopped medication, because "why
  /// did I stop that?" is a question people otherwise ring the clinic about.
  final String stopReason;

  final String doctorId;
  final String doctorName;

  /// When a doctor last confirmed this entry is still right.
  ///
  /// The API serves this on every entry for a reason: a medication list is at
  /// its most dangerous when it is stale and looks current. The UI is expected
  /// to say when the list was last checked rather than presenting it as
  /// timelessly true.
  final DateTime? lastReviewedOn;

  /// Whether this is something to be taking today. Computed by the API rather
  /// than re-derived here, so every client agrees on the answer.
  final bool active;

  const Medication({
    required this.entryNo,
    required this.drugName,
    required this.status,
    required this.active,
    this.appointmentNo = '',
    this.instructions = '',
    this.dosage = '',
    this.frequency = '',
    this.startDate,
    this.endDate,
    this.stopReason = '',
    this.doctorId = '',
    this.doctorName = '',
    this.lastReviewedOn,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      entryNo: json['entryNo'] as int? ?? 0,
      appointmentNo: json['appointmentNo'] as String? ?? '',
      drugName: json['drugName'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      status: MedicationStatus.fromJson(json['status'] as String?),
      stopReason: json['stopReason'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      lastReviewedOn: DateTime.tryParse(
        json['lastReviewedOn'] as String? ?? '',
      ),
      active: json['active'] as bool? ?? false,
    );
  }

  /// The dose and frequency as one line, skipping whichever is blank.
  String get regimen =>
      [dosage, frequency].where((s) => s.isNotEmpty).join(' · ');
}

/// How stale a medication list may get before the app says so.
///
/// Ninety days is a placeholder, not a clinical decision — it should be set by
/// the clinic. It exists so a list nobody has looked at in months is labelled
/// as such rather than shown with the same confidence as one checked today.
const Duration kMedicationReviewWindow = Duration(days: 90);

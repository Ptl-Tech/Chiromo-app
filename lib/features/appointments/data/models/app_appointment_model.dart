/// Models for app-originated appointment requests, mapping the Go API's
/// `/appointments` responses.
///
/// These are deliberately separate from [AppointmentEntity] and the Supabase
/// `appointments` table, which back the doctor, reception and consultation
/// screens. The two are not the same thing and must not be conflated: what a
/// patient raises from the app is a *request*, which sits outside clinical
/// workflow until reception accepts it and Business Central issues a hospital
/// booking number. Merging them would let the app tell someone they have an
/// appointment when the clinic has never agreed to see them.
library;

/// Where a request has got to.
///
/// The wire values are Business Central's own option captions. Anything
/// unrecognised maps to [pending] rather than throwing: a status the clinic
/// adds later should leave the request visible and cancellable, not break the
/// screen it appears on.
enum AppointmentStatus {
  pending('Pending', 'Awaiting confirmation'),
  confirmed('Confirmed', 'Confirmed'),
  rejected('Rejected', 'Not accepted'),
  cancelled('Cancelled', 'Cancelled'),
  attended('Attended', 'Attended'),
  noShow('No Show', 'Missed');

  /// The caption BC sends over OData.
  final String wireValue;

  /// What the patient reads. "Awaiting confirmation" rather than "Pending"
  /// because the distinction that matters to them is whether the hospital has
  /// agreed yet, not which row state BC is in.
  final String label;

  const AppointmentStatus(this.wireValue, this.label);

  static AppointmentStatus fromJson(String? value) {
    for (final status in AppointmentStatus.values) {
      if (status.wireValue == value) return status;
    }
    return AppointmentStatus.pending;
  }

  /// Whether this request is finished with, one way or another.
  bool get isClosed =>
      this == rejected ||
      this == cancelled ||
      this == attended ||
      this == noShow;
}

/// One appointment request the patient raised from the app.
class AppAppointment {
  final int entryNo;
  final String patientNo;
  final String patientName;
  final String branch;
  final String appointmentType;
  final String doctorId;
  final String doctorName;

  /// The requested day and slot window. Null only if BC sent something
  /// unparseable, in which case the card still renders with the raw slot text.
  final DateTime? date;
  final String slot;
  final String startTime;
  final String endTime;

  final String reason;
  final AppointmentStatus status;

  /// Reception's wording when a request is turned down, or the patient's own
  /// when they withdrew it. Written to be shown to the patient.
  final String decisionReason;

  final DateTime? bookedAt;

  /// The clinic's own appointment number, filled in when reception accepts
  /// the request. It is the key a visit note is anchored on, so it is what
  /// links the doctor's note to the appointment it was written about. Blank
  /// until the hospital has actually booked this.
  final String hospitalBookingNo;

  /// Whether the hospital has accepted this and turned it into a real booking.
  /// A stronger claim than [status] alone, and the API computes it rather than
  /// the app inferring it — it requires a hospital booking number, not just a
  /// Confirmed row.
  final bool confirmed;

  /// Mirrors what BC will actually allow, so the UI can hide the cancel button
  /// rather than offer one that errors.
  final bool cancellable;

  const AppAppointment({
    required this.entryNo,
    required this.status,
    this.patientNo = '',
    this.patientName = '',
    this.branch = '',
    this.appointmentType = '',
    this.doctorId = '',
    this.doctorName = '',
    this.date,
    this.slot = '',
    this.startTime = '',
    this.endTime = '',
    this.reason = '',
    this.decisionReason = '',
    this.bookedAt,
    this.hospitalBookingNo = '',
    this.confirmed = false,
    this.cancellable = false,
  });

  factory AppAppointment.fromJson(Map<String, dynamic> json) {
    return AppAppointment(
      entryNo: json['entryNo'] as int? ?? 0,
      patientNo: json['patientNo'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      appointmentType: json['appointmentType'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      slot: json['slot'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: AppointmentStatus.fromJson(json['status'] as String?),
      decisionReason: json['decisionReason'] as String? ?? '',
      bookedAt: DateTime.tryParse(json['bookedAt'] as String? ?? ''),
      hospitalBookingNo: json['hospitalBookingNo'] as String? ?? '',
      confirmed: json['confirmed'] as bool? ?? false,
      cancellable: json['cancellable'] as bool? ?? false,
    );
  }

  /// The slot window as "09:00 – 09:30", or whatever BC's slot label says when
  /// the times are missing.
  String get timeRange {
    if (startTime.isEmpty && endTime.isEmpty) return slot;
    if (endTime.isEmpty) return _hhmm(startTime);
    return '${_hhmm(startTime)} – ${_hhmm(endTime)}';
  }

  /// Whether this sits in the future and has not been closed out. Used to
  /// split the list into what is still coming and what has already happened.
  bool get isUpcoming {
    if (status.isClosed) return false;
    final day = date;
    if (day == null) return true;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return !day.isBefore(startOfToday);
  }

  static String _hhmm(String time) {
    if (time.length >= 5) return time.substring(0, 5);
    return time;
  }
}

/// One bookable slot in a doctor's diary.
class DoctorSlot {
  final DateTime? date;

  /// BC's own label for the slot, and the value that must be sent back when
  /// booking — it is the key BC matches on, not a formatted time.
  final String slot;

  final String startTime;
  final String endTime;

  const DoctorSlot({
    required this.slot,
    this.date,
    this.startTime = '',
    this.endTime = '',
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) {
    return DoctorSlot(
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      slot: json['slot'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }

  String get label {
    if (startTime.isEmpty) return slot;
    final start = AppAppointment._hhmm(startTime);
    if (endTime.isEmpty) return start;
    return '$start – ${AppAppointment._hhmm(endTime)}';
  }
}

/// A doctor with the slots they have free.
///
/// The availability query joins the diary to the doctor record, so a doctor
/// with no free slots produces no rows and simply does not appear. That is the
/// intended behaviour: this is a list of who can actually be seen, not a
/// directory.
class AvailableDoctor {
  final String doctorId;
  final String name;
  final String title;
  final String specialization;
  final String clinic;
  final String branch;
  final List<DoctorSlot> slots;

  const AvailableDoctor({
    required this.doctorId,
    required this.name,
    this.title = '',
    this.specialization = '',
    this.clinic = '',
    this.branch = '',
    this.slots = const [],
  });

  factory AvailableDoctor.fromJson(Map<String, dynamic> json) {
    final slots = (json['slots'] as List<dynamic>? ?? const [])
        .map((s) => DoctorSlot.fromJson(s as Map<String, dynamic>))
        .toList();

    return AvailableDoctor(
      doctorId: json['doctorId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      clinic: json['clinic'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      slots: slots,
    );
  }

  /// "Dr Jane Doe" when BC supplies a title, otherwise just the name.
  String get displayName => title.isEmpty ? name : '$title $name';

  /// The distinct days this doctor has anything free on.
  List<DateTime> get availableDates {
    final days = <DateTime>{};
    for (final slot in slots) {
      final date = slot.date;
      if (date != null) days.add(DateTime(date.year, date.month, date.day));
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  List<DoctorSlot> slotsOn(DateTime day) {
    return slots.where((s) {
      final date = s.date;
      if (date == null) return false;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }
}

/// A kind of appointment the clinic offers. Configuration in BC, so the app
/// renders whatever comes back rather than shipping a fixed list.
class AppointmentType {
  final String code;
  final String description;

  /// Whether choosing this type attracts a consultancy fee. Surfaced so the
  /// patient is not surprised at the desk.
  final bool billsConsultancyFee;

  /// A follow-up on an earlier visit rather than a new complaint.
  final bool isReview;

  const AppointmentType({
    required this.code,
    required this.description,
    this.billsConsultancyFee = false,
    this.isReview = false,
  });

  factory AppointmentType.fromJson(Map<String, dynamic> json) {
    return AppointmentType(
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      billsConsultancyFee: json['billsConsultancyFee'] as bool? ?? false,
      isReview: json['isReview'] as bool? ?? false,
    );
  }

  String get label => description.isEmpty ? code : description;
}

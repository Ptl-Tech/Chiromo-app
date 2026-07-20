/// Application-wide constants for Chiromo Hospital Management Platform.
class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────────
  static const String appName = 'Chiromo Hospital';
  static const String appTagline = 'Your Mental Health Partner';
  static const String appVersion = '1.0.0';

  // ── Supabase (replace with your project values) ───────────────
  static const String supabaseUrl = 'https://micgxvckwdptihzbzmsr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pY2d4dmNrd2RwdGloemJ6bXNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MjU2NTMsImV4cCI6MjA5OTUwMTY1M30.3la1fvzN75MSBvNMPdpVuBev3jho1j_cFUFq48xoEJ4';

  // ── Branches ──────────────────────────────────────────────────
  static const List<String> branches = [
    'Bustani',
    'Upper Hill',
    'Westlands',
    'Braeside',
    'Nyali',
    'Virtual Clinic',
  ];

  // ── User Roles ────────────────────────────────────────────────
  static const String roleSuperAdmin = 'super_admin';
  static const String roleHospitalAdmin = 'hospital_admin';
  static const String roleBranchManager = 'branch_manager';
  static const String roleReceptionist = 'receptionist';
  static const String rolePsychiatrist = 'psychiatrist';
  static const String rolePsychologist = 'psychologist';
  static const String roleTherapist = 'therapist';
  static const String roleNurse = 'nurse';
  static const String roleCashier = 'cashier';
  static const String roleLaboratory = 'laboratory';
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';

  // ── Appointment Statuses ──────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusRescheduleRequested = 'reschedule_requested';
  static const String statusRejected = 'rejected';
  static const String statusCheckedIn = 'checked_in';
  static const String statusInConsultation = 'in_consultation';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusNoShow = 'no_show';

  // ── Consultation Types ────────────────────────────────────────
  static const String consultPhysical = 'physical';
  static const String consultOnline = 'online';
  static const String consultHomeVisit = 'home_visit';

  // ── Payment Methods ───────────────────────────────────────────
  static const String paymentCash = 'cash';
  static const String paymentMpesa = 'mpesa';
  static const String paymentCard = 'card';
  static const String paymentInsurance = 'insurance';
  static const String paymentCorporate = 'corporate';

  // ── Animation Durations ───────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ── Pagination ────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

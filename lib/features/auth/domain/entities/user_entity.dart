/// Represents a user role within the Chiromo system.
enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  hospitalAdmin('hospital_admin', 'Hospital Admin'),
  branchManager('branch_manager', 'Branch Manager'),
  receptionist('receptionist', 'Receptionist'),
  doctor('doctor', 'Doctor'),
  psychiatrist('psychiatrist', 'Psychiatrist'),
  psychologist('psychologist', 'Psychologist'),
  therapist('therapist', 'Therapist'),
  nurse('nurse', 'Nurse'),
  cashier('cashier', 'Cashier'),
  laboratory('laboratory', 'Laboratory Staff'),
  patient('patient', 'Patient');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  /// Resolve from a raw string (e.g. from Supabase).
  static UserRole fromString(String v) => UserRole.values.firstWhere(
    (r) => r.value == v,
    orElse: () => UserRole.patient,
  );

  bool get isDoctor =>
      this == doctor ||
      this == psychiatrist ||
      this == psychologist ||
      this == therapist;

  bool get isAdmin => this == superAdmin || this == hospitalAdmin;

  bool get isStaff => this != patient;
}

/// Domain entity representing an authenticated user profile.
class UserEntity {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? bio;
  final UserRole role;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.bio,
    required this.role,
    this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });
}

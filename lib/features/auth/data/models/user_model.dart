import '../../domain/entities/user_entity.dart';

/// Data model that maps between Business Central's `PublicUser` JSON
/// (returned by the Go API's `/auth/login` and `/auth/me` endpoints) and the
/// domain [UserEntity].
class UserModel {
  final String email;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? phoneNumber;
  final String? gender;
  final String? idNumber;
  final DateTime? dateOfBirth;
  final DateTime? dateRegistered;
  final bool emailVerified;

  const UserModel({
    required this.email,
    this.firstName,
    this.middleName,
    this.lastName,
    this.phoneNumber,
    this.gender,
    this.idNumber,
    this.dateOfBirth,
    this.dateRegistered,
    this.emailVerified = false,
  });

  /// Derive a display name from first + middle + last name.
  String get fullName => [
    firstName ?? '',
    middleName ?? '',
    lastName ?? '',
  ].where((s) => s.isNotEmpty).join(' ');

  /// Deserialise from the Go API's PublicUser JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      gender: json['gender'] as String?,
      idNumber: json['idNumber'] as String?,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      dateRegistered: _parseDate(json['dateRegistered']),
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Convert to domain entity.
  ///
  /// Business Central's PublicUser has no internal id, role, avatar, or
  /// profile metadata, so email is used as the stable identifier and the
  /// remaining fields fall back to sensible defaults until the rest of the
  /// app's profile data is migrated off Supabase.
  UserEntity toEntity() {
    final now = DateTime.now();
    return UserEntity(
      id: email,
      email: email,
      fullName: fullName,
      phone: phoneNumber,
      gender: gender,
      idNumber: idNumber,
      avatarUrl: null,
      dateOfBirth: dateOfBirth,
      bio: null,
      role: UserRole.patient,
      branchId: null,
      createdAt: dateRegistered ?? now,
      updatedAt: now,
    );
  }
}

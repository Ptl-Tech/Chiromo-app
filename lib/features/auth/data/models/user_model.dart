import '../../domain/entities/user_entity.dart';

/// Data model that maps between the Supabase `profiles` table
/// and the domain [UserEntity].
class UserModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? bio;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.dateOfBirth,
    this.bio,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Derive a display name from first + last name.
  String get fullName =>
      [firstName ?? '', lastName ?? ''].where((s) => s.isNotEmpty).join(' ');

  /// Deserialise from Supabase row.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      bio: json['bio'] as String?,
      role: (json['role'] as String?) ?? 'patient',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Serialise to Supabase-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'bio': bio,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Convert to domain entity.
  UserEntity toEntity() => UserEntity(
    id: id,
    email: '', // email comes from auth.users, not profiles
    fullName: fullName,
    phone: phoneNumber,
    avatarUrl: avatarUrl,
    dateOfBirth: dateOfBirth,
    bio: bio,
    role: UserRole.fromString(role),
    branchId: null,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

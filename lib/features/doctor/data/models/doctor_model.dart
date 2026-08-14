import 'package:chiromo/features/auth/data/models/user_model.dart';
import '../../domain/entities/doctor_entity.dart';

class DoctorModel {
  final String id;
  final String userId;
  final String specialty;
  final String qualifications;
  final double consultationFee;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? userProfile;

  const DoctorModel({
    required this.id,
    required this.userId,
    required this.specialty,
    required this.qualifications,
    required this.consultationFee,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  /// Deserialise from Supabase row (used by features still on Supabase).
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      specialty: json['specialty'] as String,
      qualifications: json['qualifications'] as String,
      consultationFee: (json['consultation_fee'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userProfile: json['profiles'] != null ? UserModel.fromJson(json['profiles']) : null,
    );
  }

  /// Deserialise from the custom JWT API response.
  ///
  /// API shape: `{"Doctor_ID": "100001", "Doctors_Name": "Dr. Judy Kamau", "Specialization": "PSYCHIATRIST"}`
  ///
  /// Fields not present in the API are given safe defaults so the
  /// domain / UI layers continue to work without changes.
  factory DoctorModel.fromApiJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final rawName = (json['Doctors_Name'] as String? ?? '').trim();
    final nameParts = rawName.split(RegExp(r'\s+'));

    // First part(s) = first name, last part = last name
    final firstName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join(' ')
        : nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.last : '';

    return DoctorModel(
      id: json['Doctor_ID']?.toString() ?? '',
      userId: json['Doctor_ID']?.toString() ?? '',
      specialty: json['Specialization'] as String? ?? '',
      qualifications: '',       // not available from API yet
      consultationFee: 0.0,     // not available from API yet
      isAvailable: true,        // default
      createdAt: now,
      updatedAt: now,
      userProfile: UserModel(
        id: json['Doctor_ID']?.toString() ?? '',
        firstName: firstName,
        lastName: lastName,
        role: 'doctor',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  DoctorEntity toEntity() => DoctorEntity(
        id: id,
        userId: userId,
        specialty: specialty,
        qualifications: qualifications,
        consultationFee: consultationFee,
        isAvailable: isAvailable,
        createdAt: createdAt,
        updatedAt: updatedAt,
        userProfile: userProfile?.toEntity(),
      );
}

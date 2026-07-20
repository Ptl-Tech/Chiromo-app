import 'package:chiromo/features/auth/domain/entities/user_entity.dart';

/// Represents a Doctor profile in the domain layer.
class DoctorEntity {
  final String id;
  final String userId;
  final String specialty;
  final String qualifications;
  final double consultationFee;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relation to the base user profile
  final UserEntity? userProfile;

  const DoctorEntity({
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
}

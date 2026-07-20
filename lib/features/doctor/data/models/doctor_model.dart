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

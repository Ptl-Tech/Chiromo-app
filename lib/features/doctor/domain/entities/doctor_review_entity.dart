import 'package:equatable/equatable.dart';

class DoctorReviewEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;

  // Optional nested properties for UI
  final String? patientName;
  final String? patientAvatarUrl;

  const DoctorReviewEntity({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    this.patientName,
    this.patientAvatarUrl,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        patientId,
        doctorId,
        rating,
        reviewText,
        createdAt,
        patientName,
        patientAvatarUrl,
      ];
}

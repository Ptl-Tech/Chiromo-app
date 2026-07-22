import '../../domain/entities/doctor_review_entity.dart';

class DoctorReviewModel extends DoctorReviewEntity {
  const DoctorReviewModel({
    required super.id,
    required super.appointmentId,
    required super.patientId,
    required super.doctorId,
    required super.rating,
    super.reviewText,
    required super.createdAt,
    super.patientName,
    super.patientAvatarUrl,
  });

  factory DoctorReviewModel.fromJson(Map<String, dynamic> json) {
    return DoctorReviewModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientName: json['patient_name'] as String?,
      patientAvatarUrl: json['patient_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DoctorReviewModel.fromEntity(DoctorReviewEntity entity) {
    return DoctorReviewModel(
      id: entity.id,
      appointmentId: entity.appointmentId,
      patientId: entity.patientId,
      doctorId: entity.doctorId,
      rating: entity.rating,
      reviewText: entity.reviewText,
      createdAt: entity.createdAt,
      patientName: entity.patientName,
      patientAvatarUrl: entity.patientAvatarUrl,
    );
  }
}

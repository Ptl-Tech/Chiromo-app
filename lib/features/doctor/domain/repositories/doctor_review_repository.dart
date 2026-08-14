import '../entities/doctor_review_entity.dart';

abstract class DoctorReviewRepository {
  Future<DoctorReviewEntity> createReview(DoctorReviewEntity review);
  Future<DoctorReviewEntity?> getReviewForAppointment(String appointmentId);
}

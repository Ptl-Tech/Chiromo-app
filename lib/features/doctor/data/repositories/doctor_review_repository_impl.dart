import '../../domain/entities/doctor_review_entity.dart';
import '../../domain/repositories/doctor_review_repository.dart';
import '../datasources/doctor_review_remote_datasource.dart';
import '../models/doctor_review_model.dart';

class DoctorReviewRepositoryImpl implements DoctorReviewRepository {
  final DoctorReviewRemoteDataSource _remoteDataSource;

  DoctorReviewRepositoryImpl(this._remoteDataSource);

  @override
  Future<DoctorReviewEntity> createReview(DoctorReviewEntity review) async {
    return _remoteDataSource.createReview(DoctorReviewModel.fromEntity(review));
  }

  @override
  Future<DoctorReviewEntity?> getReviewForAppointment(String appointmentId) async {
    return _remoteDataSource.getReviewForAppointment(appointmentId);
  }
}

import '../../domain/entities/doctor_entity.dart';

abstract class DoctorRepository {
  Future<List<DoctorEntity>> getAllDoctors();
  Future<DoctorEntity?> getDoctorByUserId(String userId);
  Future<void> updateDoctorAvailability(String doctorId, bool isAvailable);
}

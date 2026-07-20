import '../../domain/entities/doctor_entity.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<DoctorEntity>> getAllDoctors() async {
    final models = await remoteDataSource.getAllDoctors();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<DoctorEntity?> getDoctorByUserId(String userId) async {
    final model = await remoteDataSource.getDoctorByUserId(userId);
    return model?.toEntity();
  }

  @override
  Future<void> updateDoctorAvailability(String doctorId, bool isAvailable) async {
    await remoteDataSource.updateDoctorAvailability(doctorId, isAvailable);
  }
}

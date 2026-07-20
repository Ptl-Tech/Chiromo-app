import '../../domain/entities/queue_entity.dart';
import '../../domain/repositories/reception_repository.dart';
import '../datasources/reception_remote_datasource.dart';

class ReceptionRepositoryImpl implements ReceptionRepository {
  final ReceptionRemoteDataSource _remoteDataSource;

  ReceptionRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<QueueEntity>> getQueue() async {
    final models = await _remoteDataSource.getQueue();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<QueueEntity> addToQueue({
    required String patientId,
    String? appointmentId,
    String? branchId,
    String? assignedDoctorId,
    String? notes,
  }) async {
    final model = await _remoteDataSource.addToQueue(
      patientId: patientId,
      appointmentId: appointmentId,
      branchId: branchId,
      assignedDoctorId: assignedDoctorId,
      notes: notes,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateQueueStatus(String queueId, String status) async {
    await _remoteDataSource.updateQueueStatus(queueId, status);
  }
}

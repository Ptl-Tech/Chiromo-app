import '../entities/queue_entity.dart';

abstract class ReceptionRepository {
  Future<List<QueueEntity>> getQueue();
  Future<QueueEntity> addToQueue({
    required String patientId,
    String? appointmentId,
    String? branchId,
    String? assignedDoctorId,
    String? notes,
  });
  Future<void> updateQueueStatus(String queueId, String status);
}

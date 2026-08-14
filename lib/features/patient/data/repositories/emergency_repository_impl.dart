import '../../domain/entities/safety_plan_entity.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_datasource.dart';
import '../models/safety_plan_model.dart';
import '../models/emergency_contact_model.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final EmergencyRemoteDataSource _remoteDataSource;

  EmergencyRepositoryImpl(this._remoteDataSource);

  @override
  Future<SafetyPlanEntity?> getSafetyPlan(String patientId) {
    return _remoteDataSource.getSafetyPlan(patientId);
  }

  @override
  Future<SafetyPlanEntity> upsertSafetyPlan(SafetyPlanEntity plan) {
    return _remoteDataSource.upsertSafetyPlan(SafetyPlanModel.fromEntity(plan));
  }

  @override
  Future<List<EmergencyContactEntity>> getEmergencyContacts(String patientId) {
    return _remoteDataSource.getEmergencyContacts(patientId);
  }

  @override
  Future<EmergencyContactEntity> createEmergencyContact(EmergencyContactEntity contact) {
    return _remoteDataSource.createEmergencyContact(EmergencyContactModel.fromEntity(contact));
  }

  @override
  Future<EmergencyContactEntity> updateEmergencyContact(EmergencyContactEntity contact) {
    return _remoteDataSource.updateEmergencyContact(EmergencyContactModel.fromEntity(contact));
  }

  @override
  Future<void> deleteEmergencyContact(String id) {
    return _remoteDataSource.deleteEmergencyContact(id);
  }
}

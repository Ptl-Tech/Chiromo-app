import '../entities/safety_plan_entity.dart';
import '../entities/emergency_contact_entity.dart';

abstract class EmergencyRepository {
  Future<SafetyPlanEntity?> getSafetyPlan(String patientId);
  Future<SafetyPlanEntity> upsertSafetyPlan(SafetyPlanEntity plan);

  Future<List<EmergencyContactEntity>> getEmergencyContacts(String patientId);
  Future<EmergencyContactEntity> createEmergencyContact(EmergencyContactEntity contact);
  Future<EmergencyContactEntity> updateEmergencyContact(EmergencyContactEntity contact);
  Future<void> deleteEmergencyContact(String id);
}

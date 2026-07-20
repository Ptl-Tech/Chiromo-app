class MedicalRecordEntity {
  final String id;
  final String patientId;
  final String doctorId;
  final String? appointmentId;
  final String? chiefComplaint;
  final String? clinicalNotes;
  final String? bloodPressure;
  final int? heartRate;
  final double? temperature;
  final double? weight;
  final double? height;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalRecordEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    this.chiefComplaint,
    this.clinicalNotes,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    required this.createdAt,
    required this.updatedAt,
  });
}

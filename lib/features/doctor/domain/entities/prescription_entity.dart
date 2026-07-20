class PrescriptionEntity {
  final String id;
  final String medicalRecordId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;
  final bool isDispensed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrescriptionEntity({
    required this.id,
    required this.medicalRecordId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.instructions,
    required this.isDispensed,
    required this.createdAt,
    required this.updatedAt,
  });
}

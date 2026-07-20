class DiagnosisEntity {
  final String id;
  final String medicalRecordId;
  final String? icd10Code;
  final String description;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiagnosisEntity({
    required this.id,
    required this.medicalRecordId,
    this.icd10Code,
    required this.description,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

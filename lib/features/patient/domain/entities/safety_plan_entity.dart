import 'package:equatable/equatable.dart';

class SafetyPlanEntity extends Equatable {
  final String id;
  final String patientId;
  final String? warningSigns;
  final String? copingStrategies;
  final String? reasonsToLive;
  final String? professionalContacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SafetyPlanEntity({
    required this.id,
    required this.patientId,
    this.warningSigns,
    this.copingStrategies,
    this.reasonsToLive,
    this.professionalContacts,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        warningSigns,
        copingStrategies,
        reasonsToLive,
        professionalContacts,
        createdAt,
        updatedAt,
      ];
}

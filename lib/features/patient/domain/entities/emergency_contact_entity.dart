import 'package:equatable/equatable.dart';

class EmergencyContactEntity extends Equatable {
  final String id;
  final String patientId;
  final String name;
  final String phoneNumber;
  final String? relationship;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContactEntity({
    required this.id,
    required this.patientId,
    required this.name,
    required this.phoneNumber,
    this.relationship,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        name,
        phoneNumber,
        relationship,
        createdAt,
        updatedAt,
      ];
}

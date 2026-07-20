import '../../../auth/domain/entities/user_entity.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';

class InvoiceEntity {
  final String id;
  final String patientId;
  final String? appointmentId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final DateTime issuedAt;
  final DateTime? paidAt;
  final UserEntity? patient;
  final AppointmentEntity? appointment;

  const InvoiceEntity({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    required this.issuedAt,
    this.paidAt,
    this.patient,
    this.appointment,
  });
}

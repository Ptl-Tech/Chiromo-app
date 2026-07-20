import '../../domain/entities/invoice_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../appointments/data/models/appointment_model.dart';

class InvoiceModel {
  final String id;
  final String patientId;
  final String? appointmentId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final DateTime issuedAt;
  final DateTime? paidAt;
  final UserModel? patient;
  final AppointmentModel? appointment;

  const InvoiceModel({
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

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      patient: json['patient'] != null ? UserModel.fromJson(json['patient']) : null,
      appointment: json['appointment'] != null ? AppointmentModel.fromJson(json['appointment']) : null,
    );
  }

  InvoiceEntity toEntity() {
    return InvoiceEntity(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      amount: amount,
      status: status,
      paymentMethod: paymentMethod,
      issuedAt: issuedAt,
      paidAt: paidAt,
      patient: patient?.toEntity(),
      appointment: appointment?.toEntity(),
    );
  }
}

import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.invoiceId,
    required super.patientId,
    required super.amount,
    required super.paymentMethod,
    super.transactionReference,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      patientId: json['patient_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      transactionReference: json['transaction_reference'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'patient_id': patientId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_reference': transactionReference,
      'status': status,
    };
  }
}

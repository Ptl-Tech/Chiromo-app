class PaymentEntity {
  final String id;
  final String invoiceId;
  final String patientId;
  final double amount;
  final String paymentMethod;
  final String? transactionReference;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentEntity({
    required this.id,
    required this.invoiceId,
    required this.patientId,
    required this.amount,
    required this.paymentMethod,
    this.transactionReference,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

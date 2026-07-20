import '../entities/invoice_entity.dart';
import '../entities/payment_entity.dart';

abstract class CashierRepository {
  Future<List<InvoiceEntity>> getInvoices();
  Future<InvoiceEntity> createInvoice({
    required String patientId,
    String? appointmentId,
    required double amount,
  });
  Future<PaymentEntity> processPayment(PaymentEntity payment);
}

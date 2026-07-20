import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/cashier_repository.dart';
import '../datasources/cashier_remote_datasource.dart';
import '../models/payment_model.dart';

class CashierRepositoryImpl implements CashierRepository {
  final CashierRemoteDataSource _remoteDataSource;

  CashierRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<InvoiceEntity>> getInvoices() async {
    final models = await _remoteDataSource.getInvoices();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<InvoiceEntity> createInvoice({
    required String patientId,
    String? appointmentId,
    required double amount,
  }) async {
    final model = await _remoteDataSource.createInvoice(
      patientId: patientId,
      appointmentId: appointmentId,
      amount: amount,
    );
    return model.toEntity();
  }



  @override
  Future<PaymentEntity> processPayment(PaymentEntity payment) async {
    final model = PaymentModel(
      id: payment.id,
      invoiceId: payment.invoiceId,
      patientId: payment.patientId,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      transactionReference: payment.transactionReference,
      status: payment.status,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
    return await _remoteDataSource.processPayment(model);
  }
}

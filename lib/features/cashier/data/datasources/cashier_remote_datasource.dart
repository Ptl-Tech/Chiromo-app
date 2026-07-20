import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

class CashierRemoteDataSource {
  final SupabaseClient _client;

  CashierRemoteDataSource(this._client);

  Future<List<InvoiceModel>> getInvoices() async {
    final response = await _client
        .from('invoices')
        .select('''
          *,
          patient:profiles!patient_id(*),
          appointment:appointments!appointment_id(
            *,
            doctor:doctors!doctor_id(
              *,
              profiles!user_id(*)
            )
          )
        ''')
        .order('issued_at', ascending: false);

    return (response as List).map((e) => InvoiceModel.fromJson(e)).toList();
  }

  Future<InvoiceModel> createInvoice({
    required String patientId,
    String? appointmentId,
    required double amount,
  }) async {
    final response = await _client.from('invoices').insert({
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'amount': amount,
      'status': 'pending',
    }).select('''
          *,
          patient:profiles!patient_id(*),
          appointment:appointments!appointment_id(
            *,
            doctor:doctors!doctor_id(
              *,
              profiles!user_id(*)
            )
          )
        ''').single();

    return InvoiceModel.fromJson(response);
  }

  Future<PaymentModel> processPayment(PaymentModel payment) async {
    // 1. Insert into payments table
    final response = await _client.from('payments').insert(payment.toJson()).select().single();
    
    // 2. Update invoice status
    await _client.from('invoices').update({
      'status': 'paid',
      'payment_method': payment.paymentMethod,
      'paid_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', payment.invoiceId);

    return PaymentModel.fromJson(response);
  }
}

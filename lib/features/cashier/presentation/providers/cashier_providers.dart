import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/cashier_repository.dart';
import '../../data/datasources/cashier_remote_datasource.dart';
import '../../data/repositories/cashier_repository_impl.dart';

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  final client = SupabaseService.client;
  return CashierRepositoryImpl(CashierRemoteDataSource(client));
});

final allInvoicesProvider = FutureProvider<List<InvoiceEntity>>((ref) async {
  final repo = ref.watch(cashierRepositoryProvider);
  return repo.getInvoices();
});

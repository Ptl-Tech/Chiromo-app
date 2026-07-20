import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/cashier_providers.dart';

class CashierDashboardScreen extends ConsumerWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(allInvoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(allInvoicesProvider),
          ),
        ],
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (invoices) => _buildBody(context, ref, invoices),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<InvoiceEntity> invoices,
  ) {
    final pending = invoices.where((i) => i.status == 'pending').toList();
    final paid = invoices.where((i) => i.status == 'paid').toList();
    final totalAmount = invoices.fold<double>(0.0, (sum, i) => sum + i.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total',
                  '\u{20A6}${totalAmount.toStringAsFixed(2)}',
                  ChiromoColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryCard(
                  'Pending',
                  '${pending.length}',
                  ChiromoColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryCard(
                  'Paid',
                  '${paid.length}',
                  ChiromoColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Invoices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          invoices.isEmpty
              ? const Center(child: Text('No invoices found.'))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final statusColor = inv.status == 'paid'
                        ? ChiromoColors.success
                        : ChiromoColors.warning;
                    final patientName = inv.patient?.fullName ?? 'Unknown';
                    final created = inv.issuedAt.toLocal();
                    final formattedDate =
                        '${created.day}/${created.month}/${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}';
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ChiromoColors.primarySurface,
                          child: Text(
                            '#${inv.id.substring(0, 4)}',
                            style: const TextStyle(
                              color: ChiromoColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '\u{20A6}${inv.amount.toStringAsFixed(2)} – $patientName',
                        ),
                        subtitle: Text('Created: $formattedDate'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inv.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onTap: inv.status == 'pending'
                            ? () => _showPaymentDialog(context, ref, inv)
                            : null,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    InvoiceEntity inv,
  ) {
    final formKey = GlobalKey<FormState>();
    final refCtrl = TextEditingController();
    String selectedMethod = 'mpesa';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Process Payment'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Amount: \u{20A6}${inv.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'insurance',
                          child: Text('Insurance'),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedMethod = v!),
                    ),
                    const SizedBox(height: 16),
                    if (selectedMethod == 'mpesa' || selectedMethod == 'card')
                      TextFormField(
                        controller: refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Reference',
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required for $selectedMethod'
                            : null,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if ((selectedMethod == 'mpesa' ||
                            selectedMethod == 'card') &&
                        !formKey.currentState!.validate()) {
                      return;
                    }
                    try {
                      final repo = ref.read(cashierRepositoryProvider);

                      final payment = PaymentEntity(
                        id: '',
                        invoiceId: inv.id,
                        patientId: inv.patient!.id,
                        amount: inv.amount,
                        paymentMethod: selectedMethod,
                        transactionReference: refCtrl.text.isNotEmpty
                            ? refCtrl.text
                            : null,
                        status: 'completed',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await repo.processPayment(payment);
                      ref.invalidate(allInvoicesProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment processed successfully.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Confirm Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

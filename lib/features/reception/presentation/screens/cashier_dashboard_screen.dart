import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/layouts/app_scaffold.dart';

class CashierDashboardScreen extends StatelessWidget {
  const CashierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cashier & Billing',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pending Bills',
                    '18',
                    ChiromoColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Collected Today',
                    'KES 145K',
                    ChiromoColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pending Invoices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final names = [
                  'Jane Doe',
                  'Michael Kariuki',
                  'Sarah Wanjiku',
                  'David Omondi',
                ];
                final amounts = [
                  'KES 4,500',
                  'KES 12,000',
                  'KES 3,500',
                  'KES 8,000',
                ];
                final types = [
                  'Consultation',
                  'Lab Tests & Meds',
                  'Therapy Session',
                  'Consultation & Meds',
                ];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          names[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          amounts[index],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ChiromoColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            types[index],
                            style: const TextStyle(
                              color: ChiromoColors.textSecondary,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            onPressed: () {
                              _showPaymentDialog(
                                context,
                                names[index],
                                amounts[index],
                              );
                            },
                            child: const Text('Process Pay'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
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

  void _showPaymentDialog(BuildContext context, String name, String amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient: $name'),
            const SizedBox(height: 8),
            Text(
              'Amount Due: $amount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Payment Method:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              initialValue: 'M-PESA',
              items: [
                'M-PESA',
                'Cash',
                'Card',
                'Insurance',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment processed successfully')),
              );
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}

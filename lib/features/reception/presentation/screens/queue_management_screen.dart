import 'package:flutter/material.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../theme/chiromo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reception_providers.dart';

class QueueManagementScreen extends ConsumerWidget {
  const QueueManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(currentQueueProvider);
    return AppScaffold(
      title: 'Queue Management',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patient by file number or name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: ChiromoColors.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Check In'),
                ),
              ],
            ),
          ),
          Expanded(
            child: queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (queues) {
                if (queues.isEmpty) {
                  return const Center(child: Text('Queue is currently empty.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: queues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = queues[index];

                    Color statusColor = ChiromoColors.warning;
                    String statusText = q.status.toUpperCase();
                    if (q.status == 'triage') statusColor = ChiromoColors.info;
                    if (q.status == 'with_doctor') {
                      statusColor = ChiromoColors.primary;
                    }
                    if (q.status == 'completed') {
                      statusColor = ChiromoColors.success;
                    }

                    final timeFormatted = DateFormat(
                      'h:mm a',
                    ).format(q.checkInTime.toLocal());
                    final doctorName =
                        q.doctor?.userProfile?.fullName ?? 'Unassigned';

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: ChiromoColors.primarySurface,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: ChiromoColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          q.patient?.fullName ?? 'Unknown Patient',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Arrival: $timeFormatted | Dr. $doctorName',
                        ),
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
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

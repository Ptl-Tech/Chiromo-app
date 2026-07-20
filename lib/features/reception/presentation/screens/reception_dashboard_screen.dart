import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/layouts/app_scaffold.dart';
import '../../../../widgets/cards/chiromo_action_card.dart';
import '../../../../theme/chiromo_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reception_providers.dart';

class ReceptionDashboardScreen extends ConsumerWidget {
  const ReceptionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(currentQueueProvider);

    return AppScaffold(
      title: 'Front Desk Reception',
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () {},
          tooltip: 'Scan Patient ID',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (queues) {
                final waiting = queues.where((q) => q.status == 'waiting').length;
                final inSession = queues.where((q) => q.status == 'with_doctor' || q.status == 'triage').length;
                final completed = queues.where((q) => q.status == 'completed').length;
                
                return Row(
                  children: [
                    Expanded(child: _buildQueueCard('Waiting', '$waiting', ChiromoColors.warning)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQueueCard('In Session', '$inSession', ChiromoColors.info)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildQueueCard('Completed', '$completed', ChiromoColors.success)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ChiromoActionCard(
              title: 'Queue Management',
              subtitle: 'Manage patient flow, check-ins, and triage',
              icon: Icons.queue,
              onTap: () => context.go('/reception/queue'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Register New Patient',
              subtitle: 'Create a new patient record and assign a file number',
              icon: Icons.person_add,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Book Appointment',
              subtitle: 'Schedule an appointment for a walk-in patient',
              icon: Icons.calendar_month,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/chiromo_colors.dart';
import '../../../../widgets/cards/chiromo_action_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hospital Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            
            // Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard('Total Patients', '1,204', Icons.people, ChiromoColors.primary),
                    _buildMetricCard('Active Doctors', '45', Icons.medical_services, ChiromoColors.gold),
                    _buildMetricCard('Appointments Today', '128', Icons.calendar_today, ChiromoColors.success),
                    _buildMetricCard('Revenue Today', 'KES 145K', Icons.attach_money, ChiromoColors.info),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            Text('Management Modules', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            ChiromoActionCard(
              title: 'User Management',
              subtitle: 'Manage staff roles, permissions, and accounts',
              icon: Icons.manage_accounts,
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Branch Management',
              subtitle: 'Add or configure hospital branches (e.g. Chiromo Lane, Westlands)',
              icon: Icons.business,
              onTap: () => context.go('/admin/branches'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'Analytics & Reports',
              subtitle: 'View detailed financial and clinical reports',
              icon: Icons.analytics,
              onTap: () => context.go('/analytics'),
            ),
            const SizedBox(height: 12),
            ChiromoActionCard(
              title: 'System Settings',
              subtitle: 'Configure global application settings',
              icon: Icons.settings,
              onTap: () => context.go('/admin/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ChiromoColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: ChiromoColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}


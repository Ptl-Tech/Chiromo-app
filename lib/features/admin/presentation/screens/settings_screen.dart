import 'package:flutter/material.dart';
import '../../../../theme/chiromo_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../widgets/buttons/chiromo_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('System Configuration'),
          _buildSwitchTile(
            'Enable Maintenance Mode',
            'Suspend user access temporarily',
            false,
          ),
          _buildSwitchTile(
            'Debug Logging',
            'Save detailed logs for troubleshooting',
            true,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Security'),
          _buildListTile(
            Icons.security,
            'Two-Factor Authentication',
            'Enforce 2FA for all admins',
          ),
          _buildListTile(
            Icons.vpn_key,
            'API Keys',
            'Manage third-party integrations',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Localization'),
          _buildListTile(Icons.language, 'Language', 'English (UK)'),
          _buildListTile(Icons.attach_money, 'Currency', 'KES'),

          const SizedBox(height: 48),
          ChiromoButton(
            label: 'Sign Out Admin',
            variant: ChiromoButtonVariant.outline,
            icon: Icons.logout,
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ChiromoColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ChiromoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: ChiromoColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ChiromoColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: ChiromoColors.textTertiary,
      ),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ChiromoColors.textSecondary),
      ),
      value: value,
      onChanged: (v) {},
      activeThumbColor: ChiromoColors.primary,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chiromo/theme/chiromo_colors.dart';
import 'package:chiromo/widgets/layouts/app_scaffold.dart';
import '../providers/emergency_hotlines_provider.dart';
import '../providers/emergency_providers.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  // Helper to convert hex string to Color
  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Helper to get IconData from string
  IconData _iconFromName(String iconName) {
    switch (iconName) {
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'phone_in_talk':
      default:
        return Icons.phone_in_talk_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hotlinesAsync = ref.watch(emergencyHotlinesProvider);
    final safetyPlanAsync = ref.watch(safetyPlanProvider);
    final emergencyContactsAsync = ref.watch(emergencyContactsProvider);

    return AppScaffold(
      title: 'Emergency & Crisis',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Immediate Danger Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFE4E1).withValues(alpha: 0.6),
                    const Color(0xFFFFE4E4).withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFB3BA).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B7A).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/3d/siren.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'If you or someone else is in immediate danger, please go to the nearest emergency room or call emergency services immediately.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Immediate Help Section
            Text(
              'Immediate Help',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ChiromoColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            hotlinesAsync.when(
              data: (hotlines) {
                if (hotlines.isEmpty) {
                  return const Text('No emergency hotlines available.');
                }
                return Column(
                  children: hotlines
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildEmergencyContactCard(
                            context: context,
                            title: h.title,
                            subtitle: h.subtitle,
                            phoneNumber: h.phoneNumber,
                            icon: _iconFromName(h.iconName),
                            color: _colorFromHex(h.colorHex),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text(
                'Error loading hotlines: $e',
                style: TextStyle(color: ChiromoColors.error),
              ),
            ),

            const SizedBox(height: 36),

            // Personal Safety Plan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Safety Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ChiromoColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      context.push('/patient/emergency/safety-plan'),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChiromoColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: ChiromoColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            safetyPlanAsync.when(
              data: (plan) {
                bool hasData =
                    plan != null &&
                    ((plan.warningSigns?.isNotEmpty ?? false) ||
                        (plan.copingStrategies?.isNotEmpty ?? false) ||
                        (plan.reasonsToLive?.isNotEmpty ?? false) ||
                        (plan.professionalContacts?.isNotEmpty ?? false));

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: ChiromoColors.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: ChiromoColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: hasData
                                  ? [
                                      ChiromoColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      Colors.white,
                                    ]
                                  : [
                                      Colors.grey.withValues(alpha: 0.1),
                                      Colors.white,
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: hasData
                                      ? ChiromoColors.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.grey.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasData
                                      ? Icons.shield_rounded
                                      : Icons.shield_outlined,
                                  color: hasData
                                      ? ChiromoColors.primary
                                      : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  hasData
                                      ? 'Your safety plan is active and ready.'
                                      : 'Your safety plan is empty. Click Edit to create one.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: hasData
                                        ? ChiromoColors.textPrimary
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasData)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 24, thickness: 1),
                                if (plan.warningSigns?.isNotEmpty ?? false)
                                  _buildPlanDetailRow(
                                    Icons.warning_amber_rounded,
                                    'Warning Signs',
                                    plan.warningSigns!,
                                  ),
                                if (plan.copingStrategies?.isNotEmpty ?? false)
                                  _buildPlanDetailRow(
                                    Icons.self_improvement_rounded,
                                    'Coping Strategies',
                                    plan.copingStrategies!,
                                  ),
                                if (plan.reasonsToLive?.isNotEmpty ?? false)
                                  _buildPlanDetailRow(
                                    Icons.favorite_rounded,
                                    'Reasons to Live',
                                    plan.reasonsToLive!,
                                    iconColor: Colors.redAccent,
                                  ),
                                if (plan.professionalContacts?.isNotEmpty ??
                                    false)
                                  _buildPlanDetailRow(
                                    Icons.medical_services_rounded,
                                    'Professional Contacts',
                                    plan.professionalContacts!,
                                    iconColor: Colors.blueAccent,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading safety plan: $e'),
            ),
            const SizedBox(height: 36),

            // Emergency Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Contacts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ChiromoColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/patient/emergency/contact'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ChiromoColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: ChiromoColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            emergencyContactsAsync.when(
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.contact_phone_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No personal emergency contacts added yet.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: contacts
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () => context.push(
                              '/patient/emergency/contact',
                              extra: c,
                            ),
                            child: _buildEmergencyContactCard(
                              context: context,
                              title: c.name,
                              subtitle: c.relationship ?? 'Personal Contact',
                              phoneNumber: c.phoneNumber,
                              icon: Icons.person_rounded,
                              color: ChiromoColors.primary,
                              isPersonal: true,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading contacts: $e'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? ChiromoColors.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? ChiromoColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ChiromoColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ChiromoColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String phoneNumber,
    required IconData icon,
    required Color color,
    bool isPersonal = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makePhoneCall(context, phoneNumber),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: ChiromoColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ChiromoColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isPersonal) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone_rounded,
                              size: 14,
                              color: color.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
